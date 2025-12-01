// lib/core/services/message_storage_service.dart
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum MessageStatus { sending, sent, delivered, seen, failed }

enum MessageSender { user, other }

class StoredMessage {
  final String id;
  final String text;
  final DateTime timestamp;
  final String senderId;
  final String? senderName;
  final MessageSender sender;
  final String? senderImageUrl;
  final MessageStatus status;
  final String? clientMessageId;
  final bool isEdited;
  final DateTime? editedAt;

  StoredMessage({
    required this.id,
    required this.text,
    required this.timestamp,
    required this.senderId,
    this.senderName,
    required this.sender,
    this.senderImageUrl,
    required this.status,
    this.clientMessageId,
    this.isEdited = false,
    this.editedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'timestamp': timestamp.toIso8601String(),
      'sender': sender.name,
      'senderId': senderId,
      'senderName': senderName,
      'senderImageUrl': senderImageUrl,
      'status': status.name,
      'clientMessageId': clientMessageId,
      'isEdited': isEdited,
      'editedAt': editedAt?.toIso8601String(),
    };
  }

  factory StoredMessage.fromJson(Map<String, dynamic> json) {
    return StoredMessage(
      id: json['id'] ?? '',
      text: json['text'] ?? '',
      timestamp: DateTime.parse(json['timestamp']),
      sender: MessageSender.values.firstWhere(
        (e) => e.name == json['sender'],
        orElse: () => MessageSender.other,
      ),
      senderId: json['senderId'] ?? '',
      senderName: json['senderName'] ?? '',
      senderImageUrl: json['senderImageUrl'],
      status: MessageStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => MessageStatus.sent,
      ),
      clientMessageId: json['clientMessageId'],
      isEdited: json['isEdited'] as bool? ?? false,
      editedAt: json['editedAt'] != null
          ? DateTime.parse(json['editedAt']).toLocal()
          : null,
    );
  }

  StoredMessage copyWith({
    String? id,
    String? text,
    DateTime? timestamp,
    String? senderId,
    String? senderName,
    MessageSender? sender,
    String? senderImageUrl,
    MessageStatus? status,
    String? clientMessageId,
    bool? isEdited,
    DateTime? editedAt,
  }) {
    return StoredMessage(
      id: id ?? this.id,
      text: text ?? this.text,
      timestamp: timestamp ?? this.timestamp,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      sender: sender ?? this.sender,
      senderImageUrl: senderImageUrl ?? this.senderImageUrl,
      status: status ?? this.status,
      clientMessageId: clientMessageId ?? this.clientMessageId,
      isEdited: isEdited ?? this.isEdited,
      editedAt: editedAt ?? this.editedAt,
    );
  }
}

class MessageStorageService {
  static Future<void> saveMessages(
    String conversationId,
    List<StoredMessage> messages,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      final messagesToSave = messages;

      final messageJsonList = messagesToSave
          .map((msg) => jsonEncode(msg.toJson()))
          .toList();
      await prefs.setStringList('messages_$conversationId', messageJsonList);

      if (messages.isNotEmpty) {
        await prefs.setString(
          'last_message_time_$conversationId',
          messages.last.timestamp.toIso8601String(),
        );
      }

      debugPrint(
        '[MessageStorageService] Saved ${messageJsonList.length} messages for $conversationId',
      );
    } catch (e) {
      debugPrint('[MessageStorageService] Error saving messages: $e');
    }
  }

  static Future<List<StoredMessage>> loadMessages(String conversationId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final messageJsonList =
          prefs.getStringList('messages_$conversationId') ?? [];

      final messages = messageJsonList
          .map((jsonStr) {
            try {
              final data = jsonDecode(jsonStr);
              return StoredMessage.fromJson(data);
            } catch (e) {
              debugPrint(
                '[MessageStorageService] Error parsing stored message: $e',
              );
              return null;
            }
          })
          .whereType<StoredMessage>()
          .toList();

      messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));

      debugPrint(
        '[MessageStorageService] Loaded ${messages.length} messages for $conversationId',
      );
      return messages;
    } catch (e) {
      debugPrint('[MessageStorageService] Error loading messages: $e');
      return [];
    }
  }

  static Set<String> _processedMessageIds = {};

  static Future<void> addMessage(
    String conversationId,
    StoredMessage message,
  ) async {
    try {
      final existingMessages = await loadMessages(conversationId);

      final isDuplicate = existingMessages.any(
        (existing) =>
            existing.id == message.id ||
            (existing.clientMessageId != null &&
                existing.clientMessageId == message.clientMessageId) ||
            (existing.senderId == message.senderId &&
                existing.text == message.text &&
                (message.timestamp.difference(existing.timestamp).abs() <
                    Duration(seconds: 5))),
      );

      if (!isDuplicate) {
        existingMessages.add(message);
        await saveMessages(conversationId, existingMessages);
        _processedMessageIds.add(message.id);
        debugPrint(
          '[MessageStorageService] Added message ${message.id} (clientId:${message.clientMessageId}) to $conversationId',
        );
      } else {
        debugPrint(
          '[MessageStorageService] Duplicate message skipped: ${message.id}',
        );
      }
    } catch (e) {
      debugPrint('[MessageStorageService] Error adding message: $e');
    }
  }

  Future<void> updateMessage(
    String conversationId,
    StoredMessage updatedMessage, {
    String? oldClientMessageId,
  }) async {
    try {
      final messages = await loadMessages(conversationId);
      final index = messages.indexWhere(
        (m) =>
            m.id == updatedMessage.id ||
            (oldClientMessageId != null &&
                m.clientMessageId == oldClientMessageId),
      );

      if (index != -1) {
        messages[index] = updatedMessage;
        await saveMessages(conversationId, messages);
        debugPrint(
          '[MessageStorageService] Updated message ${updatedMessage.id} in $conversationId',
        );
      } else {
        debugPrint(
          '[MessageStorageService] Message not found for update: ${updatedMessage.id}',
        );
      }
    } catch (e) {
      debugPrint('[MessageStorageService] Error updating message: $e');
    }
  }

  static Future<void> updateMessageStatus(
    String conversationId,
    String messageId,
    MessageStatus newStatus, {
    String? clientMessageId,
    String? oldClientMessageId,
  }) async {
    try {
      final messages = await loadMessages(conversationId);
      bool updated = false;

      for (int i = 0; i < messages.length; i++) {
        if (messages[i].id == messageId ||
            (clientMessageId != null &&
                messages[i].clientMessageId == clientMessageId)) {
          messages[i] = messages[i].copyWith(status: newStatus);
          updated = true;
          break;
        }
      }

      if (updated) {
        await saveMessages(conversationId, messages);
        debugPrint(
          '[MessageStorageService] Updated status for message $messageId (client:$clientMessageId) => $newStatus',
        );
      } else {
        debugPrint(
          '[MessageStorageService] No matching message found to update for $messageId (client:$clientMessageId)',
        );
      }
    } catch (e) {
      debugPrint('[MessageStorageService] Error updating message status: $e');
    }
  }

  static Future<void> replaceTemporaryMessage(
    String conversationId,
    String clientMessageId,
    StoredMessage serverMessage,
  ) async {
    try {
      final messages = await loadMessages(conversationId);
      bool replaced = false;

      for (int i = 0; i < messages.length; i++) {
        if (messages[i].clientMessageId == clientMessageId) {
          messages[i] = serverMessage;
          replaced = true;
          break;
        }
      }

      if (replaced) {
        await saveMessages(conversationId, messages);
        debugPrint(
          '[MessageStorageService] Replaced temporary message (client:$clientMessageId) with server message ${serverMessage.id}',
        );
      } else {
        await addMessage(conversationId, serverMessage);
        debugPrint(
          '[MessageStorageService] Temporary message not found; added server message ${serverMessage.id}',
        );
      }
    } catch (e) {
      debugPrint(
        '[MessageStorageService] Error replacing temporary message: $e',
      );
    }
  }

  static Future<List<StoredMessage>> getPendingMessages(
    String conversationId,
  ) async {
    try {
      final messages = await loadMessages(conversationId);
      return messages
          .where(
            (msg) =>
                msg.status == MessageStatus.sending ||
                msg.status == MessageStatus.failed,
          )
          .toList();
    } catch (e) {
      debugPrint('[MessageStorageService] Error getting pending messages: $e');
      return [];
    }
  }

  static Future<void> clearMessages(String conversationId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('messages_$conversationId');
      await prefs.remove('last_message_time_$conversationId');
      debugPrint(
        '[MessageStorageService] Cleared messages for $conversationId',
      );
    } catch (e) {
      debugPrint('[MessageStorageService] Error clearing messages: $e');
    }
  }

  static Future<DateTime?> getLastMessageTime(String conversationId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timeStr = prefs.getString('last_message_time_$conversationId');

      if (timeStr != null) {
        return DateTime.parse(timeStr);
      }
      return null;
    } catch (e) {
      debugPrint('[MessageStorageService] Error getting last message time: $e');
      return null;
    }
  }

  static Future<List<StoredMessage>> searchMessages(
    String conversationId,
    String query,
  ) async {
    try {
      final messages = await loadMessages(conversationId);
      final lowerQuery = query.toLowerCase();

      return messages
          .where((msg) => msg.text.toLowerCase().contains(lowerQuery))
          .toList();
    } catch (e) {
      debugPrint('[MessageStorageService] Error searching messages: $e');
      return [];
    }
  }

  static Future<int> getMessageCount(String conversationId) async {
    try {
      final messages = await loadMessages(conversationId);
      return messages.length;
    } catch (e) {
      debugPrint('[MessageStorageService] Error getting message count: $e');
      return 0;
    }
  }

  static Future<int> getStorageSize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs
          .getKeys()
          .where((key) => key.startsWith('messages_'))
          .toList();

      int totalSize = 0;
      for (final key in keys) {
        final messageList = prefs.getStringList(key) ?? [];
        totalSize += messageList.join().length;
      }

      return totalSize;
    } catch (e) {
      debugPrint('[MessageStorageService] Error getting storage size: $e');
      return 0;
    }
  }
}
