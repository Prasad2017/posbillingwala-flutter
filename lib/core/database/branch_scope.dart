import 'package:shared_preferences/shared_preferences.dart';
import 'package:pos_billingwala_v2/features/auth/domain/session_keys.dart';
import 'package:pos_billingwala_v2/features/auth/domain/user_session.dart';

/// Android [BranchSession] + [LicenceScopeGuard] helpers for Flutter.
class BranchScope {
  BranchScope._();

  static const boundLicenceKey = 'boundLicenceKey';
  static const boundBranchId = 'boundBranchId';

  /// Prefer session.branchId; fall back to licence userId (Android).
  static String effectiveBranchId(UserSession session) {
    final branch = session.branchId?.trim() ?? '';
    if (branch.isNotEmpty) return branch;
    return session.userId.trim();
  }

  /// Prefer organizationId; fall back to ownerId then userId (Android).
  static String effectiveOrganizationId(UserSession session) {
    final org = session.organizationId?.trim() ?? '';
    if (org.isNotEmpty) return org;
    final owner = session.ownerId?.trim() ?? '';
    if (owner.isNotEmpty) return owner;
    return session.userId.trim();
  }

  static Future<({String boundLicence, String boundBranch})> readBound() async {
    final prefs = await SharedPreferences.getInstance();
    return (
      boundLicence: (prefs.getString(boundLicenceKey) ?? '').trim(),
      boundBranch: (prefs.getString(boundBranchId) ?? '').trim(),
    );
  }

  static Future<void> persistBound({
    required String licenceKey,
    required String branchId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (licenceKey.trim().isNotEmpty) {
      await prefs.setString(boundLicenceKey, licenceKey.trim());
    }
    await prefs.setString(boundBranchId, branchId.trim());
  }

  /// Keeps SessionKeys org/branch fields aligned (already in UserSession.toMap).
  static Future<void> mirrorSessionPrefs(UserSession session) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(SessionKeys.branchId, session.branchId ?? '');
    await prefs.setString(SessionKeys.branchLabel, session.branchLabel ?? '');
    await prefs.setString(
      SessionKeys.organizationId,
      session.organizationId ?? '',
    );
  }
}
