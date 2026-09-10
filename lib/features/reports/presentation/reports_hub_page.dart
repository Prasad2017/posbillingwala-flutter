import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:pos_billingwala_v2/core/constants/app_colors.dart';
import 'package:pos_billingwala_v2/core/database/database_provider.dart';
import 'package:pos_billingwala_v2/core/widgets/app_module_icon.dart';
import 'package:pos_billingwala_v2/core/widgets/app_section_header.dart';
import 'package:pos_billingwala_v2/core/widgets/donut_chart.dart';
import 'package:pos_billingwala_v2/core/widgets/mini_bar_chart.dart';
import 'package:pos_billingwala_v2/core/widgtes/widgtes.dart';
import 'package:pos_billingwala_v2/features/reports/domain/reports_providers.dart';

class ReportsHubPage extends ConsumerWidget {
  const ReportsHubPage({super.key});

  void _resetFilters(WidgetRef ref) {
    ref.read(reportInvoiceTypeFilterProvider.notifier).select(ReportInvoiceTypeFilter.all);
    ref.read(reportPaymentFilterProvider.notifier).select(ReportPaymentFilter.all);
  }

  Future<void> _clearAllInvoices(BuildContext context, WidgetRef ref) async {
    final db = ref.read(appDatabaseProvider);
    final pending = await db.countPendingInvoiceSync();
    if (!context.mounted) return;
    if (pending > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sync ' + pending.toString() + ' pending bill(s) first.')),
      );
      return;
    }
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear all invoices'),
        content: const Text('Delete all local invoices and line items? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.red),
            child: const Text('Clear all'),
          ),
        ],
      ),
    );
    if (confirm != true || !context.mounted) return;
    await db.clearAllInvoices();
    ref.invalidate(todayInvoicesProvider);
    ref.invalidate(monthInvoicesProvider);
    ref.invalidate(periodInvoicesProvider);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('All invoices cleared')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(todaySalesSummaryProvider);
    final month = ref.watch(monthSalesSummaryProvider);
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
    final cash = today.cashTotal.toDouble();
    final upi = today.upiTotal.toDouble();
    final other = (today.totalSales - cash - upi).clamp(0, double.infinity).toDouble();

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Reports & Analytics'),
        actions: [IconButton(onPressed: () => _clearAllInvoices(context, ref), icon: const Icon(Icons.delete_sweep_outlined))],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          _HeroSalesCard(
            amount: currency.format(today.totalSales),
            bills: today.billCount,
            onTap: () => context.push('/reports/dashboard'),
          ),
          const SizedBox(height: 20),
          const AppSectionHeader(title: 'Business overview', subtitle: 'Your business performance at a glance'),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: _MiniKpi(icon: Icons.receipt_long_rounded, color: AppColors.primary, label: 'Bills', value: today.billCount.toString())),
            const SizedBox(width: 10),
            Expanded(child: _MiniKpi(icon: Icons.calendar_month_rounded, color: AppColors.purple, label: 'Month sales', value: currency.format(month.totalSales))),
          ]),
          const SizedBox(height: 20),
          const AppSectionHeader(title: 'Payment mix', subtitle: 'Today by payment method'),
          const SizedBox(height: 10),
          AppCard(
            padding: const EdgeInsets.all(18),
            child: Row(children: [
              DonutChart(
                values: [cash, upi, other],
                colors: const [AppColors.primary, AppColors.orange, AppColors.green],
                centerValue: today.billCount.toString(),
                centerTitle: 'Bills',
              ),
              const SizedBox(width: 18),
              Expanded(child: Column(children: [
                _Legend(color: AppColors.primary, label: 'Cash', value: currency.format(cash)),
                const SizedBox(height: 12),
                _Legend(color: AppColors.orange, label: 'UPI', value: currency.format(upi)),
                const SizedBox(height: 12),
                _Legend(color: AppColors.green, label: 'Other', value: currency.format(other)),
              ])),
            ]),
          ),
          const SizedBox(height: 20),
          AppSectionHeader(
            title: 'Sales trend',
            subtitle: 'Recent performance snapshot',
            action: 'View details',
            onAction: () => context.push('/reports/dashboard'),
          ),
          const SizedBox(height: 10),
          AppCard(
            padding: const EdgeInsets.all(18),
            child: const Column(children: [
              MiniBarChart(values: [42, 65, 38, 76, 58, 88, 70], color: AppColors.primary),
              SizedBox(height: 10),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('Mon'), Text('Tue'), Text('Wed'), Text('Thu'), Text('Fri'), Text('Sat'), Text('Sun'),
              ]),
            ]),
          ),
          const SizedBox(height: 22),
          const AppSectionHeader(title: 'Explore reports', subtitle: 'Detailed business reports'),
          const SizedBox(height: 10),
          _ReportGrid(items: [
            _ReportItem(Icons.dashboard_rounded, 'Sales Overview', AppColors.primary, () => context.push('/reports/dashboard')),
            _ReportItem(Icons.receipt_long_rounded, 'Invoices', AppColors.orange, () { _resetFilters(ref); context.push('/reports/invoices'); }),
            _ReportItem(Icons.inventory_2_rounded, 'Products', AppColors.purple, () => context.push('/reports/products')),
            _ReportItem(Icons.payments_rounded, 'Payments', AppColors.green, () => context.push('/reports/payment-mode')),
            _ReportItem(Icons.table_restaurant_rounded, 'Tables', AppColors.red, () => context.push('/reports/table')),
            _ReportItem(Icons.takeout_dining_rounded, 'Takeaway', AppColors.teal, () => context.push('/reports/takeaway')),
            _ReportItem(Icons.discount_rounded, 'Discounts', AppColors.orangeDark, () => context.push('/reports/discount')),
            _ReportItem(Icons.account_balance_wallet_rounded, 'Expenses', AppColors.red, () => context.push('/reports/expense')),
            _ReportItem(Icons.restaurant_rounded, 'Mess', AppColors.teal, () => context.push('/reports/mess')),
            _ReportItem(Icons.replay_rounded, 'Refunds', AppColors.primaryDark, () => context.push('/reports/refund')),
          ]),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () => _clearAllInvoices(context, ref),
            icon: const Icon(Icons.delete_sweep_outlined, color: AppColors.red),
            label: const Text('Clear all local invoices'),
          ),
        ],
      ),
    );
  }
}

class _HeroSalesCard extends StatelessWidget {
  const _HeroSalesCard({required this.amount, required this.bills, required this.onTap});
  final String amount;
  final int bills;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(26),
    child: Ink(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryDark]),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Today\'s sales', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w700)),
          const SizedBox(height: 7),
          Text(amount, style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          Text(bills.toString() + ' bills today', style: const TextStyle(color: Colors.white)),
        ])),
        Container(
          width: 62, height: 62,
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: .16), borderRadius: BorderRadius.circular(20)),
          child: const Icon(Icons.trending_up_rounded, color: Colors.white, size: 32),
        ),
      ]),
    ),
  );
}

class _MiniKpi extends StatelessWidget {
  const _MiniKpi({required this.icon, required this.color, required this.label, required this.value});
  final IconData icon;
  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => AppCard(
    padding: const EdgeInsets.all(14),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      AppModuleIcon(icon: icon, color: color, size: 44),
      const SizedBox(height: 14),
      Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: AppColors.navy)),
      const SizedBox(height: 3),
      Text(label, style: TextStyle(color: AppColors.navy.withValues(alpha: .55), fontSize: 12)),
    ]),
  );
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label, required this.value});
  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Row(children: [
    Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
    const SizedBox(width: 8),
    Expanded(child: Text(label)),
    Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
  ]);
}

class _ReportItem {
  const _ReportItem(this.icon, this.title, this.color, this.onTap);
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;
}

class _ReportGrid extends StatelessWidget {
  const _ReportGrid({required this.items});
  final List<_ReportItem> items;

  @override
  Widget build(BuildContext context) => GridView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    itemCount: items.length,
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 2, mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 1.45,
    ),
    itemBuilder: (context, index) {
      final item = items[index];
      return InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            AppModuleIcon(icon: item.icon, color: item.color, size: 42),
            const Spacer(),
            Text(item.title, style: const TextStyle(color: AppColors.navy, fontWeight: FontWeight.w800)),
          ]),
        ),
      );
    },
  );
}
