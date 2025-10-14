// import 'dart:convert';
// import 'package:circleslate/core/constants/app_colors.dart';
// import 'package:circleslate/core/utils/user_image_helper.dart';
// import 'package:circleslate/presentation/routes/app_router.dart';
// import 'package:flutter/material.dart';
// import 'package:go_router/go_router.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:web_socket_channel/io.dart';
// import 'package:web_socket_channel/web_socket_channel.dart';
//
// class ChatScreen extends StatefulWidget {
//   final String chatPartnerName;
//   final String currentUserId;
//   final String chatPartnerId;
//   final String? conversationId;
//   final bool isadmin;
//   final bool isGroup;
//
//   const ChatScreen({
//     super.key,
//     required this.chatPartnerName,
//     required this.currentUserId,
//     required this.chatPartnerId,
//     required this.conversationId,
//     required this.isadmin,
//     this.isGroup = false,
//   });
//
//   @override
//   _ChatScreenState createState() => _ChatScreenState();
// }
//
// class _ChatScreenState extends State<ChatScreen> {
//   final TextEditingController _controller = TextEditingController();
//   late WebSocketChannel channel;
//   List<Map<String, dynamic>> messages = [];
//   String? _chatPartnerImageUrl;
//
//   @override
//   void initState() {
//     super.initState();
//     debugPrint("📌 ChatScreen initialized with:");
//     debugPrint("chatPartnerName: ${widget.chatPartnerName}");
//     debugPrint("currentUserId: ${widget.currentUserId}");
//     debugPrint("chatPartnerId: ${widget.chatPartnerId}");
//     debugPrint("conversationId: ${widget.conversationId}");
//     debugPrint("isadmin: ${widget.isadmin}");
//     debugPrint("isGroup: ${widget.isGroup}");
//     _connectWebSocket();
//   }
//
//   void _connectWebSocket() async {
//     print("🔹 Connecting to WebSocket...");
//
//     final token = await _getToken(); // await the async function
//     print("🔑 Retrieved token: $token");
//
//     if (token == null) {
//       print("⚠️ No token found. Cannot connect to WebSocket.");
//       return; // handle no token case
//     }
//
//     final id = widget.conversationId;
//     final url = 'https://app.circleslate.com/api/chat/$id/?token=$token';
//     print("🌐 Connecting to URL: $url");
//
//     try {
//       channel = IOWebSocketChannel.connect(url);
//       print("✅ WebSocket connection established.");
//
//       channel.stream.listen(
//         (data) {
//           print("📩 Received raw data: $data");
//           final decoded = json.decode(data);
//           print("🟢 Decoded JSON: $decoded");
//
//           if (decoded['type'] == 'message') {
//             setState(() {
//               messages.add(decoded['message']);
//             });
//             print("💬 Message added: ${decoded['message']}");
//           }
//         },
//         onError: (error) {
//           print("❌ WebSocket error: $error");
//         },
//         onDone: () {
//           print("ℹ️ WebSocket connection closed.");
//         },
//       );
//     } catch (e) {
//       print("⚠️ Exception while connecting WebSocket: $e");
//     }
//   }
//
//   static Future<String?> _getToken() async {
//     final prefs = await SharedPreferences.getInstance();
//     final token = prefs.getString('accessToken');
//     print("🔑 _getToken returned: $token");
//     return token;
//   }
//
//   void sendMessage(String text) {
//     if (text.isEmpty) return;
//     final message = json.encode({'content': text});
//     channel.sink.add(message);
//     _controller.clear();
//   }
//
//   Future<void> _loadChatPartnerImage() async {
//     try {
//       final imageUrl = await UserImageHelper.getUserImageUrl(
//         widget.chatPartnerId,
//       );
//       setState(() {
//         _chatPartnerImageUrl = imageUrl;
//       });
//       debugPrint(
//         '[OneToOneConversationPage] Chat partner image loaded: $imageUrl',
//       );
//     } catch (e) {
//       debugPrint(
//         '[OneToOneConversationPage] Error loading chat partner image: $e',
//       );
//     }
//   }
//
//   @override
//   void dispose() {
//     channel.sink.close();
//     _controller.dispose();
//     super.dispose();
//   }
//
//   Widget buildMessage(Map<String, dynamic> message) {
//     bool isMe = message['sender']['id'] == widget.currentUserId;
//
//     return Align(
//       alignment: isMe ? Alignment.centerLeft : Alignment.centerRight,
//       child: Container(
//         margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
//         padding: const EdgeInsets.all(10),
//         decoration: BoxDecoration(
//           color: isMe ? Colors.blue : Colors.blue[300],
//           borderRadius: BorderRadius.circular(10),
//         ),
//         child: Row(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             if (isMe) SizedBox(width: 5),
//             Flexible(
//               child: message['image_url'] != null
//                   ? Image.network(
//                 'http://72.60.26.57${message['image_url']}',
//                 width: 100,
//                 height: 100,
//                 fit: BoxFit.cover,
//               )
//                   : Text(
//                 message['content'] ?? '',
//                 style: TextStyle(
//                   color: isMe ? Colors.white : Colors.black,
//                   fontSize: 16,
//                 ),
//               ),
//             ),
//             // Receiver avatar
//             if (!isMe)
//               CircleAvatar(
//                 radius: 10,
//                 backgroundImage: NetworkImage(
//                   'http://72.60.26.57${message['sender']['profile_photo_url']}',
//                 ),
//               ),
//             if (!isMe) SizedBox(width: 5),
//             // Sender avatar
//             if (isMe)
//               CircleAvatar(
//                 radius: 15,
//                 backgroundImage: NetworkImage(
//                   'http://72.60.26.57${message['sender']['profile_photo_url']}',
//                 ),
//               ),
//           ],
//         ),
//       ),
//     );
//   }
//
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
//         title: Row(
//           children: [
//             // Chat partner avatar
//             UserImageHelper.buildUserAvatarWithErrorHandling(
//               imageUrl: _chatPartnerImageUrl,
//               radius: 18,
//               backgroundColor: Colors.white,
//               iconColor: Colors.grey[600],
//             ),
//             const SizedBox(width: 12),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     widget.chatPartnerName,
//                     style: const TextStyle(
//                       color: Colors.white,
//                       fontSize: 20.0,
//                       fontWeight: FontWeight.w500,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//
//             // Chat partner name and typing indicator
//           ],
//         ),
//         actions: [
//           if (widget.isadmin == false) // only show if admin
//             Container(
//               margin: const EdgeInsets.only(right: 8.0),
//               child: IconButton(
//                 icon: const Icon(Icons.manage_accounts, color: Colors.white),
//                 tooltip: 'Group Manager',
//                 onPressed: () {
//                   debugPrint("PRINT groupId: ${widget.conversationId}");
//                   debugPrint("PRINT conversationId: ${widget.conversationId}");
//                   context.push(
//                     RoutePaths.groupManagement,
//                     extra: {
//                       'groupId': widget.conversationId,
//                       'conversationId': widget.conversationId,
//                       'currentUserId': widget.currentUserId,
//                       'isCurrentUserAdmin': true,
//                     },
//                   );
//                 },
//               ),
//             ),
//         ],
//       ),
//
//       body: Column(
//         children: [
//           Expanded(
//             child: ListView.builder(
//               reverse: false,
//               itemCount: messages.length,
//               itemBuilder: (context, index) {
//                 return buildMessage(messages[index]);
//               },
//             ),
//           ),
//           Padding(
//             padding: const EdgeInsets.all(8.0),
//             child: Row(
//               children: [
//                 Expanded(
//                   child: TextField(
//                     controller: _controller,
//                     decoration: InputDecoration(
//                       hintText: 'Type a message...',
//                       border: OutlineInputBorder(
//                         borderSide: BorderSide(color: AppColors.primaryBlue),
//                         borderRadius: BorderRadius.circular(20),
//                       ),
//                     ),
//                   ),
//                 ),
//                 IconButton(
//                   icon: Icon(Icons.send),
//                   color: AppColors.primaryBlue,
//                   onPressed: () => sendMessage(_controller.text),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
