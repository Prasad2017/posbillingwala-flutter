import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:asn1lib/asn1lib.dart';
import 'package:pointycastle/export.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pos_billingwala_v2/features/auth/domain/session_keys.dart';

/// Offline RSA licence validation (Android [LicenseValidator] parity).
class LicenseValidator {
  LicenseValidator._();

  static const _payloadKey = 'licensePayload';
  static const _signatureKey = 'licenseSignature';
  static const _lastServerTimeKey = 'licenseLastServerTimeMs';
  static const _clockToleranceMs = 24 * 60 * 60 * 1000;

  static Future<void> saveFromLogin({
    required String? licensePayload,
    required String? licenseSignature,
    required String? issuedAt,
    required String? offlineGraceUntil,
    required String? trialConsumed,
    required String? organizationId,
    required String? branchId,
    required String? branchLabel,
    required String deviceId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_payloadKey, licensePayload?.trim() ?? '');
    await prefs.setString(_signatureKey, licenseSignature?.trim() ?? '');
    await prefs.setString(SessionKeys.organizationId, organizationId ?? '');
    await prefs.setString(SessionKeys.branchId, branchId ?? '');
    await prefs.setString(SessionKeys.branchLabel, branchLabel ?? '');
    await prefs.setString('deviceId', deviceId);
    await prefs.setString('issuedAt', issuedAt ?? '');
    await prefs.setString('offlineGraceUntil', offlineGraceUntil ?? '');
    await prefs.setString('trialConsumed', trialConsumed ?? '');

    final issuedSec = int.tryParse(issuedAt?.trim() ?? '') ?? 0;
    if (issuedSec > 0) {
      final issuedMs = issuedSec * 1000;
      final last = int.tryParse(prefs.getString(_lastServerTimeKey) ?? '') ?? 0;
      if (issuedMs > last) {
        await prefs.setString(_lastServerTimeKey, '$issuedMs');
      }
    }

    await _persistModulesFromPayload(prefs, licensePayload);
  }

  static Future<bool> hasStoredPayload() async {
    final prefs = await SharedPreferences.getInstance();
    final p = prefs.getString(_payloadKey)?.trim() ?? '';
    final s = prefs.getString(_signatureKey)?.trim() ?? '';
    return p.isNotEmpty && s.isNotEmpty;
  }

  static Future<LicenseValidationResult> validate({
    required String deviceId,
    required String licenceKey,
    required int localInvoiceCount,
  }) async {
    final result = LicenseValidationResult();
    final prefs = await SharedPreferences.getInstance();

    if (!await hasStoredPayload()) {
      // No signed payload yet — fall back to expiry-date login (legacy).
      result.valid = true;
      result.message = '';
      result.legacyFallback = true;
      return result;
    }

    final payload = await verifyAndParse(prefs);
    if (payload == null) {
      result.message = 'Licence signature invalid. Please login again.';
      return result;
    }

    if (payload.deviceId.isNotEmpty && payload.deviceId != deviceId) {
      result.message = 'Licence is bound to another device.';
      return result;
    }

    if (licenceKey.isNotEmpty &&
        payload.licenseKey.isNotEmpty &&
        licenceKey != payload.licenseKey) {
      result.message = 'Licence key mismatch.';
      return result;
    }

    final trustedNow = _trustedNowMs(prefs);
    if (_detectClockRollback(prefs, trustedNow)) {
      result.message = 'Device clock appears incorrect.';
      return result;
    }

    if (!_isExpiryValid(payload.expiryDate, trustedNow)) {
      result.message = 'Your licence has expired. Please renew.';
      return result;
    }

    final graceMs = payload.offlineGraceUntil * 1000;
    if (graceMs > 0 && trustedNow > graceMs) {
      result.message = 'Offline grace period ended. Connect and login again.';
      return result;
    }

    if (payload.trialConsumed == 1 ||
        prefs.getString('trialConsumed') == '1') {
      result.message = 'Trial already used on this licence.';
      result.trialBillBlocked = true;
      return result;
    }

    if (payload.isTrial == 1 &&
        payload.trialMaxBills > 0 &&
        localInvoiceCount >= payload.trialMaxBills) {
      result.message =
          'Trial bill limit (${payload.trialMaxBills}) reached. Please upgrade.';
      result.trialBillBlocked = true;
      return result;
    }

    result.valid = true;
    result.payload = payload;
    return result;
  }

  static Future<SignedLicensePayload?> verifyAndParse(
    SharedPreferences prefs,
  ) async {
    try {
      final payloadB64 = prefs.getString(_payloadKey)?.trim();
      final signatureB64 = prefs.getString(_signatureKey)?.trim();
      if (payloadB64 == null ||
          payloadB64.isEmpty ||
          signatureB64 == null ||
          signatureB64.isEmpty) {
        return null;
      }

      final payloadBytes = base64.decode(payloadB64);
      final signatureBytes = base64.decode(signatureB64);
      final publicKey = await _loadPublicKey();
      final verifier = Signer('SHA-256/RSA')
        ..init(false, PublicKeyParameter<RSAPublicKey>(publicKey));
      final ok = verifier.verifySignature(
        Uint8List.fromList(payloadBytes),
        RSASignature(Uint8List.fromList(signatureBytes)),
      );
      if (!ok) return null;

      final json = jsonDecode(utf8.decode(payloadBytes));
      if (json is! Map) return null;
      return SignedLicensePayload.fromJson(Map<String, dynamic>.from(json));
    } catch (_) {
      return null;
    }
  }

  static Future<RSAPublicKey> _loadPublicKey() async {
    final pem = await rootBundle.loadString('assets/license_signing_public.pem');
    final b64 = pem
        .replaceAll('-----BEGIN PUBLIC KEY-----', '')
        .replaceAll('-----END PUBLIC KEY-----', '')
        .replaceAll(RegExp(r'\s'), '');
    final der = base64.decode(b64);
    return _parsePublicKeyFromDer(Uint8List.fromList(der));
  }

  /// Parses SubjectPublicKeyInfo (X.509) DER into [RSAPublicKey].
  static RSAPublicKey _parsePublicKeyFromDer(Uint8List der) {
    final parser = ASN1Parser(der);
    final top = parser.nextObject() as ASN1Sequence;
    final topElements = top.elements;
    final bitString = topElements[1] as ASN1BitString;
    var keyBytes = bitString.contentBytes();
    if (keyBytes.isNotEmpty && keyBytes[0] == 0) {
      keyBytes = keyBytes.sublist(1);
    }
    final keyParser = ASN1Parser(Uint8List.fromList(keyBytes));
    final keySeq = keyParser.nextObject() as ASN1Sequence;
    final elements = keySeq.elements;
    final modulus = (elements[0] as ASN1Integer).valueAsBigInteger;
    final exponent = (elements[1] as ASN1Integer).valueAsBigInteger;
    return RSAPublicKey(modulus, exponent);
  }

  static Future<void> _persistModulesFromPayload(
    SharedPreferences prefs,
    String? payloadB64,
  ) async {
    if (payloadB64 == null || payloadB64.trim().isEmpty) return;
    try {
      final bytes = base64.decode(payloadB64.trim());
      final json = jsonDecode(utf8.decode(bytes));
      if (json is! Map) return;
      final p = SignedLicensePayload.fromJson(Map<String, dynamic>.from(json));
      await prefs.setString(
        SessionKeys.fastBilling,
        p.fastBilling == 1 ? 'Yes' : 'No',
      );
      await prefs.setString(
        SessionKeys.takeAway,
        p.takeAway == 1 ? 'Yes' : 'No',
      );
      await prefs.setString(SessionKeys.dineIn, p.dineIn == 1 ? 'Yes' : 'No');
      await prefs.setString(SessionKeys.mess, p.mess == 1 ? 'Yes' : 'No');
    } catch (_) {}
  }

  static int _trustedNowMs(SharedPreferences prefs) {
    final deviceNow = DateTime.now().millisecondsSinceEpoch;
    final lastServer =
        int.tryParse(prefs.getString(_lastServerTimeKey) ?? '') ?? 0;
    return deviceNow > lastServer ? deviceNow : lastServer;
  }

  static bool _detectClockRollback(SharedPreferences prefs, int trustedNowMs) {
    final lastServer =
        int.tryParse(prefs.getString(_lastServerTimeKey) ?? '') ?? 0;
    if (lastServer <= 0) return false;
    final deviceNow = DateTime.now().millisecondsSinceEpoch;
    return deviceNow + _clockToleranceMs < lastServer ||
        trustedNowMs + _clockToleranceMs < lastServer;
  }

  static bool _isExpiryValid(String expiryDateYmd, int trustedNowMs) {
    if (expiryDateYmd.trim().isEmpty) return false;
    try {
      final parts = expiryDateYmd.trim().split('-');
      if (parts.length < 3) return false;
      final end = DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
        23,
        59,
        59,
        999,
      );
      return trustedNowMs <= end.millisecondsSinceEpoch;
    } catch (_) {
      return false;
    }
  }
}

class LicenseValidationResult {
  bool valid = false;
  bool trialBillBlocked = false;
  bool legacyFallback = false;
  String message = '';
  SignedLicensePayload? payload;
}

class SignedLicensePayload {
  SignedLicensePayload({
    this.payloadVersion = 0,
    this.organizationId = '',
    this.branchId = '',
    this.branchLabel = '',
    this.licenseId = '',
    this.deviceId = '',
    this.licenseKey = '',
    this.licenseType = '',
    this.isTrial = 0,
    this.trialMaxBills = 0,
    this.trialBillCount = 0,
    this.trialConsumed = 0,
    this.expiryDate = '',
    this.issuedAt = 0,
    this.offlineGraceUntil = 0,
    this.fastBilling = 0,
    this.takeAway = 0,
    this.dineIn = 0,
    this.mess = 0,
  });

  final int payloadVersion;
  final String organizationId;
  final String branchId;
  final String branchLabel;
  final String licenseId;
  final String deviceId;
  final String licenseKey;
  final String licenseType;
  final int isTrial;
  final int trialMaxBills;
  final int trialBillCount;
  final int trialConsumed;
  final String expiryDate;
  final int issuedAt;
  final int offlineGraceUntil;
  final int fastBilling;
  final int takeAway;
  final int dineIn;
  final int mess;

  factory SignedLicensePayload.fromJson(Map<String, dynamic> json) {
    int i(dynamic v) =>
        v is int ? v : int.tryParse(v?.toString() ?? '') ?? 0;
    String s(dynamic v) => v?.toString() ?? '';
    return SignedLicensePayload(
      payloadVersion: i(json['payloadVersion']),
      organizationId: s(json['organizationId']),
      branchId: s(json['branchId']),
      branchLabel: s(json['branchLabel']),
      licenseId: s(json['licenseId']),
      deviceId: s(json['deviceId']),
      licenseKey: s(json['licenseKey']),
      licenseType: s(json['licenseType']),
      isTrial: i(json['isTrial']),
      trialMaxBills: i(json['trialMaxBills']),
      trialBillCount: i(json['trialBillCount']),
      trialConsumed: i(json['trialConsumed']),
      expiryDate: s(json['expiryDate']),
      issuedAt: i(json['issuedAt']),
      offlineGraceUntil: i(json['offlineGraceUntil']),
      fastBilling: i(json['fastBilling']),
      takeAway: i(json['takeAway']),
      dineIn: i(json['dineIn']),
      mess: i(json['mess']),
    );
  }
}
