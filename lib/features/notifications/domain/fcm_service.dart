import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:pos_billingwala_v2/core/network/api_client.dart';
import 'package:pos_billingwala_v2/features/auth/data/device_identity_service.dart';
import 'package:pos_billingwala_v2/features/notifications/data/fcm_api.dart';
import 'package:pos_billingwala_v2/features/notifications/domain/in_app_notification_store.dart';
import 'package:pos_billingwala_v2/features/notifications/domain/notification_navigator.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _pendingMessTokensKey = 'pending_mess_meal_tokens_v1';

/// Background isolate entry — must be top-level.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  await FcmService.handleIncomingMessage(message, fromBackground: true);
}

class FcmService {
  FcmService({
    ApiClient? apiClient,
    DeviceIdentityService? deviceIdentity,
  })  : _api = FcmApi(apiClient ?? ApiClient()),
        _deviceIdentity = deviceIdentity ?? DeviceIdentityService();

  final FcmApi _api;
  final DeviceIdentityService _deviceIdentity;
  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  static const channelId = 'pos_push_alerts';
  static bool _initialized = false;

  /// Last opened notification type/url (for debugging / deferred navigation).
  static String? lastOpenedType;
  static String? lastOpenedUrl;

  Future<void> initialize() async {
    if (kIsWeb || _initialized) return;
    try {
      await Firebase.initializeApp();
    } catch (e) {
      debugPrint('Firebase init skipped/failed: $e');
      return;
    }

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    await _local.initialize(
      settings: const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload == null || payload.isEmpty) return;
        try {
          final map = jsonDecode(payload) as Map<String, dynamic>;
          _openFromData(map);
        } catch (_) {}
      },
    );

    const channel = AndroidNotificationChannel(
      channelId,
      'POS Alerts',
      description: 'Licence, promo, and mess alerts',
      importance: Importance.high,
    );
    await _local
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    FirebaseMessaging.onMessage.listen((message) {
      handleIncomingMessage(message, fromBackground: false);
    });

    FirebaseMessaging.onMessageOpenedApp.listen(_handleOpenedMessage);

    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) {
      // Defer until navigator is ready.
      Future<void>.delayed(const Duration(milliseconds: 800), () {
        _handleOpenedMessage(initial);
      });
    }

    FirebaseMessaging.instance.onTokenRefresh.listen((token) async {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('fcm_last_user_id') ?? '';
      if (userId.isEmpty) return;
      await registerForUser(userId);
    });

    _initialized = true;
  }

  static void _handleOpenedMessage(RemoteMessage message) {
    _openFromData(message.data);
  }

  static void _openFromData(Map<String, dynamic> data) {
    final type = (data['type'] ?? data['event'] ?? '').toString();
    final url = data['url']?.toString();
    lastOpenedType = type;
    lastOpenedUrl = url;
    // Uses rootNavigatorKey from router.dart when no BuildContext is available.
    openNotificationTargetFromKey(type: type, url: url);
  }

  Future<void> registerForUser(String userId) async {
    if (kIsWeb || userId.isEmpty) return;
    try {
      if (!_initialized) await initialize();
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null || token.isEmpty) return;
      final device = await _deviceIdentity.resolve();
      await _api.registerToken(
        userId: userId,
        deviceId: device.deviceId,
        fcmToken: token,
      );
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('fcm_last_user_id', userId);
    } catch (e) {
      debugPrint('FCM register failed: $e');
    }
  }

  Future<void> clearForUser(String userId) async {
    if (kIsWeb || userId.isEmpty) return;
    try {
      final device = await _deviceIdentity.resolve();
      await _api.registerToken(
        userId: userId,
        deviceId: device.deviceId,
        fcmToken: '',
      );
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('fcm_last_user_id');
      await FirebaseMessaging.instance.deleteToken();
    } catch (e) {
      debugPrint('FCM clear failed: $e');
    }
  }

  static Future<void> handleIncomingMessage(
    RemoteMessage message, {
    required bool fromBackground,
  }) async {
    final data = message.data;
    final type = (data['type'] ?? data['event'] ?? '').toString();

    if (type == 'mess.token.created') {
      await _enqueueMessToken(data);
      return;
    }

    final title = (message.notification?.title ??
            data['title'] ??
            (type == 'license_expiring' ? 'Licence expiring' : 'POS Billingwala'))
        .toString();
    final body = (message.notification?.body ??
            data['body'] ??
            data['message'] ??
            '')
        .toString();

    final store = InAppNotificationStore();
    await store.add(
      InAppNotification(
        id: message.messageId ??
            '${DateTime.now().millisecondsSinceEpoch}_$type',
        title: title,
        body: body,
        type: type.isEmpty ? 'promotional' : type,
        createdAt: DateTime.now(),
        url: data['url']?.toString(),
      ),
    );

    if (fromBackground) return;

    final payload = jsonEncode({
      'type': type.isEmpty ? 'promotional' : type,
      'url': data['url']?.toString() ?? '',
    });

    final local = FlutterLocalNotificationsPlugin();
    await local.show(
      id: title.hashCode ^ body.hashCode,
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          'POS Alerts',
          channelDescription: 'Licence, promo, and mess alerts',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: payload,
    );
  }

  static Future<void> _enqueueMessToken(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_pendingMessTokensKey);
    final list = <Map<String, dynamic>>[];
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw) as List<dynamic>;
        list.addAll(
          decoded.whereType<Map>().map((e) => Map<String, dynamic>.from(e)),
        );
      } catch (_) {}
    }
    list.insert(0, {
      'tokenId': data['tokenId']?.toString() ?? '',
      'tokenNumber': data['tokenNumber']?.toString() ?? '',
      'registrationNo': data['registrationNo']?.toString() ?? '',
      'mealSession': data['mealSession']?.toString() ?? '',
      'date': data['date']?.toString() ?? '',
      'createdAt': data['createdAt']?.toString() ??
          DateTime.now().toIso8601String(),
      'printStatus': data['printStatus']?.toString() ?? 'RECEIVED',
    });
    await prefs.setString(
      _pendingMessTokensKey,
      jsonEncode(list.take(100).toList()),
    );
  }

  static Future<List<Map<String, dynamic>>> loadPendingMessTokens() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_pendingMessTokensKey);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } catch (_) {
      return const [];
    }
  }
}
