import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pos_billingwala_v2/core/constants/app_colors.dart';
import 'package:pos_billingwala_v2/core/widgets/donut_chart.dart';
import 'package:pos_billingwala_v2/core/widgets/app_section_header.dart';
import 'package:pos_billingwala_v2/core/database/app_database.dart';
import 'package:pos_billingwala_v2/features/inventory/domain/inventory_providers.dart';
import 'package:pos_billingwala_v2/features/masters/domain/masters_providers.dart';
import 'package:pos_billingwala_v2/core/widgtes/widgtes.dart';
import 'package:pos_billingwala_v2/core/widgets/app_module_icon.dart';

class InventoryPage extends ConsumerStatefulWidget {
  const InventoryPage({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  ConsumerState<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends ConsumerState<InventoryPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab.clamp(0, 1),
    );
    _tabs.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final busy = ref.watch(inventoryControllerProvider).isLoading;

    ref.listen(inventoryControllerProvider, (prev, next) {
      next.whenOrNull(
        data: (msg) {
          if (msg == null) return;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
        },
        error: (e, _) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
        },
      );
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory'),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'Stock'),
            Tab(text: 'Expenses'),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Sync stock & expenses',
            onPressed: busy
                ? null
                : () => ref.read(inventoryControllerProvider.notifier).syncAll(),
            icon: busy
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.cloud_sync_rounded),
          ),
        ],
      ),
      body: Column(children: [
        Container(margin: const EdgeInsets.fromLTRB(16, 12, 16, 0), padding: const EdgeInsets.all(14), decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryDark]), borderRadius: BorderRadius.circular(20)), child: const Row(children: [AppModuleIcon(icon: Icons.inventory_2_rounded, color: Colors.white, size: 48), SizedBox(width: 12), Expanded(child: Text('Track stock and expenses', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)))])),
        Expanded(child: TabBarView(
        controller: _tabs,
        children: const [
          _StockTab(),
          _ExpensesTab(),
        ],
      )),
      ]),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (_tabs.index == 0) {
            _showAddStock(context);
          } else {
            _showAddExpense(context);
          }
        },
        icon: const Icon(Icons.add_rounded),
        label: Text(_tabs.index == 0 ? 'Add stock' : 'Add expense'),
      )),
      ]),
    );
  }

  Future<void> _showAddStock(BuildContext context) async {
    final products = await ref.read(mastersRepositoryProvider).watchProducts().first;
    if (!context.mounted) return;
    if (products.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sync Masters products first')),
      );
      return;
    }

    Product? selected = products.first;
    final qtyCtrl = TextEditingController(text: '1');

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: const Text('Add stock'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppDropdownFormField<Product>(
                label: 'Product',
                items: products,
                itemLabel: (p) => p.productName,
                value: selected,
                onChanged: (value) => setLocal(() => selected = value),
              ),
              const SizedBox(height: 12),
              AppTextField(
                      controller: qtyCtrl,
                      label: 'Quantity',
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
                    ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            AppButton(
            label: 'Save',
            onPressed: () => Navigator.pop(context, true),
          ),
          ],
        ),
      ),
    );

    if (ok != true || selected == null || !context.mounted) return;
    final qty = double.tryParse(qtyCtrl.text.trim()) ?? 0;
    await ref.read(inventoryControllerProvider.notifier).addStock(
          productId: selected!.productId,
          productName: selected!.productName,
          quantity: qty,
        );
  }

  Future<void> _showAddExpense(BuildContext context) async {
    final nameCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add expense'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppTextField(
                      controller: nameCtrl,
                      label: 'Expense name',
                    ),
            const SizedBox(height: 12),
            AppTextField(
                      controller: amountCtrl,
                      label: 'Amount',
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
                    ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          AppButton(
            label: 'Save',
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final amount = double.tryParse(amountCtrl.text.trim()) ?? 0;
    await ref.read(inventoryControllerProvider.notifier).addExpense(
          name: nameCtrl.text,
          amount: amount,
        );
  }
}

class _StockTab extends ConsumerWidget {
  const _StockTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balances = ref.watch(stockBalancesProvider);
    final movementsAsync = ref.watch(inventoryMovementsProvider);
    final qtyFormat = NumberFormat('#0.##');
    final lowCount = balances.where((b) => b.lowStock).length;
    final healthyCount = balances.length - lowCount;
    final totalQty = balances.fold<double>(0, (sum, b) => sum + b.remaining);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      children: [
        AppCard(
          padding: const EdgeInsets.all(18),
          accentColor: AppColors.teal,
          child: Row(
            children: [
              DonutChart(
                values: [healthyCount.toDouble(), lowCount.toDouble()],
                colors: const [AppColors.green, AppColors.orange],
                centerValue: balances.length.toString(),
                centerTitle: 'Products',
                size: 126,
                strokeWidth: 15,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Inventory health', style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.navy)),
                    const SizedBox(height: 8),
                    Text(qtyFormat.format(totalQty) + ' total units', style: TextStyle(color: AppColors.navy.withValues(alpha: .6))),
                    const SizedBox(height: 8),
                    Text(lowCount.toString() + ' low stock', style: const TextStyle(color: AppColors.orange, fontWeight: FontWeight.w800)),
                    Text(healthyCount.toString() + ' healthy items', style: const TextStyle(color: AppColors.green, fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const AppSectionHeader(
          title: 'Current stock',
          subtitle: 'Live quantity and low-stock alerts',
        ),
        const SizedBox(height: 8),
        if (balances.isEmpty)
          const AppCard(
            padding: EdgeInsets.zero,
            child: ListTile(
              leading: Icon(Icons.inventory_2_outlined),
              title: Text('No stock yet'),
              subtitle: Text('Tap Add stock to create the first ledger row.'),
            ),
          )
        else
          ...balances.map(
            (b) => AppCard(
            color: b.lowStock
                  ? AppColors.warning.withValues(alpha: 0.12)
                  : null,
            padding: EdgeInsets.zero,
            child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: b.lowStock
                      ? AppColors.warning.withValues(alpha: 0.2)
                      : AppColors.primaryLight,
                  child: Icon(
                    Icons.inventory_2_rounded,
                    color: b.lowStock ? AppColors.warning : AppColors.primary,
                  ),
                ),
                title: Text(
                  b.productName,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(b.lowStock ? 'Low stock' : 'In stock'),
                trailing: Text(
                  qtyFormat.format(b.remaining),
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: b.lowStock ? AppColors.warning : AppColors.primary,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
          ),
        const SizedBox(height: 20),
        const AppSectionHeader(
          title: 'Recent movements',
          subtitle: 'Latest stock activity',
        ),
        const SizedBox(height: 8),
        movementsAsync.when(
          data: (rows) {
            if (rows.isEmpty) {
              return const Text('No movements yet');
            }
            final dateFmt = DateFormat('dd MMM');
            return Column(
              children: rows.take(40).map((row) {
                final isIn = row.saleInventoryQuantity <= 0;
                return AppCard(
            padding: EdgeInsets.zero,
            child: ListTile(
                    dense: true,
                    leading: Icon(
                      isIn ? Icons.add_circle_outline : Icons.remove_circle_outline,
                      color: isIn ? AppColors.success : AppColors.danger,
                    ),
                    title: Text(
                      row.productName.isEmpty
                          ? 'Product ${row.productId}'
                          : row.productName,
                    ),
                    subtitle: Text(
                      '${isIn ? 'Stock in' : 'Sale out'} Â· ${dateFmt.format(row.inventoryDate)}',
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          isIn
                              ? '+${qtyFormat.format(row.productInventoryQuantity)}'
                              : '-${qtyFormat.format(row.saleInventoryQuantity)}',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: isIn ? AppColors.success : AppColors.danger,
                          ),
                        ),
                        Text(
                          'Bal ${qtyFormat.format(row.afterSaleInventoryQuantity)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('$e'),
        ),
      ],
    );
  }
}

class _ExpensesTab extends ConsumerWidget {
  const _ExpensesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(expensesProvider);
    final total = ref.watch(expensesTotalProvider);
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
    final dateFmt = DateFormat('dd MMM yyyy');

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppColors.red, AppColors.orangeDark]),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total expenses',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.white70),
                ),
                const SizedBox(height: 4),
                Text(
                  currency.format(total),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: expensesAsync.when(
            data: (rows) {
              if (rows.isEmpty) {
                return const Center(child: Text('No expenses yet'));
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                itemCount: rows.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final row = rows[index];
                  return AppCard(
            padding: EdgeInsets.zero,
            child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: AppColors.primaryLight,
                        child: Icon(
                          Icons.payments_outlined,
                          color: AppColors.primary,
                        ),
                      ),
                      title: Text(
                        row.expensesName,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(dateFmt.format(row.expensesDate)),
                      trailing: Text(
                        currency.format(row.expensesAmount),
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppColors.danger,
                        ),
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
    );
  }
}
