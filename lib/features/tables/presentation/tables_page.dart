import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:pos_billingwala_v2/core/constants/app_colors.dart';
import 'package:pos_billingwala_v2/core/database/app_database.dart';
import 'package:pos_billingwala_v2/core/database/database_provider.dart';
import 'package:pos_billingwala_v2/features/tables/domain/tables_providers.dart';
import 'package:pos_billingwala_v2/core/widgtes/widgtes.dart';
import 'package:pos_billingwala_v2/core/widgets/app_module_icon.dart';

class TablesPage extends ConsumerWidget {
  const TablesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final floor = ref.watch(floorTablesProvider);
    final syncState = ref.watch(tablesControllerProvider);
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
    final isSyncing = syncState.isLoading;

    ref.listen(tablesControllerProvider, (prev, next) {
      next.whenOrNull(
        error: (error, _) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$error')),
          );
        },
      );
    });

    final running = floor
        .where(
          (t) =>
              t.status == FloorTableStatus.running ||
              t.status == FloorTableStatus.hold ||
              t.status == FloorTableStatus.billRequest,
        )
        .length;
    final available =
        floor.where((t) => t.status == FloorTableStatus.available).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dine-in Tables'),
        actions: [
          IconButton(
            tooltip: 'Sync tables',
            onPressed: isSyncing
                ? null
                : () =>
                    ref.read(tablesControllerProvider.notifier).syncTables(),
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
        ],
      ),
      body: Column(
        children: [
          Padding(padding: const EdgeInsets.fromLTRB(16, 12, 16, 0), child: Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: .08), borderRadius: BorderRadius.circular(20)), child: const Row(children: [AppModuleIcon(icon: Icons.table_restaurant_rounded, color: AppColors.primary, size: 48), SizedBox(width: 12), Text('Manage your dine-in tables', style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.navy))]))),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                _StatChip(
                  label: 'Available',
                  value: '$available',
                  color: AppColors.success,
                ),
                const SizedBox(width: 8),
                _StatChip(
                  label: 'Running',
                  value: '$running',
                  color: AppColors.warning,
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: isSyncing
                      ? null
                      : () => ref
                          .read(tablesControllerProvider.notifier)
                          .syncTables(),
                  icon: const Icon(Icons.sync_rounded, size: 18),
                  label: Text(isSyncing ? 'Syncing…' : 'Sync'),
                ),
              ],
            ),
          ),
          Expanded(
            child: floor.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.table_restaurant_outlined,
                            size: 56,
                            color: AppColors.primary,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No tables yet',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Sync tables from cloud, or defaults will be created automatically.',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          AppButton(
            label: 'Sync tables',
            icon: Icons.cloud_download_rounded,
            onPressed: isSyncing
                                ? null
                                : () => ref
                                    .read(tablesControllerProvider.notifier)
                                    .syncTables(),
            expanded: false,
          ),
                        ],
                      ),
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.05,
                    ),
                    itemCount: floor.length,
                    itemBuilder: (context, index) {
                      final item = floor[index];
                      return _TableCard(
                        floor: item,
                        currency: currency,
                        onTap: () => _onTableTap(context, ref, item),
                        onLongPress: () =>
                            _onTableActions(context, ref, item, floor),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _onTableTap(
    BuildContext context,
    WidgetRef ref,
    FloorTableView floor,
  ) async {
    if (floor.status == FloorTableStatus.blocked ||
        floor.status == FloorTableStatus.reserved) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Table is ${floor.statusLabel.toLowerCase()}')),
      );
      return;
    }

    try {
      await ref.read(tablesControllerProvider.notifier).openTable(floor);
      if (!context.mounted) return;
      context.push('/tables/billing');
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    }
  }

  Future<void> _onTableActions(
    BuildContext context,
    WidgetRef ref,
    FloorTableView floor,
    List<FloorTableView> all,
  ) async {
    if (floor.status == FloorTableStatus.blocked ||
        floor.status == FloorTableStatus.reserved) {
      return;
    }

    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.restaurant_menu_rounded),
              title: Text(
                floor.table.displayName.isEmpty
                    ? 'Table ${floor.table.tableNumber}'
                    : floor.table.displayName,
              ),
              subtitle: Text(
                floor.joinedLabel == null
                    ? floor.statusLabel
                    : 'Joined: ${floor.joinedLabel}',
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.point_of_sale_rounded),
              title: const Text('Open billing'),
              onTap: () => Navigator.pop(context, 'open'),
            ),
            if (floor.status == FloorTableStatus.running ||
                floor.status == FloorTableStatus.hold ||
                floor.status == FloorTableStatus.billRequest) ...[
              ListTile(
                leading: const Icon(Icons.merge_type_rounded),
                title: const Text('Join with another table'),
                onTap: () => Navigator.pop(context, 'join'),
              ),
              ListTile(
                leading: const Icon(Icons.swap_horiz_rounded),
                title: const Text('Transfer to another table'),
                onTap: () => Navigator.pop(context, 'transfer'),
              ),
              ListTile(
                leading: const Icon(Icons.move_down_rounded),
                title: const Text('Move items to another table'),
                onTap: () => Navigator.pop(context, 'move'),
              ),
              ListTile(
                leading: const Icon(Icons.call_split_rounded),
                title: const Text('Split bill'),
                subtitle: const Text('Equal / by item / by amount'),
                onTap: () => Navigator.pop(context, 'split_bill'),
              ),
              if (floor.openSession?.sessionStatus != 'HOLD')
                ListTile(
                  leading: const Icon(Icons.pause_circle_outline_rounded),
                  title: const Text('Hold table'),
                  onTap: () => Navigator.pop(context, 'hold'),
                ),
              if (floor.openSession?.sessionStatus == 'HOLD')
                ListTile(
                  leading: const Icon(Icons.play_circle_outline_rounded),
                  title: const Text('Resume table'),
                  onTap: () => Navigator.pop(context, 'resume'),
                ),
              ListTile(
                leading: const Icon(Icons.receipt_long_rounded),
                title: const Text('Mark bill requested'),
                onTap: () => Navigator.pop(context, 'bill'),
              ),
            ],
            if (floor.openSession != null &&
                (floor.joinedLabel?.contains('+') ?? false) &&
                !floor.isJoinedSecondary)
              ListTile(
                leading: const Icon(Icons.call_split_rounded),
                title: const Text('Split joined tables'),
                subtitle: const Text('Cart stays on primary table'),
                onTap: () => Navigator.pop(context, 'split'),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (!context.mounted || action == null) return;

    if (action == 'open') {
      await _onTableTap(context, ref, floor);
      return;
    }

    if (action == 'split' && floor.openSession != null) {
      await ref
          .read(tablesControllerProvider.notifier)
          .splitJoined(floor.openSession!.sessionId);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Joined tables split')),
      );
      return;
    }

    if (action == 'split_bill' && floor.openSession != null) {
      await context.push(
        '/tables/split-bill'
        '?table=${Uri.encodeComponent(floor.billingTableNumber)}'
        '&sessionId=${floor.openSession!.sessionId}',
      );
      return;
    }

    if (action == 'hold' && floor.openSession != null) {
      await ref.read(tablesControllerProvider.notifier).setSessionStatus(
            sessionId: floor.openSession!.sessionId,
            status: 'HOLD',
          );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Table on hold')),
      );
      return;
    }

    if (action == 'resume' && floor.openSession != null) {
      await ref.read(tablesControllerProvider.notifier).setSessionStatus(
            sessionId: floor.openSession!.sessionId,
            status: 'RUNNING',
          );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Table resumed')),
      );
      return;
    }

    if (action == 'bill' && floor.openSession != null) {
      await ref.read(tablesControllerProvider.notifier).setSessionStatus(
            sessionId: floor.openSession!.sessionId,
            status: 'BILL_REQUEST',
          );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bill requested')),
      );
      return;
    }

    if (action == 'transfer' || action == 'move') {
      final candidates = all
          .where(
            (t) =>
                t.table.tableNumber != floor.billingTableNumber &&
                t.status == FloorTableStatus.available,
          )
          .toList();
      if (candidates.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No available target tables')),
        );
        return;
      }
      final target = await showDialog<FloorTableView>(
        context: context,
        builder: (context) => SimpleDialog(
          title: Text(action == 'transfer' ? 'Transfer to' : 'Move items to'),
          children: candidates
              .map(
                (c) => SimpleDialogOption(
                  onPressed: () => Navigator.pop(context, c),
                  child: Text(
                    c.table.displayName.isEmpty
                        ? 'Table ${c.table.tableNumber}'
                        : c.table.displayName,
                  ),
                ),
              )
              .toList(),
        ),
      );
      if (target == null || !context.mounted) return;
      try {
        if (action == 'transfer') {
          await ref.read(tablesControllerProvider.notifier).transferTable(
                fromTable: floor.billingTableNumber,
                toTable: target.table.tableNumber,
              );
        } else {
          final items = await ref
              .read(appDatabaseProvider)
              .getCartItems(cartScope: floor.billingTableNumber);
          if (items.isEmpty) {
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('No items to move')),
            );
            return;
          }
          if (!context.mounted) return;
          final selected = await showDialog<List<CartItem>>(
            context: context,
            builder: (context) => _MoveItemsDialog(items: items),
          );
          if (selected == null || selected.isEmpty || !context.mounted) return;
          await ref.read(tablesControllerProvider.notifier).moveItems(
                fromTable: floor.billingTableNumber,
                toTable: target.table.tableNumber,
                items: selected,
              );
        }
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              action == 'transfer'
                  ? 'Transferred to T${target.table.tableNumber}'
                  : 'Items moved to T${target.table.tableNumber}',
            ),
          ),
        );
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
      return;
    }

    if (action == 'join') {
      final candidates = all
          .where(
            (t) =>
                t.table.tableNumber != floor.billingTableNumber &&
                t.status == FloorTableStatus.available,
          )
          .toList();
      if (candidates.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No available tables to join')),
        );
        return;
      }

      final secondary = await showDialog<FloorTableView>(
        context: context,
        builder: (context) => SimpleDialog(
          title: const Text('Join with'),
          children: candidates
              .map(
                (c) => SimpleDialogOption(
                  onPressed: () => Navigator.pop(context, c),
                  child: Text(
                    c.table.displayName.isEmpty
                        ? 'Table ${c.table.tableNumber}'
                        : c.table.displayName,
                  ),
                ),
              )
              .toList(),
        ),
      );
      if (secondary == null || !context.mounted) return;

      try {
        await ref.read(tablesControllerProvider.notifier).joinTables(
              primaryTable: floor.billingTableNumber,
              secondaryTable: secondary.table.tableNumber,
            );
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Joined T${secondary.table.tableNumber} into T${floor.billingTableNumber}',
            ),
          ),
        );
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    }
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _TableCard extends StatelessWidget {
  const _TableCard({
    required this.floor,
    required this.currency,
    required this.onTap,
    required this.onLongPress,
  });

  final FloorTableView floor;
  final NumberFormat currency;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  Color get _bg {
    switch (floor.status) {
      case FloorTableStatus.available:
        return AppColors.success.withValues(alpha: 0.12);
      case FloorTableStatus.running:
        return AppColors.warning.withValues(alpha: 0.16);
      case FloorTableStatus.hold:
        return Colors.blueGrey.withValues(alpha: 0.16);
      case FloorTableStatus.billRequest:
        return AppColors.primary.withValues(alpha: 0.16);
      case FloorTableStatus.blocked:
        return AppColors.danger.withValues(alpha: 0.12);
      case FloorTableStatus.reserved:
        return AppColors.primaryLight;
    }
  }

  Color get _fg {
    switch (floor.status) {
      case FloorTableStatus.available:
        return AppColors.success;
      case FloorTableStatus.running:
        return AppColors.warning;
      case FloorTableStatus.hold:
        return Colors.blueGrey.shade700;
      case FloorTableStatus.billRequest:
        return AppColors.primary;
      case FloorTableStatus.blocked:
        return AppColors.danger;
      case FloorTableStatus.reserved:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final table = floor.table;
    final name = table.displayName.trim().isEmpty
        ? 'Table ${table.tableNumber}'
        : table.displayName;

    return Container(
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _fg.withValues(alpha: .18)),
        boxShadow: [BoxShadow(color: _fg.withValues(alpha: .06), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.table_restaurant_rounded, color: _fg),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      floor.statusLabel,
                      style: TextStyle(
                        color: _fg,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                name,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                floor.joinedLabel ??
                    (table.capacity > 0
                        ? 'Seats ${table.capacity}'
                        : 'Table ${table.tableNumber}'),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (floor.currentAmount > 0) ...[
                const SizedBox(height: 8),
                Text(
                  currency.format(floor.currentAmount),
                  style: TextStyle(
                    color: _fg,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ] else if (floor.isJoinedSecondary) ...[
                const SizedBox(height: 8),
                Text(
                  'Joined → T${floor.billingTableNumber}',
                  style: TextStyle(
                    color: _fg,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
          ),
        ),
      ),
    );
  }
}

class _MoveItemsDialog extends StatefulWidget {
  const _MoveItemsDialog({required this.items});

  final List<CartItem> items;

  @override
  State<_MoveItemsDialog> createState() => _MoveItemsDialogState();
}

class _MoveItemsDialogState extends State<_MoveItemsDialog> {
  late final Set<int> _selected;

  @override
  void initState() {
    super.initState();
    _selected = {for (var i = 0; i < widget.items.length; i++) i};
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select items to move'),
      content: SizedBox(
        width: 360,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: widget.items.length,
          itemBuilder: (context, index) {
            final item = widget.items[index];
            return CheckboxListTile(
              value: _selected.contains(index),
              title: Text(item.productName),
              subtitle: Text('Qty ${item.quantity}'),
              onChanged: (on) => setState(() {
                if (on == true) {
                  _selected.add(index);
                } else {
                  _selected.remove(index);
                }
              }),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        AppButton(
            label: 'Move',
            onPressed: () {
            final picked = [for (final i in _selected) widget.items[i]];
            Navigator.pop(context, picked);
          },
          ),
      ],
    );
  }
}
