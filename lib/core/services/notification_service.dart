// // import 'dart:convert';
// // import 'package:circleslate/core/network/endpoints.dart';
// // import 'package:http/http.dart' as http;
// // import 'package:shared_preferences/shared_preferences.dart';
// //
// // class AppNotification {
// //   final String id;
// //   final String title;
// //   final String body;
// //   final DateTime timestamp;
// //   bool isRead;
// //   final String? conversationId;
// //   final String? chatPartnerId;
// //   final String chatPartnerName;
// //   final bool isGroupChat;
// //   final String? conversationName;
// //
// //   AppNotification({
// //     required this.id,
// //     required this.title,
// //     required this.body,
// //     required this.timestamp,
// //     this.isRead = false,
// //     required this.conversationId,
// //     this.chatPartnerId,
// //     required this.chatPartnerName,
// //     required this.isGroupChat,
// //     this.conversationName,
// //   });
// //
// //   factory AppNotification.fromJson(Map<String, dynamic> json) {
// //     final sender = json['sender'];
// //     String chatPartnerName = 'Unknown';
// //     if (sender != null && sender is Map) {
// //       chatPartnerName = (sender['full_name'] ?? 'Unknown').toString();
// //     }
// //
// //     return AppNotification(
// //       id: json['id'],
// //       title: json['title'],
// //       body: json['message'],
// //       timestamp: DateTime.parse(json['created_at']),
// //       isRead: json['is_read'] ?? false,
// //       conversationId: json['conversation']?.toString(),
// //       chatPartnerId: sender != null && sender['id'] != null ? sender['id'].toString() : null,
// //       chatPartnerName: chatPartnerName,
// //       conversationName: json['conversation_name']?.toString(),
// //       isGroupChat: (json['conversation_name'] ?? '').toString().toLowerCase().contains('team'),
// //     );
// //   }
// //
// // }
// //
// // class NotificationService {
// //   final String _baseUrl = 'http://72.60.26.57/api/chat/notifications/';
// //
// //   /// Fetch notifications from API
// //   Future<List<AppNotification>> fetchNotifications({int limit = 5101}) async {
// //     final prefs = await SharedPreferences.getInstance();
// //     final token = prefs.getString('accessToken');
// //
// //     if (token == null) {
// //       throw Exception('No access token found in SharedPreferences.');
// //     }
// //
// //     final response = await http.get(
// //       Uri.parse('$_baseUrl?limit=$limit'),
// //       headers: {
// //         'Authorization': 'Bearer $token',
// //       },
// //     );
// //
// //     if (response.statusCode == 200) {
// //       final data = jsonDecode(response.body);
// //       final notificationsJson = data['notifications'] as List;
// //       return notificationsJson
// //           .map((json) => AppNotification.fromJson(json))
// //           .toList();
// //     } else {
// //       throw Exception(
// //           'Failed to fetch notifications: ${response.statusCode} ${response.body}');
// //     }
// //   }
// //
// //   /// Mark a notification as read
// //   Future<void> markAsRead(String notificationId) async {
// //     final prefs = await SharedPreferences.getInstance();
// //     final token = prefs.getString('accessToken');
// //
// //     if (token == null) {
// //       throw Exception('No access token found in SharedPreferences.');
// //     }
// //
// //     final response = await http.post(
// //       Uri.parse('$_baseUrl$notificationId/read/'),
// //       headers: {
// //         'Authorization': 'Bearer $token',
// //       },
// //     );
// //
// //     if (response.statusCode != 200) {
// //       throw Exception(
// //           'Failed to mark notification as read: ${response.statusCode} ${response.body}');
// //     }
// //   }
// //
// //
// //   Future<int> getUnreadCount() async {
// //     final prefs = await SharedPreferences.getInstance();
// //     final token = prefs.getString('accessToken');
// //
// //     print('🔑 Access Token: $token');
// //
// //     if (token == null) {
// //       print('⚠️ No token found, returning 0');
// //       return 0;
// //     }
// //
// //     final url = Uri.parse('${Urls.baseUrl}/chat/notifications/unread-count/');
// //     print('🌐 Sending request to: $url');
// //
// //     final response = await http.get(
// //       url,
// //       headers: {
// //         'Authorization': 'Bearer $token',
// //       },
// //     );
// //
// //     print('📩 Response Status Code: ${response.statusCode}');
// //     print('📩 Response Body: ${response.body}');
// //
// //     if (response.statusCode == 200) {
// //       final data = jsonDecode(response.body);
// //       print('✅ Decoded Response: $data');
// //
// //       final unreadCount = data['unread_count'] ?? 0;
// //       print('🔢 Unread Count: $unreadCount');
// //       return unreadCount;
// //     } else {
// //       print('❌ Request failed with status: ${response.statusCode}');
// //       return 0;
// //     }
// //   }
// //
// // }
//
//
//
//
// import 'dart:convert';
// import 'package:circleslate/core/network/endpoints.dart';
// import 'package:http/http.dart' as http;
// import 'package:shared_preferences/shared_preferences.dart';
//
// class AppNotification {
//   final String id;
//   final String title;
//   final String body;
//   final DateTime timestamp;
//   bool isRead;
//   final String? conversationId;
//   final String? chatPartnerId;
//   final String chatPartnerName;
//   final bool isGroupChat;
//   final String? conversationName;
//
//   AppNotification({
//     required this.id,
//     required this.title,
//     required this.body,
//     required this.timestamp,
//     this.isRead = false,
//     required this.conversationId,
//     this.chatPartnerId,
//     required this.chatPartnerName,
//     required this.isGroupChat,
//     this.conversationName,
//   });
//
//   factory AppNotification.fromJson(Map<String, dynamic> json) {
//     final sender = json['sender'];
//     String chatPartnerName = 'Unknown';
//     if (sender != null && sender is Map) {
//       chatPartnerName = (sender['full_name'] ?? 'Unknown').toString();
//     }
//
//     // Handle is_read as String or bool
//     bool isReadValue = false;
//     if (json['is_read'] != null) {
//       if (json['is_read'] is bool) {
//         isReadValue = json['is_read'] as bool;
//       } else if (json['is_read'] is String) {
//         isReadValue = json['is_read'].toLowerCase() == 'true';
//       }
//     }
//
//     return AppNotification(
//       id: json['id'],
//       title: json['title'],
//       body: json['message'],
//       timestamp: DateTime.parse(json['created_at']),
//       isRead: isReadValue,
//       conversationId: json['conversation']?.toString(),
//       chatPartnerId: sender != null && sender['id'] != null ? sender['id'].toString() : null,
//       chatPartnerName: chatPartnerName,
//       conversationName: json['conversation_name']?.toString(),
//       isGroupChat: (json['conversation_name'] ?? '').toString().toLowerCase().contains('team'),
//     );
//   }
// }
//
// class NotificationService {
//   final String _baseUrl = 'http://72.60.26.57/api/chat/notifications/';
//
//   /// Fetch notifications from API
//   Future<List<AppNotification>> fetchNotifications({int limit = 5101}) async {
//     final prefs = await SharedPreferences.getInstance();
//     final token = prefs.getString('accessToken');
//
//     if (token == null) {
//       throw Exception('No access token found in SharedPreferences.');
//     }
//
//     final response = await http.get(
//       Uri.parse('$_baseUrl?limit=$limit'),
//       headers: {
//         'Authorization': 'Bearer $token',
//       },
//     );
//
//     if (response.statusCode == 200) {
//       final data = jsonDecode(response.body);
//       final notificationsJson = data['notifications'] as List;
//       return notificationsJson
//           .map((json) => AppNotification.fromJson(json))
//           .toList();
//     } else {
//       throw Exception(
//           'Failed to fetch notifications: ${response.statusCode} ${response.body}');
//     }
//   }
//
//   /// Mark a notification as read
//   Future<void> markAsRead(String notificationId) async {
//     final prefs = await SharedPreferences.getInstance();
//     final token = prefs.getString('accessToken');
//
//     if (token == null) {
//       throw Exception('No access token found in SharedPreferences.');
//     }
//
//     final response = await http.post(
//       Uri.parse('$_baseUrl$notificationId/read/'),
//       headers: {
//         'Authorization': 'Bearer $token',
//       },
//     );
//
//     if (response.statusCode != 200) {
//       throw Exception(
//           'Failed to mark notification as read: ${response.statusCode} ${response.body}');
//     }
//   }
//
//   Future<int> getUnreadCount() async {
//     final prefs = await SharedPreferences.getInstance();
//     final token = prefs.getString('accessToken');
//
//     print('🔑 Access Token: $token');
//
//     if (token == null) {
//       print('⚠️ No token found, returning 0');
//       return 0;
//     }
//
//     final url = Uri.parse('${Urls.baseUrl}/chat/notifications/unread-count/');
//     print('🌐 Sending request to: $url');
//
//     final response = await http.get(
//       url,
//       headers: {
//         'Authorization': 'Bearer $token',
//       },
//     );
//
//     print('📩 Response Status Code: ${response.statusCode}');
//     print('📩 Response Body: ${response.body}');
//
//     if (response.statusCode == 200) {
//       final data = jsonDecode(response.body);
//       print('✅ Decoded Response: $data');
//
//       final unreadCount = data['unread_count'] ?? 0;
//       print('🔢 Unread Count: $unreadCount');
//       return unreadCount;
//     } else {
//       print('❌ Request failed with status: ${response.statusCode}');
//       return 0;
//     }
//   }
// }


//
//
// import 'dart:convert';
// import 'package:circleslate/core/network/endpoints.dart';
// import 'package:http/http.dart' as http;
// import 'package:shared_preferences/shared_preferences.dart';
//
// class AppNotification {
//   final String id;
//   final String title;
//   final String body;
//   final DateTime timestamp;
//   bool isRead;
//   final String? conversationId;
//   final String? chatPartnerId;
//   final String chatPartnerName;
//   final bool isGroupChat;
//   final String? conversationName;
//
//   AppNotification({
//     required this.id,
//     required this.title,
//     required this.body,
//     required this.timestamp,
//     this.isRead = false,
//     required this.conversationId,
//     this.chatPartnerId,
//     required this.chatPartnerName,
//     required this.isGroupChat,
//     this.conversationName,
//   });
//
//   factory AppNotification.fromJson(Map<String, dynamic> json) {
//     final sender = json['sender'];
//     String chatPartnerName = 'Unknown';
//     if (sender != null && sender is Map) {
//       chatPartnerName = (sender['full_name'] ?? 'Unknown').toString();
//     }
//
//     return AppNotification(
//       id: json['id'],
//       title: json['title'],
//       body: json['message'],
//       timestamp: DateTime.parse(json['created_at']),
//       isRead: json['is_read'] ?? false,
//       conversationId: json['conversation']?.toString(),
//       chatPartnerId: sender != null && sender['id'] != null ? sender['id'].toString() : null,
//       chatPartnerName: chatPartnerName,
//       conversationName: json['conversation_name']?.toString(),
//       isGroupChat: (json['conversation_name'] ?? '').toString().toLowerCase().contains('team'),
//     );
//   }
// }
//
//
// class NotificationService {
//   final String _baseUrl = '${Urls.baseUrl}/chat/notifications/';
//
//   /// Fetch notifications from API
//   Future<List<AppNotification>> fetchNotifications({int limit = 5101}) async {
//     final prefs = await SharedPreferences.getInstance();
//     final token = prefs.getString('accessToken');
//
//     if (token == null) {
//       throw Exception('No access token found in SharedPreferences.');
//     }
//
//     final response = await http.get(
//       Uri.parse('$_baseUrl?limit=$limit'),
//       headers: {
//         'Authorization': 'Bearer $token',
//       },
//     );
//
//     if (response.statusCode == 200) {
//       final data = jsonDecode(response.body);
//       final notificationsJson = data['notifications'] as List;
//       return notificationsJson
//           .map((json) => AppNotification.fromJson(json))
//           .toList();
//     } else {
//       throw Exception(
//           'Failed to fetch notifications: ${response.statusCode} ${response.body}');
//     }
//   }
//
//   /// Mark a notification as read
//   Future<void> markAsRead(String notificationId) async {
//     final prefs = await SharedPreferences.getInstance();
//     final token = prefs.getString('accessToken');
//
//     if (token == null) {
//       throw Exception('No access token found in SharedPreferences.');
//     }
//
//     final response = await http.post(
//       Uri.parse('$_baseUrl$notificationId/read/'),
//       headers: {
//         'Authorization': 'Bearer $token',
//       },
//     );
//
//     if (response.statusCode != 200) {
//       throw Exception(
//           'Failed to mark notification as read: ${response.statusCode} ${response.body}');
//     }
//   }
//
//
//   Future<int> getUnreadCount() async {
//     final prefs = await SharedPreferences.getInstance();
//     final token = prefs.getString('accessToken');
//
//     print('🔑 Access Token: $token');
//
//     if (token == null) {
//       print('⚠️ No token found, returning 0');
//       return 0;
//     }
//
//     final url = Uri.parse('${Urls.baseUrl}/chat/notifications/unread-count/');
//     print('🌐 Sending request to: $url');
//
//     final response = await http.get(
//       url,
//       headers: {
//         'Authorization': 'Bearer $token',
//       },
//     );
//
//     print('📩 Response Status Code: ${response.statusCode}');
//     print('📩 Response Body: ${response.body}');
//
//     if (response.statusCode == 200) {
//       final data = jsonDecode(response.body);
//       print('✅ Decoded Response: $data');
//
//       final unreadCount = data['unread_count'] ?? 0;
//       print('🔢 Unread Count: $unreadCount');
//       return unreadCount;
//     } else {
//       print('❌ Request failed with status: ${response.statusCode}');
//       return 0;
//     }
//   }
//
// }



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
  final String _baseUrl = '${Urls.baseUrl}/chat/notifications/';

  /// Fetch notifications from API
  Future<List<AppNotification>> fetchNotifications({int limit = 5101}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');

    if (token == null) {
      throw Exception('No access token found in SharedPreferences.');
    }

    final response = await http.get(
      Uri.parse('$_baseUrl?limit=$limit'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final notificationsJson = data['notifications'] as List;
      return notificationsJson
          .map((json) => AppNotification.fromJson(json))
          .toList();
    } else {
      throw Exception(
          'Failed to fetch notifications: ${response.statusCode} ${response.body}');
    }
  }

  /// Mark a notification as read
  Future<void> markAsRead(String notificationId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');

    if (token == null) {
      throw Exception('No access token found in SharedPreferences.');
    }

    final response = await http.post(
      Uri.parse('$_baseUrl$notificationId/read/'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception(
          'Failed to mark notification as read: ${response.statusCode} ${response.body}');
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

    final url = Uri.parse('${Urls.baseUrl}/chat/notifications/unread-count/');
    print('🌐 Sending request to: $url');

    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    print('📩 Response Status Code: ${response.statusCode}');
    print('📩 Response Body: ${response.body}');

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