import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pos_billingwala_v2/core/constants/app_colors.dart';
import 'package:pos_billingwala_v2/core/constants/app_constants.dart';
import 'package:pos_billingwala_v2/core/widgtes/widgtes.dart';
import 'package:pos_billingwala_v2/core/widgets/app_module_icon.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AppCard(
            accentColor: AppColors.primary,
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const AppModuleIcon(icon: Icons.point_of_sale_rounded, color: AppColors.primary, size: 76),
                const SizedBox(height: 16),
                Text(
                  AppConstants.appName,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 4),
                Text(AppConstants.appVersionLabel),
                const SizedBox(height: 16),
                const Divider(),
                const ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.code_rounded),
                  title: Text('Developer'),
                  subtitle: Text('POS Billingwala / Webus Labs'),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.language_rounded),
                  title: const Text('Website'),
                  subtitle: Text(AppConstants.website),
                  trailing: IconButton(
                    tooltip: 'Copy',
                    icon: const Icon(Icons.copy_rounded),
                    onPressed: () async {
                      await Clipboard.setData(
                        const ClipboardData(text: AppConstants.website),
                      );
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Website copied')),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
