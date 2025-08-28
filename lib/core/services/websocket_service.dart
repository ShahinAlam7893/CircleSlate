// // lib/core/services/websocket_service.dart
// import 'dart:async';
// import 'dart:convert';
// import 'package:web_socket_channel/web_socket_channel.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:uuid/uuid.dart';
// import 'package:flutter/foundation.dart';
//
// class ChatSocketService {
//   WebSocketChannel? _channel;
//   String? _conversationId;
//   String? _token;
//   final Uuid _uuid = const Uuid();
//
//   final _messagesController = StreamController<String>.broadcast();
//   final _connectionStatusController = StreamController<bool>.broadcast();
//
//   Stream<String> get messages => _messagesController.stream;
//   Stream<bool> get connectionStatus => _connectionStatusController.stream;
//
//   bool _isConnected = false;
//   Timer? _heartbeatTimer;
//   Timer? _reconnectTimer;
//   int _reconnectAttempts = 0;
//   static const int maxReconnectAttempts = 5;
//
//
//   Future<void> connect(String conversationId) async {
//     if (conversationId.isEmpty) {
//       throw Exception('conversationId is empty — cannot connect to WebSocket.');
//     }
//     _conversationId = conversationId;
//     await _establishConnection();
//   }
//
//   Future<void> _establishConnection() async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       _token = prefs.getString('accessToken');
//
//       if (_token == null) throw Exception('Authentication token not found');
//
//       final wsUrl =
//           'ws://10.10.13.27:8000/ws/chat/$_conversationId/?token=$_token';
//       debugPrint('[ChatSocketService] Connecting to WebSocket: $wsUrl');
//
//       _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
//
//       _channel!.stream.listen(
//             (data) => _handleMessage(data),
//         onDone: _handleDisconnection,
//         onError: _handleConnectionError,
//         cancelOnError: true,
//       );
//
//       _isConnected = true;
//       _reconnectAttempts = 0;
//       _connectionStatusController.add(true);
//       _startHeartbeat();
//       debugPrint('[ChatSocketService] WebSocket connected successfully');
//     } catch (e) {
//       debugPrint('[ChatSocketService] Failed to connect to WebSocket: $e');
//       _handleConnectionError(e);
//     }
//   }
//
//   void _handleMessage(dynamic data) {
//     try {
//       final String text = data is String ? data : jsonEncode(data);
//       final decoded = jsonDecode(text);
//
//       if (decoded['type'] == 'heartbeat') {
//         _handleHeartbeat(decoded);
//       } else {
//         _messagesController.add(text);
//       }
//     } catch (e) {
//       debugPrint('[ChatSocketService] Error parsing message, forwarding raw: $e');
//       _messagesController.add(data is String ? data : data.toString());
//     }
//   }
//
//   void _handleHeartbeat(Map<String, dynamic> data) {
//     if (data['require_response'] == true) _sendHeartbeatResponse();
//   }
//
//   void _sendHeartbeatResponse() {
//     if (isConnected) {
//       final response = {
//         'type': 'heartbeat_response',
//         'timestamp': DateTime.now().toIso8601String(),
//       };
//       _channel?.sink.add(jsonEncode(response));
//     }
//   }
//
//   void _startHeartbeat() {
//     _heartbeatTimer?.cancel();
//     _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (_) {
//       if (isConnected) _sendHeartbeat();
//     });
//   }
//
//   void _sendHeartbeat() {
//     try {
//       final heartbeat = {
//         'type': 'heartbeat',
//         'timestamp': DateTime.now().toIso8601String(),
//       };
//       _channel?.sink.add(jsonEncode(heartbeat));
//     } catch (e) {
//       _handleConnectionError(e);
//     }
//   }
//
//
//   void _handleDisconnection() {
//     _isConnected = false;
//     if (!_connectionStatusController.isClosed) {
//       _connectionStatusController.add(false); // Only add if not closed
//     }
//     _heartbeatTimer?.cancel();
//     if (_reconnectAttempts < maxReconnectAttempts) _scheduleReconnect();
//   }
//
//   void _handleConnectionError(dynamic error) {
//     _isConnected = false;
//     _connectionStatusController.add(false);
//     _heartbeatTimer?.cancel();
//     if (_reconnectAttempts < maxReconnectAttempts) _scheduleReconnect();
//     _messagesController.addError(error);
//   }
//
//   void _scheduleReconnect() {
//     _reconnectAttempts++;
//     final delay = Duration(seconds: _reconnectAttempts * 2);
//     _reconnectTimer?.cancel();
//     _reconnectTimer = Timer(delay, () async {
//       if (_conversationId != null) await _establishConnection();
//     });
//   }
//
//   /// Send a chat message
//   void sendMessage(String content, String receiverId, [String? clientMessageId]) {
//     if (!isConnected) {
//       debugPrint('[ChatSocketService] Cannot send message, socket not connected yet.');
//       return;
//     }
//     if (content.isEmpty || receiverId.isEmpty) {
//       debugPrint('[ChatSocketService] Cannot send empty message or to empty receiver.');
//       return;
//     }
//
//     final messagePayload = {
//       'type': 'new_message',
//       'content': content,
//       'receiver_id': receiverId, // keep as string (UUID)
//       'conversation_id': _conversationId,
//       'timestamp': DateTime.now().toIso8601String(),
//       'client_message_id': clientMessageId ?? _uuid.v4(),
//     };
//
//     try {
//       _channel?.sink.add(jsonEncode(messagePayload));
//       debugPrint('[ChatSocketService] Sent message: $messagePayload');
//     } catch (e) {
//       _handleConnectionError(e);
//     }
//   }
//
//   /// Send typing indicator
//   void sendTypingIndicator(String receiverId, bool isTyping, {required bool isGroup}) {
//     if (!isConnected || receiverId.isEmpty) return;
//
//     final payload = {
//       'type': 'typing_indicator',
//       'receiver_id': receiverId, // UUID string
//       'is_typing': isTyping,
//       'timestamp': DateTime.now().toIso8601String(),
//       'is_group': isGroup,
//     };
//
//     try {
//       _channel?.sink.add(jsonEncode(payload));
//       debugPrint('[ChatSocketService] Sent typing indicator: $payload');
//     } catch (_) {}
//   }
//
//   void markAsRead(List<String> messageIds) {
//     if (!isConnected || messageIds.isEmpty) return;
//
//     final payload = {
//       'type': 'mark_as_read',
//       'message_ids': messageIds,
//       'timestamp': DateTime.now().toIso8601String(),
//     };
//
//     try {
//       _channel?.sink.add(jsonEncode(payload));
//     } catch (_) {}
//   }
//
//   /// Send a raw message (for custom message types)
//   void sendRawMessage(String message) {
//     if (!isConnected) {
//       debugPrint('[ChatSocketService] Cannot send raw message, socket not connected yet.');
//       return;
//     }
//
//     try {
//       _channel?.sink.add(message);
//       debugPrint('[ChatSocketService] Sent raw message: $message');
//     } catch (e) {
//       _handleConnectionError(e);
//     }
//   }
//
//   bool get isConnected => _isConnected && _channel != null && (_channel!.closeCode == null);
//
//   Future<void> reconnect() async {
//     if (_conversationId != null) {
//       await dispose();
//       _reconnectAttempts = 0;
//       await _establishConnection();
//     }
//   }
//
//   Future<void> dispose() async {
//     _heartbeatTimer?.cancel();
//     _reconnectTimer?.cancel();
//     try {
//       _channel?.sink.close();
//     } catch (_) {}
//     _channel = null;
//     _isConnected = false;
//     // Close streams only if they are not already closed
//     if (!_messagesController.isClosed) {
//       await _messagesController.close();
//     }
//     if (!_connectionStatusController.isClosed) {
//       await _connectionStatusController.close();
//     }
//   }
// }




import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart';

class ChatSocketService {
  WebSocketChannel? _channel;
  String? _conversationId;
  String? _token;
  final Uuid _uuid = const Uuid();

  final _messagesController = StreamController<String>.broadcast();
  final _connectionStatusController = StreamController<bool>.broadcast();

  Stream<String> get messages => _messagesController.stream;
  Stream<bool> get connectionStatus => _connectionStatusController.stream;

  bool _isConnected = false;
  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  static const int maxReconnectAttempts = 5;

  Future<void> connect(String conversationId) async {
    if (conversationId.isEmpty) {
      debugPrint('[ChatSocketService] Error: conversationId is empty');
      throw Exception('conversationId is empty — cannot connect to WebSocket.');
    }
    _conversationId = conversationId;
    await _establishConnection();
  }

  Future<void> _establishConnection() async {
    if (_isConnected) {
      debugPrint('[ChatSocketService] Already connected, skipping');
      return;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString('accessToken');

      if (_token == null) {
        debugPrint('[ChatSocketService] Error: Authentication token not found');
        throw Exception('Authentication token not found');
      }

      final wsUrl = 'ws://10.10.13.27:8000/ws/chat/$_conversationId/?token=$_token';
      debugPrint('[ChatSocketService] Connecting to WebSocket: $wsUrl');

      // Close existing channel if any
      if (_channel != null) {
        try {
          await _channel!.sink.close();
        } catch (_) {}
        _channel = null;
      }

      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

      _channel!.stream.listen(
            (data) => _handleMessage(data),
        onDone: _handleDisconnection,
        onError: _handleConnectionError,
        cancelOnError: false, // Prevent stream cancellation on error
      );

      _isConnected = true;
      _reconnectAttempts = 0;
      if (!_connectionStatusController.isClosed) {
        _connectionStatusController.add(true);
      }
      _startHeartbeat();
      debugPrint('[ChatSocketService] WebSocket connected successfully');
    } catch (e) {
      _handleConnectionError(e);
    }
  }

  void _handleMessage(dynamic data) {
    try {
      final String text = data is String ? data : jsonEncode(data);
      final decoded = jsonDecode(text);

      if (decoded['type'] == 'heartbeat') {
        _handleHeartbeat(decoded);
      } else {
        if (!_messagesController.isClosed) {
          _messagesController.add(text);
        } else {
          debugPrint('[ChatSocketService] Messages controller closed, cannot forward: $text');
        }
      }
    } catch (e) {
      debugPrint('[ChatSocketService] Error parsing message: $e');
      if (!_messagesController.isClosed) {
        _messagesController.add(data is String ? data : data.toString());
      }
    }
  }

  void _handleHeartbeat(Map<String, dynamic> data) {
    if (data['require_response'] == true) _sendHeartbeatResponse();
  }

  void _sendHeartbeatResponse() {
    if (isConnected) {
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
      _handleConnectionError(e);
    }
  }

  void _handleDisconnection() {
    debugPrint('[ChatSocketService] WebSocket disconnected, closeCode: ${_channel?.closeCode}');
    _isConnected = false;
    if (!_connectionStatusController.isClosed) {
      _connectionStatusController.add(false);
    } else {
      debugPrint('[ChatSocketService] Connection status controller closed');
    }
    _heartbeatTimer?.cancel();
    if (_reconnectAttempts < maxReconnectAttempts) _scheduleReconnect();
  }

  void _handleConnectionError(dynamic error) {
    debugPrint('[ChatSocketService] WebSocket error: $error');
    _isConnected = false;
    if (!_connectionStatusController.isClosed) {
      _connectionStatusController.add(false);
    } else {
      debugPrint('[ChatSocketService] Connection status controller closed');
    }
    _heartbeatTimer?.cancel();
    if (_reconnectAttempts < maxReconnectAttempts) _scheduleReconnect();
    // Avoid adding error to messagesController to prevent stream closure
  }

  void _scheduleReconnect() {
    _reconnectAttempts++;
    final delay = Duration(seconds: _reconnectAttempts * 2);
    debugPrint('[ChatSocketService] Scheduling reconnect attempt $_reconnectAttempts after ${delay.inSeconds}s');
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, () async {
      if (_conversationId != null) await _establishConnection();
    });
  }

  void sendMessage(String content, String receiverId, [String? clientMessageId]) {
    if (!isConnected) {
      debugPrint('[ChatSocketService] Cannot send message, socket not connected');
      return;
    }
    if (content.isEmpty || receiverId.isEmpty) {
      debugPrint('[ChatSocketService] Cannot send empty message or to empty receiver');
      return;
    }

    final messagePayload = {
      'type': 'new_message',
      'content': content,
      'receiver_id': receiverId,
      'conversation_id': _conversationId,
      'timestamp': DateTime.now().toIso8601String(),
      'client_message_id': clientMessageId ?? _uuid.v4(),
    };

    try {
      _channel?.sink.add(jsonEncode(messagePayload));
      debugPrint('[ChatSocketService] Sent message: $messagePayload');
    } catch (e) {
      debugPrint('[ChatSocketService] Error sending message: $e');
      _handleConnectionError(e);
    }
  }

  void sendTypingIndicator(String receiverId, bool isTyping, {required bool isGroup}) {
    if (!isConnected || receiverId.isEmpty) {
      debugPrint('[ChatSocketService] Cannot send typing indicator, socket not connected or invalid receiver');
      return;
    }

    final payload = {
      'type': 'typing_indicator',
      'receiver_id': receiverId,
      'is_typing': isTyping,
      'timestamp': DateTime.now().toIso8601String(),
      'is_group': isGroup,
    };

    try {
      _channel?.sink.add(jsonEncode(payload));
      debugPrint('[ChatSocketService] Sent typing indicator: $payload');
    } catch (e) {
      debugPrint('[ChatSocketService] Error sending typing indicator: $e');
    }
  }

  void markAsRead(List<String> messageIds) {
    if (!isConnected || messageIds.isEmpty) {
      debugPrint('[ChatSocketService] Cannot mark messages as read, socket not connected or empty message IDs');
      return;
    }

    final payload = {
      'type': 'mark_as_read',
      'message_ids': messageIds,
      'timestamp': DateTime.now().toIso8601String(),
    };

    try {
      _channel?.sink.add(jsonEncode(payload));
      debugPrint('[ChatSocketService] Sent mark_as_read: $payload');
    } catch (e) {
      debugPrint('[ChatSocketService] Error sending mark_as_read: $e');
    }
  }

  void sendRawMessage(String message) {
    if (!isConnected) {
      debugPrint('[ChatSocketService] Cannot send raw message, socket not connected');
      return;
    }

    try {
      _channel?.sink.add(message);
      debugPrint('[ChatSocketService] Sent raw message: $message');
    } catch (e) {
      debugPrint('[ChatSocketService] Error sending raw message: $e');
      _handleConnectionError(e);
    }
  }

  bool get isConnected => _isConnected && _channel != null && (_channel!.closeCode == null);

  Future<void> reconnect() async {
    if (_conversationId != null) {
      await dispose();
      _reconnectAttempts = 0;
      await _establishConnection();
    }
  }

  Future<void> dispose() async {
    debugPrint('[ChatSocketService] Disposing WebSocket service');
    _heartbeatTimer?.cancel();
    _reconnectTimer?.cancel();
    try {
      await _channel?.sink.close();
    } catch (_) {}
    _channel = null;
    _isConnected = false;
    if (!_messagesController.isClosed) {
      await _messagesController.close();
    }
    if (!_connectionStatusController.isClosed) {
      await _connectionStatusController.close();
    }
  }
}