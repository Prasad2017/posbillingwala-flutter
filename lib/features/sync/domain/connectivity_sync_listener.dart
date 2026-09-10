import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_billingwala_v2/features/auth/domain/auth_controller.dart';
import 'package:pos_billingwala_v2/features/sync/domain/full_sync_controller.dart';

/// When the device comes back online, push pending offline rows (Android
/// OfflineToNetworkReceiver style).
class ConnectivitySyncListener {
  ConnectivitySyncListener(this._ref);

  final Ref _ref;
  StreamSubscription<List<ConnectivityResult>>? _sub;
  bool _wasOffline = false;
  bool _running = false;

  void start() {
    _sub?.cancel();
    _sub = Connectivity().onConnectivityChanged.listen((results) async {
      final online = results.any(
        (r) =>
            r == ConnectivityResult.mobile ||
            r == ConnectivityResult.wifi ||
            r == ConnectivityResult.ethernet ||
            r == ConnectivityResult.vpn ||
            r == ConnectivityResult.other,
      );
      if (!online) {
        _wasOffline = true;
        return;
      }
      if (!_wasOffline) return;
      _wasOffline = false;
      await _uploadIfLoggedIn();
    });

    // Seed current state.
    Connectivity().checkConnectivity().then((results) {
      final online = results.any(
        (r) =>
            r == ConnectivityResult.mobile ||
            r == ConnectivityResult.wifi ||
            r == ConnectivityResult.ethernet ||
            r == ConnectivityResult.vpn ||
            r == ConnectivityResult.other,
      );
      _wasOffline = !online;
    });
  }

  Future<void> _uploadIfLoggedIn() async {
    if (_running) return;
    final userId = _ref.read(authControllerProvider).session?.userId;
    if (userId == null || userId.isEmpty) return;
    _running = true;
    try {
      debugPrint('Connectivity restored — uploading pending sync…');
      await _ref.read(fullSyncControllerProvider.notifier).uploadAll();
    } catch (e) {
      debugPrint('Auto upload failed: $e');
    } finally {
      _running = false;
    }
  }

  void dispose() {
    _sub?.cancel();
    _sub = null;
  }
}

final connectivitySyncListenerProvider = Provider<ConnectivitySyncListener>((
  ref,
) {
  final listener = ConnectivitySyncListener(ref);
  listener.start();
  ref.onDispose(listener.dispose);
  return listener;
});
