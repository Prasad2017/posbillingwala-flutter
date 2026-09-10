import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pos_billingwala_v2/features/auth/domain/auth_controller.dart';
import 'package:pos_billingwala_v2/features/auth/presentation/login_page.dart';
import 'package:pos_billingwala_v2/features/auth/presentation/mpin_page.dart';
import 'package:pos_billingwala_v2/features/auth/presentation/register_page.dart';
import 'package:pos_billingwala_v2/features/auth/presentation/splash_page.dart';
import 'package:pos_billingwala_v2/features/home/presentation/home_page.dart';
import 'package:pos_billingwala_v2/features/inventory/presentation/inventory_page.dart';
import 'package:pos_billingwala_v2/features/masters/presentation/masters_page.dart';
import 'package:pos_billingwala_v2/features/masters/presentation/portion_masters_page.dart';
import 'package:pos_billingwala_v2/features/masters/presentation/subcategories_page.dart';
import 'package:pos_billingwala_v2/features/masters/presentation/table_master_page.dart';
import 'package:pos_billingwala_v2/core/database/app_database.dart';
import 'package:pos_billingwala_v2/features/mess/presentation/mess_meal_sessions_page.dart';
import 'package:pos_billingwala_v2/features/mess/presentation/mess_meal_tokens_today_page.dart';
import 'package:pos_billingwala_v2/features/mess/presentation/mess_page.dart';
import 'package:pos_billingwala_v2/features/mess/presentation/mess_payments_page.dart';
import 'package:pos_billingwala_v2/features/mess/presentation/mess_token_scan_page.dart';
import 'package:pos_billingwala_v2/features/notifications/presentation/notifications_page.dart';
import 'package:pos_billingwala_v2/features/pos/presentation/pos_page.dart';
import 'package:pos_billingwala_v2/features/pos/presentation/payment_page.dart';
import 'package:pos_billingwala_v2/features/reports/domain/reports_providers.dart';
import 'package:pos_billingwala_v2/features/reports/presentation/expense_report_page.dart';
import 'package:pos_billingwala_v2/features/reports/presentation/invoice_detail_page.dart';
import 'package:pos_billingwala_v2/features/reports/presentation/mess_member_report_page.dart';
import 'package:pos_billingwala_v2/features/reports/presentation/operational_report_page.dart';
import 'package:pos_billingwala_v2/features/reports/presentation/product_wise_report_page.dart';
import 'package:pos_billingwala_v2/features/reports/presentation/reports_hub_page.dart';
import 'package:pos_billingwala_v2/features/reports/presentation/reports_page.dart';
import 'package:pos_billingwala_v2/features/reports/presentation/sales_dashboard_page.dart';
import 'package:pos_billingwala_v2/features/print/domain/bluetooth_printer_hub.dart';
import 'package:pos_billingwala_v2/features/print/presentation/test_invoice_preview_page.dart';
import 'package:pos_billingwala_v2/features/settings/presentation/about_page.dart';
import 'package:pos_billingwala_v2/features/settings/presentation/business_hours_page.dart';
import 'package:pos_billingwala_v2/features/settings/presentation/change_pin_page.dart';
import 'package:pos_billingwala_v2/features/settings/presentation/company_settings_page.dart';
import 'package:pos_billingwala_v2/features/settings/presentation/settings_hub_page.dart';
import 'package:pos_billingwala_v2/features/settings/presentation/settings_page.dart';
import 'package:pos_billingwala_v2/features/settings/presentation/share_app_page.dart';
import 'package:pos_billingwala_v2/features/support/presentation/support_page.dart';
import 'package:pos_billingwala_v2/features/support/presentation/support_ticket_detail_page.dart';
import 'package:pos_billingwala_v2/features/sync/presentation/sync_page.dart';
import 'package:pos_billingwala_v2/features/tables/presentation/split_bill_page.dart';
import 'package:pos_billingwala_v2/features/tables/presentation/tables_page.dart';
import 'package:pos_billingwala_v2/features/takeaway/presentation/takeaway_page.dart';

/// Global navigator key for FCM deep links and context-free navigation.
final rootNavigatorKey = GlobalKey<NavigatorState>();

class GoRouterRefresh extends ChangeNotifier {
  void ping() => notifyListeners();
}

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = GoRouterRefresh();
  ref.listen<AuthState>(authControllerProvider, (_, _) => refresh.ping());
  ref.onDispose(refresh.dispose);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/splash',
    refreshListenable: refresh,
    debugLogDiagnostics: kDebugMode,
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider);
      final loc = state.matchedLocation;

      final isSplash = loc == '/splash';
      final isLogin = loc == '/login';
      final isMpin = loc == '/mpin';
      final isRegister = loc == '/register';
      final isAuthRoute = isLogin || isMpin || isRegister || isSplash;

      switch (auth.status) {
        case AuthStatus.unknown:
          return isSplash ? null : '/splash';
        case AuthStatus.unauthenticated:
          if (isLogin || isRegister) return null;
          return '/login';
        case AuthStatus.needsMpin:
          if (isMpin) return null;
          if (isLogin || isRegister) return null;
          return '/mpin';
        case AuthStatus.authenticated:
          if (isAuthRoute) return '/';
          return null;
      }
    },
    routes: [
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/mpin',
        name: 'mpin',
        builder: (context, state) => const MpinPage(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: '/pos',
        name: 'pos',
        builder: (context, state) => const PosPage(resetSessionOnOpen: true),
      ),
      GoRoute(
        path: '/pos/payment',
        name: 'payment',
        builder: (context, state) => const PaymentPage(),
      ),
      GoRoute(
        path: '/tables',
        name: 'tables',
        builder: (context, state) => const TablesPage(),
      ),
      GoRoute(
        path: '/tables/billing',
        name: 'tables-billing',
        builder: (context, state) => const PosPage(),
      ),
      GoRoute(
        path: '/tables/payment',
        name: 'tables-payment',
        builder: (context, state) => const PaymentPage(),
      ),
      GoRoute(
        path: '/tables/split-bill',
        name: 'tables-split-bill',
        builder: (context, state) {
          final table = state.uri.queryParameters['table'] ?? '';
          final sessionId =
              int.tryParse(state.uri.queryParameters['sessionId'] ?? '') ?? 0;
          return SplitBillPage(tableNumber: table, sessionId: sessionId);
        },
      ),
      GoRoute(
        path: '/takeaway',
        name: 'takeaway',
        builder: (context, state) => const TakeawayPage(),
      ),
      GoRoute(
        path: '/takeaway/billing',
        name: 'takeaway-billing',
        builder: (context, state) => const PosPage(),
      ),
      GoRoute(
        path: '/takeaway/payment',
        name: 'takeaway-payment',
        builder: (context, state) => const PaymentPage(),
      ),
      GoRoute(
        path: '/mess',
        name: 'mess',
        builder: (context, state) => const MessPage(),
      ),
      GoRoute(
        path: '/mess/meal-sessions',
        name: 'mess-meal-sessions',
        builder: (context, state) => const MessMealSessionsPage(),
      ),
      GoRoute(
        path: '/mess/meal-tokens-today',
        name: 'mess-meal-tokens-today',
        builder: (context, state) => const MessMealTokensTodayPage(),
      ),
      GoRoute(
        path: '/mess/payments',
        name: 'mess-payments',
        builder: (context, state) {
          final member =
              state.extra is MessMember ? state.extra as MessMember : null;
          return MessPaymentsPage(member: member);
        },
      ),
      GoRoute(
        path: '/mess/scan',
        name: 'mess-scan',
        builder: (context, state) => const MessTokenScanPage(),
      ),
      GoRoute(
        path: '/masters',
        name: 'masters',
        builder: (context, state) => const MastersPage(),
      ),
      GoRoute(
        path: '/masters/subcategories',
        name: 'masters-subcategories',
        builder: (context, state) => const SubcategoriesPage(),
      ),
      GoRoute(
        path: '/masters/tables',
        name: 'masters-tables',
        builder: (context, state) => const TableMasterPage(),
      ),
      GoRoute(
        path: '/masters/portion-masters',
        name: 'masters-portion-masters',
        builder: (context, state) => const PortionMastersPage(),
      ),
      GoRoute(
        path: '/inventory',
        name: 'inventory',
        builder: (context, state) {
          final tab = state.uri.queryParameters['tab'];
          return InventoryPage(initialTab: tab == 'expenses' ? 1 : 0);
        },
      ),
      GoRoute(
        path: '/reports',
        name: 'reports',
        builder: (context, state) => const ReportsHubPage(),
      ),
      GoRoute(
        path: '/reports/dashboard',
        name: 'reports-dashboard',
        builder: (context, state) => const SalesDashboardPage(),
      ),
      GoRoute(
        path: '/reports/invoices',
        name: 'reports-invoices',
        builder: (context, state) => const ReportsPage(),
      ),
      GoRoute(
        path: '/reports/payment-mode',
        name: 'reports-payment-mode',
        builder: (context, state) => const OperationalReportPage(
          title: 'Payment Mode Report',
          paymentBreakdown: true,
        ),
      ),
      GoRoute(
        path: '/reports/sale',
        name: 'reports-sale',
        builder: (context, state) => const OperationalReportPage(
          title: 'Sale / POS Report',
          typeFilter: ReportInvoiceTypeFilter.pos,
        ),
      ),
      GoRoute(
        path: '/reports/table',
        name: 'reports-table',
        builder: (context, state) => const OperationalReportPage(
          title: 'Table Report',
          typeFilter: ReportInvoiceTypeFilter.table,
        ),
      ),
      GoRoute(
        path: '/reports/takeaway',
        name: 'reports-takeaway',
        builder: (context, state) => const OperationalReportPage(
          title: 'Take Away Report',
          typeFilter: ReportInvoiceTypeFilter.takeaway,
        ),
      ),
      GoRoute(
        path: '/reports/discount',
        name: 'reports-discount',
        builder: (context, state) => const OperationalReportPage(
          title: 'Discount Report',
          typeFilter: ReportInvoiceTypeFilter.discountOnly,
        ),
      ),
      GoRoute(
        path: '/reports/mess',
        name: 'reports-mess',
        builder: (context, state) => const OperationalReportPage(
          title: 'Mess Report',
          typeFilter: ReportInvoiceTypeFilter.mess,
        ),
      ),
      GoRoute(
        path: '/reports/refund',
        name: 'reports-refund',
        builder: (context, state) => const OperationalReportPage(
          title: 'Refund Report',
          typeFilter: ReportInvoiceTypeFilter.refundOnly,
        ),
      ),
      GoRoute(
        path: '/reports/mess-members',
        name: 'reports-mess-members',
        builder: (context, state) => const MessMemberReportPage(),
      ),
      GoRoute(
        path: '/reports/expense',
        name: 'reports-expense',
        builder: (context, state) => const ExpenseReportPage(),
      ),
      GoRoute(
        path: '/reports/products',
        name: 'reports-products',
        builder: (context, state) {
          final type = state.uri.queryParameters['type'] ?? 'all';
          return ProductWiseReportPage(initialType: type);
        },
      ),
      GoRoute(
        path: '/reports/invoice/:invoiceId',
        name: 'invoice-detail',
        builder: (context, state) {
          final invoiceId = int.parse(state.pathParameters['invoiceId']!);
          return InvoiceDetailPage(invoiceId: invoiceId);
        },
      ),
      GoRoute(
        path: '/sync',
        name: 'sync',
        builder: (context, state) => const SyncPage(),
      ),
      GoRoute(
        path: '/notifications',
        name: 'notifications',
        builder: (context, state) => const NotificationsPage(),
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsHubPage(),
      ),
      GoRoute(
        path: '/settings/company',
        name: 'settings-company',
        builder: (context, state) => const CompanySettingsPage(),
      ),
      GoRoute(
        path: '/settings/devices',
        name: 'settings-devices',
        builder: (context, state) => const SettingsPage(),
      ),
      GoRoute(
        path: '/settings/business-hours',
        name: 'settings-business-hours',
        builder: (context, state) => const BusinessHoursPage(),
      ),
      GoRoute(
        path: '/settings/about',
        name: 'settings-about',
        builder: (context, state) => const AboutPage(),
      ),
      GoRoute(
        path: '/settings/share',
        name: 'settings-share',
        builder: (context, state) => const ShareAppPage(),
      ),
      GoRoute(
        path: '/settings/change-pin',
        name: 'settings-change-pin',
        builder: (context, state) => const ChangePinPage(),
      ),
      GoRoute(
        path: '/settings/test-print',
        name: 'test-print-preview',
        builder: (context, state) {
          final mode = state.uri.queryParameters['mode'] ?? 'invoice';
          final channel = mode == 'kot'
              ? PrinterChannelKind.kot
              : PrinterChannelKind.bill;
          return TestInvoicePreviewPage(channel: channel);
        },
      ),
      GoRoute(
        path: '/support',
        name: 'support',
        builder: (context, state) => const SupportPage(),
      ),
      GoRoute(
        path: '/support/:ticketId',
        name: 'support-ticket',
        builder: (context, state) {
          final ticketId = state.pathParameters['ticketId'] ?? '';
          return SupportTicketDetailPage(ticketId: ticketId);
        },
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Not found')),
      body: Center(child: Text(state.error?.toString() ?? 'Page not found')),
    ),
  );
});
