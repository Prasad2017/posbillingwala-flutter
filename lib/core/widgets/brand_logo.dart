import 'package:flutter/material.dart';
import 'package:pos_billingwala_v2/core/constants/app_colors.dart';

/// Displays the official POS2 BillingWala logo when the provided brand asset exists.
class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, this.width = 230});

  final double width;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/pos2_billingwala_logo.png',
      width: width,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'POS²',
            style: TextStyle(
              color: AppColors.primaryDark,
              fontWeight: FontWeight.w900,
              fontSize: width * .24,
              height: .9,
            ),
          ),
          Text(
            'BillingWala',
            style: TextStyle(
              color: AppColors.primaryDark,
              fontWeight: FontWeight.w900,
              fontSize: width * .17,
              height: .95,
            ),
          ),
        ],
      ),
    );
  }
}
