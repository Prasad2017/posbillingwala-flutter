import 'package:pos_billingwala_v2/core/utils/json_parsers.dart';

class ComboDto {
  const ComboDto({
    required this.comboId,
    required this.comboName,
    this.comboCode,
    this.comboPrice = 0,
    this.comboCgst = 0,
    this.comboSgst = 0,
    this.comboWithGstPrice,
    this.comboActiveStatus = '1',
    this.comboDeletedStatus = '0',
    this.comboNetworkStatus,
    this.comboSortOrder = 0,
  });

  final int comboId;
  final String comboName;
  final String? comboCode;
  final double comboPrice;
  final double comboCgst;
  final double comboSgst;
  final double? comboWithGstPrice;
  final String comboActiveStatus;
  final String comboDeletedStatus;
  final String? comboNetworkStatus;
  final int comboSortOrder;

  double get resolvedWithGstPrice {
    if (comboWithGstPrice != null) return comboWithGstPrice!;
    final tax = comboCgst + comboSgst;
    if (tax <= 0) return comboPrice;
    return comboPrice + (comboPrice * tax / 100);
  }

  factory ComboDto.fromJson(Map<String, dynamic> json) {
    return ComboDto(
      comboId: parseInt(json['comboId']) ?? 0,
      comboName: parseString(json['comboName']) ?? '',
      comboCode: parseString(json['comboCode']),
      comboPrice: parseMoney(json['comboPrice']),
      comboCgst: parseMoney(json['comboCGST'] ?? json['comboCgst']),
      comboSgst: parseMoney(json['comboSGST'] ?? json['comboSgst']),
      comboWithGstPrice: parseMoney(
        json['comboWithGSTPrice'] ?? json['comboWithGstPrice'],
      ),
      comboActiveStatus: parseString(json['comboActiveStatus']) ?? '1',
      comboDeletedStatus: parseString(json['comboDeletedStatus']) ?? '0',
      comboNetworkStatus: parseString(json['comboNetworkStatus']),
      comboSortOrder: parseInt(json['comboSortOrder']) ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'comboId': comboId,
        'comboName': comboName,
        'comboCode': comboCode,
        'comboPrice': comboPrice,
        'comboCGST': comboCgst,
        'comboSGST': comboSgst,
        'comboWithGSTPrice': resolvedWithGstPrice,
        'comboActiveStatus': comboActiveStatus,
        'comboDeletedStatus': comboDeletedStatus,
        'comboNetworkStatus': comboNetworkStatus,
        'comboSortOrder': comboSortOrder,
      };
}

class ComboItemDto {
  const ComboItemDto({
    required this.comboItemId,
    required this.comboId,
    this.productId,
    this.portionId,
    this.comboItemQuantity = 1,
    this.comboItemSortOrder = 0,
    this.comboItemDeletedStatus = '0',
    this.comboItemNetworkStatus,
    this.comboNetworkStatus,
    this.productNetworkStatus,
    this.portionNetworkStatus,
    this.productName,
    this.portionName,
  });

  final int comboItemId;
  final int comboId;
  final int? productId;
  final int? portionId;
  final int comboItemQuantity;
  final int comboItemSortOrder;
  final String comboItemDeletedStatus;
  final String? comboItemNetworkStatus;
  final String? comboNetworkStatus;
  final String? productNetworkStatus;
  final String? portionNetworkStatus;
  final String? productName;
  final String? portionName;

  factory ComboItemDto.fromJson(Map<String, dynamic> json) {
    return ComboItemDto(
      comboItemId: parseInt(json['comboItemId']) ?? 0,
      comboId: parseInt(json['comboId']) ?? 0,
      productId: parseInt(json['productId']),
      portionId: parseInt(json['portionId']),
      comboItemQuantity: parseInt(json['comboItemQuantity']) ?? 1,
      comboItemSortOrder: parseInt(json['comboItemSortOrder']) ?? 0,
      comboItemDeletedStatus:
          parseString(json['comboItemDeletedStatus']) ?? '0',
      comboItemNetworkStatus: parseString(json['comboItemNetworkStatus']),
      comboNetworkStatus: parseString(json['comboNetworkStatus']),
      productNetworkStatus: parseString(json['productNetworkStatus']),
      portionNetworkStatus: parseString(json['portionNetworkStatus']),
      productName: parseString(json['productName']),
      portionName: parseString(json['portionName']),
    );
  }

  Map<String, dynamic> toJson() => {
        'comboItemId': comboItemId,
        'comboId': comboId,
        'productId': productId,
        'portionId': portionId,
        'comboItemQuantity': comboItemQuantity,
        'comboItemSortOrder': comboItemSortOrder,
        'comboItemDeletedStatus': comboItemDeletedStatus,
        'comboItemNetworkStatus': comboItemNetworkStatus,
        'comboNetworkStatus': comboNetworkStatus,
        'productNetworkStatus': productNetworkStatus,
        'portionNetworkStatus': portionNetworkStatus,
        'productName': productName,
        'portionName': portionName,
      };
}
