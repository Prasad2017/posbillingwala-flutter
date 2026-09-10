import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:pos_billingwala_v2/core/constants/app_colors.dart';
import 'package:pos_billingwala_v2/core/database/app_database.dart';
import 'package:pos_billingwala_v2/features/reports/domain/report_export.dart';
import 'package:pos_billingwala_v2/features/reports/domain/reports_providers.dart';
import 'package:pos_billingwala_v2/core/widgtes/widgtes.dart';

class ReportsPage extends ConsumerWidget {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final period = ref.watch(reportPeriodProvider);
    final paymentFilter = ref.watch(reportPaymentFilterProvider);
    final invoicesAsync = ref.watch(periodInvoicesProvider);
    final filtered = ref.watch(filteredPeriodInvoicesProvider);
    final summary = ref.watch(periodSalesSummaryProvider);
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
    final timeFormat = DateFormat('dd MMM, hh:mm a');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        actions: [
          IconButton(
            tooltip: 'Export CSV',
            onPressed: filtered.isEmpty
                ? null
                : () => shareInvoicesCsv(
                      invoices: filtered,
                      title: 'Invoices — ${period.label}',
                    ),
            icon: const Icon(Icons.ios_share_rounded),
          ),
          IconButton(
            tooltip: 'Pick a day',
            onPressed: () async {
              final now = DateTime.now();
              final picked = await showDatePicker(
                context: context,
                initialDate: period.day ?? now,
                firstDate: DateTime(now.year - 2),
                lastDate: now,
              );
              if (picked != null) {
                ref.read(reportPeriodProvider.notifier).useDay(picked);
              }
            },
            icon: const Icon(Icons.calendar_month_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: SegmentedButton<ReportPeriodKind>(
              segments: const [
                ButtonSegment(
                  value: ReportPeriodKind.today,
                  label: Text('Today'),
                ),
                ButtonSegment(
                  value: ReportPeriodKind.month,
                  label: Text('Month'),
                ),
                ButtonSegment(
                  value: ReportPeriodKind.day,
                  label: Text('Day'),
                ),
              ],
              selected: {period.kind},
              onSelectionChanged: (value) {
                final kind = value.first;
                switch (kind) {
                  case ReportPeriodKind.today:
                    ref.read(reportPeriodProvider.notifier).useToday();
                  case ReportPeriodKind.month:
                    ref.read(reportPeriodProvider.notifier).useMonth();
                  case ReportPeriodKind.day:
                    final day = period.day ?? DateTime.now();
                    ref.read(reportPeriodProvider.notifier).useDay(day);
                }
              },
            ),
          ),
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              children: [
                for (final entry in const [
                  (ReportPaymentFilter.all, 'All'),
                  (ReportPaymentFilter.cash, 'Cash'),
                  (ReportPaymentFilter.upi, 'UPI'),
                  (ReportPaymentFilter.cashPlusUpi, 'Cash+UPI'),
                ])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(entry.$2),
                      selected: paymentFilter == entry.$1,
                      onSelected: (_) => ref
                          .read(reportPaymentFilterProvider.notifier)
                          .select(entry.$1),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary,
                    AppColors.primary.withValues(alpha: 0.86),
                  ],
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    period.label,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: Colors.white70,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    currency.format(summary.totalSales),
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Avg bill ${currency.format(summary.avgBill)}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _SummaryChip(label: 'Bills', value: '${summary.billCount}'),
                      _SummaryChip(
                        label: 'Cash',
                        value: currency.format(summary.cashTotal),
                      ),
                      _SummaryChip(
                        label: 'UPI',
                        value: currency.format(summary.upiTotal),
                      ),
                      _SummaryChip(
                        label: 'GST',
                        value: currency.format(summary.gstTotal),
                      ),
                      _SummaryChip(label: 'POS', value: '${summary.posCount}'),
                      _SummaryChip(
                        label: 'Table',
                        value: '${summary.tableCount}',
                      ),
                      _SummaryChip(
                        label: 'Takeaway',
                        value: '${summary.takeawayCount}',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: invoicesAsync.when(
              data: (_) {
                if (filtered.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.receipt_long_outlined,
                            size: 56,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No bills for ${period.label.toLowerCase()}',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Save bills locally or download from Sync.',
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final invoice = filtered[index];
                    return _InvoiceTile(
                      invoice: invoice,
                      currency: currency,
                      timeFormat: timeFormat,
                      onTap: () =>
                          context.push('/reports/invoice/${invoice.invoiceId}'),
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

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _InvoiceTile extends StatelessWidget {
  const _InvoiceTile({
    required this.invoice,
    required this.currency,
    required this.timeFormat,
    required this.onTap,
  });

  final Invoice invoice;
  final NumberFormat currency;
  final DateFormat timeFormat;
  final VoidCallback onTap;

  String get _typeLabel {
    return switch (invoice.invoiceType) {
      'take_away' => 'Takeaway',
      'table_wise' => 'Table',
      _ => 'POS',
    };
  }

  IconData get _icon {
    return switch (invoice.invoiceType) {
      'take_away' => Icons.takeout_dining_rounded,
      'table_wise' => Icons.table_restaurant_rounded,
      _ => Icons.receipt_long_rounded,
    };
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
            padding: EdgeInsets.zero,
            child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: AppColors.primaryLight,
          child: Icon(_icon, color: AppColors.primary),
        ),
        title: Text(
          invoice.invoiceNumber,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          [
            timeFormat.format(invoice.invoiceDate),
            _typeLabel,
            invoice.paymentMode,
            if (invoice.customerName != null) invoice.customerName!,
            if (invoice.noOfTable.trim().isNotEmpty) 'T${invoice.noOfTable}',
          ].join(' Â· '),
        ),
        trailing: Text(
          currency.format(invoice.totalAmount),
          style: const TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
