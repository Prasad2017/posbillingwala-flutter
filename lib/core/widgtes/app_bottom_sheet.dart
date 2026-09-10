import 'package:flutter/material.dart';
import 'package:pos_billingwala_v2/core/widgtes/app_button.dart';
import 'package:pos_billingwala_v2/core/widgtes/widget_strings.dart';
import 'package:pos_billingwala_v2/core/widgtes/widget_theme.dart';

Future<T?> showAppBottomSheet<T>({
  required BuildContext context,
  required String title,
  required Widget child,
  IconData? icon,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (ctx) => Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        16,
        24,
        MediaQuery.of(ctx).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: ctx.primary.withValues(alpha: .10), borderRadius: BorderRadius.circular(14)), child: Icon(icon, color: ctx.primary)),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: ctx.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            child,
          ],
        ),
      ),
    ),
  );
}

/// Confirmation sheet built on [showAppBottomSheet] with message + AppButton row.
Future<bool> showAppConfirmBottomSheet({
  required BuildContext context,
  required String title,
  required String message,
  required String confirmLabel,
  String? cancelLabel,
  IconData? icon,
  AppButtonVariant confirmVariant = AppButtonVariant.primary,
}) async {
  final result = await showAppBottomSheet<bool>(
    context: context,
    title: title,
    icon: icon,
    child: Builder(
      builder: (sheetContext) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            message,
            style: TextStyle(
              fontSize: 15,
              height: 1.45,
              color: sheetContext.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: cancelLabel ?? WidgetStrings.cancel,
                  variant: AppButtonVariant.outlined,
                  onPressed: () => Navigator.of(sheetContext).pop(false),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppButton(
                  label: confirmLabel,
                  variant: confirmVariant,
                  onPressed: () => Navigator.of(sheetContext).pop(true),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
  return result == true;
}
