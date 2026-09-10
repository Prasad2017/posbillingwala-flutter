import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pos_billingwala_v2/core/constants/app_colors.dart';
import 'package:pos_billingwala_v2/core/database/app_database.dart';
import 'package:pos_billingwala_v2/core/database/database_provider.dart';
import 'package:pos_billingwala_v2/features/reports/domain/report_export.dart';
import 'package:pos_billingwala_v2/features/reports/domain/reports_providers.dart';
import 'package:pos_billingwala_v2/core/widgtes/widgtes.dart';
import 'package:pos_billingwala_v2/core/widgets/app_module_icon.dart';

class ProductWiseReportPage extends ConsumerStatefulWidget {
  const ProductWiseReportPage({super.key, this.initialType = 'all'});

  final String initialType;

  @override
  ConsumerState<ProductWiseReportPage> createState() =>
      _ProductWiseReportPageState();
}

class _ProductWiseReportPageState extends ConsumerState<ProductWiseReportPage> {
  late String _typeFilter; // all | product | combo
  AsyncValue<List<ProductSalesRow>> _rows = const AsyncLoading();

  @override
  void initState() {
    super.initState();
    _typeFilter = widget.initialType == 'combo' || widget.initialType == 'product'
        ? widget.initialType
        : 'all';
    Future.microtask(_load);
  }

  Future<void> _load() async {
    final period = ref.read(reportPeriodProvider);
    final (start, end) = period.range;
    setState(() => _rows = const AsyncLoading());
    final result = await AsyncValue.guard(() {
      return ref.read(appDatabaseProvider).getProductWiseSales(
            start: start,
            end: end,
            invoiceItemType: _typeFilter == 'all' ? null : _typeFilter,
          );
    });
    if (!mounted) return;
    setState(() => _rows = result);
  }

  @override
  Widget build(BuildContext context) {
    final period = ref.watch(reportPeriodProvider);
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    ref.listen(reportPeriodProvider, (_, _) => _load());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Product-wise Report'),
        actions: [
          IconButton(
            tooltip: 'Export CSV',
            onPressed: () {
              final rows = _rows.asData?.value;
              if (rows == null || rows.isEmpty) return;
              shareProductSalesCsv(
                rows: rows,
                title: 'Product-wise — ${period.label}',
              );
            },
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
          Container(margin: const EdgeInsets.fromLTRB(16, 10, 16, 0), padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: AppColors.purple.withValues(alpha: .08), borderRadius: BorderRadius.circular(20)), child: const Row(children: [AppModuleIcon(icon: Icons.inventory_2_rounded, color: AppColors.purple, size: 48), SizedBox(width: 12), Expanded(child: Text('Discover your best-selling items', style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.navy)))])),
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
                switch (value.first) {
                  case ReportPeriodKind.today:
                    ref.read(reportPeriodProvider.notifier).useToday();
                  case ReportPeriodKind.month:
                    ref.read(reportPeriodProvider.notifier).useMonth();
                  case ReportPeriodKind.day:
                    ref
                        .read(reportPeriodProvider.notifier)
                        .useDay(period.day ?? DateTime.now());
                }
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'all', label: Text('All')),
                ButtonSegment(value: 'product', label: Text('Products')),
                ButtonSegment(value: 'combo', label: Text('Combos')),
              ],
              selected: {_typeFilter},
              onSelectionChanged: (v) {
                setState(() => _typeFilter = v.first);
                _load();
              },
            ),
          ),
          Expanded(
            child: _rows.when(
              data: (rows) {
                if (rows.isEmpty) {
                  return const Center(child: Text('No sales in this period'));
                }
                final totalQty =
                    rows.fold<int>(0, (s, r) => s + r.totalQuantity);
                final totalAmt =
                    rows.fold<double>(0, (s, r) => s + r.totalAmount);
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: AppCard(
            color: AppColors.primaryLight,
            padding: EdgeInsets.zero,
            child: ListTile(
                          title: Text(
                            '${rows.length} items • Qty $totalQty',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          trailing: Text(
                            currency.format(totalAmt),
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
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        itemCount: rows.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 6),
                        itemBuilder: (context, index) {
                          final row = rows[index];
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
                                row.productName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              subtitle: Text(
                                'Qty ${row.totalQuantity}'
                                '${row.itemType == 'combo' ? ' • Combo' : ''}',
                              ),
                              trailing: Text(
                                currency.format(row.totalAmount),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary,
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
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('$e')),
            ),
          ),
        ],
      )),
      ]),
    );
  }
}
