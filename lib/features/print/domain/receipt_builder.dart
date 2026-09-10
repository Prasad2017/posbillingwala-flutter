import 'package:intl/intl.dart';
import 'package:pos_billingwala_v2/core/database/app_database.dart';
import 'package:pos_billingwala_v2/features/print/domain/esc_pos_encoder.dart';
import 'package:pos_billingwala_v2/features/print/domain/printer_settings.dart';
import 'package:pos_billingwala_v2/features/print/domain/receipt_rasterizer.dart';
import 'package:pos_billingwala_v2/features/print/domain/shop_receipt_profile.dart';

/// Bill / KOT receipt content aligned with Android BluetoothPrint layouts.
class ReceiptBuilder {
  ReceiptBuilder(this.settings, {this.shopProfile = const ShopReceiptProfile()});

  final PrinterSettings settings;
  final ShopReceiptProfile shopProfile;
  final _money = NumberFormat('#0.00');
  /// Android bill date format.
  final _date = DateFormat('yyyy-MM-dd HH:mm:ss');
  final _rasterizer = const ReceiptRasterizer();

  /// Marker inserted where UPI QR should appear (terms → QR → footer).
  static const upiQrMarker = '<<<UPI_QR>>>';

  String _rupee(num value) => '₹${_money.format(value)}';

  /// Unicode-safe thermal bytes (any language + ₹) via bitmap, like Android.
  Future<List<int>> billPrintBytes({
    required Invoice invoice,
    required List<InvoiceItem> items,
    String? shopName,
    bool duplicate = false,
  }) {
    final upiUri = _upiUriFor(invoice);
    final logoPath = settings.logoUse ? shopProfile.logoLocalPath : null;
    return _rasterizer.encodeText(
      billText(
        invoice: invoice,
        items: items,
        shopName: shopName,
        duplicate: duplicate,
      ),
      settings: settings,
      qrPayload: upiUri,
      logoPath: logoPath,
      qrMarker: upiUri != null ? upiQrMarker : null,
    );
  }

  Future<List<int>> kotPrintBytes(KotTicket ticket) {
    return _rasterizer.encodeText(kotText(ticket), settings: settings);
  }

  Future<List<int>> rawPrintBytes(String text) {
    return _rasterizer.encodeText(text, settings: settings);
  }

  Future<List<int>> testPrintBytes(String label) {
    final width = settings.charsPerLine;
    final text = StringBuffer()
      ..writeln(_center('POS Billingwala', width))
      ..writeln(_center('टेस्ट प्रिंट / Test', width))
      ..writeln('-' * width)
      ..writeln(label)
      ..writeln(_date.format(DateTime.now()))
      ..writeln(_rupee(123.45))
      ..writeln('-' * width)
      ..writeln('नमस्ते · Hello · வணக்கம்');
    return _rasterizer.encodeText(text.toString(), settings: settings);
  }

  String? _upiUriFor(Invoice invoice) {
    if (!settings.paymentUse || !shopProfile.hasUpiId) return null;
    final amount = invoice.totalAmount > 0
        ? invoice.totalAmount
        : (invoice.upiAmount > 0 ? invoice.upiAmount : 0.0);
    return buildUpiPayUri(
      upiId: shopProfile.upiId,
      payeeName: shopProfile.shopName1.trim().isNotEmpty
          ? shopProfile.shopName1.trim()
          : (shopProfile.companyName.isNotEmpty
              ? shopProfile.companyName
              : 'Merchant'),
      amount: amount,
      note: invoice.invoiceNumber,
    );
  }

  /// Android ORIGINAL / DUPLICATE bill layout (BluetoothPrint).
  String billText({
    required Invoice invoice,
    required List<InvoiceItem> items,
    String? shopName,
    bool duplicate = false,
  }) {
    final width = settings.charsPerLine;
    final buf = StringBuffer();

    // 1) Shop header (logo drawn separately by rasterizer)
    final header = shopProfile.headerLines();
    if (header.isNotEmpty) {
      for (final line in header) {
        buf.writeln(_center(line, width));
      }
    } else {
      final shop = (shopName?.trim().isNotEmpty ?? false)
          ? shopName!.trim()
          : 'POS Billingwala';
      buf.writeln(_center(shop, width));
    }

    // 2) Bill meta (before copy banner — Android order)
    buf.writeln('Bill No: ${invoice.invoiceNumber}');
    buf.writeln('Date: ${_date.format(invoice.invoiceDate)}');
    if (invoice.noOfTable.trim().isNotEmpty) {
      buf.writeln('Table No: ${invoice.noOfTable}');
    }
    if (settings.customerUse) {
      final name = invoice.customerName?.trim();
      final mobile = invoice.customerMobile?.trim();
      buf.writeln(
        'Customer Name: ${name == null || name.isEmpty ? 'NA' : name}',
      );
      buf.writeln(
        'Customer Mobile: ${mobile == null || mobile.isEmpty ? 'NA' : mobile}',
      );
      buf.writeln('Customer Address: NA');
    }

    // 3) Copy banner
    buf.writeln(
      _center(
        duplicate ? '**** Duplicate Copy ****' : '**** Original Copy ****',
        width,
      ),
    );
    buf.writeln('-' * width);

    // 4) Item columns — Android ITEM | RATE | AMOUNT (qty on item row as Xn)
    final itemW = width - 16;
    final rateW = 8;
    final amtW = 8;
    buf.writeln(_columns(['ITEM', 'RATE', 'AMOUNT'], [itemW, rateW, amtW]));
    buf.writeln('-' * width);

    for (final item in items) {
      final amt = item.productPrice * item.productQuantity;
      buf.writeln(item.productName);
      buf.writeln(
        _columns(
          [
            'X${item.productQuantity}',
            _money.format(item.productPrice),
            _money.format(amt),
          ],
          [itemW, rateW, amtW],
        ),
      );
    }
    buf.writeln('-' * width);

    // 5) Totals — Android labels + shop CGST/SGST %
    buf.writeln(_pair('SUB TOTAL', _rupee(invoice.subTotal), width));

    final cgstPct = double.tryParse(shopProfile.shopCgst.trim()) ?? 0;
    final sgstPct = double.tryParse(shopProfile.shopSgst.trim()) ?? 0;
    final gstOn = shopProfile.gstEnabled && (cgstPct > 0 || sgstPct > 0);
    if (gstOn) {
      final cgstAmt = invoice.subTotal * cgstPct / 100;
      final sgstAmt = invoice.subTotal * sgstPct / 100;
      if (cgstPct > 0) {
        buf.writeln(
          _pair(
            'CGST@${_money.format(cgstPct)}%',
            _rupee(cgstAmt),
            width,
          ),
        );
      }
      if (sgstPct > 0) {
        buf.writeln(
          _pair(
            'SGST@${_money.format(sgstPct)}%',
            _rupee(sgstAmt),
            width,
          ),
        );
      }
    } else if (invoice.totalGstAmount > 0) {
      // Fallback when shop rates missing but invoice has GST.
      final half = invoice.totalGstAmount / 2;
      buf.writeln(_pair('CGST', _rupee(half), width));
      buf.writeln(_pair('SGST', _rupee(half), width));
    }

    buf.writeln(_pair('DISCOUNT', _rupee(invoice.discount), width));
    if (invoice.packingCharge > 0) {
      buf.writeln(_pair('PACKING', _rupee(invoice.packingCharge), width));
    }

    // Android Math.ceil on total
    final totalCeil = invoice.totalAmount.ceilToDouble();
    buf.writeln(_pair('TOTAL AMOUNT', _rupee(totalCeil), width));
    buf.writeln('-' * width);

    // 6) Terms
    if (settings.invoiceTerms.trim().isNotEmpty) {
      buf.writeln(_center(settings.invoiceTerms.trim(), width));
    }

    // 7) UPI QR marker (rasterizer inserts QR here — no caption text)
    if (settings.paymentUse && shopProfile.hasUpiId) {
      buf.writeln(upiQrMarker);
    }

    // 8) Footer
    buf.writeln(_center('Powered by POS Billingwala', width));
    buf.writeln(_center('www.posbillingwala.com', width));
    return buf.toString();
  }

  /// Latin-1 fallback only. Prefer [billPrintBytes] for Unicode / ₹.
  List<int> billEscPos({
    required Invoice invoice,
    required List<InvoiceItem> items,
    String? shopName,
  }) {
    final text = billText(invoice: invoice, items: items)
        .replaceAll(upiQrMarker, '')
        .replaceAll('₹', 'Rs.');
    final encoder = EscPosEncoder(charsPerLine: settings.charsPerLine)
      ..init();
    for (final line in text.split('\n')) {
      if (line.trim().isEmpty) continue;
      encoder.text(line);
    }
    encoder.feed(settings.feedLines);
    return encoder.bytes;
  }

  String kotText(KotTicket ticket) {
    final width = settings.charsPerLine;
    final buf = StringBuffer()
      ..writeln(_center('KOT', width))
      ..writeln(_center(ticket.kot.kotNumber, width))
      ..writeln('-' * width)
      ..writeln('KOT: ${ticket.kot.kotNumber}')
      ..writeln('Date: ${_date.format(ticket.kot.createdAt)}')
      ..writeln('Table No: ${ticket.kot.tableNumber}')
      ..writeln('Round: ${ticket.roundNumber}')
      ..writeln(ticket.kot.kitchenName)
      ..writeln('-' * width);
    for (final item in ticket.items) {
      buf.writeln(
        _pair(item.productName, 'X${item.productQuantity}', width),
      );
    }
    buf.writeln('-' * width);
    return buf.toString();
  }

  /// Latin-1 fallback only. Prefer [kotPrintBytes] for Unicode.
  List<int> kotEscPos(KotTicket ticket) {
    final encoder = EscPosEncoder(charsPerLine: settings.charsPerLine)
      ..init()
      ..text('KOT', boldStyle: true, center: true)
      ..text(ticket.kot.kotNumber, boldStyle: true, center: true)
      ..separator()
      ..text('Date: ${_date.format(ticket.kot.createdAt)}')
      ..text('Table No: ${ticket.kot.tableNumber}')
      ..text('Round: ${ticket.roundNumber}')
      ..text(ticket.kot.kitchenName)
      ..separator();
    for (final item in ticket.items) {
      encoder.line(item.productName, 'X${item.productQuantity}');
    }
    encoder
      ..separator()
      ..feed(settings.feedLines);
    return encoder.bytes;
  }

  List<int> testEscPos(String label) {
    return (EscPosEncoder(charsPerLine: settings.charsPerLine)
          ..init()
          ..text('POS Billingwala', boldStyle: true, center: true)
          ..text('Test print', center: true)
          ..separator()
          ..text(label)
          ..text(_date.format(DateTime.now()))
          ..separator()
          ..feed(settings.feedLines))
        .bytes;
  }

  String _center(String value, int width) {
    if (value.runes.length >= width) return value;
    final pad = width - value.runes.length;
    final left = pad ~/ 2;
    return (' ' * left) + value;
  }

  String _pair(String left, String right, int width) {
    final space = width - left.runes.length - right.runes.length;
    final gap = space > 1 ? ' ' * space : ' ';
    return '$left$gap$right';
  }

  String _columns(List<String> values, List<int> widths) {
    final parts = <String>[];
    for (var i = 0; i < values.length; i++) {
      final w = widths[i];
      final v = values[i];
      if (i == values.length - 1) {
        parts.add(v.padLeft(w));
      } else if (i == 0) {
        parts.add(v.padRight(w));
      } else {
        parts.add(v.padLeft(w));
      }
    }
    return parts.join();
  }
}
