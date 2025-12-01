// core/services/message_read_service.dart

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../network/endpoints.dart';
import 'message_storage_service.dart';

class MessageReadService {
  /// Mark a single message as read using the POST endpoint
  static Future<bool> markMessageAsRead(String messageId) async {
    if (messageId.isEmpty) {
      debugPrint('[MessageReadService] Empty messageId, skipping');
      return false;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('accessToken');

      if (token == null) {
        debugPrint('[MessageReadService] No access token found');
        return false;
      }

      // Use the correct endpoint format
      final url = Uri.parse(
        'https://app.circleslate.com/api/chat/messages/$messageId/read/',
      );
      debugPrint('[MessageReadService] → POST $url');

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('[MessageReadService] ✅ Message $messageId marked as read');
        return true;
      } else {
        debugPrint(
          '[MessageReadService] ❌ Failed ${response.statusCode}: ${response.body}',
        );
        return false;
      }
    } catch (e) {
      debugPrint('[MessageReadService] ❌ Exception: $e');
      return false;
    }
  }

  /// Mark multiple messages as read in parallel (very fast)
  static Future<List<String>> markMultipleMessagesAsRead(
    List<String> messageIds,
  ) async {
    if (messageIds.isEmpty) return [];

    debugPrint(
      '[MessageReadService] Marking ${messageIds.length} messages as read...',
    );

    final futures = messageIds.map(markMessageAsRead).toList();
    final results = await Future.wait(futures);

    final successful = <String>[];
    for (int i = 0; i < messageIds.length; i++) {
      if (results[i]) successful.add(messageIds[i]);
    }

    debugPrint(
      '[MessageReadService] ✅ Successfully marked ${successful.length}/${messageIds.length} messages',
    );
    return successful;
  }

  /// Mark entire conversation as read when user opens the chat
  /// This is the MAIN method to call
  static Future<void> markConversationAsRead(String conversationId) async {
    try {
      debugPrint(
        '[MessageReadService] 📖 Opening conversation: $conversationId',
      );

      // 1. Load messages from local storage
      final messages = await MessageStorageService.loadMessages(conversationId);

      if (messages.isEmpty) {
        debugPrint('[MessageReadService] No local messages found');
        return;
      }

      // 2. Find unread messages from OTHER person (not sent by me)
      final unreadMessageIds = messages
          .where(
            (msg) =>
                msg.sender == MessageSender.other && // Not sent by me
                msg.status != MessageStatus.seen && // Not already seen
                msg.id.isNotEmpty, // Has valid ID
          )
          .map((msg) => msg.id)
          .toList();

      if (unreadMessageIds.isEmpty) {
        debugPrint('[MessageReadService] ✅ No unread messages to mark');
        return;
      }

      debugPrint(
        '[MessageReadService] 📨 Found ${unreadMessageIds.length} unread messages: $unreadMessageIds',
      );

      // 3. Mark them all as read on server (parallel requests)
      final successfulIds = await markMultipleMessagesAsRead(unreadMessageIds);

      // 4. Update local storage for successful ones
      for (final msgId in successfulIds) {
        await MessageStorageService.updateMessageStatus(
          conversationId,
          msgId,
          MessageStatus.seen,
        );
      }

      debugPrint('[MessageReadService] ✅ Conversation fully marked as read');
    } catch (e) {
      debugPrint('[MessageReadService] ❌ Error: $e');
    }
  }
}
