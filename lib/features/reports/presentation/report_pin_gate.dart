import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pos_billingwala_v2/core/widgtes/widgtes.dart';
import 'package:pos_billingwala_v2/core/widgets/app_module_icon.dart';
import 'package:pos_billingwala_v2/features/auth/domain/auth_controller.dart';

/// Android `report_password_dialog` — unlock Reports.
Future<bool> showReportPinGate(BuildContext context, WidgetRef ref) async {
  final expected =
      ref.read(authControllerProvider).session?.reportPin?.trim();
  final pin = (expected == null || expected.isEmpty) ? '9082' : expected;
  final controller = TextEditingController();

  final ok = await showAppBottomSheet<bool>(
    context: context,
    title: 'Enter Report PIN',
    icon: Icons.lock_outline_rounded,
    child: Builder(
      builder: (sheetContext) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Center(child: AppModuleIcon(icon: Icons.lock_rounded, color: AppColors.primary, size: 68)),
          const SizedBox(height: 12),
          const Text('This protects sales and invoice reports.', textAlign: TextAlign.center),
          const SizedBox(height: 16),
          AppTextField(
            controller: controller,
            label: 'Report PIN',
            keyboardType: TextInputType.number,
            obscureText: true,
          ),
          const SizedBox(height: 16),
          AppButton(
            label: 'Unlock',
            onPressed: () {
              final match =
                  controller.text.trim().toLowerCase() == pin.toLowerCase();
              Navigator.pop(sheetContext, match);
            },
          ),
        ],
      ),
    ),
  );
  controller.dispose();
  if (ok == true) return true;
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Incorrect Report PIN')),
    );
  }
  return false;
}

Future<void> pushReportsUnlocked(
  BuildContext context,
  WidgetRef ref, {
  String route = '/reports',
}) async {
  if (!await showReportPinGate(context, ref)) return;
  if (!context.mounted) return;
  context.push(route);
}
