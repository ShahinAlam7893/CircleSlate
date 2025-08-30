import 'dart:convert';
import 'package:circleslate/data/models/conversation_model.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:circleslate/core/constants/app_assets.dart';
import 'package:circleslate/core/constants/app_colors.dart';
import 'package:circleslate/core/services/message_storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:circleslate/core/utils/user_image_helper.dart';
import 'package:provider/provider.dart';
import 'package:circleslate/presentation/common_providers/auth_provider.dart';

import '../../../../../core/services/group/group_chat_socket_service.dart';
import '../../../../../data/models/group_model.dart';
import '../../../../routes/app_router.dart';
import 'package:http/http.dart' as http;

class GroupConversationPage extends StatefulWidget {
  final String groupId;       // This is the unique group ID
  final String currentUserId; // Current logged-in user ID
  final String groupName;     // This is the display name of the group

  const GroupConversationPage({
    super.key,
    required this.groupId,
    required this.currentUserId,
    required this.groupName,
  });

  @override
  State<GroupConversationPage> createState() => _GroupConversationPageState();
}

class _GroupConversationPageState extends State<GroupConversationPage> with WidgetsBindingObserver {
  final TextEditingController _messageController = TextEditingController();
  final List<StoredMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();
  final Uuid _uuid = const Uuid();

  late GroupChatSocketService _groupChatSocketService;

  bool _isLoading = true;
  bool _isConversationReady = false;
  bool _isTyping = false;
  bool _isSomeoneTyping = false;

  // Store user images for better performance
  final Map<String, String?> _userImages = {};

  // Group information
  String? _groupImageUrl;
  int _memberCount = 0;

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
    _messageController.addListener(() {
      // Trigger rebuild to update send button state
      if (mounted) setState(() {});
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      debugPrint('[GroupConversationPage] App resumed - reconnecting if needed');
      if (!_isConversationReady) {
        _connectWebSocket();
      }
    } else if (state == AppLifecycleState.paused) {
      debugPrint('[GroupConversationPage] App paused');
    }
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
        Uri.parse('http://72.60.26.57/api/chat/conversations/${widget.groupId}/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final groupData = jsonDecode(response.body);

        // ✅ Check if user is still in the group
        final isMember = groupData['is_member'] ?? true;

        if (!isMember) {
          // Redirect or block access
          if (mounted) {
            showDialog(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text("Access Denied"),
                content: const Text("You are no longer a member of this group."),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pop(context); // go back
                    },
                    child: const Text("OK"),
                  ),
                ],
              ),
            );
          }
          return;
        }

        setState(() {
          _groupImageUrl = groupData['display_photo'];
          _memberCount = groupData['participant_count'] ?? 0;
        });

        debugPrint('[GroupConversationPage] Group info loaded: $_memberCount members');
      } else if (response.statusCode == 403) {
        // Not a member -> block access
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('[GroupConversationPage] Error loading group information: $e');
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
      await MessageStorageService.clearMessages(widget.groupId);
    }
  }

  Future<void> _connectWebSocket() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');
    if (token == null) {
      debugPrint('[GroupConversationPage] No token found!');
      setState(() {
        _isConversationReady = false;
      });
      return;
    }

    try {
      debugPrint('[GroupConversationPage] Connecting to WebSocket...');
      await _groupChatSocketService.connect(widget.groupId, token);
      debugPrint('[GroupConversationPage] WebSocket connected successfully');

      // Monitor connection status
      _groupChatSocketService.connectionStatusStream.listen((isConnected) {
        debugPrint('[GroupConversationPage] WebSocket connection status: $isConnected');
        if (mounted) {
          setState(() {
            _isConversationReady = isConnected;
          });
        }
      });

      // Request conversation messages from server via WebSocket
      _requestConversationMessages();

    } catch (e) {
      debugPrint('[GroupConversationPage] WebSocket connection failed: $e');
      setState(() {
        _isConversationReady = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to connect to chat: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Request conversation messages from server
  void _requestConversationMessages() {
    try {
      final request = {
        'type': 'get_conversation_messages',
        'conversation_id': widget.groupId,
      };
      _groupChatSocketService.sendRawMessage(jsonEncode(request));
      debugPrint('[GroupConversationPage] Requested conversation messages');
    } catch (e) {
      debugPrint('[GroupConversationPage] Error requesting conversation messages: $e');
    }
  }

  /// Handle conversation messages from server
  void _handleConversationMessages(List<dynamic> messagesData) async {
    debugPrint('[GroupConversationPage] Processing ${messagesData.length} conversation messages');

    try {
      final List<StoredMessage> newMessages = [];

      for (var msgData in messagesData) {
        try {
          final message = Message.fromJson(msgData);
          String? senderImageUrl = await _getUserImageUrl(message.senderId);

          final storedMessage = StoredMessage(
            id: message.id,
            text: message.content,
            timestamp: DateTime.parse(message.timestamp),
            senderId: message.senderId,
            sender: message.senderId == widget.currentUserId ? MessageSender.user : MessageSender.other,
            senderImageUrl: senderImageUrl,
            status: MessageStatus.seen,
            clientMessageId: null,
          );

          newMessages.add(storedMessage);
        } catch (e) {
          debugPrint('[GroupConversationPage] Error processing message in conversation: $e');
        }
      }

      // Sort messages by timestamp
      newMessages.sort((a, b) => a.timestamp.compareTo(b.timestamp));

      // Save to local storage
      await MessageStorageService.saveMessages(widget.groupId, newMessages);

      // Update UI
      if (mounted) {
        setState(() {
          _messages.clear();
          _messages.addAll(newMessages);
        });
        _scrollToBottom();
      }

      debugPrint('[GroupConversationPage] Loaded ${newMessages.length} conversation messages');

    } catch (e) {
      debugPrint('[GroupConversationPage] Error loading conversation messages: $e');
    }
  }

  void _handleIncomingMessage(Message message) async {
    debugPrint('[GroupConversationPage] Handling incoming message: ${message.content} from ${message.senderId}');

    if (message.senderId.isEmpty) {
      debugPrint('[GroupConversationPage] Incoming message has empty senderId, skipping');
      return;
    }

    // Check if this message is from the current user (to avoid duplicates)
    if (message.senderId == widget.currentUserId) {
      debugPrint('[GroupConversationPage] Processing own message from server: ${message.id}');
      return;
    }

    // Check for duplicates based on id or clientMessageId
    final localMessageIndex = _messages.indexWhere(
            (m) => m.id == message.id || (m.clientMessageId != null && m.clientMessageId == message.id)
    );

    if (localMessageIndex != -1) {
      debugPrint('[GroupConversationPage] Message already exists locally, skipping: ${message.id}');
      final updatedMessage = _messages[localMessageIndex].copyWith(
        id: message.id,
        status: MessageStatus.sent,
        clientMessageId: null,
      );

      await MessageStorageService.updateMessageStatus(
        widget.groupId,
        updatedMessage.id,
        MessageStatus.sent,
        oldClientMessageId: _messages[localMessageIndex].clientMessageId,
        clientMessageId: updatedMessage.clientMessageId,
      );
      if (mounted) {
        setState(() {
          _messages[localMessageIndex] = updatedMessage;
        });
      }
      return;
    }

    // Enhanced duplicate check based on content, senderId, and timestamp
    final timestampThreshold = Duration(seconds: 5); // Allow messages within 5 seconds to be considered duplicates
    final existingMessage = _messages.any((m) =>
    m.senderId == message.senderId &&
        m.text == message.content &&
        (DateTime.parse(message.timestamp).difference(m.timestamp).abs() < timestampThreshold));

    if (existingMessage) {
      debugPrint('[GroupConversationPage] Message is a duplicate based on content, sender, and timestamp, skipping: ${message.id}');
      return;
    }

    // Get real user image URL
    String? senderImageUrl = await _getUserImageUrl(message.senderId);

    final storedMessage = StoredMessage(
      id: message.id,
      text: message.content,
      timestamp: DateTime.parse(message.timestamp),
      senderId: message.senderId,
      sender: message.senderId == widget.currentUserId ? MessageSender.user : MessageSender.other,
      senderImageUrl: senderImageUrl,
      status: MessageStatus.seen,
      clientMessageId: null,
    );

    await MessageStorageService.addMessage(widget.groupId, storedMessage);

    if (mounted) {
      setState(() {
        _messages.add(storedMessage);
        _messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      });
      _scrollToBottom();

      if (message.senderId != widget.currentUserId) {
        _markMessagesAsRead();
      }

      debugPrint('[GroupConversationPage] Message added to UI: ${storedMessage.text}');
    }
  }


  void _handleTyping() {
    // You can implement typing indicator here if you want
  }

  /// Get user image URL with caching
  Future<String?> _getUserImageUrl(String userId) async {
    // Check cache first
    if (_userImages.containsKey(userId)) {
      return _userImages[userId];
    }

    // Get from API
    String? imageUrl;
    if (userId == widget.currentUserId) {
      // Current user - get from AuthProvider
      imageUrl = UserImageHelper.getCurrentUserImageUrl(context);
    } else {
      // Other user - get from API
      try {
        imageUrl = await UserImageHelper.getUserImageUrl(userId);
        debugPrint('[GroupConversationPage] Fetched image for user $userId: $imageUrl');
      } catch (e) {
        debugPrint('[GroupConversationPage] Error fetching image for user $userId: $e');
        imageUrl = null;
      }
    }

    // Cache the result
    _userImages[userId] = imageUrl;
    return imageUrl;
  }

  /// Mark messages as read
  void _markMessagesAsRead() async {
    try {
      final unreadMessages = _messages
          .where((msg) =>
      msg.sender == MessageSender.other &&
          (msg.status == MessageStatus.sent || msg.status == MessageStatus.delivered))
          .map((msg) => msg.id)
          .toList();

      if (unreadMessages.isNotEmpty) {
        debugPrint('[GroupConversationPage] Marking ${unreadMessages.length} messages as read');
        for (var messageId in unreadMessages) {
          await MessageStorageService.updateMessageStatus(widget.groupId, messageId, MessageStatus.seen);
        }

        // Update UI
        if (mounted) {
          setState(() {
            for (var message in _messages) {
              if (unreadMessages.contains(message.id)) {
                message = message.copyWith(status: MessageStatus.seen);
              }
            }
          });
        }
      }
    } catch (e) {
      debugPrint('[GroupConversationPage] Error marking messages as read: $e');
    }
  }

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) {
      debugPrint('[GroupConversationPage] Cannot send empty message');
      return;
    }

    if (!_isConversationReady) {
      debugPrint('[GroupConversationPage] Conversation not ready, cannot send message');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Connecting to chat... Please wait.')),
      );
      return;
    }

    debugPrint('[GroupConversationPage] Sending message: $text');
    final clientMessageId = _uuid.v4();

    final message = StoredMessage(
      id: clientMessageId,
      text: text,
      timestamp: DateTime.now(),
      sender: MessageSender.user,
      senderId: widget.currentUserId,
      senderImageUrl: UserImageHelper.getCurrentUserImageUrl(context), // Use real user image
      status: MessageStatus.sending,
      clientMessageId: clientMessageId,
    );

    setState(() {
      _messages.add(message);
      _messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    });
    _scrollToBottom();
    _messageController.clear();

    await MessageStorageService.addMessage(widget.groupId, message);

    try {
      debugPrint('[GroupConversationPage] Sending via WebSocket...');
      _groupChatSocketService.sendMessage(
          widget.groupId,
          widget.currentUserId,
          text,
          clientMessageId: clientMessageId
      );
      await MessageStorageService.updateMessageStatus(
          widget.groupId,
          message.id,
          MessageStatus.sent,
          clientMessageId: clientMessageId
      );
      debugPrint('[GroupConversationPage] Message sent successfully');
    } catch (e) {
      debugPrint('[GroupConversationPage] Failed to send message: $e');
      await MessageStorageService.updateMessageStatus(
          widget.groupId,
          message.id,
          MessageStatus.failed,
          clientMessageId: clientMessageId
      );

      // Show error to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send message: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
    _messageController.removeListener(_handleTyping);
    _messageController.dispose();
    _scrollController.dispose();
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
            // Group avatar
            _groupImageUrl != null && _groupImageUrl!.isNotEmpty
                ? UserImageHelper.buildUserAvatarWithErrorHandling(
              imageUrl: _groupImageUrl,
              radius: 18,
              backgroundColor: Colors.white,
              iconColor: Colors.grey[600],
            )
                : CircleAvatar(
              radius: 18,
              backgroundColor: Colors.white,
              child: Icon(
                Icons.group,
                color: Colors.grey[600],
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            // Group name and member count
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.groupName,
                    style: const TextStyle(color: Colors.white, fontSize: 20.0, fontWeight: FontWeight.w500),
                  ),
                  if (_memberCount > 0)
                    Text(
                      '$_memberCount members',
                      style: const TextStyle(color: Colors.white70, fontSize: 12.0),
                    ),
                  if (_isSomeoneTyping)
                    const Text(
                      'Someone is typing...',
                      style: TextStyle(color: Colors.white70, fontSize: 12.0),
                    ),
                ],
              ),
            ),
          ],
        ),
        centerTitle: false,
        actions: [
          // Connection status indicator
          Container(
            margin: const EdgeInsets.only(right: 8.0),
            child: _isConversationReady
                ? const Icon(Icons.wifi, color: Colors.green, size: 20)
                : const Icon(Icons.wifi_off, color: Colors.red, size: 20),
          ),
          IconButton(
            icon: const Icon(Icons.manage_accounts, color: Colors.white),
            tooltip: 'Group Manager',
            onPressed: () {
              debugPrint("PRINT groupId: ${widget.groupId}");
              debugPrint("PRINT conversationId: ${widget.groupId}"); // Use groupId as conversationId
              context.push(RoutePaths.groupManagement, extra: {
                'groupId': widget.groupId,
                'conversationId': widget.groupId, // Use groupId as conversationId since they should be the same
                'currentUserId': widget.currentUserId,
                'isCurrentUserAdmin': true, // You can replace with actual admin check
              });
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                ? const Center(child: Text('No messages yet. Start the conversation!', style: TextStyle(color: Colors.grey, fontSize: 16)))
                : ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16.0),
              itemCount: _messages.length,
              itemBuilder: (context, index) => _buildMessageBubble(_messages[index]),
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(StoredMessage message) {
    final bool isUser = message.sender == MessageSender.user;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Column(
          crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
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
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                    decoration: BoxDecoration(
                      color: isUser ? AppColors.receiverBubbleColor : AppColors.senderBubbleColor,
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Text(
                      message.text,
                      style: const TextStyle(fontSize: 14.0, fontFamily: 'Poppins'),
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
    final bool canSend = _isConversationReady && _messageController.text.trim().isNotEmpty;

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
          // Current user avatar
          UserImageHelper.buildCurrentUserAvatar(
            context: context,
            radius: 18,
            backgroundColor: Colors.grey[200],
            iconColor: Colors.grey[600],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _messageController,
              enabled: _isConversationReady,
              maxLines: null,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: _isConversationReady ? 'Type a message...' : 'Connecting to chat...',
                hintStyle: TextStyle(
                  color: _isConversationReady ? Colors.grey[600] : Colors.grey[400],
                ),
                filled: true,
                fillColor: _isConversationReady ? AppColors.chatInputFillColor : Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25.0),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
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
                canSend ? Icons.send : Icons.send_outlined,
                color: canSend ? Colors.white : Colors.grey[600],
                size: 20,
              ),
              padding: const EdgeInsets.all(8.0),
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              tooltip: canSend ? 'Send message' : (_isConversationReady ? 'Type a message' : 'Connecting...'),
            ),
          ),
        ],
      ),
    );
  }
}


