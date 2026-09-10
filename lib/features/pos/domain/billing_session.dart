import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Active billing context for POS / Takeaway / Table flows.
class BillingSession {
  const BillingSession({
    required this.invoiceType,
    required this.title,
    required this.billingRoute,
    required this.paymentRoute,
    this.customerName,
    this.customerPhone,
    this.invoicePrefix = 'PB',
    this.cartScope = '',
    this.tableNumber,
    this.diningSessionId,
  });

  final String invoiceType;
  final String title;
  final String billingRoute;
  final String paymentRoute;
  final String? customerName;
  final String? customerPhone;
  final String invoicePrefix;
  final String cartScope;
  final String? tableNumber;
  final int? diningSessionId;

  static const pos = BillingSession(
    invoiceType: 'fast_billing',
    title: 'POS Billing',
    billingRoute: '/pos',
    paymentRoute: '/pos/payment',
  );

  BillingSession copyWith({
    String? invoiceType,
    String? title,
    String? billingRoute,
    String? paymentRoute,
    String? customerName,
    String? customerPhone,
    String? invoicePrefix,
    String? cartScope,
    String? tableNumber,
    int? diningSessionId,
    bool clearCustomer = false,
    bool clearTable = false,
  }) {
    return BillingSession(
      invoiceType: invoiceType ?? this.invoiceType,
      title: title ?? this.title,
      billingRoute: billingRoute ?? this.billingRoute,
      paymentRoute: paymentRoute ?? this.paymentRoute,
      customerName:
          clearCustomer ? null : (customerName ?? this.customerName),
      customerPhone:
          clearCustomer ? null : (customerPhone ?? this.customerPhone),
      invoicePrefix: invoicePrefix ?? this.invoicePrefix,
      cartScope: cartScope ?? this.cartScope,
      tableNumber: clearTable ? null : (tableNumber ?? this.tableNumber),
      diningSessionId:
          clearTable ? null : (diningSessionId ?? this.diningSessionId),
    );
  }
}

class BillingSessionController extends Notifier<BillingSession> {
  @override
  BillingSession build() => BillingSession.pos;

  void usePos() => state = BillingSession.pos;

  void startTakeaway({String? customerName, String? customerPhone}) {
    state = BillingSession(
      invoiceType: 'take_away',
      title: 'Takeaway Billing',
      billingRoute: '/takeaway/billing',
      paymentRoute: '/takeaway/payment',
      customerName: _trimOrNull(customerName),
      customerPhone: _trimOrNull(customerPhone),
    );
  }

  void startTableBilling({
    required String tableNumber,
    required String tableName,
    required int diningSessionId,
  }) {
    state = BillingSession(
      invoiceType: 'table_wise',
      title: 'Table $tableName',
      billingRoute: '/tables/billing',
      paymentRoute: '/tables/payment',
      cartScope: tableNumber,
      tableNumber: tableNumber,
      diningSessionId: diningSessionId,
    );
  }

  void updateCustomer({String? name, String? phone}) {
    final nextName = name != null ? _trimOrNull(name) : state.customerName;
    final nextPhone = phone != null ? _trimOrNull(phone) : state.customerPhone;
    state = BillingSession(
      invoiceType: state.invoiceType,
      title: state.title,
      billingRoute: state.billingRoute,
      paymentRoute: state.paymentRoute,
      customerName: nextName,
      customerPhone: nextPhone,
      invoicePrefix: state.invoicePrefix,
      cartScope: state.cartScope,
      tableNumber: state.tableNumber,
      diningSessionId: state.diningSessionId,
    );
  }

  String? _trimOrNull(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }
}

final billingSessionProvider =
    NotifierProvider<BillingSessionController, BillingSession>(
  BillingSessionController.new,
);
