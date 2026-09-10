import 'package:flutter/material.dart';
import 'package:pos_billingwala_v2/core/constants/app_colors.dart';
import 'package:pos_billingwala_v2/core/widgtes/three_dots_loader.dart';

enum AppButtonVariant { primary, success, danger, outlined }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.isLoading = false,
    this.expanded = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? icon;
  final bool isLoading;
  final bool expanded;

  Color get _loaderColor => variant == AppButtonVariant.outlined ? AppColors.primary : Colors.white;

  @override
  Widget build(BuildContext context) {
    final child = isLoading
        ? ThreeDotsLoader(color: _loaderColor)
        : Row(
            mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20),
                const SizedBox(width: 8),
              ],
              Flexible(child: Text(label, textAlign: TextAlign.center, overflow: TextOverflow.ellipsis)),
            ],
          );

    final onTap = isLoading ? null : onPressed;
    final button = switch (variant) {
      AppButtonVariant.primary => FilledButton(
          onPressed: onTap,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: child,
        ),
      AppButtonVariant.success => FilledButton(
          onPressed: onTap,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.green,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: child,
        ),
      AppButtonVariant.danger => FilledButton(
          onPressed: onTap,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.red,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: child,
        ),
      AppButtonVariant.outlined => OutlinedButton(
          onPressed: onTap,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: Color(0xFFBFD5F5)),
          ),
          child: child,
        ),
    };

    return AnimatedScale(
      scale: onTap == null ? .98 : 1,
      duration: const Duration(milliseconds: 160),
      child: expanded ? SizedBox(width: double.infinity, child: button) : button,
    );
  }
}
