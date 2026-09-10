import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:unified_esc_pos_printer/unified_esc_pos_printer.dart';

/// USB (+ optional BLE) ESC/POS connection via [PrinterManager].
/// Works with generic USB Printer Class (0x07) and USB-serial chips
/// (FTDI / CP210x / PL2303 / CH34x) — any ESC/POS thermal model.
class EscPosTransportHub {
  EscPosTransportHub({PrinterManager? manager})
      : _manager = manager ?? PrinterManager();

  static final EscPosTransportHub instance = EscPosTransportHub();

  final PrinterManager _manager;
  PrinterDevice? _connected;
  String _savedUsbId = '';
  String _savedUsbName = '';

  PrinterDevice? get connectedDevice => _connected;
  bool get isConnected => _manager.isConnected;
  String get savedUsbId => _savedUsbId;
  String get savedUsbName => _savedUsbName;

  void updateSavedUsb({required String identifier, String name = ''}) {
    _savedUsbId = identifier.trim();
    _savedUsbName = name.trim();
  }

  Future<List<PrinterDevice>> scanUsb({
    Duration timeout = const Duration(seconds: 4),
  }) async {
    if (kIsWeb || !(Platform.isAndroid || Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      return const [];
    }
    try {
      return _manager.scanPrinters(
        timeout: timeout,
        types: const {PrinterConnectionType.usb},
      );
    } catch (e) {
      debugPrint('USB scan failed: $e');
      return const [];
    }
  }

  Future<List<PrinterDevice>> scanBle({
    Duration timeout = const Duration(seconds: 5),
  }) async {
    if (kIsWeb) return const [];
    try {
      return _manager.scanPrinters(
        timeout: timeout,
        types: const {PrinterConnectionType.ble},
      );
    } catch (e) {
      debugPrint('BLE scan failed: $e');
      return const [];
    }
  }

  Future<bool> connectUsb({
    required String identifier,
    String name = '',
  }) async {
    final id = identifier.trim();
    if (id.isEmpty) return false;
    _savedUsbId = id;
    if (name.trim().isNotEmpty) _savedUsbName = name.trim();

    final platform = Platform.isAndroid ? UsbPlatform.android : UsbPlatform.desktop;
    final device = UsbPrinterDevice(
      name: _savedUsbName.isEmpty ? 'USB Printer' : _savedUsbName,
      identifier: id,
      usbPlatform: platform,
    );
    return _connect(device);
  }

  Future<bool> connectDevice(PrinterDevice device) async {
    if (device is UsbPrinterDevice) {
      _savedUsbId = device.identifier;
      _savedUsbName = device.name;
    }
    return _connect(device);
  }

  Future<bool> ensureUsbReady() async {
    if (_savedUsbId.isEmpty) return false;
    if (_manager.isConnected &&
        _connected is UsbPrinterDevice &&
        (_connected as UsbPrinterDevice).identifier == _savedUsbId) {
      return true;
    }
    return connectUsb(identifier: _savedUsbId, name: _savedUsbName);
  }

  Future<bool> writeBytes(List<int> bytes) async {
    if (bytes.isEmpty) return false;
    try {
      if (!_manager.isConnected) {
        final ok = await ensureUsbReady();
        if (!ok) return false;
      }
      await _manager.printBytes(bytes);
      return true;
    } catch (e) {
      debugPrint('USB/BLE write failed: $e');
      try {
        await _manager.disconnect();
      } catch (_) {}
      _connected = null;
      return false;
    }
  }

  Future<void> disconnect() async {
    try {
      await _manager.disconnect();
    } catch (_) {}
    _connected = null;
  }

  Future<void> clearSavedUsb() async {
    _savedUsbId = '';
    _savedUsbName = '';
    await disconnect();
  }

  Future<bool> _connect(PrinterDevice device) async {
    try {
      await _manager.connect(device);
      _connected = device;
      return true;
    } catch (e) {
      debugPrint('Printer connect failed: $e');
      _connected = null;
      return false;
    }
  }

  void dispose() {
    _manager.dispose();
  }
}
