import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pos_billingwala_v2/app/router.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens the in-app destination (or external URL) for a notification payload.
///
/// Prefer calling with a [BuildContext] from the widget tree. When only FCM
/// data is available (no widget context), use [openNotificationTargetFromKey]
/// which navigates via [rootNavigatorKey].
Future<void> openNotificationTarget(
  BuildContext context, {
  required String type,
  String? url,
}) async {
  final normalized = type.trim().toLowerCase();
  final trimmedUrl = url?.trim();

  if (normalized == 'license_expiring') {
    context.push('/settings/company');
    return;
  }

  if (normalized.startsWith('mess')) {
    context.push('/mess');
    return;
  }

  if (normalized == 'promotional' &&
      trimmedUrl != null &&
      trimmedUrl.isNotEmpty &&
      (trimmedUrl.startsWith('http://') || trimmedUrl.startsWith('https://'))) {
    final uri = Uri.tryParse(trimmedUrl);
    if (uri != null) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return;
    }
  }

  context.push('/notifications');
}

/// Context-free variant for FCM open handlers using [rootNavigatorKey].
Future<void> openNotificationTargetFromKey({
  required String type,
  String? url,
}) async {
  final context = rootNavigatorKey.currentContext;
  if (context == null || !context.mounted) return;
  await openNotificationTarget(context, type: type, url: url);
}
