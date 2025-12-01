// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import 'package:shared_preferences/shared_preferences.dart';

// // Add your MessageSender enum if it's not imported
// enum MessageSender { user, other }

// class MessageModel {
//   final String id;
//   final String content;
//   final MessageSender sender;
//   final DateTime timestamp;
//   final bool isRead;
//   final bool isOwnMessage;

//   // Sender details
//   final String senderId;
//   final String senderName;
//   final String senderEmail;

//   MessageModel({
//     required this.id,
//     required this.content,
//     required this.sender,
//     required this.timestamp,
//     required this.isRead,
//     required this.isOwnMessage,
//     required this.senderId,
//     required this.senderName,
//     required this.senderEmail,
//   });

//   factory MessageModel.fromJson(Map<String, dynamic> json) {
//     return MessageModel(
//       id: json['id'],
//       content: json['content'],
//       senderId: json['sender']['id'].toString(),
//       senderName: json['sender']['full_name'],
//       senderEmail: json['sender']['email'],
//       timestamp: DateTime.parse(json['timestamp']),
//       isRead: json['is_read'] ?? false,
//       isOwnMessage: json['is_own_message'] ?? false,
//       sender: json['is_own_message'] == true ? MessageSender.user : MessageSender.other,
//     );
//   }

//   Map<String, dynamic> toJson() => {
//     'id': id,
//     'content': content,
//     'sender': {
//       'id': senderId,
//       'full_name': senderName,
//       'email': senderEmail,
//     },
//     'timestamp': timestamp.toIso8601String(),
//     'is_read': isRead,
//     'is_own_message': isOwnMessage,
//   };

//   // For backward compatibility with your existing Message class
//   String get message => content;
//   String get receiverId => ''; // Not used in the new format
// }

// // Also update your chat API service to handle the new format
// class ChatApiService {
//   // Update this method to match your actual API
//   Future<List<MessageModel>> fetchChatHistory(String conversationId) async {
//     // Make API call to get conversation messages
//     // The endpoint should return the JSON format you showed

//     try {
//       // Get token from SharedPreferences (same as WebSocket service)
//       final prefs = await SharedPreferences.getInstance();
//       final token = prefs.getString('accessToken');

//       if (token == null) {
//         throw Exception('Authentication token not found');
//       }

//       // Replace with your actual HTTP call
//       final response = await http.get(
//         Uri.parse('https://app.circleslate.com/api/conversations/$conversationId/messages/'),
//         headers: {
//           'Authorization': 'Bearer $token',
//           'Content-Type': 'application/json',
//         },
//       );

//       if (response.statusCode == 200) {
//         final data = jsonDecode(response.body);
//         final messages = data['messages'] as List;
//         return messages.map((msg) => MessageModel.fromJson(msg)).toList();
//       } else {
//         throw Exception('Failed to load chat history');
//       }
//     } catch (e) {
//       print('Error fetching chat history: $e');
//       rethrow;
//     }
//   }
// }