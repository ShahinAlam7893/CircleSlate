import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:circleslate/data/models/conversation_model.dart';
import 'package:circleslate/presentation/common_providers/auth_provider.dart';

class ConversationProvider extends ChangeNotifier {
  final AuthProvider _authProvider;
  WebSocketChannel? _channel;

  List<Conversation> _conversations = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Conversation> get conversations => _conversations;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  ConversationProvider(this._authProvider) {
    _authProvider.addListener(_onAuthProviderChange);
    // Defer initialization to avoid calling during build
    Future.microtask(() => _init());
  }

  Future<void> _init() async {
    // Fetch conversations on init
    await refreshConversations();
    // Connect to socket after fetching
    await connectWebSocket();
  }

  @override
  void dispose() {
    _authProvider.removeListener(_onAuthProviderChange);
    _channel?.sink.close();
    super.dispose();
  }

  void _onAuthProviderChange() {
    // Update conversations from AuthProvider's public conversations list
    _conversations = _authProvider.conversations.map((data) => Conversation.fromJson(data)).toList();
    _isLoading = _authProvider.isLoading;
    _errorMessage = _authProvider.errorMessage;
    notifyListeners();
  }

  Future<void> refreshConversations() async {
    await _authProvider.fetchConversations();
    _onAuthProviderChange(); // Update our local list from the provider
  }

  /// Connect WebSocket
  Future<void> connectWebSocket() async {
    // Since accessToken is private, call async method to get token
    final token = await _authProvider.loadTokensFromStorage();

    if (token == null) {
      _errorMessage = 'Missing token for WebSocket.';
      notifyListeners();
      return;
    }

    final id = _getid();

    if (id == null) {
      _errorMessage = 'Missing conversation ID for WebSocket.';
      notifyListeners();
      return;
    }

    final uri = Uri.parse(
      'ws://app.circleslate.com/ws/chat/conversations/?token=$token',
      // 'https://app.circleslate.com/chat/conversations/?token=$token',
    );

    _channel = WebSocketChannel.connect(uri);

    _channel!.stream.listen(
          (message) {
        try {
          final data = json.decode(message);

          if (data['type'] == 'conversation_updated') {
            final updated = Conversation.fromJson(data['conversation']);
            final index = _conversations.indexWhere((c) => c.id == updated.id);
            if (index != -1) {
              _conversations[index] = updated;
            } else {
              _conversations.insert(0, updated);
            }
            notifyListeners();
          }
        } catch (e) {
          print('WebSocket JSON parsing error: $e');
        }
      },
      onError: (error) {
        print('WebSocket error: $error');
        _errorMessage = 'WebSocket error';
        notifyListeners();
      },
      onDone: () {
        print('WebSocket connection closed.');
        // Optionally reconnect here
      },
    );
  }

  /// Disconnect WebSocket
  void disconnectWebSocket() {
    _channel?.sink.close();
    _channel = null;
  }

  /// Helper to get current conversation id if needed
  String? _getid() {
    if (_conversations.isNotEmpty) {
      final firstId = _conversations.first.id;
      if (firstId.isNotEmpty && firstId != 'string') {
        return firstId;
      }
    }
    return null;
  }

}