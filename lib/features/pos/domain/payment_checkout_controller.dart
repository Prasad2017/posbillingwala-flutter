import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_billingwala_v2/core/database/database_provider.dart';
import 'package:pos_billingwala_v2/features/auth/data/device_identity_service.dart';
import 'package:pos_billingwala_v2/features/auth/domain/auth_controller.dart';
import 'package:pos_billingwala_v2/features/auth/domain/license_validator.dart';
import 'package:pos_billingwala_v2/features/pos/domain/billing_session.dart';
import 'package:pos_billingwala_v2/features/pos/domain/payment_mode.dart';
import 'package:pos_billingwala_v2/features/print/domain/printer_settings.dart';

class PaymentCheckoutState {
  const PaymentCheckoutState({
    this.mode = PaymentMode.cash,
    this.cashAmount = 0,
    this.upiAmount = 0,
    this.discount = 0,
    this.discountType = 'Amount',
    this.packingCharge = 0,
    this.packingChargeType = 'Amount',
    this.busy = false,
    this.errorMessage,
    this.result,
  });

  final PaymentMode mode;
  final double cashAmount;
  final double upiAmount;
  final double discount;
  final String discountType;
  final double packingCharge;
  final String packingChargeType;
  final bool busy;
  final String? errorMessage;
  final SavedInvoiceResult? result;

  double discountValue(double subtotal) {
    if (discount <= 0) return 0;
    if (discountType.toLowerCase().startsWith('p')) {
      return double.parse((subtotal * discount / 100).toStringAsFixed(2));
    }
    return double.parse(discount.toStringAsFixed(2));
  }

  double packingValue(double subtotal) {
    if (packingCharge <= 0) return 0;
    if (packingChargeType.toLowerCase().startsWith('p')) {
      return double.parse((subtotal * packingCharge / 100).toStringAsFixed(2));
    }
    return double.parse(packingCharge.toStringAsFixed(2));
  }

  double payableTotal({required double subtotal, required double taxTotal}) {
    final disc = discountValue(subtotal);
    final pack = packingValue(subtotal);
    return double.parse(
      (subtotal + taxTotal + pack - disc).clamp(0, double.infinity).toStringAsFixed(2),
    );
  }

  PaymentCheckoutState copyWith({
    PaymentMode? mode,
    double? cashAmount,
    double? upiAmount,
    double? discount,
    String? discountType,
    double? packingCharge,
    String? packingChargeType,
    bool? busy,
    String? errorMessage,
    SavedInvoiceResult? result,
    bool clearError = false,
    bool clearResult = false,
  }) {
    return PaymentCheckoutState(
      mode: mode ?? this.mode,
      cashAmount: cashAmount ?? this.cashAmount,
      upiAmount: upiAmount ?? this.upiAmount,
      discount: discount ?? this.discount,
      discountType: discountType ?? this.discountType,
      packingCharge: packingCharge ?? this.packingCharge,
      packingChargeType: packingChargeType ?? this.packingChargeType,
      busy: busy ?? this.busy,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      result: clearResult ? null : (result ?? this.result),
    );
  }
}

class PaymentCheckoutController extends Notifier<PaymentCheckoutState> {
  @override
  PaymentCheckoutState build() => const PaymentCheckoutState();

  void selectMode(PaymentMode mode, double totalAmount) {
    switch (mode) {
      case PaymentMode.cash:
        state = state.copyWith(
          mode: mode,
          cashAmount: totalAmount,
          upiAmount: 0,
          clearError: true,
        );
      case PaymentMode.upi:
        state = state.copyWith(
          mode: mode,
          cashAmount: 0,
          upiAmount: totalAmount,
          clearError: true,
        );
      case PaymentMode.cashPlusUpi:
        state = state.copyWith(
          mode: mode,
          cashAmount: totalAmount,
          upiAmount: 0,
          clearError: true,
        );
    }
  }

  void setCashAmount(double value, double totalAmount) {
    final cash = value < 0 ? 0.0 : value;
    final remaining =
        double.parse((totalAmount - cash).clamp(0, totalAmount).toStringAsFixed(2));
    state = state.copyWith(
      cashAmount: double.parse(cash.toStringAsFixed(2)),
      upiAmount: remaining,
      clearError: true,
    );
  }

  void setUpiAmount(double value, double totalAmount) {
    final upi = value < 0 ? 0.0 : value;
    final remaining =
        double.parse((totalAmount - upi).clamp(0, totalAmount).toStringAsFixed(2));
    state = state.copyWith(
      upiAmount: double.parse(upi.toStringAsFixed(2)),
      cashAmount: remaining,
      clearError: true,
    );
  }

  void setDiscount(double value, {String? type}) {
    state = state.copyWith(
      discount: value < 0 ? 0 : double.parse(value.toStringAsFixed(2)),
      discountType: type,
      clearError: true,
    );
  }

  void setPacking(double value, {String? type}) {
    state = state.copyWith(
      packingCharge: value < 0 ? 0 : double.parse(value.toStringAsFixed(2)),
      packingChargeType: type,
      clearError: true,
    );
  }

  Future<SavedInvoiceResult?> completePayment({
    required double subtotal,
    required double taxTotal,
  }) async {
    final totalAmount = state.payableTotal(subtotal: subtotal, taxTotal: taxTotal);
    state = state.copyWith(busy: true, clearError: true, clearResult: true);
    try {
      final tender = PaymentTender.resolve(
        mode: state.mode,
        totalAmount: totalAmount,
        cashAmount: state.cashAmount,
        upiAmount: state.upiAmount,
      );
      if (!tender.isValidFor(totalAmount)) {
        state = state.copyWith(
          busy: false,
          errorMessage: 'Cash + UPI must equal the bill total',
        );
        return null;
      }

      final session = ref.read(billingSessionProvider);
      final printer = ref.read(printerSettingsProvider);
      final invoiceCount =
          await ref.read(appDatabaseProvider).countTotalInvoices();
      final authSession = ref.read(authControllerProvider).session;
      final device = await DeviceIdentityService().resolve();
      final licence = await LicenseValidator.validate(
        deviceId: device.deviceId,
        licenceKey: authSession?.licenceKey ?? '',
        localInvoiceCount: invoiceCount,
      );
      if (licence.trialBillBlocked ||
          (!licence.valid && !licence.legacyFallback)) {
        state = state.copyWith(
          busy: false,
          errorMessage: licence.message.isNotEmpty
              ? licence.message
              : 'Billing is not allowed for this licence',
        );
        return null;
      }

      final prefix = printer.invoicePrefix.trim().isNotEmpty
          ? printer.invoicePrefix.trim()
          : session.invoicePrefix;
      final result = await ref.read(appDatabaseProvider).saveInvoiceFromCart(
            tender: tender,
            invoiceType: session.invoiceType,
            invoicePrefix: prefix,
            customerName: session.customerName,
            customerMobile: session.customerPhone,
            cartScope: session.cartScope,
            tableNumber: session.tableNumber,
            diningSessionId: session.diningSessionId,
            discount: state.discount,
            discountType: state.discountType,
            packingCharge: state.packingCharge,
            packingChargeType: state.packingChargeType,
            updateInventory: printer.productQuantityUpdate,
          );
      state = state.copyWith(busy: false, result: result);
      return result;
    } catch (e) {
      state = state.copyWith(
        busy: false,
        errorMessage: e.toString().replaceFirst('Bad state: ', ''),
      );
      return null;
    }
  }

  void reset() {
    state = const PaymentCheckoutState();
  }
}

final paymentCheckoutControllerProvider =
    NotifierProvider<PaymentCheckoutController, PaymentCheckoutState>(
  PaymentCheckoutController.new,
);
