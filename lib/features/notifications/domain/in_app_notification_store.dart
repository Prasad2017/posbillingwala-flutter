import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class InAppNotification {
  const InAppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.createdAt,
    this.read = false,
    this.url,
  });

  final String id;
  final String title;
  final String body;
  final String type;
  final DateTime createdAt;
  final bool read;
  final String? url;

  InAppNotification copyWith({bool? read}) {
    return InAppNotification(
      id: id,
      title: title,
      body: body,
      type: type,
      createdAt: createdAt,
      read: read ?? this.read,
      url: url,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'type': type,
        'createdAt': createdAt.toIso8601String(),
        'read': read,
        'url': url,
      };

  factory InAppNotification.fromJson(Map<String, dynamic> json) {
    return InAppNotification(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Notification',
      body: json['body']?.toString() ?? '',
      type: json['type']?.toString() ?? 'promotional',
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      read: json['read'] == true,
      url: json['url']?.toString(),
    );
  }
}

class InAppNotificationStore {
  static const _key = 'in_app_notifications_v1';
  static const _max = 50;

  Future<List<InAppNotification>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .whereType<Map>()
          .map((e) => InAppNotification.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> save(List<InAppNotification> items) async {
    final prefs = await SharedPreferences.getInstance();
    final clipped = items.take(_max).toList();
    await prefs.setString(
      _key,
      jsonEncode(clipped.map((e) => e.toJson()).toList()),
    );
  }

  Future<List<InAppNotification>> add(InAppNotification item) async {
    final current = await load();
    final next = [item, ...current.where((e) => e.id != item.id)];
    await save(next);
    return next;
  }

  Future<List<InAppNotification>> markRead(String id) async {
    final current = await load();
    final next = current
        .map((e) => e.id == id ? e.copyWith(read: true) : e)
        .toList();
    await save(next);
    return next;
  }

  Future<List<InAppNotification>> markAllRead() async {
    final current = await load();
    final next = current.map((e) => e.copyWith(read: true)).toList();
    await save(next);
    return next;
  }
}
