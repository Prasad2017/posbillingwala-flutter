import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pos_billingwala_v2/core/constants/app_colors.dart';
import 'package:pos_billingwala_v2/core/database/app_database.dart';
import 'package:pos_billingwala_v2/features/inventory/domain/inventory_providers.dart';
import 'package:pos_billingwala_v2/features/reports/domain/report_export.dart';
import 'package:pos_billingwala_v2/features/reports/domain/reports_providers.dart';
import 'package:pos_billingwala_v2/features/reports/presentation/report_period_controls.dart';
import 'package:pos_billingwala_v2/core/widgtes/widgtes.dart';
import 'package:pos_billingwala_v2/core/widgets/app_module_icon.dart';

/// Expense-wise report with period filter and Excel share.
class ExpenseReportPage extends ConsumerWidget {
  const ExpenseReportPage({super.key});

  List<ShopExpense> _inPeriod(
    List<ShopExpense> rows,
    ReportPeriod period,
  ) {
    final range = period.range;
    return rows
        .where(
          (e) =>
              !e.expensesDate.isBefore(range.$1) &&
              e.expensesDate.isBefore(range.$2),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final period = ref.watch(reportPeriodProvider);
    final expensesAsync = ref.watch(expensesProvider);
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
    final dateFmt = DateFormat('dd MMM yyyy, hh:mm a');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Report'),
        actions: [
          IconButton(
            tooltip: 'Export',
            onPressed: expensesAsync.maybeWhen(
              data: (all) {
                final filtered = _inPeriod(all, period);
                if (filtered.isEmpty) return null;
                return () => shareExpensesCsv(
                      expenses: filtered,
                      title: 'Expense Report — ${period.label}',
                    );
              },
              orElse: () => null,
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
      body: Column(
        children: [
          Padding(padding: const EdgeInsets.fromLTRB(16, 12, 16, 0), child: Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: AppColors.red.withValues(alpha: .08), borderRadius: BorderRadius.circular(20)), child: const Row(children: [AppModuleIcon(icon: Icons.account_balance_wallet_rounded, color: AppColors.red, size: 48), SizedBox(width: 12), Expanded(child: Text('Understand where your business spends', style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.navy)))]))),
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
          Expanded(
            child: expensesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('$e')),
              data: (all) {
                final filtered = _inPeriod(all, period);
                var total = 0.0;
                for (final row in filtered) {
                  total += row.expensesAmount;
                }
                if (filtered.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const AppModuleIcon(
                            icon: Icons.account_balance_wallet_outlined,
                            color: AppColors.orange,
                            size: 72,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No expenses for ${period.label}',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Add expenses from Inventory Management.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: AppCard(
                        accentColor: AppColors.orange,
                        color: AppColors.orange.withValues(alpha: .08),
                        padding: EdgeInsets.zero,
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          leading: const AppModuleIcon(icon: Icons.account_balance_wallet_rounded, color: AppColors.orange, size: 50),
                          title: Text(
                            '${filtered.length} expense'
                            '${filtered.length == 1 ? '' : 's'}',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          trailing: Text(
                            currency.format(total),
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        itemCount: filtered.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final row = filtered[index];
                          return AppCard(
            padding: EdgeInsets.zero,
            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: AppColors.primaryLight,
                                child: Text(
                                  '${index + 1}',
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              title: Text(
                                row.expensesName.isEmpty
                                    ? 'Expense'
                                    : row.expensesName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              subtitle: Text(dateFmt.format(row.expensesDate)),
                              trailing: Text(
                                currency.format(row.expensesAmount),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
