import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pos_billingwala_v2/core/constants/app_colors.dart';
import 'package:pos_billingwala_v2/features/sync/domain/full_sync_controller.dart';
import 'package:pos_billingwala_v2/features/sync/domain/sync_providers.dart';
import 'package:pos_billingwala_v2/core/widgtes/widgtes.dart';

class SyncPage extends ConsumerWidget {
  const SyncPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingAsync = ref.watch(pendingInvoicesProvider);
    final syncState = ref.watch(invoiceSyncControllerProvider);
    final fullState = ref.watch(fullSyncControllerProvider);
    final isBusy = syncState.isLoading || fullState.isLoading;
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: 'â‚¹');

    ref.listen(invoiceSyncControllerProvider, (prev, next) {
      next.whenOrNull(
        data: (result) {
          if (result?.message == null) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result!.message!)),
          );
        },
        error: (error, _) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$error')),
          );
        },
      );
    });

    ref.listen(fullSyncControllerProvider, (prev, next) {
      next.whenOrNull(
        data: (result) {
          if (result?.message == null) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result!.message)),
          );
        },
        error: (error, _) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$error')),
          );
        },
      );
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sync'),
        actions: [
          IconButton(
            tooltip: 'Sync bills both ways',
            onPressed: isBusy
                ? null
                : () => ref
                    .read(invoiceSyncControllerProvider.notifier)
                    .syncBothWays(),
            icon: isBusy
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.sync_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: AppCard(
            color: AppColors.primary,
            padding: const EdgeInsets.all(16),
            child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Full sync',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Upload pending masters, bills, inventory, mess, dining & company, '
                      'then download the latest from cloud.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                    const SizedBox(height: 14),
                    AppButton(
                      label: 'Sync everything',
                      icon: Icons.cloud_sync_rounded,
                      isLoading: fullState.isLoading || isBusy,
                      onPressed: () => ref
                          .read(fullSyncControllerProvider.notifier)
                          .syncEverything(),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: AppButton(
            label: 'Upload',
            icon: Icons.cloud_upload_rounded,
            variant: AppButtonVariant.outlined,
            isLoading: isBusy,
            expanded: false,
            onPressed: () => ref
                                    .read(fullSyncControllerProvider.notifier)
                                    .uploadAll(),
          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: AppButton(
            label: 'Download',
            icon: Icons.cloud_download_rounded,
            variant: AppButtonVariant.outlined,
            isLoading: isBusy,
            expanded: false,
            onPressed: () => ref
                                    .read(fullSyncControllerProvider.notifier)
                                    .downloadAll(),
          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    AppButton(
            label: 'Fetch data (reset)',
            icon: Icons.refresh_rounded,
            variant: AppButtonVariant.outlined,
            isLoading: isBusy,
            expanded: false,
            onPressed: () async {
                              final ok = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Fetch all data'),
                                  content: const Text(
                                    'This clears local catalog, bills, mess, inventory '
                                    'and dining data on this device, then downloads '
                                    'fresh data from the cloud. Pending unsynced '
                                    'changes will be lost. Continue?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: const Text('Cancel'),
                                    ),
                                    AppButton(
            label: 'Wipe & fetch',
            onPressed: () =>
                                          Navigator.pop(context, true),
          ),
                                  ],
                                ),
                              );
                              if (ok == true) {
                                await ref
                                    .read(fullSyncControllerProvider.notifier)
                                    .resetAndFetchAll();
                              }
                            },
          ),
                    const SizedBox(height: 8),
                    Text(
                      'Upload = pending offline data â†’ server. '
                      'Download = refresh from server. '
                      'Fetch data = wipe local ops tables then download.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: AppCard(
              padding: const EdgeInsets.all(12),
              child: ref.watch(syncPendingSnapshotProvider).when(
                      data: (s) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pending uploads · ${s.total}',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _PendingChip('Bills', s.invoices),
                              _PendingChip('Categories', s.categories),
                              _PendingChip('Products', s.products),
                              _PendingChip('Combos', s.combos),
                              _PendingChip('Subcats', s.subcategories),
                              _PendingChip('Portions', s.portions),
                              _PendingChip('Mess', s.messMembers + s.messTokens),
                              _PendingChip('Dining', s.diningSessions),
                              _PendingChip('Stock', s.inventory),
                              _PendingChip('Expenses', s.expenses),
                            ],
                          ),
                        ],
                      ),
                      loading: () => const LinearProgressIndicator(),
                      error: (e, _) => Text('$e'),
                    ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: AppCard(
            color: AppColors.primaryLight,
            padding: const EdgeInsets.all(16),
            child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.receipt_long_rounded,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: pendingAsync.when(
                            data: (rows) => Text(
                              rows.isEmpty
                                  ? 'No pending bill uploads'
                                  : '${rows.length} bill(s) waiting to upload',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w700),
                            ),
                            loading: () => const Text('Checking pendingâ€¦'),
                            error: (e, _) => Text('$e'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: AppButton(
            label: 'Upload bills',
            icon: Icons.cloud_upload_rounded,
            onPressed: isBusy
                                ? null
                                : () => ref
                                    .read(invoiceSyncControllerProvider.notifier)
                                    .uploadPending(),
            expanded: false,
          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: AppButton(
            label: 'Bills only',
            icon: Icons.cloud_download_rounded,
            variant: AppButtonVariant.outlined,
            isLoading: isBusy,
            expanded: false,
            onPressed: () => ref
                                    .read(invoiceSyncControllerProvider.notifier)
                                    .downloadInvoices(
                                      invoiceDate: DateFormat('yyyy-MM')
                                          .format(DateTime.now()),
                                    ),
          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'When internet returns, pending data uploads automatically.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          Expanded(
            child: pendingAsync.when(
              data: (rows) {
                if (rows.isEmpty) {
                  return const Center(
                    child: Text('No pending invoices'),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: rows.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final invoice = rows[index];
                    return AppCard(
                      padding: EdgeInsets.zero,
                      child: ListTile(
                        leading: const Icon(
                          Icons.receipt_long_rounded,
                          color: AppColors.warning,
                        ),
                        title: Text(
                          invoice.invoiceNumber,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(
                          '${invoice.paymentMode} · ${invoice.invoiceType}',
                        ),
                        trailing: Text(
                          currency.format(invoice.totalAmount),
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        onTap: isBusy
                            ? null
                            : () => ref
                                .read(invoiceSyncControllerProvider.notifier)
                                .uploadPending(
                                  onlyInvoiceId: invoice.invoiceId,
                                ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('$e')),
            ),
          ),
        ],
      ),
    );
  }
}

class _PendingChip extends StatelessWidget {
  const _PendingChip(this.label, this.count);

  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text('$label: $count'),
      visualDensity: VisualDensity.compact,
      backgroundColor: count > 0
          ? AppColors.primaryLight
          : Theme.of(context).colorScheme.surfaceContainerHighest,
    );
  }
}
