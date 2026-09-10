import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:pos_billingwala_v2/core/constants/app_colors.dart';
import 'package:pos_billingwala_v2/core/database/app_database.dart';
import 'package:pos_billingwala_v2/core/database/database_provider.dart';
import 'package:pos_billingwala_v2/features/reports/domain/reports_providers.dart';
import 'package:pos_billingwala_v2/core/widgtes/widgtes.dart';
import 'package:pos_billingwala_v2/core/widgets/app_module_icon.dart';

/// High-level sales dashboard: KPIs, 7-day trend, payment donut, recent bills.
class SalesDashboardPage extends ConsumerWidget {
  const SalesDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(todaySalesSummaryProvider);
    final month = ref.watch(monthSalesSummaryProvider);
    final todayAsync = ref.watch(todayInvoicesProvider);
    final trendAsync = ref.watch(_last7DaysProvider);
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
    final timeFormat = DateFormat('hh:mm a');
    final dayLabel = DateFormat('E');

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(title: const Text('Sales Overview')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppColors.primary, AppColors.purple]), borderRadius: BorderRadius.circular(22)), child: const Row(children: [AppModuleIcon(icon: Icons.auto_graph_rounded, color: Colors.white, size: 52), SizedBox(width: 12), Expanded(child: Text('Live sales performance at a glance', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)))])),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _DashKpi(
                  label: 'Today',
                  value: currency.format(today.totalSales),
                  sub: '${today.billCount} bills',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DashKpi(
                  label: 'This month',
                  value: currency.format(month.totalSales),
                  sub: '${month.billCount} bills',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Last 7 days',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
          ),
          const SizedBox(height: 8),
          AppCard(
            accentColor: AppColors.purple,
            padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
            child: trendAsync.when(
                data: (points) => SizedBox(
                  height: 160,
                  child: _BarTrendChart(
                    points: points,
                    dayLabel: dayLabel,
                    currency: currency,
                  ),
                ),
                loading: () => const SizedBox(
                  height: 160,
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('$e'),
                ),
              ),
          ),
          const SizedBox(height: 16),
          Text(
            'Payment mix today',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
          ),
          const SizedBox(height: 8),
          AppCard(
            padding: const EdgeInsets.all(16),
            child: Row(
                children: [
                  SizedBox(
                    width: 110,
                    height: 110,
                    child: CustomPaint(
                      painter: _DonutPainter(
                        cash: today.cashTotal,
                        upi: today.upiTotal,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      children: [
                        _MixCard(
                          label: 'Cash',
                          value: currency.format(today.cashTotal),
                          color: AppColors.primary,
                        ),
                        const SizedBox(height: 8),
                        _MixCard(
                          label: 'UPI',
                          value: currency.format(today.upiTotal),
                          color: const Color(0xFF2E7D32),
                        ),
                        const SizedBox(height: 8),
                        _MixCard(
                          label: 'Avg bill',
                          value: currency.format(today.avgBill),
                          color: Colors.blueGrey,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Recent bills today',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                ),
              ),
              TextButton(
                onPressed: () {
                  ref
                      .read(reportInvoiceTypeFilterProvider.notifier)
                      .select(ReportInvoiceTypeFilter.all);
                  ref
                      .read(reportPaymentFilterProvider.notifier)
                      .select(ReportPaymentFilter.all);
                  context.push('/reports/invoices');
                },
                child: const Text('All invoices'),
              ),
            ],
          ),
          const SizedBox(height: 4),
          todayAsync.when(
            data: (invoices) {
              final recent = invoices.take(10).toList();
              if (recent.isEmpty) {
                return const AppCard(
                  padding: EdgeInsets.all(24),
                  child: Center(child: Text('No bills today yet')),
                );
              }
              return AppCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    for (var i = 0; i < recent.length; i++) ...[
                      if (i > 0) const Divider(height: 1),
                      ListTile(
                        onTap: () => context.push(
                          '/reports/invoice/${recent[i].invoiceId}',
                        ),
                        title: Text(
                          recent[i].invoiceNumber,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(
                          [
                            timeFormat.format(recent[i].invoiceDate),
                            recent[i].paymentMode,
                            recent[i].invoiceType,
                          ].join(' · '),
                        ),
                        trailing: Text(
                          currency.format(recent[i].totalAmount),
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (e, _) => AppCard(
              padding: const EdgeInsets.all(16),
              child: Text('$e'),
            ),
          ),
        ],
      ),
    );
  }
}

final _last7DaysProvider = FutureProvider<List<DailySalesPoint>>((ref) {
  return ref.watch(appDatabaseProvider).getDailySalesLastDays(7);
});

class _BarTrendChart extends StatelessWidget {
  const _BarTrendChart({
    required this.points,
    required this.dayLabel,
    required this.currency,
  });

  final List<DailySalesPoint> points;
  final DateFormat dayLabel;
  final NumberFormat currency;

  @override
  Widget build(BuildContext context) {
    final maxV = points.fold<double>(0, (m, p) => p.total > m ? p.total : m);
    return Column(
      children: [
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (final p in points)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (p.total > 0)
                          Text(
                            currency.format(p.total).replaceAll('.00', ''),
                            style: const TextStyle(fontSize: 9),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        const SizedBox(height: 4),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 350),
                          height: maxV <= 0
                              ? 4
                              : (4 + (p.total / maxV) * 100).clamp(4, 104),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            for (final p in points)
              Expanded(
                child: Text(
                  dayLabel.format(p.date),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({required this.cash, required this.upi});

  final double cash;
  final double upi;

  @override
  void paint(Canvas canvas, Size size) {
    final total = cash + upi;
    final rect = Offset.zero & size;
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 18
      ..strokeCap = StrokeCap.butt;
    if (total <= 0) {
      stroke.color = const Color(0xFFE0E0E0);
      canvas.drawArc(rect.deflate(12), 0, 6.28, false, stroke);
      return;
    }
    final cashSweep = (cash / total) * 6.28318530718;
    stroke.color = AppColors.primary;
    canvas.drawArc(rect.deflate(12), -1.5708, cashSweep, false, stroke);
    stroke.color = const Color(0xFF2E7D32);
    canvas.drawArc(
      rect.deflate(12),
      -1.5708 + cashSweep,
      6.28318530718 - cashSweep,
      false,
      stroke,
    );
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) =>
      oldDelegate.cash != cash || oldDelegate.upi != upi;
}

class _DashKpi extends StatelessWidget {
  const _DashKpi({
    required this.label,
    required this.value,
    required this.sub,
  });

  final String label;
  final String value;
  final String sub;

  @override
  Widget build(BuildContext context) {
    return AppCard(
            padding: const EdgeInsets.all(16),
            child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: 6),
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

class _MixCard extends StatelessWidget {
  const _MixCard({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(label)),
        Text(
          value,
          style: TextStyle(fontWeight: FontWeight.w800, color: color),
        ),
      ],
    );
  }
}
