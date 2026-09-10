import 'package:pos_billingwala_v2/features/auth/data/auth_api.dart';
import 'package:pos_billingwala_v2/features/auth/data/device_identity_service.dart';
import 'package:pos_billingwala_v2/features/auth/data/session_store.dart';
import 'package:pos_billingwala_v2/features/auth/domain/license_validator.dart';
import 'package:pos_billingwala_v2/features/auth/domain/login_response.dart';
import 'package:pos_billingwala_v2/features/auth/domain/user_session.dart';

enum DeviceConflictAction { cancel, rebind }

class AuthException implements Exception {
  AuthException(this.message, {this.needsDeviceConfirm = false});

  final String message;
  final bool needsDeviceConfirm;

  @override
  String toString() => message;
}

class AuthRepository {
  AuthRepository({
    required this._api,
    required this._sessionStore,
    required this._deviceIdentityService,
  });

  final AuthApi _api;
  final SessionStore _sessionStore;
  final DeviceIdentityService _deviceIdentityService;

  Future<UserSession?> readStoredSession() => _sessionStore.readSession();

  Future<void> clearSession({String? licenceKey}) async {
    if (licenceKey != null && licenceKey.isNotEmpty) {
      try {
        await _api.serverLogout(licenceKey: licenceKey);
      } catch (_) {
        // Local logout still proceeds if network fails.
      }
    }
    await _sessionStore.clearSession();
  }

  /// Licence-key login matching Android Login.java flow.
  Future<UserSession> loginWithLicence({
    required String licenceKey,
    Future<DeviceConflictAction> Function(String message)? onDeviceConflict,
  }) async {
    final device = await _deviceIdentityService.resolve();
    final key = licenceKey.trim();
    if (key.isEmpty) {
      throw AuthException('Please enter your licence key');
    }

    var check = await _api.loginCheck(licenceKey: key, deviceId: device.deviceId);

    if (check.status == '2') {
      final rebound = await _api.updateLicenceKey(
        licenceKey: key,
        deviceId: device.deviceId,
        deviceName: device.deviceName,
      );
      if (!rebound.isSuccess) {
        throw AuthException(rebound.message ?? 'Unable to bind this device');
      }
      check = await _api.loginCheck(licenceKey: key, deviceId: device.deviceId);
    } else if (check.status == '3') {
      final action = onDeviceConflict == null
          ? DeviceConflictAction.cancel
          : await onDeviceConflict(
              check.message ??
                  'This licence is already registered on another device. Bind it to this device?',
            );
      if (action != DeviceConflictAction.rebind) {
        throw AuthException('Device binding cancelled');
      }
      final rebound = await _api.updateLicenceKey(
        licenceKey: key,
        deviceId: device.deviceId,
        deviceName: device.deviceName,
      );
      if (!rebound.isSuccess) {
        throw AuthException(rebound.message ?? 'Unable to bind this device');
      }
      check = await _api.loginCheck(licenceKey: key, deviceId: device.deviceId);
    }

    if (check.status == '0') {
      throw AuthException(check.message ?? 'Invalid licence key');
    }
    if (!check.isSuccess || (check.licenceId?.isEmpty ?? true)) {
      throw AuthException(check.message ?? 'Login failed');
    }

    final expire = await _api.checkLicenceExpire(
      userId: check.licenceId!,
      deviceId: device.deviceId,
      deviceName: device.deviceName,
    );
    if (!expire.isSuccess) {
      throw AuthException(expire.message ?? 'Licence check failed');
    }
    if (!_isLicenceValid(expire.licenceKeyExpireDate)) {
      throw AuthException('Your licence has expired. Please renew to continue.');
    }

    final session = UserSession.fromLogin(expire);
    if (session.userId.isEmpty || session.licenceKey.isEmpty) {
      throw AuthException('Incomplete licence data from server');
    }
    await _sessionStore.saveSession(session);
    await LicenseValidator.saveFromLogin(
      licensePayload: expire.licensePayload,
      licenseSignature: expire.licenseSignature,
      issuedAt: expire.issuedAt,
      offlineGraceUntil: expire.offlineGraceUntil,
      trialConsumed: expire.trialConsumed,
      organizationId: expire.organizationId,
      branchId: expire.branchId,
      branchLabel: expire.branchLabel,
      deviceId: device.deviceId,
    );
    await _assertSignedLicense(
      deviceId: device.deviceId,
      licenceKey: session.licenceKey,
    );
    return session;
  }

  /// MPIN unlock matching Android LoginMPin.java flow.
  Future<UserSession> loginWithMpin({
    required String mpin,
    Future<DeviceConflictAction> Function(String message)? onDeviceConflict,
  }) async {
    final stored = await _sessionStore.readSession();
    if (stored == null) {
      throw AuthException('No licence found. Please login with licence key.');
    }

    final device = await _deviceIdentityService.resolve();
    final pin = mpin.trim();
    if (pin.length != 4) {
      throw AuthException('Enter your 4-digit PB-PIN');
    }

    Future<LoginResponse> attempt() {
      return _api.loginMpin(
        mpin: pin,
        licenceKey: stored.licenceKey,
        deviceId: device.deviceId,
        deviceName: device.deviceName,
      );
    }

    var response = await attempt();

    if (response.status == '3') {
      final action = onDeviceConflict == null
          ? DeviceConflictAction.cancel
          : await onDeviceConflict(
              response.message ??
                  'This licence is already registered on another device. Bind it to this device?',
            );
      if (action != DeviceConflictAction.rebind) {
        throw AuthException('Device binding cancelled');
      }

      final rebound = await _api.updateLicenceKey(
        licenceKey: stored.licenceKey,
        deviceId: device.deviceId,
        deviceName: device.deviceName,
      );
      if (!rebound.isSuccess) {
        throw AuthException(rebound.message ?? 'Unable to bind this device');
      }

      await _api.updateMpin(
        mpin: pin,
        licenceKey: stored.licenceKey,
        deviceId: device.deviceId,
        deviceName: device.deviceName,
      );
      response = await attempt();
    }

    if (!response.isSuccess) {
      throw AuthException(response.message ?? 'Invalid PB-PIN');
    }
    if (!_isLicenceValid(response.licenceKeyExpireDate)) {
      throw AuthException('Your licence has expired. Please renew to continue.');
    }

    final session = UserSession.fromLogin(response);
    await _sessionStore.saveSession(session);
    await LicenseValidator.saveFromLogin(
      licensePayload: response.licensePayload,
      licenseSignature: response.licenseSignature,
      issuedAt: response.issuedAt,
      offlineGraceUntil: response.offlineGraceUntil,
      trialConsumed: response.trialConsumed,
      organizationId: response.organizationId,
      branchId: response.branchId,
      branchLabel: response.branchLabel,
      deviceId: device.deviceId,
    );
    await _assertSignedLicense(
      deviceId: device.deviceId,
      licenceKey: session.licenceKey,
    );
    return session;
  }

  Future<void> _assertSignedLicense({
    required String deviceId,
    required String licenceKey,
  }) async {
    if (!await LicenseValidator.hasStoredPayload()) return;
    final result = await LicenseValidator.validate(
      deviceId: deviceId,
      licenceKey: licenceKey,
      localInvoiceCount: 0,
    );
    if (!result.valid) {
      throw AuthException(result.message.isEmpty
          ? 'Licence validation failed'
          : result.message);
    }
  }

  Future<TrialRegisterResponse> registerTrial({
    required String name,
    required String contactNumber,
    required String address,
    required String shopName,
  }) {
    return _api.registerTrial(
      name: name.trim(),
      contactNumber: contactNumber.trim(),
      address: address.trim(),
      shopName: shopName.trim(),
    );
  }

  bool _isLicenceValid(String? expireDate) {
    if (expireDate == null || expireDate.isEmpty) return false;
    try {
      final end = DateTime.parse(expireDate);
      final today = DateTime.now();
      final todayDate = DateTime(today.year, today.month, today.day);
      final endDate = DateTime(end.year, end.month, end.day);
      return !endDate.isBefore(todayDate);
    } catch (_) {
      return false;
    }
  }
}
