import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

import '../../../data/models/group_model.dart';

class GroupConversationManager {
  static const String baseUrl = 'http://72.60.26.57/api/chat';

  static Future<GroupChat> createGroupConversation(
      String currentUserId,
      List<String> participantIds,
      String groupName,
      ) async {
    if (currentUserId.isEmpty) {
      throw Exception('Current user ID cannot be empty');
    }

    try {
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

      debugPrint('[GroupConversationManager] Creating group with payload: $payload');

      final response = await http.post(
        Uri.parse('$baseUrl/conversations/create-group/'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(payload),
      );

      debugPrint('[GroupConversationManager] Response status: ${response.statusCode}');
      debugPrint('[GroupConversationManager] Response body: ${response.body}');

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return GroupChat.fromJson(data, currentUserId: '');
      } else {
        throw Exception('Failed to create group: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('[GroupConversationManager] Error creating group: $e');
      rethrow;
    }
  }
}