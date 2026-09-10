import 'package:drift/drift.dart';

/// Android [BranchSession] columns stamped on operational tables.
mixin BranchColumns on Table {
  TextColumn get organizationId => text().withDefault(const Constant(''))();
  TextColumn get branchId => text().withDefault(const Constant(''))();
  TextColumn get deviceId => text().withDefault(const Constant(''))();
}

/// Matches Android `food_type` master table (subset for catalog UI).
class FoodTypes extends Table {
  IntColumn get foodTypeId => integer()();
  TextColumn get foodTypeName => text().withDefault(const Constant(''))();
  TextColumn get foodTypeCode => text().nullable()();
  IntColumn get foodTypeSortOrder =>
      integer().withDefault(const Constant(0))();
  TextColumn get foodTypeStatus => text().withDefault(const Constant('1'))();

  @override
  Set<Column<Object>> get primaryKey => {foodTypeId};
}

/// Matches Android `product_category`.
class ProductCategories extends Table {
  IntColumn get categoryId => integer()();
  TextColumn get categoryName => text().withDefault(const Constant(''))();
  IntColumn get foodTypeId => integer().nullable()();
  TextColumn get foodTypeCode => text().nullable()();
  IntColumn get categorySortOrder =>
      integer().withDefault(const Constant(0))();
  TextColumn get categoryDeletedStatus =>
      text().withDefault(const Constant('0'))();
  TextColumn get categoryNetworkStatus => text().nullable()();
  TextColumn get categoryStatus => text().withDefault(const Constant('1'))();
  /// Local sync flag: `0` pending, `1` uploaded.
  TextColumn get categorySyncStatus =>
      text().withDefault(const Constant('1'))();

  @override
  Set<Column<Object>> get primaryKey => {categoryId};
}

/// Matches Android `product_subcategory`.
class ProductSubcategories extends Table {
  IntColumn get subcategoryId => integer()();
  IntColumn get categoryId => integer().nullable()();
  TextColumn get subcategoryName => text().withDefault(const Constant(''))();
  TextColumn get categoryNetworkStatus => text().nullable()();
  TextColumn get subcategoryNetworkStatus => text().nullable()();
  IntColumn get subcategorySortOrder =>
      integer().withDefault(const Constant(0))();
  TextColumn get subcategoryDeletedStatus =>
      text().withDefault(const Constant('0'))();
  TextColumn get subcategoryStatus =>
      text().withDefault(const Constant('1'))();
  /// Local sync flag: `0` pending, `1` uploaded.
  TextColumn get subcategorySyncStatus =>
      text().withDefault(const Constant('1'))();

  @override
  Set<Column<Object>> get primaryKey => {subcategoryId};
}

/// Matches Android `product` (fields needed for Masters + POS cart).
class Products extends Table {
  IntColumn get productId => integer()();
  IntColumn get categoryId => integer().nullable()();
  TextColumn get categoryName => text().nullable()();
  IntColumn get subcategoryId => integer().nullable()();
  TextColumn get productCode => text().nullable()();
  TextColumn get productName => text().withDefault(const Constant(''))();
  RealColumn get productPrice => real().withDefault(const Constant(0))();
  TextColumn get openPrice => text().withDefault(const Constant('0'))();
  TextColumn get productUnit => text().nullable()();
  RealColumn get productCgst => real().withDefault(const Constant(0))();
  RealColumn get productSgst => real().withDefault(const Constant(0))();
  RealColumn get productWithGstPrice =>
      real().withDefault(const Constant(0))();
  TextColumn get productDeletedStatus =>
      text().withDefault(const Constant('0'))();
  TextColumn get productNetworkStatus => text().nullable()();
  TextColumn get productStatus => text().withDefault(const Constant('1'))();
  TextColumn get productSyncStatus =>
      text().withDefault(const Constant('1'))();

  @override
  Set<Column<Object>> get primaryKey => {productId};
}

/// Matches Android `product_portion`.
class ProductPortions extends Table {
  IntColumn get portionId => integer()();
  IntColumn get productId => integer()();
  IntColumn get portionMasterId => integer().nullable()();
  TextColumn get portionName => text().withDefault(const Constant(''))();
  RealColumn get portionPrice => real().withDefault(const Constant(0))();
  IntColumn get portionSortOrder => integer().withDefault(const Constant(0))();
  TextColumn get portionDeletedStatus =>
      text().withDefault(const Constant('0'))();
  TextColumn get portionNetworkStatus => text().nullable()();
  TextColumn get portionStatus => text().withDefault(const Constant('1'))();
  TextColumn get portionSyncStatus =>
      text().withDefault(const Constant('1'))();

  @override
  Set<Column<Object>> get primaryKey => {portionId};
}

/// Android `combo` master.
class Combos extends Table {
  IntColumn get comboId => integer()();
  TextColumn get comboName => text().withDefault(const Constant(''))();
  TextColumn get comboCode => text().nullable()();
  RealColumn get comboPrice => real().withDefault(const Constant(0))();
  RealColumn get comboCgst => real().withDefault(const Constant(0))();
  RealColumn get comboSgst => real().withDefault(const Constant(0))();
  RealColumn get comboWithGstPrice =>
      real().withDefault(const Constant(0))();
  TextColumn get comboActiveStatus =>
      text().withDefault(const Constant('1'))();
  TextColumn get comboDeletedStatus =>
      text().withDefault(const Constant('0'))();
  TextColumn get comboNetworkStatus => text().nullable()();
  IntColumn get comboSortOrder => integer().withDefault(const Constant(0))();
  TextColumn get comboSyncStatus =>
      text().withDefault(const Constant('1'))();

  @override
  Set<Column<Object>> get primaryKey => {comboId};
}

/// Android `combo_item` components.
class ComboItems extends Table {
  IntColumn get comboItemId => integer()();
  IntColumn get comboId => integer()();
  IntColumn get productId => integer().nullable()();
  IntColumn get portionId => integer().nullable()();
  IntColumn get comboItemQuantity =>
      integer().withDefault(const Constant(1))();
  IntColumn get comboItemSortOrder =>
      integer().withDefault(const Constant(0))();
  TextColumn get comboItemDeletedStatus =>
      text().withDefault(const Constant('0'))();
  TextColumn get comboItemNetworkStatus => text().nullable()();
  TextColumn get comboNetworkStatus => text().nullable()();
  TextColumn get productNetworkStatus => text().nullable()();
  TextColumn get portionNetworkStatus => text().nullable()();
  TextColumn get comboItemSyncStatus =>
      text().withDefault(const Constant('1'))();

  @override
  Set<Column<Object>> get primaryKey => {comboItemId};
}

/// Persistent cart. `cartScope` isolates POS/takeaway (`''`) from dine-in tables.
class CartItems extends Table {
  IntColumn get productId => integer()();
  TextColumn get cartScope => text().withDefault(const Constant(''))();
  /// `0` = base product / no portion; else product_portion.portionId.
  IntColumn get portionId => integer().withDefault(const Constant(0))();
  TextColumn get productName => text().withDefault(const Constant(''))();
  IntColumn get categoryId => integer().nullable()();
  TextColumn get categoryName => text().nullable()();
  TextColumn get productCode => text().nullable()();
  RealColumn get unitPrice => real().withDefault(const Constant(0))();
  RealColumn get gstPercent => real().withDefault(const Constant(0))();
  IntColumn get quantity => integer().withDefault(const Constant(1))();
  /// Qty already sent to kitchen via KOT (delta = quantity - printedQuantity).
  IntColumn get printedQuantity => integer().withDefault(const Constant(0))();
  TextColumn get productUnit => text().nullable()();
  IntColumn get diningSessionId => integer().nullable()();
  /// `product` or `combo`.
  TextColumn get lineType => text().withDefault(const Constant('product'))();
  IntColumn get comboId => integer().nullable()();
  TextColumn get comboNetworkStatus => text().nullable()();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {productId, cartScope, portionId};
}

/// Local offline mess member payments (synced via API when online).
class MessMemberPayments extends Table {
  IntColumn get localPaymentId => integer().autoIncrement()();
  TextColumn get memberId => text()();
  TextColumn get memberName => text().withDefault(const Constant(''))();
  RealColumn get paymentMessAmount => real().withDefault(const Constant(0))();
  RealColumn get paymentPaidAmount => real().withDefault(const Constant(0))();
  TextColumn get messTotalDays => text().withDefault(const Constant('30'))();
  /// `yyyy-MM`
  TextColumn get paymentDate => text()();
  TextColumn get paymentNetworkStatus => text()();
  TextColumn get paymentStatus => text().withDefault(const Constant('0'))();
  /// `0` pending upload, `1` uploaded.
  TextColumn get paymentSyncStatus =>
      text().withDefault(const Constant('0'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// Local invoice header (Android `invoice` subset).
class Invoices extends Table with BranchColumns {
  IntColumn get invoiceId => integer().autoIncrement()();
  TextColumn get invoiceNumber => text()();
  DateTimeColumn get invoiceDate => dateTime()();
  TextColumn get invoiceType =>
      text().withDefault(const Constant('fast_billing'))();
  RealColumn get subTotal => real().withDefault(const Constant(0))();
  RealColumn get totalGstAmount => real().withDefault(const Constant(0))();
  RealColumn get discount => real().withDefault(const Constant(0))();
  TextColumn get discountType =>
      text().withDefault(const Constant('Amount'))();
  RealColumn get packingCharge => real().withDefault(const Constant(0))();
  TextColumn get packingChargeType =>
      text().withDefault(const Constant('Amount'))();
  RealColumn get totalAmount => real().withDefault(const Constant(0))();
  TextColumn get paymentMode => text().withDefault(const Constant('Cash'))();
  RealColumn get cashAmount => real().withDefault(const Constant(0))();
  RealColumn get upiAmount => real().withDefault(const Constant(0))();
  TextColumn get invoiceOrderStatus =>
      text().withDefault(const Constant('completed'))();
  /// Idempotency key uploaded to cloud (never changes after create).
  TextColumn get invoiceNetworkStatus => text()();
  /// Local sync flag: `0` pending, `1` uploaded (Android `invoiceStatus`).
  TextColumn get invoiceSyncStatus => text().withDefault(const Constant('0'))();
  TextColumn get noOfTable => text().withDefault(const Constant(''))();
  TextColumn get customerName => text().nullable()();
  TextColumn get customerMobile => text().nullable()();
  IntColumn get diningSessionId => integer().nullable()();
  IntColumn get itemCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// Local invoice line items (Android `invoice_final_product` subset).
class InvoiceItems extends Table with BranchColumns {
  IntColumn get invoiceItemId => integer().autoIncrement()();
  TextColumn get invoiceNumber => text()();
  IntColumn get productId => integer().nullable()();
  TextColumn get productName => text().withDefault(const Constant(''))();
  TextColumn get productCode => text().nullable()();
  RealColumn get productPrice => real().withDefault(const Constant(0))();
  IntColumn get productQuantity => integer().withDefault(const Constant(1))();
  RealColumn get productCgst => real().withDefault(const Constant(0))();
  RealColumn get productSgst => real().withDefault(const Constant(0))();
  TextColumn get productUnit => text().nullable()();
  TextColumn get categoryName => text().nullable()();
  TextColumn get invoiceItemType =>
      text().withDefault(const Constant('product'))();
  TextColumn get productStatus => text().withDefault(const Constant('completed'))();
  TextColumn get invoiceItemNetworkStatus => text().nullable()();
  TextColumn get invoiceItemSyncStatus =>
      text().withDefault(const Constant('0'))();
}

/// Android `pos_table` subset for dine-in floor.
class PosTables extends Table with BranchColumns {
  IntColumn get tableId => integer()();
  TextColumn get tableNumber => text()();
  TextColumn get displayName => text().withDefault(const Constant(''))();
  IntColumn get capacity => integer().withDefault(const Constant(0))();
  IntColumn get areaId => integer().nullable()();
  TextColumn get tableActive => text().withDefault(const Constant('1'))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  TextColumn get statusOverride => text().nullable()();
  TextColumn get posTableNetworkStatus => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {tableId};
}

/// Android dining area master.
class DiningAreas extends Table with BranchColumns {
  IntColumn get areaId => integer()();
  TextColumn get areaName => text().withDefault(const Constant(''))();
  IntColumn get areaSortOrder => integer().withDefault(const Constant(0))();
  TextColumn get areaActive => text().withDefault(const Constant('1'))();
  TextColumn get areaNetworkStatus => text().nullable()();
  TextColumn get areaSyncStatus => text().withDefault(const Constant('1'))();

  @override
  Set<Column<Object>> get primaryKey => {areaId};
}

/// Android table type master.
class TableTypes extends Table with BranchColumns {
  IntColumn get tableTypeId => integer()();
  TextColumn get tableTypeName => text().withDefault(const Constant(''))();
  IntColumn get tableTypeSortOrder =>
      integer().withDefault(const Constant(0))();
  TextColumn get tableTypeActive => text().withDefault(const Constant('1'))();
  TextColumn get tableTypeNetworkStatus => text().nullable()();
  TextColumn get tableTypeSyncStatus =>
      text().withDefault(const Constant('1'))();

  @override
  Set<Column<Object>> get primaryKey => {tableTypeId};
}

/// Android portion_master (reusable portion names).
class PortionMasters extends Table {
  IntColumn get portionMasterId => integer()();
  TextColumn get portionName => text().withDefault(const Constant(''))();
  TextColumn get portionMasterDeletedStatus =>
      text().withDefault(const Constant('0'))();
  TextColumn get portionMasterNetworkStatus => text().nullable()();
  TextColumn get portionMasterSyncStatus =>
      text().withDefault(const Constant('1'))();

  @override
  Set<Column<Object>> get primaryKey => {portionMasterId};
}

/// Android `dining_session` subset for open dine-in bills.
class DiningSessions extends Table with BranchColumns {
  IntColumn get sessionId => integer().autoIncrement()();
  TextColumn get primaryTableNumber => text()();
  /// CSV of joined secondary table numbers (Android `joinedTableNumbers`).
  TextColumn get joinedTableNumbers =>
      text().withDefault(const Constant(''))();
  TextColumn get sessionStatus =>
      text().withDefault(const Constant('RUNNING'))();
  IntColumn get guestCount => integer().withDefault(const Constant(1))();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get closedAt => dateTime().nullable()();
  TextColumn get customerName => text().nullable()();
  TextColumn get customerMobile => text().nullable()();
  RealColumn get paidAmount => real().withDefault(const Constant(0))();
  TextColumn get sessionNetworkStatus => text().nullable()();
  /// Local sync flag: `0` pending, `1` uploaded.
  TextColumn get sessionSyncStatus =>
      text().withDefault(const Constant('0'))();
  IntColumn get sessionVersion => integer().withDefault(const Constant(1))();
}

/// Android `order_round` — one round per KOT delta.
class OrderRounds extends Table with BranchColumns {
  IntColumn get orderRoundId => integer().autoIncrement()();
  IntColumn get sessionId => integer()();
  IntColumn get roundNumber => integer()();
  IntColumn get kotId => integer().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// Android `kot` — kitchen order ticket header.
class Kots extends Table with BranchColumns {
  IntColumn get kotId => integer().autoIncrement()();
  IntColumn get sessionId => integer()();
  IntColumn get orderRoundId => integer()();
  TextColumn get kotNumber => text()();
  TextColumn get tableNumber => text()();
  TextColumn get printStatus =>
      text().withDefault(const Constant('PENDING'))();
  TextColumn get kitchenName =>
      text().withDefault(const Constant('Main Kitchen'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// Android `kot_item` — name + qty only on the ticket.
class KotItems extends Table with BranchColumns {
  IntColumn get kotItemId => integer().autoIncrement()();
  IntColumn get kotId => integer()();
  IntColumn get productId => integer().nullable()();
  TextColumn get productName => text().withDefault(const Constant(''))();
  IntColumn get productQuantity => integer().withDefault(const Constant(1))();
  TextColumn get portionName => text().nullable()();
  TextColumn get productUnit => text().nullable()();
}

/// Android `member` / mess_member subset.
class MessMembers extends Table {
  IntColumn get memberId => integer()();
  TextColumn get memberName => text().withDefault(const Constant(''))();
  TextColumn get memberMobileNumber => text().nullable()();
  TextColumn get memberAltenetMobileNumber => text().nullable()();
  TextColumn get memberAddress => text().nullable()();
  TextColumn get registrationNo => text().nullable()();
  TextColumn get memberType =>
      text().withDefault(const Constant('student'))();
  TextColumn get rollNo => text().nullable()();
  TextColumn get college => text().nullable()();
  TextColumn get studentYear => text().nullable()();
  TextColumn get company => text().nullable()();
  TextColumn get memberStatus => text().withDefault(const Constant('1'))();
  TextColumn get memberNetworkStatus => text().nullable()();
  TextColumn get memberSyncStatus =>
      text().withDefault(const Constant('1'))();

  @override
  Set<Column<Object>> get primaryKey => {memberId};
}

/// Android `mess_token` subset for local issue / verify.
class MessTokens extends Table {
  IntColumn get tokenId => integer().autoIncrement()();
  TextColumn get tokenCode => text()();
  TextColumn get memberId => text().nullable()();
  TextColumn get memberName => text().nullable()();
  TextColumn get memberMobile => text().nullable()();
  TextColumn get memberType =>
      text().withDefault(const Constant('member'))();
  TextColumn get messType => text().withDefault(const Constant('Lunch'))();
  RealColumn get tokenAmount => real().withDefault(const Constant(0))();
  DateTimeColumn get tokenDate => dateTime()();
  DateTimeColumn get verifiedDate => dateTime().nullable()();
  TextColumn get tokenState =>
      text().withDefault(const Constant('active'))();
  TextColumn get tokenNetworkStatus => text().nullable()();
  TextColumn get tokenSyncStatus =>
      text().withDefault(const Constant('0'))();
}

/// Android `inventory` ledger (append-only stock in/out rows).
class InventoryMovements extends Table with BranchColumns {
  IntColumn get inventoryId => integer().autoIncrement()();
  IntColumn get productId => integer()();
  TextColumn get productName => text().withDefault(const Constant(''))();
  /// Qty added on stock-in (0 on sale deduct).
  RealColumn get productInventoryQuantity =>
      real().withDefault(const Constant(0))();
  /// Remaining balance after this movement.
  RealColumn get afterSaleInventoryQuantity =>
      real().withDefault(const Constant(0))();
  /// Qty sold on this movement (0 on stock-in).
  RealColumn get saleInventoryQuantity =>
      real().withDefault(const Constant(0))();
  DateTimeColumn get inventoryDate => dateTime()();
  TextColumn get inventoryNetworkStatus => text()();
  TextColumn get inventorySyncStatus =>
      text().withDefault(const Constant('0'))();
}

/// Android `expenses` table.
class ShopExpenses extends Table with BranchColumns {
  IntColumn get expensesId => integer().autoIncrement()();
  TextColumn get expensesName => text().withDefault(const Constant(''))();
  RealColumn get expensesAmount => real().withDefault(const Constant(0))();
  DateTimeColumn get expensesDate => dateTime()();
  TextColumn get expensesNetworkStatus => text()();
  TextColumn get expensesSyncStatus =>
      text().withDefault(const Constant('0'))();
}

/// Android `mess_invoice` paper coupon ledger.
class MessInvoices extends Table {
  IntColumn get invoiceId => integer().autoIncrement()();
  TextColumn get memberId => text().nullable()();
  TextColumn get memberName => text().withDefault(const Constant(''))();
  TextColumn get messType => text().withDefault(const Constant('Lunch'))();
  DateTimeColumn get messInvoiceDate => dateTime()();
  TextColumn get messInvoiceNetworkStatus => text()();
  /// `0` pending upload, `1` synced (Android messInvoiceStatus).
  TextColumn get messInvoiceStatus =>
      text().withDefault(const Constant('0'))();
}
