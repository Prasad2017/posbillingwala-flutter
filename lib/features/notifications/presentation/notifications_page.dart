import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pos_billingwala_v2/core/constants/app_colors.dart';
import 'package:pos_billingwala_v2/features/notifications/domain/fcm_service.dart';
import 'package:pos_billingwala_v2/features/notifications/domain/notification_navigator.dart';
import 'package:pos_billingwala_v2/features/notifications/domain/notification_providers.dart';
import 'package:pos_billingwala_v2/core/widgtes/widgtes.dart';

class NotificationsPage extends ConsumerStatefulWidget {
  const NotificationsPage({super.key});

  @override
  ConsumerState<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends ConsumerState<NotificationsPage> {
  List<Map<String, dynamic>> _messTokens = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(inAppNotificationsProvider.notifier).reload();
      final tokens = await FcmService.loadPendingMessTokens();
      if (mounted) setState(() => _messTokens = tokens);
    });
  }

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(inAppNotificationsProvider);
    final time = DateFormat('dd MMM, hh:mm a');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: () =>
                ref.read(inAppNotificationsProvider.notifier).markAllRead(),
            child: const Text(
              'Mark all read',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_messTokens.isNotEmpty) ...[
            Text(
              'Pending mess meal tokens',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 8),
            ..._messTokens.take(20).map(
                  (t) => AppCard(
            color: AppColors.warning.withValues(alpha: 0.12),
            padding: EdgeInsets.zero,
            child: ListTile(
                      leading: const Icon(Icons.qr_code_2_rounded),
                      title: Text(
                        t['tokenNumber']?.toString().isNotEmpty == true
                            ? t['tokenNumber'].toString()
                            : 'Meal token',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(
                        [
                          if ((t['mealSession']?.toString() ?? '').isNotEmpty)
                            t['mealSession'],
                          if ((t['registrationNo']?.toString() ?? '')
                              .isNotEmpty)
                            t['registrationNo'],
                        ].join(' Â· '),
                      ),
                    ),
                  ),
                ),
            const SizedBox(height: 16),
          ],
          Text(
            'Alerts',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 8),
          if (items.isEmpty)
            const AppCard(
            padding: EdgeInsets.zero,
            child: ListTile(
                leading: Icon(Icons.notifications_none_rounded),
                title: Text('No alerts yet'),
                subtitle: Text('Licence and promo pushes appear here.'),
              ),
            )
          else
            ...items.map(
              (n) => AppCard(
            color: n.read ? null : AppColors.primaryLight,
            padding: EdgeInsets.zero,
            child: ListTile(
                  onTap: () async {
                    await ref
                        .read(inAppNotificationsProvider.notifier)
                        .markRead(n.id);
                    if (!context.mounted) return;
                    await openNotificationTarget(
                      context,
                      type: n.type,
                      url: n.url,
                    );
                  },
                  leading: Icon(
                    n.type == 'license_expiring'
                        ? Icons.warning_amber_rounded
                        : Icons.campaign_rounded,
                    color: AppColors.primary,
                  ),
                  title: Text(
                    n.title,
                    style: TextStyle(
                      fontWeight: n.read ? FontWeight.w600 : FontWeight.w800,
                    ),
                  ),
                  subtitle: Text(
                    '${n.body}\n${time.format(n.createdAt)}',
                  ),
                  isThreeLine: true,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
