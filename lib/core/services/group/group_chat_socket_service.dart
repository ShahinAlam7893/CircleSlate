// core/services/group/group_chat_socket_service.dart
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../../data/models/group_model.dart';
import '../../network/endpoints.dart';

class GroupChatSocketService {
  WebSocketChannel? _channel;
  final Function(Message) onMessageReceived;
  final Function(List<dynamic>)? onConversationMessages;

  // New callbacks for edit/delete
  final Function(String messageId, String newContent)? onMessageEdited;
  final Function(String messageId)? onMessageDeleted;

  final StreamController<bool> _connectionStatusController =
      StreamController<bool>.broadcast();
  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  static const int maxReconnectAttempts = 5;

  Stream<bool> get connectionStatusStream => _connectionStatusController.stream;
  bool _isConnected = false;
  bool get isConnected => _isConnected;

  GroupChatSocketService({
    required this.onMessageReceived,
    this.onConversationMessages,
    this.onMessageEdited,
    this.onMessageDeleted,
  });

  Future<void> connect(String conversationId, String token) async {
    try {
      final wsUrl = '${Urls.chatWebSocket}$conversationId/?token=$token';
      debugPrint('[GroupChatSocketService] Connecting to: $wsUrl');

      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      _isConnected = true;
      _reconnectAttempts = 0;
      _connectionStatusController.add(true);
      _startHeartbeat();

      _channel!.stream.listen(
        (data) {
          _handleIncomingData(data);
        },
        onError: (error) {
          debugPrint('[GroupChatSocketService] WebSocket error: $error');
          _handleDisconnection();
        },
        onDone: () {
          debugPrint('[GroupChatSocketService] WebSocket closed by server');
          _handleDisconnection();
        },
      );
    } catch (e) {
      debugPrint('[GroupChatSocketService] Connection failed: $e');
      _handleDisconnection();
      rethrow;
    }
  }

  void _handleIncomingData(dynamic data) {
    try {
      final message = jsonDecode(data) as Map<String, dynamic>;
      debugPrint('[GroupChatSocketService] ← Received: ${message['type']}');

      switch (message['type']) {
        case 'heartbeat':
          _handleHeartbeat(message);
          break;

        case 'message':
        case 'new_message':
          final msgData = message['message'] ?? message;
          onMessageReceived(Message.fromJson(msgData));
          break;

        case 'conversation_messages':
          final messages = message['messages'] as List<dynamic>;
          onConversationMessages?.call(messages);
          break;

        case 'message_edited':
        case 'edit_message':
          final msgId = message['message_id'] ?? message['id'];
          final newContent = message['content'] ?? message['new_content'];
          if (msgId != null && newContent != null) {
            onMessageEdited?.call(msgId.toString(), newContent.toString());
          }
          break;

        case 'message_deleted':
        case 'delete_message':
          final msgId = message['message_id'] ?? message['id'];
          if (msgId != null) {
            onMessageDeleted?.call(msgId.toString());
          }
          break;

        case 'typing_indicator':
          // Optional: handle typing from server
          break;

        default:
          // Fallback: try to parse as direct message
          if (message['content'] != null && message['sender_id'] != null) {
            onMessageReceived(Message.fromJson(message));
          }
          break;
      }
    } catch (e, s) {
      debugPrint('[GroupChatSocketService] Parse error: $e\n$s');
      debugPrint('[GroupChatSocketService] Raw data: $data');
    }
  }

  // Send normal message
  void sendMessage(
    String conversationId,
    String senderId,
    String content, {
    String? clientMessageId,
  }) {
    final payload = {
      'type': 'message',
      'conversation_id': conversationId,
      'sender_id': senderId,
      'content': content,
      'message_type': 'text',
      if (clientMessageId != null) 'client_message_id': clientMessageId,
    };
    sendRawMessage(jsonEncode(payload));
  }

  // Send edit message
  void sendEditMessage(String messageId, String newContent) {
    final payload = {
      'type': 'edit_message',
      'message_id': messageId,
      'content': newContent,
    };
    sendRawMessage(jsonEncode(payload));
    debugPrint('[GroupChatSocketService] → Edit message: $messageId');
  }

  // Send delete message
  void sendDeleteMessage(String messageId) {
    final payload = {'type': 'delete_message', 'message_id': messageId};
    sendRawMessage(jsonEncode(payload));
    debugPrint('[GroupChatSocketService] → Delete message: $messageId');
  }

  void sendRawMessage(String message) {
    if (_channel == null || !_isConnected) {
      debugPrint('[GroupChatSocketService] Cannot send: not connected');
      return;
    }
    debugPrint('[GroupChatSocketService] → $message');
    _channel!.sink.add(message);
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_isConnected) _sendHeartbeat();
    });
  }

  void _sendHeartbeat() {
    try {
      sendRawMessage(
        jsonEncode({
          'type': 'heartbeat',
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );
    } catch (e) {
      _handleDisconnection();
    }
  }

  void _handleHeartbeat(Map<String, dynamic> data) {
    if (data['require_response'] == true) {
      sendRawMessage(
        jsonEncode({
          'type': 'heartbeat_response',
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );
    }
  }

  void _handleDisconnection() {
    if (!_isConnected) return;
    _isConnected = false;
    _connectionStatusController.add(false);
    _heartbeatTimer?.cancel();

    if (_reconnectAttempts < maxReconnectAttempts) {
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    _reconnectAttempts++;
    final delay = Duration(
      seconds: pow(2, _reconnectAttempts).toInt().clamp(2, 30),
    );
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, () {
      debugPrint(
        '[GroupChatSocketService] Reconnecting... attempt $_reconnectAttempts',
      );
      // You’ll need to re-call connect() from the page
    });
  }

  void disconnect() {
    _channel?.sink.close();
    _channel = null;
    _isConnected = false;
    _connectionStatusController.add(false);
    _heartbeatTimer?.cancel();
    _reconnectTimer?.cancel();
  }

  void dispose() {
    disconnect();
    _connectionStatusController.close();
  }
}
