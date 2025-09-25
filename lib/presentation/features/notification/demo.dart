// import 'package:flutter/material.dart';
// import 'package:go_router/go_router.dart';
//
// import '../../../core/constants/app_colors.dart';
// import '../../../core/services/notification_service.dart';
// import '../../../data/datasources/shared_pref/local/token_manager.dart';
// import '../../routes/app_router.dart';
//
// class NotificationPage extends StatefulWidget {
//   const NotificationPage({super.key});
//
//   @override
//   State<NotificationPage> createState() => _NotificationPageState();
// }
//
// class _NotificationPageState extends State<NotificationPage> {
//   final NotificationService _notificationService = NotificationService();
//   final TokenManager _tokenManager = TokenManager();
//
//   bool _loading = true;
//   String? _error;
//   List<AppNotification> _notifications = [];
//
//   @override
//   void initState() {
//     super.initState();
//     _debugTokenStorage();
//     _loadNotifications();
//   }
//
//   Future<void> _debugTokenStorage() async {
//     debugPrint("🛠 [NotificationPage] Debugging token storage...");
//     final token = await _tokenManager.getTokens();
//     if (token == null) {
//       debugPrint("❌ [NotificationPage] TokenEntity is NULL in SharedPreferences.");
//     } else {
//       debugPrint("✅ [NotificationPage] TokenEntity found: $token");
//     }
//   }
//
//   Future<void> _loadNotifications() async {
//     debugPrint("🔍 [NotificationPage] Fetching notifications...");
//     try {
//       final notifications = await _notificationService.fetchNotifications(limit: 5101);
//       debugPrint("📦 [NotificationPage] Notifications fetched: ${notifications.length}");
//
//       setState(() {
//         _notifications = notifications;
//         _loading = false;
//       });
//     } catch (e, st) {
//       debugPrint("⚠️ [NotificationPage] Error while fetching: $e");
//       debugPrint("Stacktrace: $st");
//       setState(() {
//         _error = e.toString();
//         _loading = false;
//       });
//     }
//   }
//
//   /// -------------------------------
//   /// 🔹 Separate Handlers
//   /// -------------------------------
//   void _handleEventNotification(AppNotification notification) {
//     context.push(
//       '${RoutePaths.eventDetails}/${notification.eventId}',
//       extra: {
//         'eventId': notification.eventId,
//         'eventTitle': notification.title,
//         'eventDescription': notification.body,
//         'eventTimestamp': notification.timestamp.toLocal().toString(),
//       },
//     );
//   }
//
//   void _handleGroupNotification(AppNotification notification) {
//     context.push(
//       '/group_conversation',
//       extra: {
//         'conversationId': notification.conversationId,
//         'groupName': notification.conversationName ?? notification.title,
//         'currentUserId': 'currentUserId', // replace with actual
//         'isGroupChat': true,
//       },
//     );
//   }
//
//   void _handleOneToOneNotification(AppNotification notification) {
//     context.push(
//       '/one-to-one-conversation',
//       extra: {
//         'conversationId': notification.conversationId,
//         'chatPartnerId': notification.chatPartnerId ?? '',
//         'chatPartnerName': notification.chatPartnerName ?? notification.title,
//         'currentUserId': 'currentUserId', // replace with actual
//         'isGroupChat': false,
//       },
//     );
//   }
//
//   void _handleNotificationTap(AppNotification notification) async {
//     debugPrint("👆 [NotificationPage] Tapped → id=${notification.id}, type:"
//         " eventId=${notification.eventId}, group=${notification.isGroupChat}, convoId=${notification.conversationId}");
//
//     if (!notification.isRead) {
//       await _notificationService.markAsRead(notification.id);
//       setState(() => notification.isRead = true);
//     }
//
//     if (notification.eventId != null) {
//       _handleEventNotification(notification);
//     } else if (notification.conversationId != null) {
//       if (notification.isGroupChat) {
//         _handleGroupNotification(notification);
//       } else {
//         _handleOneToOneNotification(notification);
//       }
//     }
//   }
//
//   /// -------------------------------
//   /// 🔹 UI Helpers
//   /// -------------------------------
//   Widget _buildSectionHeader(String title) => Padding(
//     padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//     child: Text(
//       title,
//       style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
//     ),
//   );
//
//   Widget _buildNotificationTile(AppNotification notification) {
//     return GestureDetector(
//       onTap: () => _handleNotificationTap(notification),
//       child: Container(
//         margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//         padding: const EdgeInsets.all(12),
//         decoration: BoxDecoration(
//           color: notification.isRead ? Colors.grey.shade200 : Colors.blue.shade50,
//           border: Border(
//             left: BorderSide(
//               color: notification.isRead ? Colors.grey : Colors.blue,
//               width: 4,
//             ),
//           ),
//           borderRadius: BorderRadius.circular(8),
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               notification.title,
//               style: TextStyle(
//                 fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
//                 fontSize: 16,
//               ),
//             ),
//             const SizedBox(height: 4),
//             Text(
//               notification.body,
//               style: TextStyle(color: Colors.grey.shade800, fontSize: 14),
//             ),
//             const SizedBox(height: 4),
//             Text(
//               "${notification.timestamp.toLocal()}".split('.')[0],
//               style: const TextStyle(fontSize: 12, color: Colors.grey),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     // Separate notifications by type
//     final eventNotifications = _notifications.where((n) => n.eventId != null).toList();
//     final groupNotifications = _notifications.where((n) => n.isGroupChat && n.conversationId != null).toList();
//     final oneToOneNotifications = _notifications.where((n) => !n.isGroupChat && n.conversationId != null).toList();
//
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Notifications"),
//         foregroundColor: Colors.white,
//         backgroundColor: AppColors.buttonPrimary,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back),
//           onPressed: () => context.pushReplacement('/home'),
//         ),
//       ),
//       body: _loading
//           ? const Center(child: CircularProgressIndicator())
//           : _error != null
//           ? Center(child: Text("Error: $_error"))
//           : ListView(
//         children: [
//           if (eventNotifications.isNotEmpty) ...[
//             _buildSectionHeader("Event Notifications"),
//             ...eventNotifications.map(_buildNotificationTile),
//           ],
//           if (groupNotifications.isNotEmpty) ...[
//             _buildSectionHeader("Group Notifications"),
//             ...groupNotifications.map(_buildNotificationTile),
//           ],
//           if (oneToOneNotifications.isNotEmpty) ...[
//             _buildSectionHeader("One-to-One Notifications"),
//             ...oneToOneNotifications.map(_buildNotificationTile),
//           ],
//         ],
//       ),
//     );
//   }
// }
//
//
//
// import 'package:flutter/material.dart';
// import 'package:go_router/go_router.dart';
//
// import '../../../core/constants/app_colors.dart';
// import '../../../core/services/notification_service.dart';
// import '../../../data/datasources/shared_pref/local/token_manager.dart';
// import '../../routes/app_router.dart';
//
// class NotificationPage extends StatefulWidget {
//   const NotificationPage({super.key});
//
//   @override
//   State<NotificationPage> createState() => _NotificationPageState();
// }
//
// class _NotificationPageState extends State<NotificationPage> {
//   final NotificationService _notificationService = NotificationService();
//   final TokenManager _tokenManager = TokenManager();
//
//   bool _loading = true;
//   String? _error;
//   List<AppNotification> _notifications = [];
//
//   @override
//   void initState() {
//     super.initState();
//     _debugTokenStorage();
//     _loadNotifications();
//   }
//
//   Future<void> _debugTokenStorage() async {
//     debugPrint("🛠 [NotificationPage] Debugging token storage...");
//     final token = await _tokenManager.getTokens();
//     if (token == null) {
//       debugPrint("❌ [NotificationPage] TokenEntity is NULL in SharedPreferences.");
//     } else {
//       debugPrint("✅ [NotificationPage] TokenEntity found: $token");
//     }
//   }
//
//   Future<void> _loadNotifications() async {
//     debugPrint("🔍 [NotificationPage] Fetching notifications...");
//     try {
//       final notifications = await _notificationService.fetchNotifications(limit: 5101);
//       debugPrint("📦 [NotificationPage] Notifications fetched: ${notifications.length}");
//
//       // for (var n in notifications) {
//       //   debugPrint("   → Notification ID=${n.id}, title=${n.title}, eventId=${n.eventId}");
//       // }
//
//       setState(() {
//         _notifications = notifications;
//         _loading = false;
//       });
//     } catch (e, st) {
//       debugPrint("⚠️ [NotificationPage] Error while fetching: $e");
//       debugPrint("Stacktrace: $st");
//       setState(() {
//         _error = e.toString();
//         _loading = false;
//       });
//     }
//   }
//
//
//   void _handleNotificationTap(AppNotification notification) async {
//     debugPrint("👆 [NotificationPage] Tapped notification → "
//         "id=${notification.id}, title=${notification.title}, eventId=${notification.eventId}, name=${notification.conversationName}, group or not=${notification.isGroupChat}");
//
//     if (!notification.isRead) {
//       await _notificationService.markAsRead(notification.id);
//       setState(() {
//         notification.isRead = true;
//       });
//     }
//
//     if (notification.eventId != null) {
//       context.push(
//         '${RoutePaths.eventDetails}/${notification.eventId}',
//         extra: {
//           'eventId': notification.eventId,
//           'eventTitle': notification.title,
//           'eventDescription': notification.body,
//           'eventTimestamp': notification.timestamp.toLocal().toString(),
//         },
//       );
//       // context.push(
//       //   '${RoutePaths.eventDetails}/:id',
//       //   extra: {
//       //     'eventId': notification.eventId,
//       //   },
//       // );
//
//     }
//
//     else if (notification.conversationId != null) {
//       if (!notification.isGroupChat) {
//         context.push(
//           '/group_conversation',
//           extra: {
//             'conversationId': notification.conversationId,
//             'groupName': notification.conversationName ?? notification.title,
//             'currentUserId': 'currentUserId',
//             'isGroupChat': true,
//           },
//         );
//       } else {
//         context.push(
//           '/one-to-one-conversation',
//           extra: {
//             'conversationId': notification.conversationId,
//             'chatPartnerId': notification.chatPartnerId ?? '',
//             'chatPartnerName': notification.chatPartnerName ?? notification.title,
//             'currentUserId': 'currentUserId',
//             'isGroupChat': false,
//           },
//         );
//       }
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Notifications"),
//         foregroundColor: Colors.white,
//         backgroundColor: AppColors.buttonPrimary,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back),
//           onPressed: () => context.pushReplacement('/home'),
//         ),
//       ),
//       body: _loading
//           ? const Center(child: CircularProgressIndicator())
//           : _error != null
//           ? Center(child: Text("Error: $_error"))
//           : ListView.builder(
//         itemCount: _notifications.length,
//         itemBuilder: (context, index) {
//           final notification = _notifications[index];
//           return GestureDetector(
//             onTap: () => _handleNotificationTap(notification),
//             child: Container(
//               margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//               padding: const EdgeInsets.all(12),
//               decoration: BoxDecoration(
//                 color: notification.isRead
//                     ? Colors.grey.shade200
//                     : Colors.blue.shade50,
//                 border: Border(
//                   left: BorderSide(
//                     color: notification.isRead ? Colors.grey : Colors.blue,
//                     width: 4,
//                   ),
//                 ),
//                 borderRadius: BorderRadius.circular(8),
//               ),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     notification.title,
//                     style: TextStyle(
//                       fontWeight: notification.isRead
//                           ? FontWeight.normal
//                           : FontWeight.bold,
//                       fontSize: 16,
//                     ),
//                   ),
//                   const SizedBox(height: 4),
//                   Text(
//                     notification.body,
//                     style: TextStyle(
//                       color: Colors.grey.shade800,
//                       fontSize: 14,
//                     ),
//                   ),
//                   const SizedBox(height: 4),
//                   Text(
//                     "${notification.timestamp.toLocal()}".split('.')[0],
//                     style: const TextStyle(
//                       fontSize: 12,
//                       color: Colors.grey,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           );
//         },
//       ),
//     );
//   }
// }