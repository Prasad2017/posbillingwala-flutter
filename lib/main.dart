import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_billingwala_v2/app/app.dart';
import 'package:pos_billingwala_v2/features/notifications/domain/fcm_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Best-effort Firebase/FCM init — tests and desktops may skip.
  try {
    await FcmService().initialize();
  } catch (_) {}

  runApp(
    const ProviderScope(
      child: PosBillingwalaApp(),
    ),
  );
}
