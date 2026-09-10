import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_billingwala_v2/core/constants/app_colors.dart';
import 'package:pos_billingwala_v2/features/auth/domain/auth_controller.dart';
import 'package:pos_billingwala_v2/features/masters/data/masters_api.dart';
import 'package:pos_billingwala_v2/features/masters/domain/masters_providers.dart';
import 'package:pos_billingwala_v2/features/tables/domain/tables_providers.dart';
import 'package:pos_billingwala_v2/core/widgtes/widgtes.dart';
import 'package:pos_billingwala_v2/core/widgets/app_module_icon.dart';

class TableMasterPage extends ConsumerStatefulWidget {
  const TableMasterPage({super.key});

  @override
  ConsumerState<TableMasterPage> createState() => _TableMasterPageState();
}

class _TableMasterPageState extends ConsumerState<TableMasterPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _syncAll() async {
    setState(() => _busy = true);
    try {
      await ref.read(mastersSyncControllerProvider.notifier).syncNow();
      await ref.read(tablesControllerProvider.notifier).syncTables();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Table master synced')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _addArea() async {
    final name = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Row(children: [AppModuleIcon(icon: Icons.restaurant_rounded, color: AppColors.primary, size: 42), SizedBox(width: 10), Text('Add dining area')]),
        content: AppTextField(
                      controller: name,
                      label: 'Area name',
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
    if (ok != true || !mounted) {
      name.dispose();
      return;
    }
    final userId = ref.read(authControllerProvider).session?.userId ?? '';
    setState(() => _busy = true);
    try {
      await ref.read(mastersRepositoryProvider).createDiningArea(
            userId: userId,
            areaName: name.text.trim(),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Area saved')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _busy = false);
      name.dispose();
    }
  }

  Future<void> _addType() async {
    final name = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add table type'),
        content: AppTextField(
                      controller: name,
                      label: 'Type name',
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
    if (ok != true || !mounted) {
      name.dispose();
      return;
    }
    final userId = ref.read(authControllerProvider).session?.userId ?? '';
    setState(() => _busy = true);
    try {
      await ref.read(mastersRepositoryProvider).createTableType(
            userId: userId,
            tableTypeName: name.text.trim(),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Type saved')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _busy = false);
      name.dispose();
    }
  }

  Future<void> _addTable() async {
    final number = TextEditingController();
    final name = TextEditingController();
    final capacity = TextEditingController(text: '4');
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add table'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
          Container(margin: const EdgeInsets.fromLTRB(16, 10, 16, 8), padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: .08), borderRadius: BorderRadius.circular(20)), child: const Row(children: [AppModuleIcon(icon: Icons.table_bar_rounded, color: AppColors.primary, size: 48), SizedBox(width: 12), Expanded(child: Text('Organize your restaurant tables', style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.navy)))])),
            AppTextField(
                      controller: number,
                      label: 'Table number',
                    ),
            const SizedBox(height: 12),
            AppTextField(
                      controller: name,
                      label: 'Display name',
                    ),
            const SizedBox(height: 12),
            AppTextField(
                      controller: capacity,
                      label: 'Capacity',
                      keyboardType: TextInputType.number,
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
    if (ok != true || !mounted) {
      number.dispose();
      name.dispose();
      capacity.dispose();
      return;
    }
    final userId = ref.read(authControllerProvider).session?.userId;
    if (userId == null) return;
    setState(() => _busy = true);
    try {
      final success =
          await MastersApi(ref.read(apiClientProvider)).insertPosTable(
        userId: userId,
        tableNumber: number.text.trim(),
        tableName: name.text.trim().isEmpty
            ? 'Table ${number.text.trim()}'
            : name.text.trim(),
        capacity: capacity.text.trim().isEmpty ? '4' : capacity.text.trim(),
        posTableNetworkStatus: 'tbl_${DateTime.now().millisecondsSinceEpoch}',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(success ? 'Table saved' : 'Save failed')),
      );
      if (success) {
        await ref.read(tablesControllerProvider.notifier).syncTables();
      }
    } finally {
      if (mounted) setState(() => _busy = false);
      number.dispose();
      name.dispose();
      capacity.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final areas = ref.watch(diningAreasProvider);
    final types = ref.watch(tableTypesProvider);
    final floor = ref.watch(floorTablesProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Table Master'),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'Areas'),
            Tab(text: 'Types'),
            Tab(text: 'Tables'),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _busy ? null : _syncAll,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _busy
            ? null
            : () {
                switch (_tabs.index) {
                  case 0:
                    _addArea();
                  case 1:
                    _addType();
                  default:
                    _addTable();
                }
              },
        icon: const Icon(Icons.add),
        label: const Text('Add'),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          areas.when(
            data: (rows) => rows.isEmpty
                ? const Center(child: Text('No dining areas yet'))
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
                    itemCount: rows.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final a = rows[i];
                      final pending = a.areaSyncStatus == '0';
                      return AppCard(
            padding: EdgeInsets.zero,
            child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor:
                                AppColors.primary.withValues(alpha: 0.12),
                            child: const Icon(
                              Icons.place_outlined,
                              color: AppColors.primary,
                            ),
                          ),
                          title: Text(a.areaName),
                          subtitle: Text(
                            pending ? 'Pending sync' : 'Synced',
                          ),
                          trailing: pending
                              ? const Icon(
                                  Icons.cloud_upload_outlined,
                                  color: AppColors.warning,
                                )
                              : null,
                        ),
                      );
                    },
                  ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('$e')),
          ),
          types.when(
            data: (rows) => rows.isEmpty
                ? const Center(child: Text('No table types yet'))
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
                    itemCount: rows.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final t = rows[i];
                      final pending = t.tableTypeSyncStatus == '0';
                      return AppCard(
            padding: EdgeInsets.zero,
            child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor:
                                AppColors.primary.withValues(alpha: 0.12),
                            child: const Icon(
                              Icons.category_outlined,
                              color: AppColors.primary,
                            ),
                          ),
                          title: Text(t.tableTypeName),
                          subtitle: Text(
                            pending ? 'Pending sync' : 'Synced',
                          ),
                          trailing: pending
                              ? const Icon(
                                  Icons.cloud_upload_outlined,
                                  color: AppColors.warning,
                                )
                              : null,
                        ),
                      );
                    },
                  ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('$e')),
          ),
          Builder(
            builder: (context) {
              final rows = floor;
              if (rows.isEmpty) {
                return const Center(child: Text('No tables yet'));
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
                itemCount: rows.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final t = rows[i];
                  return AppCard(
            padding: EdgeInsets.zero,
            child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor:
                            AppColors.primary.withValues(alpha: 0.12),
                        child: Text(
                          t.table.tableNumber,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      title: Text(
                        t.table.displayName.isEmpty
                            ? 'Table ${t.table.tableNumber}'
                            : t.table.displayName,
                      ),
                      subtitle: Text('Capacity ${t.table.capacity}'),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
