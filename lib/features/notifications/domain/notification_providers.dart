import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_billingwala_v2/features/auth/domain/auth_controller.dart';
import 'package:pos_billingwala_v2/features/notifications/domain/fcm_service.dart';
import 'package:pos_billingwala_v2/features/notifications/domain/in_app_notification_store.dart';

final fcmServiceProvider = Provider<FcmService>((ref) {
  return FcmService(apiClient: ref.watch(apiClientProvider));
});

final inAppNotificationsProvider =
    NotifierProvider<InAppNotificationsController, List<InAppNotification>>(
  InAppNotificationsController.new,
);

class InAppNotificationsController extends Notifier<List<InAppNotification>> {
  final _store = InAppNotificationStore();

  @override
  List<InAppNotification> build() {
    Future.microtask(reload);
    return const [];
  }

  Future<void> reload() async {
    state = await _store.load();
  }

  Future<void> markRead(String id) async {
    state = await _store.markRead(id);
  }

  Future<void> markAllRead() async {
    state = await _store.markAllRead();
  }

  int get unreadCount => state.where((e) => !e.read).length;
}

final unreadNotificationCountProvider = Provider<int>((ref) {
  return ref.watch(inAppNotificationsProvider).where((e) => !e.read).length;
});
