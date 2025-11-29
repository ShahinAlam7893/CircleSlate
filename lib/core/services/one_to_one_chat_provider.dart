// core/services/one_to_one_chat_provider.dart
// CRITICAL FIX: Only mark messages as read when chat page is actually visible

import 'dart:async';
import 'dart:convert';
import 'package:circleslate/core/network/endpoints.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../services/conversation_manager.dart';
import '../services/message_storage_service.dart';
import '../services/message_read_service.dart';
import '../utils/snackbar_utils.dart';
import '../utils/user_image_helper.dart';

class ConversationProvider extends ChangeNotifier {
  final String currentUserId;
  final String chatPartnerId;
  final String chatPartnerName;
  final String? initialConversationId;
  final String? initialChatPartnerImageUrl;
  final BuildContext context;

  late String conversationId;
  final List<StoredMessage> _messages = [];
  List<StoredMessage> get messages => List.unmodifiable(_messages);

  final Set<String> _messageIds = {};
  final TextEditingController messageController = TextEditingController();
  final ScrollController scrollController = ScrollController();

  bool _isLoading = true;
  bool get isLoading => _isLoading && _messages.isEmpty;

  bool _isConnected = false;
  bool get isConnected => _isConnected;

  bool _inputReady = false;
  bool get inputReady => _inputReady;

  bool _partnerTyping = false;
  bool get partnerTyping => _partnerTyping;

  String? _partnerImageUrl;
  String? get partnerImageUrl => _partnerImageUrl;

  Timer? _typingTimer;
  bool _initialHistoryLoaded = false;
  int _page = 1;
  static const int _pageSize = 50;

  late WebSocketChannel _channel;
  StreamSubscription? _socketSub;

  StoredMessage? _editingMessage;
  StoredMessage? get editingMessage => _editingMessage;
  bool get isEditing => _editingMessage != null;

  // ✅ CRITICAL FIX: Track if chat page is actually visible
  bool _isChatPageVisible = false;

  // ✅ ADD PUBLIC GETTER
  bool get isChatPageVisible => _isChatPageVisible;

  ConversationProvider({
    required this.context,
    required this.currentUserId,
    required this.chatPartnerId,
    required this.chatPartnerName,
    this.initialConversationId,
    this.initialChatPartnerImageUrl,
  }) {
    debugPrint(
      "ConversationProvider() → Created for $chatPartnerName ($chatPartnerId)",
    );
    _partnerImageUrl = initialChatPartnerImageUrl;
    if (_partnerImageUrl == null || _partnerImageUrl!.isEmpty) {
      _loadPartnerImage();
    }
    _init();
  }

  void setPageVisible(bool visible) {
    _isChatPageVisible = visible;
    debugPrint('[Provider] Chat page visibility changed: $visible');

    // If page just became visible AND messages are loaded, mark unread as read
    if (visible && _messages.isNotEmpty) {
      debugPrint(
        '[Provider] Page became visible, checking for unread messages...',
      );
      // Schedule marking after a brief delay to ensure everything is ready
      Future.delayed(const Duration(milliseconds: 300), () {
        if (_isChatPageVisible) {
          markAllUnreadAsRead();
        }
      });
    }
  }

  void startEditing(StoredMessage message) {
    if (message.sender != MessageSender.user) return;
    _editingMessage = message;
    messageController.text = message.text;
    messageController.selection = TextSelection.fromPosition(
      TextPosition(offset: message.text.length),
    );
    notifyListeners();
    _scrollToBottom();
  }

  void cancelEditing() {
    _editingMessage = null;
    messageController.clear();
    notifyListeners();
  }

  Future<void> _init() async {
    debugPrint("INIT → Starting chat initialization...");
    _isLoading = true;
    notifyListeners();

    conversationId = initialConversationId?.isNotEmpty ?? false
        ? initialConversationId!
        : await _createConversation();

    if (conversationId.isEmpty) {
      debugPrint("INIT → FAILED: Could not create/get conversation");
      SnackbarUtils.showError(context, 'Failed to start chat');
      _isLoading = false;
      notifyListeners();
      return;
    }

    debugPrint("INIT → Conversation ID: $conversationId");

    await _loadLocalMessages();
    await _connectWebSocket();

    messageController.addListener(_onTypingChanged);
    _inputReady = true;
    _isLoading = false;
    debugPrint("INIT → Chat ready! Input enabled.");
    notifyListeners();

    // DON'T mark as read here - wait for page to explicitly call setPageVisible(true)
  }

  Future<String> _createConversation() async {
    debugPrint("CONVERSATION → Creating or fetching...");
    final data = await ConversationManager.getOrCreateConversation(
      currentUserId,
      chatPartnerId,
      partnerName: chatPartnerName,
    );
    final id = data['conversation']?['id']?.toString() ?? '';
    debugPrint("CONVERSATION → Success! ID: $id");
    return id;
  }

  Future<void> _loadPartnerImage() async {
    debugPrint("IMAGE → Loading partner image...");
    var url =
        initialChatPartnerImageUrl ??
        await UserImageHelper.getUserImageUrl(chatPartnerId) ??
        'assets/images/default_user.png';

    if (!url.startsWith('http')) {
      url = 'https://app.circleslate.com$url';
    }
    _partnerImageUrl = url;
    debugPrint("IMAGE → Partner image loaded: $url");
    notifyListeners();
  }

  Future<void> _connectWebSocket() async {
    final token =
        (await SharedPreferences.getInstance()).getString('accessToken') ?? '';
    if (token.isEmpty) {
      debugPrint("WEBSOCKET → No token! Cannot connect.");
      return;
    }

    final url =
        'wss://app.circleslate.com/ws/chat/$conversationId/?token=$token';
    debugPrint("WEBSOCKET → Connecting to $url");

    try {
      _channel = WebSocketChannel.connect(Uri.parse(url));
      _socketSub?.cancel();
      _socketSub = _channel.stream.listen(
        _handleRawMessage,
        onError: (error) {
          debugPrint("WEBSOCKET → ERROR: $error");
          _setConnected(false);
        },
        onDone: () {
          debugPrint("WEBSOCKET → DISCONNECTED");
          _setConnected(false);
        },
      );
      _setConnected(true);
      debugPrint("WEBSOCKET → CONNECTED SUCCESSFULLY!");
      _requestHistory(page: 1);
    } catch (e) {
      debugPrint("WEBSOCKET → CONNECT FAILED: $e");
      _setConnected(false);
    }
  }

  void _setConnected(bool connected) {
    if (_isConnected != connected) {
      _isConnected = connected;
      debugPrint(
        "WEBSOCKET → Status: ${connected ? 'CONNECTED' : 'DISCONNECTED'}",
      );
      notifyListeners();
    }
  }

  void _handleRawMessage(dynamic raw) {
    try {
      final data = jsonDecode(raw as String) as Map<String, dynamic>;
      final type = data['type'] as String?;

      debugPrint("\n🔵 WEBSOCKET RECEIVED ═══════════════════════");
      debugPrint("Type: $type");
      debugPrint("Full data: $data");
      debugPrint("═══════════════════════════════════════════");

      switch (type) {
        case 'message':
        case null:
          _handleIncomingMessage(data['message'] ?? data);
          break;

        case 'conversation_messages':
          _handleHistory(data);
          break;

        case 'typing_indicator':
          final typing = data['typing'] == true;
          _partnerTyping = typing;
          debugPrint("TYPING → Partner typing: $typing");
          notifyListeners();
          break;

        case 'mark_as_read':
          final ids = (data['message_ids'] as List?)?.cast<String>() ?? [];
          debugPrint("READ → Messages marked as seen: $ids");
          _updateStatus(ids, MessageStatus.seen);
          break;

        case 'message_edited':
          debugPrint("🔶 EDIT EVENT RECEIVED ═══════════════════");
          final msgData = data['message'] as Map<String, dynamic>;
          debugPrint("Edit data: $msgData");
          _handleMessageEdited(msgData);
          debugPrint("═══════════════════════════════════════════");
          break;

        case 'message_deleted':
          debugPrint("🔴 DELETE EVENT RECEIVED ═══════════════════");
          final deletedId = data['message_id']?.toString();
          debugPrint("Message ID to delete: $deletedId");
          if (deletedId != null) {
            _removeMessage(deletedId);
            debugPrint("✅ Message $deletedId removed from UI");
          } else {
            debugPrint("❌ No message_id in delete event!");
          }
          debugPrint("═══════════════════════════════════════════");
          break;

        default:
          debugPrint("⚠️ UNKNOWN MESSAGE TYPE: $type");
      }
    } catch (e) {
      debugPrint("❌ SOCKET PARSE ERROR → $e | Raw: $raw");
    }
  }

  Future<void> _handleMessageEdited(Map<String, dynamic> json) async {
    debugPrint("_handleMessageEdited → Parsing edited message...");
    debugPrint("Received JSON: $json");

    final updatedMsg = await _parseServerMessage(json);

    if (updatedMsg != null) {
      debugPrint("_handleMessageEdited → Parsed successfully:");
      debugPrint("  ID: ${updatedMsg.id}");
      debugPrint("  Text: ${updatedMsg.text}");
      debugPrint("  isEdited: ${updatedMsg.isEdited}");
      debugPrint("  editedAt: ${updatedMsg.editedAt}");

      final oldMsg = _messages.firstWhere(
        (m) => m.id == updatedMsg.id,
        orElse: () => updatedMsg,
      );
      debugPrint("  Old text: ${oldMsg.text}");

      _replaceMessage(updatedMsg);
      debugPrint("✅ Message replaced in UI");
    } else {
      debugPrint("❌ Failed to parse edited message");
    }
  }

  void _requestHistory({required int page}) {
    if (!_isConnected) return;
    if (page == 1 && _initialHistoryLoaded) {
      debugPrint("HISTORY → Page 1 already loaded, skipping");
      return;
    }

    debugPrint("HISTORY → Requesting page $page");
    _channel.sink.add(
      jsonEncode({
        'type': 'get_conversation_messages',
        'conversation_id': conversationId,
        'page': page,
        'page_size': _pageSize,
      }),
    );
  }

  Future<void> _loadLocalMessages() async {
    debugPrint("LOCAL → Loading messages from storage...");
    final local = await MessageStorageService.loadMessages(conversationId);
    _messages.clear();
    _messageIds.clear();

    for (final msg in local) {
      if (msg.id.isNotEmpty && !_messageIds.contains(msg.id)) {
        _messages.add(msg);
        _messageIds.add(msg.id);
      }
    }
    debugPrint("LOCAL → Loaded ${_messages.length} messages from storage");
    _sortAndNotify();
  }

  void _handleHistory(Map<String, dynamic> data) async {
    // Only load history on first load AND if we have no local messages
    if (_initialHistoryLoaded || _messages.isNotEmpty) {
      debugPrint("HISTORY → Ignored (already have real-time messages)");
      if (_isChatPageVisible) {
        Future.delayed(const Duration(milliseconds: 300), markAllUnreadAsRead);
      }
      return;
    }

    final msgs = (data['messages'] as List?) ?? [];
    debugPrint("HISTORY → Loading initial ${msgs.length} messages");

    for (final m in msgs) {
      final msg = await _parseServerMessage(m as Map<String, dynamic>);
      if (msg != null && msg.id.isNotEmpty && !_messageIds.contains(msg.id)) {
        _messages.add(msg);
        _messageIds.add(msg.id);
      }
    }

    _initialHistoryLoaded = true;
    await MessageStorageService.saveMessages(conversationId, _messages);
    _sortAndNotify();

    if (_isChatPageVisible) {
      Future.delayed(const Duration(milliseconds: 300), markAllUnreadAsRead);
    }
  }

  Future<StoredMessage?> _parseServerMessage(Map<String, dynamic> json) async {
    final id = json['id']?.toString();
    final text = json['content']?.toString();
    if (id == null || text == null || text.isEmpty) return null;

    final senderId =
        json['sender']?['id']?.toString() ??
        json['sender_id']?.toString() ??
        '';
    final isMine = senderId == currentUserId;

    final status = json['is_read'] == true
        ? MessageStatus.seen
        : json['is_delivered'] == true
        ? MessageStatus.delivered
        : MessageStatus.sent;

    final timestamp =
        DateTime.tryParse(json['timestamp']?.toString() ?? '')?.toLocal() ??
        DateTime.now();
    final editedAt = json['edited_at'] != null
        ? DateTime.tryParse(json['edited_at'].toString())?.toLocal()
        : null;

    final msg = StoredMessage(
      id: id,
      text: text,
      timestamp: timestamp,
      senderId: senderId,
      sender: isMine ? MessageSender.user : MessageSender.other,
      senderImageUrl: isMine
          ? UserImageHelper.getCurrentUserImageUrl(context)
          : await _resolveImageUrl(
              json['sender']?['profile_photo_url']?.toString(),
              senderId,
            ),
      status: status,
      isEdited: json['is_edited'] == true,
      editedAt: editedAt,
    );

    return msg;
  }

  Future<String?> _resolveImageUrl(String? raw, String userId) async {
    if (raw?.isNotEmpty ?? false) {
      return raw!.startsWith('http') ? raw : 'https://app.circleslate.com$raw';
    }
    return await UserImageHelper.getUserImageUrl(userId);
  }

  // ✅ CRITICAL FIX: Only mark as read if page is visible
  void _handleIncomingMessage(Map<String, dynamic> json) async {
    final serverId = json['id']?.toString();
    if (serverId == null) return;

    final content = json['content']?.toString() ?? '';
    final senderId =
        json['sender']?['id']?.toString() ??
        json['sender_id']?.toString() ??
        '';

    // ✅ RESTORED: Original logic for handling my own messages
    if (senderId == currentUserId) {
      final pendingIndex = _messages.indexWhere(
        (m) =>
            m.sender == MessageSender.user &&
            m.text == content &&
            m.status.index <= MessageStatus.sent.index &&
            m.id != serverId,
      );

      if (pendingIndex != -1) {
        final confirmedMsg = await _parseServerMessage(json);
        if (confirmedMsg != null) {
          final oldId = _messages[pendingIndex].id;
          _messages[pendingIndex] = confirmedMsg;
          _messageIds.remove(oldId);
          _messageIds.add(serverId);
          await MessageStorageService.saveMessages(conversationId, _messages);
          _sortAndNotify();
          debugPrint(
            "[CONFIRM] Replaced temp message $oldId with server message $serverId",
          );
          return; // ✅ CRITICAL: Return here to prevent duplicate
        }
      }
    }

    // ✅ Prevent duplicates - check if message already exists
    if (_messageIds.contains(serverId)) {
      debugPrint("[DUPLICATE] Message $serverId already exists, skipping");
      return;
    }

    final msg = await _parseServerMessage(json);
    if (msg == null) return;

    _messages.add(msg);
    _messageIds.add(serverId);
    await MessageStorageService.addMessage(conversationId, msg);

    // ✅ Only mark as read if chat page is VISIBLE
    if (msg.sender == MessageSender.other && _isChatPageVisible) {
      debugPrint('[Provider] 📨 Chat VISIBLE → Marking as read: $serverId');
      await _markSingleMessageAsRead(serverId);
    } else if (msg.sender == MessageSender.other) {
      debugPrint('[Provider] ⏸️ Chat NOT visible → Keeping unread: $serverId');
    }

    _sortAndNotify();
  }

  void _updateStatus(List<String> ids, MessageStatus status) async {
    bool changed = false;
    for (final id in ids) {
      final i = _messages.indexWhere((m) => m.id == id);
      if (i != -1 && _messages[i].status != status) {
        _messages[i] = _messages[i].copyWith(status: status);
        changed = true;
      }
      await MessageStorageService.updateMessageStatus(
        conversationId,
        id,
        status,
      );
    }
    if (changed) _sortAndNotify();
  }

  Future<void> _markSingleMessageAsRead(String messageId) async {
    debugPrint("MARK_READ → Marking message as read: $messageId");

    final success = await MessageReadService.markMessageAsRead(messageId);

    if (success) {
      await MessageStorageService.updateMessageStatus(
        conversationId,
        messageId,
        MessageStatus.seen,
      );

      final index = _messages.indexWhere((m) => m.id == messageId);
      if (index != -1) {
        _messages[index] = _messages[index].copyWith(
          status: MessageStatus.seen,
        );
        notifyListeners();
      }

      if (_isConnected) {
        _channel.sink.add(
          jsonEncode({
            'type': 'mark_as_read',
            'message_ids': [messageId],
          }),
        );
      }
    }
  }

  /// Mark all unread messages as read (call when chat becomes visible)
  Future<void> markAllUnreadAsRead() async {
    if (!_isChatPageVisible) {
      debugPrint('[Provider] ⏸️ Page not visible, skipping mark as read');
      return;
    }

    final unread = _messages
        .where(
          (m) =>
              m.sender == MessageSender.other &&
              m.status.index < MessageStatus.seen.index,
        )
        .map((m) => m.id)
        .toList();

    if (unread.isEmpty) {
      debugPrint('[Provider] ✅ No unread messages to mark');
      return;
    }

    debugPrint("[Provider] 📖 Found ${unread.length} unread messages: $unread");
    debugPrint("[Provider] 🔄 Marking messages as read via API...");

    final successfulIds = await MessageReadService.markMultipleMessagesAsRead(
      unread,
    );

    debugPrint(
      "[Provider] ✅ Successfully marked ${successfulIds.length}/${unread.length} messages",
    );

    for (final id in successfulIds) {
      await MessageStorageService.updateMessageStatus(
        conversationId,
        id,
        MessageStatus.seen,
      );

      final index = _messages.indexWhere((m) => m.id == id);
      if (index != -1) {
        _messages[index] = _messages[index].copyWith(
          status: MessageStatus.seen,
        );
      }
    }

    if (_isConnected && successfulIds.isNotEmpty) {
      _channel.sink.add(
        jsonEncode({'type': 'mark_as_read', 'message_ids': successfulIds}),
      );
      debugPrint('[Provider] 📤 Sent read receipt via WebSocket');
    }

    notifyListeners();
  }

  Future<void> editMessage(String messageId, String newText) async {
    final token = (await SharedPreferences.getInstance()).getString(
      'accessToken',
    );
    if (token == null) {
      SnackbarUtils.showError(context, 'Not logged in');
      return;
    }

    debugPrint("═══════════════════════════════════════════");
    debugPrint("EDIT → Starting edit for message ID: $messageId");
    debugPrint("EDIT → New text: '$newText'");
    debugPrint("EDIT → Current messages count: ${_messages.length}");
    debugPrint("═══════════════════════════════════════════");

    try {
      final url = Uri.parse(
        'https://app.circleslate.com/api/chat/messages/$messageId/edit/',
      );
      final response = await http.put(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'content': newText}),
      );

      debugPrint("EDIT → HTTP Response: ${response.statusCode}");
      debugPrint("EDIT → Response body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final updatedMessage = data['message'];

        debugPrint("EDIT → Server returned updated message: $updatedMessage");

        // Parse and update locally
        final parsed = await _parseServerMessage(updatedMessage);
        if (parsed != null) {
          _replaceMessage(parsed);
          debugPrint("EDIT → ✅ Local UI updated successfully");
          debugPrint("EDIT → Updated message text: ${parsed.text}");
          debugPrint("EDIT → Updated message isEdited: ${parsed.isEdited}");
        }

        debugPrint(
          "EDIT → ⚠️ Server should now broadcast 'message_edited' to other users",
        );
        debugPrint(
          "EDIT → Other users should receive via WebSocket: type='message_edited'",
        );
      } else {
        final error = jsonDecode(response.body);
        debugPrint("EDIT → ❌ Failed: ${error['detail'] ?? 'Unknown error'}");
        SnackbarUtils.showError(context, error['detail'] ?? 'Failed to edit');
      }
    } catch (e) {
      debugPrint("EDIT → ❌ EXCEPTION: $e");
      SnackbarUtils.showError(context, 'Edit failed');
    }

    debugPrint("═══════════════════════════════════════════\n");
  }

  Future<void> deleteMessage(String messageId) async {
    final token = (await SharedPreferences.getInstance()).getString(
      'accessToken',
    );
    if (token == null) {
      SnackbarUtils.showError(context, 'Not logged in');
      return;
    }

    debugPrint("═══════════════════════════════════════════");
    debugPrint("DELETE → Starting delete for message ID: $messageId");
    debugPrint("DELETE → Current messages count: ${_messages.length}");
    debugPrint("═══════════════════════════════════════════");

    try {
      final url = Uri.parse(
        'https://app.circleslate.com/api/chat/messages/$messageId/delete/',
      );
      final response = await http.delete(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      debugPrint("DELETE → HTTP Response: ${response.statusCode}");
      debugPrint("DELETE → Response body: ${response.body}");

      if (response.statusCode == 200) {
        _removeMessage(messageId);
        debugPrint("DELETE → ✅ Local UI updated - message removed");
        debugPrint("DELETE → Remaining messages: ${_messages.length}");

        debugPrint(
          "DELETE → ⚠️ Server should now broadcast 'message_deleted' to other users",
        );
        debugPrint(
          "DELETE → Other users should receive via WebSocket: type='message_deleted', message_id='$messageId'",
        );
      } else {
        final error = jsonDecode(response.body);
        debugPrint("DELETE → ❌ Failed: ${error['detail'] ?? 'Unknown error'}");
        SnackbarUtils.showError(context, error['detail'] ?? 'Failed to delete');
      }
    } catch (e) {
      debugPrint("DELETE → ❌ EXCEPTION: $e");
      SnackbarUtils.showError(context, 'Delete failed');
    }

    debugPrint("═══════════════════════════════════════════\n");
  }

  void _replaceMessage(StoredMessage newMsg) async {
    debugPrint("_replaceMessage → Looking for message ID: ${newMsg.id}");

    final index = _messages.indexWhere((m) => m.id == newMsg.id);

    if (index != -1) {
      debugPrint("_replaceMessage → Found at index $index");
      debugPrint(
        "  Old: ${_messages[index].text} (edited: ${_messages[index].isEdited})",
      );
      debugPrint("  New: ${newMsg.text} (edited: ${newMsg.isEdited})");

      _messages[index] = newMsg;
      await MessageStorageService.saveMessages(conversationId, _messages);
      _sortAndNotify();

      debugPrint("✅ Message replaced and UI updated");
    } else {
      debugPrint("❌ Message not found in list!");
      debugPrint(
        "Available message IDs: ${_messages.map((m) => m.id).toList()}",
      );
    }
  }

  void _removeMessage(String messageId) async {
    debugPrint("_removeMessage → Removing message ID: $messageId");
    debugPrint("Before removal: ${_messages.length} messages");

    final beforeCount = _messages.length;
    _messages.removeWhere((m) => m.id == messageId);
    _messageIds.remove(messageId);
    final afterCount = _messages.length;

    debugPrint(
      "After removal: $afterCount messages (removed: ${beforeCount - afterCount})",
    );

    await MessageStorageService.saveMessages(conversationId, _messages);
    _sortAndNotify();

    debugPrint("✅ Message removed and storage updated");
  }

  void onSendPressed() {
    final text = messageController.text.trim();
    if (text.isEmpty || !inputReady) return;

    if (isEditing) {
      final msg = _editingMessage!;
      editMessage(msg.id, text);
      cancelEditing();
    } else {
      sendMessage(text);
      messageController.clear();
    }
  }

  Future<void> sendMessage(String text, {String? retryMessageId}) async {
    final tempId = retryMessageId ?? const Uuid().v4();
    final now = DateTime.now();

    debugPrint("[SEND] Creating temp message with ID: $tempId, text: '$text'");

    final tempMessage = StoredMessage(
      id: tempId,
      text: text,
      timestamp: now,
      senderId: currentUserId,
      sender: MessageSender.user,
      senderImageUrl: UserImageHelper.getCurrentUserImageUrl(context),
      status: MessageStatus.sending,
    );

    _messages.add(tempMessage);
    _messageIds.add(tempId);
    await MessageStorageService.addMessage(conversationId, tempMessage);
    _sortAndNotify();

    debugPrint(
      "[SEND] Temp message added. Total messages: ${_messages.length}",
    );
    debugPrint("[SEND] Message IDs in list: $_messageIds");

    try {
      _channel.sink.add(
        jsonEncode({
          'type': 'message',
          'content': text,
          'receiver_id': chatPartnerId,
        }),
      );
      debugPrint("[SEND] Message sent via WebSocket");
    } catch (e) {
      debugPrint("[SEND] Failed to send via WebSocket: $e");
      final i = _messages.indexWhere((m) => m.id == tempId);
      if (i != -1) {
        _messages[i] = _messages[i].copyWith(status: MessageStatus.failed);
        await MessageStorageService.updateMessageStatus(
          conversationId,
          tempId,
          MessageStatus.failed,
        );
        notifyListeners();
      }
    }
  }

  void _onTypingChanged() {
    final hasText = messageController.text.trim().isNotEmpty;
    final wasTyping = _typingTimer?.isActive == true;

    if (hasText && !wasTyping) _sendTyping(true);
    _typingTimer?.cancel();

    if (hasText) {
      _typingTimer = Timer(
        const Duration(seconds: 3),
        () => _sendTyping(false),
      );
    } else if (wasTyping) {
      _sendTyping(false);
    }
    notifyListeners();
  }

  void _sendTyping(bool typing) {
    if (_isConnected) {
      _channel.sink.add(
        jsonEncode({'type': 'typing_indicator', 'typing': typing}),
      );
    }
  }

  void _sortAndNotify() {
    _messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    _scrollToBottom();
    notifyListeners();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  static String formatMessageTime(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDay = DateTime(date.year, date.month, date.day);

    if (messageDay == today) return DateFormat('h:mm a').format(date);
    if (messageDay == yesterday)
      return 'Yesterday ${DateFormat('h:mm a').format(date)}';
    if (date.year == now.year) return DateFormat('MMM d, h:mm a').format(date);
    return DateFormat('MMM d, yyyy').format(date);
  }

  void resume() {
    debugPrint("LIFECYCLE → Resumed");
    _isChatPageVisible = true; // ✅ Mark as visible
    _connectWebSocket();
    markAllUnreadAsRead(); // ✅ Mark unread messages
  }

  void pause() {
    debugPrint("LIFECYCLE → Paused");
    _isChatPageVisible = false; // ✅ Mark as not visible
    _sendTyping(false);
  }

  @override
  void dispose() {
    _isChatPageVisible = false; // ✅ Mark as not visible
    messageController.removeListener(_onTypingChanged);
    messageController.dispose();
    scrollController.dispose();
    _typingTimer?.cancel();
    _socketSub?.cancel();
    try {
      _channel.sink.close();
    } catch (_) {}
    super.dispose();
  }

  void reconnect() async {
    await _socketSub?.cancel();
    try {
      _channel.sink.close();
    } catch (_) {}
    _page = 1;
    _initialHistoryLoaded = false;
    await _connectWebSocket();
  }
}
