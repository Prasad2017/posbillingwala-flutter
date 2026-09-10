import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:pos_billingwala_v2/core/constants/app_colors.dart';
import 'package:pos_billingwala_v2/features/pos/domain/billing_session.dart';
import 'package:pos_billingwala_v2/features/pos/domain/payment_checkout_controller.dart';
import 'package:pos_billingwala_v2/features/pos/domain/payment_mode.dart';
import 'package:pos_billingwala_v2/features/pos/domain/pos_providers.dart';
import 'package:pos_billingwala_v2/features/print/domain/print_providers.dart';
import 'package:pos_billingwala_v2/features/print/domain/printer_settings.dart';
import 'package:pos_billingwala_v2/features/sync/domain/sync_providers.dart';
import 'package:pos_billingwala_v2/core/widgtes/widgtes.dart';
import 'package:pos_billingwala_v2/core/widgets/app_module_icon.dart';

class PaymentPage extends ConsumerStatefulWidget {
  const PaymentPage({super.key});

  @override
  ConsumerState<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends ConsumerState<PaymentPage> {
  final _cashController = TextEditingController();
  final _upiController = TextEditingController();
  final _discountController = TextEditingController(text: '0');
  final _packingController = TextEditingController(text: '0');
  final _customerNameController = TextEditingController();
  final _customerPhoneController = TextEditingController();
  late final NumberFormat _currency;

  @override
  void initState() {
    super.initState();
    _currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final session = ref.read(billingSessionProvider);
      _customerNameController.text = session.customerName ?? '';
      _customerPhoneController.text = session.customerPhone ?? '';
      final summary = ref.read(cartSummaryProvider);
      final total = ref.read(paymentCheckoutControllerProvider).payableTotal(
            subtotal: summary.subtotal,
            taxTotal: summary.taxTotal,
          );
      ref
          .read(paymentCheckoutControllerProvider.notifier)
          .selectMode(PaymentMode.cash, total);
      _syncControllers();
    });
  }

  @override
  void dispose() {
    _cashController.dispose();
    _upiController.dispose();
    _discountController.dispose();
    _packingController.dispose();
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    super.dispose();
  }

  void _persistCustomer() {
    ref.read(billingSessionProvider.notifier).updateCustomer(
          name: _customerNameController.text,
          phone: _customerPhoneController.text,
        );
  }

  void _syncControllers() {
    final state = ref.read(paymentCheckoutControllerProvider);
    _cashController.text = state.cashAmount.toStringAsFixed(2);
    _upiController.text = state.upiAmount.toStringAsFixed(2);
  }

  double _payable(CartSummary summary, PaymentCheckoutState checkout) =>
      checkout.payableTotal(
        subtotal: summary.subtotal,
        taxTotal: summary.taxTotal,
      );

  Future<void> _complete() async {
    _persistCustomer();
    final summary = ref.read(cartSummaryProvider);
    final result = await ref
        .read(paymentCheckoutControllerProvider.notifier)
        .completePayment(
          subtotal: summary.subtotal,
          taxTotal: summary.taxTotal,
        );
    if (!mounted || result == null) return;

    final session = ref.read(billingSessionProvider);
    unawaited(
      ref
          .read(invoiceSyncControllerProvider.notifier)
          .uploadPending(onlyInvoiceId: result.invoiceId),
    );

    final autoPrint = ref.read(printerSettingsProvider).autoShareOnSave;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Bill saved'),
        content: Text(
          'Invoice: ${result.invoiceNumber}\n'
          'Payment: ${result.paymentMode}\n'
          'Amount: ${_currency.format(result.totalAmount)}'
          '${session.tableNumber != null ? '\nTable: ${session.tableNumber}' : ''}'
          '${session.customerName != null ? '\nCustomer: ${session.customerName}' : ''}',
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final printResult =
                  await printInvoiceById(ref, result.invoiceId);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(printResult.message ?? 'Print done'),
                ),
              );
            },
            child: const Text('Print / Share'),
          ),
          AppButton(
            label: 'New bill',
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(paymentCheckoutControllerProvider.notifier).reset();
              context.go(session.billingRoute);
            },
            expanded: false,
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(paymentCheckoutControllerProvider.notifier).reset();
              context.go('/');
            },
            child: const Text('Home'),
          ),
        ],
      ),
    );

    if (autoPrint && mounted) {
      final printResult = await printInvoiceById(ref, result.invoiceId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(printResult.message ?? 'Print done')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final summary = ref.watch(cartSummaryProvider);
    final cartAsync = ref.watch(cartItemsProvider);
    final checkout = ref.watch(paymentCheckoutControllerProvider);
    final session = ref.watch(billingSessionProvider);
    final printerSettings = ref.watch(printerSettingsProvider);
    final showCustomer = printerSettings.customerUse ||
        session.invoiceType == 'take_away' ||
        (session.customerName?.trim().isNotEmpty ?? false) ||
        (session.customerPhone?.trim().isNotEmpty ?? false);
    final theme = Theme.of(context);

    ref.listen(paymentCheckoutControllerProvider, (prev, next) {
      if (next.errorMessage != null &&
          next.errorMessage != prev?.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.errorMessage!)),
        );
      }
    });

    if (summary.isEmpty && checkout.result == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Invoice Preview')),
        body: const Center(
          child: Text('Cart is empty. Add products before payment.'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: const Text('Invoice Preview'),
        actions: [
          if (session.tableNumber != null)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: Text(
                  'T${session.tableNumber}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (showCustomer)
                        AppCard(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Customer',
                                  style: TextStyle(fontWeight: FontWeight.w800),
                                ),
                                const SizedBox(height: 12),
                                AppTextField(
                                  controller: _customerNameController,
                                  label: 'Name',
                                  textCapitalization: TextCapitalization.words,
                                  onChanged: (_) => _persistCustomer(),
                                ),
                                const SizedBox(height: 12),
                                AppTextField(
                                  controller: _customerPhoneController,
                                  label: 'Mobile',
                                  keyboardType: TextInputType.phone,
                                  onChanged: (_) => _persistCustomer(),
                                ),
                              ],
                            ),
                        ),
                      if (showCustomer) const SizedBox(height: 12),
                      AppCard(
                        accentColor: AppColors.primary,
                        padding: EdgeInsets.zero,
                        child: Column(
                          children: [
                            const ListTile(
                              leading: AppModuleIcon(icon: Icons.shopping_bag_rounded, color: AppColors.primary, size: 44),
                              title: Text(
                                'Items',
                                style: TextStyle(fontWeight: FontWeight.w900),
                              ),
                            ),
                            const Divider(height: 1),
                            cartAsync.when(
                              data: (items) => Column(
                                children: items
                                    .map(
                                      (item) => ListTile(
                                        dense: true,
                                        title: Text(item.productName),
                                        subtitle: Text(
                                          '${_currency.format(item.unitPrice)} × ${item.quantity}',
                                        ),
                                        trailing: Text(
                                          _currency.format(
                                            item.unitPrice * item.quantity,
                                          ),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ),
                              loading: () => const Padding(
                                padding: EdgeInsets.all(16),
                                child: CircularProgressIndicator(),
                              ),
                              error: (e, _) => ListTile(title: Text('$e')),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      AppCard(
                        accentColor: AppColors.orange,
                        child: Column(
                            children: [
                              _PayRow(
                                'Sub Total',
                                _currency.format(summary.subtotal),
                              ),
                              _PayRow(
                                'GST',
                                _currency.format(summary.taxTotal),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: StringDropdownField(
                                      label: 'Disc type',
                                      value: checkout.discountType,
                                      options: const ['Amount', 'Percent'],
                                      onChanged: checkout.busy
                                          ? (_) {}
                                          : (v) {
                                              if (v == null) return;
                                              final d = double.tryParse(
                                                    _discountController.text,
                                                  ) ??
                                                  0;
                                              final n = ref.read(
                                                paymentCheckoutControllerProvider
                                                    .notifier,
                                              );
                                              n.setDiscount(d, type: v);
                                              n.selectMode(
                                                checkout.mode,
                                                _payable(
                                                  summary,
                                                  ref.read(
                                                    paymentCheckoutControllerProvider,
                                                  ),
                                                ),
                                              );
                                              _syncControllers();
                                            },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    flex: 2,
                                    child: AppTextField(
                                      controller: _discountController,
                                      label: 'Discount',
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      onChanged: checkout.busy
                                          ? null
                                          : (v) {
                                              final d =
                                                  double.tryParse(v) ?? 0;
                                              final n = ref.read(
                                                paymentCheckoutControllerProvider
                                                    .notifier,
                                              );
                                              n.setDiscount(d);
                                              n.selectMode(
                                                checkout.mode,
                                                _payable(
                                                  summary,
                                                  ref.read(
                                                    paymentCheckoutControllerProvider,
                                                  ),
                                                ),
                                              );
                                              _syncControllers();
                                            },
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: StringDropdownField(
                                      label: 'Pack type',
                                      value: checkout.packingChargeType,
                                      options: const ['Amount', 'Percent'],
                                      onChanged: checkout.busy
                                          ? (_) {}
                                          : (v) {
                                              if (v == null) return;
                                              final p = double.tryParse(
                                                    _packingController.text,
                                                  ) ??
                                                  0;
                                              final n = ref.read(
                                                paymentCheckoutControllerProvider
                                                    .notifier,
                                              );
                                              n.setPacking(p, type: v);
                                              n.selectMode(
                                                checkout.mode,
                                                _payable(
                                                  summary,
                                                  ref.read(
                                                    paymentCheckoutControllerProvider,
                                                  ),
                                                ),
                                              );
                                              _syncControllers();
                                            },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    flex: 2,
                                    child: AppTextField(
                                      controller: _packingController,
                                      label: 'Packing',
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      onChanged: checkout.busy
                                          ? null
                                          : (v) {
                                              final p =
                                                  double.tryParse(v) ?? 0;
                                              final n = ref.read(
                                                paymentCheckoutControllerProvider
                                                    .notifier,
                                              );
                                              n.setPacking(p);
                                              n.selectMode(
                                                checkout.mode,
                                                _payable(
                                                  summary,
                                                  ref.read(
                                                    paymentCheckoutControllerProvider,
                                                  ),
                                                ),
                                              );
                                              _syncControllers();
                                            },
                                    ),
                                  ),
                                ],
                              ),
                              if (checkout.discountValue(summary.subtotal) >
                                  0) ...[
                                const SizedBox(height: 8),
                                _PayRow(
                                  'Discount',
                                  '- ${_currency.format(checkout.discountValue(summary.subtotal))}',
                                ),
                              ],
                              if (checkout.packingValue(summary.subtotal) >
                                  0) ...[
                                const SizedBox(height: 4),
                                _PayRow(
                                  'Packing',
                                  _currency.format(
                                    checkout.packingValue(summary.subtotal),
                                  ),
                                ),
                              ],
                              const Divider(),
                              _PayRow(
                                'TOTAL',
                                _currency.format(_payable(summary, checkout)),
                                bold: true,
                              ),
                            ],
                          ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Payment mode',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: 2.65,
                        children: PaymentMode.values.map((mode) {
                          final selected = checkout.mode == mode;
                          final total = _payable(summary, checkout);
                          final color = _paymentColor(mode);
                          return InkWell(
                            borderRadius: BorderRadius.circular(18),
                            onTap: checkout.busy ? null : () {
                              ref.read(paymentCheckoutControllerProvider.notifier).selectMode(mode, total);
                              _syncControllers();
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 220),
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: selected ? color : color.withValues(alpha: .08),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: color.withValues(alpha: selected ? .8 : .16), width: selected ? 2 : 1),
                              ),
                              child: Row(
                                children: [
                                  Icon(_paymentIcon(mode), color: selected ? Colors.white : color),
                                  const SizedBox(width: 9),
                                  Expanded(child: Text(mode.label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.w900, color: selected ? Colors.white : AppColors.navy))),
                                  if (selected) const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      if (checkout.mode == PaymentMode.cashPlusUpi) ...[
                        const SizedBox(height: 16),
                        AppTextField(
                          controller: _cashController,
                          label: 'Cash amount',
                          prefixIcon: Icons.payments_outlined,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                          ],
                          onChanged: (value) {
                            final cash = double.tryParse(value) ?? 0;
                            ref
                                .read(
                                  paymentCheckoutControllerProvider.notifier,
                                )
                                .setCashAmount(
                                  cash,
                                  _payable(summary, checkout),
                                );
                            final upi = ref
                                .read(paymentCheckoutControllerProvider)
                                .upiAmount;
                            _upiController.text = upi.toStringAsFixed(2);
                          },
                        ),
                        const SizedBox(height: 12),
                        AppTextField(
                          controller: _upiController,
                          label: 'UPI amount',
                          prefixIcon: Icons.qr_code_2_rounded,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                          ],
                          onChanged: (value) {
                            final upi = double.tryParse(value) ?? 0;
                            ref
                                .read(
                                  paymentCheckoutControllerProvider.notifier,
                                )
                                .setUpiAmount(
                                  upi,
                                  _payable(summary, checkout),
                                );
                            final cash = ref
                                .read(paymentCheckoutControllerProvider)
                                .cashAmount;
                            _cashController.text = cash.toStringAsFixed(2);
                          },
                        ),
                      ],
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
                Material(
                  elevation: 10,
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Payable amount',
                                style: TextStyle(color: Colors.black54),
                              ),
                              Text(
                                _currency.format(_payable(summary, checkout)),
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        AppButton(
                          label: 'PRINT BILL',
                          icon: Icons.print_rounded,
                          isLoading: checkout.busy,
                          expanded: false,
                          onPressed: summary.isEmpty ? null : _complete,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Color _paymentColor(PaymentMode mode) {
  switch (mode) {
    case PaymentMode.cash: return AppColors.green;
    case PaymentMode.upi: return AppColors.primary;
    case PaymentMode.card: return AppColors.purple;
    case PaymentMode.cashPlusUpi: return AppColors.orange;
  }
}

IconData _paymentIcon(PaymentMode mode) {
  switch (mode) {
    case PaymentMode.cash: return Icons.payments_rounded;
    case PaymentMode.upi: return Icons.qr_code_2_rounded;
    case PaymentMode.card: return Icons.credit_card_rounded;
    case PaymentMode.cashPlusUpi: return Icons.account_balance_wallet_rounded;
  }
}

class _PayRow extends StatelessWidget {
  const _PayRow(this.label, this.value, {this.bold = false});

  final String label;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final style = bold
        ? const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)
        : null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(label, style: style),
          const Spacer(),
          Text(
            value,
            style: style?.copyWith(color: AppColors.primary) ?? style,
          ),
        ],
      ),
    );
  }
}
