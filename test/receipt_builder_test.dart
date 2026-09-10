import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:pos_billingwala_v2/features/print/domain/esc_pos_encoder.dart';
import 'package:pos_billingwala_v2/features/print/domain/print_image_encoder.dart';
import 'package:pos_billingwala_v2/features/print/domain/printer_settings.dart';
import 'package:pos_billingwala_v2/features/print/domain/receipt_builder.dart';
import 'package:pos_billingwala_v2/core/database/app_database.dart';

void main() {
  test('esc pos encoder emits init and text bytes', () {
    final encoder = EscPosEncoder(charsPerLine: 32)
      ..init()
      ..text('Hello', boldStyle: true, center: true)
      ..cut();
    expect(encoder.bytes, isNotEmpty);
    expect(encoder.bytes.take(2), [0x1B, 0x40]);
  });

  test('receipt builder includes bill totals', () {
    final invoice = Invoice(
      invoiceId: 1,
      invoiceNumber: 'PB/09-09/00001',
      invoiceDate: DateTime(2026, 9, 9, 10, 30),
      invoiceType: 'fast_billing',
      subTotal: 100,
      totalGstAmount: 5,
      discount: 0,
      discountType: 'Amount',
      packingCharge: 0,
      packingChargeType: 'Amount',
      totalAmount: 105,
      paymentMode: 'Cash',
      cashAmount: 105,
      upiAmount: 0,
      invoiceOrderStatus: 'completed',
      invoiceNetworkStatus: 'abcdefghij',
      invoiceSyncStatus: '0',
      noOfTable: '',
      customerName: 'Ravi',
      customerMobile: null,
      diningSessionId: null,
      itemCount: 1,
      createdAt: DateTime(2026, 9, 9, 10, 30),
      organizationId: '',
      branchId: '',
      deviceId: '',
    );
    final items = [
      InvoiceItem(
        invoiceItemId: 1,
        invoiceNumber: invoice.invoiceNumber,
        productId: 10,
        productName: 'Tea',
        productCode: 'TEA',
        productPrice: 100,
        productQuantity: 1,
        productCgst: 2.5,
        productSgst: 2.5,
        productUnit: 'cup',
        categoryName: 'Beverages',
        invoiceItemType: 'product',
        productStatus: 'completed',
        invoiceItemNetworkStatus: 'itemkey123',
        invoiceItemSyncStatus: '0',
        organizationId: '',
        branchId: '',
        deviceId: '',
      ),
    ];

    final text = ReceiptBuilder(const PrinterSettings()).billText(
      invoice: invoice,
      items: items,
      shopName: 'Demo Cafe',
    );
    expect(text, contains('Demo Cafe'));
    expect(text, contains('PB/09-09/00001'));
    expect(text, contains('Tea'));
    expect(text, contains('TOTAL'));
    expect(text, contains('₹105.00'));
    expect(text, contains('Cash'));
  });

  test('receipt text keeps unicode product names and rupee', () {
    final invoice = Invoice(
      invoiceId: 1,
      invoiceNumber: 'PB/09-09/00002',
      invoiceDate: DateTime(2026, 9, 9, 10, 30),
      invoiceType: 'fast_billing',
      subTotal: 50,
      totalGstAmount: 0,
      discount: 0,
      discountType: 'Amount',
      packingCharge: 0,
      packingChargeType: 'Amount',
      totalAmount: 50,
      paymentMode: 'UPI',
      cashAmount: 0,
      upiAmount: 50,
      invoiceOrderStatus: 'completed',
      invoiceNetworkStatus: 'abcdefghij',
      invoiceSyncStatus: '0',
      noOfTable: '',
      customerName: 'राम',
      customerMobile: null,
      diningSessionId: null,
      itemCount: 1,
      createdAt: DateTime(2026, 9, 9, 10, 30),
      organizationId: '',
      branchId: '',
      deviceId: '',
    );
    final items = [
      InvoiceItem(
        invoiceItemId: 1,
        invoiceNumber: invoice.invoiceNumber,
        productId: 10,
        productName: 'चहा',
        productCode: 'TEA',
        productPrice: 50,
        productQuantity: 1,
        productCgst: 0,
        productSgst: 0,
        productUnit: 'cup',
        categoryName: 'Beverages',
        invoiceItemType: 'product',
        productStatus: 'completed',
        invoiceItemNetworkStatus: 'itemkey123',
        invoiceItemSyncStatus: '0',
        organizationId: '',
        branchId: '',
        deviceId: '',
      ),
    ];

    final text = ReceiptBuilder(const PrinterSettings()).billText(
      invoice: invoice,
      items: items,
      shopName: 'डेमो कॅफे',
    );
    expect(text, contains('डेमो कॅफे'));
    expect(text, contains('चहा'));
    expect(text, contains('राम'));
    expect(text, contains('₹50.00'));
  });

  test('print image encoder emits GS v 0 header', () {
    final rgba = Uint8List(8 * 8 * 4);
    for (var i = 0; i < rgba.length; i += 4) {
      rgba[i] = 0;
      rgba[i + 1] = 0;
      rgba[i + 2] = 0;
      rgba[i + 3] = 255;
    }
    final bytes = PrintImageEncoder.encodeRgba(
      rgba: rgba,
      width: 8,
      height: 8,
    );
    expect(bytes.take(4).toList(), [0x1d, 0x76, 0x30, 0x00]);
  });
}
