import 'package:flutter/material.dart';

/// POS2 BillingWala brand palette extracted from the official logo.
/// Blue is the primary identity; orange/red are energetic accent colors.
class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF076BF5);
  static const Color primaryDark = Color(0xFF0121B1);
  static const Color navy = Color(0xFF020745);
  static const Color primaryLight = Color(0xFFE8F3FF);
  static const Color cyanSoft = Color(0xFFB7DFF4);

  static const Color orange = Color(0xFFFF8A00);
  static const Color orangeDark = Color(0xFFFF5A00);
  static const Color yellow = Color(0xFFFFC400);
  static const Color red = Color(0xFFF52B3A);

  static const Color surface = Color(0xFFF7F9FC);
  static const Color success = Color(0xFF16A36A);
  static const Color warning = orange;
  static const Color danger = red;

  static const List<Color> brandGradient = [
    primary,
    primaryDark,
  ];

  static const List<Color> warmGradient = [
    orange,
    red,
  ];
}
