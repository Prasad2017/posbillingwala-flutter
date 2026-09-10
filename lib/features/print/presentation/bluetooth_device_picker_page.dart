import 'package:flutter/material.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:pos_billingwala_v2/core/permissions/app_permission_service.dart';
import 'package:pos_billingwala_v2/features/print/domain/bluetooth_printer_hub.dart';
import 'package:pos_billingwala_v2/core/widgtes/widgtes.dart';

/// Paired Bluetooth device list â€” same role as Android [DeviceListActivity].
class BluetoothDevicePickerPage extends StatefulWidget {
  const BluetoothDevicePickerPage({
    super.key,
    required this.channel,
    this.title,
  });

  final PrinterChannelKind channel;
  final String? title;

  @override
  State<BluetoothDevicePickerPage> createState() =>
      _BluetoothDevicePickerPageState();
}

class _BluetoothDevicePickerPageState extends State<BluetoothDevicePickerPage> {
  final _hub = BluetoothPrinterHub.instance;
  final _permissions = const AppPermissionService();

  bool _loading = true;
  String? _error;
  List<BluetoothInfo> _devices = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
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
              'Allow Bluetooth, nearby devices, and location to list printers.';
        });
        return;
      }
      if (!await _hub.isBluetoothOn()) {
        setState(() {
          _loading = false;
          _error = 'Turn on Bluetooth and try again.';
        });
        return;
      }
      final list = await _hub.pairedDevices();
      if (!mounted) return;
      setState(() {
        _devices = list;
        _loading = false;
        if (list.isEmpty) {
          _error =
              'No paired printers found. Pair the thermal printer in Android Bluetooth settings, then refresh.';
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not load paired devices: $e';
      });
    }
  }

  Future<void> _select(BluetoothInfo device) async {
    final ok = await _hub.connect(
      widget.channel,
      address: device.macAdress,
      fromUser: true,
    );
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context, device);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not connect to ${device.name}. Try again.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.title ??
        (widget.channel == PrinterChannelKind.bill
            ? 'Select bill printer'
            : 'Select KOT printer');

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null && _devices.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_error!, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      AppButton(
            label: 'Retry',
            icon: Icons.refresh_rounded,
            onPressed: _load,
            expanded: false,
          ),
                      TextButton(
                        onPressed: _permissions.openAppSettingsPage,
                        child: const Text('Open app settings'),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  itemCount: _devices.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final d = _devices[index];
                    return ListTile(
                      leading: const Icon(Icons.print_rounded),
                      title: Text(
                        d.name.isEmpty ? 'Unknown printer' : d.name,
                      ),
                      subtitle: Text(d.macAdress),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => _select(d),
                    );
                  },
                ),
    );
  }
}
