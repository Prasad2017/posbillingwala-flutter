import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_billingwala_v2/core/database/app_database.dart';
import 'package:pos_billingwala_v2/core/database/database_provider.dart';
import 'package:pos_billingwala_v2/features/auth/domain/auth_controller.dart';
import 'package:pos_billingwala_v2/features/masters/data/masters_api.dart';
import 'package:pos_billingwala_v2/features/masters/data/masters_repository.dart';

final mastersRepositoryProvider = Provider<MastersRepository>((ref) {
  return MastersRepository(
    api: MastersApi(ref.watch(apiClientProvider)),
    db: ref.watch(appDatabaseProvider),
  );
});

final categoriesProvider = StreamProvider<List<ProductCategory>>((ref) {
  return ref.watch(mastersRepositoryProvider).watchCategories();
});

final subcategoriesProvider = StreamProvider<List<ProductSubcategory>>((ref) {
  return ref.watch(mastersRepositoryProvider).watchSubcategories();
});

final foodTypesProvider = StreamProvider<List<FoodType>>((ref) {
  return ref.watch(mastersRepositoryProvider).watchFoodTypes();
});

final diningAreasProvider = StreamProvider<List<DiningArea>>((ref) {
  return ref.watch(mastersRepositoryProvider).watchDiningAreas();
});

final tableTypesProvider = StreamProvider<List<TableType>>((ref) {
  return ref.watch(mastersRepositoryProvider).watchTableTypes();
});

final portionMastersProvider = StreamProvider<List<PortionMaster>>((ref) {
  return ref.watch(mastersRepositoryProvider).watchPortionMasters();
});

final selectedCategoryIdProvider =
    NotifierProvider<SelectedCategoryId, int?>(SelectedCategoryId.new);

class SelectedCategoryId extends Notifier<int?> {
  @override
  int? build() => null;

  void select(int? id) => state = id;
}

final productsProvider = StreamProvider<List<Product>>((ref) {
  final categoryId = ref.watch(selectedCategoryIdProvider);
  return ref
      .watch(mastersRepositoryProvider)
      .watchProducts(categoryId: categoryId);
});

final catalogCountsProvider =
    FutureProvider<({int categories, int products, int combos})>((ref) async {
  ref.watch(categoriesProvider);
  ref.watch(productsProvider);
  return ref.watch(mastersRepositoryProvider).localCounts();
});

final combosListProvider = StreamProvider<List<Combo>>((ref) {
  return ref.watch(appDatabaseProvider).watchActiveCombos();
});

class MastersSyncController extends Notifier<AsyncValue<MastersSyncResult?>> {
  @override
  AsyncValue<MastersSyncResult?> build() => const AsyncData(null);

  Future<void> syncNow() async {
    final userId = ref.read(authControllerProvider).session?.userId;
    if (userId == null || userId.isEmpty) {
      state = AsyncError(
        'Please login before syncing masters',
        StackTrace.current,
      );
      return;
    }

    state = const AsyncLoading();
    state = await AsyncValue.guard(() {
      return ref.read(mastersRepositoryProvider).syncFromCloud(userId);
    });
  }

  Future<int> uploadPending() async {
    final userId = ref.read(authControllerProvider).session?.userId;
    if (userId == null || userId.isEmpty) {
      state = AsyncError(
        'Please login before uploading masters',
        StackTrace.current,
      );
      return 0;
    }
    state = const AsyncLoading();
    try {
      final count =
          await ref.read(mastersRepositoryProvider).uploadPendingMasters(userId);
      state = AsyncData(
        MastersSyncResult(
          foodTypeCount: 0,
          categoryCount: 0,
          productCount: 0,
          portionCount: 0,
          uploadedPending: count,
        ),
      );
      return count;
    } catch (e, st) {
      state = AsyncError(e, st);
      return 0;
    }
  }

  Future<void> createCategory(
    String name, {
    int? foodTypeId,
    String? foodTypeCode,
  }) async {
    final userId = ref.read(authControllerProvider).session?.userId ?? '';
    await ref.read(mastersRepositoryProvider).createCategory(
          userId: userId,
          categoryName: name,
          foodTypeId: foodTypeId,
          foodTypeCode: foodTypeCode,
        );
  }

  Future<void> createProduct({
    required String name,
    required double price,
    int? categoryId,
    String? categoryName,
  }) async {
    final userId = ref.read(authControllerProvider).session?.userId ?? '';
    await ref.read(mastersRepositoryProvider).createProduct(
          userId: userId,
          productName: name,
          productPrice: price,
          categoryId: categoryId,
          categoryName: categoryName,
        );
  }

  Future<void> updateCategory({
    required int categoryId,
    required String name,
  }) {
    return ref.read(mastersRepositoryProvider).updateCategory(
          categoryId: categoryId,
          categoryName: name,
        );
  }

  Future<void> deleteCategory(int categoryId) {
    return ref.read(mastersRepositoryProvider).deleteCategory(categoryId);
  }

  Future<void> updateProduct({
    required int productId,
    required String name,
    required double price,
    int? categoryId,
    String? categoryName,
  }) {
    return ref.read(mastersRepositoryProvider).updateProduct(
          productId: productId,
          productName: name,
          productPrice: price,
          categoryId: categoryId,
          categoryName: categoryName,
        );
  }

  Future<void> deleteProduct(int productId) {
    return ref.read(mastersRepositoryProvider).deleteProduct(productId);
  }

  Future<void> createCombo({
    required String name,
    required double price,
    List<({int productId, int quantity})> items = const [],
  }) {
    return ref.read(mastersRepositoryProvider).createCombo(
          comboName: name,
          comboPrice: price,
          items: items,
        );
  }

  Future<void> updateCombo({
    required int comboId,
    required String name,
    required double price,
    List<({int productId, int quantity})> items = const [],
  }) {
    return ref.read(mastersRepositoryProvider).updateCombo(
          comboId: comboId,
          comboName: name,
          comboPrice: price,
          items: items,
        );
  }

  Future<void> deleteCombo(int comboId) {
    return ref.read(mastersRepositoryProvider).deleteCombo(comboId);
  }
}

final mastersSyncControllerProvider =
    NotifierProvider<MastersSyncController, AsyncValue<MastersSyncResult?>>(
  MastersSyncController.new,
);
