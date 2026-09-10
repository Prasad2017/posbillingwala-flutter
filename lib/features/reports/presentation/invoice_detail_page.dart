import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pos_billingwala_v2/core/constants/app_colors.dart';
import 'package:pos_billingwala_v2/core/database/app_database.dart';
import 'package:pos_billingwala_v2/core/database/database_provider.dart';
import 'package:pos_billingwala_v2/features/print/domain/print_providers.dart';
import 'package:pos_billingwala_v2/features/reports/domain/reports_providers.dart';
import 'package:pos_billingwala_v2/features/sync/data/invoice_sync_api.dart';
import 'package:pos_billingwala_v2/features/auth/domain/auth_controller.dart';
import 'package:pos_billingwala_v2/features/sync/domain/sync_providers.dart';
import 'package:pos_billingwala_v2/core/widgtes/widgtes.dart';

class InvoiceDetailPage extends ConsumerWidget {
  const InvoiceDetailPage({super.key, required this.invoiceId});

  final int invoiceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(invoiceDetailProvider(invoiceId));
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: 'â‚¹');
    final timeFormat = DateFormat('dd MMM yyyy, hh:mm a');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bill details'),
        actions: [
          IconButton(
            tooltip: 'Edit bill',
            onPressed: () async {
              final detail = await ref.read(invoiceDetailProvider(invoiceId).future);
              if (!context.mounted || detail == null) return;
              if (detail.invoice.invoiceOrderStatus == 'cancelled' ||
                  detail.invoice.invoiceOrderStatus == 'refunded') {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Voided / refunded bills cannot be edited'),
                  ),
                );
                return;
              }
              await _editInvoiceHeader(context, ref, detail.invoice);
              ref.invalidate(invoiceDetailProvider(invoiceId));
            },
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            tooltip: 'Print / Share',
            onPressed: () async {
              final result = await printInvoiceById(ref, invoiceId);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(result.message ?? 'Done')),
              );
            },
            icon: const Icon(Icons.print_rounded),
          ),
          IconButton(
            tooltip: 'Print duplicate',
            onPressed: () async {
              final result = await printInvoiceById(
                ref,
                invoiceId,
                duplicate: true,
              );
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(result.message ?? 'Duplicate printed')),
              );
            },
            icon: const Icon(Icons.copy_all_rounded),
          ),
        ],
      ),
      body: detailAsync.when(
        data: (detail) {
          if (detail == null) {
            return const Center(child: Text('Bill not found'));
          }
          final invoice = detail.invoice;
          final items = detail.items;
          final pending = invoice.invoiceSyncStatus == '0';
          final cancelled = invoice.invoiceOrderStatus == 'cancelled';
          final refunded = invoice.invoiceOrderStatus == 'refunded';

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              AppCard(
            padding: const EdgeInsets.all(16),
            child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        invoice.invoiceNumber,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(timeFormat.format(invoice.invoiceDate)),
                      const SizedBox(height: 8),
                      Text(
                        _typeLabel(invoice.invoiceType),
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          Chip(
                            label: Text(pending ? 'Pending sync' : 'Synced'),
                            backgroundColor: pending
                                ? AppColors.warning.withValues(alpha: 0.2)
                                : AppColors.success.withValues(alpha: 0.2),
                          ),
                          if (cancelled)
                            Chip(
                              label: const Text('Voided'),
                              backgroundColor:
                                  AppColors.danger.withValues(alpha: 0.2),
                            ),
                          if (refunded)
                            Chip(
                              label: const Text('Refunded'),
                              backgroundColor:
                                  AppColors.warning.withValues(alpha: 0.2),
                            ),
                        ],
                      ),
                      if (invoice.customerName != null) ...[
                        const SizedBox(height: 8),
                        Text('Customer: ${invoice.customerName}'),
                      ],
                      if (invoice.customerMobile != null) ...[
                        const SizedBox(height: 4),
                        Text('Mobile: ${invoice.customerMobile}'),
                      ],
                      const Divider(height: 24),
                      _Row(label: 'Payment', value: invoice.paymentMode),
                      _Row(
                        label: 'Cash',
                        value: currency.format(invoice.cashAmount),
                      ),
                      _Row(
                        label: 'UPI',
                        value: currency.format(invoice.upiAmount),
                      ),
                      _Row(
                        label: 'Subtotal',
                        value: currency.format(invoice.subTotal),
                      ),
                      _Row(
                        label: 'GST',
                        value: currency.format(invoice.totalGstAmount),
                      ),
                      const SizedBox(height: 8),
                      _Row(
                        label: 'Grand total',
                        value: currency.format(invoice.totalAmount),
                        emphasized: true,
                      ),
                    ],
                  ),
              ),
              if (!cancelled && !refunded) ...[
                const SizedBox(height: 8),
                AppButton(
            label: 'Edit customer / payment',
            icon: Icons.edit_outlined,
            variant: AppButtonVariant.outlined,
            expanded: false,
            onPressed: () async {
                    await _editInvoiceHeader(context, ref, invoice);
                    ref.invalidate(invoiceDetailProvider(invoiceId));
                  },
          ),
                const SizedBox(height: 8),
                AppButton(
            label: 'Refund bill',
            icon: Icons.replay_rounded,
            variant: AppButtonVariant.outlined,
            expanded: false,
            onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Refund bill'),
                        content: const Text(
                          'Mark this bill as refunded? It will show in Refund Report and re-upload on sync.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          AppButton(
            label: 'Refund',
            onPressed: () => Navigator.pop(context, true),
          ),
                        ],
                      ),
                    );
                    if (confirm != true) return;
                    await ref
                        .read(appDatabaseProvider)
                        .refundInvoiceLocally(invoice.invoiceId);
                    ref.invalidate(invoiceDetailProvider(invoiceId));
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Bill marked refunded')),
                    );
                  },
          ),
              ],
              if (pending) ...[
                const SizedBox(height: 8),
                AppButton(
            label: 'Upload to cloud',
            icon: Icons.cloud_upload_rounded,
            expanded: false,
            onPressed: () async {
                    final result = await ref
                        .read(invoiceSyncControllerProvider.notifier)
                        .uploadPending(onlyInvoiceId: invoice.invoiceId);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(result.message ?? 'Sync finished'),
                      ),
                    );
                  },
          ),
                if (!cancelled) ...[
                  const SizedBox(height: 8),
                  AppButton(
            label: 'Void bill',
            icon: Icons.cancel_outlined,
            variant: AppButtonVariant.outlined,
            expanded: false,
            onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Void bill'),
                          content: const Text(
                            'Mark this pending bill as cancelled?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel'),
                            ),
                            AppButton(
            label: 'Void',
            onPressed: () => Navigator.pop(context, true),
          ),
                          ],
                        ),
                      );
                      if (confirm != true) return;
                      await ref
                          .read(appDatabaseProvider)
                          .voidInvoiceLocally(invoice.invoiceId);
                      ref.invalidate(invoiceDetailProvider(invoiceId));
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Bill voided locally')),
                      );
                    },
          ),
                ],
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Text(
                    'Items',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const Spacer(),
                  if (!cancelled && !refunded)
                    TextButton.icon(
                      onPressed: () => _addInvoiceProduct(
                        context,
                        ref,
                        invoice.invoiceId,
                      ),
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Add'),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              ...items.map(
                (item) => AppCard(
            padding: EdgeInsets.zero,
            child: ListTile(
                    title: Text(
                      item.productName,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      '${currency.format(item.productPrice)} Ã— ${item.productQuantity}'
                      '${item.invoiceItemType == 'combo' ? ' Â· Combo' : ''}',
                    ),
                    trailing: (!cancelled && !refunded)
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: 'Qty',
                                icon: const Icon(Icons.edit_note_rounded),
                                onPressed: () async {
                                  final qtyCtrl = TextEditingController(
                                    text: '${item.productQuantity}',
                                  );
                                  final ok = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Update quantity'),
                                      content: AppTextField(
                      controller: qtyCtrl,
                      label: 'Quantity',
                      keyboardType: TextInputType.number,
                    ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, false),
                                          child: const Text('Cancel'),
                                        ),
                                        AppButton(
            label: 'Save',
            onPressed: () =>
                                              Navigator.pop(context, true),
          ),
                                      ],
                                    ),
                                  );
                                  if (ok != true) {
                                    qtyCtrl.dispose();
                                    return;
                                  }
                                  final qty =
                                      int.tryParse(qtyCtrl.text.trim()) ?? 0;
                                  qtyCtrl.dispose();
                                  try {
                                    await ref
                                        .read(appDatabaseProvider)
                                        .updateInvoiceItemQuantity(
                                          invoiceItemId: item.invoiceItemId,
                                          quantity: qty,
                                        );
                                    ref.invalidate(
                                      invoiceDetailProvider(invoiceId),
                                    );
                                  } catch (e) {
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('$e')),
                                    );
                                  }
                                },
                              ),
                              IconButton(
                                tooltip: 'Delete line',
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () async {
                                  final network =
                                      item.invoiceItemNetworkStatus?.trim();
                                  try {
                                    await ref
                                        .read(appDatabaseProvider)
                                        .deleteInvoiceItemAndRecompute(
                                          item.invoiceItemId,
                                        );
                                    if (network != null && network.isNotEmpty) {
                                      try {
                                        await InvoiceSyncApi(
                                          ref.read(apiClientProvider),
                                        ).deleteInvoiceProduct(
                                          invoiceProductNetworkStatus: network,
                                        );
                                      } catch (_) {}
                                    }
                                    ref.invalidate(
                                      invoiceDetailProvider(invoiceId),
                                    );
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Line removed'),
                                      ),
                                    );
                                  } catch (e) {
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('$e')),
                                    );
                                  }
                                },
                              ),
                            ],
                          )
                        : Text(
                            currency.format(
                              item.productPrice * item.productQuantity,
                            ),
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                  ),
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

  String _typeLabel(String type) {
    return switch (type) {
      'take_away' => 'Takeaway',
      'table_wise' => 'Dine-in',
      _ => 'POS',
    };
  }
}

Future<void> _addInvoiceProduct(
  BuildContext context,
  WidgetRef ref,
  int invoiceId,
) async {
  final products = await ref.read(appDatabaseProvider).watchActiveProducts().first;
  if (!context.mounted) return;
  if (products.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No products in catalog')),
    );
    return;
  }
  Product? selected = products.first;
  final qtyCtrl = TextEditingController(text: '1');
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setLocal) => AlertDialog(
        title: const Text('Add product'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppDropdownFormField<Product>(
              label: 'Product',
              items: products,
              itemLabel: (p) => p.productName,
              value: selected,
              onChanged: (v) => setLocal(() => selected = v),
            ),
            const SizedBox(height: 12),
            AppTextField(
                      controller: qtyCtrl,
                      label: 'Quantity',
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
            label: 'Add',
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    ),
  );
  if (ok != true || selected == null) {
    qtyCtrl.dispose();
    return;
  }
  final qty = int.tryParse(qtyCtrl.text.trim()) ?? 1;
  qtyCtrl.dispose();
  try {
    await ref.read(appDatabaseProvider).addInvoiceItemLine(
          invoiceId: invoiceId,
          productId: selected!.productId,
          productName: selected!.productName,
          productPrice: selected!.productPrice,
          quantity: qty <= 0 ? 1 : qty,
          productCode: selected!.productCode,
          categoryName: selected!.categoryName,
          cgst: selected!.productCgst,
          sgst: selected!.productSgst,
        );
    ref.invalidate(invoiceDetailProvider(invoiceId));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Item added Â· pending sync')),
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }
}

Future<void> _editInvoiceHeader(
  BuildContext context,
  WidgetRef ref,
  Invoice invoice,
) async {
  final nameCtrl = TextEditingController(text: invoice.customerName ?? '');
  final mobileCtrl = TextEditingController(text: invoice.customerMobile ?? '');
  final discountCtrl =
      TextEditingController(text: invoice.discount.toStringAsFixed(2));
  final cashCtrl =
      TextEditingController(text: invoice.cashAmount.toStringAsFixed(2));
  final upiCtrl =
      TextEditingController(text: invoice.upiAmount.toStringAsFixed(2));
  var paymentMode = invoice.paymentMode;
  var discountType = invoice.discountType;

  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setLocal) => AlertDialog(
        title: const Text('Edit bill'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppTextField(
                      controller: nameCtrl,
                      label: 'Customer name',
                    ),
              const SizedBox(height: 12),
              AppTextField(
                      controller: mobileCtrl,
                      label: 'Mobile',
                      keyboardType: TextInputType.phone,
                    ),
              const SizedBox(height: 12),
              StringDropdownField(
                              label: 'Discount type',
                              value: 'Amount',
                              options: const ['Amount', 'Percent'],
                              onChanged: (v) {
                  if (v != null) setLocal(() => discountType = v);
                },
                            ),
              const SizedBox(height: 12),
              AppTextField(
                      controller: discountCtrl,
                      label: 'Discount',
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
              const SizedBox(height: 12),
              StringDropdownField(
                              label: 'Payment mode',
                              value: 'Cash',
                              options: const ['Cash', 'UPI', 'Mixed', 'Card'],
                              onChanged: (v) {
                  if (v != null) setLocal(() => paymentMode = v);
                },
                            ),
              const SizedBox(height: 12),
              AppTextField(
                      controller: cashCtrl,
                      label: 'Cash amount',
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
              const SizedBox(height: 12),
              AppTextField(
                      controller: upiCtrl,
                      label: 'UPI amount',
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
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

  if (ok == true) {
    try {
      await ref.read(appDatabaseProvider).updateInvoiceHeader(
            invoiceId: invoice.invoiceId,
            customerName: nameCtrl.text.trim().isEmpty
                ? null
                : nameCtrl.text.trim(),
            customerMobile: mobileCtrl.text.trim().isEmpty
                ? null
                : mobileCtrl.text.trim(),
            paymentMode: paymentMode,
            cashAmount: double.tryParse(cashCtrl.text.trim()) ?? 0,
            upiAmount: double.tryParse(upiCtrl.text.trim()) ?? 0,
            discount: double.tryParse(discountCtrl.text.trim()) ?? 0,
            discountType: discountType,
          );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bill updated Â· pending sync')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    }
  }

  nameCtrl.dispose();
  mobileCtrl.dispose();
  discountCtrl.dispose();
  cashCtrl.dispose();
  upiCtrl.dispose();
}

class _Row extends StatelessWidget {
  const _Row({
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final style = emphasized
        ? Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            )
        : Theme.of(context).textTheme.bodyMedium;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(label, style: style),
          const Spacer(),
          Text(
            value,
            style: style?.copyWith(
              color: emphasized ? AppColors.primary : null,
            ),
          ),
        ],
      ),
    );
  }
}
