import '../../../data/models/group_model.dart';

enum ChatMessageStatus { sent, delivered, seen }

class Chat {
  final String conversationId;
  final String name;
  final String lastMessage;
  final String time;
  final String imageUrl;
  final int unreadCount;
  final bool isOnline;
  final ChatMessageStatus status;
  final bool isGroupChat;
  final bool? isCurrentUserAdminInGroup;
  final List<dynamic> participants;
  final String currentUserId;
  final GroupChat? groupChat;

  const Chat({
    required this.conversationId,
    required this.name,
    required this.lastMessage,
    required this.time,
    required this.imageUrl,
    this.unreadCount = 0,
    this.isOnline = false,
    this.status = ChatMessageStatus.sent,
    this.isGroupChat = false,
    this.isCurrentUserAdminInGroup,
    this.participants = const [],
    this.currentUserId = '',
    this.groupChat,
  });

  factory Chat.fromJson(
    Map<String, dynamic> json, {
    required String currentUserId,
  }) {
    print("🔍 Raw Chat JSON: $json");

    final lastMsg = json['last_message'];
    final participants = json['participants'] as List<dynamic>? ?? [];

    // Pick the "other" participant for 1-to-1 chat
    final otherParticipant = participants.firstWhere(
      (p) => p['id'].toString() != currentUserId.toString(),
      orElse: () => null,
    );

    // Decide image source
    String imageUrl;
    if (json['is_group'] == true) {
      imageUrl = json['display_photo'] ?? "";
      // imageUrl = json['display_photo'] ?? "assets/images/default_group.png";
    } else {
      imageUrl =
          otherParticipant != null &&
              otherParticipant['profile_photo_url'] != null
          ? otherParticipant['profile_photo_url']
          : "";
      // : 'assets/images/default_user.png';
    }

    print("📌 Chosen imageUrl: $imageUrl");

    // For single chats, use the other participant's name; for group chats, use display_name
    String chatName;
    if (json['is_group'] == true) {
      chatName = json['display_name'] ?? json['name'] ?? 'Unknown Group';
    } else {
      chatName =
          otherParticipant?['full_name'] ??
          json['display_name'] ??
          json['name'] ??
          'Unknown';
    }

    return Chat(
      conversationId: json['conversationId'] ?? json['id'] ?? 'Unknown',
      name: chatName,
      lastMessage: lastMsg != null ? lastMsg['content'] ?? '' : '',
      time: lastMsg != null ? lastMsg['timestamp'] ?? '' : '',
      imageUrl: imageUrl,
      unreadCount: json['unread_count'] ?? 0,
      isOnline: otherParticipant != null
          ? otherParticipant['is_online'] ?? false
          : false,
      status: () {
        final msg = json['last_message'];
        final statusStr = msg != null ? msg['status'] as String? : null;

        switch (statusStr) {
          case 'sent':
            return ChatMessageStatus.sent;
          case 'delivered':
            return ChatMessageStatus.delivered;
          case 'seen':
            return ChatMessageStatus.seen;
          default:
            return ChatMessageStatus.sent;
        }
      }(),

      isGroupChat: json['is_group'] ?? false,
      isCurrentUserAdminInGroup: json['user_role'] == 'Admin',
      participants: participants,
      currentUserId: currentUserId,
    );
  }
}
