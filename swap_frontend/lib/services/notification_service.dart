import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config.dart';
import '../models/notification.dart';

class NotificationService {
  final String baseUrl;
  NotificationService({String? baseUrl})
      : baseUrl = baseUrl ?? AppConfig.apiBaseUrl;

  Future<List<AppNotification>> getNotifications(String uid, {int limit = 50}) async {
    final uri = Uri.parse('$baseUrl/notifications?uid=$uid&limit=$limit');
    try {
      final resp = await http.get(uri).timeout(const Duration(seconds: 8));
      if (resp.statusCode != 200) throw Exception('${resp.statusCode}');
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final list = data['notifications'] as List<dynamic>;
      return list.map((e) => AppNotification.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('[NotificationService] getNotifications error: $e');
      return [];
    }
  }

  Future<int> getUnreadCount(String uid) async {
    final uri = Uri.parse('$baseUrl/notifications/unread-count?uid=$uid');
    try {
      final resp = await http.get(uri).timeout(const Duration(seconds: 8));
      if (resp.statusCode != 200) return 0;
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      return data['unread_count'] as int? ?? 0;
    } catch (e) {
      debugPrint('[NotificationService] getUnreadCount error: $e');
      return 0;
    }
  }

  Future<void> markRead(String notificationId, String uid) async {
    final uri = Uri.parse('$baseUrl/notifications/$notificationId/read?uid=$uid');
    try {
      await http.patch(uri).timeout(const Duration(seconds: 8));
    } catch (e) {
      debugPrint('[NotificationService] markRead error: $e');
    }
  }

  Future<void> markAllRead(String uid) async {
    final uri = Uri.parse('$baseUrl/notifications/read-all?uid=$uid');
    try {
      await http.patch(uri).timeout(const Duration(seconds: 8));
    } catch (e) {
      debugPrint('[NotificationService] markAllRead error: $e');
    }
  }
}
