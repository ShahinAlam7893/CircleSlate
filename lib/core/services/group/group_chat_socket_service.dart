import 'dart:async';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../../data/models/group_model.dart';

class GroupChatSocketService {
  WebSocketChannel? _channel;
  final String baseWsUrl = 'ws://72.60.26.57:8000/ws/chat/';
  final Function(Message) onMessageReceived;
  final Function(List<dynamic>)? onConversationMessages;

  final StreamController<bool> _connectionStatusController = StreamController<bool>.broadcast();
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
  });

  Future<void> connect(String conversationId, String token) async {
    try {
      final wsUrl = '$baseWsUrl$conversationId/?token=$token';
      debugPrint('[GroupChatSocketService] Connecting to WebSocket: $wsUrl');
      debugPrint('conversation ID: $conversationId');
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      _isConnected = true;
      _reconnectAttempts = 0;
      _connectionStatusController.add(true);
      _startHeartbeat();

      _channel!.stream.listen(
            (data) {
          try {
            final message = jsonDecode(data);
            debugPrint('[GroupChatSocketService] Received message: $message');

            // Handle heartbeat messages
            if (message['type'] == 'heartbeat') {
              _handleHeartbeat(message);
              return;
            }

            // Handle different message types
            if (message['type'] == 'message' && message['message'] != null) {
              // Handle message type with nested message object
              debugPrint('[GroupChatSocketService] Processing nested message');
              onMessageReceived(Message.fromJson(message['message']));
            } else if (message['type'] == 'new_message') {
              // Handle direct new_message type
              debugPrint('[GroupChatSocketService] Processing new_message');
              onMessageReceived(Message.fromJson(message));
            } else if (message['type'] == 'conversation_messages' && message['messages'] != null) {
              // Handle conversation_messages type - load multiple messages
              final messages = message['messages'] as List;
              debugPrint('[GroupChatSocketService] Loading ${messages.length} conversation messages');
              if (onConversationMessages != null) {
                onConversationMessages!(messages);
              } else {
                for (var msgData in messages) {
                  onMessageReceived(Message.fromJson(msgData));
                }
              }
            } else if (message['type'] == 'typing_indicator') {
              // Handle typing indicator
              debugPrint('[GroupChatSocketService] Typing indicator: ${message['is_typing']}');
            } else if (message['type'] == 'mark_as_read') {
              // Handle mark as read
              debugPrint('[GroupChatSocketService] Mark as read: ${message['message_ids']}');
            } else if (message['content'] != null && message['sender_id'] != null) {
              // Handle direct message format
              debugPrint('[GroupChatSocketService] Processing direct message format');
              onMessageReceived(Message.fromJson(message));
            } else {
              // Default handling for regular messages
              debugPrint('[GroupChatSocketService] Processing default message format');
              onMessageReceived(Message.fromJson(message));
            }
          } catch (e) {
            debugPrint('[GroupChatSocketService] Error parsing message: $e');
            debugPrint('[GroupChatSocketService] Raw message data: $data');
          }
        },
        onError: (error) {
          debugPrint('[GroupChatSocketService] WebSocket error: $error');
          _handleDisconnection();
        },
        onDone: () {
          debugPrint('[GroupChatSocketService] WebSocket connection closed');
          _handleDisconnection();
        },
      );
    } catch (e) {
      debugPrint('[GroupChatSocketService] Error connecting to WebSocket: $e');
      _handleDisconnection();
      rethrow;
    }
  }

  void sendMessage(String conversationId, String senderId, String content, {String? clientMessageId}) {
    if (_channel == null) {
      debugPrint('[GroupChatSocketService] WebSocket not connected');
      return;
    }
    final message = {
      'type': 'message',
      'conversation_id': conversationId,
      'sender_id': senderId,
      'content': content,
      'message_type': 'text',
      if (clientMessageId != null) 'client_message_id': clientMessageId,
    };

    sendRawMessage(jsonEncode(message));

    debugPrint('[GroupChatSocketService] Sending message: $message');
    debugPrint('conversation ID: $conversationId');

  }

  void sendRawMessage(String message) {
    if (_channel == null) {
      debugPrint('[GroupChatSocketService] WebSocket not connected');
      return;
    }
    debugPrint('[GroupChatSocketService] Sending raw message: $message');
    _channel!.sink.add(message);
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (isConnected) _sendHeartbeat();
    });
  }

  void _sendHeartbeat() {
    try {
      final heartbeat = {
        'type': 'heartbeat',
        'timestamp': DateTime.now().toIso8601String(),
      };
      _channel?.sink.add(jsonEncode(heartbeat));
    } catch (e) {
      debugPrint('[GroupChatSocketService] Error sending heartbeat: $e');
      _handleDisconnection();
    }
  }

  void _handleHeartbeat(Map<String, dynamic> data) {
    if (data['require_response'] == true) {
      final response = {
        'type': 'heartbeat_response',
        'timestamp': DateTime.now().toIso8601String(),
      };
      _channel?.sink.add(jsonEncode(response));
    }
  }

  void _handleDisconnection() {
    _isConnected = false;
    _connectionStatusController.add(false);
    _heartbeatTimer?.cancel();

    if (_reconnectAttempts < maxReconnectAttempts) {
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    _reconnectAttempts++;
    final delay = Duration(seconds: _reconnectAttempts * 2);
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, () {
      debugPrint('[GroupChatSocketService] Attempting to reconnect... (attempt $_reconnectAttempts)');
      // Note: You would need to store conversationId and token to reconnect
      // For now, we'll just log the attempt
    });
  }

  void disconnect() {
    _channel?.sink.close();
    _channel = null;
    _isConnected = false;
    _connectionStatusController.add(false);
    _heartbeatTimer?.cancel();
    _reconnectTimer?.cancel();

    debugPrint('[GroupChatSocketService] WebSocket disconnected');
  }

  void dispose() {
    _connectionStatusController.close();
    _heartbeatTimer?.cancel();
    _reconnectTimer?.cancel();
  }
}
