import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pos_billingwala_v2/core/database/app_database.dart';
import 'package:pos_billingwala_v2/core/database/database_provider.dart';
import 'package:pos_billingwala_v2/features/auth/domain/auth_controller.dart';
import 'package:pos_billingwala_v2/features/sync/data/invoice_sync_api.dart';

class InvoiceSyncResult {
  const InvoiceSyncResult({
    required this.uploaded,
    required this.downloaded,
    required this.failed,
    this.message,
  });

  final int uploaded;
  final int downloaded;
  final int failed;
  final String? message;

  bool get hasFailures => failed > 0;
}

final pendingInvoicesProvider = StreamProvider<List<Invoice>>((ref) {
  return ref.watch(appDatabaseProvider).watchPendingSyncInvoices();
});

final syncPendingSnapshotProvider =
    FutureProvider<SyncPendingSnapshot>((ref) async {
  // Refresh when pending invoices change.
  ref.watch(pendingInvoicesProvider);
  return ref.read(appDatabaseProvider).getSyncPendingSnapshot();
});

class InvoiceSyncController extends Notifier<AsyncValue<InvoiceSyncResult?>> {
  @override
  AsyncValue<InvoiceSyncResult?> build() => const AsyncData(null);

  Future<InvoiceSyncResult> uploadPending({int? onlyInvoiceId}) async {
    final userId = ref.read(authControllerProvider).session?.userId;
    if (userId == null || userId.isEmpty) {
      const result = InvoiceSyncResult(
        uploaded: 0,
        downloaded: 0,
        failed: 0,
        message: 'Please login first',
      );
      state = const AsyncData(result);
      return result;
    }

    state = const AsyncLoading();
    final db = ref.read(appDatabaseProvider);
    final api = InvoiceSyncApi(ref.read(apiClientProvider));

    try {
      final List<Invoice> pending;
      if (onlyInvoiceId == null) {
        pending = await db.getPendingSyncInvoices();
      } else {
        final invoice = await db.getInvoiceById(onlyInvoiceId);
        pending = (invoice != null && invoice.invoiceSyncStatus == '0')
            ? [invoice]
            : const <Invoice>[];
      }

      var uploaded = 0;
      var failed = 0;
      String? lastError;

      for (final invoice in pending) {
        try {
          final items = await db.getInvoiceItems(invoice.invoiceNumber);
          for (final item in items) {
            if (item.invoiceItemSyncStatus == '1') continue;
            final ok = await api.uploadInvoiceItem(item: item);
            if (!ok) {
              throw StateError('Line upload failed for ${item.productName}');
            }
          }

          final headerOk = await api.uploadInvoice(
            userId: userId,
            invoice: invoice,
          );
          if (!headerOk) {
            throw StateError(
              'Invoice upload failed for ${invoice.invoiceNumber}',
            );
          }

          await db.markInvoiceSynced(invoice.invoiceId);
          uploaded++;
        } catch (e) {
          failed++;
          lastError = e.toString();
        }
      }

      final result = InvoiceSyncResult(
        uploaded: uploaded,
        downloaded: 0,
        failed: failed,
        message: failed == 0
            ? (uploaded == 0 ? 'Nothing pending' : 'Uploaded $uploaded bill(s)')
            : 'Uploaded $uploaded, failed $failed'
                '${lastError == null ? '' : ': $lastError'}',
      );
      state = AsyncData(result);
      return result;
    } catch (e, st) {
      state = AsyncError(e, st);
      return InvoiceSyncResult(
        uploaded: 0,
        downloaded: 0,
        failed: 1,
        message: e.toString(),
      );
    }
  }

  /// Downloads invoices (+ lines) from cloud and upserts as synced.
  Future<InvoiceSyncResult> downloadInvoices({String? invoiceDate}) async {
    final userId = ref.read(authControllerProvider).session?.userId;
    if (userId == null || userId.isEmpty) {
      const result = InvoiceSyncResult(
        uploaded: 0,
        downloaded: 0,
        failed: 0,
        message: 'Please login first',
      );
      state = const AsyncData(result);
      return result;
    }

    state = const AsyncLoading();
    try {
      final api = InvoiceSyncApi(ref.read(apiClientProvider));
      final db = ref.read(appDatabaseProvider);

      final headers = await api.fetchInvoices(
        userId,
        invoiceDate: invoiceDate,
      );
      final lines = await api.fetchInvoiceItems(userId);

      final validHeaders = headers
          .where(
            (e) =>
                e.invoiceNumber.isNotEmpty && e.invoiceNetworkStatus.isNotEmpty,
          )
          .toList();

      final itemsByNumber = <String, List<InvoiceItemsCompanion>>{};
      for (final line in lines) {
        if (line.invoiceNumber.isEmpty || line.productName.isEmpty) continue;
        itemsByNumber
            .putIfAbsent(line.invoiceNumber, () => <InvoiceItemsCompanion>[])
            .add(line.toCompanion());
      }

      final companions = validHeaders.map((e) {
        final count = itemsByNumber[e.invoiceNumber]?.fold<int>(
              0,
              (sum, item) =>
                  sum + (item.productQuantity.present ? item.productQuantity.value : 1),
            ) ??
            0;
        return e.toCompanion().copyWith(itemCount: Value(count));
      }).toList();

      final resultUpsert = await db.upsertCloudInvoices(
        headers: companions,
        itemsByNumber: itemsByNumber,
      );
      final downloaded = resultUpsert.inserted + resultUpsert.updated;

      final result = InvoiceSyncResult(
        uploaded: 0,
        downloaded: downloaded,
        failed: 0,
        message: downloaded == 0
            ? 'No cloud bills to import'
            : 'Downloaded $downloaded bill(s)'
                ' (${resultUpsert.inserted} new, ${resultUpsert.updated} updated'
                '${resultUpsert.skipped > 0 ? ', ${resultUpsert.skipped} skipped' : ''})',
      );
      state = AsyncData(result);
      return result;
    } catch (e, st) {
      state = AsyncError(e, st);
      return InvoiceSyncResult(
        uploaded: 0,
        downloaded: 0,
        failed: 1,
        message: e.toString(),
      );
    }
  }

  Future<InvoiceSyncResult> syncBothWays() async {
    final upload = await uploadPending();
    final dateKey = DateFormat('yyyy-MM').format(DateTime.now());
    final download = await downloadInvoices(invoiceDate: dateKey);
    final result = InvoiceSyncResult(
      uploaded: upload.uploaded,
      downloaded: download.downloaded,
      failed: upload.failed + download.failed,
      message:
          'Upload ${upload.uploaded}, download ${download.downloaded}'
          '${(upload.failed + download.failed) > 0 ? ', failed ${upload.failed + download.failed}' : ''}',
    );
    state = AsyncData(result);
    return result;
  }
}

final invoiceSyncControllerProvider =
    NotifierProvider<InvoiceSyncController, AsyncValue<InvoiceSyncResult?>>(
  InvoiceSyncController.new,
);
