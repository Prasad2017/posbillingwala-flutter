import 'package:flutter/material.dart';
import 'package:pos_billingwala_v2/core/widgtes/widgtes.dart';
import 'package:pos_billingwala_v2/core/constants/app_colors.dart';
import 'package:pos_billingwala_v2/core/widgets/app_module_icon.dart';
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
        title: const Row(children: [AppModuleIcon(icon: Icons.devices_other_rounded, color: AppColors.red, size: 46), SizedBox(width: 10), Expanded(child: Text('Device already registered'))]),
        content: AppCard(accentColor: AppColors.red, child: Text(message)),
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
