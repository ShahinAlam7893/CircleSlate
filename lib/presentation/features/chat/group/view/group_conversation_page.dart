// presentation/pages/group_conversation_page.dart

import 'dart:async';
import 'dart:convert';
import 'package:circleslate/core/network/endpoints.dart';
import 'package:circleslate/core/utils/snackbar_utils.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:circleslate/core/constants/app_colors.dart';
import 'package:circleslate/core/services/message_storage_service.dart';
import 'package:circleslate/core/services/message_read_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:circleslate/core/utils/user_image_helper.dart';
import '../../widgets/professional_message_bubble.dart';
import '../../../../../data/services/typing_indicator_service.dart';
import '../../../../../core/services/group/group_chat_socket_service.dart';
import '../../../../../data/models/group_model.dart'
    hide MessageStatus, StoredMessage, MessageSender;
import '../../../../routes/app_router.dart';
import 'package:http/http.dart' as http;

class GroupConversationPage extends StatefulWidget {
  final String groupId;
  final String currentUserId;
  final String groupName;
  final bool isCurrentUserAdminInGroup;

  const GroupConversationPage({
    super.key,
    required this.groupId,
    required this.currentUserId,
    required this.groupName,
    required this.isCurrentUserAdminInGroup,
  });

  @override
  State<GroupConversationPage> createState() => _GroupConversationPageState();
}

class _GroupConversationPageState extends State<GroupConversationPage>
    with WidgetsBindingObserver {
  final TextEditingController _messageController = TextEditingController();
  final List<StoredMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();
  final Uuid _uuid = const Uuid();

  late GroupChatSocketService _groupChatSocketService;

  bool _isLoading = true;
  bool _isConversationReady = false;
  Set<String> _typingUsers = <String>{};
  Timer? _typingTimer;
  final TypingIndicatorService _typingService = TypingIndicatorService();
  StreamSubscription<Set<String>>? _typingSubscription;

  final Map<String, String?> _userImages = {};

  String? _groupImageUrl;
  int _memberCount = 0;

  bool _hasMarkedAsRead = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _groupChatSocketService = GroupChatSocketService(
      onMessageReceived: _handleIncomingMessage,
      onConversationMessages: _handleConversationMessages,
    );

    _initializeConversation();
    _messageController.addListener(_handleTyping);
    _setupTypingIndicators();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      debugPrint('[GroupChat] Opening group → marking as read');
      if (!_hasMarkedAsRead) {
        _hasMarkedAsRead = true;
        MessageReadService.markConversationAsRead(widget.groupId);
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      debugPrint('[GroupConversationPage] App resumed');
      if (!_isConversationReady) {
        _connectWebSocket();
      }
      MessageReadService.markConversationAsRead(widget.groupId);
    }
  }

  void _setupTypingIndicators() {
    _typingSubscription = _typingService
        .getGroupTypingStream(widget.groupId)
        .listen((typingUsers) {
          if (mounted) {
            setState(() {
              _typingUsers = typingUsers;
            });
          }
        });
  }

  Future<void> _initializeConversation() async {
    setState(() => _isLoading = true);

    await _loadMessagesFromLocal();
    await _connectWebSocket();
    await _loadGroupInformation();

    setState(() {
      _isConversationReady = true;
      _isLoading = false;
    });
  }

  Future<void> _loadGroupInformation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('accessToken');
      if (token == null) return;

      final response = await http.get(
        Uri.parse(
          '${Urls.baseUrl}/api/chat/conversations/${widget.groupId}/',
        ),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _groupImageUrl = data['display_photo'];
          _memberCount = data['participant_count'] ?? 0;
        });
      }
    } catch (e) {
      debugPrint('[GroupConversationPage] Error loading group info: $e');
    }
  }

  Future<void> _loadMessagesFromLocal() async {
    try {
      final messages = await MessageStorageService.loadMessages(widget.groupId);
      setState(() {
        _messages.clear();
        _messages.addAll(messages);
      });
      _scrollToBottom();
    } catch (e) {
      debugPrint('Error loading local messages: $e');
    }
  }

  Future<void> _connectWebSocket() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');
    if (token == null) return;

    try {
      await _groupChatSocketService.connect(widget.groupId, token);
      _groupChatSocketService.connectionStatusStream.listen((connected) {
        if (mounted) setState(() => _isConversationReady = connected);
      });
      _requestConversationMessages();
    } catch (e) {
      debugPrint('[GroupConversationPage] WebSocket failed: $e');
      if (mounted) {
        SnackbarUtils.showError(context, 'Failed to connect to group chat');
      }
    }
  }

  void _requestConversationMessages() {
    _groupChatSocketService.sendRawMessage(
      jsonEncode({
        'type': 'get_conversation_messages',
        'conversation_id': widget.groupId,
      }),
    );
  }

  void _handleConversationMessages(List<dynamic> messagesData) async {
    final newMessages = <StoredMessage>[];
    for (var msgData in messagesData) {
      try {
        final message = Message.fromJson(msgData);
        final senderImage = await _getUserImageUrl(message.senderId);

        newMessages.add(
          StoredMessage(
            id: message.id,
            text: message.content,
            timestamp: DateTime.parse(message.timestamp).toLocal(),
            senderId: message.senderId,
            sender: message.senderId == widget.currentUserId
                ? MessageSender.user
                : MessageSender.other,
            senderImageUrl: senderImage,
            status: MessageStatus.seen,
            senderName: message.senderName,
          ),
        );
      } catch (e) {
        debugPrint('Error parsing message: $e');
      }
    }

    newMessages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    await MessageStorageService.saveMessages(widget.groupId, newMessages);

    if (mounted) {
      setState(() {
        _messages.clear();
        _messages.addAll(newMessages);
      });
      _scrollToBottom();
    }
  }

  void _handleIncomingMessage(Message message) async {
    if (message.senderId == widget.currentUserId) return;

    final exists = _messages.any(
      (m) =>
          m.id == message.id ||
          (m.clientMessageId != null && m.clientMessageId == message.id),
    );
    if (exists) return;

    final senderImage = await _getUserImageUrl(message.senderId);

    final storedMessage = StoredMessage(
      id: message.id,
      text: message.content,
      timestamp: DateTime.parse(message.timestamp).toLocal(),
      senderId: message.senderId,
      sender: MessageSender.other,
      senderImageUrl: senderImage,
      status: MessageStatus.seen,
      senderName: message.senderName,
    );

    await MessageStorageService.addMessage(widget.groupId, storedMessage);

    if (mounted) {
      setState(() {
        _messages.add(storedMessage);
        _messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      });
      _scrollToBottom();
      MessageReadService.markMessageAsRead(message.id);
    }
  }

  Future<String?> _getUserImageUrl(String userId) async {
    if (_userImages.containsKey(userId)) return _userImages[userId];
    final url = userId == widget.currentUserId
        ? UserImageHelper.getCurrentUserImageUrl(context)
        : await UserImageHelper.getUserImageUrl(userId);
    _userImages[userId] = url;
    return url;
  }

  void _handleTyping() {
    final typing = _messageController.text.isNotEmpty;
    if (typing == (_typingTimer != null)) return;

    _typingTimer?.cancel();
    if (typing) {
      _typingTimer = Timer(const Duration(seconds: 3), () {
        _sendTypingStatus(false);
      });
    }
    _sendTypingStatus(typing);
  }

  void _sendTypingStatus(bool isTyping) {
    _groupChatSocketService.sendRawMessage(
      jsonEncode({
        'type': 'typing',
        'conversation_id': widget.groupId,
        'user_id': widget.currentUserId,
        'is_typing': isTyping,
      }),
    );
  }

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || !_isConversationReady) return;

    final clientId = _uuid.v4();
    final tempMessage = StoredMessage(
      id: clientId,
      text: text,
      timestamp: DateTime.now(),
      sender: MessageSender.user,
      senderId: widget.currentUserId,
      senderImageUrl: UserImageHelper.getCurrentUserImageUrl(context),
      status: MessageStatus.sending,
      clientMessageId: clientId,
    );

    setState(() {
      _messages.add(tempMessage);
      _messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    });
    _scrollToBottom();
    _messageController.clear();

    await MessageStorageService.addMessage(widget.groupId, tempMessage);

    try {
      _groupChatSocketService.sendMessage(
        widget.groupId,
        widget.currentUserId,
        text,
        clientMessageId: clientId,
      );
    } catch (e) {
      await MessageStorageService.updateMessageStatus(
        widget.groupId,
        clientId,
        MessageStatus.failed,
        clientMessageId: clientId,
      );
      if (mounted) setState(() {});
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _groupChatSocketService.disconnect();
    _messageController.dispose();
    _scrollController.dispose();
    _typingTimer?.cancel();
    _typingSubscription?.cancel();
    _typingService.disposeGroup(widget.groupId);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 22, 9, 80),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 22, 9, 80),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            _groupImageUrl != null && _groupImageUrl!.isNotEmpty
                ? UserImageHelper.buildUserAvatarWithErrorHandling(
                    imageUrl: _groupImageUrl,
                    radius: 18,
                  )
                : const CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.group, color: Colors.grey),
                  ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.groupName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (_memberCount > 0)
                    Text(
                      '$_memberCount members',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  if (_typingUsers.isNotEmpty)
                    Text(
                      _typingUsers.length == 1
                          ? '${_typingUsers.first} is typing...'
                          : 'Several people are typing...',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.manage_accounts, color: Colors.white),
            onPressed: () => context.push(
              RoutePaths.groupManagement,
              extra: {
                'groupId': widget.groupId,
                'conversationId': widget.groupId,
                'currentUserId': widget.currentUserId,
                'isCurrentUserAdminInGroup': widget.isCurrentUserAdminInGroup,
              },
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                ? const Center(
                    child: Text(
                      'No messages yet. Start the conversation!',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount:
                        _messages.length + (_typingUsers.isNotEmpty ? 1 : 0),
                    itemBuilder: (context, i) {
                      if (i == _messages.length && _typingUsers.isNotEmpty) {
                        return Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            _typingUsers.length == 1
                                ? '${_typingUsers.first} is typing...'
                                : '${_typingUsers.take(3).join(', ')}${_typingUsers.length > 3 ? ' and others' : ''} are typing...',
                            style: const TextStyle(
                              fontStyle: FontStyle.italic,
                              color: Colors.grey,
                            ),
                          ),
                        );
                      }
                      final msg = _messages[i];
                      return ProfessionalMessageBubble(
                        message: msg,
                        currentUserId: widget.currentUserId,
                        showAvatar: true,
                        showTimestamp: true,
                        isGroupChat: true,
                        onRetry: msg.status == MessageStatus.failed
                            ? () => _sendMessage()
                            : null,
                      );
                    },
                  ),
          ),
          SafeArea(
            minimum: const EdgeInsets.only(bottom: 8),
            child: _buildMessageInput(),
          ),
        ],
      ),
    );
  }

  // REACTIVE INPUT — NO setState(() {}) NEEDED!
  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          UserImageHelper.buildCurrentUserAvatar(context: context, radius: 18),
          const SizedBox(width: 12),
          Expanded(
            child: ValueListenableBuilder<TextEditingValue>(
              valueListenable: _messageController,
              builder: (context, value, child) {
                final bool canSend =
                    _isConversationReady && value.text.trim().isNotEmpty;

                return TextField(
                  controller: _messageController,
                  enabled: _isConversationReady,
                  maxLines: null,
                  decoration: InputDecoration(
                    hintText: _isConversationReady
                        ? 'Type a message...'
                        : 'Connecting...',
                    filled: true,
                    fillColor: AppColors.chatInputFillColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  onSubmitted: (_) => canSend ? _sendMessage() : null,
                );
              },
            ),
          ),
          const SizedBox(width: 8),

          // Send Button — also reactive
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: _messageController,
            builder: (context, value, child) {
              final bool canSend =
                  _isConversationReady && value.text.trim().isNotEmpty;

              return Container(
                decoration: BoxDecoration(
                  color: canSend ? AppColors.primaryBlue : Colors.grey[300],
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.send,
                    color: canSend ? Colors.white : Colors.grey[600],
                  ),
                  onPressed: canSend ? _sendMessage : null,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
