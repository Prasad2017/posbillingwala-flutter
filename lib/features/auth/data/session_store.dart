import 'package:shared_preferences/shared_preferences.dart';
import 'package:pos_billingwala_v2/features/auth/domain/session_keys.dart';
import 'package:pos_billingwala_v2/features/auth/domain/user_session.dart';

class SessionStore {
  Future<UserSession?> readSession() async {
    final prefs = await SharedPreferences.getInstance();
    final licenceKey = prefs.getString(SessionKeys.licenceKey);
    final userId = prefs.getString(SessionKeys.userId);
    final loggedIn = prefs.getString(SessionKeys.userLogin);

    if (licenceKey == null ||
        licenceKey.isEmpty ||
        userId == null ||
        userId.isEmpty ||
        loggedIn != 'UserLoginSuccessful') {
      return null;
    }

    final map = <String, String?>{};
    for (final key in [
      SessionKeys.userId,
      SessionKeys.ownerId,
      SessionKeys.userName,
      SessionKeys.shopName,
      SessionKeys.shopImage,
      SessionKeys.licenceKey,
      SessionKeys.appPin,
      SessionKeys.licenceKeyExpireDate,
      SessionKeys.reportPin,
      SessionKeys.authToken,
      SessionKeys.tokenExpiresAt,
      SessionKeys.fastBilling,
      SessionKeys.takeAway,
      SessionKeys.dineIn,
      SessionKeys.mess,
      SessionKeys.totalSaleData,
      SessionKeys.todaySaleData,
      SessionKeys.licenseType,
      SessionKeys.isTrial,
      SessionKeys.organizationId,
      SessionKeys.branchId,
      SessionKeys.branchLabel,
    ]) {
      map[key] = prefs.getString(key);
    }

    return UserSession.fromMap(map);
  }

  Future<void> saveSession(UserSession session) async {
    final prefs = await SharedPreferences.getInstance();
    final map = session.toMap();
    for (final entry in map.entries) {
      await prefs.setString(entry.key, entry.value);
    }
  }

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  Future<bool> hasStoredLicence() async {
    final prefs = await SharedPreferences.getInstance();
    final key = prefs.getString(SessionKeys.licenceKey);
    return key != null && key.isNotEmpty;
  }

  Future<void> updateAppPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(SessionKeys.appPin, pin);
  }
}
