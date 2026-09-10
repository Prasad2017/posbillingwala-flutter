import 'package:flutter/material.dart';
import 'package:pos_billingwala_v2/core/constants/app_colors.dart';
import 'package:pos_billingwala_v2/core/widgtes/widget_theme.dart';

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.color,
    this.onTap,
    this.accentColor,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final VoidCallback? onTap;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final accent = accentColor;
    final decoration = BoxDecoration(
      color: color ?? context.cardColor,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(
        color: (accent ?? AppColors.primary).withValues(alpha: accent == null ? .06 : .18),
      ),
      boxShadow: [
        BoxShadow(
          color: AppColors.navy.withValues(alpha: .045),
          blurRadius: 18,
          offset: const Offset(0, 7),
        ),
      ],
    );

    return Container(
      margin: margin ?? EdgeInsets.zero,
      decoration: decoration,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          splashColor: (accent ?? AppColors.primary).withValues(alpha: .08),
          highlightColor: (accent ?? AppColors.primary).withValues(alpha: .04),
          child: AnimatedPadding(
            duration: const Duration(milliseconds: 180),
            padding: EdgeInsets.zero,
            child: Padding(
            padding: padding,
            child: child,
          ),
            ),
        ),
      ),
    );
  }
}
