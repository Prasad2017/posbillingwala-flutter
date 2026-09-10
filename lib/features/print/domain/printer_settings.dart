import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// How the bill/KOT printer is reached. Works with any ESC/POS model.
enum PosPrinterTransport {
  bluetooth,
  usb,
  network,
}

extension PosPrinterTransportX on PosPrinterTransport {
  String get label {
    switch (this) {
      case PosPrinterTransport.bluetooth:
        return 'Bluetooth';
      case PosPrinterTransport.usb:
        return 'USB';
      case PosPrinterTransport.network:
        return 'Network';
    }
  }

  static PosPrinterTransport fromStorage(String? value) {
    switch (value) {
      case 'usb':
        return PosPrinterTransport.usb;
      case 'network':
        return PosPrinterTransport.network;
      case 'bluetooth':
      default:
        return PosPrinterTransport.bluetooth;
    }
  }

  String get storageValue {
    switch (this) {
      case PosPrinterTransport.bluetooth:
        return 'bluetooth';
      case PosPrinterTransport.usb:
        return 'usb';
      case PosPrinterTransport.network:
        return 'network';
    }
  }
}

class PrinterSettings {
  const PrinterSettings({
    this.paperSize = PrinterPaperSize.inch2,
    this.billTransport = PosPrinterTransport.bluetooth,
    this.kotTransport = PosPrinterTransport.bluetooth,
    this.billBluetoothAddress = '',
    this.kotBluetoothAddress = '',
    this.billUsbIdentifier = '',
    this.kotUsbIdentifier = '',
    this.billUsbName = '',
    this.kotUsbName = '',
    this.networkHost = '',
    this.networkPort = 9100,
    this.feedLines = 3,
    this.autoShareOnSave = true,
    this.invoiceTitle = '',
    this.invoiceTerms = '',
    this.invoicePrefix = 'PB',
    this.customerUse = false,
    this.paymentUse = false,
    this.duplicateBillUse = false,
    this.logoUse = false,
    this.kotEnable = true,
    this.productQuantityUpdate = true,
    this.kotAutoPrint = false,
    this.kotCopies = 1,
  });

  final PrinterPaperSize paperSize;
  final PosPrinterTransport billTransport;
  final PosPrinterTransport kotTransport;
  final String billBluetoothAddress;
  final String kotBluetoothAddress;
  /// Android USB id `vendorId:productId`, or desktop serial path.
  final String billUsbIdentifier;
  final String kotUsbIdentifier;
  final String billUsbName;
  final String kotUsbName;
  final String networkHost;
  final int networkPort;
  final int feedLines;
  final bool autoShareOnSave;
  final String invoiceTitle;
  final String invoiceTerms;
  final String invoicePrefix;
  final bool customerUse;
  final bool paymentUse;
  final bool duplicateBillUse;
  final bool logoUse;
  final bool kotEnable;
  final bool productQuantityUpdate;
  final bool kotAutoPrint;
  final int kotCopies;

  int get charsPerLine => paperSize == PrinterPaperSize.inch3 ? 48 : 32;

  PosPrinterTransport transportFor({required bool isKot}) =>
      isKot ? kotTransport : billTransport;

  String bluetoothFor({required bool isKot}) {
    if (isKot && kotBluetoothAddress.trim().isNotEmpty) {
      return kotBluetoothAddress.trim();
    }
    return billBluetoothAddress.trim();
  }

  String usbIdFor({required bool isKot}) {
    if (isKot && kotUsbIdentifier.trim().isNotEmpty) {
      return kotUsbIdentifier.trim();
    }
    return billUsbIdentifier.trim();
  }

  String usbNameFor({required bool isKot}) {
    if (isKot && kotUsbName.trim().isNotEmpty) {
      return kotUsbName.trim();
    }
    return billUsbName.trim();
  }

  PrinterSettings copyWith({
    PrinterPaperSize? paperSize,
    PosPrinterTransport? billTransport,
    PosPrinterTransport? kotTransport,
    String? billBluetoothAddress,
    String? kotBluetoothAddress,
    String? billUsbIdentifier,
    String? kotUsbIdentifier,
    String? billUsbName,
    String? kotUsbName,
    String? networkHost,
    int? networkPort,
    int? feedLines,
    bool? autoShareOnSave,
    String? invoiceTitle,
    String? invoiceTerms,
    String? invoicePrefix,
    bool? customerUse,
    bool? paymentUse,
    bool? duplicateBillUse,
    bool? logoUse,
    bool? kotEnable,
    bool? productQuantityUpdate,
    bool? kotAutoPrint,
    int? kotCopies,
  }) {
    return PrinterSettings(
      paperSize: paperSize ?? this.paperSize,
      billTransport: billTransport ?? this.billTransport,
      kotTransport: kotTransport ?? this.kotTransport,
      billBluetoothAddress:
          billBluetoothAddress ?? this.billBluetoothAddress,
      kotBluetoothAddress: kotBluetoothAddress ?? this.kotBluetoothAddress,
      billUsbIdentifier: billUsbIdentifier ?? this.billUsbIdentifier,
      kotUsbIdentifier: kotUsbIdentifier ?? this.kotUsbIdentifier,
      billUsbName: billUsbName ?? this.billUsbName,
      kotUsbName: kotUsbName ?? this.kotUsbName,
      networkHost: networkHost ?? this.networkHost,
      networkPort: networkPort ?? this.networkPort,
      feedLines: feedLines ?? this.feedLines,
      autoShareOnSave: autoShareOnSave ?? this.autoShareOnSave,
      invoiceTitle: invoiceTitle ?? this.invoiceTitle,
      invoiceTerms: invoiceTerms ?? this.invoiceTerms,
      invoicePrefix: invoicePrefix ?? this.invoicePrefix,
      customerUse: customerUse ?? this.customerUse,
      paymentUse: paymentUse ?? this.paymentUse,
      duplicateBillUse: duplicateBillUse ?? this.duplicateBillUse,
      logoUse: logoUse ?? this.logoUse,
      kotEnable: kotEnable ?? this.kotEnable,
      productQuantityUpdate:
          productQuantityUpdate ?? this.productQuantityUpdate,
      kotAutoPrint: kotAutoPrint ?? this.kotAutoPrint,
      kotCopies: kotCopies ?? this.kotCopies,
    );
  }
}

enum PrinterPaperSize { inch2, inch3 }

class PrinterSettingsStore {
  static const _paperKey = 'printer_paper_size';
  static const _billTransportKey = 'printer_bill_transport';
  static const _kotTransportKey = 'printer_kot_transport';
  static const _billMacKey = 'printer_bill_mac';
  static const _kotMacKey = 'printer_kot_mac';
  static const _billUsbKey = 'printer_bill_usb';
  static const _kotUsbKey = 'printer_kot_usb';
  static const _billUsbNameKey = 'printer_bill_usb_name';
  static const _kotUsbNameKey = 'printer_kot_usb_name';
  static const _hostKey = 'printer_network_host';
  static const _portKey = 'printer_network_port';
  static const _feedKey = 'printer_feed_lines';
  static const _autoShareKey = 'printer_auto_share';
  static const _invoiceTitleKey = 'printer_invoice_title';
  static const _invoiceTermsKey = 'printer_invoice_terms';
  static const _invoicePrefixKey = 'printer_invoice_prefix';
  static const _customerUseKey = 'printer_customer_use';
  static const _paymentUseKey = 'printer_payment_use';
  static const _duplicateKey = 'printer_duplicate_bill';
  static const _logoUseKey = 'printer_logo_use';
  static const _kotEnableKey = 'printer_kot_enable';
  static const _qtyUpdateKey = 'printer_qty_update';
  static const _kotAutoKey = 'printer_kot_auto';
  static const _kotCopiesKey = 'printer_kot_copies';

  Future<PrinterSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    final paper = prefs.getString(_paperKey) == '3-Inch'
        ? PrinterPaperSize.inch3
        : PrinterPaperSize.inch2;
    return PrinterSettings(
      paperSize: paper,
      billTransport:
          PosPrinterTransportX.fromStorage(prefs.getString(_billTransportKey)),
      kotTransport:
          PosPrinterTransportX.fromStorage(prefs.getString(_kotTransportKey)),
      billBluetoothAddress: prefs.getString(_billMacKey) ?? '',
      kotBluetoothAddress: prefs.getString(_kotMacKey) ?? '',
      billUsbIdentifier: prefs.getString(_billUsbKey) ?? '',
      kotUsbIdentifier: prefs.getString(_kotUsbKey) ?? '',
      billUsbName: prefs.getString(_billUsbNameKey) ?? '',
      kotUsbName: prefs.getString(_kotUsbNameKey) ?? '',
      networkHost: prefs.getString(_hostKey) ?? '',
      networkPort: prefs.getInt(_portKey) ?? 9100,
      feedLines: prefs.getInt(_feedKey) ?? 3,
      autoShareOnSave: prefs.getBool(_autoShareKey) ?? true,
      invoiceTitle: prefs.getString(_invoiceTitleKey) ?? '',
      invoiceTerms: prefs.getString(_invoiceTermsKey) ?? '',
      invoicePrefix: prefs.getString(_invoicePrefixKey) ?? 'PB',
      customerUse: prefs.getBool(_customerUseKey) ?? false,
      paymentUse: prefs.getBool(_paymentUseKey) ?? false,
      duplicateBillUse: prefs.getBool(_duplicateKey) ?? false,
      logoUse: prefs.getBool(_logoUseKey) ?? false,
      kotEnable: prefs.getBool(_kotEnableKey) ?? true,
      productQuantityUpdate: prefs.getBool(_qtyUpdateKey) ?? true,
      kotAutoPrint: prefs.getBool(_kotAutoKey) ?? false,
      kotCopies: prefs.getInt(_kotCopiesKey) ?? 1,
    );
  }

  Future<void> save(PrinterSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _paperKey,
      settings.paperSize == PrinterPaperSize.inch3 ? '3-Inch' : '2-Inch',
    );
    await prefs.setString(
      _billTransportKey,
      settings.billTransport.storageValue,
    );
    await prefs.setString(
      _kotTransportKey,
      settings.kotTransport.storageValue,
    );
    await prefs.setString(_billMacKey, settings.billBluetoothAddress.trim());
    await prefs.setString(_kotMacKey, settings.kotBluetoothAddress.trim());
    await prefs.setString(_billUsbKey, settings.billUsbIdentifier.trim());
    await prefs.setString(_kotUsbKey, settings.kotUsbIdentifier.trim());
    await prefs.setString(_billUsbNameKey, settings.billUsbName.trim());
    await prefs.setString(_kotUsbNameKey, settings.kotUsbName.trim());
    await prefs.setString(_hostKey, settings.networkHost.trim());
    await prefs.setInt(_portKey, settings.networkPort);
    await prefs.setInt(_feedKey, settings.feedLines);
    await prefs.setBool(_autoShareKey, settings.autoShareOnSave);
    await prefs.setString(_invoiceTitleKey, settings.invoiceTitle.trim());
    await prefs.setString(_invoiceTermsKey, settings.invoiceTerms.trim());
    await prefs.setString(
      _invoicePrefixKey,
      settings.invoicePrefix.trim().isEmpty ? 'PB' : settings.invoicePrefix.trim(),
    );
    await prefs.setBool(_customerUseKey, settings.customerUse);
    await prefs.setBool(_paymentUseKey, settings.paymentUse);
    await prefs.setBool(_duplicateKey, settings.duplicateBillUse);
    await prefs.setBool(_logoUseKey, settings.logoUse);
    await prefs.setBool(_kotEnableKey, settings.kotEnable);
    await prefs.setBool(_qtyUpdateKey, settings.productQuantityUpdate);
    await prefs.setBool(_kotAutoKey, settings.kotAutoPrint);
    await prefs.setInt(_kotCopiesKey, settings.kotCopies);
  }
}

final printerSettingsProvider =
    NotifierProvider<PrinterSettingsController, PrinterSettings>(
  PrinterSettingsController.new,
);

class PrinterSettingsController extends Notifier<PrinterSettings> {
  final _store = PrinterSettingsStore();

  @override
  PrinterSettings build() {
    Future.microtask(_reload);
    return const PrinterSettings();
  }

  Future<void> _reload() async {
    state = await _store.load();
  }

  Future<void> update(PrinterSettings settings) async {
    await _store.save(settings);
    state = settings;
  }
}
