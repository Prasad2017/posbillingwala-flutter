import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pos_billingwala_v2/core/constants/app_colors.dart';
import 'package:pos_billingwala_v2/core/constants/app_constants.dart';
import 'package:pos_billingwala_v2/core/widgtes/widgtes.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

class ShareAppPage extends StatelessWidget {
  const ShareAppPage({super.key});

  static const _playStoreLink =
      'https://play.google.com/store/apps/details?id=com.pos_billingwala';

  Future<void> _share(BuildContext context) async {
    final box = context.findRenderObject() as RenderBox?;
    final text =
        'Try ${AppConstants.appName} — smart POS billing for shops & restaurants.\n'
        'Download: $_playStoreLink\n'
        'Learn more: ${AppConstants.website}';
    await SharePlus.instance.share(
      ShareParams(
        text: text,
        subject: AppConstants.appName,
        sharePositionOrigin: box == null
            ? null
            : box.localToGlobal(Offset.zero) & box.size,
      ),
    );
  }

  Future<void> _copyLink(BuildContext context) async {
    await Clipboard.setData(const ClipboardData(text: _playStoreLink));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Play Store link copied')),
    );
  }

  void _showQr(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Share QR'),
        content: SizedBox(
          width: 240,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              QrImageView(
                data: _playStoreLink,
                size: 220,
                backgroundColor: Colors.white,
              ),
              const SizedBox(height: 12),
              Text(
                'Scan to open Play Store',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Share App')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AppCard(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Icon(
                  Icons.share_rounded,
                  size: 48,
                  color: AppColors.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  'Share ${AppConstants.appName}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Invite other shop owners with a Play Store link.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    AppButton(
                      label: 'Share now',
                      icon: Icons.share_rounded,
                      expanded: false,
                      onPressed: () => _share(context),
                    ),
                    AppButton(
                      label: 'Copy link',
                      icon: Icons.copy_rounded,
                      variant: AppButtonVariant.outlined,
                      expanded: false,
                      onPressed: () => _copyLink(context),
                    ),
                    AppButton(
                      label: 'Show QR',
                      icon: Icons.qr_code_2_rounded,
                      variant: AppButtonVariant.outlined,
                      expanded: false,
                      onPressed: () => _showQr(context),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
