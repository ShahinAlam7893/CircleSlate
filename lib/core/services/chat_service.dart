import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models/chat_model.dart';


class ChatService {
  static const String baseUrl = 'http://72.60.26.57/api/chat';

  static Future<Map<String, dynamic>> getOrCreateConversation(
      String currentUserId, String partnerId, {required String partnerName}) async {
    try {
      if (currentUserId.isEmpty || partnerId.isEmpty) {
        throw Exception('Missing user id(s).');
      }
      if (currentUserId == partnerId) {
        throw Exception('Cannot create conversation with yourself.');
      }

      final prefs = await SharedPreferences.getInstance();
      final conversationKey = _getConversationKey(currentUserId, partnerId);
      final cachedConversationId = prefs.getString(conversationKey);
      final token = prefs.getString('accessToken');

      if (token == null) {
        throw Exception('No authentication token found');
      }

      if (cachedConversationId != null && cachedConversationId.isNotEmpty) {
        final exists = await _verifyConversationExists(cachedConversationId, token);
        if (exists) {
          return {
            'conversation': {'id': cachedConversationId},
            'created': false,
            'cached': true,
          };
        }
        await prefs.remove(conversationKey);
      }

      final url = Uri.parse('$baseUrl/conversations/create/');
      final payload = {
        'participant_ids': [int.parse(partnerId)],
        'is_group': false,
      };

      final response = await http.post(
        url,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final conversationId = data['conversation']['id'].toString();
        await prefs.setString(conversationKey, conversationId);
        return data;
      }

      if (response.statusCode == 400) {
        return await _findExistingConversation(token, prefs, conversationKey, currentUserId, partnerId);
      }

      throw Exception('Failed to create conversation: ${response.statusCode}');
    } catch (e) {
      debugPrint('[ChatService] Error: $e');
      rethrow;
    }
  }

  static Future<GroupChat> createGroupConversation(
      String currentUserId, List<String> participantIds, String groupName) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');
    if (token == null) {
      throw Exception('No access token found');
    }

    final allParticipantIds = [currentUserId, ...participantIds];
    final payload = {
      'name': groupName.isNotEmpty ? groupName : null,
      'participant_ids': allParticipantIds,
    };

    final response = await http.post(
      Uri.parse('$baseUrl/conversations/create-group/'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(payload),
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return GroupChat.fromJson(data, currentUserId: currentUserId);
    }
    throw Exception('Failed to create group: ${response.statusCode}');
  }

  static Future<List<Chat>> fetchChats() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');
    final currentUserId = prefs.getString('currentUserId');

    if (token == null || currentUserId == null) {
      throw Exception('Access token or user ID not found');
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
      return conversations.map((json) => Chat.fromJson(json, currentUserId: currentUserId)).toList();
    }
    throw Exception('Failed to load chats: ${response.statusCode}');
  }

  static Future<List<GroupChat>> fetchGroupChats() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');
    final currentUserId = prefs.getString('currentUserId');

    if (token == null || currentUserId == null) {
      throw Exception('Access token or user ID not found');
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
      return conversations
          .map((json) => GroupChat.fromJson(json, currentUserId: currentUserId))
          .where((chat) => chat.isGroup)
          .toList();
    }
    throw Exception('Failed to load group chats: ${response.statusCode}');
  }

  static Future<List<Message>> fetchMessages(String conversationId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');

    if (token == null) {
      throw Exception('Access token not found');
    }

    final url = Uri.parse('$baseUrl/conversations/$conversationId/messages/');
    final response = await http.get(
      url,
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> messages = data['messages'] ?? [];
      return messages.map((json) => Message.fromJson(json)).toList();
    }
    throw Exception('Failed to load messages: ${response.statusCode}');
  }

  static Future<void> sendMessage(String conversationId, String content, String receiverId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');

    if (token == null) {
      throw Exception('Authentication token not found');
    }

    final url = Uri.parse('$baseUrl/conversations/$conversationId/messages/');
    final body = {
      'content': content,
      'receiver_id': receiverId,
    };

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception('Failed to send message: ${response.statusCode}');
    }
  }

  static Future<GroupMembersResponse> fetchGroupMembers(String conversationId) async {
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
    }
    throw Exception('Failed to load group members: ${response.statusCode}');
  }

  static String _getConversationKey(String userId1, String userId2) {
    final ids = [userId1, userId2]..sort();
    return 'conversation_${ids[0]}_${ids[1]}';
  }

  static Future<bool> _verifyConversationExists(String conversationId, String token) async {
    try {
      final url = Uri.parse('$baseUrl/conversations/$conversationId/');
      final response = await http.get(url, headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      });
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<Map<String, dynamic>> fetchUserProfile(String userId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/users/$userId'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'profilePhotoUrl': data['profile_photo_url'] ?? '',
          'fullName': data['full_name'] ?? 'Unknown',
          'email': data['email'] ?? '',
          'isOnline': data['is_online'] ?? false,
        };
      } else {
        throw Exception('Failed to fetch user profile: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching user profile: $e');
    }
  }

  static Future<Map<String, dynamic>> _findExistingConversation(
      String token, SharedPreferences prefs, String conversationKey, String currentUserId, String partnerId) async {
    final findUrl = Uri.parse('$baseUrl/conversations/');
    final listResp = await http.get(findUrl, headers: {
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    });

    if (listResp.statusCode == 200) {
      final listData = jsonDecode(listResp.body);
      final List<dynamic> conversations = listData['conversations'] ?? [];

      for (final conv in conversations) {
        if (conv['is_group'] == false && conv['participant_count'] == 2) {
          final participants = conv['participants'] ?? [];
          final ids = participants.map((p) => p is Map ? p['id'].toString() : p.toString()).toList();
          if (ids.contains(partnerId)) {
            final conversationId = conv['id'].toString();
            await prefs.setString(conversationKey, conversationId);
            return {
              'conversation': {'id': conversationId},
              'created': false,
              'cached': false,
            };
          }
        }
      }
    }
    throw Exception('No existing conversation found.');
  }
}