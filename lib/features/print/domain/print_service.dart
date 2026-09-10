import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:pos_billingwala_v2/core/database/app_database.dart';
import 'package:pos_billingwala_v2/features/print/domain/bluetooth_printer_hub.dart';
import 'package:pos_billingwala_v2/features/print/domain/esc_pos_transport_hub.dart';
import 'package:pos_billingwala_v2/features/print/domain/printer_settings.dart';
import 'package:pos_billingwala_v2/features/print/domain/receipt_builder.dart';
import 'package:pos_billingwala_v2/features/print/domain/sample_receipt_data.dart';
import 'package:pos_billingwala_v2/features/print/domain/shop_receipt_profile.dart';
import 'package:share_plus/share_plus.dart';

enum PrintOutcome {
  bluetoothPrinted,
  usbPrinted,
  networkPrinted,
  shared,
  previewOnly,
  failed,
}

class PrintResult {
  const PrintResult({
    required this.outcome,
    required this.text,
    this.message,
  });

  final PrintOutcome outcome;
  final String text;
  final String? message;
}

/// Routes ESC/POS raster bytes to Bluetooth, USB, or Network.
/// Any ESC/POS thermal model is supported (bitmap path is brand-agnostic).
class PrintService {
  PrintService(
    this.settings, {
    this.shopProfile = const ShopReceiptProfile(),
    BluetoothPrinterHub? hub,
    EscPosTransportHub? usbHub,
  })  : hub = hub ?? BluetoothPrinterHub.instance,
        usbHub = usbHub ?? EscPosTransportHub.instance;

  final PrinterSettings settings;
  final BluetoothPrinterHub hub;
  final EscPosTransportHub usbHub;
  final ShopReceiptProfile shopProfile;

  ReceiptBuilder get _builder =>
      ReceiptBuilder(settings, shopProfile: shopProfile);

  Future<PrintResult> printBill({
    required Invoice invoice,
    required List<InvoiceItem> items,
    String? shopName,
    bool preferShare = false,
    bool duplicate = false,
  }) async {
    _syncSavedEndpoints(isKot: false);
    final text = _builder.billText(
      invoice: invoice,
      items: items,
      shopName: shopName,
      duplicate: duplicate,
    );
    final bytes = await _builder.billPrintBytes(
      invoice: invoice,
      items: items,
      shopName: shopName,
      duplicate: duplicate,
    );
    return _dispatch(
      text: text,
      bytes: bytes,
      channel: PrinterChannelKind.bill,
      preferShare: preferShare,
      label: duplicate ? 'Duplicate bill' : 'Bill',
    );
  }

  Future<PrintResult> printKot(
    KotTicket ticket, {
    bool preferShare = false,
  }) async {
    _syncSavedEndpoints(isKot: true);
    final text = _builder.kotText(ticket);
    final bytes = await _builder.kotPrintBytes(ticket);
    return _dispatch(
      text: text,
      bytes: bytes,
      channel: PrinterChannelKind.kot,
      preferShare: preferShare,
      label: 'KOT',
    );
  }

  /// Sample invoice / KOT (same lines as Android printer-settings test).
  Future<PrintResult> printTest(PrinterChannelKind channel, {String? shopName}) {
    if (channel == PrinterChannelKind.kot) {
      return printKot(SampleReceiptData.sampleKot());
    }
    final sample = SampleReceiptData.sampleBill();
    return printBill(
      invoice: sample.invoice,
      items: sample.items,
      shopName: shopName,
    );
  }

  String previewText(PrinterChannelKind channel, {String? shopName}) {
    if (channel == PrinterChannelKind.kot) {
      return _builder.kotText(SampleReceiptData.sampleKot());
    }
    final sample = SampleReceiptData.sampleBill();
    return _builder.billText(
      invoice: sample.invoice,
      items: sample.items,
      shopName: shopName,
    );
  }

  Future<PrintResult> printRawText(
    String text, {
    PrinterChannelKind channel = PrinterChannelKind.bill,
    bool preferShare = false,
    String label = 'Receipt',
  }) async {
    _syncSavedEndpoints(isKot: channel == PrinterChannelKind.kot);
    final bytes = await _builder.rawPrintBytes(text);
    return _dispatch(
      text: text,
      bytes: bytes,
      channel: channel,
      preferShare: preferShare,
      label: label,
    );
  }

  void _syncSavedEndpoints({required bool isKot}) {
    hub.updateSavedAddresses(
      billMac: settings.billBluetoothAddress,
      kotMac: settings.kotBluetoothAddress,
    );
    usbHub.updateSavedUsb(
      identifier: settings.usbIdFor(isKot: isKot),
      name: settings.usbNameFor(isKot: isKot),
    );
  }

  Future<bool> _printNetwork(List<int> bytes) async {
    final host = settings.networkHost.trim();
    if (host.isEmpty) return false;
    final port = settings.networkPort <= 0 ? 9100 : settings.networkPort;
    Socket? socket;
    try {
      socket = await Socket.connect(
        host,
        port,
        timeout: const Duration(seconds: 5),
      );
      socket.add(bytes);
      await socket.flush();
      return true;
    } finally {
      await socket?.close();
    }
  }

  Future<PrintResult> _dispatch({
    required String text,
    required List<int> bytes,
    required PrinterChannelKind channel,
    required bool preferShare,
    required String label,
  }) async {
    if (!preferShare && !kIsWeb) {
      final isKot = channel == PrinterChannelKind.kot;
      final transport = settings.transportFor(isKot: isKot);

      // Preferred transport for this channel.
      final preferred = await _tryTransport(
        transport: transport,
        channel: channel,
        isKot: isKot,
        bytes: bytes,
        text: text,
        label: label,
      );
      if (preferred != null) return preferred;

      // Fallbacks so a misconfigured type still prints if another path works.
      for (final alt in PosPrinterTransport.values) {
        if (alt == transport) continue;
        final result = await _tryTransport(
          transport: alt,
          channel: channel,
          isKot: isKot,
          bytes: bytes,
          text: text,
          label: label,
        );
        if (result != null) return result;
      }

      return PrintResult(
        outcome: PrintOutcome.failed,
        text: text,
        message: '$label failed — printer not reachable',
      );
    }

    await SharePlus.instance.share(
      ShareParams(text: text, subject: label),
    );
    return PrintResult(
      outcome: PrintOutcome.shared,
      text: text,
      message: '$label shared (no printer available)',
    );
  }

  Future<PrintResult?> _tryTransport({
    required PosPrinterTransport transport,
    required PrinterChannelKind channel,
    required bool isKot,
    required List<int> bytes,
    required String text,
    required String label,
  }) async {
    try {
      switch (transport) {
        case PosPrinterTransport.bluetooth:
          if (!Platform.isAndroid && !Platform.isIOS) return null;
          final mac = settings.bluetoothFor(isKot: isKot);
          if (mac.isEmpty) return null;
          hub.updateSavedAddresses(
            billMac: settings.billBluetoothAddress,
            kotMac: settings.kotBluetoothAddress,
          );
          final sent = await hub.write(channel, bytes);
          if (!sent) return null;
          return PrintResult(
            outcome: PrintOutcome.bluetoothPrinted,
            text: text,
            message: '$label sent to Bluetooth printer',
          );

        case PosPrinterTransport.usb:
          if (!(Platform.isAndroid ||
              Platform.isWindows ||
              Platform.isLinux ||
              Platform.isMacOS)) {
            return null;
          }
          final id = settings.usbIdFor(isKot: isKot);
          if (id.isEmpty) return null;
          usbHub.updateSavedUsb(
            identifier: id,
            name: settings.usbNameFor(isKot: isKot),
          );
          final sent = await usbHub.writeBytes(bytes);
          if (!sent) return null;
          return PrintResult(
            outcome: PrintOutcome.usbPrinted,
            text: text,
            message: '$label sent to USB printer',
          );

        case PosPrinterTransport.network:
          if (settings.networkHost.trim().isEmpty) return null;
          final ok = await _printNetwork(bytes);
          if (!ok) return null;
          return PrintResult(
            outcome: PrintOutcome.networkPrinted,
            text: text,
            message:
                '$label sent to ${settings.networkHost}:${settings.networkPort}',
          );
      }
    } catch (e) {
      debugPrint('Transport $transport failed: $e');
      return null;
    }
  }
}
