import 'package:flutter/material.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:pos_billingwala_v2/core/permissions/app_permission_service.dart';
import 'package:pos_billingwala_v2/features/print/domain/bluetooth_printer_hub.dart';
import 'package:pos_billingwala_v2/features/print/domain/esc_pos_transport_hub.dart';
import 'package:pos_billingwala_v2/features/print/domain/printer_settings.dart';
import 'package:unified_esc_pos_printer/unified_esc_pos_printer.dart' as esc;
import 'package:pos_billingwala_v2/core/widgtes/widgtes.dart';
import 'package:pos_billingwala_v2/core/constants/app_colors.dart';
import 'package:pos_billingwala_v2/core/widgets/app_module_icon.dart';

/// Result returned when the user picks a printer for bill/KOT.
class PickedPrinter {
  const PickedPrinter({
    required this.transport,
    this.bluetoothMac = '',
    this.bluetoothName = '',
    this.usbIdentifier = '',
    this.usbName = '',
    this.networkHost = '',
    this.networkPort = 9100,
  });

  final PosPrinterTransport transport;
  final String bluetoothMac;
  final String bluetoothName;
  final String usbIdentifier;
  final String usbName;
  final String networkHost;
  final int networkPort;
}

/// Pick any ESC/POS printer: Bluetooth (paired), USB (OTG), or Network.
class PrinterDevicePickerPage extends StatefulWidget {
  const PrinterDevicePickerPage({
    super.key,
    required this.channel,
    this.initialTransport = PosPrinterTransport.bluetooth,
  });

  final PrinterChannelKind channel;
  final PosPrinterTransport initialTransport;

  @override
  State<PrinterDevicePickerPage> createState() =>
      _PrinterDevicePickerPageState();
}

class _PrinterDevicePickerPageState extends State<PrinterDevicePickerPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final _btHub = BluetoothPrinterHub.instance;
  final _usbHub = EscPosTransportHub.instance;
  final _permissions = const AppPermissionService();
  final _hostCtrl = TextEditingController();
  final _portCtrl = TextEditingController(text: '9100');

  bool _loading = false;
  String? _error;
  List<BluetoothInfo> _btDevices = const [];
  List<esc.PrinterDevice> _usbDevices = const [];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTransport.index.clamp(0, 2),
    );
    _tabs.addListener(() {
      if (!_tabs.indexIsChanging) _loadCurrentTab();
    });
    _loadCurrentTab();
  }

  @override
  void dispose() {
    _tabs.dispose();
    _hostCtrl.dispose();
    _portCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentTab() async {
    final index = _tabs.index;
    if (index == 0) {
      await _loadBluetooth();
    } else if (index == 1) {
      await _loadUsb();
    }
  }

  Future<void> _loadBluetooth() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final allowed = await _permissions.ensurePrintPermissions();
      if (!allowed) {
        setState(() {
          _loading = false;
          _error =
              'Allow Bluetooth / nearby devices / location to list printers.';
        });
        return;
      }
      if (!await _btHub.isBluetoothOn()) {
        setState(() {
          _loading = false;
          _error = 'Turn on Bluetooth and try again.';
        });
        return;
      }
      final list = await _btHub.pairedDevices();
      if (!mounted) return;
      setState(() {
        _btDevices = list;
        _loading = false;
        if (list.isEmpty) {
          _error =
              'No paired Bluetooth printers. Pair any ESC/POS thermal printer in system Bluetooth settings, then refresh.';
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = '$e';
      });
    }
  }

  Future<void> _loadUsb() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await _usbHub.scanUsb();
      if (!mounted) return;
      setState(() {
        _usbDevices = list;
        _loading = false;
        if (list.isEmpty) {
          _error =
              'No USB printers found. Connect any ESC/POS USB/OTG printer (Printer Class or USB-serial), grant USB permission, then refresh.';
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = '$e';
      });
    }
  }

  Future<void> _selectBluetooth(BluetoothInfo device) async {
    final ok = await _btHub.connect(
      widget.channel,
      address: device.macAdress,
      fromUser: true,
    );
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not connect to ${device.name}')),
      );
      return;
    }
    Navigator.pop(
      context,
      PickedPrinter(
        transport: PosPrinterTransport.bluetooth,
        bluetoothMac: device.macAdress,
        bluetoothName: device.name,
      ),
    );
  }

  Future<void> _selectUsb(esc.PrinterDevice device) async {
    final ok = await _usbHub.connectDevice(device);
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not connect to ${device.name}. Accept the USB permission dialog if shown.',
          ),
        ),
      );
      return;
    }
    final usb = device as esc.UsbPrinterDevice;
    Navigator.pop(
      context,
      PickedPrinter(
        transport: PosPrinterTransport.usb,
        usbIdentifier: usb.identifier,
        usbName: usb.name,
      ),
    );
  }

  void _selectNetwork() {
    final host = _hostCtrl.text.trim();
    final port = int.tryParse(_portCtrl.text.trim()) ?? 9100;
    if (host.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter printer IP / host')),
      );
      return;
    }
    Navigator.pop(
      context,
      PickedPrinter(
        transport: PosPrinterTransport.network,
        networkHost: host,
        networkPort: port.clamp(1, 65535),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.channel == PrinterChannelKind.bill
        ? 'Select bill printer'
        : 'Select KOT printer';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'Bluetooth'),
            Tab(text: 'USB'),
            Tab(text: 'Network'),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loading ? null : _loadCurrentTab,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: Column(children: [
        Container(margin: const EdgeInsets.fromLTRB(16, 12, 16, 0), padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: .08), borderRadius: BorderRadius.circular(20)), child: const Row(children: [AppModuleIcon(icon: Icons.print_connect_rounded, color: AppColors.primary, size: 48), SizedBox(width: 12), Expanded(child: Text('Connect your billing printer', style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.navy)))])),
        Expanded(child: TabBarView(
        controller: _tabs,
        children: [
          _deviceList(
            loading: _loading && _tabs.index == 0,
            error: _tabs.index == 0 ? _error : null,
            emptyAction: _loadBluetooth,
            children: _btDevices
                .map(
                  (d) => ListTile(
                    leading: const Icon(Icons.bluetooth_rounded),
                    title: Text(d.name.isEmpty ? 'Bluetooth printer' : d.name),
                    subtitle: Text(d.macAdress),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => _selectBluetooth(d),
                  ),
                )
                .toList(),
          ),
          _deviceList(
            loading: _loading && _tabs.index == 1,
            error: _tabs.index == 1 ? _error : null,
            emptyAction: _loadUsb,
            children: _usbDevices
                .map(
                  (d) => ListTile(
                    leading: const Icon(Icons.usb_rounded),
                    title: Text(d.name.isEmpty ? 'USB printer' : d.name),
                    subtitle: Text(
                      d is esc.UsbPrinterDevice
                          ? d.identifier
                          : d.connectionType.name,
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => _selectUsb(d),
                  ),
                )
                .toList(),
          ),
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Works with any Wiâ€‘Fi / LAN ESC/POS printer on port 9100 (or custom).',
              ),
              const SizedBox(height: 16),
              AppTextField(
                      controller: _hostCtrl,
                      label: 'IP / host',
                      hint: '192.168.1.50',
                    ),
              const SizedBox(height: 12),
              AppTextField(
                      controller: _portCtrl,
                      label: 'Port',
                      hint: '9100',
                      keyboardType: TextInputType.number,
                    ),
              const SizedBox(height: 16),
              AppButton(
            label: 'Use this network printer',
            icon: Icons.wifi_rounded,
            onPressed: _selectNetwork,
            expanded: false,
          ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _deviceList({
    required bool loading,
    required String? error,
    required Future<void> Function() emptyAction,
    required List<Widget> children,
  }) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (children.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              error ?? 'No devices found',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            AppButton(
            label: 'Retry',
            icon: Icons.refresh_rounded,
            onPressed: emptyAction,
            expanded: false,
          ),
          ],
        ),
      );
    }
    return ListView.separated(
      itemCount: children.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) => children[index],
    );
  }
}
