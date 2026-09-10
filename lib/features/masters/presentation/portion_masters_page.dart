import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_billingwala_v2/core/constants/app_colors.dart';
import 'package:pos_billingwala_v2/features/auth/domain/auth_controller.dart';
import 'package:pos_billingwala_v2/features/masters/domain/masters_providers.dart';
import 'package:pos_billingwala_v2/core/widgtes/widgtes.dart';

class PortionMastersPage extends ConsumerStatefulWidget {
  const PortionMastersPage({super.key});

  @override
  ConsumerState<PortionMastersPage> createState() => _PortionMastersPageState();
}

class _PortionMastersPageState extends ConsumerState<PortionMastersPage> {
  bool _busy = false;

  Future<void> _sync() async {
    setState(() => _busy = true);
    try {
      await ref.read(mastersSyncControllerProvider.notifier).syncNow();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Portion masters synced')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _add() async {
    final name = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add portion master'),
        content: AppTextField(
                      controller: name,
                      label: 'Portion name (Half, Fullâ€¦)',
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
      await ref.read(mastersRepositoryProvider).createPortionMaster(
            userId: userId,
            portionName: name.text.trim(),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Portion master saved')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _busy = false);
      name.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final list = ref.watch(portionMastersProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Portion masters'),
        actions: [
          IconButton(
            onPressed: _busy ? null : _sync,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _busy ? null : _add,
        icon: const Icon(Icons.add),
        label: const Text('Add'),
      ),
      body: list.when(
        data: (rows) {
          if (rows.isEmpty) {
            return const Center(
              child: Text('No portion masters yet. Add Half / Full etc.'),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
            itemCount: rows.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final row = rows[i];
              final pending = row.portionMasterSyncStatus == '0';
              return AppCard(
            padding: EdgeInsets.zero,
            child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                    child: const Icon(
                      Icons.straighten_rounded,
                      color: AppColors.primary,
                    ),
                  ),
                  title: Text(row.portionName),
                  subtitle: Text(pending ? 'Pending sync' : 'Synced'),
                  trailing: IconButton(
                    tooltip: 'Delete',
                    onPressed: _busy
                        ? null
                        : () async {
                            await ref
                                .read(mastersRepositoryProvider)
                                .deletePortionMaster(row.portionMasterId);
                            final userId = ref
                                    .read(authControllerProvider)
                                    .session
                                    ?.userId ??
                                '';
                            if (userId.isNotEmpty) {
                              await ref
                                  .read(mastersRepositoryProvider)
                                  .uploadPendingMasters(userId);
                            }
                          },
                    icon: const Icon(Icons.delete_outline_rounded),
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
