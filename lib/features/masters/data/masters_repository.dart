import 'package:drift/drift.dart';
import 'package:pos_billingwala_v2/core/database/app_database.dart';
import 'package:pos_billingwala_v2/features/masters/data/masters_api.dart';
import 'package:pos_billingwala_v2/shared/models/catalog_dtos.dart';
import 'package:pos_billingwala_v2/shared/models/combo_dtos.dart';

class MastersSyncResult {
  const MastersSyncResult({
    required this.foodTypeCount,
    required this.categoryCount,
    required this.productCount,
    required this.portionCount,
    this.tableCount = 0,
    this.comboCount = 0,
    this.subcategoryCount = 0,
    this.diningAreaCount = 0,
    this.tableTypeCount = 0,
    this.portionMasterCount = 0,
    this.uploadedPending = 0,
  });

  final int foodTypeCount;
  final int categoryCount;
  final int productCount;
  final int portionCount;
  final int tableCount;
  final int comboCount;
  final int subcategoryCount;
  final int diningAreaCount;
  final int tableTypeCount;
  final int portionMasterCount;
  final int uploadedPending;
}

class MastersRepository {
  MastersRepository({
    required this.api,
    required this.db,
  });

  final MastersApi api;
  final AppDatabase db;

  Stream<List<ProductCategory>> watchCategories() =>
      db.watchActiveCategories();

  Stream<List<Product>> watchProducts({
    int? categoryId,
    int? subcategoryId,
  }) =>
      db.watchActiveProducts(
        categoryId: categoryId,
        subcategoryId: subcategoryId,
      );

  Stream<List<ProductSubcategory>> watchSubcategories({int? categoryId}) =>
      db.watchActiveSubcategories(categoryId: categoryId);

  Stream<List<DiningArea>> watchDiningAreas() => db.watchActiveDiningAreas();

  Stream<List<TableType>> watchTableTypes() => db.watchActiveTableTypes();

  Stream<List<PortionMaster>> watchPortionMasters() =>
      db.watchActivePortionMasters();

  Stream<List<FoodType>> watchFoodTypes() => db.watchActiveFoodTypes();

  Future<({int categories, int products, int combos})> localCounts() async {
    return (
      categories: await db.countActiveCategories(),
      products: await db.countActiveProducts(),
      combos: await db.countActiveCombos(),
    );
  }

  Future<MastersSyncResult> syncFromCloud(String userId) async {
    if (userId.trim().isEmpty) {
      throw Exception('Missing userId for catalog sync');
    }

    final uploaded = await uploadPendingMasters(userId);

    final foodTypes = await api.fetchFoodTypes();
    final categories = await api.fetchCategories(userId);
    List<SubcategoryDto> subcategories = const [];
    try {
      subcategories = await api.fetchSubcategories(userId);
    } catch (_) {}
    final products = await api.fetchProducts(userId);
    final portions = await api.fetchPortions(userId);
    List<ComboDto> combos = const [];
    List<ComboItemDto> comboItems = const [];
    try {
      combos = await api.fetchCombos(userId);
      comboItems = await api.fetchComboItems(userId);
    } catch (_) {
      // Combo endpoints may be unavailable on older servers.
    }
    List<PosTableDto> tables = const [];
    try {
      tables = await api.fetchPosTables(userId);
    } catch (_) {
      // Tables endpoint may be unavailable; floor can seed locally.
    }
    List<DiningAreaDto> diningAreas = const [];
    List<TableTypeDto> tableTypes = const [];
    List<PortionMasterDto> portionMasters = const [];
    try {
      diningAreas = await api.fetchDiningAreas(userId);
    } catch (_) {}
    try {
      tableTypes = await api.fetchTableTypes(userId);
    } catch (_) {}
    try {
      portionMasters = await api.fetchPortionMasters(userId);
    } catch (_) {}

    await db.replaceFoodTypes(
      foodTypes
          .where((e) => e.foodTypeId > 0)
          .map(
            (e) => FoodTypesCompanion.insert(
              foodTypeId: Value(e.foodTypeId),
              foodTypeName: Value(e.foodTypeName),
              foodTypeCode: Value(e.foodTypeCode),
              foodTypeSortOrder: Value(e.foodTypeSortOrder),
              foodTypeStatus: Value(e.foodTypeStatus),
            ),
          )
          .toList(),
    );

    await db.replaceCategories(
      categories
          .where((e) => e.categoryId > 0)
          .map(
            (e) => ProductCategoriesCompanion.insert(
              categoryId: Value(e.categoryId),
              categoryName: Value(e.categoryName),
              foodTypeId: Value(e.foodTypeId),
              foodTypeCode: Value(e.foodTypeCode),
              categorySortOrder: Value(e.categorySortOrder),
              categoryDeletedStatus: Value(e.categoryDeletedStatus),
              categoryNetworkStatus: Value(e.categoryNetworkStatus),
              categoryStatus: Value(e.categoryStatus),
              categorySyncStatus: const Value('1'),
            ),
          )
          .toList(),
    );

    await db.replaceSubcategories(
      subcategories
          .where((e) => e.subcategoryId > 0)
          .map(
            (e) => ProductSubcategoriesCompanion.insert(
              subcategoryId: Value(e.subcategoryId),
              categoryId: Value(e.categoryId),
              subcategoryName: Value(e.subcategoryName),
              categoryNetworkStatus: Value(e.categoryNetworkStatus),
              subcategoryNetworkStatus: Value(e.subcategoryNetworkStatus),
              subcategorySortOrder: Value(e.subcategorySortOrder),
              subcategoryDeletedStatus: Value(e.subcategoryDeletedStatus),
              subcategorySyncStatus: const Value('1'),
            ),
          )
          .toList(),
    );

    await db.replaceProducts(
      products
          .where((e) => e.productId > 0)
          .map(
            (e) => ProductsCompanion.insert(
              productId: Value(e.productId),
              categoryId: Value(e.categoryId),
              categoryName: Value(e.categoryName),
              subcategoryId: Value(e.subcategoryId),
              productCode: Value(e.productCode),
              productName: Value(e.productName),
              productPrice: Value(e.productPrice),
              openPrice: Value(e.openPrice),
              productUnit: Value(e.productUnit),
              productCgst: Value(e.productCgst),
              productSgst: Value(e.productSgst),
              productWithGstPrice: Value(e.productWithGstPrice),
              productDeletedStatus: Value(e.productDeletedStatus),
              productNetworkStatus: Value(e.productNetworkStatus),
              productStatus: Value(e.productStatus),
              productSyncStatus: const Value('1'),
            ),
          )
          .toList(),
    );

    await db.replacePortions(
      portions
          .where((e) => e.portionId > 0 && e.productId > 0)
          .map(
            (e) => ProductPortionsCompanion.insert(
              portionId: Value(e.portionId),
              productId: e.productId,
              portionMasterId: Value(e.portionMasterId),
              portionName: Value(e.portionName),
              portionPrice: Value(e.portionPrice),
              portionSortOrder: Value(e.portionSortOrder),
              portionDeletedStatus: Value(e.portionDeletedStatus),
              portionNetworkStatus: Value(e.portionNetworkStatus),
              portionStatus: Value(e.portionStatus),
              portionSyncStatus: const Value('1'),
            ),
          )
          .toList(),
    );

    if (combos.isNotEmpty) {
      await db.replaceCombos(
        combos
            .where((e) => e.comboId > 0)
            .map(
              (e) => CombosCompanion.insert(
                comboId: Value(e.comboId),
                comboName: Value(e.comboName),
                comboCode: Value(e.comboCode),
                comboPrice: Value(e.comboPrice),
                comboCgst: Value(e.comboCgst),
                comboSgst: Value(e.comboSgst),
                comboWithGstPrice: Value(e.resolvedWithGstPrice),
                comboActiveStatus: Value(e.comboActiveStatus),
                comboDeletedStatus: Value(e.comboDeletedStatus),
                comboNetworkStatus: Value(e.comboNetworkStatus),
                comboSortOrder: Value(e.comboSortOrder),
                comboSyncStatus: const Value('1'),
              ),
            )
            .toList(),
      );
      await db.replaceComboItems(
        comboItems
            .where((e) => e.comboItemId > 0 && e.comboId > 0)
            .map(
              (e) => ComboItemsCompanion.insert(
                comboItemId: Value(e.comboItemId),
                comboId: e.comboId,
                productId: Value(e.productId),
                portionId: Value(e.portionId),
                comboItemQuantity: Value(e.comboItemQuantity),
                comboItemSortOrder: Value(e.comboItemSortOrder),
                comboItemDeletedStatus: Value(e.comboItemDeletedStatus),
                comboItemNetworkStatus: Value(e.comboItemNetworkStatus),
                comboNetworkStatus: Value(e.comboNetworkStatus),
                productNetworkStatus: Value(e.productNetworkStatus),
                portionNetworkStatus: Value(e.portionNetworkStatus),
                comboItemSyncStatus: const Value('1'),
              ),
            )
            .toList(),
      );
    }

    if (tables.isNotEmpty) {
      await db.replacePosTables(
        tables
            .where((e) => e.tableId > 0 && e.tableNumber.trim().isNotEmpty)
            .map(
              (e) => PosTablesCompanion.insert(
                tableId: Value(e.tableId),
                tableNumber: e.tableNumber,
                displayName: Value(
                  e.tableName.isEmpty ? 'Table ${e.tableNumber}' : e.tableName,
                ),
                capacity: Value(e.capacity),
                areaId: Value(e.areaId),
                tableActive: Value(e.tableActive),
                sortOrder: Value(e.sortOrder),
                statusOverride: Value(e.statusOverride),
                posTableNetworkStatus: Value(e.posTableNetworkStatus),
              ),
            )
            .toList(),
      );
    } else {
      await db.seedDefaultTablesIfEmpty();
    }

    if (diningAreas.isNotEmpty) {
      await db.replaceDiningAreas(
        diningAreas
            .where((e) => e.areaId > 0)
            .map(
              (e) => DiningAreasCompanion.insert(
                areaId: Value(e.areaId),
                areaName: Value(e.areaName),
                areaSortOrder: Value(e.areaSortOrder),
                areaActive: Value(e.areaActive),
                areaNetworkStatus: Value(e.areaNetworkStatus),
                areaSyncStatus: const Value('1'),
              ),
            )
            .toList(),
      );
    }

    if (tableTypes.isNotEmpty) {
      await db.replaceTableTypes(
        tableTypes
            .where((e) => e.tableTypeId > 0)
            .map(
              (e) => TableTypesCompanion.insert(
                tableTypeId: Value(e.tableTypeId),
                tableTypeName: Value(e.tableTypeName),
                tableTypeSortOrder: Value(e.tableTypeSortOrder),
                tableTypeActive: Value(e.tableTypeActive),
                tableTypeNetworkStatus: Value(e.tableTypeNetworkStatus),
                tableTypeSyncStatus: const Value('1'),
              ),
            )
            .toList(),
      );
    }

    if (portionMasters.isNotEmpty) {
      await db.replacePortionMasters(
        portionMasters
            .where((e) => e.portionMasterId > 0)
            .map(
              (e) => PortionMastersCompanion.insert(
                portionMasterId: Value(e.portionMasterId),
                portionName: Value(e.portionName),
                portionMasterDeletedStatus: Value(e.portionMasterDeletedStatus),
                portionMasterNetworkStatus: Value(e.portionMasterNetworkStatus),
                portionMasterSyncStatus: const Value('1'),
              ),
            )
            .toList(),
      );
    }

    return MastersSyncResult(
      foodTypeCount: foodTypes.length,
      categoryCount: categories.length,
      productCount: products.length,
      portionCount: portions.length,
      tableCount:
          tables.isNotEmpty ? tables.length : await db.countActivePosTables(),
      comboCount: combos.length,
      subcategoryCount: subcategories.length,
      diningAreaCount: diningAreas.length,
      tableTypeCount: tableTypes.length,
      portionMasterCount: portionMasters.length,
      uploadedPending: uploaded,
    );
  }

  /// Uploads locally-created categories / products / portions / combos.
  Future<int> uploadPendingMasters(String userId) async {
    if (userId.trim().isEmpty) return 0;
    var uploaded = 0;

    for (final category in await db.getPendingCategories()) {
      final network = category.categoryNetworkStatus?.trim().isNotEmpty == true
          ? category.categoryNetworkStatus!
          : 'cat_${category.categoryId}';
      final ok = await api.insertCategory(
        userId: userId,
        categoryName: category.categoryName,
        categoryNetworkStatus: network,
        categoryDeletedStatus: category.categoryDeletedStatus,
        foodTypeCode: category.foodTypeCode ?? '',
        categorySortOrder: '${category.categorySortOrder}',
      );
      if (ok) {
        await db.markCategorySynced(category.categoryId);
        uploaded++;
      }
    }

    for (final sub in await db.getPendingSubcategories()) {
      final network = sub.subcategoryNetworkStatus?.trim().isNotEmpty == true
          ? sub.subcategoryNetworkStatus!
          : 'sub_${sub.subcategoryId}';
      final ok = await api.insertSubcategory(
        userId: userId,
        categoryId: '${sub.categoryId ?? 0}',
        categoryNetworkStatus: sub.categoryNetworkStatus ?? '',
        subcategoryName: sub.subcategoryName,
        subcategoryNetworkStatus: network,
        subcategoryDeletedStatus: sub.subcategoryDeletedStatus,
        subcategorySortOrder: '${sub.subcategorySortOrder}',
      );
      if (ok) {
        await db.markSubcategorySynced(sub.subcategoryId);
        uploaded++;
      }
    }

    for (final product in await db.getPendingProducts()) {
      final network = product.productNetworkStatus?.trim().isNotEmpty == true
          ? product.productNetworkStatus!
          : 'prd_${product.productId}';
      final ok = await api.insertProduct(
        userId: userId,
        categoryId: '${product.categoryId ?? 0}',
        categoryName: product.categoryName ?? '',
        productCode: product.productCode ?? '',
        productName: product.productName,
        productPrice: product.productPrice.toStringAsFixed(2),
        productUnit: product.productUnit ?? '',
        productCgst: product.productCgst.toStringAsFixed(2),
        productSgst: product.productSgst.toStringAsFixed(2),
        productNetworkStatus: network,
        productDeletedStatus: product.productDeletedStatus,
        subcategoryId: '${product.subcategoryId ?? 0}',
        openPrice: product.openPrice,
      );
      if (ok) {
        await db.markProductSynced(product.productId);
        uploaded++;
      }
    }

    for (final area in await db.getPendingDiningAreas()) {
      final network = area.areaNetworkStatus?.trim().isNotEmpty == true
          ? area.areaNetworkStatus!
          : 'area_${area.areaId}';
      final ok = await api.insertDiningArea(
        userId: userId,
        areaName: area.areaName,
        areaSortOrder: '${area.areaSortOrder}',
        areaActive: area.areaActive,
        areaNetworkStatus: network,
      );
      if (ok) {
        await db.markDiningAreaSynced(area.areaId);
        uploaded++;
      }
    }

    for (final type in await db.getPendingTableTypes()) {
      final network = type.tableTypeNetworkStatus?.trim().isNotEmpty == true
          ? type.tableTypeNetworkStatus!
          : 'tt_${type.tableTypeId}';
      final ok = await api.insertTableType(
        userId: userId,
        tableTypeName: type.tableTypeName,
        tableTypeSortOrder: '${type.tableTypeSortOrder}',
        tableTypeActive: type.tableTypeActive,
        tableTypeNetworkStatus: network,
      );
      if (ok) {
        await db.markTableTypeSynced(type.tableTypeId);
        uploaded++;
      }
    }

    for (final master in await db.getPendingPortionMasters()) {
      final network =
          master.portionMasterNetworkStatus?.trim().isNotEmpty == true
              ? master.portionMasterNetworkStatus!
              : 'pm_${master.portionMasterId}';
      final ok = await api.insertPortionMaster(
        userId: userId,
        portionName: master.portionName,
        portionMasterDeletedStatus: master.portionMasterDeletedStatus,
        portionMasterNetworkStatus: network,
      );
      if (ok) {
        await db.markPortionMasterSynced(master.portionMasterId);
        uploaded++;
      }
    }

    for (final portion in await db.getPendingPortions()) {
      final network = portion.portionNetworkStatus?.trim().isNotEmpty == true
          ? portion.portionNetworkStatus!
          : 'por_${portion.portionId}';
      final product = await (db.select(db.products)
            ..where((t) => t.productId.equals(portion.productId)))
          .getSingleOrNull();
      final ok = await api.insertPortion(
        userId: userId,
        productId: '${portion.productId}',
        productNetworkStatus: product?.productNetworkStatus ?? '',
        portionName: portion.portionName,
        portionPrice: portion.portionPrice.toStringAsFixed(2),
        portionSortOrder: '${portion.portionSortOrder}',
        portionNetworkStatus: network,
        portionDeletedStatus: portion.portionDeletedStatus,
        portionMasterId: '${portion.portionMasterId ?? 0}',
      );
      if (ok) {
        await db.markPortionSynced(portion.portionId);
        uploaded++;
      }
    }

    for (final combo in await db.getPendingCombos()) {
      final network = combo.comboNetworkStatus?.trim().isNotEmpty == true
          ? combo.comboNetworkStatus!
          : 'cmb_${combo.comboId}';
      final withGst = combo.comboWithGstPrice > 0
          ? combo.comboWithGstPrice
          : combo.comboPrice;
      final ok = await api.insertCombo(
        userId: userId,
        comboName: combo.comboName,
        comboCode: combo.comboCode ?? '',
        comboPrice: combo.comboPrice.toStringAsFixed(2),
        comboCgst: combo.comboCgst.toStringAsFixed(2),
        comboSgst: combo.comboSgst.toStringAsFixed(2),
        comboWithGstPrice: withGst.toStringAsFixed(2),
        comboNetworkStatus: network,
        comboActiveStatus: combo.comboActiveStatus,
        comboDeletedStatus: combo.comboDeletedStatus,
        comboSortOrder: '${combo.comboSortOrder}',
      );
      if (ok) {
        final items = await db.getComboItemsForCombo(combo.comboId);
        for (final item in items) {
          if (item.comboItemSyncStatus == '1') continue;
          await api.insertComboItem(
            userId: userId,
            comboId: '${combo.comboId}',
            comboNetworkStatus: network,
            productId: '${item.productId ?? 0}',
            productNetworkStatus: item.productNetworkStatus ?? '',
            portionId: '${item.portionId ?? 0}',
            portionNetworkStatus: item.portionNetworkStatus ?? '',
            comboItemQuantity: '${item.comboItemQuantity}',
            comboItemSortOrder: '${item.comboItemSortOrder}',
            comboItemNetworkStatus: item.comboItemNetworkStatus ??
                'cbi_${item.comboItemId}',
            comboItemDeletedStatus: item.comboItemDeletedStatus,
          );
        }
        await db.markComboSynced(combo.comboId);
        uploaded++;
      }
    }

    return uploaded;
  }

  Future<int> createCategory({
    required String userId,
    required String categoryName,
    int? foodTypeId,
    String? foodTypeCode,
    bool uploadNow = true,
  }) async {
    final id = await db.insertLocalCategory(
      categoryName: categoryName.trim(),
      foodTypeId: foodTypeId,
      foodTypeCode: foodTypeCode,
    );
    if (uploadNow && userId.trim().isNotEmpty) {
      await uploadPendingMasters(userId);
    }
    return id;
  }

  Future<int> createDiningArea({
    required String userId,
    required String areaName,
    bool uploadNow = true,
  }) async {
    final id = await db.insertLocalDiningArea(areaName: areaName.trim());
    if (uploadNow && userId.trim().isNotEmpty) {
      await uploadPendingMasters(userId);
    }
    return id;
  }

  Future<int> createTableType({
    required String userId,
    required String tableTypeName,
    bool uploadNow = true,
  }) async {
    final id =
        await db.insertLocalTableType(tableTypeName: tableTypeName.trim());
    if (uploadNow && userId.trim().isNotEmpty) {
      await uploadPendingMasters(userId);
    }
    return id;
  }

  Future<int> createPortionMaster({
    required String userId,
    required String portionName,
    bool uploadNow = true,
  }) async {
    final id =
        await db.insertLocalPortionMaster(portionName: portionName.trim());
    if (uploadNow && userId.trim().isNotEmpty) {
      await uploadPendingMasters(userId);
    }
    return id;
  }

  Future<void> deletePortionMaster(int portionMasterId) =>
      db.softDeletePortionMaster(portionMasterId);

  Future<int> createSubcategory({
    required String userId,
    required String subcategoryName,
    required int categoryId,
    String? categoryNetworkStatus,
    bool uploadNow = true,
  }) async {
    final id = await db.insertLocalSubcategory(
      subcategoryName: subcategoryName.trim(),
      categoryId: categoryId,
      categoryNetworkStatus: categoryNetworkStatus,
    );
    if (uploadNow && userId.trim().isNotEmpty) {
      await uploadPendingMasters(userId);
    }
    return id;
  }

  Future<int> createProduct({
    required String userId,
    required String productName,
    required double productPrice,
    int? categoryId,
    String? categoryName,
    bool uploadNow = true,
  }) async {
    final id = await db.insertLocalProduct(
      productName: productName.trim(),
      productPrice: productPrice,
      categoryId: categoryId,
      categoryName: categoryName,
    );
    if (uploadNow && userId.trim().isNotEmpty) {
      await uploadPendingMasters(userId);
    }
    return id;
  }

  Future<void> updateCategory({
    required int categoryId,
    required String categoryName,
  }) {
    return db.updateLocalCategory(
      categoryId: categoryId,
      categoryName: categoryName.trim(),
    );
  }

  Future<void> deleteCategory(int categoryId) =>
      db.softDeleteCategory(categoryId);

  Future<void> updateProduct({
    required int productId,
    required String productName,
    required double productPrice,
    int? categoryId,
    String? categoryName,
  }) {
    return db.updateLocalProduct(
      productId: productId,
      productName: productName.trim(),
      productPrice: productPrice,
      categoryId: categoryId,
      categoryName: categoryName,
    );
  }

  Future<void> deleteProduct(int productId) =>
      db.softDeleteProduct(productId);

  Future<int> createCombo({
    required String comboName,
    required double comboPrice,
    List<({int productId, int quantity})> items = const [],
  }) async {
    final id = await db.insertLocalCombo(
      comboName: comboName.trim(),
      comboPrice: comboPrice,
    );
    if (items.isNotEmpty) {
      await db.replaceLocalComboItems(comboId: id, items: items);
    }
    return id;
  }

  Future<void> updateCombo({
    required int comboId,
    required String comboName,
    required double comboPrice,
    List<({int productId, int quantity})> items = const [],
  }) async {
    await db.updateLocalCombo(
      comboId: comboId,
      comboName: comboName.trim(),
      comboPrice: comboPrice,
    );
    await db.replaceLocalComboItems(comboId: comboId, items: items);
  }

  Future<void> deleteCombo(int comboId) => db.softDeleteCombo(comboId);
}
