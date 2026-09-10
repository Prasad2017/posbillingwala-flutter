import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pos_billingwala_v2/core/database/app_database.dart';
import 'package:pos_billingwala_v2/core/database/database_provider.dart';
import 'package:pos_billingwala_v2/features/auth/domain/auth_controller.dart';
import 'package:pos_billingwala_v2/features/company/data/company_api.dart';
import 'package:pos_billingwala_v2/features/company/data/company_dtos.dart';
import 'package:pos_billingwala_v2/features/inventory/domain/inventory_providers.dart';
import 'package:pos_billingwala_v2/features/masters/domain/masters_providers.dart';
import 'package:pos_billingwala_v2/features/mess/data/mess_api.dart';
import 'package:pos_billingwala_v2/features/mess/domain/mess_dtos.dart';
import 'package:pos_billingwala_v2/features/mess/domain/mess_providers.dart';
import 'package:pos_billingwala_v2/features/print/domain/printer_settings.dart';
import 'package:pos_billingwala_v2/features/sync/domain/sync_providers.dart';
import 'package:pos_billingwala_v2/features/tables/data/dining_session_api.dart';
import 'package:pos_billingwala_v2/features/tables/domain/tables_providers.dart';

enum FullSyncMode { uploadOnly, downloadOnly, both }

class FullSyncResult {
  const FullSyncResult({
    required this.message,
    this.mode = FullSyncMode.both,
    this.mastersUploaded = 0,
    this.invoicesUploaded = 0,
    this.invoicesDownloaded = 0,
    this.inventorySynced = false,
    this.messUploaded = 0,
    this.diningUploaded = 0,
    this.diningDownloaded = 0,
    this.companySynced = false,
    this.failed = 0,
  });

  final String message;
  final FullSyncMode mode;
  final int mastersUploaded;
  final int invoicesUploaded;
  final int invoicesDownloaded;
  final bool inventorySynced;
  final int messUploaded;
  final int diningUploaded;
  final int diningDownloaded;
  final bool companySynced;
  final int failed;
}

/// Android-parity sync orchestrator:
/// - Upload pending offline rows to server
/// - Download / refresh cloud data into local DB
class FullSyncController extends Notifier<AsyncValue<FullSyncResult?>> {
  @override
  AsyncValue<FullSyncResult?> build() => const AsyncData(null);

  Future<FullSyncResult> syncEverything() =>
      _run(FullSyncMode.both);

  Future<FullSyncResult> uploadAll() => _run(FullSyncMode.uploadOnly);

  Future<FullSyncResult> downloadAll() => _run(FullSyncMode.downloadOnly);

  /// Android Home "Fetch Data": confirm wipe → reset local ops tables → download.
  Future<FullSyncResult> resetAndFetchAll() async {
    final userId = ref.read(authControllerProvider).session?.userId;
    if (userId == null || userId.isEmpty) {
      const result = FullSyncResult(message: 'Please login first', failed: 1);
      state = const AsyncData(result);
      return result;
    }
    state = const AsyncLoading();
    try {
      await ref.read(appDatabaseProvider).resetOperationalDataForFetch();
      final result = await _run(FullSyncMode.downloadOnly);
      return result;
    } catch (e) {
      final result = FullSyncResult(message: '$e', failed: 1);
      state = AsyncData(result);
      return result;
    }
  }

  Future<FullSyncResult> _run(FullSyncMode mode) async {
    final userId = ref.read(authControllerProvider).session?.userId;
    if (userId == null || userId.isEmpty) {
      const result = FullSyncResult(message: 'Please login first', failed: 1);
      state = const AsyncData(result);
      return result;
    }

    state = const AsyncLoading();
    final db = ref.read(appDatabaseProvider);
    var failed = 0;
    final notes = <String>[];

    var mastersUploaded = 0;
    var invoicesUploaded = 0;
    var invoicesDownloaded = 0;
    var inventorySynced = false;
    var messUploaded = 0;
    var diningUploaded = 0;
    var diningDownloaded = 0;
    var companySynced = false;

    final doUpload =
        mode == FullSyncMode.uploadOnly || mode == FullSyncMode.both;
    final doDownload =
        mode == FullSyncMode.downloadOnly || mode == FullSyncMode.both;

    // ---- UPLOAD (local → server) — same spirit as Android UserSynchronizeData
    if (doUpload) {
      try {
        mastersUploaded = await ref
            .read(mastersRepositoryProvider)
            .uploadPendingMasters(userId);
        notes.add('masters↑$mastersUploaded');
      } catch (_) {
        failed++;
        notes.add('masters↑ error');
      }

      try {
        final upload =
            await ref.read(invoiceSyncControllerProvider.notifier).uploadPending();
        invoicesUploaded = upload.uploaded;
        failed += upload.failed;
        notes.add('bills↑$invoicesUploaded');
      } catch (_) {
        failed++;
        notes.add('bills↑ error');
      }

      try {
        messUploaded = await _uploadPendingMess(userId, db);
        notes.add('mess↑$messUploaded');
      } catch (_) {
        failed++;
        notes.add('mess↑ error');
      }

      try {
        diningUploaded = await _uploadPendingDining(userId, db);
        notes.add('dining↑$diningUploaded');
      } catch (_) {
        failed++;
        notes.add('dining↑ error');
      }

      try {
        await ref.read(inventoryControllerProvider.notifier).syncAll();
        inventorySynced = true;
        notes.add('inventory↑ ok');
      } catch (_) {
        failed++;
        notes.add('inventory↑ error');
      }

      try {
        companySynced = await _uploadCompanyAndPrinter(userId);
        notes.add(companySynced ? 'company↑ ok' : 'company↑ skip');
      } catch (_) {
        failed++;
        notes.add('company↑ error');
      }
    }

    // ---- DOWNLOAD (server → local) — same spirit as Android NetworkDataFetcher
    if (doDownload) {
      try {
        await ref.read(mastersRepositoryProvider).syncFromCloud(userId);
        notes.add('masters↓ ok');
      } catch (_) {
        failed++;
        notes.add('masters↓ error');
      }

      try {
        await ref.read(tablesControllerProvider.notifier).syncTables();
        notes.add('tables↓ ok');
      } catch (_) {
        // Masters sync already pulls tables; ignore secondary failure.
        notes.add('tables↓ skip');
      }

      try {
        final dateKey = DateFormat('yyyy-MM').format(DateTime.now());
        final download = await ref
            .read(invoiceSyncControllerProvider.notifier)
            .downloadInvoices(invoiceDate: dateKey);
        invoicesDownloaded = download.downloaded;
        failed += download.failed;
        notes.add('bills↓$invoicesDownloaded');
      } catch (_) {
        failed++;
        notes.add('bills↓ error');
      }

      if (!doUpload) {
        // When download-only, still refresh inventory/expenses from cloud.
        try {
          await ref.read(inventoryControllerProvider.notifier).syncAll();
          inventorySynced = true;
          notes.add('inventory↓ ok');
        } catch (_) {
          failed++;
          notes.add('inventory↓ error');
        }
      }

      try {
        await ref.read(messControllerProvider.notifier).syncMembers();
        notes.add('mess↓ ok');
      } catch (_) {
        failed++;
        notes.add('mess↓ error');
      }

      try {
        diningDownloaded = await _downloadDining(userId, db);
        notes.add('dining↓$diningDownloaded');
      } catch (_) {
        failed++;
        notes.add('dining↓ error');
      }

      try {
        final ok = await _downloadCompanyAndPrinter(userId);
        companySynced = companySynced || ok;
        notes.add(ok ? 'company↓ ok' : 'company↓ skip');
      } catch (_) {
        failed++;
        notes.add('company↓ error');
      }
    }

    final label = switch (mode) {
      FullSyncMode.uploadOnly => 'Upload to server',
      FullSyncMode.downloadOnly => 'Download from server',
      FullSyncMode.both => 'Sync everything',
    };

    final result = FullSyncResult(
      message: failed == 0
          ? '$label complete · ${notes.join(' · ')}'
          : '$label finished with $failed issue(s) · ${notes.join(' · ')}',
      mode: mode,
      mastersUploaded: mastersUploaded,
      invoicesUploaded: invoicesUploaded,
      invoicesDownloaded: invoicesDownloaded,
      inventorySynced: inventorySynced,
      messUploaded: messUploaded,
      diningUploaded: diningUploaded,
      diningDownloaded: diningDownloaded,
      companySynced: companySynced,
      failed: failed,
    );
    state = AsyncData(result);
    return result;
  }

  Future<int> _uploadPendingMess(String userId, AppDatabase db) async {
    final api = MessApi(ref.read(apiClientProvider));
    var uploaded = 0;

    for (final member in await db.getPendingMessMembers()) {
      final ok = await api.insertMessMember(
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
      if (ok) {
        await db.markMessMemberSynced(member.memberId);
        uploaded++;
      }
    }

    for (final token in await db.getPendingMessTokens()) {
      final ok = await api.insertMessToken(
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
      if (ok) {
        await db.markMessTokenSynced(token.tokenId);
        uploaded++;
      }
    }
    return uploaded;
  }

  Future<int> _uploadPendingDining(String userId, AppDatabase db) async {
    final diningApi = DiningSessionApi(ref.read(apiClientProvider));
    var diningUploaded = 0;
    for (final session in await db.getPendingDiningSessions()) {
      final dto = DiningSessionDto(
        sessionId: session.sessionId,
        localSessionId: '${session.sessionId}',
        primaryTableNumber: session.primaryTableNumber,
        joinedTableNumbers: session.joinedTableNumbers,
        sessionStatus: session.sessionStatus,
        guestCount: session.guestCount,
        startedAt: session.startedAt,
        closedAt: session.closedAt,
        customerName: session.customerName,
        customerMobile: session.customerMobile,
        paidAmount: session.paidAmount,
        sessionVersion: session.sessionVersion,
        sessionNetworkStatus: session.sessionNetworkStatus,
      );
      final ok = await diningApi.insertDiningSession(
        userId: userId,
        session: dto,
      );
      if (ok) {
        await db.markDiningSessionSynced(session.sessionId);
        diningUploaded++;
      }
    }
    return diningUploaded;
  }

  Future<int> _downloadDining(String userId, AppDatabase db) async {
    final diningApi = DiningSessionApi(ref.read(apiClientProvider));
    final cloudSessions =
        await diningApi.fetchDiningSessions(userId, openOnly: true);
    final companions = cloudSessions
        .where((e) => e.primaryTableNumber.trim().isNotEmpty)
        .map(
          (e) => DiningSessionsCompanion.insert(
            primaryTableNumber: e.primaryTableNumber,
            joinedTableNumbers: Value(e.joinedTableNumbers),
            sessionStatus: Value(e.sessionStatus),
            guestCount: Value(e.guestCount),
            startedAt: e.startedAt ?? DateTime.now(),
            closedAt: Value(e.closedAt),
            customerName: Value(e.customerName),
            customerMobile: Value(e.customerMobile),
            paidAmount: Value(e.paidAmount),
            sessionNetworkStatus: Value(e.sessionNetworkStatus),
            sessionSyncStatus: const Value('1'),
            sessionVersion: Value(e.sessionVersion),
          ),
        )
        .toList();
    return db.upsertDiningSessionsFromCloud(companions);
  }

  Future<bool> _downloadCompanyAndPrinter(String userId) async {
    final api = CompanyApi(ref.read(apiClientProvider));
    final companies = await api.getCompanyList(userId);
    final printers = await api.getCompanyPrinterSetting(userId);
    if (companies.isEmpty && printers.isEmpty) return false;

    if (printers.isNotEmpty) {
      final p = printers.first;
      final current = ref.read(printerSettingsProvider);
      await ref.read(printerSettingsProvider.notifier).update(
            current.copyWith(
              billBluetoothAddress: p.bluetoothAddress.isNotEmpty
                  ? p.bluetoothAddress
                  : current.billBluetoothAddress,
              kotBluetoothAddress: p.bluetoothKotAddress.isNotEmpty
                  ? p.bluetoothKotAddress
                  : current.kotBluetoothAddress,
              feedLines:
                  int.tryParse(p.printerFeedLines) ?? current.feedLines,
            ),
          );
    }
    return true;
  }

  Future<bool> _uploadCompanyAndPrinter(String userId) async {
    final api = CompanyApi(ref.read(apiClientProvider));
    final session = ref.read(authControllerProvider).session;
    final settings = ref.read(printerSettingsProvider);

    // Best-effort: push current shop name + printer MACs if we have them.
    final companies = await api.getCompanyList(userId);
    final base = companies.isNotEmpty
        ? companies.first
        : CompanyDto(companyName: session?.shopName ?? '');
    final companyOk = await api.insertCompanyDetail(
      userId: userId,
      company: CompanyDto(
        companyId: base.companyId,
        companyName: base.companyName.isNotEmpty
            ? base.companyName
            : (session?.shopName ?? ''),
        companyMobile: base.companyMobile,
        companyAddress: base.companyAddress,
        shopName1: base.shopName1,
        shopName2: base.shopName2,
        addressLine1: base.addressLine1,
        addressLine2: base.addressLine2,
        addressLine3: base.addressLine3,
        phoneNo1: base.phoneNo1,
        phoneNo2: base.phoneNo2,
        gstStatus: base.gstStatus,
        gstNumber: base.gstNumber,
        panNumber: base.panNumber,
        companyFssis: base.companyFssis,
      ),
    );
    final printerOk = await api.insertCompanyPrinterSetting(
      userId: userId,
      setting: CompanyPrinterSettingDto(
        bluetoothAddress: settings.billBluetoothAddress,
        bluetoothKotAddress: settings.kotBluetoothAddress,
        printerFeedLines: '${settings.feedLines}',
        kotPrinterFeedLines: '${settings.feedLines}',
      ),
    );
    return companyOk || printerOk;
  }
}

final fullSyncControllerProvider =
    NotifierProvider<FullSyncController, AsyncValue<FullSyncResult?>>(
  FullSyncController.new,
);
