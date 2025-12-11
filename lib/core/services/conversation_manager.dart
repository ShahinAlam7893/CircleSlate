import 'dart:convert';
import 'package:circleslate/core/network/endpoints.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ConversationManager {
  static Future<Map<String, dynamic>> getOrCreateConversation(
    String currentUserId,
    String partnerId, {
    required String partnerName,
  }) async {
    try {
      debugPrint(
        '[ConversationManager] getOrCreateConversation called with: currentUserId=$currentUserId, partnerId=$partnerId',
      );

      if (currentUserId.isEmpty || partnerId.isEmpty) {
        throw Exception(
          'Missing user id(s). currentUserId or partnerId is empty.',
        );
      }
      if (currentUserId == partnerId) {
        throw Exception(
          'Cannot create a one-to-one conversation with yourself.',
        );
      }

      final prefs = await SharedPreferences.getInstance();
      final conversationKey = _getConversationKey(currentUserId, partnerId);
      final cachedConversationId = prefs.getString(conversationKey);

      debugPrint(
        '[ConversationManager] Conversation cache key: $conversationKey',
      );
      debugPrint(
        '[ConversationManager] Cached conversation ID: $cachedConversationId',
      );

      if (cachedConversationId != null && cachedConversationId.isNotEmpty) {
        debugPrint(
          '[ConversationManager] Found cached conversation id: $cachedConversationId',
        );
        final existsOnServer = await _verifyConversationExists(
          cachedConversationId,
        );
        if (existsOnServer) {
          debugPrint(
            '[ConversationManager] Cached conversation verified on server',
          );
          return {
            'conversation': {'id': cachedConversationId},
            'created': false,
            'cached': true,
          };
        } else {
          debugPrint(
            '[ConversationManager] Cached conversation no longer exists on server. Removing cache.',
          );
          await prefs.remove(conversationKey);
        }
      } else {
        debugPrint(
          '[ConversationManager] No cached conversation found or empty.',
        );
      }

      final token = prefs.getString('accessToken');
      if (token == null) {
        throw Exception('No authentication token found in SharedPreferences');
      }

      final url = Uri.parse(
        '${Urls.createConversation}',
      );
      final payload = {
        'participant_ids': [int.parse(partnerId)],
      };

      debugPrint(
        '[ConversationManager] Sending create request to $url with payload: $payload',
      );
      final response = await http.post(
        url,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(payload),
      );

      debugPrint(
        '[ConversationManager] Create response: ${response.statusCode} ${response.body}',
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        debugPrint('[ConversationManager] Create response data: $data');

        if (data['conversation'] == null ||
            data['conversation']['id'] == null) {
          throw Exception('Response missing conversation id');
        }

        final conversationId = data['conversation']['id'].toString();
        debugPrint(
          '[ConversationManager] New conversation ID: $conversationId',
        );

        await prefs.setString(conversationKey, conversationId);
        await _storeConversationMetadata(conversationId, data['conversation']);

        debugPrint(
          '[ConversationManager] Conversation created and cached: $conversationId',
        );
        return data;
      }

      // 3. If 400, try to find existing conversation
      if (response.statusCode == 400) {
        debugPrint(
          '[ConversationManager] Received 400. Trying to find existing conversation.',
        );
        return await _findExistingConversation(
          token,
          prefs,
          conversationKey,
          currentUserId,
          partnerId,
        );
      }

      // 4. Otherwise throw error
      throw Exception(
        'Failed to create conversation: ${response.statusCode} - ${response.body}',
      );
    } catch (e) {
      debugPrint('[ConversationManager] Error: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> _findExistingConversation(
    String token,
    SharedPreferences prefs,
    String conversationKey,
    String currentUserId,
    String partnerId,
  ) async {
    try {
      final findUrl = Uri.parse(
        '${Urls.chatConversations}',
      );
      debugPrint(
        '[ConversationManager] Fetching user conversations from $findUrl',
      );
      final listResp = await http.get(
        findUrl,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint(
        '[ConversationManager] List response: ${listResp.statusCode} ${listResp.body}',
      );

      if (listResp.statusCode == 200) {
        final listData = jsonDecode(listResp.body);
        debugPrint('[ConversationManager] List data: $listData');

        final List<dynamic> conversations = listData is List
            ? listData
            : (listData['conversations'] ?? listData['results'] ?? []);

        for (final conv in conversations) {
          // Ensure it's a one-to-one conversation
          if (conv['is_group'] == false && conv['participant_count'] == 2) {
            final participants = conv['participants'] ?? [];
            final ids = participants
                .map((p) => p is Map ? p['id'].toString() : p.toString())
                .toList();

            // Check if partnerId is in participants (currentUserId is implicit)
            if (ids.contains(partnerId)) {
              final conversationId = conv['id'].toString();
              debugPrint(
                '[ConversationManager] Found existing conversation: $conversationId — caching and returning.',
              );
              await prefs.setString(conversationKey, conversationId);
              await _storeConversationMetadata(conversationId, conv);
              return {
                'conversation': {'id': conversationId},
                'created': false,
                'cached': false,
              };
            }
          }
        }
      }
      throw Exception(
        'No existing one-to-one conversation found for user $currentUserId and partner $partnerId.',
      );
    } catch (e) {
      debugPrint(
        '[ConversationManager] Error in fallback conversation search: $e',
      );
      rethrow;
    }
  }

  static String _getConversationKey(String userId1, String userId2) {
    final ids = [userId1, userId2]..sort();
    final key = 'conversation_${ids[0]}_${ids[1]}';
    debugPrint('[ConversationManager] Generated conversation cache key: $key');
    return key;
  }

  static Future<bool> _verifyConversationExists(String conversationId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('accessToken');
      if (token == null) {
        debugPrint(
          '[ConversationManager] No token found during conversation verification.',
        );
        return false;
      }

      final url = Uri.parse(
        '${Urls.chatConversations}$conversationId/',
      );
      final response = await http.get(
        url,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint(
        '[ConversationManager] verifyConversationExists($conversationId) -> ${response.statusCode}',
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('[ConversationManager] Error verifying conversation: $e');
      return false;
    }
  }

  static Future<void> _storeConversationMetadata(
    String conversationId,
    Map<String, dynamic> data,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'conversation_meta_$conversationId',
        jsonEncode(data),
      );
      debugPrint(
        '[ConversationManager] Stored conversation meta for $conversationId',
      );
    } catch (e) {
      debugPrint(
        '[ConversationManager] Error storing conversation metadata: $e',
      );
    }
  }
}
