import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:circleslate/core/constants/app_assets.dart';
import 'package:circleslate/core/constants/app_colors.dart';
import 'package:circleslate/core/services/conversation_manager.dart';
import 'package:circleslate/core/services/websocket_service.dart';
import 'package:circleslate/core/services/message_storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;
import 'package:circleslate/core/utils/user_image_helper.dart';
import 'package:provider/provider.dart';
import 'package:circleslate/presentation/common_providers/auth_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

class OneToOneConversationPage extends StatefulWidget {
  final String chatPartnerName;
  final String currentUserId;
  final String chatPartnerId;
  final String? conversationId;
  final String? chatPartnerImageUrl;

  const OneToOneConversationPage({
    super.key,
    required this.chatPartnerName,
    required this.currentUserId,
    required this.chatPartnerId,
    this.conversationId,
    this.chatPartnerImageUrl,
    required bool isadmin,
    required,
  });

  @override
  State<OneToOneConversationPage> createState() =>
      _OneToOneConversationPageState();
}

class _OneToOneConversationPageState extends State<OneToOneConversationPage>
    with WidgetsBindingObserver {
  final TextEditingController _messageController = TextEditingController();
  final List<StoredMessage> _messages = [];
  final ChatSocketService _chatSocketService = ChatSocketService();
  final ScrollController _scrollController = ScrollController();
  final Uuid _uuid = const Uuid();

  String? _conversationId;
  bool _isLoading = true;
  bool _isConversationReady = false;
  bool _isTyping = false;
  bool _isPartnerTyping = false;
  bool _isLoadingMessages = false;
  DateTime? _lastMessageTime;
  String? _chatPartnerImageUrl;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _chatPartnerImageUrl = widget.chatPartnerImageUrl;
    setState(() {});
    debugPrint(
      '[OneToOneConversationPage] initState: currentUser=${widget.currentUserId} partner=${widget.chatPartnerId} conversationId=${widget.conversationId}',
    );
    debugPrint(
      '[OneToOneConversationPage] Chat partner image URL: $_chatPartnerImageUrl',
    );
    if (_chatPartnerImageUrl == null || _chatPartnerImageUrl!.isEmpty) {
      _loadChatPartnerImage();
    }
    _initializeConversation();
    _messageController.addListener(_handleTyping);
    _messageController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  Future<void> _loadChatPartnerImage() async {
    try {
      String? imageUrl = widget.chatPartnerImageUrl;

      if (imageUrl == null || imageUrl.isEmpty) {
        debugPrint(
          '[OneToOneConversationPage] No chat partner image URL provided, fetching from API',
        );
        imageUrl = await UserImageHelper.getUserImageUrl(widget.chatPartnerId);
      }
      if (imageUrl == null || imageUrl.isEmpty) {
        debugPrint(
          '[OneToOneConversationPage] No image URL available, using default',
        );
        imageUrl = 'assets/images/default_user.png';
      } else if (!imageUrl.startsWith('http')) {
        imageUrl = 'http://72.60.26.57$imageUrl';
      }
      setState(() {
        _chatPartnerImageUrl = imageUrl;
      });
      debugPrint(
        '[OneToOneConversationPage] Chat partner image loaded: $imageUrl',
      );
    } catch (e) {
      debugPrint(
        '[OneToOneConversationPage] Error loading chat partner image: $e',
      );
      setState(() {
        _chatPartnerImageUrl = 'assets/images/default_user.png';
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      debugPrint(
        '[OneToOneConversationPage] App resumed - reconnecting socket & marking read',
      );
      _chatSocketService.reconnect();
      _markMessagesAsRead();
    } else if (state == AppLifecycleState.paused) {
      debugPrint(
        '[OneToOneConversationPage] App paused - sending typing=false',
      );
      _chatSocketService.sendTypingIndicator(
        widget.chatPartnerId,
        false,
        isGroup: false,
      );
    }
  }

  Future<void> _initializeConversation() async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (widget.conversationId != null && widget.conversationId!.isNotEmpty) {
        _conversationId = widget.conversationId;
        debugPrint(
          '[OneToOneConversationPage] Using passed conversationId: $_conversationId',
        );
      } else {
        final conversationData =
            await ConversationManager.getOrCreateConversation(
              widget.currentUserId,
              widget.chatPartnerId,
              partnerName: widget.chatPartnerName,
            );
        debugPrint(
          '[OneToOneConversationPage] Conversation data: $conversationData',
        );
        _conversationId = conversationData['conversation']['id'].toString();
      }

      if (_conversationId == null || _conversationId!.isEmpty) {
        throw Exception('Conversation ID is empty after initialization');
      }

      setState(() {
        _isConversationReady = true;
      });

      await _loadMessagesFromLocal();
      await _connectWebSocket();
      await _sendPendingMessages();

      setState(() {
        _isLoading = false;
      });
      debugPrint(
        '[OneToOneConversationPage] Initialization complete for conversation $_conversationId',
      );
    } catch (e, st) {
      debugPrint(
        '[OneToOneConversationPage] Error initializing conversation: $e\n$st',
      );
      setState(() {
        _isLoading = false;
        _isConversationReady = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to initialize conversation: $e')),
      );
    }
  }

  Future<void> _loadMessagesFromLocal() async {
    if (_conversationId == null) return;
    try {
      debugPrint(
        '[OneToOneConversationPage] Loading messages from local for $_conversationId',
      );
      final messages = await MessageStorageService.loadMessages(
        _conversationId!,
      );
      setState(() {
        _messages.clear();
        _messages.addAll(messages);
        if (_messages.isNotEmpty) {
          _lastMessageTime = _messages.last.timestamp;
        }
      });
      _scrollToBottom();
    } catch (e) {
      debugPrint(
        '[OneToOneConversationPage] Error loading messages from local storage: $e',
      );
      await MessageStorageService.clearMessages(_conversationId!);
    }
  }

  Future<void> _sendPendingMessages() async {
    if (_conversationId == null) return;
    final pendingMessages = await MessageStorageService.getPendingMessages(
      _conversationId!,
    );
    debugPrint(
      '[OneToOneConversationPage] Found ${pendingMessages.length} pending messages to send',
    );
    for (var message in pendingMessages) {
      try {
        _chatSocketService.sendMessage(
          message.text,
          widget.chatPartnerId,
          message.clientMessageId,
        );
        await MessageStorageService.updateMessageStatus(
          _conversationId!,
          message.id,
          MessageStatus.sent,
          clientMessageId: message.clientMessageId,
        );
        debugPrint(
          '[OneToOneConversationPage] Pending message sent (client:${message.clientMessageId})',
        );
      } catch (e) {
        debugPrint(
          '[OneToOneConversationPage] Error sending pending message: $e',
        );
        await MessageStorageService.updateMessageStatus(
          _conversationId!,
          message.id,
          MessageStatus.failed,
          clientMessageId: message.clientMessageId,
        );
      }
    }
    await _loadMessagesFromLocal();
  }

  Future<void> _connectWebSocket() async {
    if (_conversationId == null) return;
    try {
      debugPrint(
        '[OneToOneConversationPage] Connecting WebSocket for conversation $_conversationId',
      );
      await _chatSocketService.connect(_conversationId!);

      _chatSocketService.connectionStatus.listen(
        (isConnected) {
          debugPrint(
            '[OneToOneConversationPage] WebSocket connection status: $isConnected',
          );
          setState(() {});
        },
        onError: (e) {
          debugPrint(
            '[OneToOneConversationPage] connectionStatus stream error: $e',
          );
        },
      );

      _chatSocketService.messages.listen(
        (data) {
          debugPrint(
            '[OneToOneConversationPage] Received socket message: $data',
          );
          try {
            final decoded = jsonDecode(data);
            debugPrint('[OneToOneConversationPage] Decoded message: $decoded');
            if (decoded['type'] == 'new_message') {
              debugPrint('[OneToOneConversationPage] Processing new_message');
              _addMessageFromServer(decoded['message'] ?? decoded);
            } else if (decoded['type'] == 'conversation_messages' &&
                decoded['messages'] != null) {
              final messages = decoded['messages'] as List;
              debugPrint(
                '[OneToOneConversationPage] Loading ${messages.length} conversation messages',
              );
              _loadConversationMessages(messages);
            } else if (decoded['type'] == 'typing_indicator') {
              setState(() {
                _isPartnerTyping = decoded['is_typing'] == true;
              });
            } else if (decoded['type'] == 'mark_as_read') {
              _updateMessageStatuses(
                List<String>.from(decoded['message_ids'] ?? []),
                MessageStatus.seen,
              );
            } else {
              debugPrint(
                '[OneToOneConversationPage] Unhandled socket message type: ${decoded['type']}',
              );
            }
          } catch (e) {
            debugPrint(
              '[OneToOneConversationPage] Error decoding socket message: $e',
            );
          }
        },
        onError: (err) {
          debugPrint('[OneToOneConversationPage] Messages stream error: $err');
        },
      );

      _markMessagesAsRead();
      _requestConversationMessages();
    } catch (e) {
      debugPrint('[OneToOneConversationPage] Error connecting WebSocket: $e');
    }
  }

  void _requestConversationMessages() {
    if (_conversationId == null) return;
    try {
      setState(() {
        _isLoadingMessages = true;
      });

      final request = {
        'type': 'get_conversation_messages',
        'conversation_id': _conversationId,
      };
      _chatSocketService.sendRawMessage(jsonEncode(request));
      debugPrint('[OneToOneConversationPage] Requested conversation messages');

      Timer(const Duration(seconds: 10), () {
        if (mounted && _isLoadingMessages) {
          setState(() {
            _isLoadingMessages = false;
          });
          debugPrint(
            '[OneToOneConversationPage] Conversation messages request timed out',
          );
        }
      });
    } catch (e) {
      debugPrint(
        '[OneToOneConversationPage] Error requesting conversation messages: $e',
      );
      setState(() {
        _isLoadingMessages = false;
      });
    }
  }

  void _loadConversationMessages(List<dynamic> messagesData) async {
    debugPrint(
      '[OneToOneConversationPage] Processing ${messagesData.length} conversation messages',
    );

    try {
      final List<StoredMessage> newMessages = [];

      for (var msgData in messagesData) {
        try {
          debugPrint('[OneToOneConversationPage] Processing message: $msgData');
          final String messageId = msgData['id']?.toString() ?? '';
          final String content = msgData['content']?.toString() ?? '';
          final String timestamp = msgData['timestamp']?.toString() ?? '';

          String senderId;
          if (msgData['sender'] is Map) {
            senderId = msgData['sender']['id']?.toString() ?? '';
          } else {
            senderId =
                msgData['sender_id']?.toString() ??
                msgData['sender']?.toString() ??
                '';
          }
          debugPrint('[OneToOneConversationPage] Parsed senderId: $senderId');

          if (senderId.isEmpty || senderId == 'currentUserId') {
            debugPrint(
              '[OneToOneConversationPage] Invalid senderId, skipping message: $msgData',
            );
            continue;
          }

          final bool isRead = msgData['is_read'] == true;
          final bool isDelivered = msgData['is_delivered'] == true;
          final String? clientMessageId = msgData['client_message_id']
              ?.toString();

          DateTime messageTime;
          try {
            messageTime = DateTime.parse(timestamp);
          } catch (e) {
            debugPrint(
              '[OneToOneConversationPage] Error parsing timestamp: $timestamp, using current time',
            );
            messageTime = DateTime.now();
          }

          String? senderImageUrl;
          if (senderId == widget.currentUserId) {
            senderImageUrl = UserImageHelper.getCurrentUserImageUrl(context);
          } else {
            if (msgData['sender'] is Map &&
                msgData['sender']['profile_photo_url'] != null) {
              String imageUrl = msgData['sender']['profile_photo_url']
                  .toString();
              if (imageUrl.isNotEmpty && !imageUrl.startsWith('http')) {
                imageUrl = 'http://72.60.26.57$imageUrl';
              }
              senderImageUrl = imageUrl;
            } else {
              senderImageUrl = await UserImageHelper.getUserImageUrl(senderId);
            }
          }

          final message = StoredMessage(
            id: messageId,
            text: content,
            timestamp: messageTime,
            sender: senderId == widget.currentUserId
                ? MessageSender.user
                : MessageSender.other,
            senderId: senderId,
            senderImageUrl: senderImageUrl,
            status: isRead
                ? MessageStatus.seen
                : isDelivered
                ? MessageStatus.delivered
                : MessageStatus.sent,
            clientMessageId: clientMessageId,
          );

          newMessages.add(message);
        } catch (e) {
          debugPrint('[OneToOneConversationPage] Error processing message: $e');
        }
      }

      newMessages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      await MessageStorageService.saveMessages(_conversationId!, newMessages);

      setState(() {
        _messages.clear();
        _messages.addAll(newMessages);
        if (_messages.isNotEmpty) {
          _lastMessageTime = _messages.last.timestamp;
        }
        _isLoadingMessages = false;
      });

      _scrollToBottom();
      debugPrint(
        '[OneToOneConversationPage] Loaded ${newMessages.length} conversation messages',
      );
    } catch (e) {
      debugPrint(
        '[OneToOneConversationPage] Error loading conversation messages: $e',
      );
    }
  }

  void _addMessageFromServer(Map<String, dynamic> msgData) async {
    debugPrint(
      '[OneToOneConversationPage] _addMessageFromServer payload: $msgData',
    );

    try {
      final String messageId =
          msgData['id']?.toString() ?? msgData['message_id']?.toString() ?? '';
      final String content =
          msgData['content']?.toString() ?? msgData['text']?.toString() ?? '';
      final String timestamp = msgData['timestamp']?.toString() ?? '';

      if (messageId.isEmpty || content.isEmpty) {
        debugPrint(
          '[OneToOneConversationPage] Invalid message data: missing id or content',
        );
        return;
      }

      String senderId;
      String? senderImageUrl;
      if (msgData['sender'] is Map) {
        senderId = msgData['sender']['id']?.toString() ?? '';
        senderImageUrl =
            msgData['sender']['profile_photo']?.toString() ??
            msgData['sender']['profile_photo_url']?.toString();
        if (senderImageUrl != null && !senderImageUrl!.startsWith('http')) {
          senderImageUrl = 'http://72.60.26.57$senderImageUrl';
        }
      } else {
        senderId =
            msgData['sender_id']?.toString() ??
            msgData['sender']?.toString() ??
            '';
      }
      debugPrint('[OneToOneConversationPage] Parsed senderId: $senderId');

      if (senderId.isEmpty || senderId == 'currentUserId') {
        debugPrint(
          '[OneToOneConversationPage] Invalid senderId, skipping message',
        );
        return;
      }

      if (senderId == widget.currentUserId) {
        debugPrint(
          '[OneToOneConversationPage] Skipping own message: $messageId',
        );
        return;
      }

      DateTime messageTime;
      try {
        messageTime = DateTime.parse(timestamp);
      } catch (e) {
        debugPrint(
          '[OneToOneConversationPage] Error parsing timestamp: $timestamp, using current time',
        );
        messageTime = DateTime.now();
      }

      final bool isRead = msgData['is_read'] == true;
      final bool isDelivered = msgData['is_delivered'] == true;
      final String? clientMessageId = msgData['client_message_id']?.toString();
      final status = isRead
          ? MessageStatus.seen
          : isDelivered
          ? MessageStatus.delivered
          : MessageStatus.sent;

      if (senderImageUrl == null || senderImageUrl.isEmpty) {
        senderImageUrl = await UserImageHelper.getUserImageUrl(senderId);
        debugPrint(
          '[OneToOneConversationPage] Fetched image for user $senderId: $senderImageUrl',
        );
      }

      final message = StoredMessage(
        id: messageId,
        text: content,
        timestamp: messageTime,
        sender: MessageSender.other,
        senderId: senderId,
        senderImageUrl: senderImageUrl,
        status: status,
        clientMessageId: clientMessageId,
      );

      final existingMessage = _messages.any(
        (m) =>
            m.id == messageId ||
            (m.clientMessageId != null && m.clientMessageId == clientMessageId),
      );
      if (existingMessage) {
        debugPrint(
          '[OneToOneConversationPage] Message already exists, skipping: $messageId (client: $clientMessageId)',
        );
        return;
      }

      await MessageStorageService.replaceTemporaryMessage(
        _conversationId!,
        clientMessageId ?? '',
        message,
      );

      if (mounted) {
        setState(() {
          _messages.removeWhere((m) => m.clientMessageId == clientMessageId);
          _messages.add(message);
          _messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
          _lastMessageTime = _messages.last.timestamp;
        });

        _scrollToBottom();
        _markMessagesAsRead();
        debugPrint(
          '[OneToOneConversationPage] Message added to UI: ${message.text} (id: $messageId)',
        );
      }
    } catch (e) {
      debugPrint(
        '[OneToOneConversationPage] Error processing message from server: $e',
      );
    }
  }

  void _updateMessageStatuses(
    List<String> messageIds,
    MessageStatus status,
  ) async {
    debugPrint(
      '[OneToOneConversationPage] Updating ${messageIds.length} message statuses => $status',
    );
    for (var messageId in messageIds) {
      await MessageStorageService.updateMessageStatus(
        _conversationId!,
        messageId,
        status,
      );
    }
    await _loadMessagesFromLocal();
  }

  void _markMessagesAsRead() async {
    if (_conversationId == null) return;
    final unreadMessages = _messages
        .where(
          (msg) =>
              msg.sender == MessageSender.other &&
              (msg.status == MessageStatus.sent ||
                  msg.status == MessageStatus.delivered),
        )
        .map((msg) => msg.id)
        .toList();
    if (unreadMessages.isNotEmpty) {
      debugPrint(
        '[OneToOneConversationPage] Marking ${unreadMessages.length} messages as read',
      );
      _chatSocketService.markAsRead(unreadMessages);
      _updateMessageStatuses(unreadMessages, MessageStatus.seen);
    }
  }

  void _handleTyping() {
    final isTypingNow = _messageController.text.isNotEmpty;
    if (isTypingNow != _isTyping) {
      _isTyping = isTypingNow;
      debugPrint('[OneToOneConversationPage] Typing changed: $_isTyping');
      _chatSocketService.sendTypingIndicator(
        widget.chatPartnerId,
        _isTyping,
        isGroup: false,
      );
    }
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _conversationId == null)
      return;

    final clientMessageId = _uuid.v4();
    final message = StoredMessage(
      id: clientMessageId,
      text: _messageController.text.trim(),
      timestamp: DateTime.now(),
      sender: MessageSender.user,
      senderId: widget.currentUserId,
      senderImageUrl: UserImageHelper.getCurrentUserImageUrl(context),
      status: MessageStatus.sending,
      clientMessageId: clientMessageId,
    );

    debugPrint(
      '[OneToOneConversationPage] Sending message locally (client:$clientMessageId): ${message.text}',
    );
    setState(() {
      _messages.add(message);
      _messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      _lastMessageTime = _messages.last.timestamp;
    });
    _scrollToBottom();
    _messageController.clear();

    await MessageStorageService.addMessage(_conversationId!, message);

    try {
      _chatSocketService.sendMessage(
        message.text,
        widget.chatPartnerId,
        clientMessageId,
      );

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('accessToken');
      if (token != null) {
        final url = Uri.parse(
          'http://72.60.26.57/api/chat/messages/$_conversationId/send/',
        );
        final response = await http.post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({
            'content': message.text,
            'receiver_id': widget.chatPartnerId,
            'client_message_id': clientMessageId,
          }),
        );
        debugPrint(
          '[OneToOneConversationPage] HTTP API response: ${response.statusCode}',
        );
      }

      await MessageStorageService.updateMessageStatus(
        _conversationId!,
        message.id,
        MessageStatus.sent,
        clientMessageId: clientMessageId,
      );
      debugPrint(
        '[OneToOneConversationPage] Message sent via socket (client:$clientMessageId)',
      );
    } catch (e) {
      debugPrint('[OneToOneConversationPage] Error sending message: $e');
      await MessageStorageService.updateMessageStatus(
        _conversationId!,
        message.id,
        MessageStatus.failed,
        clientMessageId: clientMessageId,
      );
    }
    await _loadMessagesFromLocal();
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
    _messageController.removeListener(_handleTyping);
    _chatSocketService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            UserImageHelper.buildUserAvatarWithErrorHandling(
              imageUrl: _chatPartnerImageUrl,
              radius: 18,
              backgroundColor: Colors.white,
              iconColor: Colors.grey[600],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.chatPartnerName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20.0,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (_isPartnerTyping)
                    const Text(
                      'Typing...',
                      style: TextStyle(color: Colors.white70, fontSize: 14.0),
                    ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16.0),
            child: _chatSocketService.isConnected
                ? const Icon(Icons.wifi, color: Colors.green, size: 20)
                : const Icon(Icons.wifi_off, color: Colors.red, size: 20),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _isLoadingMessages
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text(
                          'Loading conversation...',
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                      ],
                    ),
                  )
                : _messages.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No messages yet. Start the conversation!',
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16.0),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) => _buildMessageBubble(
                      _messages[index],
                      widget.currentUserId,
                    ),
                  ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(StoredMessage message, String currentUserId) {
    final bool isUser = message.senderId == widget.currentUserId;
    print(
      "isUser: $isUser, abcdefcg ${widget.chatPartnerId} senderId: ${message.senderId}",
    );
    print("fshkjsdgh ${widget.currentUserId}");

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Column(
          crossAxisAlignment: isUser
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (!isUser)
                  UserImageHelper.buildUserAvatarWithErrorHandling(
                    imageUrl: message.senderImageUrl,
                    radius: 16,
                    backgroundColor: Colors.grey[200],
                    iconColor: Colors.grey[600],
                  ),
                const SizedBox(width: 8.0),
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 10.0,
                    ),
                    decoration: BoxDecoration(
                      color: isUser
                          ? AppColors.receiverBubbleColor
                          : AppColors.senderBubbleColor,
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Text(
                      message.text,
                      style: const TextStyle(
                        fontSize: 14.0,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                ),
                if (isUser) const SizedBox(width: 8.0),
                if (isUser)
                  Row(
                    children: [
                      _buildMessageStatusIcon(message.status),
                      const SizedBox(width: 4.0),
                      UserImageHelper.buildUserAvatarWithErrorHandling(
                        imageUrl: message.senderImageUrl,
                        radius: 16,
                        backgroundColor: Colors.grey[200],
                        iconColor: Colors.grey[600],
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 4.0),
            Text(
              DateFormat('h:mm a').format(message.timestamp),
              style: const TextStyle(fontSize: 10.0, color: Color(0x991A1A1A)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageStatusIcon(MessageStatus status) {
    switch (status) {
      case MessageStatus.sending:
        return const Icon(Icons.access_time, size: 12, color: Colors.grey);
      case MessageStatus.sent:
        return const Icon(Icons.check, size: 12, color: Colors.grey);
      case MessageStatus.delivered:
        return const Icon(Icons.done_all, size: 12, color: Colors.grey);
      case MessageStatus.seen:
        return const Icon(Icons.done_all, size: 12, color: Colors.blue);
      case MessageStatus.failed:
        return const Icon(Icons.error_outline, size: 12, color: Colors.red);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildMessageInput() {
    final bool canSend =
        _isConversationReady && _messageController.text.trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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
          Expanded(
            child: TextField(
              controller: _messageController,
              enabled: _isConversationReady,
              maxLines: null,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: _isConversationReady
                    ? 'Type a message...'
                    : 'Connecting...',
                hintStyle: TextStyle(
                  color: _isConversationReady
                      ? Colors.grey[600]
                      : Colors.grey[400],
                ),
                filled: true,
                fillColor: AppColors.chatInputFillColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25.0),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 12.0,
                ),
              ),
              onSubmitted: (_) => canSend ? _sendMessage() : null,
            ),
          ),
          const SizedBox(width: 8.0),
          Container(
            decoration: BoxDecoration(
              color: canSend ? AppColors.primaryBlue : Colors.grey[300],
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: canSend ? _sendMessage : null,
              icon: Icon(
                Icons.send,
                color: canSend ? Colors.white : Colors.grey[600],
                size: 20,
              ),
              padding: const EdgeInsets.all(8.0),
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            ),
          ),
        ],
      ),
    );
  }
}
