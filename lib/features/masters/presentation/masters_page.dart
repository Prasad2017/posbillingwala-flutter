import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:pos_billingwala_v2/core/constants/app_colors.dart';
import 'package:pos_billingwala_v2/core/database/app_database.dart';
import 'package:pos_billingwala_v2/core/database/database_provider.dart';
import 'package:pos_billingwala_v2/features/masters/domain/masters_providers.dart';
import 'package:pos_billingwala_v2/features/print/domain/print_providers.dart';
import 'package:pos_billingwala_v2/core/widgtes/widgtes.dart';
import 'package:pos_billingwala_v2/core/widgets/app_module_icon.dart';

class MastersPage extends ConsumerWidget {
  const MastersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final productsAsync = ref.watch(productsProvider);
    final selectedCategoryId = ref.watch(selectedCategoryIdProvider);
    final syncState = ref.watch(mastersSyncControllerProvider);
    final countsAsync = ref.watch(catalogCountsProvider);
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    ref.listen(mastersSyncControllerProvider, (prev, next) {
      next.whenOrNull(
        data: (result) {
          if (result == null) return;
          final parts = <String>[];
          if (result.uploadedPending > 0) {
            parts.add('uploaded ${result.uploadedPending} pending');
          }
          if (result.categoryCount > 0 || result.productCount > 0) {
            parts.add(
              'downloaded ${result.categoryCount} categories, '
              '${result.productCount} products, '
              '${result.portionCount} portions'
              '${result.subcategoryCount > 0 ? ', ${result.subcategoryCount} subcategories' : ''}'
              '${result.comboCount > 0 ? ', ${result.comboCount} combos' : ''}'
              '${result.tableCount > 0 ? ', ${result.tableCount} tables' : ''}',
            );
          }
          if (parts.isEmpty) {
            parts.add('Masters sync finished');
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(parts.join(' • '))),
          );
        },
        error: (error, _) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error.toString())),
          );
        },
      );
    });

    final isSyncing = syncState.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Masters'),
        actions: [
          IconButton(
            tooltip: 'Upload pending',
            onPressed: isSyncing
                ? null
                : () => ref
                    .read(mastersSyncControllerProvider.notifier)
                    .uploadPending(),
            icon: const Icon(Icons.cloud_upload_rounded),
          ),
          IconButton(
            tooltip: 'Download from cloud',
            onPressed: isSyncing
                ? null
                : () =>
                    ref.read(mastersSyncControllerProvider.notifier).syncNow(),
            icon: isSyncing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.cloud_download_rounded),
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'category') {
                await _showAddCategoryDialog(context, ref);
              } else if (value == 'product') {
                await _showAddProductDialog(context, ref);
              } else if (value == 'combo') {
                await _showAddComboDialog(context, ref);
              } else if (value == 'subcategories') {
                context.push('/masters/subcategories');
              } else if (value == 'tables') {
                context.push('/masters/tables');
              } else if (value == 'portions') {
                context.push('/masters/portion-masters');
              } else if (value == 'print_catalog') {
                await _printCatalog(context, ref);
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'category', child: Text('Add category')),
              PopupMenuItem(value: 'product', child: Text('Add product')),
              PopupMenuItem(value: 'combo', child: Text('Add combo')),
              PopupMenuItem(
                value: 'subcategories',
                child: Text('Subcategories'),
              ),
              PopupMenuItem(
                value: 'portions',
                child: Text('Portion masters'),
              ),
              PopupMenuItem(value: 'tables', child: Text('Table master')),
              PopupMenuItem(
                value: 'print_catalog',
                child: Text('Print product list'),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: isSyncing
            ? null
            : () => _showAddProductDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Add product'),
      ),
      body: Column(
        children: [
          Container(margin: const EdgeInsets.fromLTRB(16, 10, 16, 0), padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: .08), borderRadius: BorderRadius.circular(20)), child: const Row(children: [AppModuleIcon(icon: Icons.category_rounded, color: AppColors.primary, size: 48), SizedBox(width: 12), Expanded(child: Text('Products, categories & business catalog', style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.navy)))])),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: countsAsync.when(
              data: (counts) => Row(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _CountChip(label: 'Categories', value: '${counts.categories}', icon: Icons.category_rounded, color: AppColors.purple),
                          const SizedBox(width: 8),
                          _CountChip(label: 'Products', value: '${counts.products}', icon: Icons.inventory_2_rounded, color: AppColors.primary),
                          const SizedBox(width: 8),
                          _CountChip(label: 'Combos', value: '${counts.combos}', icon: Icons.auto_awesome_rounded, color: AppColors.orange),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: IconButton(
                      tooltip: isSyncing ? 'Syncing' : 'Sync catalog',
                      onPressed: isSyncing ? null : () => ref.read(mastersSyncControllerProvider.notifier).syncNow(),
                      icon: isSyncing
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.sync_rounded),
                    ),
                  ),
                ],
              ),
              loading: () => const LinearProgressIndicator(minHeight: 2),
              error: (_, _) => const SizedBox.shrink(),
            ),
          ),
          SizedBox(
            height: 48,
            child: categoriesAsync.when(
              data: (categories) {
                if (categories.isEmpty) {
                  return const Center(
                    child: Text('No categories — tap Sync to download'),
                  );
                }
                return ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: const Text('All'),
                        selected: selectedCategoryId == null,
                        onSelected: (_) => ref
                            .read(selectedCategoryIdProvider.notifier)
                            .select(null),
                      ),
                    ),
                    ...categories.asMap().entries.map(
                      (entry) {
                        final index = entry.key;
                        final category = entry.value;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onLongPress: () async {
                              final action = await showAppBottomSheet<String>(
                                context: context,
                                title: category.categoryName,
                                icon: Icons.category_outlined,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      leading: const Icon(Icons.edit_outlined),
                                      title: const Text('Edit category'),
                                      onTap: () =>
                                          Navigator.pop(context, 'edit'),
                                    ),
                                    if (index > 0)
                                      ListTile(
                                        contentPadding: EdgeInsets.zero,
                                        leading: const Icon(
                                          Icons.arrow_back_rounded,
                                        ),
                                        title: const Text('Move earlier'),
                                        onTap: () =>
                                            Navigator.pop(context, 'left'),
                                      ),
                                    if (index < categories.length - 1)
                                      ListTile(
                                        contentPadding: EdgeInsets.zero,
                                        leading: const Icon(
                                          Icons.arrow_forward_rounded,
                                        ),
                                        title: const Text('Move later'),
                                        onTap: () =>
                                            Navigator.pop(context, 'right'),
                                      ),
                                  ],
                                ),
                              );
                              if (action == 'edit') {
                                if (!context.mounted) return;
                                await _showEditCategoryDialog(
                                  context,
                                  ref,
                                  category,
                                );
                              } else if (action == 'left' ||
                                  action == 'right') {
                                final swapWith = action == 'left'
                                    ? categories[index - 1]
                                    : categories[index + 1];
                                final aOrder = category.categorySortOrder;
                                final bOrder = swapWith.categorySortOrder;
                                await ref
                                    .read(appDatabaseProvider)
                                    .updateCategorySortOrder(
                                      category.categoryId,
                                      bOrder == aOrder
                                          ? aOrder - 1
                                          : bOrder,
                                    );
                                await ref
                                    .read(appDatabaseProvider)
                                    .updateCategorySortOrder(
                                      swapWith.categoryId,
                                      aOrder == bOrder
                                          ? bOrder + 1
                                          : aOrder,
                                    );
                              }
                            },
                            child: FilterChip(
                              avatar: category.categorySyncStatus == '0'
                                  ? const Icon(Icons.cloud_off, size: 16)
                                  : null,
                              label: Text(category.categoryName),
                              selected:
                                  selectedCategoryId == category.categoryId,
                              onSelected: (_) => ref
                                  .read(selectedCategoryIdProvider.notifier)
                                  .select(category.categoryId),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                );
              },
              loading: () => const Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
              error: (e, _) => Center(child: Text('$e')),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  const TabBar(
                    tabs: [
                      Tab(text: 'Products'),
                      Tab(text: 'Combos'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        productsAsync.when(
                          data: (products) {
                            if (products.isEmpty) {
                              return const Center(
                                child: Text('No products yet'),
                              );
                            }
                            return ListView.separated(
                              padding:
                                  const EdgeInsets.fromLTRB(16, 8, 16, 88),
                              itemCount: products.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                final product = products[index];
                                return _ProductTile(
                                  product: product,
                                  priceLabel: currency
                                      .format(product.productPrice),
                                  onEdit: () => _showEditProductDialog(
                                    context,
                                    ref,
                                    product,
                                  ),
                                  onDelete: () => _confirmDeleteProduct(
                                    context,
                                    ref,
                                    product,
                                  ),
                                );
                              },
                            );
                          },
                          loading: () => const Center(
                            child: CircularProgressIndicator(),
                          ),
                          error: (e, _) => Center(child: Text('$e')),
                        ),
                        _CombosTab(currency: currency),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> _printCatalog(BuildContext context, WidgetRef ref) async {
  final products = await ref.read(appDatabaseProvider).watchActiveProducts().first;
  if (products.isEmpty) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No products to print')),
      );
    }
    return;
  }
  final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
  final buf = StringBuffer()
    ..writeln('PRODUCT LIST')
    ..writeln(DateFormat('dd MMM yyyy HH:mm').format(DateTime.now()))
    ..writeln('-' * 32);
  for (final p in products) {
    buf.writeln(p.productName);
    buf.writeln('  ${currency.format(p.productPrice)}');
  }
  buf.writeln('-' * 32);
  buf.writeln('Total items: ${products.length}');
  final result = await ref.read(printServiceProvider).printRawText(
        buf.toString(),
        label: 'Product catalog',
      );
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(result.message ?? result.outcome.name)),
  );
}

Future<void> _showAddCategoryDialog(BuildContext context, WidgetRef ref) async {
  final controller = TextEditingController();
  final foodTypes = ref.read(foodTypesProvider).maybeWhen(
        data: (v) => v,
        orElse: () => const <FoodType>[],
      );
  FoodType? selectedFoodType = foodTypes.isEmpty ? null : foodTypes.first;
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setLocal) => AlertDialog(
        title: const Text('Add category'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppTextField(
                      controller: controller,
                      label: 'Category name',
                    ),
            if (foodTypes.isNotEmpty) ...[
              const SizedBox(height: 12),
              AppDropdownFormField<FoodType>(
                label: 'Food type',
                items: foodTypes,
                itemLabel: (f) => f.foodTypeName,
                value: selectedFoodType,
                onChanged: (v) => setLocal(() => selectedFoodType = v),
              ),
            ],
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
  if (ok == true && controller.text.trim().isNotEmpty) {
    await ref.read(mastersSyncControllerProvider.notifier).createCategory(
          controller.text.trim(),
          foodTypeId: selectedFoodType?.foodTypeId,
          foodTypeCode: selectedFoodType?.foodTypeCode,
        );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Category saved')),
      );
    }
  }
  controller.dispose();
}

Future<void> _showAddProductDialog(BuildContext context, WidgetRef ref) async {
  final nameController = TextEditingController();
  final priceController = TextEditingController();
  final categories =
      ref.read(categoriesProvider).maybeWhen(data: (v) => v, orElse: () => null) ??
          const <ProductCategory>[];
  int? categoryId = ref.read(selectedCategoryIdProvider) ??
      (categories.isNotEmpty ? categories.first.categoryId : null);

  ProductCategory? selectedCategory() {
    if (categoryId == null) return null;
    for (final c in categories) {
      if (c.categoryId == categoryId) return c;
    }
    return null;
  }

  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text('Add product'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppTextField(
                controller: nameController,
                label: 'Product name',
              ),
              const SizedBox(height: 12),
              AppTextField(
                controller: priceController,
                label: 'Price',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 12),
              AppDropdownFormField<ProductCategory>(
                label: 'Category',
                items: categories,
                itemLabel: (c) => c.categoryName,
                value: selectedCategory(),
                onChanged: (c) => setState(() => categoryId = c?.categoryId),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          AppButton(
            label: 'Save',
            expanded: false,
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    ),
  );

  if (ok == true && nameController.text.trim().isNotEmpty) {
    final price = double.tryParse(priceController.text.trim()) ?? 0;
    final categoryName = categories
        .where((c) => c.categoryId == categoryId)
        .map((c) => c.categoryName)
        .firstOrNull;
    await ref.read(mastersSyncControllerProvider.notifier).createProduct(
          name: nameController.text.trim(),
          price: price,
          categoryId: categoryId,
          categoryName: categoryName,
        );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product saved')),
      );
    }
  }
  nameController.dispose();
  priceController.dispose();
}

class _CountChip extends StatelessWidget {
  const _CountChip({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 112),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .09),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: .12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppModuleIcon(icon: icon, color: color, size: 36),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.navy)),
              Text(label, style: TextStyle(fontSize: 11, color: AppColors.navy.withValues(alpha: .58))),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProductTile extends StatelessWidget {
  const _ProductTile({
    required this.product,
    required this.priceLabel,
    required this.onEdit,
    required this.onDelete,
  });

  final Product product;
  final String priceLabel;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pending = product.productSyncStatus == '0';
    return AppCard(
      accentColor: pending ? AppColors.orange : AppColors.primary,
      padding: EdgeInsets.zero,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        onTap: onEdit,
        leading: AppModuleIcon(
          icon: Icons.shopping_bag_rounded,
          color: pending ? AppColors.orange : AppColors.primary,
          size: 50,
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                product.productName,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (pending)
              Chip(
                visualDensity: VisualDensity.compact,
                label: const Text('Pending'),
                backgroundColor: AppColors.warning.withValues(alpha: 0.2),
              ),
          ],
        ),
        subtitle: Text(
          [
            if (product.categoryName != null &&
                product.categoryName!.trim().isNotEmpty)
              product.categoryName!,
            if (product.productCode != null &&
                product.productCode!.trim().isNotEmpty)
              'Code: ${product.productCode}',
            if (product.productCgst > 0 || product.productSgst > 0)
              'GST ${product.productCgst + product.productSgst}%',
          ].join(' • '),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              priceLabel,
              style: theme.textTheme.titleMedium?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w900,
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (v) {
                if (v == 'edit') onEdit();
                if (v == 'delete') onDelete();
              },
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'edit', child: Text('Edit')),
                PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CombosTab extends ConsumerWidget {
  const _CombosTab({required this.currency});

  final NumberFormat currency;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final combosAsync = ref.watch(combosListProvider);
    return combosAsync.when(
      data: (combos) {
        if (combos.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('No combos yet'),
                const SizedBox(height: 12),
                AppButton(
            label: 'Add combo',
            onPressed: () => _showAddComboDialog(context, ref),
          ),
              ],
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
          itemCount: combos.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final combo = combos[index];
            final price = combo.comboWithGstPrice > 0
                ? combo.comboWithGstPrice
                : combo.comboPrice;
            return AppCard(
              accentColor: index.isEven ? AppColors.purple : AppColors.orange,
              padding: EdgeInsets.zero,
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                leading: AppModuleIcon(
                  icon: Icons.auto_awesome_rounded,
                  color: index.isEven ? AppColors.purple : AppColors.orange,
                  size: 48,
                ),
                onTap: () => _showEditComboDialog(context, ref, combo),
                title: Text(
                  combo.comboName,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(currency.format(price)),
                trailing: IconButton(
                  tooltip: 'Delete',
                  onPressed: () async {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Delete combo'),
                        content: Text('Remove ${combo.comboName}?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          AppButton(
            label: 'Delete',
            onPressed: () => Navigator.pop(context, true),
          ),
                        ],
                      ),
                    );
                    if (ok == true) {
                      await ref
                          .read(mastersSyncControllerProvider.notifier)
                          .deleteCombo(combo.comboId);
                      ref.invalidate(catalogCountsProvider);
                    }
                  },
                  icon: const Icon(Icons.delete_outline),
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
    );
  }
}

Future<void> _showEditCategoryDialog(
  BuildContext context,
  WidgetRef ref,
  ProductCategory category,
) async {
  final controller = TextEditingController(text: category.categoryName);
  final action = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Edit category'),
      content: AppTextField(
                      controller: controller,
                      label: 'Category name',
                    ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, 'delete'),
          child: const Text('Delete'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, 'cancel'),
          child: const Text('Cancel'),
        ),
        AppButton(
            label: 'Save',
            onPressed: () => Navigator.pop(context, 'save'),
          ),
      ],
    ),
  );
  if (action == 'save' && controller.text.trim().isNotEmpty) {
    await ref.read(mastersSyncControllerProvider.notifier).updateCategory(
          categoryId: category.categoryId,
          name: controller.text.trim(),
        );
  } else if (action == 'delete') {
    await ref
        .read(mastersSyncControllerProvider.notifier)
        .deleteCategory(category.categoryId);
    ref.read(selectedCategoryIdProvider.notifier).select(null);
  }
  controller.dispose();
  ref.invalidate(catalogCountsProvider);
}

Future<void> _showEditProductDialog(
  BuildContext context,
  WidgetRef ref,
  Product product,
) async {
  final nameController = TextEditingController(text: product.productName);
  final priceController =
      TextEditingController(text: product.productPrice.toStringAsFixed(2));
  final categories =
      ref.read(categoriesProvider).maybeWhen(data: (v) => v, orElse: () => null) ??
          const <ProductCategory>[];
  int? categoryId = product.categoryId;

  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text('Edit product'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppTextField(
                      controller: nameController,
                      label: 'Product name',
                    ),
              const SizedBox(height: 12),
              AppTextField(
                      controller: priceController,
                      label: 'Price',
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
              const SizedBox(height: 12),
              AppDropdownFormField<ProductCategory>(
                label: 'Category',
                items: categories,
                itemLabel: (c) => c.categoryName,
                value: categoryId == null
                    ? null
                    : categories
                        .cast<ProductCategory?>()
                        .firstWhere(
                          (c) => c?.categoryId == categoryId,
                          orElse: () => null,
                        ),
                onChanged: (c) => setState(() => categoryId = c?.categoryId),
              ),
              const SizedBox(height: 12),
              AppButton(
                label: 'Manage portions',
                icon: Icons.straighten_rounded,
                variant: AppButtonVariant.outlined,
                expanded: false,
                onPressed: () async {
                  Navigator.pop(context, false);
                  await _showManagePortionsDialog(context, ref, product);
                },
              ),
            ],
          ),
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

  if (ok == true && nameController.text.trim().isNotEmpty) {
    final price = double.tryParse(priceController.text.trim()) ?? 0;
    final categoryName = categories
        .where((c) => c.categoryId == categoryId)
        .map((c) => c.categoryName)
        .firstOrNull;
    await ref.read(mastersSyncControllerProvider.notifier).updateProduct(
          productId: product.productId,
          name: nameController.text.trim(),
          price: price,
          categoryId: categoryId,
          categoryName: categoryName,
        );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product updated')),
      );
    }
  }
  nameController.dispose();
  priceController.dispose();
}

Future<void> _showManagePortionsDialog(
  BuildContext context,
  WidgetRef ref,
  Product product,
) async {
  final db = ref.read(appDatabaseProvider);
  var portions = await db.getPortionsForProduct(product.productId);
  if (!context.mounted) return;

  await showDialog<void>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setLocal) => AlertDialog(
        title: Text('Portions • ${product.productName}'),
        content: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (portions.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: Text('No portions yet'),
                )
              else
                ...portions.map(
                  (p) => ListTile(
                    dense: true,
                    title: Text(p.portionName),
                    subtitle: Text('â‚¹${p.portionPrice.toStringAsFixed(2)}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () async {
                        await db.softDeletePortion(p.portionId);
                        portions =
                            await db.getPortionsForProduct(product.productId);
                        setLocal(() {});
                      },
                    ),
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          AppButton(
            label: 'Cancel',
            onPressed: () async {
              final nameCtrl = TextEditingController();
              final priceCtrl = TextEditingController(text: '0');
              final add = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Add portion'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppTextField(
                      controller: nameCtrl,
                      label: 'Portion name',
                    ),
                      const SizedBox(height: 12),
                      AppTextField(
                      controller: priceCtrl,
                      label: 'Price',
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
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
            expanded: false,
            onPressed: () => Navigator.pop(context, true),
          ),
                  ],
                ),
              );
              if (add == true && nameCtrl.text.trim().isNotEmpty) {
                await db.insertLocalPortion(
                  productId: product.productId,
                  portionName: nameCtrl.text.trim(),
                  portionPrice: double.tryParse(priceCtrl.text.trim()) ?? 0,
                );
                portions = await db.getPortionsForProduct(product.productId);
                setLocal(() {});
              }
              nameCtrl.dispose();
              priceCtrl.dispose();
            },
          ),
        ],
      ),
    ),
  );
}

Future<void> _confirmDeleteProduct(
  BuildContext context,
  WidgetRef ref,
  Product product,
) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Delete product'),
      content: Text('Remove ${product.productName}?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        AppButton(
            label: 'Delete',
            onPressed: () => Navigator.pop(context, true),
          ),
      ],
    ),
  );
  if (ok == true) {
    await ref
        .read(mastersSyncControllerProvider.notifier)
        .deleteProduct(product.productId);
    ref.invalidate(catalogCountsProvider);
  }
}

Future<void> _showAddComboDialog(BuildContext context, WidgetRef ref) async {
  final nameController = TextEditingController();
  final priceController = TextEditingController();
  final products =
      ref.read(productsProvider).maybeWhen(data: (v) => v, orElse: () => null) ??
          const <Product>[];
  // All products regardless of category filter:
  final allProducts =
      await ref.read(appDatabaseProvider).watchActiveProducts().first;
  final selected = <int, int>{}; // productId → qty

  if (!context.mounted) return;
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text('Add combo'),
        content: SizedBox(
          width: 420,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppTextField(
                      controller: nameController,
                      label: 'Combo name',
                    ),
                const SizedBox(height: 12),
                AppTextField(
                      controller: priceController,
                      label: 'Combo price',
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                const SizedBox(height: 16),
                Text(
                  'Items in combo',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 8),
                if (allProducts.isEmpty && products.isEmpty)
                  const Text('No products — sync Masters first.')
                else
                  ...((allProducts.isNotEmpty ? allProducts : products)
                      .take(40)
                      .map((p) {
                    final qty = selected[p.productId] ?? 0;
                    return CheckboxListTile(
                      dense: true,
                      value: qty > 0,
                      title: Text(p.productName),
                      subtitle: qty > 0 ? Text('Qty: $qty') : null,
                      secondary: qty > 0
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove),
                                  onPressed: () => setState(() {
                                    final next = qty - 1;
                                    if (next <= 0) {
                                      selected.remove(p.productId);
                                    } else {
                                      selected[p.productId] = next;
                                    }
                                  }),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add),
                                  onPressed: () => setState(() {
                                    selected[p.productId] = qty + 1;
                                  }),
                                ),
                              ],
                            )
                          : null,
                      onChanged: (on) => setState(() {
                        if (on == true) {
                          selected[p.productId] = 1;
                        } else {
                          selected.remove(p.productId);
                        }
                      }),
                    );
                  })),
              ],
            ),
          ),
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
  if (ok == true && nameController.text.trim().isNotEmpty) {
    final price = double.tryParse(priceController.text.trim()) ?? 0;
    final items = selected.entries
        .map((e) => (productId: e.key, quantity: e.value))
        .toList();
    await ref.read(mastersSyncControllerProvider.notifier).createCombo(
          name: nameController.text.trim(),
          price: price,
          items: items,
        );
    ref.invalidate(catalogCountsProvider);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            items.isEmpty
                ? 'Combo saved'
                : 'Combo saved with ${items.length} items',
          ),
        ),
      );
    }
  }
  nameController.dispose();
  priceController.dispose();
}

Future<void> _showEditComboDialog(
  BuildContext context,
  WidgetRef ref,
  Combo combo,
) async {
  final nameController = TextEditingController(text: combo.comboName);
  final priceController = TextEditingController(
    text: (combo.comboWithGstPrice > 0
            ? combo.comboWithGstPrice
            : combo.comboPrice)
        .toStringAsFixed(2),
  );
  final allProducts =
      await ref.read(appDatabaseProvider).watchActiveProducts().first;
  final existing =
      await ref.read(appDatabaseProvider).getComboItemsForCombo(combo.comboId);
  final selected = <int, int>{
    for (final item in existing)
      if (item.productId != null && item.comboItemQuantity > 0)
        item.productId!: item.comboItemQuantity,
  };

  if (!context.mounted) return;
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text('Edit combo'),
        content: SizedBox(
          width: 420,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppTextField(
                      controller: nameController,
                      label: 'Combo name',
                    ),
                const SizedBox(height: 12),
                AppTextField(
                      controller: priceController,
                      label: 'Combo price',
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                const SizedBox(height: 16),
                Text(
                  'Items in combo',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 8),
                if (allProducts.isEmpty)
                  const Text('No products — sync Masters first.')
                else
                  ...allProducts.take(40).map((p) {
                    final qty = selected[p.productId] ?? 0;
                    return CheckboxListTile(
                      dense: true,
                      value: qty > 0,
                      title: Text(p.productName),
                      subtitle: qty > 0 ? Text('Qty: $qty') : null,
                      secondary: qty > 0
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove),
                                  onPressed: () => setState(() {
                                    final next = qty - 1;
                                    if (next <= 0) {
                                      selected.remove(p.productId);
                                    } else {
                                      selected[p.productId] = next;
                                    }
                                  }),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add),
                                  onPressed: () => setState(() {
                                    selected[p.productId] = qty + 1;
                                  }),
                                ),
                              ],
                            )
                          : null,
                      onChanged: (checked) => setState(() {
                        if (checked == true) {
                          selected[p.productId] = 1;
                        } else {
                          selected.remove(p.productId);
                        }
                      }),
                    );
                  }),
              ],
            ),
          ),
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
  if (ok == true && nameController.text.trim().isNotEmpty) {
    final price = double.tryParse(priceController.text.trim()) ?? 0;
    final items = selected.entries
        .map((e) => (productId: e.key, quantity: e.value))
        .toList();
    await ref.read(mastersSyncControllerProvider.notifier).updateCombo(
          comboId: combo.comboId,
          name: nameController.text.trim(),
          price: price,
          items: items,
        );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Combo updated')),
      );
    }
  }
  nameController.dispose();
  priceController.dispose();
}


