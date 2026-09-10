import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pos_billingwala_v2/core/constants/app_colors.dart';
import 'package:pos_billingwala_v2/core/constants/app_constants.dart';
import 'package:pos_billingwala_v2/core/widgets/app_module_icon.dart';
import 'package:pos_billingwala_v2/core/widgtes/widgtes.dart';
import 'package:pos_billingwala_v2/features/auth/domain/auth_controller.dart';
import 'package:pos_billingwala_v2/features/reports/presentation/report_pin_gate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

/// Android-style User Setting hub (grouped rows → existing routes / details).
class SettingsHubPage extends ConsumerWidget {
  const SettingsHubPage({super.key});

  static const _playStoreUrl =
      'https://play.google.com/store/apps/details?id=com.pos_billingwala';
  static const _languageKey = 'appLanguage';

  Future<void> _rateUs(BuildContext context) async {
    final uri = Uri.parse(_playStoreUrl);
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open Play Store')),
      );
    }
  }

  Future<void> _checkUpdate(BuildContext context) async {
    final uri = Uri.parse(_playStoreUrl);
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Opened Play Store — check for updates'
              : 'Could not open Play Store',
        ),
      ),
    );
  }

  Future<void> _pickLanguage(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getString(_languageKey) ?? 'en';
    if (!context.mounted) return;

    final selected = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Language'),
        children: [
          for (final option in const [
            ('en', 'English'),
            ('hi', 'Hindi'),
            ('mr', 'Marathi'),
          ])
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, option.$1),
              child: Row(
                children: [
                  Icon(
                    current == option.$1
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    color: AppColors.navy,
                  ),
                  const SizedBox(width: 12),
                  Text(option.$2),
                ],
              ),
            ),
        ],
      ),
    );
    if (selected == null || selected == current) return;

    await prefs.setString(_languageKey, selected);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Restart app to apply')),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryDark]), borderRadius: BorderRadius.circular(24)), child: const Row(children: [AppModuleIcon(icon: Icons.settings_suggest_rounded, color: Colors.white, size: 56), SizedBox(width: 14), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Business control center', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)), SizedBox(height: 4), Text('Manage billing, printers and preferences', style: TextStyle(color: Colors.white70))]))])),
          const SizedBox(height: 18),
          _Section(
            title: 'Billing & catalog',
            children: [
              _RowTile(
                icon: Icons.receipt_long_rounded,
                title: 'Invoice Details',
                subtitle: "View today's bills and reprints",
                onTap: () => pushReportsUnlocked(
                  context,
                  ref,
                  route: '/reports/invoices',
                ),
              ),
              _RowTile(
                icon: Icons.bar_chart_rounded,
                title: 'Reports',
                subtitle: 'Sales overview and filters',
                onTap: () => pushReportsUnlocked(context, ref),
              ),
              _RowTile(
                icon: Icons.inventory_2_rounded,
                title: 'Master Data',
                subtitle: 'Categories, products & combos',
                onTap: () => context.push('/masters'),
              ),
              _RowTile(
                icon: Icons.account_tree_outlined,
                title: 'Subcategories',
                subtitle: 'Product subcategory master',
                onTap: () => context.push('/masters/subcategories'),
              ),
              _RowTile(
                icon: Icons.table_restaurant_outlined,
                title: 'Table Master',
                subtitle: 'Areas, types & tables',
                onTap: () => context.push('/masters/tables'),
              ),
            ],
          ),
          _Section(
            title: 'Store',
            children: [
              _RowTile(
                icon: Icons.storefront_rounded,
                title: 'Shop Details',
                subtitle: 'Business profile & cloud company',
                onTap: () => context.push('/settings/company'),
              ),
              _RowTile(
                icon: Icons.print_rounded,
                title: 'Printer Details',
                subtitle: 'Bluetooth / USB / Network & test print',
                onTap: () => context.push('/settings/devices'),
              ),
              _RowTile(
                icon: Icons.schedule_rounded,
                title: 'Business Hours',
                subtitle: 'Opening and closing times',
                onTap: () => context.push('/settings/business-hours'),
              ),
              _RowTile(
                icon: Icons.warehouse_rounded,
                title: 'Inventory Management',
                subtitle: 'Stock ledger',
                onTap: () => context.push('/inventory'),
              ),
              _RowTile(
                icon: Icons.payments_outlined,
                title: 'Expense Management',
                subtitle: 'Shop expenses',
                onTap: () => context.push('/inventory?tab=expenses'),
              ),
            ],
          ),
          _Section(
            title: 'Cloud & app',
            children: [
              _RowTile(
                icon: Icons.support_agent_rounded,
                title: 'Help & Support',
                subtitle: 'Tickets and contact',
                onTap: () => context.push('/support'),
              ),
              _RowTile(
                icon: Icons.cloud_download_rounded,
                title: 'Fetch / Synchronize',
                subtitle: 'Offline \u2194 cloud sync',
                onTap: () => context.push('/sync'),
              ),
              _RowTile(
                icon: Icons.system_update_rounded,
                title: 'Update App',
                subtitle: 'Open Play Store listing',
                onTap: () => _checkUpdate(context),
              ),
              _RowTile(
                icon: Icons.star_rate_rounded,
                title: 'Rate Us',
                subtitle: 'Open Play Store listing',
                onTap: () => _rateUs(context),
              ),
              _RowTile(
                icon: Icons.language_rounded,
                title: 'Language',
                subtitle: 'English / Hindi / Marathi',
                onTap: () => _pickLanguage(context),
              ),
              _RowTile(
                icon: Icons.info_outline_rounded,
                title: 'About',
                subtitle: AppConstants.appVersionLabel,
                onTap: () => context.push('/settings/about'),
              ),
              _RowTile(
                icon: Icons.share_rounded,
                title: 'Share App',
                subtitle: 'Invite others via Play Store link',
                onTap: () => context.push('/settings/share'),
              ),
            ],
          ),
          _Section(
            title: 'Account',
            children: [
              _RowTile(
                icon: Icons.pin_rounded,
                title: 'Change App Login PB-PIN',
                subtitle: 'Unlock with PB-PIN next launch',
                onTap: () => context.push('/settings/change-pin'),
              ),
              _RowTile(
                icon: Icons.logout_rounded,
                title: 'Logout',
                subtitle: 'Clear session on this device',
                onTap: () async {
                  final ok = await showAppConfirmBottomSheet(
                    context: context,
                    title: 'Logout',
                    message:
                        'Clear this device session and return to licence login?',
                    confirmLabel: 'Logout',
                    confirmVariant: AppButtonVariant.danger,
                    icon: Icons.logout_rounded,
                  );
                  if (ok) {
                    await ref.read(authControllerProvider.notifier).logout();
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            AppConstants.appVersionLabel,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.black45,
                ),
          ),
          Text(
            'Developed by POS Billingwala',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.black38,
                ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 6, 4, 10),
            child: Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900, color: AppColors.navy,
            )),
          ),
          AppCard(
            padding: EdgeInsets.zero,
            accentColor: AppColors.primary,
            child: Column(children: children),
          ),
        ],
      ),
    );
  }
}

class _RowTile extends StatelessWidget {
  const _RowTile({required this.icon, required this.title, required this.subtitle, required this.onTap});
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  Color get _color {
    const colors = [
      AppColors.primary, AppColors.orange, AppColors.green,
      AppColors.purple, AppColors.red, AppColors.teal,
    ];
    return colors[icon.codePoint % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      minVerticalPadding: 12,
      onTap: onTap,
      leading: AppModuleIcon(icon: icon, color: _color, size: 48),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.navy)),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 3),
        child: Text(subtitle, style: TextStyle(color: AppColors.navy.withValues(alpha: .55))),
      ),
      trailing: Container(
        width: 34, height: 34,
        decoration: BoxDecoration(color: _color.withValues(alpha: .09), shape: BoxShape.circle),
        child: Icon(Icons.arrow_forward_ios_rounded, size: 14, color: _color),
      ),
    );
  }
}
