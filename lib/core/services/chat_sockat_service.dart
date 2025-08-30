import 'dart:async';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../data/models/chat_model.dart';


class ChatSocketService {
  WebSocketChannel? _channel;
  String? _conversationId;
  String? _token;
  final Uuid _uuid = const Uuid();
  final Function(Message) onMessageReceived;
  final Function(List<dynamic>)? onConversationMessages;

  final _messagesController = StreamController<String>.broadcast();
  final _connectionStatusController = StreamController<bool>.broadcast();
  Stream<String> get messages => _messagesController.stream;
  Stream<bool> get connectionStatus => _connectionStatusController.stream;

  bool _isConnected = false;
  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  static const int maxReconnectAttempts = 5;

  ChatSocketService({
    required this.onMessageReceived,
    this.onConversationMessages,
  });

  Future<void> connect(String conversationId) async {
    if (conversationId.isEmpty) {
      throw Exception('conversationId is empty.');
    }
    _conversationId = conversationId;
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('accessToken');
    if (_token == null) {
      throw Exception('Token not found');
    }
    await _establishConnection();
  }

  Future<void> _establishConnection() async {
    try {
      final wsUrl = 'ws://72.60.26.57:8000/ws/chat/$_conversationId/?token=$_token';
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

      _channel!.stream.listen(
            (data) => _handleMessage(data),
        onDone: _handleDisconnection,
        onError: _handleConnectionError,
      );

      _isConnected = true;
      _reconnectAttempts = 0;
      _connectionStatusController.add(true);
      _startHeartbeat();
    } catch (e) {
      _handleConnectionError(e);
      rethrow;
    }
  }

  void _handleMessage(dynamic data) {
    try {
      final String text = data is String ? data : jsonEncode(data);
      final decoded = jsonDecode(text);

      if (decoded['type'] == 'heartbeat') {
        _handleHeartbeat(decoded);
        return;
      }

      if (decoded['type'] == 'message' && decoded['message'] != null) {
        onMessageReceived(Message.fromJson(decoded['message']));
      } else if (decoded['type'] == 'new_message') {
        onMessageReceived(Message.fromJson(decoded));
      } else if (decoded['type'] == 'conversation_messages' && decoded['messages'] != null) {
        final messages = decoded['messages'] as List;
        if (onConversationMessages != null) {
          onConversationMessages!(messages);
        } else {
          for (var msgData in messages) {
            onMessageReceived(Message.fromJson(msgData));
          }
        }
      } else if (decoded['type'] == 'typing_indicator') {
        // Handle typing
      } else {
        onMessageReceived(Message.fromJson(decoded));
      }
    } catch (e) {
      _messagesController.add(data is String ? data : data.toString());
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

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (isConnected) {
        final heartbeat = {
          'type': 'heartbeat',
          'timestamp': DateTime.now().toIso8601String(),
        };
        _channel?.sink.add(jsonEncode(heartbeat));
      }
    });
  }

  void sendMessage(String content, String receiverId, [String? clientMessageId, bool isGroup = false]) {
    if (!isConnected) return;
    final messagePayload = {
      'type': isGroup ? 'message' : 'new_message',
      'content': content,
      'receiver_id': receiverId,
      'conversation_id': _conversationId,
      'timestamp': DateTime.now().toIso8601String(),
      'client_message_id': clientMessageId ?? _uuid.v4(),
    };
    _channel?.sink.add(jsonEncode(messagePayload));
  }

  void sendTypingIndicator(String receiverId, bool isTyping, {required bool isGroup}) {
    if (!isConnected) return;
    final payload = {
      'type': 'typing_indicator',
      'receiver_id': receiverId,
      'is_typing': isTyping,
      'timestamp': DateTime.now().toIso8601String(),
      'is_group': isGroup,
    };
    _channel?.sink.add(jsonEncode(payload));
  }

  void markAsRead(List<String> messageIds) {
    if (!isConnected) return;
    final payload = {
      'type': 'mark_as_read',
      'message_ids': messageIds,
      'timestamp': DateTime.now().toIso8601String(),
    };
    _channel?.sink.add(jsonEncode(payload));
  }

  bool get isConnected => _isConnected && _channel != null && (_channel!.closeCode == null);

  void _handleDisconnection() {
    _isConnected = false;
    _connectionStatusController.add(false);
    _heartbeatTimer?.cancel();
    if (_reconnectAttempts < maxReconnectAttempts) {
      _reconnectAttempts++;
      final delay = Duration(seconds: _reconnectAttempts * 2);
      _reconnectTimer = Timer(delay, _establishConnection);
    }
  }

  void _handleConnectionError(dynamic error) {
    _isConnected = false;
    _connectionStatusController.add(false);
    _heartbeatTimer?.cancel();
    _handleDisconnection();
  }

  Future<void> reconnect() async {
    await dispose();
    _reconnectAttempts = 0;
    await _establishConnection();
  }

  Future<void> dispose() async {
    _heartbeatTimer?.cancel();
    _reconnectTimer?.cancel();
    await _messagesController.close();
    await _connectionStatusController.close();
    _channel?.sink.close();
    _channel = null;
    _isConnected = false;
  }
}