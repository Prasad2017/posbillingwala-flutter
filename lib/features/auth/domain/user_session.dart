import 'package:pos_billingwala_v2/features/auth/domain/login_response.dart';
import 'package:pos_billingwala_v2/features/auth/domain/session_keys.dart';

class UserSession {
  const UserSession({
    required this.userId,
    required this.licenceKey,
    this.ownerId,
    this.userName,
    this.shopName,
    this.shopImage,
    this.appPin,
    this.licenceKeyExpireDate,
    this.reportPin,
    this.authToken,
    this.tokenExpiresAt,
    this.fastBilling = false,
    this.takeAway = false,
    this.dineIn = false,
    this.mess = false,
    this.totalSaleData = false,
    this.todaySaleData = false,
    this.licenseType,
    this.isTrial = false,
    this.organizationId,
    this.branchId,
    this.branchLabel,
  });

  final String userId;
  final String licenceKey;
  final String? ownerId;
  final String? userName;
  final String? shopName;
  final String? shopImage;
  final String? appPin;
  final String? licenceKeyExpireDate;
  final String? reportPin;
  final String? authToken;
  final String? tokenExpiresAt;
  final bool fastBilling;
  final bool takeAway;
  final bool dineIn;
  final bool mess;
  final bool totalSaleData;
  final bool todaySaleData;
  final String? licenseType;
  final bool isTrial;
  final String? organizationId;
  final String? branchId;
  final String? branchLabel;

  String get displayName =>
      (shopName?.trim().isNotEmpty ?? false) ? shopName!.trim() : 'POS Billingwala';

  factory UserSession.fromLogin(LoginResponse response) {
    bool flag(String? value) => value == '1' || value?.toLowerCase() == 'true';

    return UserSession(
      userId: response.licenceId ?? '',
      licenceKey: response.licenceKey ?? '',
      ownerId: response.ownerId,
      userName: response.userName,
      shopName: response.shopName,
      shopImage: response.shopImage,
      appPin: response.mpin,
      licenceKeyExpireDate: response.licenceKeyExpireDate,
      reportPin: response.reportPin,
      authToken: response.authToken,
      tokenExpiresAt: response.tokenExpiresAt,
      fastBilling: flag(response.fastBilling),
      takeAway: flag(response.takeAway),
      dineIn: flag(response.dineIn),
      mess: flag(response.mess),
      totalSaleData: flag(response.totalSaleData),
      todaySaleData: flag(response.todaySaleData),
      licenseType: response.licenseType,
      isTrial: flag(response.isTrial),
      organizationId: response.organizationId,
      branchId: response.branchId,
      branchLabel: response.branchLabel,
    );
  }

  factory UserSession.fromMap(Map<String, String?> map) {
    bool flag(String? value) => value == '1' || value?.toLowerCase() == 'true';

    return UserSession(
      userId: map[SessionKeys.userId] ?? '',
      licenceKey: map[SessionKeys.licenceKey] ?? '',
      ownerId: map[SessionKeys.ownerId],
      userName: map[SessionKeys.userName],
      shopName: map[SessionKeys.shopName],
      shopImage: map[SessionKeys.shopImage],
      appPin: map[SessionKeys.appPin],
      licenceKeyExpireDate: map[SessionKeys.licenceKeyExpireDate],
      reportPin: map[SessionKeys.reportPin],
      authToken: map[SessionKeys.authToken],
      tokenExpiresAt: map[SessionKeys.tokenExpiresAt],
      fastBilling: flag(map[SessionKeys.fastBilling]),
      takeAway: flag(map[SessionKeys.takeAway]),
      dineIn: flag(map[SessionKeys.dineIn]),
      mess: flag(map[SessionKeys.mess]),
      totalSaleData: flag(map[SessionKeys.totalSaleData]),
      todaySaleData: flag(map[SessionKeys.todaySaleData]),
      licenseType: map[SessionKeys.licenseType],
      isTrial: flag(map[SessionKeys.isTrial]),
      organizationId: map[SessionKeys.organizationId],
      branchId: map[SessionKeys.branchId],
      branchLabel: map[SessionKeys.branchLabel],
    );
  }

  Map<String, String> toMap() {
    String yn(bool value) => value ? '1' : '0';

    return {
      SessionKeys.userLogin: 'UserLoginSuccessful',
      SessionKeys.firstLogin: 'firstLogin',
      SessionKeys.userId: userId,
      SessionKeys.ownerId: ownerId ?? '',
      SessionKeys.userName: userName ?? '',
      SessionKeys.shopName: shopName ?? '',
      SessionKeys.shopImage: shopImage ?? '',
      SessionKeys.licenceKey: licenceKey,
      SessionKeys.appPin: appPin ?? '',
      SessionKeys.licenceKeyExpireDate: licenceKeyExpireDate ?? '',
      SessionKeys.reportPin: reportPin ?? '',
      SessionKeys.authToken: authToken ?? '',
      SessionKeys.tokenExpiresAt: tokenExpiresAt ?? '',
      SessionKeys.fastBilling: yn(fastBilling),
      SessionKeys.takeAway: yn(takeAway),
      SessionKeys.dineIn: yn(dineIn),
      SessionKeys.mess: yn(mess),
      SessionKeys.totalSaleData: yn(totalSaleData),
      SessionKeys.todaySaleData: yn(todaySaleData),
      SessionKeys.licenseType: licenseType ?? '',
      SessionKeys.isTrial: yn(isTrial),
      SessionKeys.organizationId: organizationId ?? '',
      SessionKeys.branchId: branchId ?? '',
      SessionKeys.branchLabel: branchLabel ?? '',
    };
  }

  UserSession copyWith({
    String? userId,
    String? licenceKey,
    String? ownerId,
    String? userName,
    String? shopName,
    String? shopImage,
    String? appPin,
    String? licenceKeyExpireDate,
    String? reportPin,
    String? authToken,
    String? tokenExpiresAt,
    bool? fastBilling,
    bool? takeAway,
    bool? dineIn,
    bool? mess,
    bool? totalSaleData,
    bool? todaySaleData,
    String? licenseType,
    bool? isTrial,
    String? organizationId,
    String? branchId,
    String? branchLabel,
  }) {
    return UserSession(
      userId: userId ?? this.userId,
      licenceKey: licenceKey ?? this.licenceKey,
      ownerId: ownerId ?? this.ownerId,
      userName: userName ?? this.userName,
      shopName: shopName ?? this.shopName,
      shopImage: shopImage ?? this.shopImage,
      appPin: appPin ?? this.appPin,
      licenceKeyExpireDate: licenceKeyExpireDate ?? this.licenceKeyExpireDate,
      reportPin: reportPin ?? this.reportPin,
      authToken: authToken ?? this.authToken,
      tokenExpiresAt: tokenExpiresAt ?? this.tokenExpiresAt,
      fastBilling: fastBilling ?? this.fastBilling,
      takeAway: takeAway ?? this.takeAway,
      dineIn: dineIn ?? this.dineIn,
      mess: mess ?? this.mess,
      totalSaleData: totalSaleData ?? this.totalSaleData,
      todaySaleData: todaySaleData ?? this.todaySaleData,
      licenseType: licenseType ?? this.licenseType,
      isTrial: isTrial ?? this.isTrial,
      organizationId: organizationId ?? this.organizationId,
      branchId: branchId ?? this.branchId,
      branchLabel: branchLabel ?? this.branchLabel,
    );
  }
}
