import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Local business hours stored as minutes-from-midnight ints
/// (`businessOpenMinutes` / `businessCloseMinutes`), matching
/// [BusinessHoursPage] SharedPreferences writes.
class BusinessHours {
  static const openKey = 'businessOpenMinutes';
  static const closeKey = 'businessCloseMinutes';

  /// Minutes from midnight, or null if unset (treat as always open).
  static Future<({int? open, int? close})> load() async {
    final prefs = await SharedPreferences.getInstance();
    return (
      open: prefs.getInt(openKey),
      close: prefs.getInt(closeKey),
    );
  }

  /// When either bound is null, the shop is treated as always open.
  /// Overnight ranges (close ≤ open) wrap past midnight.
  static bool isOpenNow({
    required int? openMinutes,
    required int? closeMinutes,
    DateTime? now,
  }) {
    if (openMinutes == null || closeMinutes == null) return true;

    final n = now ?? DateTime.now();
    final current = n.hour * 60 + n.minute;

    if (closeMinutes <= openMinutes) {
      return current >= openMinutes || current < closeMinutes;
    }
    return current >= openMinutes && current < closeMinutes;
  }
}

final shopOpenNowProvider = FutureProvider<bool>((ref) async {
  final hours = await BusinessHours.load();
  return BusinessHours.isOpenNow(
    openMinutes: hours.open,
    closeMinutes: hours.close,
  );
});
