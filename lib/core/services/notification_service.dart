// lib/core/services/notification_service.dart
import 'dart:convert';
import 'package:circleslate/core/network/endpoints.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AppNotification {
  final String id;
  final String title;
  final String body;
  final String? eventId;
  final String? conversationId;
  final String? conversationName;
  final String? chatPartnerId;
  final String? chatPartnerName;
  final bool isGroupChat;
  bool isRead;
  final DateTime timestamp;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    this.eventId,
    this.conversationId,
    this.conversationName,
    this.chatPartnerId,
    this.chatPartnerName,
    required this.isGroupChat,
    required this.isRead,
    required this.timestamp,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'],
      title: json['title'] ?? '',
      body: json['message'] ?? '',
      eventId: json['extra_data']?['event_id'],
      conversationId: json['conversation'],
      conversationName: json['conversation_name'],
      chatPartnerId: json['sender']?['id']?.toString(),
      chatPartnerName: json['sender']?['full_name'],
      isGroupChat: json['notification_type'] == "group_add",
      isRead: json['is_read'] ?? false,
      timestamp: DateTime.parse(json['created_at']),
    );
  }
}

class NotificationService {
  final String _baseUrl = Urls.notifications;

  Future<List<AppNotification>> fetchNotifications({int limit = 5101}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');

    if (token == null) {
      throw Exception('No access token found in SharedPreferences.');
    }

    final response = await http.get(
      Uri.parse('$_baseUrl?limit=$limit'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final notificationsJson = data['notifications'] as List;
      return notificationsJson
          .map((json) => AppNotification.fromJson(json))
          .toList();
    } else {
      throw Exception(
        'Failed to fetch notifications: ${response.statusCode} ${response.body}',
      );
    }
  }

  Future<void> markAsRead(String notificationId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');

    if (token == null) {
      throw Exception('No access token found in SharedPreferences.');
    }

    final response = await http.post(
      Uri.parse('$_baseUrl$notificationId/read/'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to mark notification as read: ${response.statusCode} ${response.body}',
      );
    }
  }

  Future<int> getUnreadCount() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');

    print('🔑 Access Token: $token');

    if (token == null) {
      print('⚠️ No token found, returning 0');
      return 0;
    }

    final url = Uri.parse(Urls.unreadNotificationCount);
    print('🌐 Sending request to: $url');

    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print('✅ Decoded Response: $data');

      final unreadCount = data['unread_count'] ?? 0;
      print('🔢 Unread Count: $unreadCount');
      return unreadCount;
    } else {
      print('❌ Request failed with status: ${response.statusCode}');
      return 0;
    }
  }
}
