import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:pos_billingwala_v2/core/constants/app_colors.dart';
import 'package:pos_billingwala_v2/core/database/database_provider.dart';
import 'package:pos_billingwala_v2/features/reports/domain/reports_providers.dart';
import 'package:pos_billingwala_v2/core/widgtes/widgtes.dart';

/// Android ReportsHub â€” tiles into invoice / payment / type views.
class ReportsHubPage extends ConsumerWidget {
  const ReportsHubPage({super.key});

  void _resetFilters(WidgetRef ref) {
    ref
        .read(reportInvoiceTypeFilterProvider.notifier)
        .select(ReportInvoiceTypeFilter.all);
    ref
        .read(reportPaymentFilterProvider.notifier)
        .select(ReportPaymentFilter.all);
  }

  Future<void> _clearAllInvoices(BuildContext context, WidgetRef ref) async {
    final db = ref.read(appDatabaseProvider);
    final pending = await db.countPendingInvoiceSync();
    if (!context.mounted) return;

    if (pending > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Sync $pending pending bill(s) first before clearing invoices.',
          ),
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear all invoices'),
        content: const Text(
          'Delete all local invoices and line items? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          AppButton(
            label: 'Clear all',
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );
    if (confirm != true || !context.mounted) return;

    try {
      await db.clearAllInvoices();
      ref.invalidate(todayInvoicesProvider);
      ref.invalidate(monthInvoicesProvider);
      ref.invalidate(periodInvoicesProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All invoices cleared')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(todaySalesSummaryProvider);
    final month = ref.watch(monthSalesSummaryProvider);
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: 'â‚¹');

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: const Text('Reports'),
        actions: [
          IconButton(
            tooltip: 'Clear all invoices',
            onPressed: () => _clearAllInvoices(context, ref),
            icon: const Icon(Icons.delete_sweep_outlined),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          AppCard(
            padding: const EdgeInsets.all(16),
            child: Row(
                children: [
                  Expanded(
                    child: _Kpi(
                      label: 'Today',
                      value: currency.format(today.totalSales),
                      sub: '${today.billCount} bills',
                    ),
                  ),
                  Container(width: 1, height: 48, color: Colors.black12),
                  Expanded(
                    child: _Kpi(
                      label: 'This month',
                      value: currency.format(month.totalSales),
                      sub: '${month.billCount} bills',
                    ),
                  ),
                ],
              ),
          ),
          const SizedBox(height: 16),
          Text(
            'Sales & analytics',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
          ),
          const SizedBox(height: 8),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _HubTile(
                  icon: Icons.dashboard_rounded,
                  title: 'Sales Overview',
                  subtitle: 'Today / month KPIs and recent bills',
                  onTap: () => context.push('/reports/dashboard'),
                ),
                const Divider(height: 1),
                _HubTile(
                  icon: Icons.receipt_long_rounded,
                  title: 'Invoice Report',
                  subtitle: 'All bills in selected period',
                  onTap: () {
                    _resetFilters(ref);
                    context.push('/reports/invoices');
                  },
                ),
                const Divider(height: 1),
                _HubTile(
                  icon: Icons.inventory_2_rounded,
                  title: 'Product-wise Report',
                  subtitle: 'Qty & amount by product / combo',
                  onTap: () => context.push('/reports/products'),
                ),
                const Divider(height: 1),
                _HubTile(
                  icon: Icons.dining_rounded,
                  title: 'Combo-wise Report',
                  subtitle: 'Sales of combo items only',
                  onTap: () => context.push('/reports/products?type=combo'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Operational',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
          ),
          const SizedBox(height: 8),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _HubTile(
                  icon: Icons.payments_rounded,
                  title: 'Payment Mode Report',
                  subtitle:
                      'Cash ${currency.format(today.cashTotal)} Â· UPI ${currency.format(today.upiTotal)} (today)',
                  onTap: () => context.push('/reports/payment-mode'),
                ),
                const Divider(height: 1),
                _HubTile(
                  icon: Icons.point_of_sale_rounded,
                  title: 'Sale / POS Report',
                  subtitle: '${today.posCount} POS bills today',
                  onTap: () => context.push('/reports/sale'),
                ),
                const Divider(height: 1),
                _HubTile(
                  icon: Icons.table_restaurant_rounded,
                  title: 'Table Report',
                  subtitle: '${today.tableCount} table bills today',
                  onTap: () => context.push('/reports/table'),
                ),
                const Divider(height: 1),
                _HubTile(
                  icon: Icons.takeout_dining_rounded,
                  title: 'Take Away Report',
                  subtitle: '${today.takeawayCount} parcels today',
                  onTap: () => context.push('/reports/takeaway'),
                ),
                const Divider(height: 1),
                _HubTile(
                  icon: Icons.discount_rounded,
                  title: 'Discount Report',
                  subtitle:
                      'Discount total ${currency.format(today.discountTotal)} today',
                  onTap: () => context.push('/reports/discount'),
                ),
                const Divider(height: 1),
                _HubTile(
                  icon: Icons.restaurant_rounded,
                  title: 'Mess Report',
                  subtitle: 'Mess / meal billing invoices',
                  onTap: () => context.push('/reports/mess'),
                ),
                const Divider(height: 1),
                _HubTile(
                  icon: Icons.replay_rounded,
                  title: 'Refund Report',
                  subtitle: 'Refunded bills',
                  onTap: () => context.push('/reports/refund'),
                ),
                const Divider(height: 1),
                _HubTile(
                  icon: Icons.groups_rounded,
                  title: 'Mess Member Report',
                  subtitle: 'Members â†’ payment history',
                  onTap: () => context.push('/reports/mess-members'),
                ),
                const Divider(height: 1),
                _HubTile(
                  icon: Icons.account_balance_wallet_outlined,
                  title: 'Expense Report',
                  subtitle: 'Shop expenses (inventory)',
                  onTap: () => context.push('/reports/expense'),
                ),
                const Divider(height: 1),
                _HubTile(
                  icon: Icons.delete_sweep_outlined,
                  title: 'Clear all invoices',
                  subtitle: 'Remove local bills after sync',
                  onTap: () => _clearAllInvoices(context, ref),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Kpi extends StatelessWidget {
  const _Kpi({
    required this.label,
    required this.value,
    required this.sub,
  });

  final String label;
  final String value;
  final String sub;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
          ),
          Text(sub, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _HubTile extends StatelessWidget {
  const _HubTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: AppColors.primaryLight,
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right_rounded),
    );
  }
}
