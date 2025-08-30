// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import 'package:circleslate/core/constants/app_assets.dart';
// import 'package:circleslate/core/constants/app_colors.dart';
// import 'package:circleslate/core/services/websocket_service.dart';
// import 'package:circleslate/core/services/chat_api_service.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:http/http.dart' as http;
//
// enum MessageSender { user, other }
// enum MessageStatus { sent, delivered, seen }
//
// class Message {
//   final String text;
//   final DateTime timestamp;
//   final MessageSender sender;
//   final String? senderImageUrl;
//   final MessageStatus status;
//
//   const Message({
//     required this.text,
//     required this.timestamp,
//     required this.sender,
//     this.senderImageUrl,
//     this.status = MessageStatus.sent,
//   });
// }
//
// class OneToOneConversationPage extends StatefulWidget {
//   final String chatPartnerName;
//   final String currentUserId;
//   final String chatPartnerId;
//   final String? conversationId;
//
//   const OneToOneConversationPage({
//     super.key,
//     required this.chatPartnerName,
//     required this.currentUserId,
//     required this.chatPartnerId,
//     this.conversationId,
//   });
//
//   @override
//   State<OneToOneConversationPage> createState() => _OneToOneConversationPageState();
// }
//
// class _OneToOneConversationPageState extends State<OneToOneConversationPage> with WidgetsBindingObserver {
//   final TextEditingController _messageController = TextEditingController();
//   final List<Message> _messages = [];
//   final ChatSocketService _chatSocketService = ChatSocketService();
//   final ChatApiService _chatApiService = ChatApiService();
//   final ScrollController _scrollController = ScrollController();
//
//   String? _conversationId;
//   bool _isLoading = true;
//   DateTime? _lastMessageTime;
//   bool _isConversationReady = true;
//
//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addObserver(this);
//     _initializeConversation();
//   }
//
//   void _initializeConversation() async {
//     if (widget.conversationId != null) {
//       setState(() {
//         _conversationId = widget.conversationId!;
//         _isConversationReady = true;
//       });
//     } else {
//       final id = await _getOrCreateConversationId();
//       setState(() {
//         _conversationId = id;
//         _isConversationReady = true;
//       });
//     }
//     await _loadMessagesFromLocal();
//     _loadMessages();
//   }
//
//   Future<void> _loadMessagesFromLocal() async {
//     if (_conversationId == null) return;
//     final prefs = await SharedPreferences.getInstance();
//     final messageJsonList = prefs.getStringList('messages_${_conversationId!}') ?? [];
//     final pendingMessages = prefs.getStringList('pending_messages_${_conversationId!}') ?? [];
//
//     final loadedMessages = messageJsonList.map((jsonStr) {
//       final data = jsonDecode(jsonStr);
//       return Message(
//         text: data['text'],
//         timestamp: DateTime.parse(data['timestamp']),
//         sender: data['sender'] == 'user' ? MessageSender.user : MessageSender.other,
//         senderImageUrl: data['senderImageUrl'],
//         status: MessageStatus.values.firstWhere((e) => e.toString() == data['status']),
//       );
//     }).toList();
//
//     for (var jsonStr in pendingMessages) {
//       final data = jsonDecode(jsonStr);
//       loadedMessages.add(Message(
//         text: data['content'],
//         timestamp: DateTime.parse(data['timestamp']),
//         sender: MessageSender.user,
//         senderImageUrl: AppAssets.jennyProfile,
//         status: MessageStatus.sent,
//       ));
//     }
//
//     setState(() {
//       _messages.clear();
//       _messages.addAll(loadedMessages);
//       _messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
//       if (_messages.isNotEmpty) {
//         _lastMessageTime = _messages.last.timestamp;
//       }
//     });
//     _scrollToBottom();
//   }
//
//   Future<void> _saveMessagesToLocal() async {
//     if (!_isConversationReady || _conversationId == null) return;
//     final prefs = await SharedPreferences.getInstance();
//     final messageJsonList = _messages.map((msg) => jsonEncode({
//       'text': msg.text,
//       'timestamp': msg.timestamp.toIso8601String(),
//       'sender': msg.sender == MessageSender.user ? 'user' : 'other',
//       'senderImageUrl': msg.senderImageUrl,
//       'status': msg.status.toString(),
//     })).toList();
//     await prefs.setStringList('messages_${_conversationId!}', messageJsonList);
//   }
//
//   Future<void> _removePendingMessage(String clientMessageId) async {
//     if (_conversationId == null) return;
//     final prefs = await SharedPreferences.getInstance();
//     final pendingMessages = prefs.getStringList('pending_messages_${_conversationId!}') ?? [];
//     pendingMessages.removeWhere((jsonStr) => jsonDecode(jsonStr)['client_message_id'] == clientMessageId);
//     await prefs.setStringList('pending_messages_${_conversationId!}', pendingMessages);
//   }
//
//   void _loadMessages() async {
//     if (_conversationId == null) return;
//     setState(() {
//       _isLoading = true;
//     });
//
//     try {
//       final history = await _chatApiService.fetchChatHistory(_conversationId!);
//       final uiMessages = history.map((messageModel) {
//         return Message(
//           text: messageModel.content,
//           timestamp: messageModel.timestamp,
//           sender: messageModel.senderId == widget.currentUserId ? MessageSender.user : MessageSender.other,
//           senderImageUrl: messageModel.senderId == widget.currentUserId ? AppAssets.jennyProfile : AppAssets.sarahMartinez,
//           status: messageModel.isRead ? MessageStatus.seen : MessageStatus.delivered,
//         );
//       }).toList();
//
//       setState(() {
//         _messages.clear();
//         _messages.addAll(uiMessages);
//         _messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
//         _lastMessageTime = _messages.isNotEmpty ? _messages.last.timestamp : null;
//         _isLoading = false;
//       });
//       _saveMessagesToLocal();
//       _scrollToBottom();
//     } catch (e) {
//       print("Failed to load chat history: $e");
//       setState(() {
//         _isLoading = false;
//       });
//     }
//
//     _connectWebSocket();
//   }
//
//   void _connectWebSocket() async {
//     if (_conversationId == null) return;
//     try {
//       await _chatSocketService.connect(_conversationId!);
//
//       _chatSocketService.messages.listen((data) {
//         try {
//           final decoded = jsonDecode(data);
//           print('Received WebSocket data: $decoded');
//
//           if (decoded['type'] == 'conversation_messages' && decoded['messages'] != null) {
//             final messages = decoded['messages'] as List;
//             for (var msgData in messages) {
//               _addMessageFromServer(msgData);
//             }
//           } else if (decoded['content'] != null && decoded['sender'] != null) {
//             _addMessageFromServer(decoded);
//           } else if (decoded['type'] == 'new_message' || decoded['message'] != null) {
//             final msgData = decoded['message'] ?? decoded;
//             if (msgData['content'] != null) {
//               _addMessageFromServer(msgData);
//             }
//           }
//         } catch (e) {
//           print('Error parsing WebSocket message: $e');
//         }
//       });
//     } catch (e) {
//       print("WebSocket connection failed: $e");
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Failed to connect to chat: $e')),
//         );
//       }
//     }
//   }
//
//   void _addMessageFromServer(Map<String, dynamic> msgData) {
//     try {
//       final message = Message(
//         text: msgData['content'] ?? '',
//         timestamp: DateTime.parse(msgData['timestamp'] ?? DateTime.now().toIso8601String()),
//         sender: msgData['sender']['id'].toString() == widget.currentUserId
//             ? MessageSender.user
//             : MessageSender.other,
//         senderImageUrl: msgData['sender']['id'].toString() == widget.currentUserId
//             ? AppAssets.jennyProfile
//             : AppAssets.sarahMartinez,
//         status: msgData['is_read'] == true ? MessageStatus.seen : MessageStatus.delivered,
//       );
//
//       setState(() {
//         if (msgData['client_message_id'] != null) {
//           _messages.removeWhere((msg) =>
//           msg.text == message.text &&
//               msg.sender == message.sender &&
//               msg.timestamp.difference(message.timestamp).abs().inSeconds < 5);
//         }
//         _messages.add(message);
//         _messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
//         _lastMessageTime = message.timestamp;
//       });
//       _saveMessagesToLocal();
//       _scrollToBottom();
//
//       if (msgData['client_message_id'] != null) {
//         _removePendingMessage(msgData['client_message_id']);
//       }
//     } catch (e) {
//       print('Error adding message from server: $e');
//     }
//   }
//
//   void _sendMessage() async {
//     print('SendMessage called. isConversationReady: $_isConversationReady, text: ${_messageController.text}');
//     if (!_isConversationReady || _conversationId == null) {
//       print('Conversation not ready');
//       return;
//     }
//     if (_messageController.text.trim().isEmpty) {
//       print('Message is empty');
//       return;
//     }
//
//     final messageText = _messageController.text.trim();
//
//     setState(() {
//       _messages.add(Message(
//         text: messageText,
//         timestamp: DateTime.now(),
//         sender: MessageSender.user,
//         senderImageUrl: AppAssets.jennyProfile,
//         status: MessageStatus.sent,
//       ));
//       _messageController.clear();
//       _lastMessageTime = DateTime.now();
//     });
//     _saveMessagesToLocal();
//     _scrollToBottom();
//
//     try {
//       if (_chatSocketService.isConnected) {
//         await _chatApiService.sendMessage(
//             _conversationId!,
//             messageText,
//             widget.chatPartnerId ?? ''
//         );
//       } else {
//         await _chatApiService.sendMessage(_conversationId!, messageText, widget.chatPartnerId);
//         _reloadRecentMessages();
//       }
//     } catch (e) {
//       print('Error sending message: $e');
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Failed to send message: $e')),
//         );
//       }
//     }
//   }
//
//   void _reloadRecentMessages() async {
//     if (_conversationId == null) return;
//     try {
//       final history = await _chatApiService.fetchChatHistory(_conversationId!);
//       final newMessages = <Message>[];
//
//       for (var messageModel in history) {
//         final message = Message(
//           text: messageModel.content,
//           timestamp: messageModel.timestamp,
//           sender: messageModel.senderId == widget.currentUserId ? MessageSender.user : MessageSender.other,
//           senderImageUrl: messageModel.senderId == widget.currentUserId ? AppAssets.jennyProfile : AppAssets.sarahMartinez,
//           status: messageModel.isRead ? MessageStatus.seen : MessageStatus.delivered,
//         );
//
//         bool messageExists = _messages.any((existingMsg) =>
//         existingMsg.text == message.text &&
//             existingMsg.timestamp.difference(message.timestamp).abs().inSeconds < 2 &&
//             existingMsg.sender == message.sender);
//
//         if (!messageExists) {
//           newMessages.add(message);
//         }
//       }
//
//       final prefs = await SharedPreferences.getInstance();
//       final pendingMessages = prefs.getStringList('pending_messages_${_conversationId!}') ?? [];
//       for (var jsonStr in pendingMessages) {
//         final data = jsonDecode(jsonStr);
//         await _chatApiService.sendMessage(_conversationId!, data['content'], data['receiver_id']);
//       }
//       await prefs.setStringList('pending_messages_${_conversationId!}', []);
//
//       if (newMessages.isNotEmpty) {
//         setState(() {
//           _messages.addAll(newMessages);
//           _messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
//           _lastMessageTime = _messages.isNotEmpty ? _messages.last.timestamp : null;
//         });
//         _saveMessagesToLocal();
//         _scrollToBottom();
//       }
//     } catch (e) {
//       print("Failed to reload recent messages: $e");
//     }
//   }
//
//   Future<String> _getOrCreateConversationId() async {
//     final prefs = await SharedPreferences.getInstance();
//     final token = prefs.getString('accessToken');
//     final url = Uri.parse('http://72.60.26.57/api/chat/conversations/create/');
//     final response = await http.post(
//       url,
//       headers: {
//         'Accept': 'application/json',
//         'Authorization': 'Bearer $token',
//         'Content-Type': 'application/json',
//       },
//       body: jsonEncode({
//         'user_id': widget.currentUserId,
//         'partner_id': widget.chatPartnerId,
//       }),
//     );
//     if (response.statusCode == 200) {
//       final data = jsonDecode(response.body);
//       return data['conversation']['id'];
//     } else {
//       throw Exception('Failed to create conversation');
//     }
//   }
//
//   void _scrollToBottom() {
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       if (_scrollController.hasClients) {
//         _scrollController.animateTo(
//           _scrollController.position.maxScrollExtent,
//           duration: const Duration(milliseconds: 300),
//           curve: Curves.easeOut,
//         );
//       }
//     });
//   }
//
//   @override
//   void dispose() {
//     WidgetsBinding.instance.removeObserver(this);
//     _messageController.dispose();
//     _chatSocketService.dispose();
//     _scrollController.dispose();
//     _saveMessagesToLocal();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: AppColors.primaryBlue,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back, color: Colors.white),
//           onPressed: () => Navigator.pop(context),
//         ),
//         title: Text(
//           widget.chatPartnerName,
//           style: const TextStyle(color: Colors.white, fontSize: 20.0, fontWeight: FontWeight.w500),
//         ),
//         centerTitle: true,
//         actions: [
//           Padding(
//             padding: const EdgeInsets.only(right: 16.0),
//             child: Center(
//               child: Container(
//                 width: 8,
//                 height: 8,
//                 decoration: BoxDecoration(
//                   shape: BoxShape.circle,
//                   color: _chatSocketService.isConnected ? Colors.green : Colors.red,
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//       body: Column(
//         children: [
//           Expanded(
//             child: _isLoading
//                 ? const Center(child: CircularProgressIndicator())
//                 : _messages.isEmpty
//                 ? const Center(
//               child: Text(
//                 'No messages yet. Start the conversation!',
//                 style: TextStyle(color: Colors.grey, fontSize: 16),
//               ),
//             )
//                 : ListView.builder(
//               controller: _scrollController,
//               padding: const EdgeInsets.all(16.0),
//               itemCount: _messages.length,
//               itemBuilder: (context, index) => _buildMessageBubble(_messages[index]),
//             ),
//           ),
//           _buildMessageInput(),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildMessageBubble(Message message) {
//     final bool isUser = message.sender == MessageSender.user;
//
//     return Align(
//       alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
//       child: Padding(
//         padding: const EdgeInsets.symmetric(vertical: 4.0),
//         child: Column(
//           crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
//           children: [
//             Row(
//               mainAxisSize: MainAxisSize.min,
//               crossAxisAlignment: CrossAxisAlignment.end,
//               children: [
//                 if (!isUser)
//                   CircleAvatar(radius: 16, backgroundImage: AssetImage(message.senderImageUrl!)),
//                 const SizedBox(width: 8.0),
//                 Flexible(
//                   child: Container(
//                     padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
//                     decoration: BoxDecoration(
//                       color: isUser ? AppColors.receiverBubbleColor : AppColors.senderBubbleColor,
//                       borderRadius: BorderRadius.circular(12.0),
//                     ),
//                     child: Text(
//                       message.text,
//                       style: const TextStyle(fontSize: 14.0, fontFamily: 'Poppins'),
//                     ),
//                   ),
//                 ),
//                 if (isUser) const SizedBox(width: 8.0),
//                 if (isUser)
//                   CircleAvatar(radius: 16, backgroundImage: AssetImage(message.senderImageUrl!)),
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
//
//   Widget _buildMessageInput() {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
//       color: Colors.white,
//       child: Row(
//         children: [
//           Expanded(
//             child: TextField(
//               controller: _messageController,
//               enabled: _isConversationReady,
//               decoration: InputDecoration(
//                 hintText: 'Type a message',
//                 filled: true,
//                 fillColor: AppColors.chatInputFillColor,
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(25.0),
//                   borderSide: BorderSide.none,
//                 ),
//               ),
//               onSubmitted: (_) => _isConversationReady ? _sendMessage() : null,
//             ),
//           ),
//           const SizedBox(width: 8.0),
//           GestureDetector(
//             onTap: _isConversationReady ? _sendMessage : null,
//             child: Icon(
//               Icons.send,
//               color: _isConversationReady ? AppColors.primaryBlue : AppColors.buttonPrimary,
//             ),
//           )
//         ],
//       ),
//     );
//   }
// }