import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:pos_billingwala_v2/core/constants/app_colors.dart';
import 'package:pos_billingwala_v2/core/database/app_database.dart';
import 'package:pos_billingwala_v2/features/reports/domain/report_export.dart';
import 'package:pos_billingwala_v2/features/reports/domain/reports_providers.dart';
import 'package:pos_billingwala_v2/features/reports/presentation/report_period_controls.dart';
import 'package:pos_billingwala_v2/core/widgtes/widgtes.dart';
import 'package:pos_billingwala_v2/core/widgets/app_module_icon.dart';

/// Reusable operational report: period chips, optional payment KPIs, invoice list.
class OperationalReportPage extends ConsumerStatefulWidget {
  const OperationalReportPage({
    super.key,
    required this.title,
    this.typeFilter,
    this.paymentFilter,
    this.paymentBreakdown = false,
  });

  final String title;
  final ReportInvoiceTypeFilter? typeFilter;
  final ReportPaymentFilter? paymentFilter;
  final bool paymentBreakdown;

  @override
  ConsumerState<OperationalReportPage> createState() =>
      _OperationalReportPageState();
}

class _OperationalReportPageState extends ConsumerState<OperationalReportPage> {
  late final bool _showTypeChips;

  @override
  void initState() {
    super.initState();
    _showTypeChips = widget.typeFilter == null ||
        widget.typeFilter == ReportInvoiceTypeFilter.all;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(reportInvoiceTypeFilterProvider.notifier).select(
            widget.typeFilter ?? ReportInvoiceTypeFilter.all,
          );
      ref.read(reportPaymentFilterProvider.notifier).select(
            widget.paymentFilter ?? ReportPaymentFilter.all,
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final period = ref.watch(reportPeriodProvider);
    final paymentFilter = ref.watch(reportPaymentFilterProvider);
    final typeFilter = ref.watch(reportInvoiceTypeFilterProvider);
    final invoicesAsync = ref.watch(periodInvoicesProvider);
    final filtered = ref.watch(filteredPeriodInvoicesProvider);
    final summary = ref.watch(periodSalesSummaryProvider);
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
    final timeFormat = DateFormat('dd MMM, hh:mm a');

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            tooltip: 'Export CSV',
            onPressed: filtered.isEmpty
                ? null
                : () => shareInvoicesCsv(
                      invoices: filtered,
                      title: '${widget.title} — ${period.label}',
                    ),
            icon: const Icon(Icons.ios_share_rounded),
          ),
          IconButton(
            tooltip: 'Pick a month',
            onPressed: () => pickReportMonth(context, ref),
            icon: const Icon(Icons.calendar_view_month_rounded),
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
      body: Column(children: [
        Container(margin: const EdgeInsets.fromLTRB(16, 10, 16, 4), padding: const EdgeInsets.all(14), decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppColors.primary, AppColors.purple]), borderRadius: BorderRadius.circular(22)), child: Row(children: [AppModuleIcon(icon: widget.paymentBreakdown ? Icons.account_balance_wallet_rounded : Icons.analytics_rounded, color: Colors.white, size: 48), const SizedBox(width: 12), Expanded(child: Text('Track ${widget.title.toLowerCase()} performance', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)))])),
        Expanded(child: Column(
        children: [
          Container(margin: const EdgeInsets.fromLTRB(16, 10, 16, 0), padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: .08), borderRadius: BorderRadius.circular(20)), child: const Row(children: [AppModuleIcon(icon: Icons.insights_rounded, color: AppColors.primary, size: 48), SizedBox(width: 12), Expanded(child: Text('Live operational insights', style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.navy)))])),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: SegmentedButton<ReportPeriodKind>(
              segments: [
                const ButtonSegment(
                  value: ReportPeriodKind.today,
                  label: Text('Today'),
                ),
                ButtonSegment(
                  value: ReportPeriodKind.month,
                  label: Text(period.kind == ReportPeriodKind.month
                      ? period.label
                      : 'Month'),
                ),
                const ButtonSegment(
                  value: ReportPeriodKind.day,
                  label: Text('Day'),
                ),
              ],
              selected: {period.kind},
              onSelectionChanged: (value) {
                final kind = value.first;
                if (kind == ReportPeriodKind.month &&
                    period.kind == ReportPeriodKind.month) {
                  pickReportMonth(context, ref);
                  return;
                }
                onReportPeriodSelected(ref, kind, period);
              },
            ),
          ),
          if (_showTypeChips)
            SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                children: [
                  for (final entry in const [
                    (ReportInvoiceTypeFilter.all, 'All'),
                    (ReportInvoiceTypeFilter.pos, 'POS'),
                    (ReportInvoiceTypeFilter.table, 'Table'),
                    (ReportInvoiceTypeFilter.takeaway, 'Takeaway'),
                    (ReportInvoiceTypeFilter.mess, 'Mess'),
                    (ReportInvoiceTypeFilter.discountOnly, 'Discount'),
                    (ReportInvoiceTypeFilter.refundOnly, 'Refund'),
                  ])
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(entry.$2),
                        selected: typeFilter == entry.$1,
                        onSelected: (_) => ref
                            .read(reportInvoiceTypeFilterProvider.notifier)
                            .select(entry.$1),
                      ),
                    ),
                ],
              ),
            ),
          if (!widget.paymentBreakdown)
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
          if (widget.paymentBreakdown)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  Expanded(
                    child: _PayKpi(
                      label: 'Cash',
                      value: currency.format(summary.cashTotal),
                      count: filtered
                          .where((e) => e.paymentMode == 'Cash')
                          .length,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _PayKpi(
                      label: 'UPI',
                      value: currency.format(summary.upiTotal),
                      count: filtered
                          .where(
                            (e) =>
                                e.paymentMode == 'UPI' ||
                                e.paymentMode == 'Online',
                          )
                          .length,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _PayKpi(
                      label: 'Cash+UPI',
                      value: currency.format(
                        filtered
                            .where((e) => e.paymentMode == 'Cash+UPI')
                            .fold<double>(0, (s, e) => s + e.totalAmount),
                      ),
                      count: filtered
                          .where((e) => e.paymentMode == 'Cash+UPI')
                          .length,
                    ),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary,
                    AppColors.primary.withValues(alpha: 0.86),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
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
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${summary.billCount} bills • Avg ${currency.format(summary.avgBill)}',
                    style: const TextStyle(color: Colors.white70),
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
                      onTap: () => context
                          .push('/reports/invoice/${invoice.invoiceId}'),
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

class _PayKpi extends StatelessWidget {
  const _PayKpi({
    required this.label,
    required this.value,
    required this.count,
  });

  final String label;
  final String value;
  final int count;

  @override
  Widget build(BuildContext context) {
    return AppCard(
            padding: const EdgeInsets.all(12),
            child: Column(
          children: [
            Text(label, style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
            Text('$count bills', style: Theme.of(context).textTheme.bodySmall),
          ],
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
    final type = invoice.invoiceType.toLowerCase();
    if (type.contains('mess')) return 'Mess';
    return switch (invoice.invoiceType) {
      'take_away' => 'Takeaway',
      'table_wise' => 'Table',
      _ => 'POS',
    };
  }

  IconData get _icon {
    final type = invoice.invoiceType.toLowerCase();
    if (type.contains('mess')) return Icons.restaurant_rounded;
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
            if (invoice.discount > 0)
              'Disc ${currency.format(invoice.discount)}',
          ].join(' • '),
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
