import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../data/models/group_model.dart';
import '../../data/models/chat_model.dart';
import 'package:circleslate/core/network/endpoints.dart';

class ChatService {
  static const String baseUrl = '${Urls.baseUrl}/api/chat';

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
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );


    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> conversations = data['conversations'];

      debugPrint(
        '[fetchChats] Number of conversations: ${conversations.length}',
      );

      final chats = conversations.map<Chat>((json) {
        final chat = Chat.fromJson(json, currentUserId: '');

        debugPrint(
          '[fetchChats] Parsed chat: ${chat.conversationId}, ${chat.conversationId}}',
        );
        return chat;
      }).toList();

      return chats;
    } else {
      debugPrint(
        '[fetchChats] Failed to load chats with status code: ${response.statusCode}',
      );
      throw Exception(
        'Failed to load chats. Status Code: ${response.statusCode}',
      );
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
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> conversations = data['conversations'] ?? [];

      final groupChats = conversations
          .map<GroupChat>(
            (json) => GroupChat.fromJson(json, currentUserId: currentUserId),
          )
          .where((chat) => chat.isGroup)
          .toList();

      return groupChats;
    } else {
      throw Exception(
        'Failed to load group chats. Status Code: ${response.statusCode}',
      );
    }
  }

  Future<GroupMembersResponse> fetchGroupMembers(String conversationId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');

    if (token == null) {
      throw Exception('Access token not found');
    }

    final url = Uri.parse('$baseUrl/conversations/$conversationId/members/');
    final response = await http.get(
      url,
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return GroupMembersResponse.fromJson(data);
    } else {
      throw Exception(
        'Failed to load group members. Status Code: ${response.statusCode}',
      );
    }
  }
}
