import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pos_billingwala_v2/core/constants/app_colors.dart';
import 'package:pos_billingwala_v2/core/permissions/app_permission_service.dart';
import 'package:pos_billingwala_v2/features/auth/domain/auth_controller.dart';
import 'package:pos_billingwala_v2/features/company/data/company_api.dart';
import 'package:pos_billingwala_v2/features/company/data/company_dtos.dart';
import 'package:pos_billingwala_v2/features/print/domain/bluetooth_printer_hub.dart';
import 'package:pos_billingwala_v2/features/print/domain/esc_pos_transport_hub.dart';
import 'package:pos_billingwala_v2/features/print/domain/printer_settings.dart';
import 'package:pos_billingwala_v2/features/print/domain/shop_receipt_profile.dart';
import 'package:pos_billingwala_v2/features/print/presentation/printer_device_picker_page.dart';
import 'package:pos_billingwala_v2/core/widgtes/widgtes.dart';
import 'package:pos_billingwala_v2/core/widgets/app_module_icon.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  static const _permissions = AppPermissionService();

  late final TextEditingController _billMac;
  late final TextEditingController _kotMac;
  late final TextEditingController _host;
  late final TextEditingController _port;
  late final TextEditingController _feed;
  late final TextEditingController _invoiceTitle;
  late final TextEditingController _invoiceTerms;
  late final TextEditingController _invoicePrefix;
  late final TextEditingController _kotCopies;
  late final TextEditingController _companyName;
  late final TextEditingController _companyMobile;
  late final TextEditingController _companyAddress;
  late final TextEditingController _addressLine1;
  late final TextEditingController _addressLine2;
  late final TextEditingController _addressLine3;
  late final TextEditingController _gstNumber;
  late final TextEditingController _panNumber;
  late final TextEditingController _companyFssis;
  late final TextEditingController _currencyName;
  late final TextEditingController _countryName;
  late final TextEditingController _stateName;
  late final TextEditingController _noOfTable;
  late final TextEditingController _paymentLogo;
  late final TextEditingController _openingMinutes;
  late final TextEditingController _closingMinutes;
  bool _gstEnabled = false;
  bool _companyBusy = false;
  bool _permissionBusy = false;
  bool _btBusy = false;
  String _btStatus = 'Checking…';
  String _usbStatus = 'USB idle';
  Map<Permission, PermissionStatus> _permissionStatuses = const {};
  final _hub = BluetoothPrinterHub.instance;
  final _usbHub = EscPosTransportHub.instance;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(printerSettingsProvider);
    _billMac = TextEditingController(text: settings.billBluetoothAddress);
    _kotMac = TextEditingController(text: settings.kotBluetoothAddress);
    _host = TextEditingController(text: settings.networkHost);
    _port = TextEditingController(text: '${settings.networkPort}');
    _feed = TextEditingController(text: '${settings.feedLines}');
    _invoiceTitle = TextEditingController(text: settings.invoiceTitle);
    _invoiceTerms = TextEditingController(text: settings.invoiceTerms);
    _invoicePrefix = TextEditingController(text: settings.invoicePrefix);
    _kotCopies = TextEditingController(text: '${settings.kotCopies}');
    final shop = ref.read(authControllerProvider).session?.shopName ?? '';
    _companyName = TextEditingController(text: shop);
    _companyMobile = TextEditingController();
    _companyAddress = TextEditingController();
    _addressLine1 = TextEditingController();
    _addressLine2 = TextEditingController();
    _addressLine3 = TextEditingController();
    _gstNumber = TextEditingController();
    _panNumber = TextEditingController();
    _companyFssis = TextEditingController();
    _currencyName = TextEditingController(text: 'INR');
    _countryName = TextEditingController(text: 'India');
    _stateName = TextEditingController();
    _noOfTable = TextEditingController();
    _paymentLogo = TextEditingController();
    _openingMinutes = TextEditingController();
    _closingMinutes = TextEditingController();
    Future.microtask(() async {
      await _loadCompanyCloud();
      await _refreshPermissions();
      await _syncHubAndAutoConnect();
      await _refreshBtStatus();
    });
  }

  Future<void> _syncHubAndAutoConnect() async {
    final s = ref.read(printerSettingsProvider);
    _hub.updateSavedAddresses(
      billMac: s.billBluetoothAddress,
      kotMac: s.kotBluetoothAddress,
    );
    _usbHub.updateSavedUsb(
      identifier: s.billUsbIdentifier,
      name: s.billUsbName,
    );
    if (s.billTransport == PosPrinterTransport.bluetooth) {
      await _hub.autoConnect(PrinterChannelKind.bill);
    } else if (s.billTransport == PosPrinterTransport.usb &&
        s.billUsbIdentifier.isNotEmpty) {
      await _usbHub.connectUsb(
        identifier: s.billUsbIdentifier,
        name: s.billUsbName,
      );
    }
    if (s.kotTransport == PosPrinterTransport.bluetooth &&
        s.kotBluetoothAddress.trim().isNotEmpty &&
        s.kotBluetoothAddress.trim().toLowerCase() !=
            s.billBluetoothAddress.trim().toLowerCase()) {
      await _hub.autoConnect(PrinterChannelKind.kot);
    }
  }

  Future<void> _refreshBtStatus() async {
    final on = await _hub.isBluetoothOn();
    final linked = await _hub.connectionStatus();
    final usbLinked = _usbHub.isConnected;
    if (!mounted) return;
    setState(() {
      if (!on) {
        _btStatus = 'Bluetooth off';
      } else if (linked && _hub.connectedAddress.isNotEmpty) {
        _btStatus = 'BT connected: ${_hub.connectedAddress}';
      } else if (_hub.isConnecting) {
        _btStatus = 'Connectingâ€¦';
      } else {
        _btStatus = 'Bluetooth not connected';
      }
      if (usbLinked && _usbHub.savedUsbId.isNotEmpty) {
        _usbStatus =
            'USB connected: ${_usbHub.savedUsbName.isEmpty ? _usbHub.savedUsbId : _usbHub.savedUsbName}';
      } else if (_usbHub.savedUsbId.isNotEmpty) {
        _usbStatus = 'USB saved: ${_usbHub.savedUsbId}';
      } else {
        _usbStatus = 'USB not configured';
      }
    });
  }

  Future<void> _pickPrinter(PrinterChannelKind channel) async {
    final settings = ref.read(printerSettingsProvider);
    final initial = channel == PrinterChannelKind.bill
        ? settings.billTransport
        : settings.kotTransport;
    final picked = await Navigator.of(context).push<PickedPrinter>(
      MaterialPageRoute(
        builder: (_) => PrinterDevicePickerPage(
          channel: channel,
          initialTransport: initial,
        ),
      ),
    );
    if (picked == null || !mounted) return;

    if (channel == PrinterChannelKind.bill) {
      if (picked.transport == PosPrinterTransport.bluetooth) {
        _billMac.text = picked.bluetoothMac;
      }
      if (picked.transport == PosPrinterTransport.network) {
        _host.text = picked.networkHost;
        _port.text = '${picked.networkPort}';
      }
    } else {
      if (picked.transport == PosPrinterTransport.bluetooth) {
        _kotMac.text = picked.bluetoothMac;
      }
      if (picked.transport == PosPrinterTransport.network) {
        _host.text = picked.networkHost;
        _port.text = '${picked.networkPort}';
      }
    }

    final current = ref.read(printerSettingsProvider);
    final updated = channel == PrinterChannelKind.bill
        ? current.copyWith(
            billTransport: picked.transport,
            billBluetoothAddress:
                picked.transport == PosPrinterTransport.bluetooth
                    ? picked.bluetoothMac
                    : current.billBluetoothAddress,
            billUsbIdentifier: picked.transport == PosPrinterTransport.usb
                ? picked.usbIdentifier
                : current.billUsbIdentifier,
            billUsbName: picked.transport == PosPrinterTransport.usb
                ? picked.usbName
                : current.billUsbName,
            networkHost: picked.transport == PosPrinterTransport.network
                ? picked.networkHost
                : current.networkHost,
            networkPort: picked.transport == PosPrinterTransport.network
                ? picked.networkPort
                : current.networkPort,
          )
        : current.copyWith(
            kotTransport: picked.transport,
            kotBluetoothAddress:
                picked.transport == PosPrinterTransport.bluetooth
                    ? picked.bluetoothMac
                    : current.kotBluetoothAddress,
            kotUsbIdentifier: picked.transport == PosPrinterTransport.usb
                ? picked.usbIdentifier
                : current.kotUsbIdentifier,
            kotUsbName: picked.transport == PosPrinterTransport.usb
                ? picked.usbName
                : current.kotUsbName,
            networkHost: picked.transport == PosPrinterTransport.network
                ? picked.networkHost
                : current.networkHost,
            networkPort: picked.transport == PosPrinterTransport.network
                ? picked.networkPort
                : current.networkPort,
          );
    await ref.read(printerSettingsProvider.notifier).update(updated);
    _hub.updateSavedAddresses(
      billMac: updated.billBluetoothAddress,
      kotMac: updated.kotBluetoothAddress,
    );
    _usbHub.updateSavedUsb(
      identifier: updated.usbIdFor(isKot: channel == PrinterChannelKind.kot),
      name: updated.usbNameFor(isKot: channel == PrinterChannelKind.kot),
    );
    await _refreshBtStatus();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${picked.transport.label} printer selected',
        ),
      ),
    );
  }

  Future<void> _connectChannel(PrinterChannelKind channel) async {
    setState(() => _btBusy = true);
    try {
      await _save(showSnack: false);
      final settings = ref.read(printerSettingsProvider);
      final transport = channel == PrinterChannelKind.bill
          ? settings.billTransport
          : settings.kotTransport;

      var ok = false;
      switch (transport) {
        case PosPrinterTransport.bluetooth:
          final mac = channel == PrinterChannelKind.bill
              ? _billMac.text.trim()
              : _kotMac.text.trim();
          if (mac.isEmpty) {
            await _pickPrinter(channel);
            return;
          }
          ok = await _hub.connect(channel, address: mac, fromUser: true);
        case PosPrinterTransport.usb:
          final id = settings.usbIdFor(
            isKot: channel == PrinterChannelKind.kot,
          );
          if (id.isEmpty) {
            await _pickPrinter(channel);
            return;
          }
          ok = await _usbHub.connectUsb(
            identifier: id,
            name: settings.usbNameFor(
              isKot: channel == PrinterChannelKind.kot,
            ),
          );
        case PosPrinterTransport.network:
          ok = settings.networkHost.trim().isNotEmpty;
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ok
                ? '${transport.label} printer ready'
                : 'Connect failed â€” pick a printer',
          ),
        ),
      );
      if (!ok) await _pickPrinter(channel);
      await _refreshBtStatus();
    } finally {
      if (mounted) setState(() => _btBusy = false);
    }
  }

  Future<void> _disconnectChannel(PrinterChannelKind channel) async {
    setState(() => _btBusy = true);
    try {
      final settings = ref.read(printerSettingsProvider);
      final transport = channel == PrinterChannelKind.bill
          ? settings.billTransport
          : settings.kotTransport;
      if (transport == PosPrinterTransport.usb) {
        await _usbHub.clearSavedUsb();
      } else {
        await _hub.disconnect(channel);
      }
      if (channel == PrinterChannelKind.bill) {
        _billMac.clear();
        await ref.read(printerSettingsProvider.notifier).update(
              settings.copyWith(
                billBluetoothAddress: '',
                billUsbIdentifier: '',
                billUsbName: '',
              ),
            );
      } else {
        _kotMac.clear();
        await ref.read(printerSettingsProvider.notifier).update(
              settings.copyWith(
                kotBluetoothAddress: '',
                kotUsbIdentifier: '',
                kotUsbName: '',
              ),
            );
      }
      await _refreshBtStatus();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Printer disconnected')),
      );
    } finally {
      if (mounted) setState(() => _btBusy = false);
    }
  }

  Future<void> _openTestPreview(PrinterChannelKind channel) async {
    await _save(showSnack: false);
    if (!mounted) return;
    final mode =
        channel == PrinterChannelKind.kot ? 'kot' : 'invoice';
    await context.push('/settings/test-print?mode=$mode');
    if (!mounted) return;
    await _refreshBtStatus();
  }

  Future<void> _refreshPermissions() async {
    final statuses = await _permissions.checkAll();
    if (!mounted) return;
    setState(() => _permissionStatuses = statuses);
  }

  Future<void> _requestPermissions() async {
    setState(() => _permissionBusy = true);
    try {
      final statuses = await _permissions.requestAll();
      final blocked = statuses.values.any((s) => s.isPermanentlyDenied);
      if (!mounted) return;
      setState(() {
        _permissionStatuses = statuses;
        _permissionBusy = false;
      });
      if (blocked) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Some permissions are blocked. Open system settings to enable them.',
            ),
            action: SnackBarAction(
              label: 'Open',
              onPressed: _permissions.openAppSettingsPage,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permissions updated')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _permissionBusy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Permission request failed: $e')),
      );
    }
  }

  @override
  void dispose() {
    _billMac.dispose();
    _kotMac.dispose();
    _host.dispose();
    _port.dispose();
    _feed.dispose();
    _invoiceTitle.dispose();
    _invoiceTerms.dispose();
    _invoicePrefix.dispose();
    _kotCopies.dispose();
    _companyName.dispose();
    _companyMobile.dispose();
    _companyAddress.dispose();
    _addressLine1.dispose();
    _addressLine2.dispose();
    _addressLine3.dispose();
    _gstNumber.dispose();
    _panNumber.dispose();
    _companyFssis.dispose();
    _currencyName.dispose();
    _countryName.dispose();
    _stateName.dispose();
    _noOfTable.dispose();
    _paymentLogo.dispose();
    _openingMinutes.dispose();
    _closingMinutes.dispose();
    super.dispose();
  }

  void _applyCompanyDto(CompanyDto c) {
    _companyName.text = c.companyName;
    _companyMobile.text = c.companyMobile ?? '';
    _companyAddress.text = c.companyAddress ?? '';
    _addressLine1.text = c.addressLine1 ?? '';
    _addressLine2.text = c.addressLine2 ?? '';
    _addressLine3.text = c.addressLine3 ?? '';
    _gstEnabled = c.gstStatus == '1' || c.gstStatus?.toLowerCase() == 'true';
    _gstNumber.text = c.gstNumber ?? '';
    _panNumber.text = c.panNumber ?? '';
    _companyFssis.text = c.companyFssis ?? '';
    _currencyName.text = c.currencyName ?? 'INR';
    _countryName.text = c.countryName ?? 'India';
    _stateName.text = c.stateName ?? '';
    _noOfTable.text = c.noOfTable ?? '';
    _paymentLogo.text = c.paymentLogo ?? '';
    _openingMinutes.text = c.openingMinutes ?? '';
    _closingMinutes.text = c.closingMinutes ?? '';
  }

  CompanyDto _buildCompanyDto() {
    return CompanyDto(
      companyName: _companyName.text.trim(),
      companyMobile: _companyMobile.text.trim(),
      companyAddress: _companyAddress.text.trim(),
      addressLine1: _addressLine1.text.trim(),
      addressLine2: _addressLine2.text.trim(),
      addressLine3: _addressLine3.text.trim(),
      gstStatus: _gstEnabled ? '1' : '0',
      gstNumber: _gstNumber.text.trim(),
      panNumber: _panNumber.text.trim(),
      companyFssis: _companyFssis.text.trim(),
      currencyName: _currencyName.text.trim(),
      countryName: _countryName.text.trim(),
      stateName: _stateName.text.trim(),
      noOfTable: _noOfTable.text.trim(),
      paymentLogo: _paymentLogo.text.trim(),
      openingMinutes: _openingMinutes.text.trim(),
      closingMinutes: _closingMinutes.text.trim(),
    );
  }

  Future<void> _loadCompanyCloud() async {
    final userId = ref.read(authControllerProvider).session?.userId;
    if (userId == null || userId.isEmpty) return;
    setState(() => _companyBusy = true);
    try {
      final api = CompanyApi(ref.read(apiClientProvider));
      final companies = await api.getCompanyList(userId);
      if (companies.isNotEmpty) {
        setState(() => _applyCompanyDto(companies.first));
        await ref
            .read(shopReceiptProfileProvider.notifier)
            .saveFromCompany(companies.first);
      }
      final printers = await api.getCompanyPrinterSetting(userId);
      if (printers.isNotEmpty) {
        final p = printers.first;
        final current = ref.read(printerSettingsProvider);
        final updated = current.copyWith(
          billBluetoothAddress: p.bluetoothAddress.isNotEmpty
              ? p.bluetoothAddress
              : current.billBluetoothAddress,
          kotBluetoothAddress: p.bluetoothKotAddress.isNotEmpty
              ? p.bluetoothKotAddress
              : current.kotBluetoothAddress,
          feedLines: int.tryParse(p.printerFeedLines) ?? current.feedLines,
          invoiceTitle: p.invoiceTitle.isNotEmpty
              ? p.invoiceTitle
              : current.invoiceTitle,
          invoiceTerms: p.invoiceTermsCondition.isNotEmpty
              ? p.invoiceTermsCondition
              : current.invoiceTerms,
          customerUse: p.customerUse == '1',
          paymentUse: p.paymentUse == '1',
          duplicateBillUse: p.duplicateBillUse == '1',
          logoUse: p.logoUse == '1',
          kotEnable: p.kotEnable != '0',
          productQuantityUpdate: p.productQuantityUpdate == '1',
          kotAutoPrint: p.kotAutoPrint == '1',
          kotCopies: int.tryParse(p.kotCopies) ?? current.kotCopies,
          invoicePrefix: p.invoicePrefix.isNotEmpty
              ? p.invoicePrefix
              : current.invoicePrefix,
        );
        await ref.read(printerSettingsProvider.notifier).update(updated);
        _billMac.text = updated.billBluetoothAddress;
        _kotMac.text = updated.kotBluetoothAddress;
        _feed.text = '${updated.feedLines}';
        _invoiceTitle.text = updated.invoiceTitle;
        _invoiceTerms.text = updated.invoiceTerms;
        _invoicePrefix.text = updated.invoicePrefix;
        _kotCopies.text = '${updated.kotCopies}';
        _hub.updateSavedAddresses(
          billMac: updated.billBluetoothAddress,
          kotMac: updated.kotBluetoothAddress,
        );
        await _hub.autoConnect(PrinterChannelKind.bill);
      }
    } catch (_) {
      // Keep local fields if cloud load fails.
    } finally {
      if (mounted) setState(() => _companyBusy = false);
    }
  }

  Future<void> _saveCompanyCloud() async {
    final userId = ref.read(authControllerProvider).session?.userId;
    if (userId == null || userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login first')),
      );
      return;
    }
    setState(() => _companyBusy = true);
    try {
      final api = CompanyApi(ref.read(apiClientProvider));
      final companyDto = _buildCompanyDto();
      final ok = await api.insertCompanyDetail(
        userId: userId,
        company: companyDto,
      );
      await ref
          .read(shopReceiptProfileProvider.notifier)
          .saveFromCompany(companyDto);
      await _save(showSnack: false);
      final settings = ref.read(printerSettingsProvider);
      final printerOk = await api.insertCompanyPrinterSetting(
        userId: userId,
        setting: CompanyPrinterSettingDto(
          bluetoothAddress: settings.billBluetoothAddress,
          bluetoothKotAddress: settings.kotBluetoothAddress,
          printerFeedLines: '${settings.feedLines}',
          kotPrinterFeedLines: '${settings.feedLines}',
          invoiceTitle: settings.invoiceTitle,
          invoiceTermsCondition: settings.invoiceTerms,
          invoicePrefix: settings.invoicePrefix,
          customerUse: settings.customerUse ? '1' : '0',
          paymentUse: settings.paymentUse ? '1' : '0',
          duplicateBillUse: settings.duplicateBillUse ? '1' : '0',
          logoUse: settings.logoUse ? '1' : '0',
          kotEnable: settings.kotEnable ? '1' : '0',
          productQuantityUpdate: settings.productQuantityUpdate ? '1' : '0',
          kotAutoPrint: settings.kotAutoPrint ? '1' : '0',
          kotCopies: '${settings.kotCopies}',
        ),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ok && printerOk
                ? 'Company & printer settings saved to cloud'
                : 'Cloud save finished with issues',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    } finally {
      if (mounted) setState(() => _companyBusy = false);
    }
  }

  Future<void> _save({bool showSnack = true}) async {
    final current = ref.read(printerSettingsProvider);
    final feed = int.tryParse(_feed.text.trim()) ?? current.feedLines;
    final port = int.tryParse(_port.text.trim()) ?? current.networkPort;
    final copies = int.tryParse(_kotCopies.text.trim()) ?? current.kotCopies;
    final updated = current.copyWith(
      billBluetoothAddress: _billMac.text.trim(),
      kotBluetoothAddress: _kotMac.text.trim(),
      networkHost: _host.text.trim(),
      networkPort: port.clamp(1, 65535),
      feedLines: feed.clamp(1, 10),
      invoiceTitle: _invoiceTitle.text.trim(),
      invoiceTerms: _invoiceTerms.text.trim(),
      invoicePrefix: _invoicePrefix.text.trim().isEmpty
          ? 'PB'
          : _invoicePrefix.text.trim(),
      kotCopies: copies.clamp(1, 5),
    );
    await ref.read(printerSettingsProvider.notifier).update(updated);
    _hub.updateSavedAddresses(
      billMac: updated.billBluetoothAddress,
      kotMac: updated.kotBluetoothAddress,
    );
    if (!mounted) return;
    if (showSnack) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Printer settings saved')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(printerSettingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shop & Printer'),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
            Container(margin: const EdgeInsets.fromLTRB(16, 10, 16, 18), padding: const EdgeInsets.all(16), decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryDark]), borderRadius: BorderRadius.circular(22)), child: const Row(children: [AppModuleIcon(icon: Icons.tune_rounded, color: Colors.white, size: 52), SizedBox(width: 12), Expanded(child: Text('Configure your POS your way', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 17)))])),
          Text(
            'Company',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 8),
          AppCard(
            child: Column(
              children: [
                AppTextField(
                  controller: _companyName,
                  label: 'Company / shop name',
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: _companyMobile,
                  label: 'Mobile',
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: _companyAddress,
                  label: 'Address',
                  maxLines: 2,
                  minLines: 2,
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: _addressLine1,
                  label: 'Address line 1',
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: _addressLine2,
                  label: 'Address line 2',
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: _addressLine3,
                  label: 'Address line 3',
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('GST registered'),
                  value: _gstEnabled,
                  onChanged: (v) => setState(() => _gstEnabled = v),
                ),
                if (_gstEnabled) ...[
                  AppTextField(
                    controller: _gstNumber,
                    label: 'GST number',
                  ),
                  const SizedBox(height: 12),
                ],
                AppTextField(
                  controller: _panNumber,
                  label: 'PAN number',
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: _companyFssis,
                  label: 'FSSAI',
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: _paymentLogo,
                  label: 'UPI ID / payment logo text',
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        controller: _currencyName,
                        label: 'Currency',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: AppTextField(
                        controller: _noOfTable,
                        label: 'No. of tables',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        controller: _countryName,
                        label: 'Country',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: AppTextField(
                        controller: _stateName,
                        label: 'State',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        controller: _openingMinutes,
                        label: 'Opening (HH:mm or minutes)',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: AppTextField(
                        controller: _closingMinutes,
                        label: 'Closing (HH:mm or minutes)',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        label: 'Load',
                        icon: Icons.cloud_download_rounded,
                        variant: AppButtonVariant.outlined,
                        isLoading: _companyBusy,
                        onPressed: _loadCompanyCloud,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: AppButton(
                        label: 'Save cloud',
                        icon: Icons.cloud_upload_rounded,
                        isLoading: _companyBusy,
                        onPressed: _saveCompanyCloud,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'App permissions',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 8),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Needed for Bluetooth print, nearby printers, QR camera, and location discovery.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 8),
                if (_permissionStatuses.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text('Checking permissions…'),
                  )
                else
                  ..._permissionStatuses.entries.map((entry) {
                    final allowed = entry.value.isGranted ||
                        entry.value.isLimited ||
                        entry.value.isProvisional;
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      leading: Icon(
                        allowed
                            ? Icons.check_circle_rounded
                            : Icons.error_outline_rounded,
                        color: allowed ? Colors.green : Colors.orange,
                      ),
                      title: Text(_permissions.labelFor(entry.key)),
                      trailing: Text(
                        _permissions.statusLabel(entry.value),
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: allowed ? Colors.green : Colors.orange,
                        ),
                      ),
                    );
                  }),
                const SizedBox(height: 8),
                AppButton(
                  label: 'Allow location, camera, Bluetooth',
                  icon: Icons.security_rounded,
                  isLoading: _permissionBusy,
                  onPressed: _requestPermissions,
                ),
                TextButton(
                  onPressed: _permissions.openAppSettingsPage,
                  child: const Text('Open system app settings'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Printer',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 8),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Paper size',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                SegmentedButton<PrinterPaperSize>(
                  segments: const [
                    ButtonSegment(
                      value: PrinterPaperSize.inch2,
                      label: Text('2-Inch'),
                    ),
                    ButtonSegment(
                      value: PrinterPaperSize.inch3,
                      label: Text('3-Inch'),
                    ),
                  ],
                  selected: {settings.paperSize},
                  onSelectionChanged: (value) {
                    ref.read(printerSettingsProvider.notifier).update(
                          settings.copyWith(paperSize: value.first),
                        );
                  },
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.print_rounded),
                  title: const Text('Connection status'),
                  subtitle: Text('$_btStatus\n$_usbStatus'),
                  isThreeLine: true,
                  trailing: IconButton(
                    tooltip: 'Refresh',
                    onPressed: _btBusy ? null : _refreshBtStatus,
                    icon: const Icon(Icons.refresh_rounded),
                  ),
                ),
                Text(
                  'Bill printer: ${settings.billTransport.label}'
                  '${settings.billTransport == PosPrinterTransport.usb && settings.billUsbName.isNotEmpty ? ' · ${settings.billUsbName}' : ''}'
                  '${settings.billTransport == PosPrinterTransport.bluetooth && settings.billBluetoothAddress.isNotEmpty ? ' · ${settings.billBluetoothAddress}' : ''}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    AppButton(
                      label: 'Pick bill (BT / USB / Net)',
                      icon: Icons.devices_rounded,
                      expanded: false,
                      onPressed: _btBusy
                          ? null
                          : () => _pickPrinter(PrinterChannelKind.bill),
                    ),
                    AppButton(
                      label: 'Connect',
                      variant: AppButtonVariant.outlined,
                      expanded: false,
                      onPressed: _btBusy
                          ? null
                          : () => _connectChannel(PrinterChannelKind.bill),
                    ),
                    AppButton(
                      label: 'Test',
                      variant: AppButtonVariant.outlined,
                      expanded: false,
                      onPressed: _btBusy
                          ? null
                          : () => _openTestPreview(PrinterChannelKind.bill),
                    ),
                    TextButton(
                      onPressed: _btBusy
                          ? null
                          : () => _disconnectChannel(PrinterChannelKind.bill),
                      child: const Text('Disconnect'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'KOT printer: ${settings.kotTransport.label}'
                  '${settings.kotTransport == PosPrinterTransport.usb && settings.kotUsbName.isNotEmpty ? ' · ${settings.kotUsbName}' : ''}'
                  '${settings.kotTransport == PosPrinterTransport.bluetooth && settings.kotBluetoothAddress.isNotEmpty ? ' · ${settings.kotBluetoothAddress}' : ''}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    AppButton(
                      label: 'Pick KOT (BT / USB / Net)',
                      icon: Icons.devices_rounded,
                      expanded: false,
                      onPressed: _btBusy
                          ? null
                          : () => _pickPrinter(PrinterChannelKind.kot),
                    ),
                    AppButton(
                      label: 'Connect',
                      variant: AppButtonVariant.outlined,
                      expanded: false,
                      onPressed: _btBusy
                          ? null
                          : () => _connectChannel(PrinterChannelKind.kot),
                    ),
                    AppButton(
                      label: 'Test',
                      variant: AppButtonVariant.outlined,
                      expanded: false,
                      onPressed: _btBusy
                          ? null
                          : () => _openTestPreview(PrinterChannelKind.kot),
                    ),
                    TextButton(
                      onPressed: _btBusy
                          ? null
                          : () => _disconnectChannel(PrinterChannelKind.kot),
                      child: const Text('Disconnect'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: _billMac,
                  label: 'Bill Bluetooth MAC (optional manual)',
                  hint: 'AA:BB:CC:DD:EE:FF',
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: _kotMac,
                  label: 'KOT Bluetooth MAC (optional)',
                  hint: 'Uses bill printer if empty',
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: _host,
                  label: 'Network printer IP (optional)',
                  hint: '192.168.1.50',
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: _port,
                  label: 'Network port',
                  hint: '9100',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: _feed,
                  label: 'Feed lines after print',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: _invoiceTitle,
                  label: 'Invoice title',
                  hint: 'TAX INVOICE',
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: _invoiceTerms,
                  label: 'Invoice terms',
                  maxLines: 2,
                  minLines: 2,
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Share / print prompt after save'),
                  value: settings.autoShareOnSave,
                  onChanged: (value) {
                    ref.read(printerSettingsProvider.notifier).update(
                          settings.copyWith(autoShareOnSave: value),
                        );
                  },
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Ask customer name / mobile'),
                  subtitle: const Text('Shows fields on payment screen'),
                  value: settings.customerUse,
                  onChanged: (value) {
                    ref.read(printerSettingsProvider.notifier).update(
                          settings.copyWith(customerUse: value),
                        );
                  },
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('UPI QR on bill'),
                  subtitle: const Text(
                    'Uses UPI ID from company Payment Logo field',
                  ),
                  value: settings.paymentUse,
                  onChanged: (value) {
                    ref.read(printerSettingsProvider.notifier).update(
                          settings.copyWith(paymentUse: value),
                        );
                  },
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Print shop logo on bill'),
                  value: settings.logoUse,
                  onChanged: (value) {
                    ref.read(printerSettingsProvider.notifier).update(
                          settings.copyWith(logoUse: value),
                        );
                  },
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Auto print duplicate bill'),
                  value: settings.duplicateBillUse,
                  onChanged: (value) {
                    ref.read(printerSettingsProvider.notifier).update(
                          settings.copyWith(duplicateBillUse: value),
                        );
                  },
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Enable KOT'),
                  value: settings.kotEnable,
                  onChanged: (value) {
                    ref.read(printerSettingsProvider.notifier).update(
                          settings.copyWith(kotEnable: value),
                        );
                  },
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Update stock on sale'),
                  subtitle: const Text('Deduct inventory when bill is saved'),
                  value: settings.productQuantityUpdate,
                  onChanged: (value) {
                    ref.read(printerSettingsProvider.notifier).update(
                          settings.copyWith(productQuantityUpdate: value),
                        );
                  },
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Auto print KOT'),
                  subtitle: const Text('Skip preview and print immediately'),
                  value: settings.kotAutoPrint,
                  onChanged: (value) {
                    ref.read(printerSettingsProvider.notifier).update(
                          settings.copyWith(kotAutoPrint: value),
                        );
                  },
                ),
                AppTextField(
                  controller: _kotCopies,
                  label: 'KOT copies',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: _invoicePrefix,
                  label: 'Invoice prefix',
                  hint: 'PB',
                ),
                const SizedBox(height: 8),
                Text(
                  'Any ESC/POS thermal printer works: Bluetooth, USB OTG '
                  '(Printer Class / FTDI / CP210x / CH34x), or Wi‑Fi network. '
                  'Print uses bitmap so every language and ₹ work on all models.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppCard(
            color: AppColors.primaryLight,
            padding: EdgeInsets.zero,
            child: const ListTile(
              leading: Icon(Icons.info_outline, color: AppColors.primary),
              title: Text('Business profile'),
              subtitle: Text(
                'Use Company section above to load/save shop details to cloud.',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

