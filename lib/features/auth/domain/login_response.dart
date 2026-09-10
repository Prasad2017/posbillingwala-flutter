class LoginResponse {
  const LoginResponse({
    required this.status,
    this.message,
    this.mpin,
    this.licenceId,
    this.ownerId,
    this.userName,
    this.shopName,
    this.shopImage,
    this.licenceKey,
    this.licenceKeyRegDate,
    this.licenceKeyExpireDate,
    this.fastBilling,
    this.takeAway,
    this.dineIn,
    this.mess,
    this.reportPin,
    this.totalSaleData,
    this.todaySaleData,
    this.licenseType,
    this.isTrial,
    this.trialDays,
    this.trialMaxBills,
    this.trialBillCount,
    this.trialBillsRemaining,
    this.authToken,
    this.tokenExpiresAt,
    this.licensePayload,
    this.licenseSignature,
    this.organizationId,
    this.branchId,
    this.branchLabel,
    this.issuedAt,
    this.offlineGraceUntil,
    this.trialConsumed,
  });

  final String status;
  final String? message;
  final String? mpin;
  final String? licenceId;
  final String? ownerId;
  final String? userName;
  final String? shopName;
  final String? shopImage;
  final String? licenceKey;
  final String? licenceKeyRegDate;
  final String? licenceKeyExpireDate;
  final String? fastBilling;
  final String? takeAway;
  final String? dineIn;
  final String? mess;
  final String? reportPin;
  final String? totalSaleData;
  final String? todaySaleData;
  final String? licenseType;
  final String? isTrial;
  final String? trialDays;
  final String? trialMaxBills;
  final String? trialBillCount;
  final String? trialBillsRemaining;
  final String? authToken;
  final String? tokenExpiresAt;
  final String? licensePayload;
  final String? licenseSignature;
  final String? organizationId;
  final String? branchId;
  final String? branchLabel;
  final String? issuedAt;
  final String? offlineGraceUntil;
  final String? trialConsumed;

  bool get isSuccess => status == '1';

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    String? s(Object? value) => value?.toString();

    return LoginResponse(
      status: s(json['status']) ?? '0',
      message: s(json['message']),
      mpin: s(json['mpin']),
      licenceId: s(json['licenceId']),
      ownerId: s(json['ownerId']),
      userName: s(json['userName']),
      shopName: s(json['shopName']),
      shopImage: s(json['shopImage']),
      licenceKey: s(json['licenceKey']),
      licenceKeyRegDate: s(json['licence_key_reg_date']),
      licenceKeyExpireDate: s(json['licence_key_expire_date']),
      fastBilling: s(json['fastBilling']),
      takeAway: s(json['takeAway']),
      dineIn: s(json['dineIn']),
      mess: s(json['mess']),
      reportPin: s(json['reportPin']),
      totalSaleData: s(json['totalSaleData']),
      todaySaleData: s(json['todaySaleData']),
      licenseType: s(json['licenseType']),
      isTrial: s(json['isTrial']),
      trialDays: s(json['trialDays']),
      trialMaxBills: s(json['trialMaxBills']),
      trialBillCount: s(json['trialBillCount']),
      trialBillsRemaining: s(json['trialBillsRemaining']),
      authToken: s(json['authToken']),
      tokenExpiresAt: s(json['tokenExpiresAt']),
      licensePayload: s(json['licensePayload']),
      licenseSignature: s(json['licenseSignature']),
      organizationId: s(json['organizationId']),
      branchId: s(json['branchId']),
      branchLabel: s(json['branchLabel']),
      issuedAt: s(json['issuedAt']),
      offlineGraceUntil: s(json['offlineGraceUntil']),
      trialConsumed: s(json['trialConsumed']),
    );
  }

  Map<String, dynamic> toJson() => {
        'status': status,
        'message': message,
        'mpin': mpin,
        'licenceId': licenceId,
        'ownerId': ownerId,
        'userName': userName,
        'shopName': shopName,
        'shopImage': shopImage,
        'licenceKey': licenceKey,
        'licence_key_reg_date': licenceKeyRegDate,
        'licence_key_expire_date': licenceKeyExpireDate,
        'fastBilling': fastBilling,
        'takeAway': takeAway,
        'dineIn': dineIn,
        'mess': mess,
        'reportPin': reportPin,
        'totalSaleData': totalSaleData,
        'todaySaleData': todaySaleData,
        'licenseType': licenseType,
        'isTrial': isTrial,
        'trialDays': trialDays,
        'trialMaxBills': trialMaxBills,
        'trialBillCount': trialBillCount,
        'trialBillsRemaining': trialBillsRemaining,
        'authToken': authToken,
        'tokenExpiresAt': tokenExpiresAt,
        'licensePayload': licensePayload,
        'licenseSignature': licenseSignature,
        'organizationId': organizationId,
        'branchId': branchId,
        'branchLabel': branchLabel,
        'issuedAt': issuedAt,
        'offlineGraceUntil': offlineGraceUntil,
        'trialConsumed': trialConsumed,
      };
}

class TrialRegisterResponse {
  const TrialRegisterResponse({
    required this.status,
    this.message,
    this.licenceKey,
    this.mpin,
    this.reportPin,
  });

  final String status;
  final String? message;
  final String? licenceKey;
  final String? mpin;
  final String? reportPin;

  bool get isSuccess => status == '1';

  factory TrialRegisterResponse.fromJson(Map<String, dynamic> json) {
    String? s(Object? value) => value?.toString();
    return TrialRegisterResponse(
      status: s(json['status']) ?? '0',
      message: s(json['message']),
      licenceKey: s(json['licenceKey']),
      mpin: s(json['mpin']),
      reportPin: s(json['reportPin']),
    );
  }

  Map<String, dynamic> toJson() => {
        'status': status,
        'message': message,
        'licenceKey': licenceKey,
        'mpin': mpin,
        'reportPin': reportPin,
      };
}
