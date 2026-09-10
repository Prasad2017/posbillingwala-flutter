import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:pos_billingwala_v2/app/router.dart';
import 'package:pos_billingwala_v2/app/theme.dart';
import 'package:pos_billingwala_v2/core/constants/app_constants.dart';
import 'package:pos_billingwala_v2/features/sync/domain/connectivity_sync_listener.dart';
import 'package:shared_preferences/shared_preferences.dart';

final appLocaleProvider = FutureProvider<Locale>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  switch (prefs.getString('appLanguage')) {
    case 'hi':
      return const Locale('hi');
    case 'mr':
      return const Locale('mr');
    default:
      return const Locale('en');
  }
});

class PosBillingwalaApp extends ConsumerWidget {
  const PosBillingwalaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    // Keep offline→cloud auto-upload alive for the app lifetime.
    ref.watch(connectivitySyncListenerProvider);
    final locale = ref.watch(appLocaleProvider).maybeWhen(
          data: (v) => v,
          orElse: () => const Locale('en'),
        );

    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      locale: locale,
      supportedLocales: const [
        Locale('en'),
        Locale('hi'),
        Locale('mr'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: router,
    );
  }
}
