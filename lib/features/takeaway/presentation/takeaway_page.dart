import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:pos_billingwala_v2/core/constants/app_colors.dart';
import 'package:pos_billingwala_v2/features/pos/domain/billing_session.dart';
import 'package:pos_billingwala_v2/features/pos/domain/pos_providers.dart';
import 'package:pos_billingwala_v2/features/print/domain/print_providers.dart';
import 'package:pos_billingwala_v2/features/reports/domain/reports_providers.dart';
import 'package:pos_billingwala_v2/features/reports/presentation/invoice_detail_page.dart';
import 'package:pos_billingwala_v2/core/widgtes/widgtes.dart';
import 'package:pos_billingwala_v2/core/widgets/app_module_icon.dart';
import 'package:pos_billingwala_v2/core/widgets/app_module_icon.dart';

/// Android-style Take Away parcel counter: list + New Parcel.
class TakeawayPage extends ConsumerStatefulWidget {
  const TakeawayPage({super.key});

  @override
  ConsumerState<TakeawayPage> createState() => _TakeawayPageState();
}

class _TakeawayPageState extends ConsumerState<TakeawayPage> {
  Future<void> _startNewParcel({String? name, String? phone}) async {
    final nameCtrl = TextEditingController(text: name ?? '');
    final phoneCtrl = TextEditingController(text: phone ?? '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New parcel'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppTextField(
                      controller: nameCtrl,
                      label: 'Customer name (optional)',
                    ),
            const SizedBox(height: 12),
            AppTextField(
                      controller: phoneCtrl,
                      label: 'Mobile number (optional)',
                      keyboardType: TextInputType.phone,
                    ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          AppButton(
            label: 'Start order',
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );
    final customerName = nameCtrl.text;
    final customerPhone = phoneCtrl.text;
    nameCtrl.dispose();
    phoneCtrl.dispose();
    if (ok != true || !mounted) return;

    ref.read(billingSessionProvider.notifier).startTakeaway(
          customerName: customerName,
          customerPhone: customerPhone,
        );
    await ref.read(posCartControllerProvider.notifier).clear();
    if (!mounted) return;
    context.push('/takeaway/billing');
  }

  Future<void> _printDuplicate(int invoiceId) async {
    final result = await printInvoiceById(ref, invoiceId);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result.message ?? 'Done')),
    );
  }

  void _openInvoice(int invoiceId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => InvoiceDetailPage(invoiceId: invoiceId),
      ),
    );
  }

  Future<void> _showParcelMenu(int invoiceId) async {
    final action = await showAppBottomSheet<String>(
      context: context,
      title: 'Parcel options',
      icon: Icons.takeout_dining_rounded,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.print_rounded),
            title: const Text('Print duplicate'),
            onTap: () => Navigator.pop(context, 'print'),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.receipt_long_rounded),
            title: const Text('View'),
            onTap: () => Navigator.pop(context, 'view'),
          ),
        ],
      ),
    );
    if (!mounted || action == null) return;
    if (action == 'print') {
      await _printDuplicate(invoiceId);
    } else if (action == 'view') {
      _openInvoice(invoiceId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final todayInvoices = ref.watch(todayInvoicesProvider);
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
    final timeFmt = DateFormat('hh:mm a');

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Take Away'),
            Text(
              'Parcel counter',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: AppColors.navy.withValues(alpha: .55),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _startNewParcel(),
        icon: const Icon(Icons.add),
        label: const Text('New Parcel'),
      ),
      body: todayInvoices.when(
        data: (all) {
          final parcels = all
              .where((e) => e.invoiceType == 'take_away')
              .toList()
            ..sort((a, b) => b.invoiceDate.compareTo(a.invoiceDate));

          if (parcels.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const AppModuleIcon(icon: Icons.takeout_dining_rounded, color: AppColors.orange, size: 76),
                    const SizedBox(height: 14),
                    Icon(
                      Icons.takeout_dining_rounded,
                      size: 72,
                      color: AppColors.primary.withValues(alpha: 0.7),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No parcels today',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Create a new takeaway order to start billing.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    AppButton(
            label: 'New Parcel',
            icon: Icons.add,
            onPressed: () => _startNewParcel(),
            expanded: false,
          ),
                  ],
                ),
              ),
            );
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [AppColors.orange, AppColors.orangeDark]),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.takeout_dining_rounded, color: Colors.white),
                      SizedBox(width: 12),
                      Expanded(child: Text('Today\'s Parcels', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 17))),
                      Text('Tap parcel to view', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: ListView.separated(
                  itemCount: parcels.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final invoice = parcels[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: AppCard(
                        accentColor: index.isEven ? AppColors.orange : AppColors.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
                        invoice.invoiceNumber,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(
                        [
                          timeFmt.format(invoice.invoiceDate),
                          if (invoice.customerName?.trim().isNotEmpty == true)
                            invoice.customerName!,
                          invoice.paymentMode,
                        ].join(' • '),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            currency.format(invoice.totalAmount),
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                          ),
                          IconButton(
                            tooltip: 'Print duplicate',
                            onPressed: () =>
                                _printDuplicate(invoice.invoiceId),
                            icon: const Icon(Icons.print_outlined),
                          ),
                        ],
                      ),
                      onTap: () => _openInvoice(invoice.invoiceId),
                      onLongPress: () => _showParcelMenu(invoice.invoiceId),
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
    );
  }
}
