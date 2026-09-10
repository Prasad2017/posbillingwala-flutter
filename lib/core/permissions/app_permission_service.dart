import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

/// Runtime permission helper for print / QR / nearby hardware.
class AppPermissionService {
  const AppPermissionService();

  Future<List<Permission>> printPermissions() async {
    if (kIsWeb) return const [];
    if (Platform.isAndroid) {
      final sdk = (await DeviceInfoPlugin().androidInfo).version.sdkInt;
      if (sdk >= 31) {
        // Android 12+: nearby devices + optional location for discovery.
        return const [
          Permission.bluetoothScan,
          Permission.bluetoothConnect,
          Permission.bluetoothAdvertise,
          Permission.locationWhenInUse,
        ];
      }
      // Android 11 and below: classic Bluetooth + location for discovery.
      return const [
        Permission.bluetooth,
        Permission.locationWhenInUse,
        Permission.location,
      ];
    }
    if (Platform.isIOS) {
      return const [
        Permission.bluetooth,
        Permission.locationWhenInUse,
      ];
    }
    return const [];
  }

  /// Full set for Settings / first home open.
  Future<List<Permission>> allRuntimePermissions() async {
    if (kIsWeb) return const [];
    final list = <Permission>[
      ...await printPermissions(),
      Permission.camera,
    ];
    if (Platform.isAndroid) {
      final sdk = (await DeviceInfoPlugin().androidInfo).version.sdkInt;
      if (sdk >= 33) {
        list.add(Permission.notification);
      }
    } else if (Platform.isIOS) {
      list.add(Permission.notification);
    }
    final seen = <Permission>{};
    return list.where(seen.add).toList(growable: false);
  }

  Future<Map<Permission, PermissionStatus>> checkAll() async {
    final result = <Permission, PermissionStatus>{};
    for (final p in await allRuntimePermissions()) {
      result[p] = await p.status;
    }
    return result;
  }

  bool _isAllowed(PermissionStatus status) =>
      status.isGranted || status.isLimited || status.isProvisional;

  Future<bool> ensurePrintPermissions() async {
    final permissions = await printPermissions();
    if (permissions.isEmpty) return true;
    final statuses = await permissions.request();
    return statuses.values.every(_isAllowed);
  }

  Future<bool> ensureCameraPermission() async {
    if (kIsWeb) return true;
    final status = await Permission.camera.request();
    return _isAllowed(status);
  }

  Future<Map<Permission, PermissionStatus>> requestAll() async {
    final permissions = await allRuntimePermissions();
    if (permissions.isEmpty) return const {};
    return permissions.request();
  }

  Future<bool> get arePrintPermissionsGranted async {
    final permissions = await printPermissions();
    if (permissions.isEmpty) return true;
    for (final p in permissions) {
      if (!_isAllowed(await p.status)) return false;
    }
    return true;
  }

  Future<bool> openAppSettingsPage() => openAppSettings();

  String labelFor(Permission permission) {
    switch (permission) {
      case Permission.camera:
        return 'Camera';
      case Permission.location:
      case Permission.locationWhenInUse:
      case Permission.locationAlways:
        return 'Location';
      case Permission.bluetooth:
        return 'Bluetooth';
      case Permission.bluetoothScan:
      case Permission.bluetoothConnect:
      case Permission.bluetoothAdvertise:
        return 'Nearby devices';
      case Permission.notification:
        return 'Notifications';
      default:
        return permission.toString().split('.').last;
    }
  }

  String statusLabel(PermissionStatus status) {
    if (_isAllowed(status)) return 'Allowed';
    if (status.isPermanentlyDenied) return 'Blocked';
    if (status.isRestricted) return 'Restricted';
    if (status.isDenied) return 'Denied';
    return status.toString().split('.').last;
  }
}
