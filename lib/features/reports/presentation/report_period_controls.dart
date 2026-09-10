import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pos_billingwala_v2/features/reports/domain/reports_providers.dart';

Future<void> pickReportMonth(BuildContext context, WidgetRef ref) async {
  final period = ref.read(reportPeriodProvider);
  final now = DateTime.now();
  final initial = period.kind == ReportPeriodKind.month && period.day != null
      ? period.day!
      : now;
  final picked = await showDatePicker(
    context: context,
    initialDate: DateTime(initial.year, initial.month, 1),
    firstDate: DateTime(now.year - 3, 1, 1),
    lastDate: DateTime(now.year, now.month, 1),
    helpText: 'Pick any day in the month',
  );
  if (picked != null) {
    ref.read(reportPeriodProvider.notifier).useMonth(picked);
  }
}

void onReportPeriodSelected(
  WidgetRef ref,
  ReportPeriodKind kind,
  ReportPeriod current,
) {
  switch (kind) {
    case ReportPeriodKind.today:
      ref.read(reportPeriodProvider.notifier).useToday();
    case ReportPeriodKind.month:
      ref.read(reportPeriodProvider.notifier).useMonth(current.day);
    case ReportPeriodKind.day:
      final day = current.kind == ReportPeriodKind.day
          ? (current.day ?? DateTime.now())
          : DateTime.now();
      ref.read(reportPeriodProvider.notifier).useDay(day);
  }
}
