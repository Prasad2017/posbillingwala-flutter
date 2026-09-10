import 'package:pos_billingwala_v2/core/utils/json_parsers.dart';

class FoodTypeDto {
  const FoodTypeDto({
    required this.foodTypeId,
    required this.foodTypeName,
    this.foodTypeCode,
    this.foodTypeSortOrder = 0,
    this.foodTypeStatus = '1',
  });

  final int foodTypeId;
  final String foodTypeName;
  final String? foodTypeCode;
  final int foodTypeSortOrder;
  final String foodTypeStatus;

  factory FoodTypeDto.fromJson(Map<String, dynamic> json) {
    return FoodTypeDto(
      foodTypeId: parseInt(json['foodTypeId']) ?? 0,
      foodTypeName: parseString(json['foodTypeName']) ?? '',
      foodTypeCode: parseString(json['foodTypeCode']),
      foodTypeSortOrder: parseInt(json['foodTypeSortOrder']) ?? 0,
      foodTypeStatus: parseString(json['foodTypeStatus']) ?? '1',
    );
  }

  Map<String, dynamic> toJson() => {
        'foodTypeId': foodTypeId,
        'foodTypeName': foodTypeName,
        'foodTypeCode': foodTypeCode,
        'foodTypeSortOrder': foodTypeSortOrder,
        'foodTypeStatus': foodTypeStatus,
      };
}

class CategoryDto {
  const CategoryDto({
    required this.categoryId,
    required this.categoryName,
    this.foodTypeId,
    this.foodTypeCode,
    this.categorySortOrder = 0,
    this.categoryDeletedStatus = '0',
    this.categoryNetworkStatus,
    this.categoryStatus = '1',
  });

  final int categoryId;
  final String categoryName;
  final int? foodTypeId;
  final String? foodTypeCode;
  final int categorySortOrder;
  final String categoryDeletedStatus;
  final String? categoryNetworkStatus;
  final String categoryStatus;

  factory CategoryDto.fromJson(Map<String, dynamic> json) {
    return CategoryDto(
      categoryId: parseInt(json['categoryId']) ?? 0,
      categoryName: parseString(json['categoryName']) ?? '',
      foodTypeId: parseInt(json['foodTypeId']),
      foodTypeCode: parseString(json['foodTypeCode']),
      categorySortOrder: parseInt(json['categorySortOrder']) ?? 0,
      categoryDeletedStatus: parseString(json['categoryDeletedStatus']) ?? '0',
      categoryNetworkStatus: parseString(json['categoryNetworkStatus']),
      categoryStatus: parseString(json['categoryStatus']) ?? '1',
    );
  }

  Map<String, dynamic> toJson() => {
        'categoryId': categoryId,
        'categoryName': categoryName,
        'foodTypeId': foodTypeId,
        'foodTypeCode': foodTypeCode,
        'categorySortOrder': categorySortOrder,
        'categoryDeletedStatus': categoryDeletedStatus,
        'categoryNetworkStatus': categoryNetworkStatus,
        'categoryStatus': categoryStatus,
      };
}

class ProductDto {
  const ProductDto({
    required this.productId,
    required this.productName,
    this.categoryId,
    this.categoryName,
    this.subcategoryId,
    this.productCode,
    this.productPrice = 0,
    this.openPrice = '0',
    this.productUnit,
    this.productCgst = 0,
    this.productSgst = 0,
    this.productDeletedStatus = '0',
    this.productNetworkStatus,
    this.productStatus = '1',
  });

  final int productId;
  final String productName;
  final int? categoryId;
  final String? categoryName;
  final int? subcategoryId;
  final String? productCode;
  final double productPrice;
  final String openPrice;
  final String? productUnit;
  final double productCgst;
  final double productSgst;
  final String productDeletedStatus;
  final String? productNetworkStatus;
  final String productStatus;

  double get productWithGstPrice {
    final tax = productCgst + productSgst;
    if (tax <= 0) return productPrice;
    return productPrice + (productPrice * tax / 100);
  }

  factory ProductDto.fromJson(Map<String, dynamic> json) {
    return ProductDto(
      productId: parseInt(json['productId']) ?? 0,
      productName: parseString(json['productName']) ?? '',
      categoryId: parseInt(json['categoryId']),
      categoryName: parseString(json['categoryName']),
      subcategoryId: parseInt(json['subcategoryId']),
      productCode: parseString(json['productCode']),
      productPrice: parseMoney(json['productPrice']),
      openPrice: parseString(json['openPrice']) ?? '0',
      productUnit: parseString(json['productUnit']),
      productCgst: parseMoney(json['productCGST']),
      productSgst: parseMoney(json['productSGST']),
      productDeletedStatus: parseString(json['productDeletedStatus']) ?? '0',
      productNetworkStatus: parseString(json['productNetworkStatus']),
      productStatus: parseString(json['productStatus']) ?? '1',
    );
  }

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'productName': productName,
        'categoryId': categoryId,
        'categoryName': categoryName,
        'subcategoryId': subcategoryId,
        'productCode': productCode,
        'productPrice': productPrice,
        'openPrice': openPrice,
        'productUnit': productUnit,
        'productCGST': productCgst,
        'productSGST': productSgst,
        'productDeletedStatus': productDeletedStatus,
        'productNetworkStatus': productNetworkStatus,
        'productStatus': productStatus,
      };
}

class PortionDto {
  const PortionDto({
    required this.portionId,
    required this.productId,
    required this.portionName,
    this.portionMasterId,
    this.portionPrice = 0,
    this.portionSortOrder = 0,
    this.portionDeletedStatus = '0',
    this.portionNetworkStatus,
    this.portionStatus = '1',
  });

  final int portionId;
  final int productId;
  final String portionName;
  final int? portionMasterId;
  final double portionPrice;
  final int portionSortOrder;
  final String portionDeletedStatus;
  final String? portionNetworkStatus;
  final String portionStatus;

  factory PortionDto.fromJson(Map<String, dynamic> json) {
    return PortionDto(
      portionId: parseInt(json['portionId']) ?? 0,
      productId: parseInt(json['productId']) ?? 0,
      portionName: parseString(json['portionName']) ?? '',
      portionMasterId: parseInt(json['portionMasterId']),
      portionPrice: parseMoney(json['portionPrice']),
      portionSortOrder: parseInt(json['portionSortOrder']) ?? 0,
      portionDeletedStatus: parseString(json['portionDeletedStatus']) ?? '0',
      portionNetworkStatus: parseString(json['portionNetworkStatus']),
      portionStatus: parseString(json['portionStatus']) ?? '1',
    );
  }

  Map<String, dynamic> toJson() => {
        'portionId': portionId,
        'productId': productId,
        'portionName': portionName,
        'portionMasterId': portionMasterId,
        'portionPrice': portionPrice,
        'portionSortOrder': portionSortOrder,
        'portionDeletedStatus': portionDeletedStatus,
        'portionNetworkStatus': portionNetworkStatus,
        'portionStatus': portionStatus,
      };
}

class PosTableDto {
  const PosTableDto({
    required this.tableId,
    required this.tableNumber,
    this.tableName = '',
    this.capacity = 0,
    this.areaId,
    this.tableActive = '1',
    this.sortOrder = 0,
    this.statusOverride,
    this.posTableNetworkStatus,
  });

  final int tableId;
  final String tableNumber;
  final String tableName;
  final int capacity;
  final int? areaId;
  final String tableActive;
  final int sortOrder;
  final String? statusOverride;
  final String? posTableNetworkStatus;

  factory PosTableDto.fromJson(Map<String, dynamic> json) {
    return PosTableDto(
      tableId: parseInt(json['tableId']) ?? 0,
      tableNumber: parseString(json['tableNumber']) ?? '',
      tableName: parseString(json['tableName']) ?? '',
      capacity: parseInt(json['capacity']) ?? 0,
      areaId: parseInt(json['areaId']),
      tableActive: parseString(json['tableActive']) ?? '1',
      sortOrder: parseInt(json['sortOrder']) ?? 0,
      statusOverride: parseString(json['statusOverride']),
      posTableNetworkStatus: parseString(json['posTableNetworkStatus']),
    );
  }

  Map<String, dynamic> toJson() => {
        'tableId': tableId,
        'tableNumber': tableNumber,
        'tableName': tableName,
        'capacity': capacity,
        'areaId': areaId,
        'tableActive': tableActive,
        'sortOrder': sortOrder,
        'statusOverride': statusOverride,
        'posTableNetworkStatus': posTableNetworkStatus,
      };
}

class SubcategoryDto {
  const SubcategoryDto({
    this.subcategoryId = 0,
    this.categoryId,
    this.subcategoryName = '',
    this.categoryNetworkStatus,
    this.subcategoryNetworkStatus,
    this.subcategorySortOrder = 0,
    this.subcategoryDeletedStatus = '0',
  });

  final int subcategoryId;
  final int? categoryId;
  final String subcategoryName;
  final String? categoryNetworkStatus;
  final String? subcategoryNetworkStatus;
  final int subcategorySortOrder;
  final String subcategoryDeletedStatus;

  factory SubcategoryDto.fromJson(Map<String, dynamic> json) {
    return SubcategoryDto(
      subcategoryId: parseInt(json['subcategoryId']) ?? 0,
      categoryId: parseInt(json['categoryId']),
      subcategoryName: parseString(json['subcategoryName']) ?? '',
      categoryNetworkStatus: parseString(json['categoryNetworkStatus']),
      subcategoryNetworkStatus: parseString(json['subcategoryNetworkStatus']),
      subcategorySortOrder: parseInt(json['subcategorySortOrder']) ?? 0,
      subcategoryDeletedStatus:
          parseString(json['subcategoryDeletedStatus']) ?? '0',
    );
  }
}

class DiningAreaDto {
  const DiningAreaDto({
    this.areaId = 0,
    this.areaName = '',
    this.areaSortOrder = 0,
    this.areaActive = '1',
    this.areaNetworkStatus,
  });

  final int areaId;
  final String areaName;
  final int areaSortOrder;
  final String areaActive;
  final String? areaNetworkStatus;

  factory DiningAreaDto.fromJson(Map<String, dynamic> json) {
    return DiningAreaDto(
      areaId: parseInt(json['areaId']) ?? 0,
      areaName: parseString(json['areaName'] ?? json['diningAreaName']) ?? '',
      areaSortOrder: parseInt(json['areaSortOrder'] ?? json['sortOrder']) ?? 0,
      areaActive: parseString(json['areaActive'] ?? json['status']) ?? '1',
      areaNetworkStatus: parseString(json['areaNetworkStatus']),
    );
  }
}

class TableTypeDto {
  const TableTypeDto({
    this.tableTypeId = 0,
    this.tableTypeName = '',
    this.tableTypeSortOrder = 0,
    this.tableTypeActive = '1',
    this.tableTypeNetworkStatus,
  });

  final int tableTypeId;
  final String tableTypeName;
  final int tableTypeSortOrder;
  final String tableTypeActive;
  final String? tableTypeNetworkStatus;

  factory TableTypeDto.fromJson(Map<String, dynamic> json) {
    return TableTypeDto(
      tableTypeId: parseInt(json['tableTypeId']) ?? 0,
      tableTypeName:
          parseString(json['tableTypeName'] ?? json['typeName']) ?? '',
      tableTypeSortOrder:
          parseInt(json['tableTypeSortOrder'] ?? json['sortOrder']) ?? 0,
      tableTypeActive:
          parseString(json['tableTypeActive'] ?? json['status']) ?? '1',
      tableTypeNetworkStatus: parseString(json['tableTypeNetworkStatus']),
    );
  }
}

class PortionMasterDto {
  const PortionMasterDto({
    this.portionMasterId = 0,
    this.portionName = '',
    this.portionMasterDeletedStatus = '0',
    this.portionMasterNetworkStatus,
    this.portionMasterStatus = '1',
  });

  final int portionMasterId;
  final String portionName;
  final String portionMasterDeletedStatus;
  final String? portionMasterNetworkStatus;
  final String portionMasterStatus;

  factory PortionMasterDto.fromJson(Map<String, dynamic> json) {
    return PortionMasterDto(
      portionMasterId: parseInt(json['portionMasterId']) ?? 0,
      portionName: parseString(json['portionName']) ?? '',
      portionMasterDeletedStatus:
          parseString(json['portionMasterDeletedStatus']) ?? '0',
      portionMasterNetworkStatus:
          parseString(json['portionMasterNetworkStatus']),
      portionMasterStatus: parseString(json['portionMasterStatus']) ?? '1',
    );
  }
}
