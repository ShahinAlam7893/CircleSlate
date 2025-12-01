// import 'dart:async';
// import 'dart:convert';
// import 'package:circleslate/core/utils/snackbar_utils.dart';
// import 'package:circleslate/data/models/conversation_model.dart';
// import 'package:circleslate/presentation/features/chat/widgets/professional_message_bubble.dart';
// import 'package:circleslate/presentation/routes/app_router.dart';
// import 'package:flutter/material.dart';
// import 'package:go_router/go_router.dart';
// import 'package:intl/intl.dart';
// import 'package:circleslate/core/constants/app_assets.dart';
// import 'package:circleslate/core/constants/app_colors.dart';
// import 'package:circleslate/core/services/message_storage_service.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:uuid/uuid.dart';
// import 'package:circleslate/core/utils/user_image_helper.dart';

// import '../../../../../data/services/typing_indicator_service.dart';
// import 'package:provider/provider.dart';
// import 'package:circleslate/presentation/common_providers/auth_provider.dart';

// import '../../../../../core/services/group/group_chat_socket_service.dart';
// import '../../../../../data/models/group_model.dart';
// import 'package:http/http.dart' as http;

// class GroupConversationProvider extends ChangeNotifier {
//   final TextEditingController messageController = TextEditingController();
//   final List<StoredMessage> _messages = [];
//   List<StoredMessage> get messages => List.unmodifiable(_messages);
//   final ScrollController scrollController = ScrollController();
//   final Uuid _uuid = const Uuid();

//   late GroupChatSocketService _groupChatSocketService;

//   bool _isLoading = true;
//   bool get isLoading => _isLoading;

//   bool _isConversationReady = false;
//   bool get isConversationReady => _isConversationReady;

//   bool _isTyping = false;
//   bool get isTyping => _isTyping;

//   Set<String> _typingUsers = <String>{};
//   Set<String> get typingUsers => _typingUsers;

//   final Map<String, String?> _userName = {};
//   final Map<String, String?> _userImages = {};

//   // Group information
//   String? _groupImageUrl;
//   String? get groupImageUrl => _groupImageUrl;

//   int _memberCount = 0;
//   int get memberCount => _memberCount;

//   final TypingIndicatorService _typingService = TypingIndicatorService();
//   StreamSubscription<Set<String>>? _typingSubscription;

//   Timer? _typingTimer;

//   final BuildContext context;
//   final String groupId;
//   final String currentUserId;
//   final String groupName;

//   GroupConversationProvider({
//     required this.context,
//     required this.groupId,
//     required this.currentUserId,
//     required this.groupName,
//   }) {
//     _groupChatSocketService = GroupChatSocketService(
//       onMessageReceived: _handleIncomingMessage,
//       onConversationMessages: _handleConversationMessages,
//     );

//     _initializeConversation();
//     messageController.addListener(_handleTyping);
//     messageController.addListener(notifyListeners);
//     _setupTypingIndicators();
//   }

//   void _setupTypingIndicators() {
//     _typingSubscription = _typingService.getGroupTypingStream(groupId).listen((
//       typingUsers,
//     ) {
//       _typingUsers = typingUsers;
//       notifyListeners();
//     });
//   }

//   Future<void> _initializeConversation() async {
//     _isLoading = true;
//     notifyListeners();

//     await _loadMessagesFromLocal();
//     await _connectWebSocket();
//     await _loadGroupInformation();

//     _isConversationReady = true;
//     _isLoading = false;
//     notifyListeners();
//   }

//   Future<void> _loadGroupInformation() async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final token = prefs.getString('accessToken');

//       if (token == null) return;

//       final response = await http.get(
//         Uri.parse(
//           'https://app.circleslate.com/api/chat/conversations/${groupId}/',
//         ),
//         headers: {
//           'Authorization': 'Bearer $token',
//           'Content-Type': 'application/json',
//         },
//       );

//       if (response.statusCode == 200) {
//         final groupData = jsonDecode(response.body);

//         // ✅ Check if user is still in the group
//         final isMember = groupData['is_member'] ?? true;

//         if (!isMember) {
//           // Redirect or block access
//           showDialog(
//             context: context,
//             builder: (_) => AlertDialog(
//               title: const Text("Access Denied"),
//               content: const Text("You are no longer a member of this group."),
//               actions: [
//                 TextButton(
//                   onPressed: () {
//                     Navigator.pop(context);
//                   },
//                   child: const Text("OK"),
//                 ),
//               ],
//             ),
//           );
//           return;
//         }

//         _groupImageUrl = groupData['display_photo'];
//         _memberCount = groupData['participant_count'] ?? 0;

//         debugPrint(
//           '[GroupConversationPage] Group info loaded: $_memberCount members',
//         );
//         notifyListeners();
//       } else if (response.statusCode == 403) {
//         // Not a member -> block access
//         Navigator.pop(context);
//       }
//     } catch (e) {
//       debugPrint('[GroupConversationPage] Error loading group information: $e');
//     }
//   }

//   Future<void> _loadMessagesFromLocal() async {
//     try {
//       final messages = await MessageStorageService.loadMessages(groupId);
//       _messages.clear();
//       _messages.addAll(messages);
//       _scrollToBottom();
//       notifyListeners();
//     } catch (e) {
//       debugPrint('Error loading local messages: $e');
//       await MessageStorageService.clearMessages(groupId);
//     }
//   }

//   Future<void> _connectWebSocket() async {
//     final prefs = await SharedPreferences.getInstance();
//     final token = prefs.getString('accessToken');
//     if (token == null) {
//       debugPrint('[GroupConversationPage] No token found!');
//       _isConversationReady = false;
//       notifyListeners();
//       return;
//     }

//     try {
//       debugPrint('[GroupConversationPage] Connecting to WebSocket...');
//       await _groupChatSocketService.connect(groupId, token);
//       debugPrint('[GroupConversationPage] WebSocket connected successfully');

//       // Monitor connection status
//       _groupChatSocketService.connectionStatusStream.listen((isConnected) {
//         debugPrint(
//           '[GroupConversationPage] WebSocket connection status: $isConnected',
//         );
//         _isConversationReady = isConnected;
//         notifyListeners();
//       });

//       _requestConversationMessages();
//     } catch (e) {
//       debugPrint('[GroupConversationPage] WebSocket connection failed: $e');
//       _isConversationReady = false;
//       notifyListeners();

//       SnackbarUtils.showError(
//         context,
//         'Failed to connect to chat: ${e.toString()}',
//       );
//     }
//   }

//   void retryMessage(StoredMessage message) async {
//     final index = _messages.indexWhere((m) => m.id == message.id);
//     if (index != -1) {
//       _messages[index] = message.copyWith(status: MessageStatus.sending);
//       notifyListeners();
//     }

//     await MessageStorageService.updateMessageStatus(
//       groupId,
//       message.id,
//       MessageStatus.sending,
//       clientMessageId: message.clientMessageId,
//     );

//     try {
//       debugPrint('[GroupConversationPage] Retrying message: ${message.text}');
//       _groupChatSocketService.sendMessage(
//         groupId,
//         currentUserId,
//         message.text,
//         clientMessageId: message.clientMessageId ?? message.id,
//       );
//       await MessageStorageService.updateMessageStatus(
//         groupId,
//         message.id,
//         MessageStatus.sent,
//         clientMessageId: message.clientMessageId,
//       );
//       debugPrint('[GroupConversationPage] Message retry successful');
//     } catch (e) {
//       debugPrint('[GroupConversationPage] Failed to retry message: $e');
//       await MessageStorageService.updateMessageStatus(
//         groupId,
//         message.id,
//         MessageStatus.failed,
//         clientMessageId: message.clientMessageId,
//       );

//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Failed to retry message: ${e.toString()}'),
//           backgroundColor: Colors.red,
//         ),
//       );
//     }
//   }

//   /// Request conversation messages from server
//   void _requestConversationMessages() {
//     try {
//       final request = {
//         'type': 'get_conversation_messages',
//         'conversation_id': groupId,
//       };
//       _groupChatSocketService.sendRawMessage(jsonEncode(request));
//       debugPrint('[GroupConversationPage] Requested conversation messages');
//     } catch (e) {
//       debugPrint(
//         '[GroupConversationPage] Error requesting conversation messages: $e',
//       );
//     }
//   }

//   void _handleConversationMessages(List<dynamic> messagesData) async {
//     debugPrint(
//       '[GroupConversationPage] Processing ${messagesData.length} conversation messages',
//     );

//     print("current user id ===> ${currentUserId}");
//     try {
//       final List<StoredMessage> merged = [..._messages];
//       bool changed = false;

//       for (var msgData in messagesData) {
//         try {
//           final message = Message.fromJson(msgData);
//           String? senderImageUrl = await _getUserImageUrl(message.senderId);

//           final storedMessage = StoredMessage(
//             id: message.id,
//             text: message.content,
//             timestamp: DateTime.parse(message.timestamp),
//             senderId: message.senderId,
//             sender: message.senderId == currentUserId
//                 ? MessageSender.user
//                 : MessageSender.other,
//             senderImageUrl: senderImageUrl,
//             status: MessageStatus.seen,
//             clientMessageId: null,
//             senderName: message.senderName,
//           );

//           final existingIndex = merged.indexWhere(
//             (m) =>
//                 m.id == storedMessage.id ||
//                 (m.clientMessageId != null &&
//                     m.clientMessageId == storedMessage.clientMessageId),
//           );

//           if (existingIndex != -1) {
//             merged[existingIndex] = storedMessage;
//             changed = true;
//           } else {
//             merged.add(storedMessage);
//             changed = true;
//           }
//         } catch (e) {
//           debugPrint(
//             '[GroupConversationPage] Error processing message in conversation: $e',
//           );
//         }
//       }

//       if (changed) {
//         merged.sort((a, b) => a.timestamp.compareTo(b.timestamp));
//         await MessageStorageService.saveMessages(groupId, merged);
//         _messages.clear();
//         _messages.addAll(merged);
//         _scrollToBottom();
//         debugPrint(
//           '[GroupConversationPage] Loaded ${merged.length} conversation messages',
//         );
//         notifyListeners();
//       } else {
//         debugPrint('No changes from history merge');
//       }
//     } catch (e) {
//       debugPrint(
//         '[GroupConversationPage] Error loading conversation messages: $e',
//       );
//     }
//   }

//   void _handleIncomingMessage(Message message) async {
//     debugPrint(
//       '[GroupConversationPage] Handling incoming message: ${message.content} from ${message.senderId}',
//     );

//     if (message.senderId.isEmpty) {
//       debugPrint(
//         '[GroupConversationPage] Incoming message has empty senderId, skipping',
//       );
//       return;
//     }

//     // Check if this message is from the current user (to avoid duplicates)
//     if (message.senderId == currentUserId) {
//       debugPrint(
//         '[GroupConversationPage] Processing own message from server: ${message.id}',
//       );
//       return;
//     }

//     // Check for duplicates based on id or clientMessageId
//     final localMessageIndex = _messages.indexWhere(
//       (m) =>
//           m.id == message.id ||
//           (m.clientMessageId != null && m.clientMessageId == message.id),
//     );

//     if (localMessageIndex != -1) {
//       debugPrint(
//         '[GroupConversationPage] Message already exists locally, skipping: ${message.id}',
//       );
//       final updatedMessage = _messages[localMessageIndex].copyWith(
//         id: message.id,
//         status: MessageStatus.sent,
//         clientMessageId: null,
//       );

//       await MessageStorageService.updateMessageStatus(
//         groupId,
//         updatedMessage.id,
//         MessageStatus.sent,
//         // oldClientMessageId: _messages[localMessageIndex].clientMessageId,
//         clientMessageId: updatedMessage.clientMessageId,
//       );
//       _messages[localMessageIndex] = updatedMessage;
//       notifyListeners();
//       return;
//     }

//     // Enhanced duplicate check based on content, senderId, and timestamp
//     final timestampThreshold = Duration(
//       seconds: 5,
//     ); // Allow messages within 5 seconds to be considered duplicates
//     final existingMessage = _messages.any(
//       (m) =>
//           m.senderId == message.senderId &&
//           m.text == message.content &&
//           (DateTime.parse(message.timestamp).difference(m.timestamp).abs() <
//               timestampThreshold),
//     );

//     if (existingMessage) {
//       debugPrint(
//         '[GroupConversationPage] Message is a duplicate based on content, sender, and timestamp, skipping: ${message.id}',
//       );
//       return;
//     }

//     // Get real user image URL
//     String? senderImageUrl = await _getUserImageUrl(message.senderId);

//     final storedMessage = StoredMessage(
//       id: message.id,
//       text: message.content,
//       timestamp: DateTime.parse(message.timestamp),
//       senderId: message.senderId,
//       sender: message.senderId == currentUserId
//           ? MessageSender.user
//           : MessageSender.other,
//       senderImageUrl: senderImageUrl,
//       status: MessageStatus.seen,
//       clientMessageId: null,
//       senderName: message.senderName,
//     );

//     await MessageStorageService.addMessage(groupId, storedMessage);

//     _messages.add(storedMessage);
//     if (_messages.length > 1 &&
//         storedMessage.timestamp.isBefore(
//           _messages[_messages.length - 2].timestamp,
//         )) {
//       _messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
//     }
//     _scrollToBottom();

//     if (message.senderId != currentUserId) {
//       _markMessagesAsRead();
//     }

//     debugPrint(
//       '[GroupConversationPage] Message added to UI: ${storedMessage.text}',
//     );
//     notifyListeners();
//   }

//   void _handleTyping() {
//     final isTyping = messageController.text.isNotEmpty;

//     if (isTyping != _isTyping) {
//       _isTyping = isTyping;
//       notifyListeners();

//       // Cancel previous timer
//       _typingTimer?.cancel();

//       if (isTyping) {
//         // Send typing indicator
//         _groupChatSocketService.sendRawMessage(
//           jsonEncode({
//             'type': 'typing',
//             'conversation_id': groupId,
//             'user_id': currentUserId,
//             'is_typing': true,
//           }),
//         );

//         // Set timer to stop typing after 3 seconds of inactivity
//         _typingTimer = Timer(const Duration(seconds: 3), () {
//           _isTyping = false;
//           notifyListeners();
//           _groupChatSocketService.sendRawMessage(
//             jsonEncode({
//               'type': 'typing',
//               'conversation_id': groupId,
//               'user_id': currentUserId,
//               'is_typing': false,
//             }),
//           );
//         });
//       } else {
//         // Send stop typing indicator immediately
//         _groupChatSocketService.sendRawMessage(
//           jsonEncode({
//             'type': 'typing',
//             'conversation_id': groupId,
//             'user_id': currentUserId,
//             'is_typing': false,
//           }),
//         );
//       }
//     }
//   }

//   /// Get user image URL with caching
//   Future<String?> _getUserImageUrl(String userId) async {
//     // Check cache first
//     if (_userImages.containsKey(userId)) {
//       return _userImages[userId];
//     }

//     // Get from API
//     String? imageUrl;
//     if (userId == currentUserId) {
//       // Current user - get from AuthProvider
//       imageUrl = UserImageHelper.getCurrentUserImageUrl(context);
//     } else {
//       try {
//         imageUrl = await UserImageHelper.getUserImageUrl(userId);
//         debugPrint(
//           '[GroupConversationPage] Fetched image for user $userId: $imageUrl',
//         );
//       } catch (e) {
//         debugPrint(
//           '[GroupConversationPage] Error fetching image for user $userId: $e',
//         );
//         imageUrl = null;
//       }
//     }

//     _userImages[userId] = imageUrl;
//     return imageUrl;
//   }

//   /// Mark messages as read
//   void _markMessagesAsRead() async {
//     try {
//       final unreadMessages = _messages
//           .where(
//             (msg) =>
//                 msg.sender == MessageSender.other &&
//                 (msg.status == MessageStatus.sent ||
//                     msg.status == MessageStatus.delivered),
//           )
//           .map((msg) => msg.id)
//           .toList();

//       if (unreadMessages.isNotEmpty) {
//         debugPrint(
//           '[GroupConversationPage] Marking ${unreadMessages.length} messages as read',
//         );
//         for (var messageId in unreadMessages) {
//           await MessageStorageService.updateMessageStatus(
//             groupId,
//             messageId,
//             MessageStatus.seen,
//           );
//         }

//         // Update UI
//         for (int i = 0; i < _messages.length; i++) {
//           if (unreadMessages.contains(_messages[i].id)) {
//             _messages[i] = _messages[i].copyWith(status: MessageStatus.seen);
//           }
//         }
//         notifyListeners();
//       }
//     } catch (e) {
//       debugPrint('[GroupConversationPage] Error marking messages as read: $e');
//     }
//   }

//   void sendMessage() async {
//     final text = messageController.text.trim();
//     if (text.isEmpty) {
//       debugPrint('[GroupConversationPage] Cannot send empty message');
//       return;
//     }

//     if (!_isConversationReady) {
//       debugPrint(
//         '[GroupConversationPage] Conversation not ready, cannot send message',
//       );
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Connecting to chat... Please wait.')),
//       );
//       return;
//     }

//     debugPrint('[GroupConversationPage] Sending message: $text');
//     final clientMessageId = _uuid.v4();

//     final message = StoredMessage(
//       id: clientMessageId,
//       text: text,
//       timestamp: DateTime.now(),
//       sender: MessageSender.user,
//       senderId: currentUserId,
//       senderImageUrl: UserImageHelper.getCurrentUserImageUrl(context),
//       status: MessageStatus.sending,
//       clientMessageId: clientMessageId,
//       senderName: '', // ✅ provide current user name
//     );

//     _messages.add(message);
//     if (_messages.length > 1 &&
//         message.timestamp.isBefore(_messages[_messages.length - 2].timestamp)) {
//       _messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
//     }
//     _scrollToBottom();
//     messageController.clear();
//     notifyListeners();

//     await MessageStorageService.addMessage(groupId, message);

//     try {
//       debugPrint('[GroupConversationPage] Sending via WebSocket...');
//       _groupChatSocketService.sendMessage(
//         groupId,
//         currentUserId,
//         text,
//         clientMessageId: clientMessageId,
//       );
//       await MessageStorageService.updateMessageStatus(
//         groupId,
//         message.id,
//         MessageStatus.sent,
//         clientMessageId: clientMessageId,
//       );
//       debugPrint('[GroupConversationPage] Message sent successfully');
//     } catch (e) {
//       debugPrint('[GroupConversationPage] Failed to send message: $e');
//       await MessageStorageService.updateMessageStatus(
//         groupId,
//         message.id,
//         MessageStatus.failed,
//         clientMessageId: clientMessageId,
//       );

//       // Show error to user
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Failed to send message: ${e.toString()}'),
//           backgroundColor: Colors.red,
//         ),
//       );
//     }
//   }

//   void _scrollToBottom() {
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       if (scrollController.hasClients) {
//         scrollController.animateTo(
//           scrollController.position.maxScrollExtent,
//           duration: const Duration(milliseconds: 300),
//           curve: Curves.easeOut,
//         );
//       }
//     });
//   }

//   void resume() {
//     debugPrint('[GroupConversationPage] App resumed - reconnecting if needed');
//     if (!_isConversationReady) {
//       _connectWebSocket();
//     }
//   }

//   void pause() {
//     debugPrint('[GroupConversationPage] App paused');
//   }

//   void disposeAll() {
//     _groupChatSocketService.disconnect();
//     messageController.removeListener(_handleTyping);
//     messageController.removeListener(notifyListeners);
//     _typingTimer?.cancel();
//     _typingSubscription?.cancel();
//     _typingService.disposeGroup(groupId);
//     messageController.dispose();
//     scrollController.dispose();
//     notifyListeners();
//   }
// }

// class GroupConversationPage extends StatefulWidget {
//   final String groupId;
//   final String currentUserId;
//   final String groupName;

//   const GroupConversationPage({
//     super.key,
//     required this.groupId,
//     required this.currentUserId,
//     required this.groupName,
//   });

//   @override
//   State<GroupConversationPage> createState() => _GroupConversationPageState();
// }

// class _GroupConversationPageState extends State<GroupConversationPage>
//     with WidgetsBindingObserver {
//   late final GroupConversationProvider _provider;

//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addObserver(this);

//     _provider = GroupConversationProvider(
//       context: context,
//       groupId: widget.groupId,
//       currentUserId: widget.currentUserId,
//       groupName: widget.groupName,
//     );
//   }

//   @override
//   void dispose() {
//     _provider.disposeAll();
//     WidgetsBinding.instance.removeObserver(this);
//     super.dispose();
//   }

//   @override
//   void didChangeAppLifecycleState(AppLifecycleState state) {
//     if (state == AppLifecycleState.resumed) {
//       _provider.resume();
//     } else if (state == AppLifecycleState.paused) {
//       _provider.pause();
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return ChangeNotifierProvider.value(
//       value: _provider,
//       child: Scaffold(
//         appBar: AppBar(
//           backgroundColor: AppColors.primaryBlue,
//           leading: IconButton(
//             icon: const Icon(Icons.arrow_back, color: Colors.white),
//             onPressed: () => Navigator.pop(context),
//           ),
//           title: Consumer<GroupConversationProvider>(
//             builder: (context, provider, child) {
//               return Row(
//                 children: [
//                   // Group avatar
//                   provider.groupImageUrl != null &&
//                           provider.groupImageUrl!.isNotEmpty
//                       ? UserImageHelper.buildUserAvatarWithErrorHandling(
//                           imageUrl: provider.groupImageUrl,
//                           radius: 18,
//                           backgroundColor: Colors.white,
//                           iconColor: Colors.grey[600],
//                         )
//                       : CircleAvatar(
//                           radius: 18,
//                           backgroundColor: Colors.white,
//                           child: Icon(
//                             Icons.group,
//                             color: Colors.grey[600],
//                             size: 20,
//                           ),
//                         ),
//                   const SizedBox(width: 12),
//                   // Group name and member count
//                   Expanded(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           widget.groupName,
//                           style: const TextStyle(
//                             color: Colors.white,
//                             fontSize: 20.0,
//                             fontWeight: FontWeight.w500,
//                           ),
//                         ),
//                         if (provider.memberCount > 0)
//                           Text(
//                             '${provider.memberCount} members',
//                             style: const TextStyle(
//                               color: Colors.white70,
//                               fontSize: 12.0,
//                             ),
//                           ),
//                         if (provider.typingUsers.isNotEmpty)
//                           const Text(
//                             'Someone is typing...',
//                             style: TextStyle(
//                               color: Colors.white70,
//                               fontSize: 12.0,
//                             ),
//                           ),
//                       ],
//                     ),
//                   ),
//                 ],
//               );
//             },
//           ),
//           centerTitle: false,
//           actions: [
//             // Connection status indicator
//             Container(
//               margin: const EdgeInsets.only(right: 8.0),
//               child: Consumer<GroupConversationProvider>(
//                 builder: (context, provider, child) {
//                   return provider.isConversationReady
//                       ? const Icon(Icons.wifi, color: Colors.green, size: 20)
//                       : const Icon(Icons.wifi_off, color: Colors.red, size: 20);
//                 },
//               ),
//             ),
//             IconButton(
//               icon: const Icon(Icons.manage_accounts, color: Colors.white),
//               tooltip: 'Group Manager',
//               onPressed: () {
//                 debugPrint("PRINT groupId: ${widget.groupId}");
//                 debugPrint(
//                   "PRINT conversationId: ${widget.groupId}",
//                 ); // Use groupId as conversationId
//                 context.push(
//                   RoutePaths.groupManagement,
//                   extra: {
//                     'groupId': widget.groupId,
//                     'conversationId': widget
//                         .groupId, // Use groupId as conversationId since they should be the same
//                     'currentUserId': widget.currentUserId,
//                     'isCurrentUserAdmin':
//                         true, // You can replace with actual admin check
//                   },
//                 );
//               },
//             ),
//             const SizedBox(width: 8),
//           ],
//         ),
//         body: Column(
//           children: [
//             Expanded(
//               child: Consumer<GroupConversationProvider>(
//                 builder: (context, provider, child) {
//                   return provider.isLoading
//                       ? const Center(child: CircularProgressIndicator())
//                       : provider.messages.isEmpty
//                       ? const Center(
//                           child: Text(
//                             'No messages yet. Start the conversation!',
//                             style: TextStyle(color: Colors.grey, fontSize: 16),
//                           ),
//                         )
//                       : ListView.builder(
//                           controller: provider.scrollController,
//                           padding: const EdgeInsets.symmetric(vertical: 8.0),
//                           itemCount:
//                               provider.messages.length +
//                               (provider.typingUsers.isNotEmpty ? 1 : 0),
//                           itemBuilder: (context, index) {
//                             if (index == provider.messages.length &&
//                                 provider.typingUsers.isNotEmpty) {
//                               // Show typing indicator
//                               return Padding(
//                                 padding: const EdgeInsets.symmetric(
//                                   horizontal: 16.0,
//                                   vertical: 8.0,
//                                 ),
//                                 child: Row(
//                                   children: [
//                                     const SizedBox(
//                                       width: 40,
//                                     ), // Space for avatar
//                                     Expanded(
//                                       child: Container(
//                                         padding: const EdgeInsets.symmetric(
//                                           horizontal: 12.0,
//                                           vertical: 8.0,
//                                         ),
//                                         decoration: BoxDecoration(
//                                           color: Colors.grey[200],
//                                           borderRadius: BorderRadius.circular(
//                                             18.0,
//                                           ),
//                                         ),
//                                         child: Text(
//                                           provider.typingUsers.length == 1
//                                               ? '${provider.typingUsers.first} is typing...'
//                                               : '${provider.typingUsers.join(', ')} are typing...',
//                                           style: const TextStyle(
//                                             fontStyle: FontStyle.italic,
//                                             color: Colors.grey,
//                                           ),
//                                         ),
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                               );
//                             }
//                             return ProfessionalMessageBubble(
//                               message: provider.messages[index],
//                               currentUserId: widget.currentUserId,
//                               showAvatar: true,
//                               showTimestamp: true,
//                               isGroupChat: true,
//                               onRetry:
//                                   provider.messages[index].status ==
//                                       MessageStatus.failed
//                                   ? () => provider.retryMessage(
//                                       provider.messages[index],
//                                     )
//                                   : null,
//                             );
//                           },
//                         );
//                 },
//               ),
//             ),
//             Consumer<GroupConversationProvider>(
//               builder: (context, provider, child) =>
//                   _buildMessageInput(provider),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildMessageBubble(StoredMessage message, String currentUserId) {
//     final bool isUser = message.senderId == currentUserId;

//     return Align(
//       alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
//       child: Padding(
//         padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
//         child: Column(
//           crossAxisAlignment: isUser
//               ? CrossAxisAlignment.end
//               : CrossAxisAlignment.start,
//           children: [
//             if (!isUser &&
//                 message.senderName != null &&
//                 message.senderName!.isNotEmpty)
//               Padding(
//                 padding: const EdgeInsets.only(left: 8.0, bottom: 2.0),
//                 child: Text(
//                   message.senderName!,
//                   style: const TextStyle(
//                     fontSize: 12.0,
//                     fontWeight: FontWeight.w500,
//                     color: Colors.grey,
//                   ),
//                 ),
//               ),
//             Row(
//               mainAxisSize: MainAxisSize.min,
//               crossAxisAlignment: CrossAxisAlignment.end,
//               children: [
//                 if (!isUser)
//                   UserImageHelper.buildUserAvatarWithErrorHandling(
//                     imageUrl: message.senderImageUrl,
//                     radius: 16,
//                     backgroundColor: Colors.grey[200],
//                     iconColor: Colors.grey[600],
//                   ),
//                 const SizedBox(width: 8.0),
//                 Flexible(
//                   child: Container(
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 16.0,
//                       vertical: 10.0,
//                     ),
//                     decoration: BoxDecoration(
//                       color: isUser
//                           ? AppColors.receiverBubbleColor
//                           : AppColors.senderBubbleColor,
//                       borderRadius: BorderRadius.circular(12.0),
//                     ),
//                     child: Text(
//                       message.text,
//                       style: const TextStyle(
//                         fontSize: 14.0,
//                         fontFamily: 'Poppins',
//                       ),
//                     ),
//                   ),
//                 ),
//                 if (isUser) const SizedBox(width: 8.0),
//                 if (isUser)
//                   Row(
//                     children: [
//                       _buildMessageStatusIcon(message.status),
//                       const SizedBox(width: 4.0),
//                       UserImageHelper.buildUserAvatarWithErrorHandling(
//                         imageUrl: message.senderImageUrl,
//                         radius: 16,
//                         backgroundColor: Colors.grey[200],
//                         iconColor: Colors.grey[600],
//                       ),
//                     ],
//                   ),
//               ],
//             ),
//             const SizedBox(height: 4.0),
//             Text(
//               DateFormat('h:mm a').format(message.timestamp),
//               style: const TextStyle(fontSize: 10.0, color: Color(0x991A1A1A)),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildMessageStatusIcon(MessageStatus status) {
//     switch (status) {
//       case MessageStatus.sending:
//         return const Icon(Icons.access_time, size: 12, color: Colors.grey);
//       case MessageStatus.sent:
//         return const Icon(Icons.check, size: 12, color: Colors.grey);
//       case MessageStatus.delivered:
//         return const Icon(Icons.done_all, size: 12, color: Colors.grey);
//       case MessageStatus.seen:
//         return const Icon(Icons.done_all, size: 12, color: Colors.blue);
//       case MessageStatus.failed:
//         return const Icon(Icons.error_outline, size: 12, color: Colors.red);
//       default:
//         return const SizedBox.shrink();
//     }
//   }

//   Widget _buildMessageInput(GroupConversationProvider provider) {
//     final bool canSend =
//         provider.isConversationReady &&
//         provider.messageController.text.trim().isNotEmpty;

//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.1),
//             blurRadius: 4,
//             offset: const Offset(0, -2),
//           ),
//         ],
//       ),
//       child: Row(
//         children: [
//           // Current user avatar
//           UserImageHelper.buildCurrentUserAvatar(
//             context: context,
//             radius: 18,
//             backgroundColor: Colors.grey[200],
//             iconColor: Colors.grey[600],
//           ),
//           const SizedBox(width: 12),
//           Expanded(
//             child: TextField(
//               controller: provider.messageController,
//               enabled: provider.isConversationReady,
//               maxLines: null,
//               textCapitalization: TextCapitalization.sentences,
//               decoration: InputDecoration(
//                 hintText: provider.isConversationReady
//                     ? 'Type a message...'
//                     : 'Connecting to chat...',
//                 hintStyle: TextStyle(
//                   color: provider.isConversationReady
//                       ? Colors.grey[600]
//                       : Colors.grey[400],
//                 ),
//                 filled: true,
//                 fillColor: provider.isConversationReady
//                     ? AppColors.chatInputFillColor
//                     : Colors.grey[100],
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(25.0),
//                   borderSide: BorderSide.none,
//                 ),
//                 contentPadding: const EdgeInsets.symmetric(
//                   horizontal: 16.0,
//                   vertical: 12.0,
//                 ),
//               ),
//               onSubmitted: (_) => canSend ? provider.sendMessage() : null,
//             ),
//           ),
//           const SizedBox(width: 8.0),
//           Container(
//             decoration: BoxDecoration(
//               color: canSend ? AppColors.primaryBlue : Colors.grey[300],
//               shape: BoxShape.circle,
//             ),
//             child: IconButton(
//               onPressed: canSend ? provider.sendMessage : null,
//               icon: Icon(
//                 canSend ? Icons.send : Icons.send_outlined,
//                 color: canSend ? Colors.white : Colors.grey[600],
//                 size: 20,
//               ),
//               padding: const EdgeInsets.all(8.0),
//               constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
//               tooltip: canSend
//                   ? 'Send message'
//                   : (provider.isConversationReady
//                         ? 'Type a message'
//                         : 'Connecting...'),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
