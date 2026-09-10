import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:pos_billingwala_v2/core/constants/app_colors.dart';
import 'package:pos_billingwala_v2/core/constants/app_constants.dart';
import 'package:pos_billingwala_v2/core/permissions/app_permission_service.dart';
import 'package:pos_billingwala_v2/core/widgtes/widgtes.dart';
import 'package:pos_billingwala_v2/core/widgets/app_module_icon.dart';
import 'package:pos_billingwala_v2/core/widgets/donut_chart.dart';
import 'package:pos_billingwala_v2/features/auth/domain/auth_controller.dart';
import 'package:pos_billingwala_v2/features/auth/domain/user_session.dart';
import 'package:pos_billingwala_v2/features/masters/domain/masters_providers.dart';
import 'package:pos_billingwala_v2/features/notifications/domain/notification_providers.dart';
import 'package:pos_billingwala_v2/features/pos/domain/billing_session.dart';
import 'package:pos_billingwala_v2/features/pos/domain/pos_providers.dart';
import 'package:pos_billingwala_v2/features/print/domain/bluetooth_printer_hub.dart';
import 'package:pos_billingwala_v2/features/print/domain/printer_settings.dart';
import 'package:pos_billingwala_v2/features/reports/domain/reports_providers.dart';
import 'package:pos_billingwala_v2/features/reports/presentation/report_pin_gate.dart';
import 'package:pos_billingwala_v2/features/settings/domain/business_hours.dart';

/// Android-style Home dashboard (greeting, sales, catalog, billing, sync).
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  static bool _permissionsPrompted = false;
  bool _salesMonth = false;
  bool _hidePrimarySales = false;
  bool _hideTodaySales = false;
  String _printerChip = 'Checking…';

  @override
  void initState() {
    super.initState();
    if (!_permissionsPrompted) {
      _permissionsPrompted = true;
      Future.microtask(() async {
        final service = const AppPermissionService();
        if (!await service.arePrintPermissionsGranted) {
          await service.requestAll();
        }
        final settings = ref.read(printerSettingsProvider);
        final hub = BluetoothPrinterHub.instance
          ..updateSavedAddresses(
            billMac: settings.billBluetoothAddress,
            kotMac: settings.kotBluetoothAddress,
          );
        await hub.autoConnect(PrinterChannelKind.bill);
        if (!mounted) return;
        await _refreshPrinterChip();
        if (!mounted) return;
        if (const bool.fromEnvironment('AUTO_TEST_PRINT')) {
          context.go('/settings/test-print?mode=invoice');
        }
      });
    } else {
      Future.microtask(_refreshPrinterChip);
    }
  }

  Future<void> _refreshPrinterChip() async {
    final settings = ref.read(printerSettingsProvider);
    final hub = BluetoothPrinterHub.instance;
    final mac = settings.billBluetoothAddress.trim();
    String label;
    if (mac.isEmpty &&
        settings.billUsbIdentifier.isEmpty &&
        settings.networkHost.trim().isEmpty) {
      label = 'Not set';
    } else if (hub.isConnecting) {
      label = 'Connecting…';
    } else if (await hub.connectionStatus() && hub.connectedAddress.isNotEmpty) {
      label = 'Connected';
    } else if (settings.billTransport == PosPrinterTransport.usb &&
        EscPosUsbHint.isLinked(settings)) {
      label = 'USB ready';
    } else if (settings.billTransport == PosPrinterTransport.network &&
        settings.networkHost.trim().isNotEmpty) {
      label = 'Network';
    } else {
      label = 'Offline';
    }
    if (!mounted) return;
    setState(() => _printerChip = label);
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  Future<void> _openFastBilling() async {
    ref.read(billingSessionProvider.notifier).usePos();
    await ref.read(posCartControllerProvider.notifier).clear();
    if (!mounted) return;
    context.push('/pos');
  }

  Future<void> _logout() async {
    final confirm = await showAppConfirmBottomSheet(
      context: context,
      title: 'Logout',
      message: 'Clear this device session and return to licence login?',
      confirmLabel: 'Logout',
      confirmVariant: AppButtonVariant.danger,
      icon: Icons.logout_rounded,
    );
    if (confirm) {
      await ref.read(authControllerProvider.notifier).logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final session = ref.watch(authControllerProvider).session;
    final unread = ref.watch(unreadNotificationCountProvider);
    final todaySummary = ref.watch(todaySalesSummaryProvider);
    final monthSummary = ref.watch(monthSalesSummaryProvider);
    final primary = _salesMonth ? monthSummary : todaySummary;
    final countsAsync = ref.watch(catalogCountsProvider);
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
    final nowLabel = DateFormat('EEE, dd MMM yyyy · hh:mm a').format(DateTime.now());

    // Show tiles always; gate with toast when module flags are explicitly set.
    final flagsMissing = session == null || _anyBilling(session);
    final allowFast = flagsMissing || session.fastBilling;
    final allowDine = flagsMissing || session.dineIn;
    final allowTake = flagsMissing || session.takeAway;
    final allowMess = flagsMissing || session.mess;
    final showTotalSales =
        session == null || session.totalSaleData || session.todaySaleData;
    final showTodaySales = session == null || session.todaySaleData;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(catalogCountsProvider);
          ref.invalidate(todayInvoicesProvider);
          ref.invalidate(monthInvoicesProvider);
          ref.invalidate(shopOpenNowProvider);
          await _refreshPrinterChip();
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.primary, Color(0xFF3A4F9A)],
                  ),
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(24),
                  ),
                ),
                padding: EdgeInsets.fromLTRB(
                  20,
                  MediaQuery.paddingOf(context).top + 12,
                  20,
                  20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 26,
                          backgroundColor: Colors.white24,
                          child: Text(
                            () {
                              final name =
                                  (session?.shopName ?? 'P').trim();
                              if (name.isEmpty) return 'P';
                              return name.substring(0, 1).toUpperCase();
                            }(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 22,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${_greeting()},',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: Colors.white70,
                                ),
                              ),
                              Text(
                                session?.userName?.trim().isNotEmpty == true
                                    ? session!.userName!.trim()
                                    : 'Cashier',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              if (session?.shopName?.trim().isNotEmpty ==
                                  true)
                                Text(
                                  session!.shopName!.trim(),
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.9),
                                  ),
                                ),
                              if (session?.branchLabel?.trim().isNotEmpty ==
                                  true)
                                Text(
                                  'Branch: ${session!.branchLabel!.trim()}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: Colors.white70,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Fetch data',
                          onPressed: () => context.push('/sync'),
                          icon: const Icon(
                            Icons.cloud_sync_outlined,
                            color: Colors.white,
                          ),
                        ),
                        IconButton(
                          tooltip: 'Notifications',
                          onPressed: () => context.push('/notifications'),
                          icon: Badge(
                            isLabelVisible: unread > 0,
                            label: Text('$unread'),
                            child: const Icon(
                              Icons.notifications_outlined,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Settings',
                          onPressed: () => context.push('/settings'),
                          icon: const Icon(
                            Icons.settings_rounded,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ref.watch(shopOpenNowProvider).when(
                              data: (open) => _StatusChip(
                                icon: Icons.circle,
                                iconColor: open
                                    ? const Color(0xFF4ADE80)
                                    : const Color(0xFFF87171),
                                label: open ? 'Shop open' : 'Shop closed',
                              ),
                              loading: () => const _StatusChip(
                                icon: Icons.circle,
                                iconColor: Colors.white54,
                                label: 'Shop…',
                              ),
                              error: (_, _) => const _StatusChip(
                                icon: Icons.circle,
                                iconColor: Color(0xFF4ADE80),
                                label: 'Shop open',
                              ),
                            ),
                        InkWell(
                          onTap: () => context.push('/settings'),
                          borderRadius: BorderRadius.circular(20),
                          child: _StatusChip(
                            icon: Icons.print_rounded,
                            iconColor: _printerChip == 'Connected' ||
                                    _printerChip == 'USB ready' ||
                                    _printerChip == 'Network'
                                ? const Color(0xFF4ADE80)
                                : Colors.orangeAccent,
                            label: 'Bill · $_printerChip',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      nowLabel,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                    if (session?.licenceKeyExpireDate != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Licence till ${session!.licenceKeyExpireDate}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: Colors.white60,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (showTotalSales || showTodaySales)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Sales overview',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const Spacer(),
                          SegmentedButton<bool>(
                            segments: const [
                              ButtonSegment(value: false, label: Text('Today')),
                              ButtonSegment(value: true, label: Text('Month')),
                            ],
                            selected: {_salesMonth},
                            onSelectionChanged: (v) {
                              setState(() => _salesMonth = v.first);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          if (showTotalSales)
                            Expanded(
                              child: _SalesCard(
                                title: _salesMonth
                                    ? 'Monthly sales'
                                    : 'Total sales',
                                amount: _hidePrimarySales
                                    ? '••••••'
                                    : currency.format(primary.totalSales),
                                subtitle: '${primary.billCount} bills',
                                onToggleHide: () => setState(
                                  () => _hidePrimarySales = !_hidePrimarySales,
                                ),
                                hidden: _hidePrimarySales,
                                onTap: () =>
                                    pushReportsUnlocked(context, ref),
                              ),
                            ),
                          if (showTotalSales && showTodaySales)
                            const SizedBox(width: 12),
                          if (showTodaySales)
                            Expanded(
                              child: _SalesCard(
                                title: "Today's sales",
                                amount: _hideTodaySales
                                    ? '••••••'
                                    : currency
                                        .format(todaySummary.totalSales),
                                subtitle: '${todaySummary.billCount} bills',
                                onToggleHide: () => setState(
                                  () => _hideTodaySales = !_hideTodaySales,
                                ),
                                hidden: _hideTodaySales,
                                onTap: () =>
                                    pushReportsUnlocked(context, ref),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
                child: AppCard(
                  padding: const EdgeInsets.all(18),
                  accentColor: AppColors.purple,
                  child: Row(
                    children: [
                      DonutChart(
                        values: [
                          todaySummary.cashTotal.toDouble(),
                          todaySummary.upiTotal.toDouble(),
                          (todaySummary.totalSales - todaySummary.cashTotal - todaySummary.upiTotal).clamp(0, double.infinity).toDouble(),
                        ],
                        colors: const [AppColors.primary, AppColors.orange, AppColors.green],
                        centerValue: currency.format(todaySummary.totalSales),
                        centerTitle: 'Today',
                        size: 138,
                        strokeWidth: 16,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Payment overview', style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.navy)),
                            const SizedBox(height: 10),
                            _PaymentLegend(color: AppColors.primary, label: 'Cash'),
                            const SizedBox(height: 7),
                            _PaymentLegend(color: AppColors.orange, label: 'UPI'),
                            const SizedBox(height: 7),
                            _PaymentLegend(color: AppColors.green, label: 'Other'),
                            const SizedBox(height: 12),
                            TextButton.icon(
                              onPressed: () => pushReportsUnlocked(context, ref),
                              icon: const Icon(Icons.insights_rounded, size: 18),
                              label: const Text('View analytics'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Catalog',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () => context.push('/masters'),
                          child: const Text('View all'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    countsAsync.when(
                      data: (c) => Row(
                        children: [
                          Expanded(
                            child: _CatalogTile(
                              icon: Icons.category_rounded,
                              label: 'Categories',
                              value: '${c.categories}',
                              onTap: () => context.push('/masters'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _CatalogTile(
                              icon: Icons.inventory_2_rounded,
                              label: 'Products',
                              value: '${c.products}',
                              onTap: () => context.push('/masters'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _CatalogTile(
                              icon: Icons.dining_rounded,
                              label: 'Combos',
                              value: '${c.combos}',
                              onTap: () => context.push('/masters'),
                            ),
                          ),
                        ],
                      ),
                      loading: () => const LinearProgressIndicator(),
                      error: (e, _) => Text('$e'),
                    ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () =>
                            context.push('/masters/subcategories'),
                        icon: const Icon(Icons.account_tree_outlined),
                        label: const Text('Subcategories'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Start billing',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.35,
                      children: [
                        _BillingTile(
                            title: 'Fast Billing',
                            subtitle: 'Quick counter sale',
                            icon: Icons.point_of_sale_rounded,
                            onTap: () {
                              if (!allowFast) {
                                _moduleLocked(context);
                                return;
                              }
                              _openFastBilling();
                            },
                          ),
                        _BillingTile(
                            title: 'Dine-In',
                            subtitle: 'Table floor plan',
                            icon: Icons.table_restaurant_rounded,
                            onTap: () {
                              if (!allowDine) {
                                _moduleLocked(context);
                                return;
                              }
                              context.push('/tables');
                            },
                          ),
                        _BillingTile(
                            title: 'Take Away',
                            subtitle: 'Parcel counter',
                            icon: Icons.takeout_dining_rounded,
                            onTap: () {
                              if (!allowTake) {
                                _moduleLocked(context);
                                return;
                              }
                              context.push('/takeaway');
                            },
                          ),
                        _BillingTile(
                            title: 'Mess',
                            subtitle: 'Members & tokens',
                            icon: Icons.groups_rounded,
                            onTap: () {
                              if (!allowMess) {
                                _moduleLocked(context);
                                return;
                              }
                              context.push('/mess');
                            },
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cloud & tools',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _ActionCard(
                            title: 'Synchronize',
                            subtitle: 'Upload & download',
                            icon: Icons.cloud_sync_rounded,
                            onTap: () => context.push('/sync'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ActionCard(
                            title: 'Reports',
                            subtitle: 'Sales & invoices',
                            icon: Icons.bar_chart_rounded,
                            onTap: () => pushReportsUnlocked(context, ref),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _ActionCard(
                            title: 'Inventory',
                            subtitle: 'Stock & expenses',
                            icon: Icons.warehouse_rounded,
                            onTap: () => context.push('/inventory'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ActionCard(
                            title: 'Support',
                            subtitle: 'Help & tickets',
                            icon: Icons.support_agent_rounded,
                            onTap: () => context.push('/support'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                child: TextButton.icon(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout_rounded),
                  label: Text(
                    'Logout · ${AppConstants.appVersionLabel}',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _moduleLocked(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('This module is not enabled on your licence. Contact support.'),
      ),
    );
  }

  /// When no module flags are set (older sessions), treat as full licence.
  bool _anyBilling(UserSession s) =>
      !s.fastBilling && !s.dineIn && !s.takeAway && !s.mess;
}

/// Hint helper so home doesn't import USB hub just for a label.
class EscPosUsbHint {
  static bool isLinked(PrinterSettings settings) =>
      settings.billUsbIdentifier.trim().isNotEmpty;
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.icon,
    required this.iconColor,
    required this.label,
  });

  final IconData icon;
  final Color iconColor;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: iconColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _SalesCard extends StatelessWidget {
  const _SalesCard({
    required this.title,
    required this.amount,
    required this.subtitle,
    required this.onToggleHide,
    required this.hidden,
    required this.onTap,
  });

  final String title;
  final String amount;
  final String subtitle;
  final VoidCallback onToggleHide;
  final bool hidden;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Colors.black54,
                      ),
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: onToggleHide,
                icon: Icon(
                  hidden
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 18,
                ),
              ),
            ],
          ),
          Text(
            amount,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
          ),
          const SizedBox(height: 4),
          Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

Color _colorForIcon(IconData icon) {
  const colors = [
    AppColors.primary, AppColors.orange, AppColors.green,
    AppColors.purple, AppColors.red, AppColors.teal,
  ];
  return colors[icon.codePoint % colors.length];
}

class _PaymentLegend extends StatelessWidget {
  const _PaymentLegend({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(width: 9, height: 9, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 8),
      Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
    ],
  );
}

class _CatalogTile extends StatelessWidget {
  const _CatalogTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      onTap: onTap,
      child: Column(
        children: [
          AppModuleIcon(icon: icon, color: _colorForIcon(icon), size: 46),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _BillingTile extends StatelessWidget {
  const _BillingTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppModuleIcon(icon: icon, color: _colorForIcon(icon), size: 52),
          const Spacer(),
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.black54,
                ),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      onTap: onTap,
      child: ListTile(
        leading: AppModuleIcon(icon: icon, color: _colorForIcon(icon), size: 46),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }
}
