import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_billingwala_v2/core/database/app_database.dart';
import 'package:pos_billingwala_v2/core/database/database_provider.dart';
import 'package:pos_billingwala_v2/features/pos/domain/billing_session.dart';
import 'package:pos_billingwala_v2/features/pos/domain/pos_providers.dart';

final unprintedCartCountProvider = Provider<int>((ref) {
  final cart = ref.watch(cartItemsProvider).maybeWhen(
        data: (items) => items,
        orElse: () => const <CartItem>[],
      );
  var count = 0;
  for (final item in cart) {
    final delta = item.quantity - item.printedQuantity;
    if (delta > 0) count += delta;
  }
  return count;
});

class KotController extends Notifier<AsyncValue<KotTicket?>> {
  @override
  AsyncValue<KotTicket?> build() => const AsyncData(null);

  Future<KotTicket> createKot() async {
    final session = ref.read(billingSessionProvider);
    final diningSessionId = session.diningSessionId;
    final tableNumber = session.tableNumber;
    if (diningSessionId == null || tableNumber == null) {
      throw StateError('KOT is only available for dine-in tables');
    }

    state = const AsyncLoading();
    try {
      final ticket = await ref.read(appDatabaseProvider).createKotFromUnprintedCart(
            sessionId: diningSessionId,
            tableNumber: tableNumber,
            cartScope: session.cartScope,
          );
      state = AsyncData(ticket);
      return ticket;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> markPrinted(int kotId) async {
    await ref.read(appDatabaseProvider).markKotPrinted(kotId);
  }
}

final kotControllerProvider =
    NotifierProvider<KotController, AsyncValue<KotTicket?>>(
  KotController.new,
);
