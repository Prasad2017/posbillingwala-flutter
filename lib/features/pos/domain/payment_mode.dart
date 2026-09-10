/// Payment modes aligned with Android `PaymentSettlementHelper`.
enum PaymentMode {
  cash('Cash'),
  upi('UPI'),
  cashPlusUpi('Cash+UPI');

  const PaymentMode(this.label);
  final String label;

  static PaymentMode fromLabel(String? value) {
    switch (value) {
      case 'UPI':
      case 'Online':
        return PaymentMode.upi;
      case 'Cash+UPI':
        return PaymentMode.cashPlusUpi;
      case 'Cash':
      default:
        return PaymentMode.cash;
    }
  }
}

class PaymentTender {
  const PaymentTender({
    required this.mode,
    required this.cashAmount,
    required this.upiAmount,
  });

  final PaymentMode mode;
  final double cashAmount;
  final double upiAmount;

  factory PaymentTender.resolve({
    required PaymentMode mode,
    required double totalAmount,
    double? cashAmount,
    double? upiAmount,
  }) {
    final total = double.parse(totalAmount.toStringAsFixed(2));

    switch (mode) {
      case PaymentMode.cash:
        return PaymentTender(mode: mode, cashAmount: total, upiAmount: 0);
      case PaymentMode.upi:
        return PaymentTender(mode: mode, cashAmount: 0, upiAmount: total);
      case PaymentMode.cashPlusUpi:
        final cash = double.parse((cashAmount ?? 0).toStringAsFixed(2));
        final upi = double.parse((upiAmount ?? 0).toStringAsFixed(2));
        return PaymentTender(mode: mode, cashAmount: cash, upiAmount: upi);
    }
  }

  bool isValidFor(double totalAmount) {
    final total = double.parse(totalAmount.toStringAsFixed(2));
    final sum = double.parse((cashAmount + upiAmount).toStringAsFixed(2));
    if (mode == PaymentMode.cashPlusUpi) {
      return (sum - total).abs() <= 0.05 && cashAmount >= 0 && upiAmount >= 0;
    }
    return (sum - total).abs() <= 0.05;
  }
}

class SavedInvoiceResult {
  const SavedInvoiceResult({
    required this.invoiceId,
    required this.invoiceNumber,
    required this.totalAmount,
    required this.paymentMode,
  });

  final int invoiceId;
  final String invoiceNumber;
  final double totalAmount;
  final String paymentMode;
}
