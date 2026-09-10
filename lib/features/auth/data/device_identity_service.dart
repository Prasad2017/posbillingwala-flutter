import 'dart:io';
import 'dart:math';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DeviceIdentity {
  const DeviceIdentity({
    required this.deviceId,
    required this.deviceName,
  });

  final String deviceId;
  final String deviceName;
}

/// Cross-platform device identity for Android + iOS (and web fallback).
///
/// Does **not** use the Android-only `android_id` package. A stable UUID is
/// persisted when the OS does not expose a reliable hardware id.
class DeviceIdentityService {
  DeviceIdentityService({
    DeviceInfoPlugin? plugin,
    SharedPreferences? prefs,
  })  : _plugin = plugin ?? DeviceInfoPlugin(),
        _prefsOverride = prefs;

  static const _prefsKey = 'pb_device_id_v1';

  final DeviceInfoPlugin _plugin;
  final SharedPreferences? _prefsOverride;

  Future<DeviceIdentity> resolve() async {
    if (kIsWeb) {
      final id = await _persistedOrCreate('web');
      return DeviceIdentity(deviceId: id, deviceName: 'Web Browser');
    }

    if (Platform.isAndroid) {
      final info = await _plugin.androidInfo;
      final raw = info.id.trim();
      final id = raw.isNotEmpty && raw.toLowerCase() != 'unknown'
          ? raw
          : await _persistedOrCreate('android');
      final name = '${info.manufacturer} ${info.model}'.trim();
      return DeviceIdentity(
        deviceId: id,
        deviceName: name.isEmpty ? 'Android Device' : name,
      );
    }

    if (Platform.isIOS) {
      final info = await _plugin.iosInfo;
      final vendor = info.identifierForVendor?.trim();
      final id = (vendor != null && vendor.isNotEmpty)
          ? vendor
          : await _persistedOrCreate('ios');
      final name = '${info.name} ${info.model}'.trim();
      return DeviceIdentity(
        deviceId: id,
        deviceName: name.isEmpty ? 'iOS Device' : name,
      );
    }

    final id = await _persistedOrCreate('device');
    return DeviceIdentity(deviceId: id, deviceName: 'Unknown Device');
  }

  Future<String> _persistedOrCreate(String prefix) async {
    final prefs = _prefsOverride ?? await SharedPreferences.getInstance();
    final existing = prefs.getString(_prefsKey)?.trim();
    if (existing != null && existing.isNotEmpty) return existing;
    final id = '${prefix}_${_randomUuid()}';
    await prefs.setString(_prefsKey, id);
    return id;
  }

  String _randomUuid() {
    final r = Random.secure();
    String hex(int bytes) => List.generate(
          bytes,
          (_) => r.nextInt(256).toRadixString(16).padLeft(2, '0'),
        ).join();
    return '${hex(4)}-${hex(2)}-${hex(2)}-${hex(2)}-${hex(6)}';
  }
}

/// Maps app [DeviceIdentity] to legacy PHP form field names.
///
/// The existing backend still expects `android_device_id` / `androidId` /
/// `android_device_name` even for iOS clients. Prefer calling this helper
/// instead of hard-coding those keys at each call site.
class DeviceApiFields {
  const DeviceApiFields._();

  static Map<String, String> asForm({
    required String deviceId,
    String? deviceName,
    bool includeAndroidIdAlias = true,
    bool includeDeviceIdAlias = true,
    bool includeDeviceName = true,
  }) {
    final map = <String, String>{
      'android_device_id': deviceId,
    };
    if (includeAndroidIdAlias) {
      map['androidId'] = deviceId;
    }
    if (includeDeviceIdAlias) {
      // Forward-compatible / error-log style field used by some PHP endpoints.
      map['device_id'] = deviceId;
    }
    if (includeDeviceName && deviceName != null && deviceName.isNotEmpty) {
      map['android_device_name'] = deviceName;
      map['device_name'] = deviceName;
    }
    return map;
  }
}
