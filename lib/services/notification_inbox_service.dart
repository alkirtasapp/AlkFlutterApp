import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:alkirtas/utils/logging/logger.dart';

/// A notification already broadcast from the back office.
class InboxNotification {
  final int id;
  final String title;
  final String body;
  final String imageUrl;
  final DateTime date;

  /// Same keys as the push data (product_id, category_id, screen), so
  /// PushNotificationService.onTap can open it.
  final Map<String, dynamic> data;

  const InboxNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.imageUrl,
    required this.date,
    required this.data,
  });

  factory InboxNotification.fromJson(Map<String, dynamic> json) {
    return InboxNotification(
      id: int.tryParse(json['id'].toString()) ?? 0,
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      imageUrl: json['image_url']?.toString() ?? '',
      date: DateTime.tryParse(json['date']?.toString() ?? '')?.toLocal() ??
          DateTime.now(),
      data: json['data'] is Map
          ? Map<String, dynamic>.from(json['data'] as Map)
          : const {},
    );
  }

  /// Whether tapping it opens something more than the app itself.
  bool get hasTarget => data.isNotEmpty;
}

/// Notification history, read from the alkirtas_push PrestaShop module.
///
/// The back office is the only source of truth: a notification deleted there
/// disappears here on the next refresh. The phone only remembers which ids
/// were read, for the unread badge.
class NotificationInboxService {
  NotificationInboxService._();

  static const String _url = 'https://www.alkirtas.com/module/alkirtas_push/inbox';
  static const String _readKey = 'inbox_read_ids';

  static List<InboxNotification> items = const [];
  static Set<int> _readIds = {};

  /// Unread count for the bell badge.
  static final ValueNotifier<int> unreadCount = ValueNotifier(0);

  static Future<void>? _refreshing;

  /// Fetches the list; concurrent calls share one request. Keeps the last
  /// list when offline.
  static Future<void> refresh() =>
      _refreshing ??= _refresh().whenComplete(() => _refreshing = null);

  static Future<void> _refresh() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _readIds = (prefs.getStringList(_readKey) ?? const [])
          .map(int.tryParse)
          .whereType<int>()
          .toSet();

      final response =
          await http.get(Uri.parse(_url)).timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) {
        AlkLoggerHelper.warning('Notification inbox HTTP ${response.statusCode}');
        return;
      }
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      items = ((decoded['items'] as List?) ?? const [])
          .whereType<Map>()
          .map((e) => InboxNotification.fromJson(Map<String, dynamic>.from(e)))
          .toList();

      // Forget read ids of notifications that were deleted or expired.
      final ids = items.map((n) => n.id).toSet();
      _readIds = _readIds.intersection(ids);
      await _saveRead(prefs);
    } catch (e) {
      AlkLoggerHelper.warning('Notification inbox refresh failed: $e');
    } finally {
      _updateUnread();
    }
  }

  static bool isRead(InboxNotification n) => _readIds.contains(n.id);

  static Future<void> markRead(InboxNotification n) async {
    if (!_readIds.add(n.id)) return;
    _updateUnread();
    await _saveRead(await SharedPreferences.getInstance());
  }

  static Future<void> markAllRead() async {
    _readIds.addAll(items.map((n) => n.id));
    _updateUnread();
    await _saveRead(await SharedPreferences.getInstance());
  }

  static void _updateUnread() {
    unreadCount.value = items.where((n) => !_readIds.contains(n.id)).length;
  }

  static Future<void> _saveRead(SharedPreferences prefs) =>
      prefs.setStringList(_readKey, _readIds.map((id) => '$id').toList());
}
