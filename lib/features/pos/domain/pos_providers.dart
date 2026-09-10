import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_billingwala_v2/core/database/app_database.dart';
import 'package:pos_billingwala_v2/core/database/database_provider.dart';
import 'package:pos_billingwala_v2/features/masters/domain/masters_providers.dart';
import 'package:pos_billingwala_v2/features/pos/domain/billing_session.dart';
import 'package:pos_billingwala_v2/features/print/domain/shop_receipt_profile.dart';

final posSelectedCategoryIdProvider =
    NotifierProvider<PosSelectedCategoryId, int?>(PosSelectedCategoryId.new);

class PosSelectedCategoryId extends Notifier<int?> {
  @override
  int? build() => null;

  void select(int? id) {
    state = id;
  }
}

final posSelectedSubcategoryIdProvider =
    NotifierProvider<PosSelectedSubcategoryId, int?>(
  PosSelectedSubcategoryId.new,
);

class PosSelectedSubcategoryId extends Notifier<int?> {
  @override
  int? build() {
    ref.listen(posSelectedCategoryIdProvider, (prev, next) {
      if (prev != next) {
        state = null;
      }
    });
    return null;
  }

  void select(int? id) => state = id;
}

final posSubcategoriesProvider =
    StreamProvider<List<ProductSubcategory>>((ref) {
  final categoryId = ref.watch(posSelectedCategoryIdProvider);
  return ref
      .watch(mastersRepositoryProvider)
      .watchSubcategories(categoryId: categoryId);
});

final posProductsProvider = StreamProvider<List<Product>>((ref) {
  final categoryId = ref.watch(posSelectedCategoryIdProvider);
  final subcategoryId = ref.watch(posSelectedSubcategoryIdProvider);
  return ref.watch(mastersRepositoryProvider).watchProducts(
        categoryId: categoryId,
        subcategoryId: subcategoryId,
      );
});

final posCombosProvider = StreamProvider<List<Combo>>((ref) {
  return ref.watch(appDatabaseProvider).watchActiveCombos();
});

final cartItemsProvider = StreamProvider<List<CartItem>>((ref) {
  final scope = ref.watch(billingSessionProvider).cartScope;
  return ref.watch(appDatabaseProvider).watchCartItems(cartScope: scope);
});

class CartSummary {
  const CartSummary({
    required this.itemKinds,
    required this.totalQuantity,
    required this.subtotal,
    required this.taxTotal,
    required this.grandTotal,
  });

  final int itemKinds;
  final int totalQuantity;
  final double subtotal;
  final double taxTotal;
  final double grandTotal;

  bool get isEmpty => itemKinds == 0;
}

final cartSummaryProvider = Provider<CartSummary>((ref) {
  final cart = ref.watch(cartItemsProvider).maybeWhen(
        data: (items) => items,
        orElse: () => const <CartItem>[],
      );
  var subtotal = 0.0;
  var taxTotal = 0.0;
  var qty = 0;

  for (final item in cart) {
    final lineBase = item.unitPrice * item.quantity;
    subtotal += lineBase;
    taxTotal += lineBase * item.gstPercent / 100;
    qty += item.quantity;
  }

  return CartSummary(
    itemKinds: cart.length,
    totalQuantity: qty,
    subtotal: subtotal,
    taxTotal: taxTotal,
    grandTotal: subtotal + taxTotal,
  );
});

class PosCartController extends Notifier<void> {
  @override
  void build() {}

  AppDatabase get _db => ref.read(appDatabaseProvider);
  BillingSession get _session => ref.read(billingSessionProvider);

  Future<void> addProduct(Product product, {ProductPortion? portion}) async {
    final shopGst = ref.read(shopReceiptProfileProvider).shopGstPercent;
    await _db.addProductToCart(
      product,
      cartScope: _session.cartScope,
      diningSessionId: _session.diningSessionId,
      portion: portion,
      shopGstPercentFallback: shopGst > 0 ? shopGst : null,
    );
  }

  Future<void> addCombo(Combo combo) async {
    await _db.addComboToCart(
      combo,
      cartScope: _session.cartScope,
      diningSessionId: _session.diningSessionId,
    );
  }

  Future<void> increment(CartItem item) async {
    await _db.changeCartQuantity(
      item.productId,
      item.quantity + 1,
      cartScope: _session.cartScope,
      portionId: item.portionId,
    );
  }

  Future<void> decrement(CartItem item) async {
    await _db.changeCartQuantity(
      item.productId,
      item.quantity - 1,
      cartScope: _session.cartScope,
      portionId: item.portionId,
    );
  }

  Future<void> remove(CartItem item) async {
    await _db.removeCartItem(
      item.productId,
      cartScope: _session.cartScope,
      portionId: item.portionId,
    );
  }

  Future<void> clear() async {
    await _db.clearCart(cartScope: _session.cartScope);
  }
}

final posCartControllerProvider = NotifierProvider<PosCartController, void>(
  PosCartController.new,
);
