// lib/core/services/chat_api_service.dart
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models/message_model.dart';

class ChatApiService {
  final String _baseUrl = 'http://10.10.13.27:8000/api'; // Your REST API base URL

  Future<List<MessageModel>> fetchChatHistory(String conversationId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');

    if (token == null) {
      throw Exception('Authorization token not found');
    }

    final url = Uri.parse('$_baseUrl/chat/conversations/$conversationId/messages/');

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',  // unified to Bearer
      },
    );

    debugPrint('[ChatApiService] GET $url -> ${response.statusCode}');

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final List<dynamic> data = decoded['messages'] ?? decoded;
      return data.map((json) => MessageModel.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load chat history: ${response.statusCode} - ${response.body}');
    }
  }

  Future<void> sendMessage(String conversationId, String content, String receiverId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');

    if (token == null) {
      throw Exception('Authentication token not found');
    }

    final url = Uri.parse('$_baseUrl/chat/conversations/$conversationId/messages/');

    final body = {
      'content': content,
      'receiver_id': receiverId,
    };

    debugPrint('[ChatApiService] POST $url body: $body');

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    debugPrint('[ChatApiService] sendMessage -> ${response.statusCode} ${response.body}');

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception('Failed to send message: ${response.statusCode} - ${response.body}');
    }
  }
}
