import 'dart:math';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pos_billingwala_v2/core/database/app_database.dart';
import 'package:pos_billingwala_v2/core/database/database_provider.dart';
import 'package:pos_billingwala_v2/features/auth/data/device_identity_service.dart';
import 'package:pos_billingwala_v2/features/auth/domain/auth_controller.dart';
import 'package:pos_billingwala_v2/features/mess/data/mess_api.dart';
import 'package:pos_billingwala_v2/features/mess/domain/mess_dtos.dart';

/// Matches Android MessTokenQrHelper payload.
class MessTokenQrHelper {
  static const prefix = 'POSBILL|v1|';
  static const memberTypeMember = 'member';
  static const memberTypeWalkIn = 'walk_in';

  static String generateTokenCode() {
    final rand = Random.secure();
    final bytes = List<int>.generate(16, (_) => rand.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  static String buildPayload({
    required String tokenCode,
    required String userId,
    required String memberType,
  }) {
    return '$prefix$tokenCode|$userId|$memberType';
  }

  /// Returns [tokenCode, userId, memberType] or null.
  static List<String>? parsePayload(String raw) {
    if (!raw.startsWith(prefix)) return null;
    final parts = raw.split('|');
    if (parts.length < 5) return null;
    return [parts[2], parts[3], parts[4]];
  }
}

final messMembersProvider = StreamProvider<List<MessMember>>((ref) {
  return ref.watch(appDatabaseProvider).watchMessMembers();
});

final todayMessTokensProvider = StreamProvider<List<MessToken>>((ref) {
  return ref.watch(appDatabaseProvider).watchTodayMessTokens();
});

final messCommonQrProvider =
    NotifierProvider<MessCommonQrController, AsyncValue<MessCommonQrDto?>>(
  MessCommonQrController.new,
);

class MessCommonQrController extends Notifier<AsyncValue<MessCommonQrDto?>> {
  @override
  AsyncValue<MessCommonQrDto?> build() => const AsyncData(null);

  Future<void> load() async {
    final userId = ref.read(authControllerProvider).session?.userId;
    if (userId == null || userId.isEmpty) {
      state = AsyncError('Please login first', StackTrace.current);
      return;
    }
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final api = MessApi(ref.read(apiClientProvider));
      return api.fetchCommonQr(userId);
    });
  }

  Future<void> generate() async {
    final userId = ref.read(authControllerProvider).session?.userId;
    if (userId == null || userId.isEmpty) {
      state = AsyncError('Please login first', StackTrace.current);
      return;
    }
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final device = await DeviceIdentityService().resolve();
      final api = MessApi(ref.read(apiClientProvider));
      return api.generateCommonQr(
        userId,
        deviceId: device.deviceId,
        deviceName: device.deviceName,
      );
    });
  }

  Future<void> regenerate() async {
    final userId = ref.read(authControllerProvider).session?.userId;
    if (userId == null || userId.isEmpty) {
      state = AsyncError('Please login first', StackTrace.current);
      return;
    }
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final device = await DeviceIdentityService().resolve();
      final api = MessApi(ref.read(apiClientProvider));
      return api.regenerateCommonQr(
        userId,
        deviceId: device.deviceId,
        deviceName: device.deviceName,
      );
    });
  }

  Future<void> setStatus(String status) async {
    final userId = ref.read(authControllerProvider).session?.userId;
    if (userId == null || userId.isEmpty) {
      state = AsyncError('Please login first', StackTrace.current);
      return;
    }
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final device = await DeviceIdentityService().resolve();
      final api = MessApi(ref.read(apiClientProvider));
      final ok = await api.setCommonQrStatus(
        userId,
        status: status,
        deviceId: device.deviceId,
        deviceName: device.deviceName,
      );
      if (!ok) {
        throw Exception('Failed to update QR status');
      }
      return api.fetchCommonQr(userId);
    });
  }
}

class MessController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<void> syncMembers() async {
    final userId = ref.read(authControllerProvider).session?.userId;
    if (userId == null || userId.isEmpty) {
      state = AsyncError('Please login first', StackTrace.current);
      return;
    }

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final api = MessApi(ref.read(apiClientProvider));
      final members = await api.fetchMembers(userId);
      await ref.read(appDatabaseProvider).replaceMessMembers(
            members
                .where((e) => e.memberId > 0 && e.memberName.trim().isNotEmpty)
                .map(
                  (e) => MessMembersCompanion.insert(
                    memberId: Value(e.memberId),
                    memberName: Value(e.memberName),
                    memberMobileNumber: Value(e.memberMobileNumber),
                    memberAltenetMobileNumber:
                        Value(e.memberAltenetMobileNumber),
                    memberAddress: Value(e.memberAddress),
                    registrationNo: Value(e.registrationNo),
                    memberType: Value(e.memberType),
                    rollNo: Value(e.rollNo),
                    college: Value(e.college),
                    studentYear: Value(e.studentYear),
                    company: Value(e.company),
                    memberStatus: Value(e.memberStatus),
                    memberNetworkStatus: Value(e.memberNetworkStatus),
                    memberSyncStatus: const Value('1'),
                  ),
                )
                .toList(),
          );

      // Upload pending paper coupons, then refresh cloud list.
      final db = ref.read(appDatabaseProvider);
      for (final coupon in await db.getPendingMessInvoices()) {
        try {
          final ok = await api.insertMessInvoice(
            userId: userId,
            memberName: coupon.memberName,
            messType: coupon.messType,
            messInvoiceDate: DateFormat('yyyy-MM-dd HH:mm:ss')
                .format(coupon.messInvoiceDate),
            messInvoiceNetworkStatus: coupon.messInvoiceNetworkStatus,
            messInvoiceStatus: '0',
          );
          if (ok) await db.markMessInvoiceSynced(coupon.invoiceId);
        } catch (_) {}
      }
      try {
        final cloudCoupons = await api.fetchMessInvoices(userId);
        if (cloudCoupons.isNotEmpty) {
          await db.replaceMessInvoices(
            cloudCoupons
                .map(
                  (e) => MessInvoicesCompanion.insert(
                    invoiceId: e.invoiceId > 0
                        ? Value(e.invoiceId)
                        : const Value.absent(),
                    memberId: Value(e.memberId),
                    memberName: Value(e.memberName),
                    messType: Value(e.messType),
                    messInvoiceDate:
                        DateTime.tryParse(e.messInvoiceDate) ?? DateTime.now(),
                    messInvoiceNetworkStatus:
                        e.messInvoiceNetworkStatus?.trim().isNotEmpty == true
                            ? e.messInvoiceNetworkStatus!
                            : 'mi_${e.invoiceId}',
                    messInvoiceStatus: Value(
                      e.messInvoiceStatus.isEmpty ? '1' : e.messInvoiceStatus,
                    ),
                  ),
                )
                .toList(),
          );
        }
      } catch (_) {}
    });
  }

  Future<int> addLocalMember({
    required String name,
    String? mobile,
    String? registrationNo,
  }) async {
    final db = ref.read(appDatabaseProvider);
    final id = await db.upsertLocalMessMember(
      memberName: name,
      mobile: mobile,
      registrationNo: registrationNo,
    );
    final userId = ref.read(authControllerProvider).session?.userId;
    if (userId != null && userId.isNotEmpty) {
      try {
        final member = await db.getMessMember(id);
        if (member != null) {
          final ok = await MessApi(ref.read(apiClientProvider)).insertMessMember(
            userId: userId,
            member: MessMemberDto(
              memberId: member.memberId,
              memberName: member.memberName,
              memberMobileNumber: member.memberMobileNumber,
              memberAltenetMobileNumber: member.memberAltenetMobileNumber,
              memberAddress: member.memberAddress,
              registrationNo: member.registrationNo,
              memberType: member.memberType,
              rollNo: member.rollNo,
              college: member.college,
              studentYear: member.studentYear,
              company: member.company,
              memberStatus: member.memberStatus,
              memberNetworkStatus: member.memberNetworkStatus,
            ),
          );
          if (ok) await db.markMessMemberSynced(id);
        }
      } catch (_) {
        // Keep local pending row for later full sync.
      }
    }
    return id;
  }

  Future<void> updateLocalMember({
    required int memberId,
    required String name,
    String? mobile,
    String? registrationNo,
  }) async {
    final db = ref.read(appDatabaseProvider);
    await db.updateLocalMessMember(
      memberId: memberId,
      memberName: name,
      mobile: mobile,
      registrationNo: registrationNo,
    );
    final userId = ref.read(authControllerProvider).session?.userId;
    if (userId != null && userId.isNotEmpty) {
      try {
        final member = await db.getMessMember(memberId);
        if (member != null) {
          final ok = await MessApi(ref.read(apiClientProvider)).insertMessMember(
            userId: userId,
            member: MessMemberDto(
              memberId: member.memberId,
              memberName: member.memberName,
              memberMobileNumber: member.memberMobileNumber,
              memberAltenetMobileNumber: member.memberAltenetMobileNumber,
              memberAddress: member.memberAddress,
              registrationNo: member.registrationNo,
              memberType: member.memberType,
              rollNo: member.rollNo,
              college: member.college,
              studentYear: member.studentYear,
              company: member.company,
              memberStatus: member.memberStatus,
              memberNetworkStatus: member.memberNetworkStatus,
            ),
          );
          if (ok) await db.markMessMemberSynced(memberId);
        }
      } catch (_) {}
    }
  }

  Future<({MessToken token, String payload})> issueMemberToken(
    MessMember member, {
    String messType = 'Lunch',
  }) async {
    final userId = ref.read(authControllerProvider).session?.userId ?? '0';
    final code = MessTokenQrHelper.generateTokenCode();
    final db = ref.read(appDatabaseProvider);
    final token = await db.issueMessToken(
      tokenCode: code,
      memberId: '${member.memberId}',
      memberName: member.memberName,
      memberMobile: member.memberMobileNumber,
      memberType: MessTokenQrHelper.memberTypeMember,
      messType: messType,
    );
    if (userId != '0' && userId.isNotEmpty) {
      try {
        final ok = await MessApi(ref.read(apiClientProvider)).insertMessToken(
          userId: userId,
          tokenCode: token.tokenCode,
          memberId: token.memberId ?? '',
          memberName: token.memberName ?? '',
          memberMobile: token.memberMobile ?? '',
          memberType: token.memberType,
          messType: token.messType,
          tokenAmount: token.tokenAmount.toStringAsFixed(2),
          tokenDate: token.tokenDate,
          tokenNetworkStatus: token.tokenNetworkStatus ?? '',
        );
        if (ok) await db.markMessTokenSynced(token.tokenId);
      } catch (_) {}
    }
    final payload = MessTokenQrHelper.buildPayload(
      tokenCode: code,
      userId: userId,
      memberType: MessTokenQrHelper.memberTypeMember,
    );
    return (token: token, payload: payload);
  }

  Future<({MessToken token, String payload})> issueWalkInToken({
    String name = 'Walk-in',
    String? mobile,
    String messType = 'Lunch',
    double amount = 0,
  }) async {
    final userId = ref.read(authControllerProvider).session?.userId ?? '0';
    final code = MessTokenQrHelper.generateTokenCode();
    final db = ref.read(appDatabaseProvider);
    final token = await db.issueMessToken(
      tokenCode: code,
      memberName: name.trim().isEmpty ? 'Walk-in' : name.trim(),
      memberMobile: mobile?.trim().isEmpty == true ? null : mobile?.trim(),
      memberType: MessTokenQrHelper.memberTypeWalkIn,
      messType: messType,
      tokenAmount: amount,
    );
    if (userId != '0' && userId.isNotEmpty) {
      try {
        final ok = await MessApi(ref.read(apiClientProvider)).insertMessToken(
          userId: userId,
          tokenCode: token.tokenCode,
          memberId: token.memberId ?? '',
          memberName: token.memberName ?? '',
          memberMobile: token.memberMobile ?? '',
          memberType: token.memberType,
          messType: token.messType,
          tokenAmount: token.tokenAmount.toStringAsFixed(2),
          tokenDate: token.tokenDate,
          tokenNetworkStatus: token.tokenNetworkStatus ?? '',
        );
        if (ok) await db.markMessTokenSynced(token.tokenId);
      } catch (_) {}
    }
    final payload = MessTokenQrHelper.buildPayload(
      tokenCode: code,
      userId: userId,
      memberType: MessTokenQrHelper.memberTypeWalkIn,
    );
    return (token: token, payload: payload);
  }

  Future<MessToken?> verifyRaw(String rawOrCode) async {
    final parsed = MessTokenQrHelper.parsePayload(rawOrCode.trim());
    final code = parsed?.first ?? rawOrCode.trim();
    if (code.isEmpty) return null;
    final db = ref.read(appDatabaseProvider);
    final token = await db.verifyMessToken(code);
    final userId = ref.read(authControllerProvider).session?.userId;
    if (token != null && userId != null && userId.isNotEmpty) {
      try {
        await MessApi(ref.read(apiClientProvider)).verifyMessToken(
          userId: userId,
          tokenCode: token.tokenCode,
          verifiedDate: token.verifiedDate,
          verifyNetworkStatus: token.tokenNetworkStatus ?? '',
        );
        await db.markMessTokenSynced(token.tokenId);
      } catch (_) {}
    }
    return token;
  }
}

final messControllerProvider =
    NotifierProvider<MessController, AsyncValue<void>>(MessController.new);
