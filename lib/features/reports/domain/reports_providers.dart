import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_billingwala_v2/core/database/app_database.dart';
import 'package:pos_billingwala_v2/core/database/database_provider.dart';

enum ReportPeriodKind { today, month, day }

class ReportPeriod {
  const ReportPeriod.today()
      : kind = ReportPeriodKind.today,
        day = null;

  const ReportPeriod.month([DateTime? monthAnchor])
      : kind = ReportPeriodKind.month,
        day = monthAnchor;

  const ReportPeriod.day(this.day) : kind = ReportPeriodKind.day;

  final ReportPeriodKind kind;
  /// For [ReportPeriodKind.day]: the day.
  /// For [ReportPeriodKind.month]: any day in the selected month (null = current).
  final DateTime? day;

  (DateTime start, DateTime end) get range {
    final now = DateTime.now();
    switch (kind) {
      case ReportPeriodKind.today:
        final start = DateTime(now.year, now.month, now.day);
        return (start, start.add(const Duration(days: 1)));
      case ReportPeriodKind.month:
        final anchor = day ?? now;
        final start = DateTime(anchor.year, anchor.month, 1);
        final end = (anchor.month == 12)
            ? DateTime(anchor.year + 1, 1, 1)
            : DateTime(anchor.year, anchor.month + 1, 1);
        return (start, end);
      case ReportPeriodKind.day:
        final d = day ?? now;
        final start = DateTime(d.year, d.month, d.day);
        return (start, start.add(const Duration(days: 1)));
    }
  }

  String get label {
    switch (kind) {
      case ReportPeriodKind.today:
        return 'Today';
      case ReportPeriodKind.month:
        final anchor = day ?? DateTime.now();
        final now = DateTime.now();
        if (anchor.year == now.year && anchor.month == now.month) {
          return 'This month';
        }
        const months = [
          'Jan',
          'Feb',
          'Mar',
          'Apr',
          'May',
          'Jun',
          'Jul',
          'Aug',
          'Sep',
          'Oct',
          'Nov',
          'Dec',
        ];
        return '${months[anchor.month - 1]} ${anchor.year}';
      case ReportPeriodKind.day:
        final d = day ?? DateTime.now();
        return '${d.day.toString().padLeft(2, '0')}-'
            '${d.month.toString().padLeft(2, '0')}-${d.year}';
    }
  }
}

class SalesSummary {
  const SalesSummary({
    required this.billCount,
    required this.totalSales,
    required this.subTotal,
    required this.gstTotal,
    required this.discountTotal,
    required this.cashTotal,
    required this.upiTotal,
    required this.posCount,
    required this.takeawayCount,
    required this.tableCount,
    required this.avgBill,
  });

  final int billCount;
  final double totalSales;
  final double subTotal;
  final double gstTotal;
  final double discountTotal;
  final double cashTotal;
  final double upiTotal;
  final int posCount;
  final int takeawayCount;
  final int tableCount;
  final double avgBill;

  static const empty = SalesSummary(
    billCount: 0,
    totalSales: 0,
    subTotal: 0,
    gstTotal: 0,
    discountTotal: 0,
    cashTotal: 0,
    upiTotal: 0,
    posCount: 0,
    takeawayCount: 0,
    tableCount: 0,
    avgBill: 0,
  );

  factory SalesSummary.fromInvoices(List<Invoice> invoices) {
    if (invoices.isEmpty) return SalesSummary.empty;

    var total = 0.0;
    var sub = 0.0;
    var gst = 0.0;
    var discount = 0.0;
    var cash = 0.0;
    var upi = 0.0;
    var posCount = 0;
    var takeawayCount = 0;
    var tableCount = 0;

    for (final invoice in invoices) {
      total += invoice.totalAmount;
      sub += invoice.subTotal;
      gst += invoice.totalGstAmount;
      discount += invoice.discount;
      cash += invoice.cashAmount;
      upi += invoice.upiAmount;
      switch (invoice.invoiceType) {
        case 'take_away':
          takeawayCount++;
        case 'table_wise':
          tableCount++;
        default:
          posCount++;
      }
    }

    final count = invoices.length;
    return SalesSummary(
      billCount: count,
      totalSales: _r(total),
      subTotal: _r(sub),
      gstTotal: _r(gst),
      discountTotal: _r(discount),
      cashTotal: _r(cash),
      upiTotal: _r(upi),
      posCount: posCount,
      takeawayCount: takeawayCount,
      tableCount: tableCount,
      avgBill: _r(total / count),
    );
  }

  static double _r(double v) => double.parse(v.toStringAsFixed(2));
}

class ReportPeriodController extends Notifier<ReportPeriod> {
  @override
  ReportPeriod build() => const ReportPeriod.today();

  void useToday() => state = const ReportPeriod.today();
  void useMonth([DateTime? monthAnchor]) =>
      state = ReportPeriod.month(monthAnchor);
  void useDay(DateTime day) => state = ReportPeriod.day(day);
}

final reportPeriodProvider =
    NotifierProvider<ReportPeriodController, ReportPeriod>(
  ReportPeriodController.new,
);

final periodInvoicesProvider = StreamProvider<List<Invoice>>((ref) {
  final period = ref.watch(reportPeriodProvider);
  final (start, end) = period.range;
  return ref.watch(appDatabaseProvider).watchInvoicesInRange(start, end);
});

enum ReportPaymentFilter { all, cash, upi, cashPlusUpi }

class ReportPaymentFilterController extends Notifier<ReportPaymentFilter> {
  @override
  ReportPaymentFilter build() => ReportPaymentFilter.all;

  void select(ReportPaymentFilter filter) => state = filter;
}

final reportPaymentFilterProvider =
    NotifierProvider<ReportPaymentFilterController, ReportPaymentFilter>(
  ReportPaymentFilterController.new,
);

enum ReportInvoiceTypeFilter {
  all,
  pos,
  table,
  takeaway,
  mess,
  discountOnly,
  refundOnly,
}

class ReportInvoiceTypeFilterController
    extends Notifier<ReportInvoiceTypeFilter> {
  @override
  ReportInvoiceTypeFilter build() => ReportInvoiceTypeFilter.all;

  void select(ReportInvoiceTypeFilter filter) => state = filter;
}

final reportInvoiceTypeFilterProvider = NotifierProvider<
    ReportInvoiceTypeFilterController, ReportInvoiceTypeFilter>(
  ReportInvoiceTypeFilterController.new,
);

bool matchesInvoiceTypeFilter(Invoice invoice, ReportInvoiceTypeFilter filter) {
  final type = invoice.invoiceType.trim().toLowerCase();
  switch (filter) {
    case ReportInvoiceTypeFilter.all:
      return true;
    case ReportInvoiceTypeFilter.pos:
      return type == 'fast_billing' ||
          type == 'pos' ||
          (type != 'take_away' &&
              type != 'table_wise' &&
              !type.contains('mess'));
    case ReportInvoiceTypeFilter.table:
      return type == 'table_wise';
    case ReportInvoiceTypeFilter.takeaway:
      return type == 'take_away';
    case ReportInvoiceTypeFilter.mess:
      return type == 'mess' || type.contains('mess');
    case ReportInvoiceTypeFilter.discountOnly:
      return invoice.discount > 0;
    case ReportInvoiceTypeFilter.refundOnly:
      return invoice.invoiceOrderStatus.toLowerCase() == 'refunded';
  }
}

bool matchesPaymentFilter(Invoice invoice, ReportPaymentFilter filter) {
  switch (filter) {
    case ReportPaymentFilter.all:
      return true;
    case ReportPaymentFilter.cash:
      return invoice.paymentMode == 'Cash';
    case ReportPaymentFilter.upi:
      return invoice.paymentMode == 'UPI' || invoice.paymentMode == 'Online';
    case ReportPaymentFilter.cashPlusUpi:
      return invoice.paymentMode == 'Cash+UPI';
  }
}

final filteredPeriodInvoicesProvider = Provider<List<Invoice>>((ref) {
  final invoices = ref.watch(periodInvoicesProvider).maybeWhen(
        data: (rows) => rows,
        orElse: () => const <Invoice>[],
      );
  final paymentFilter = ref.watch(reportPaymentFilterProvider);
  final typeFilter = ref.watch(reportInvoiceTypeFilterProvider);
  return invoices
      .where(
        (e) =>
            matchesPaymentFilter(e, paymentFilter) &&
            matchesInvoiceTypeFilter(e, typeFilter),
      )
      .toList();
});

final periodSalesSummaryProvider = Provider<SalesSummary>((ref) {
  final invoices = ref.watch(filteredPeriodInvoicesProvider);
  return SalesSummary.fromInvoices(invoices);
});

/// Back-compat aliases used by older call sites.
typedef TodaySalesSummary = SalesSummary;

final todayInvoicesProvider = StreamProvider<List<Invoice>>((ref) {
  return ref.watch(appDatabaseProvider).watchTodayInvoices();
});

final todaySalesSummaryProvider = Provider<SalesSummary>((ref) {
  final invoices = ref.watch(todayInvoicesProvider).maybeWhen(
        data: (rows) => rows,
        orElse: () => const <Invoice>[],
      );
  return SalesSummary.fromInvoices(invoices);
});

final monthInvoicesProvider = StreamProvider<List<Invoice>>((ref) {
  final now = DateTime.now();
  final start = DateTime(now.year, now.month, 1);
  final end = (now.month == 12)
      ? DateTime(now.year + 1, 1, 1)
      : DateTime(now.year, now.month + 1, 1);
  return ref.watch(appDatabaseProvider).watchInvoicesInRange(start, end);
});

final monthSalesSummaryProvider = Provider<SalesSummary>((ref) {
  final invoices = ref.watch(monthInvoicesProvider).maybeWhen(
        data: (rows) => rows,
        orElse: () => const <Invoice>[],
      );
  return SalesSummary.fromInvoices(invoices);
});

final invoiceDetailProvider =
    FutureProvider.family<({Invoice invoice, List<InvoiceItem> items})?, int>(
  (ref, invoiceId) async {
    final db = ref.watch(appDatabaseProvider);
    final invoice = await db.getInvoiceById(invoiceId);
    if (invoice == null) return null;
    final items = await db.getInvoiceItems(invoice.invoiceNumber);
    return (invoice: invoice, items: items);
  },
);
