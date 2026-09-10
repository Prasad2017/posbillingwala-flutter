import 'package:drift/drift.dart';
import 'package:pos_billingwala_v2/core/database/app_database.dart';
import 'package:pos_billingwala_v2/core/utils/json_parsers.dart';

class InventoryDto {
  const InventoryDto({
    required this.productId,
    this.productName = '',
    this.productInventoryQuantity = 0,
    this.afterSaleInventoryQuantity = 0,
    this.saleInventoryQuantity = 0,
    required this.inventoryDate,
    required this.inventoryNetworkStatus,
    this.inventoryId,
  });

  final int? inventoryId;
  final int productId;
  final String productName;
  final double productInventoryQuantity;
  final double afterSaleInventoryQuantity;
  final double saleInventoryQuantity;
  final DateTime inventoryDate;
  final String inventoryNetworkStatus;

  factory InventoryDto.fromJson(Map<String, dynamic> json) {
    final network = parseString(json['inventoryNetworkStatus'])?.trim() ??
        'inv_${parseString(json['inventoryId']) ?? DateTime.now().millisecondsSinceEpoch}';
    return InventoryDto(
      inventoryId: parseInt(json['inventoryId']),
      productId: parseInt(json['productId']) ?? 0,
      productName: parseString(json['productName']) ?? '',
      productInventoryQuantity: parseMoney(json['productInventoryQuantity']),
      afterSaleInventoryQuantity:
          parseMoney(json['afterSaleInventoryQuantity']),
      saleInventoryQuantity: parseMoney(json['saleInventoryQuantity']),
      inventoryDate: parseInvoiceDate(json['inventoryDate']) ?? DateTime.now(),
      inventoryNetworkStatus: network,
    );
  }

  Map<String, dynamic> toJson() => {
        'inventoryId': inventoryId,
        'productId': productId,
        'productName': productName,
        'productInventoryQuantity': productInventoryQuantity,
        'afterSaleInventoryQuantity': afterSaleInventoryQuantity,
        'saleInventoryQuantity': saleInventoryQuantity,
        'inventoryDate': inventoryDate.toIso8601String(),
        'inventoryNetworkStatus': inventoryNetworkStatus,
      };

  InventoryMovementsCompanion toCompanion({String? productNameOverride}) {
    final name = (productNameOverride?.trim().isNotEmpty == true)
        ? productNameOverride!.trim()
        : productName;
    return InventoryMovementsCompanion.insert(
      productId: productId,
      productName: Value(name),
      productInventoryQuantity: Value(productInventoryQuantity),
      afterSaleInventoryQuantity: Value(afterSaleInventoryQuantity),
      saleInventoryQuantity: Value(saleInventoryQuantity),
      inventoryDate: inventoryDate,
      inventoryNetworkStatus: inventoryNetworkStatus,
      inventorySyncStatus: const Value('1'),
    );
  }
}

class ExpenseDto {
  const ExpenseDto({
    this.expensesId,
    required this.expensesName,
    this.expensesAmount = 0,
    required this.expensesDate,
    required this.expensesNetworkStatus,
  });

  final int? expensesId;
  final String expensesName;
  final double expensesAmount;
  final DateTime expensesDate;
  final String expensesNetworkStatus;

  factory ExpenseDto.fromJson(Map<String, dynamic> json) {
    final network = parseString(json['expensesNetworkStatus'])?.trim() ??
        'exp_${parseString(json['expensesId']) ?? DateTime.now().millisecondsSinceEpoch}';
    return ExpenseDto(
      expensesId: parseInt(json['expensesId']),
      expensesName: parseString(json['expensesName']) ?? '',
      expensesAmount: parseMoney(json['expensesAmount']),
      expensesDate: parseInvoiceDate(json['expensesDate']) ?? DateTime.now(),
      expensesNetworkStatus: network,
    );
  }

  Map<String, dynamic> toJson() => {
        'expensesId': expensesId,
        'expensesName': expensesName,
        'expensesAmount': expensesAmount,
        'expensesDate': expensesDate.toIso8601String(),
        'expensesNetworkStatus': expensesNetworkStatus,
      };

  ShopExpensesCompanion toCompanion() {
    return ShopExpensesCompanion.insert(
      expensesName: Value(expensesName),
      expensesAmount: Value(expensesAmount),
      expensesDate: expensesDate,
      expensesNetworkStatus: expensesNetworkStatus,
      expensesSyncStatus: const Value('1'),
    );
  }
}
