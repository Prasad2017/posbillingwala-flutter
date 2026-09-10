import 'package:pos_billingwala_v2/core/utils/json_parsers.dart';

class CompanyDto {
  const CompanyDto({
    this.companyId,
    this.companyName = '',
    this.companyLogo,
    this.paymentLogo,
    this.cashierName,
    this.companyMobile,
    this.companyAddress,
    this.shopName1,
    this.shopName2,
    this.addressLine1,
    this.addressLine2,
    this.addressLine3,
    this.phoneNo1,
    this.phoneNo2,
    this.currencyName,
    this.tableStatus,
    this.noOfTable,
    this.countryName,
    this.stateName,
    this.gstStatus,
    this.gstNumber,
    this.panNumber,
    this.companyFssis,
    this.shopCgst,
    this.shopSgst,
    this.openingMinutes,
    this.closingMinutes,
    this.companyStatus = '1',
  });

  final int? companyId;
  final String companyName;
  final String? companyLogo;
  final String? paymentLogo;
  final String? cashierName;
  final String? companyMobile;
  final String? companyAddress;
  final String? shopName1;
  final String? shopName2;
  final String? addressLine1;
  final String? addressLine2;
  final String? addressLine3;
  final String? phoneNo1;
  final String? phoneNo2;
  final String? currencyName;
  final String? tableStatus;
  final String? noOfTable;
  final String? countryName;
  final String? stateName;
  final String? gstStatus;
  final String? gstNumber;
  final String? panNumber;
  final String? companyFssis;
  final String? shopCgst;
  final String? shopSgst;
  final String? openingMinutes;
  final String? closingMinutes;
  final String companyStatus;

  factory CompanyDto.fromJson(Map<String, dynamic> json) {
    return CompanyDto(
      companyId: parseInt(json['companyId']),
      companyName: parseString(json['companyName']) ?? '',
      companyLogo: parseString(json['companyLogo']),
      paymentLogo: parseString(json['paymentLogo']),
      cashierName: parseString(json['cashierName']),
      companyMobile: parseString(json['companyMobile']),
      companyAddress: parseString(json['companyAddress']),
      shopName1: parseString(json['shopName1']),
      shopName2: parseString(json['shopName2']),
      addressLine1: parseString(json['addressLine1']),
      addressLine2: parseString(json['addressLine2']),
      addressLine3: parseString(json['addressLine3']),
      phoneNo1: parseString(json['phoneNo1']),
      phoneNo2: parseString(json['phoneNo2']),
      currencyName: parseString(json['currencyName']),
      tableStatus: parseString(json['tableStatus']),
      noOfTable: parseString(json['noOfTable']),
      countryName: parseString(json['countryName']),
      stateName: parseString(json['stateName']),
      gstStatus: parseString(json['gstStatus']),
      gstNumber: parseString(json['gstNumber']),
      panNumber: parseString(json['panNumber']),
      companyFssis: parseString(json['companyFssis']),
      shopCgst: parseString(json['shopCGST']) ?? parseString(json['shopCgst']),
      shopSgst: parseString(json['shopSGST']) ?? parseString(json['shopSgst']),
      openingMinutes: parseString(json['openingMinutes']),
      closingMinutes: parseString(json['closingMinutes']),
      companyStatus: parseString(json['companyStatus']) ?? '1',
    );
  }

  Map<String, dynamic> toJson() => {
        'companyId': companyId,
        'companyName': companyName,
        'companyLogo': companyLogo,
        'paymentLogo': paymentLogo,
        'cashierName': cashierName,
        'companyMobile': companyMobile,
        'companyAddress': companyAddress,
        'shopName1': shopName1,
        'shopName2': shopName2,
        'addressLine1': addressLine1,
        'addressLine2': addressLine2,
        'addressLine3': addressLine3,
        'phoneNo1': phoneNo1,
        'phoneNo2': phoneNo2,
        'currencyName': currencyName,
        'tableStatus': tableStatus,
        'noOfTable': noOfTable,
        'countryName': countryName,
        'stateName': stateName,
        'gstStatus': gstStatus,
        'gstNumber': gstNumber,
        'panNumber': panNumber,
        'companyFssis': companyFssis,
        'shopCGST': shopCgst,
        'shopSGST': shopSgst,
        'openingMinutes': openingMinutes,
        'closingMinutes': closingMinutes,
        'companyStatus': companyStatus,
      };
}

class CompanyPrinterSettingDto {
  const CompanyPrinterSettingDto({
    this.settingId,
    this.printerName = '',
    this.kotPrinterName = '',
    this.invoicePrefix = 'PB',
    this.invoiceTitle = '',
    this.invoiceTermsCondition = '',
    this.logoUse = '0',
    this.paymentUse = '0',
    this.customerUse = '0',
    this.productQuantityUpdate = '0',
    this.duplicateBillUse = '0',
    this.bluetoothAddress = '',
    this.bluetoothKotAddress = '',
    this.printerFeedLines = '3',
    this.kotPrinterFeedLines = '3',
    this.kotEnable = '1',
    this.kotPrefix = 'KOT',
    this.kotCopies = '1',
    this.kotAutoPrint = '0',
    this.kotPreview = '1',
    this.settingStatus = '1',
  });

  final int? settingId;
  final String printerName;
  final String kotPrinterName;
  final String invoicePrefix;
  final String invoiceTitle;
  final String invoiceTermsCondition;
  final String logoUse;
  final String paymentUse;
  final String customerUse;
  final String productQuantityUpdate;
  final String duplicateBillUse;
  final String bluetoothAddress;
  final String bluetoothKotAddress;
  final String printerFeedLines;
  final String kotPrinterFeedLines;
  final String kotEnable;
  final String kotPrefix;
  final String kotCopies;
  final String kotAutoPrint;
  final String kotPreview;
  final String settingStatus;

  factory CompanyPrinterSettingDto.fromJson(Map<String, dynamic> json) {
    return CompanyPrinterSettingDto(
      settingId: parseInt(json['settingId']),
      printerName: parseString(json['printerName']) ?? '',
      kotPrinterName: parseString(json['KOTPrinterName']) ?? '',
      invoicePrefix: parseString(json['invoicePrefix']) ?? 'PB',
      invoiceTitle: parseString(json['invoiceTitle']) ?? '',
      invoiceTermsCondition: parseString(json['invoiceTermsCondition']) ?? '',
      logoUse: parseString(json['logoUse']) ?? '0',
      paymentUse: parseString(json['paymentUse']) ?? '0',
      customerUse: parseString(json['customerUse']) ?? '0',
      productQuantityUpdate: parseString(json['productQuantityUpdate']) ?? '0',
      duplicateBillUse: parseString(json['duplicateBillUse']) ?? '0',
      bluetoothAddress: parseString(json['bluetoothAddress']) ?? '',
      bluetoothKotAddress: parseString(json['bluetoothKOTAddress']) ?? '',
      printerFeedLines: parseString(json['printerFeedLines']) ?? '3',
      kotPrinterFeedLines: parseString(json['KotPrinterFeedLines']) ?? '3',
      kotEnable: parseString(json['kotEnable']) ?? '1',
      kotPrefix: parseString(json['kotPrefix']) ?? 'KOT',
      kotCopies: parseString(json['kotCopies']) ?? '1',
      kotAutoPrint: parseString(json['kotAutoPrint']) ?? '0',
      kotPreview: parseString(json['kotPreview']) ?? '1',
      settingStatus: parseString(json['settingStatus']) ?? '1',
    );
  }

  Map<String, dynamic> toJson() => {
        'settingId': settingId,
        'printerName': printerName,
        'KOTPrinterName': kotPrinterName,
        'invoicePrefix': invoicePrefix,
        'invoiceTitle': invoiceTitle,
        'invoiceTermsCondition': invoiceTermsCondition,
        'logoUse': logoUse,
        'paymentUse': paymentUse,
        'customerUse': customerUse,
        'productQuantityUpdate': productQuantityUpdate,
        'duplicateBillUse': duplicateBillUse,
        'bluetoothAddress': bluetoothAddress,
        'bluetoothKOTAddress': bluetoothKotAddress,
        'printerFeedLines': printerFeedLines,
        'KotPrinterFeedLines': kotPrinterFeedLines,
        'kotEnable': kotEnable,
        'kotPrefix': kotPrefix,
        'kotCopies': kotCopies,
        'kotAutoPrint': kotAutoPrint,
        'kotPreview': kotPreview,
        'settingStatus': settingStatus,
      };
}
