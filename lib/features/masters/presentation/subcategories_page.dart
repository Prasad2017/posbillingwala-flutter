import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_billingwala_v2/core/constants/app_colors.dart';
import 'package:pos_billingwala_v2/core/database/app_database.dart';
import 'package:pos_billingwala_v2/core/database/database_provider.dart';
import 'package:pos_billingwala_v2/features/auth/domain/auth_controller.dart';
import 'package:pos_billingwala_v2/features/masters/domain/masters_providers.dart';
import 'package:pos_billingwala_v2/core/widgtes/widgtes.dart';
import 'package:pos_billingwala_v2/core/widgets/app_module_icon.dart';

class SubcategoriesPage extends ConsumerStatefulWidget {
  const SubcategoriesPage({super.key});

  @override
  ConsumerState<SubcategoriesPage> createState() => _SubcategoriesPageState();
}

class _SubcategoriesPageState extends ConsumerState<SubcategoriesPage> {
  bool _busy = false;

  Future<void> _sync() async {
    final userId = ref.read(authControllerProvider).session?.userId;
    if (userId == null || userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Login required')),
      );
      return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(mastersSyncControllerProvider.notifier).syncNow();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Subcategories synced')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _add() async {
    final categories = ref.read(categoriesProvider).maybeWhen(
          data: (v) => v,
          orElse: () => const <ProductCategory>[],
        );
    if (categories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sync categories in Masters first')),
      );
      return;
    }
    ProductCategory selected = categories.first;
    final nameCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: const Row(children: [AppModuleIcon(icon: Icons.account_tree_rounded, color: AppColors.teal, size: 42), SizedBox(width: 10), Text('Add subcategory')]),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppDropdownFormField<ProductCategory>(
                label: 'Category',
                items: categories,
                itemLabel: (c) => c.categoryName,
                value: selected,
                onChanged: (v) {
                  if (v != null) setLocal(() => selected = v);
                },
              ),
              const SizedBox(height: 12),
              AppTextField(
                      controller: nameCtrl,
                      label: 'Subcategory name',
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
    if (ok != true || !mounted) {
      nameCtrl.dispose();
      return;
    }
    final name = nameCtrl.text.trim();
    nameCtrl.dispose();
    if (name.isEmpty) return;
    final userId = ref.read(authControllerProvider).session?.userId ?? '';
    setState(() => _busy = true);
    try {
      await ref.read(mastersRepositoryProvider).createSubcategory(
            userId: userId,
            subcategoryName: name,
            categoryId: selected.categoryId,
            categoryNetworkStatus: selected.categoryNetworkStatus,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Subcategory saved locally')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete(ProductSubcategory row) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text('Delete subcategory'),
        content: Text('Remove ${row.subcategoryName}?'),
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
    if (ok != true || !mounted) return;
    await ref
        .read(appDatabaseProvider)
        .softDeleteSubcategory(row.subcategoryId);
  }

  @override
  Widget build(BuildContext context) {
    final rowsAsync = ref.watch(subcategoriesProvider);
    final categories = ref.watch(categoriesProvider).maybeWhen(
          data: (v) => {for (final c in v) c.categoryId: c.categoryName},
          orElse: () => const <int, String>{},
        );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Subcategories'),
        actions: [
          IconButton(
            onPressed: _busy ? null : _sync,
            icon: _busy
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _busy ? null : _add,
        icon: const Icon(Icons.add),
        label: const Text('Add'),
      ),
      body: rowsAsync.when(
        data: (rows) {
          if (rows.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const AppModuleIcon(icon: Icons.account_tree_rounded, color: AppColors.purple, size: 72),
                    const SizedBox(height: 14),
                    const Text('No subcategories yet', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
                    const SizedBox(height: 6),
                    Text('Organize products with smart groups.', style: TextStyle(color: AppColors.navy.withValues(alpha: .55))),
                    const SizedBox(height: 16),
                    AppButton(
            label: 'Sync from cloud',
            icon: Icons.cloud_download_rounded,
            onPressed: _busy ? null : _sync,
            expanded: false,
          ),
                  ],
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
            itemCount: rows.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final s = rows[index];
              final catName = categories[s.categoryId] ??
                  'Category ${s.categoryId ?? '-'}';
              final pending = s.subcategorySyncStatus == '0';
              final color = pending ? AppColors.orange : (index.isEven ? AppColors.purple : AppColors.teal);
              return AppCard(
                accentColor: color,
                padding: EdgeInsets.zero,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  leading: AppModuleIcon(
                    icon: pending ? Icons.cloud_off_outlined : Icons.account_tree_rounded,
                    color: color,
                    size: 50,
                  ),
                  title: Text(
                    s.subcategoryName,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  subtitle: Text(
                    pending ? '$catName • Pending sync' : catName,
                    style: TextStyle(color: pending ? AppColors.orange : AppColors.navy.withValues(alpha: .58)),
                  ),
                  trailing: IconButton(
                    tooltip: 'Delete',
                    onPressed: () => _delete(s),
                    icon: const Icon(Icons.delete_outline),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
      ),
    );
  }
}
