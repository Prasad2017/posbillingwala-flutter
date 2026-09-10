import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:pos_billingwala_v2/features/print/domain/esc_pos_encoder.dart';
import 'package:pos_billingwala_v2/features/print/domain/print_image_encoder.dart';
import 'package:pos_billingwala_v2/features/print/domain/printer_settings.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// Renders receipt Unicode text (any language + ₹) to ESC/POS raster bytes,
/// same approach as Android layout → bitmap → [PrintImage].
class ReceiptRasterizer {
  const ReceiptRasterizer();

  /// Android effective widths: 2″ → 48*8=384, 3″ → 72*8=576.
  static int widthPxFor(PrinterPaperSize size) =>
      size == PrinterPaperSize.inch3 ? 576 : 384;

  Future<List<int>> encodeText(
    String text, {
    required PrinterSettings settings,
    String? qrPayload,
    String? logoPath,
    String? qrMarker,
  }) async {
    final width = widthPxFor(settings.paperSize);
    final rendered = await _render(
      text,
      width,
      qrPayload: qrPayload,
      logoPath: logoPath,
      qrMarker: qrMarker,
    );
    final raster = PrintImageEncoder.encodeRgba(
      rgba: rendered.rgba,
      width: rendered.width,
      height: rendered.height,
      brightValue: 128,
    );

    final out = EscPosEncoder(charsPerLine: settings.charsPerLine)
      ..init()
      ..raw(raster)
      ..feed(settings.feedLines);
    return out.bytes;
  }

  Future<_RenderedImage> _render(
    String text,
    int widthPx, {
    String? qrPayload,
    String? logoPath,
    String? qrMarker,
  }) async {
    ui.Image? logoImage;
    var logoDrawH = 0.0;
    final path = logoPath?.trim() ?? '';
    if (path.isNotEmpty) {
      try {
        final file = File(path);
        if (await file.exists()) {
          final bytes = await file.readAsBytes();
          final codec = await ui.instantiateImageCodec(
            bytes,
            targetWidth: (widthPx * 0.45).round().clamp(64, widthPx - 32),
          );
          final frame = await codec.getNextFrame();
          logoImage = frame.image;
          logoDrawH = logoImage.height.toDouble() + 12;
        }
      } catch (_) {
        logoImage = null;
      }
    }

    final marker = qrMarker?.trim() ?? '';
    final hasInlineQr = marker.isNotEmpty &&
        text.contains(marker) &&
        qrPayload != null &&
        qrPayload.trim().isNotEmpty;

    String topText = text;
    String bottomText = '';
    if (hasInlineQr) {
      final parts = text.split(marker);
      topText = parts.first.replaceAll(RegExp(r'\n+$'), '\n');
      bottomText = parts.length > 1
          ? parts.sublist(1).join(marker).replaceFirst(RegExp(r'^\n+'), '')
          : '';
    } else {
      // Strip unused marker if present.
      if (marker.isNotEmpty) {
        topText = text.replaceAll(marker, '');
      }
    }

    const style = TextStyle(
      color: Color(0xFF000000),
      fontSize: 22,
      height: 1.25,
      fontWeight: FontWeight.w500,
    );

    final topPainter = TextPainter(
      text: TextSpan(text: topText, style: style),
      textAlign: TextAlign.left,
      textDirection: TextDirection.ltr,
      locale: const Locale('en', 'IN'),
    )..layout(maxWidth: widthPx - 16.0);

    TextPainter? bottomPainter;
    if (bottomText.trim().isNotEmpty) {
      bottomPainter = TextPainter(
        text: TextSpan(text: bottomText, style: style),
        textAlign: TextAlign.left,
        textDirection: TextDirection.ltr,
        locale: const Locale('en', 'IN'),
      )..layout(maxWidth: widthPx - 16.0);
    }

    final qrSize = (widthPx * 0.55).clamp(120.0, 280.0);
    final qrData = qrPayload?.trim() ?? '';
    // Inline marker = Android order (terms → QR → footer). No marker = append at end.
    final drawQr = qrData.isNotEmpty && (hasInlineQr || marker.isEmpty);
    final qrGap = drawQr ? qrSize + 24 : 0.0;
    final bottomH = bottomPainter?.height ?? 0.0;
    final height = (logoDrawH + topPainter.height + qrGap + bottomH + 24)
        .ceil()
        .clamp(24, 12000);

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, widthPx.toDouble(), height.toDouble()),
      Paint()..color = const Color(0xFFFFFFFF),
    );

    var y = 12.0;
    if (logoImage != null) {
      final lw = logoImage.width.toDouble();
      final lh = logoImage.height.toDouble();
      final left = (widthPx - lw) / 2;
      canvas.drawImage(logoImage, Offset(left, y), Paint());
      y += lh + 8;
      logoImage.dispose();
    }

    topPainter.paint(canvas, Offset(8, y));
    y += topPainter.height + 8;

    if (drawQr) {
      _drawQr(
        canvas,
        qrData,
        left: (widthPx - qrSize) / 2,
        top: y,
        size: qrSize,
      );
      y += qrSize + 12;
    }

    bottomPainter?.paint(canvas, Offset(8, y));

    final picture = recorder.endRecording();
    final image = await picture.toImage(widthPx, height);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    image.dispose();
    if (byteData == null) {
      return _RenderedImage(
        rgba: Uint8List(widthPx * height * 4),
        width: widthPx,
        height: height,
      );
    }
    return _RenderedImage(
      rgba: byteData.buffer.asUint8List(),
      width: widthPx,
      height: height,
    );
  }

  void _drawQr(
    Canvas canvas,
    String data, {
    required double left,
    required double top,
    required double size,
  }) {
    canvas.save();
    canvas.translate(left, top);
    QrPainter(
      data: data,
      version: QrVersions.auto,
      errorCorrectionLevel: QrErrorCorrectLevel.L,
      gapless: true,
      eyeStyle: const QrEyeStyle(
        eyeShape: QrEyeShape.square,
        color: Color(0xFF000000),
      ),
      dataModuleStyle: const QrDataModuleStyle(
        dataModuleShape: QrDataModuleShape.square,
        color: Color(0xFF000000),
      ),
    ).paint(canvas, Size(size, size));
    canvas.restore();
  }
}

class _RenderedImage {
  const _RenderedImage({
    required this.rgba,
    required this.width,
    required this.height,
  });

  final Uint8List rgba;
  final int width;
  final int height;
}
