import 'dart:io';

import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pos_billingwala_v2/core/database/app_database.dart';
import 'package:share_plus/share_plus.dart';

/// Android-style HTML spreadsheet saved as `.xls` (opens in Excel / Sheets).
String buildHtmlSpreadsheet({
  required String reportTitle,
  String? subtitle,
  required List<List<String>> rows,
}) {
  final buf = StringBuffer();
  buf
    ..write(
      '<html xmlns:o="urn:schemas-microsoft-com:office:office" '
      'xmlns:x="urn:schemas-microsoft-com:office:excel" '
      'xmlns="http://www.w3.org/TR/REC-html40">',
    )
    ..write('<head><meta charset="UTF-8"><style>')
    ..write('body{font-family:Arial,sans-serif;color:#222;margin:16px;}')
    ..write('h2{margin:0 0 4px 0;font-size:18px;}')
    ..write('.meta{margin:0 0 12px 0;color:#555;font-size:13px;}')
    ..write('table{border-collapse:collapse;width:100%;}')
    ..write('th,td{border:1px solid #CCCCCC;padding:6px 8px;font-size:13px;}')
    ..write('th{background:#E8F0FE;font-weight:bold;text-align:left;}')
    ..write('tr.data:nth-child(even){background:#FAFAFA;}')
    ..write('tr.total td{font-weight:bold;background:#F0F0F0;}')
    ..write('</style></head><body>')
    ..write('<h2>${_escapeHtml(reportTitle)}</h2>');
  if (subtitle != null && subtitle.trim().isNotEmpty) {
    buf.write('<p class="meta">${_escapeHtml(subtitle.trim())}</p>');
  }
  buf.write('<table><thead><tr>');
  if (rows.isNotEmpty) {
    for (final header in rows.first) {
      buf.write('<th>${_escapeHtml(header)}</th>');
    }
    buf.write('</tr></thead><tbody>');
    final columnCount = rows.first.length;
    for (var i = 1; i < rows.length; i++) {
      final row = rows[i];
      final totalRow = _isTotalRow(row);
      buf.write('<tr class="${totalRow ? 'total' : 'data'}">');
      for (var j = 0; j < columnCount; j++) {
        final cell = j < row.length ? row[j] : '';
        buf.write('<td>${_escapeHtml(cell)}</td>');
      }
      buf.write('</tr>');
    }
  }
  buf.write('</tbody></table></body></html>');
  return buf.toString();
}

bool _isTotalRow(List<String> row) {
  for (final cell in row) {
    final t = cell.trim().toLowerCase();
    if (t == 'total' || t == 'total amount' || t.startsWith('total ')) {
      return true;
    }
  }
  return false;
}

String _escapeHtml(String value) {
  return value
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;');
}

String _invoiceTypeLabel(String type) {
  final lower = type.toLowerCase();
  if (lower.contains('mess')) return 'Mess';
  return switch (type) {
    'take_away' => 'Takeaway',
    'table_wise' => 'Table',
    _ => 'POS',
  };
}

Future<void> _shareXlsFile({
  required String title,
  required String fileStem,
  required String htmlBody,
}) async {
  final dir = await getTemporaryDirectory();
  final safeStem = fileStem
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');
  final stamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
  final file = File(
    '${dir.path}/${safeStem.isEmpty ? 'report' : safeStem}_$stamp.xls',
  );
  await file.writeAsString(htmlBody, flush: true);
  await SharePlus.instance.share(
    ShareParams(
      files: [
        XFile(
          file.path,
          mimeType: 'application/vnd.ms-excel',
          name: file.uri.pathSegments.last,
        ),
      ],
      subject: title,
      text: title,
    ),
  );
}

Future<void> shareInvoicesCsv({
  required List<Invoice> invoices,
  required String title,
  String? subtitle,
}) async {
  final dateFmt = DateFormat('dd MMM yyyy, hh:mm a');
  final rows = <List<String>>[
    const ['SR', 'Date', 'Number', 'Type', 'Payment', 'Amount'],
  ];
  var total = 0.0;
  for (var i = 0; i < invoices.length; i++) {
    final inv = invoices[i];
    total += inv.totalAmount;
    rows.add([
      '${i + 1}',
      dateFmt.format(inv.invoiceDate),
      inv.invoiceNumber,
      _invoiceTypeLabel(inv.invoiceType),
      inv.paymentMode,
      inv.totalAmount.toStringAsFixed(2),
    ]);
  }
  rows.add(['', '', '', '', 'TOTAL', total.toStringAsFixed(2)]);
  await _shareXlsFile(
    title: title,
    fileStem: title,
    htmlBody: buildHtmlSpreadsheet(
      reportTitle: title,
      subtitle: subtitle,
      rows: rows,
    ),
  );
}

Future<void> shareProductSalesCsv({
  required List<ProductSalesRow> rows,
  required String title,
  String? subtitle,
}) async {
  final table = <List<String>>[
    const ['SR', 'Product', 'Qty', 'Amount'],
  ];
  var totalQty = 0;
  var totalAmt = 0.0;
  for (var i = 0; i < rows.length; i++) {
    final row = rows[i];
    totalQty += row.totalQuantity;
    totalAmt += row.totalAmount;
    table.add([
      '${i + 1}',
      row.productName,
      '${row.totalQuantity}',
      row.totalAmount.toStringAsFixed(2),
    ]);
  }
  table.add(['', 'TOTAL', '$totalQty', totalAmt.toStringAsFixed(2)]);
  await _shareXlsFile(
    title: title,
    fileStem: title,
    htmlBody: buildHtmlSpreadsheet(
      reportTitle: title,
      subtitle: subtitle,
      rows: table,
    ),
  );
}

Future<void> shareExpensesCsv({
  required List<ShopExpense> expenses,
  required String title,
  String? subtitle,
}) async {
  final dateFmt = DateFormat('dd MMM yyyy, hh:mm a');
  final rows = <List<String>>[
    const ['SR', 'Date', 'Expense', 'Amount'],
  ];
  var total = 0.0;
  for (var i = 0; i < expenses.length; i++) {
    final e = expenses[i];
    total += e.expensesAmount;
    rows.add([
      '${i + 1}',
      dateFmt.format(e.expensesDate),
      e.expensesName.isEmpty ? 'Expense' : e.expensesName,
      e.expensesAmount.toStringAsFixed(2),
    ]);
  }
  rows.add(['', '', 'TOTAL', total.toStringAsFixed(2)]);
  await _shareXlsFile(
    title: title,
    fileStem: title,
    htmlBody: buildHtmlSpreadsheet(
      reportTitle: title,
      subtitle: subtitle,
      rows: rows,
    ),
  );
}
