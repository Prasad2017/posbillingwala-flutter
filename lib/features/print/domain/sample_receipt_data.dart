import 'package:pos_billingwala_v2/core/database/app_database.dart';

/// Fake bill / KOT used by printer Settings → Test (Android `TestInvoiceBluetoothPrint`).
class SampleReceiptData {
  SampleReceiptData._();

  static const invoiceNumber = 'POS-TEST';

  /// Sample Item A @ ₹100 × 1 + Sample Item B @ ₹150 × 2 = ₹400.
  static ({Invoice invoice, List<InvoiceItem> items}) sampleBill({
    DateTime? now,
  }) {
    final at = now ?? DateTime.now();
    const items = <InvoiceItem>[
      InvoiceItem(
        invoiceItemId: -1,
        invoiceNumber: invoiceNumber,
        productName: 'मिसळ पाव (हाफ)',
        productPrice: 100,
        productQuantity: 1,
        productCgst: 0,
        productSgst: 0,
        invoiceItemType: 'product',
        productStatus: 'completed',
        invoiceItemSyncStatus: '0',
        organizationId: '',
        branchId: '',
        deviceId: '',
      ),
      InvoiceItem(
        invoiceItemId: -2,
        invoiceNumber: invoiceNumber,
        productName: 'वडा पाव (फुल)',
        productPrice: 150,
        productQuantity: 2,
        productCgst: 0,
        productSgst: 0,
        invoiceItemType: 'product',
        productStatus: 'completed',
        invoiceItemSyncStatus: '0',
        organizationId: '',
        branchId: '',
        deviceId: '',
      ),
    ];
    const subTotal = 400.0;
    final invoice = Invoice(
      invoiceId: -1,
      invoiceNumber: invoiceNumber,
      invoiceDate: at,
      invoiceType: 'fast_billing',
      subTotal: subTotal,
      totalGstAmount: 0,
      discount: 0,
      discountType: 'Amount',
      packingCharge: 0,
      packingChargeType: 'Amount',
      totalAmount: subTotal,
      paymentMode: 'Cash',
      cashAmount: subTotal,
      upiAmount: 0,
      invoiceOrderStatus: 'completed',
      invoiceNetworkStatus: 'test-preview',
      invoiceSyncStatus: '0',
      noOfTable: '1',
      customerName: 'नमस्ते ग्राहक',
      customerMobile: '9999999999',
      itemCount: 2,
      createdAt: at,
      organizationId: '',
      branchId: '',
      deviceId: '',
    );
    return (invoice: invoice, items: items);
  }

  static KotTicket sampleKot({DateTime? now}) {
    final at = now ?? DateTime.now();
    return KotTicket(
      kot: Kot(
        kotId: -1,
        sessionId: -1,
        orderRoundId: -1,
        kotNumber: 'KOT-TEST',
        tableNumber: '1',
        printStatus: 'pending',
        kitchenName: 'Main Kitchen',
        createdAt: at,
        organizationId: '',
        branchId: '',
        deviceId: '',
      ),
      roundNumber: 1,
      items: const [
        KotItem(
          kotItemId: -1,
          kotId: -1,
          productName: 'मिसळ पाव (हाफ)',
          productQuantity: 1,
          portionName: 'हाफ',
          organizationId: '',
          branchId: '',
          deviceId: '',
        ),
        KotItem(
          kotItemId: -2,
          kotId: -1,
          productName: 'वडा पाव (फुल)',
          productQuantity: 2,
          portionName: 'फुल',
          organizationId: '',
          branchId: '',
          deviceId: '',
        ),
      ],
    );
  }
}
