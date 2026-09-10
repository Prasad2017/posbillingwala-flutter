import 'dart:typed_data';

/// ESC/POS raster encoder matching Android [PrintImage] (GS v 0 + Floyd–Steinberg).
class PrintImageEncoder {
  /// [rgba] is raw RGBA bytes from [ui.ImageByteFormat.rawRgba].
  /// [brightValue] matches Android default `128`.
  static List<int> encodeRgba({
    required Uint8List rgba,
    required int width,
    required int height,
    int brightValue = 128,
  }) {
    var w = width;
    var h = height;
    if (w <= 0 || h <= 0) return const [];

    // Match Android: cap at 576px and force width divisible by 8.
    if (w > 576) {
      final scale = 576 / w;
      // Caller should already resize; still clamp bytes width expectation.
      w = 576;
      h = (h * scale).floor();
    }
    w = (w ~/ 8) * 8;
    if (w <= 0) return const [];

    final pixels = List<int>.filled(w * h, 0xffffffff);
    for (var y = 0; y < h; y++) {
      for (var x = 0; x < w; x++) {
        final srcX = x < width ? x : width - 1;
        final srcY = y < height ? y : height - 1;
        final i = (srcY * width + srcX) * 4;
        if (i + 2 >= rgba.length) continue;
        final r = rgba[i];
        final g = rgba[i + 1];
        final b = rgba[i + 2];
        // Pack as ARGB-style luminance source; dither expects channel access.
        pixels[y * w + x] = (0xff << 24) | (r << 16) | (g << 8) | b;
      }
    }

    _floydSteinberg(pixels, w, h, brightValue);

    final out = BytesBuilder();
    final widthBytes = w ~/ 8;
    final wl = widthBytes % 256;
    final wh = widthBytes ~/ 256;
    final hl = h % 256;
    final hh = h ~/ 256;
    // ESC/POS: GS v 0 m xL xH yL yH
    out.add([0x1d, 0x76, 0x30, 0x00, wl, wh, hl, hh]);

    for (var y = 0; y < h; y++) {
      for (var xByte = 0; xByte < widthBytes; xByte++) {
        var printByte = 0;
        for (var bit = 0; bit < 8; bit++) {
          printByte <<= 1;
          final pixel = pixels[(xByte * 8) + bit + y * w];
          // Android treats pure black (0xff000000) as print-dot.
          if ((pixel & 0x00ffffff) == 0) {
            printByte |= 1;
          }
        }
        out.addByte(printByte);
      }
    }
    return out.toBytes();
  }

  static void _floydSteinberg(
    List<int> pixels,
    int bmWidth,
    int bmHeight,
    int brightValue,
  ) {
    final bright = brightValue - 128;
    final w = bmWidth + 1;
    final h = bmHeight + 1;
    final tab = List<int>.filled(w * h, 0);

    for (var y = 0; y < h - 1; y++) {
      for (var x = 0; x < w - 1; x++) {
        if (x == w - 1 || y == h - 1) {
          tab[x + w * y] = 0;
        } else {
          final pixel = pixels[x + y * bmWidth];
          final r = (pixel >> 16) & 0xff;
          final g = (pixel >> 8) & 0xff;
          final b = pixel & 0xff;
          // Same weights as Android PrintImage (note: blue/green swapped vs classic BT.601).
          final l = ((76 * r + 151 * b + 29 * g) ~/ 256) + bright;
          tab[x + w * y] = l;
        }
      }
    }

    for (var y = 0; y < h - 2; y++) {
      for (var x = 0; x < w - 2; x++) {
        final offset = x + y * w;
        var gc = tab[offset];
        final g = gc < 128 ? 0 : 255;
        gc = gc - g;
        tab[offset] = g;
        tab[offset + 1] = tab[offset + 1] + gc * 7 ~/ 16;
        tab[offset - 1 + w] = tab[offset - 1 + w] + gc * 3 ~/ 16;
        tab[offset + w] = tab[offset + w] + gc * 5 ~/ 16;
        tab[offset + 1 + w] = tab[offset + 1 + w] + gc ~/ 16;
      }
    }

    for (var y = 0; y < h - 1; y++) {
      for (var x = 0; x < w - 1; x++) {
        pixels[x + y * bmWidth] =
            tab[x + w * y] == 0 ? 0xff000000 : 0xffffffff;
      }
    }
  }
}
