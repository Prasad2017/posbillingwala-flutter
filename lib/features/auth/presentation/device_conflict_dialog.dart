import 'package:flutter/material.dart';
import 'package:pos_billingwala_v2/core/widgtes/widgtes.dart';
import 'package:pos_billingwala_v2/features/auth/data/auth_repository.dart';

Future<DeviceConflictAction> showDeviceConflictDialog(
  BuildContext context,
  String message,
) async {
  final result = await showDialog<DeviceConflictAction>(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(children: [Icon(Icons.devices_other_rounded, color: Colors.red), SizedBox(width: 10), Expanded(child: Text('Device already registered'))]),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.of(context).pop(DeviceConflictAction.cancel),
            child: const Text('No'),
          ),
          AppButton(
            label: 'Yes, bind here',
            expanded: false,
            onPressed: () =>
                Navigator.of(context).pop(DeviceConflictAction.rebind),
          ),
        ],
      );
    },
  );
  return result ?? DeviceConflictAction.cancel;
}
