import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_billingwala_v2/core/database/database_provider.dart';
import 'package:pos_billingwala_v2/features/auth/domain/auth_controller.dart';
import 'package:pos_billingwala_v2/features/print/domain/print_service.dart';
import 'package:pos_billingwala_v2/features/print/domain/printer_settings.dart';
import 'package:pos_billingwala_v2/features/print/domain/shop_receipt_profile.dart';

final printServiceProvider = Provider<PrintService>((ref) {
  return PrintService(
    ref.watch(printerSettingsProvider),
    shopProfile: ref.watch(shopReceiptProfileProvider),
  );
});

Future<PrintResult> printInvoiceById(
  WidgetRef ref,
  int invoiceId, {
  bool preferShare = false,
  bool duplicate = false,
  bool alsoDuplicate = false,
}) async {
  final db = ref.read(appDatabaseProvider);
  final invoice = await db.getInvoiceById(invoiceId);
  if (invoice == null) {
    return const PrintResult(
      outcome: PrintOutcome.failed,
      text: '',
      message: 'Invoice not found',
    );
  }
  final items = await db.getInvoiceItems(invoice.invoiceNumber);
  final shopName = ref.read(authControllerProvider).session?.shopName;
  final service = ref.read(printServiceProvider);
  final profile = ref.read(shopReceiptProfileProvider);
  final result = await service.printBill(
    invoice: invoice,
    items: items,
    shopName: profile.companyName.isNotEmpty ? profile.companyName : shopName,
    preferShare: preferShare,
    duplicate: duplicate,
  );
  final settings = ref.read(printerSettingsProvider);
  if (alsoDuplicate || (!duplicate && settings.duplicateBillUse)) {
    await service.printBill(
      invoice: invoice,
      items: items,
      shopName: profile.companyName.isNotEmpty ? profile.companyName : shopName,
      preferShare: preferShare,
      duplicate: true,
    );
  }
  return result;
}
