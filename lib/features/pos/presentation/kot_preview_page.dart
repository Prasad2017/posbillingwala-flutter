import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pos_billingwala_v2/core/constants/app_colors.dart';
import 'package:pos_billingwala_v2/core/database/app_database.dart';
import 'package:pos_billingwala_v2/features/pos/domain/kot_providers.dart';
import 'package:pos_billingwala_v2/features/print/domain/print_providers.dart';
import 'package:pos_billingwala_v2/core/widgtes/widgtes.dart';
import 'package:pos_billingwala_v2/core/widgets/app_module_icon.dart';

/// On-screen KOT ticket (Bluetooth thermal print via ESC/POS when MAC set).
class KotPreviewPage extends ConsumerWidget {
  const KotPreviewPage({super.key, required this.ticket});

  final KotTicket ticket;

  String get _plainText {
    final buf = StringBuffer()
      ..writeln(ticket.kot.kotNumber)
      ..writeln('Table: T${ticket.kot.tableNumber}')
      ..writeln('Round: ${ticket.roundNumber}')
      ..writeln(
        'Date: ${DateFormat('dd-MM-yyyy HH:mm').format(ticket.kot.createdAt)}',
      )
      ..writeln(ticket.kot.kitchenName)
      ..writeln('------------------------');
    for (final item in ticket.items) {
      buf.writeln('${item.productName}  x${item.productQuantity}');
    }
    buf.writeln('------------------------');
    return buf.toString();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text(ticket.kot.kotNumber),
        actions: [
          IconButton(
            tooltip: 'Copy ticket',
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: _plainText));
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('KOT copied')),
              );
            },
            icon: const Icon(Icons.copy_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          AppCard(
            accentColor: AppColors.orange,
            padding: const EdgeInsets.all(20),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const AppModuleIcon(icon: Icons.restaurant_menu_rounded, color: AppColors.orange, size: 58),
                  const SizedBox(height: 10),
                  Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: AppColors.orange.withValues(alpha: .10), borderRadius: BorderRadius.circular(20)), child: Text(
                    'KITCHEN ORDER',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                        ),
                  )),
                  const SizedBox(height: 8),
                  Text(
                    ticket.kot.kotNumber,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 16),
                  _MetaRow(label: 'Table', value: 'T${ticket.kot.tableNumber}'),
                  _MetaRow(label: 'Round', value: '${ticket.roundNumber}'),
                  _MetaRow(
                    label: 'Kitchen',
                    value: ticket.kot.kitchenName,
                  ),
                  _MetaRow(
                    label: 'Date',
                    value: DateFormat('dd-MM-yyyy HH:mm')
                        .format(ticket.kot.createdAt),
                  ),
                  const Divider(height: 28),
                  ...ticket.items.map(
                    (item) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.productName,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                          Text(
                            'x${item.productQuantity}',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.primary,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Divider(height: 28),
                  Text(
                    'Set a KOT/Bill printer MAC in Settings for Bluetooth ESC/POS. '
                    'Otherwise Print/Share sends the ticket text.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
          ),
          const SizedBox(height: 16),
          AppButton(
            label: 'Print / Share KOT',
            icon: Icons.print_rounded,
            expanded: false,
            onPressed: () async {
              final result =
                  await ref.read(printServiceProvider).printKot(ticket);
              await ref
                  .read(kotControllerProvider.notifier)
                  .markPrinted(ticket.kot.kotId);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(result.message ?? 'KOT printed')),
              );
              Navigator.of(context).pop(true);
            },
          ),
          const SizedBox(height: 8),
          AppButton(
            label: 'Done',
            onPressed: () async {
              await ref
                  .read(kotControllerProvider.notifier)
                  .markPrinted(ticket.kot.kotId);
              if (!context.mounted) return;
              Navigator.of(context).pop(true);
            },
            variant: AppButtonVariant.outlined,
            expanded: false,
          ),
        ],
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
