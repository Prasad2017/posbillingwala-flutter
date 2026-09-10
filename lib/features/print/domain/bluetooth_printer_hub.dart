import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:pos_billingwala_v2/core/permissions/app_permission_service.dart';

enum PrinterChannelKind { bill, kot }

/// Android-parity Bluetooth printer session manager.
///
/// Mirrors [BluetoothPrinterChannel] in WithTable:
/// - Separate bill / KOT saved MACs
/// - One RFCOMM link via [print_bluetooth_thermal] (plugin is single-connection)
/// - Same MAC for bill+KOT → reuse connection (no second socket)
/// - Different MACs → disconnect then reconnect before write
/// - Skip connect when already linked to the same address
/// - Soft auto-reconnect with backoff after failed writes / disconnects
class BluetoothPrinterHub {
  BluetoothPrinterHub({
    this.permissions = const AppPermissionService(),
  });

  static final BluetoothPrinterHub instance = BluetoothPrinterHub();

  static const _connectWait = Duration(seconds: 12);
  static const _reconnectDelay = Duration(milliseconds: 2500);
  static const _reconnectMaxDelay = Duration(seconds: 30);

  final AppPermissionService permissions;

  String _billAddress = '';
  String _kotAddress = '';
  String _connectedAddress = '';
  bool _connecting = false;
  bool _persistentSession = false;
  Duration _reconnectBackoff = _reconnectDelay;
  Timer? _reconnectTimer;

  String get billAddress => _billAddress;
  String get kotAddress => _kotAddress;
  String get connectedAddress => _connectedAddress;
  bool get isConnecting => _connecting;
  bool get isReady => _connectedAddress.isNotEmpty;

  void updateSavedAddresses({
    required String billMac,
    required String kotMac,
  }) {
    _billAddress = _normalize(billMac);
    _kotAddress = _normalize(kotMac);
  }

  String addressFor(PrinterChannelKind kind) {
    if (kind == PrinterChannelKind.kot) {
      final kot = _kotAddress;
      if (kot.isNotEmpty) return kot;
      return _billAddress;
    }
    return _billAddress;
  }

  Future<bool> isBluetoothOn() async {
    if (kIsWeb || !(Platform.isAndroid || Platform.isIOS)) return false;
    try {
      return PrintBluetoothThermal.bluetoothEnabled;
    } catch (_) {
      return false;
    }
  }

  Future<List<BluetoothInfo>> pairedDevices() async {
    if (kIsWeb || !(Platform.isAndroid || Platform.isIOS)) return const [];
    final allowed = await permissions.ensurePrintPermissions();
    if (!allowed) return const [];
    try {
      return PrintBluetoothThermal.pairedBluetooths;
    } catch (e) {
      debugPrint('pairedDevices failed: $e');
      return const [];
    }
  }

  Future<bool> connectionStatus() async {
    if (kIsWeb || !Platform.isAndroid) return false;
    try {
      final linked = await PrintBluetoothThermal.connectionStatus;
      if (!linked) {
        _connectedAddress = '';
      }
      return linked;
    } catch (_) {
      _connectedAddress = '';
      return false;
    }
  }

  /// Silent auto-connect (Home / Settings load), same as Android autoConnect.
  Future<void> autoConnect(PrinterChannelKind kind) async {
    final mac = addressFor(kind);
    if (mac.isEmpty) return;
    if (!await isBluetoothOn()) return;
    await _connectInternal(mac, fromUser: false);
  }

  /// User-initiated connect (Settings Connect button).
  Future<bool> connect(
    PrinterChannelKind kind, {
    String? address,
    bool fromUser = true,
  }) async {
    final mac = _normalize(address ?? addressFor(kind));
    if (mac.isEmpty) return false;

    if (kind == PrinterChannelKind.bill) {
      _billAddress = mac;
    } else {
      _kotAddress = mac;
    }

    if (!await isBluetoothOn()) return false;

    final allowed = await permissions.ensurePrintPermissions();
    if (!allowed) return false;

    return _connectInternal(mac, fromUser: fromUser);
  }

  Future<void> disconnect(PrinterChannelKind kind) async {
    _cancelReconnect();
    if (kind == PrinterChannelKind.bill) {
      _billAddress = '';
    } else {
      _kotAddress = '';
    }

    // Keep physical link if the other channel still needs the same MAC.
    final other = addressFor(
      kind == PrinterChannelKind.bill
          ? PrinterChannelKind.kot
          : PrinterChannelKind.bill,
    );
    if (other.isNotEmpty &&
        other.toLowerCase() == _connectedAddress.toLowerCase()) {
      _persistentSession = true;
      return;
    }

    _persistentSession = false;
    try {
      await PrintBluetoothThermal.disconnect;
    } catch (_) {}
    _connectedAddress = '';
  }

  /// Ensures the correct printer is connected before a print write (≤12s).
  Future<bool> ensureReady(PrinterChannelKind kind) async {
    final mac = addressFor(kind);
    if (mac.isEmpty) return false;

    final allowed = await permissions.ensurePrintPermissions();
    if (!allowed) return false;
    if (!await isBluetoothOn()) return false;

    if (await _isLinkedTo(mac)) return true;

    final started = await _connectInternal(mac, fromUser: false);
    if (!started && !_connecting) return false;

    final deadline = DateTime.now().add(_connectWait);
    while (DateTime.now().isBefore(deadline)) {
      if (await _isLinkedTo(mac)) return true;
      if (!_connecting && !await _isLinkedTo(mac)) {
        // One more attempt before giving up.
        final retry = await _connectInternal(mac, fromUser: false);
        if (!retry) return await _isLinkedTo(mac);
      }
      await Future<void>.delayed(const Duration(milliseconds: 200));
    }
    return _isLinkedTo(mac);
  }

  Future<bool> write(PrinterChannelKind kind, List<int> bytes) async {
    if (bytes.isEmpty) return false;
    final ready = await ensureReady(kind);
    if (!ready) {
      debugPrint('BT write skipped: printer not ready (${addressFor(kind)})');
      _scheduleReconnect(kind);
      return false;
    }
    try {
      // print_bluetooth_thermal Android expects List<Int>, not Uint8List
      // (Uint8List arrives as typed data and the Kotlin cast returns null → false).
      final payload = List<int>.from(bytes);
      final ok = await PrintBluetoothThermal.writeBytes(payload);
      debugPrint(
        'BT write channel=${kind.name} bytes=${payload.length} ok=$ok '
        'mac=$_connectedAddress',
      );
      if (!ok) {
        _connectedAddress = '';
        _scheduleReconnect(kind);
      } else {
        _cancelReconnect();
        _reconnectBackoff = _reconnectDelay;
        _persistentSession = true;
      }
      return ok;
    } catch (e) {
      debugPrint('BT write failed: $e');
      _connectedAddress = '';
      _scheduleReconnect(kind);
      return false;
    }
  }

  Future<bool> _isLinkedTo(String mac) async {
    final linked = await connectionStatus();
    if (!linked) return false;
    if (_connectedAddress.isEmpty) {
      // Plugin connected but we lost tracked MAC — treat as linked only if
      // caller reconnects explicitly. Force reconnect for safety.
      return false;
    }
    return _connectedAddress.toLowerCase() == mac.toLowerCase();
  }

  Future<bool> _connectInternal(String address, {required bool fromUser}) async {
    final mac = _normalize(address);
    if (mac.isEmpty) return false;

    // Already on the right printer — Android skips reconnect.
    if (await _isLinkedTo(mac)) {
      _persistentSession = true;
      _cancelReconnect();
      _reconnectBackoff = _reconnectDelay;
      return true;
    }

    if (_connecting) {
      // Wait briefly for in-flight connect to the same MAC.
      final deadline = DateTime.now().add(const Duration(seconds: 8));
      while (_connecting && DateTime.now().isBefore(deadline)) {
        await Future<void>.delayed(const Duration(milliseconds: 150));
      }
      if (await _isLinkedTo(mac)) return true;
    }

    _connecting = true;
    try {
      // Plugin is single-socket: drop previous link if MAC differs.
      final currentlyLinked = await PrintBluetoothThermal.connectionStatus;
      if (currentlyLinked) {
        final same = _connectedAddress.toLowerCase() == mac.toLowerCase();
        if (!same) {
          try {
            await PrintBluetoothThermal.disconnect;
          } catch (_) {}
          _connectedAddress = '';
          await Future<void>.delayed(const Duration(milliseconds: 350));
        } else {
          _connectedAddress = mac;
          _persistentSession = true;
          return true;
        }
      }

      final ok = await PrintBluetoothThermal.connect(macPrinterAddress: mac);
      if (ok) {
        _connectedAddress = mac;
        _persistentSession = true;
        _cancelReconnect();
        _reconnectBackoff = _reconnectDelay;
        return true;
      }

      _connectedAddress = '';
      if (_persistentSession || fromUser) {
        _scheduleReconnectForAddress(mac);
      }
      return false;
    } catch (e) {
      debugPrint('BT connect failed: $e');
      _connectedAddress = '';
      _scheduleReconnectForAddress(mac);
      return false;
    } finally {
      _connecting = false;
    }
  }

  void _scheduleReconnect(PrinterChannelKind kind) {
    final mac = addressFor(kind);
    if (mac.isEmpty) return;
    _scheduleReconnectForAddress(mac);
  }

  void _scheduleReconnectForAddress(String mac) {
    if (mac.isEmpty) return;
    _reconnectTimer?.cancel();
    final delay = _reconnectBackoff;
    _reconnectBackoff = Duration(
      milliseconds: (_reconnectBackoff.inMilliseconds * 2)
          .clamp(0, _reconnectMaxDelay.inMilliseconds),
    );
    _reconnectTimer = Timer(delay, () async {
      if (!await isBluetoothOn()) return;
      if (await _isLinkedTo(mac)) return;
      debugPrint('BT auto-reconnect → $mac');
      await _connectInternal(mac, fromUser: false);
    });
  }

  void _cancelReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
  }

  String _normalize(String? value) => value?.trim() ?? '';
}
