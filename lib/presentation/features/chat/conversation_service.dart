import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../data/models/group_model.dart';
import '../../data/models/chat_model.dart';

class ChatService {
  static const String baseUrl = 'http://72.60.26.57/api/chat';


  static Future<String?> getOrCreateConversation(
      String currentUserId,
      String partnerId, {
        required String partnerName,
      }) async {
    try {
      debugPrint('[getOrCreateConversation] Starting with:');
      debugPrint('[getOrCreateConversation] currentUserId: $currentUserId (type: ${currentUserId.runtimeType})');
      debugPrint('[getOrCreateConversation] partnerId: $partnerId (type: ${partnerId.runtimeType})');
      debugPrint('[getOrCreateConversation] partnerName: $partnerName');

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('accessToken');
      if (token == null) throw Exception("No access token found");

      debugPrint('[getOrCreateConversation] Token found: ${token.substring(0, 20)}...');

      // --- 1. Try to find existing conversation ---
      debugPrint('[getOrCreateConversation] Fetching existing conversations...');
      final existingResponse = await http.get(
        Uri.parse('$baseUrl/conversations/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      debugPrint('[getOrCreateConversation] Existing conversations response: ${existingResponse.statusCode}');
      debugPrint('[getOrCreateConversation] Response body: ${existingResponse.body}');

      if (existingResponse.statusCode == 200) {
        final data = jsonDecode(existingResponse.body);
        final List conversations = data['conversations'] ?? [];
        debugPrint('[getOrCreateConversation] Found ${conversations.length} conversations');

        // Look for existing conversation with the partner
        dynamic existing;
        for (var conv in conversations) {
          final participants = conv['participants'] as List;
          final hasPartner = participants.any((p) => p['id'].toString() == partnerId);
          debugPrint('[getOrCreateConversation] Checking conversation ${conv['id']}: hasPartner=$hasPartner, participants=${participants.map((p) => p['id']).toList()}');

          if (hasPartner) {
            existing = conv;
            break;
          }
        }

        if (existing != null) {
          debugPrint("[getOrCreateConversation] Found existing conversation: ${existing['id']}");
          return existing['id'].toString();
        }
      }

      // --- 2. Create new conversation if not found ---
      debugPrint('[getOrCreateConversation] Creating new conversation...');
      final requestBody = {
        'participants': [partnerId],
        'partner_name': partnerName,
      };
      debugPrint('[getOrCreateConversation] Request body: ${jsonEncode(requestBody)}');

      // Try different endpoints for creating conversations
      Uri createUrl;
      try {
        // First try the conversations endpoint
        createUrl = Uri.parse('$baseUrl/conversations/');
        debugPrint('[getOrCreateConversation] Trying POST to: $createUrl');

        final createResponse = await http.post(
          createUrl,
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode(requestBody),
        );

        debugPrint('[getOrCreateConversation] Create response: ${createResponse.statusCode}');
        debugPrint('[getOrCreateConversation] Create response body: ${createResponse.body}');

        if (createResponse.statusCode == 201) {
          final data = jsonDecode(createResponse.body);
          debugPrint("[getOrCreateConversation] Created new conversation: ${data['id']}");
          return data['id'].toString();
        }

        // If POST fails, try PUT method
        if (createResponse.statusCode == 405) {
          debugPrint('[getOrCreateConversation] POST not allowed, trying PUT...');
          final putResponse = await http.put(
            createUrl,
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: jsonEncode(requestBody),
          );

          debugPrint('[getOrCreateConversation] PUT response: ${putResponse.statusCode}');
          debugPrint('[getOrCreateConversation] PUT response body: ${putResponse.body}');

          if (putResponse.statusCode == 201 || putResponse.statusCode == 200) {
            final data = jsonDecode(putResponse.body);
            debugPrint("[getOrCreateConversation] Created new conversation via PUT: ${data['id']}");
            return data['id'].toString();
          }
        }
      } catch (e) {
        debugPrint('[getOrCreateConversation] Error with POST/PUT: $e');
      }

      debugPrint("[getOrCreateConversation] Failed to create conversation via POST/PUT");
      return null;
    } catch (e) {
      debugPrint("[getOrCreateConversation] Error in getOrCreateConversation: $e");
      return null;
    }
  }

  static Future<List<Chat>> fetchChats() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');

    debugPrint('[fetchChats] Access token: $token');

    if (token == null) {
      debugPrint('[fetchChats] Access token is null, throwing exception.');
      throw Exception('Access token not found');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/conversations/'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    debugPrint('[fetchChats] Response status code: ${response.statusCode}');
    debugPrint('[fetchChats] Response body: ${response.body}');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> conversations = data['conversations'];

      debugPrint('[fetchChats] Number of conversations: ${conversations.length}');

      final chats = conversations.map<Chat>((json) {
        final chat = Chat.fromJson(json, currentUserId: '');

        debugPrint('[fetchChats] Parsed chat: ${chat.conversationId}, ${chat.conversationId}}');
        return chat;
      }).toList();

      return chats;
    } else {
      debugPrint('[fetchChats] Failed to load chats with status code: ${response.statusCode}');
      throw Exception('Failed to load chats. Status Code: ${response.statusCode}');
    }
  }


  // -------------------------------------------------------
  // ✅ Added Group Chat Related Methods
  // -------------------------------------------------------

  static Future<List<GroupChat>> fetchGroupChats() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');
    final currentUserId = prefs.getString('currentUserId');

    if (token == null) {
      throw Exception('Access token not found');
    }
    if (currentUserId == null) {
      throw Exception('Current user ID not found');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/conversations/'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> conversations = data['conversations'] ?? [];

      final groupChats = conversations
          .map<GroupChat>((json) => GroupChat.fromJson(json, currentUserId: currentUserId))
          .where((chat) => chat.isGroup)
          .toList();

      return groupChats;
    } else {
      throw Exception('Failed to load group chats. Status Code: ${response.statusCode}');
    }
  }

  // static Future<List<Message>> fetchMessages(String conversationId) async {
  //   final prefs = await SharedPreferences.getInstance();
  //   final token = prefs.getString('accessToken');
  //
  //   if (token == null) {
  //     throw Exception('Access token not found');
  //   }
  //
  //   final url = Uri.parse('$baseUrl/conversations/$conversationId/messages/');
  //   final response = await http.get(
  //     url,
  //     headers: {
  //       'Accept': 'application/json',
  //       'Authorization': 'Bearer $token',
  //     },
  //   );
  //
  //   if (response.statusCode == 200) {
  //     final data = jsonDecode(response.body);
  //     final List<dynamic> messages = data['messages'] ?? [];
  //     return messages.map<Message>((json) => Message.fromJson(json)).toList();
  //   } else {
  //     throw Exception('Failed to load group messages. Status Code: ${response.statusCode}');
  //   }
  // }



  Future<GroupMembersResponse> fetchGroupMembers(String conversationId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');

    if (token == null) {
      throw Exception('Access token not found');
    }

    final url = Uri.parse('$baseUrl/conversations/$conversationId/members/');
    final response = await http.get(
      url,
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return GroupMembersResponse.fromJson(data);
    } else {
      throw Exception('Failed to load group members. Status Code: ${response.statusCode}');
    }
  }

}