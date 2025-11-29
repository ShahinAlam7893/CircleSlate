import 'dart:async';

class TypingIndicatorService {
  static const Duration _typingTimeout = Duration(seconds: 3);
  
  // For one-to-one chats
  final Map<String, Timer?> _oneToOneTypingTimers = {};
  final Map<String, StreamController<bool>> _oneToOneTypingControllers = {};
  
  // For group chats
  final Map<String, Timer?> _groupTypingTimers = {};
  final Map<String, StreamController<Set<String>>> _groupTypingControllers = {};
  final Map<String, Set<String>> _groupTypingUsers = {};

  static final TypingIndicatorService _instance = TypingIndicatorService._internal();
  factory TypingIndicatorService() => _instance;
  TypingIndicatorService._internal();

  // One-to-one chat typing indicators
  Stream<bool> getOneToOneTypingStream(String conversationId) {
    if (!_oneToOneTypingControllers.containsKey(conversationId)) {
      _oneToOneTypingControllers[conversationId] = StreamController<bool>.broadcast();
    }
    return _oneToOneTypingControllers[conversationId]!.stream;
  }

  void startOneToOneTyping(String conversationId) {
    // Cancel existing timer
    _oneToOneTypingTimers[conversationId]?.cancel();
    
    // Emit typing started
    if (_oneToOneTypingControllers.containsKey(conversationId)) {
      _oneToOneTypingControllers[conversationId]!.add(true);
    }
    
    // Set timer to stop typing after timeout
    _oneToOneTypingTimers[conversationId] = Timer(_typingTimeout, () {
      stopOneToOneTyping(conversationId);
    });
  }

  void stopOneToOneTyping(String conversationId) {
    _oneToOneTypingTimers[conversationId]?.cancel();
    _oneToOneTypingTimers[conversationId] = null;
    
    if (_oneToOneTypingControllers.containsKey(conversationId)) {
      _oneToOneTypingControllers[conversationId]!.add(false);
    }
  }

  // Group chat typing indicators
  Stream<Set<String>> getGroupTypingStream(String groupId) {
    if (!_groupTypingControllers.containsKey(groupId)) {
      _groupTypingControllers[groupId] = StreamController<Set<String>>.broadcast();
      _groupTypingUsers[groupId] = <String>{};
    }
    return _groupTypingControllers[groupId]!.stream;
  }

  void startGroupTyping(String groupId, String userId, String userName) {
    // Cancel existing timer for this user
    final timerKey = '${groupId}_$userId';
    _groupTypingTimers[timerKey]?.cancel();
    
    // Add user to typing set
    if (!_groupTypingUsers.containsKey(groupId)) {
      _groupTypingUsers[groupId] = <String>{};
    }
    _groupTypingUsers[groupId]!.add(userName);
    
    // Emit updated typing users
    if (_groupTypingControllers.containsKey(groupId)) {
      _groupTypingControllers[groupId]!.add(Set.from(_groupTypingUsers[groupId]!));
    }
    
    // Set timer to stop typing after timeout
    _groupTypingTimers[timerKey] = Timer(_typingTimeout, () {
      stopGroupTyping(groupId, userId, userName);
    });
  }

  void stopGroupTyping(String groupId, String userId, String userName) {
    final timerKey = '${groupId}_$userId';
    _groupTypingTimers[timerKey]?.cancel();
    _groupTypingTimers[timerKey] = null;
    
    // Remove user from typing set
    if (_groupTypingUsers.containsKey(groupId)) {
      _groupTypingUsers[groupId]!.remove(userName);
      
      // Emit updated typing users
      if (_groupTypingControllers.containsKey(groupId)) {
        _groupTypingControllers[groupId]!.add(Set.from(_groupTypingUsers[groupId]!));
      }
    }
  }

  // Handle incoming typing indicators from WebSocket
  void handleOneToOneTypingIndicator(String conversationId, Map<String, dynamic> data) {
    final isTyping = data['is_typing'] as bool? ?? false;
    
    if (!_oneToOneTypingControllers.containsKey(conversationId)) {
      _oneToOneTypingControllers[conversationId] = StreamController<bool>.broadcast();
    }
    
    _oneToOneTypingControllers[conversationId]!.add(isTyping);
  }

  void handleGroupTypingIndicator(String groupId, Map<String, dynamic> data) {
    final userId = data['user_id'] as String?;
    final userName = data['user_name'] as String?;
    final isTyping = data['is_typing'] as bool? ?? false;
    
    if (userId == null || userName == null) return;
    
    if (isTyping) {
      startGroupTyping(groupId, userId, userName);
    } else {
      stopGroupTyping(groupId, userId, userName);
    }
  }

  // Send typing indicators via WebSocket
  Map<String, dynamic> createOneToOneTypingMessage(bool isTyping) {
    return {
      'type': 'typing_indicator',
      'is_typing': isTyping,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  Map<String, dynamic> createGroupTypingMessage(String userId, String userName, bool isTyping) {
    return {
      'type': 'typing_indicator',
      'user_id': userId,
      'user_name': userName,
      'is_typing': isTyping,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  // Cleanup
  void dispose() {
    for (final timer in _oneToOneTypingTimers.values) {
      timer?.cancel();
    }
    for (final timer in _groupTypingTimers.values) {
      timer?.cancel();
    }
    for (final controller in _oneToOneTypingControllers.values) {
      controller.close();
    }
    for (final controller in _groupTypingControllers.values) {
      controller.close();
    }
    
    _oneToOneTypingTimers.clear();
    _oneToOneTypingControllers.clear();
    _groupTypingTimers.clear();
    _groupTypingControllers.clear();
    _groupTypingUsers.clear();
  }

  void disposeConversation(String conversationId) {
    _oneToOneTypingTimers[conversationId]?.cancel();
    _oneToOneTypingTimers.remove(conversationId);
    _oneToOneTypingControllers[conversationId]?.close();
    _oneToOneTypingControllers.remove(conversationId);
  }

  void disposeGroup(String groupId) {
    // Remove all timers for this group
    final keysToRemove = _groupTypingTimers.keys
        .where((key) => key.startsWith('${groupId}_'))
        .toList();
    
    for (final key in keysToRemove) {
      _groupTypingTimers[key]?.cancel();
      _groupTypingTimers.remove(key);
    }
    
    _groupTypingControllers[groupId]?.close();
    _groupTypingControllers.remove(groupId);
    _groupTypingUsers.remove(groupId);
  }
}