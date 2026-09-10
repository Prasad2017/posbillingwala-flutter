import 'package:pos_billingwala_v2/core/constants/api_constants.dart';

class AppConstants {
  AppConstants._();

  static const String appName = 'POS Billingwala';
  static const String appVersionLabel = 'Version 2';
  static const String website = 'https://www.posbillingwala.com';

  /// Prefer [ApiConstants.baseUrl]; kept for older call sites.
  static const String apiBaseUrl = ApiConstants.baseUrl;
}
