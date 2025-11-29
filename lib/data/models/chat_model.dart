// import 'package:intl/intl.dart';
// import 'package:json_annotation/json_annotation.dart';
// import 'package:circleslate/core/constants/app_assets.dart';

// part 'chat_model.g.dart';

// enum ChatMessageStatus { sending, sent, delivered, seen, failed }

// @JsonSerializable()
// class Participant {
//   final String id;
//   @JsonKey(name: 'full_name')
//   final String fullName;
//   final String email;
//   final String? profilePhotoUrl;
//   final bool isOnline;
//   final String role;
//   final String roleCode;
//   final bool canRemove;
//   final bool isCurrentUser;

//   Participant({
//     required this.id,
//     required this.fullName,
//     required this.email,
//     this.profilePhotoUrl,
//     required this.isOnline,
//     required this.role,
//     required this.roleCode,
//     required this.canRemove,
//     required this.isCurrentUser,
//   });

//   factory Participant.fromJson(Map<String, dynamic> json) => _$ParticipantFromJson(json);
//   Map<String, dynamic> toJson() => _$ParticipantToJson(this);
// }

// @JsonSerializable()
// class Conversation {
//   final String id;
//   final String name;
//   @JsonKey(name: 'is_group')
//   final bool isGroup;
//   @JsonKey(name: 'display_name')
//   final String displayName;
//   @JsonKey(name: 'unread_count')
//   final int unreadCount;
//   @JsonKey(name: 'created_at')
//   final DateTime createdAt;
//   @JsonKey(name: 'updated_at')
//   final DateTime updatedAt;

//   final List<Participant> participants;

//   Conversation({
//     required this.id,
//     required this.name,
//     required this.isGroup,
//     required this.displayName,
//     required this.unreadCount,
//     required this.createdAt,
//     required this.updatedAt,
//     required this.participants,
//   });

//   factory Conversation.fromJson(Map<String, dynamic> json) => _$ConversationFromJson(json);
//   Map<String, dynamic> toJson() => _$ConversationToJson(this);
// }

// @JsonSerializable()
// class ConversationListResponse {
//   final List<Conversation> conversations;
//   final int count;

//   ConversationListResponse({
//     required this.conversations,
//     required this.count,
//   });

//   factory ConversationListResponse.fromJson(Map<String, dynamic> json) => _$ConversationListResponseFromJson(json);
//   Map<String, dynamic> toJson() => _$ConversationListResponseToJson(this);
// }

// @JsonSerializable()
// class Message {
//   final String id;
//   final String content;
//   final String senderId;
//   final String senderName;
//   final String senderEmail;
//   final DateTime timestamp;
//   final bool isRead;
//   final bool isOwnMessage;
//   final MessageSender sender;

//   Message({
//     required this.id,
//     required this.content,
//     required this.senderId,
//     required this.senderName,
//     required this.senderEmail,
//     required this.timestamp,
//     required this.isRead,
//     required this.isOwnMessage,
//     required this.sender,
//   });

//   factory Message.fromJson(Map<String, dynamic> json) {
//     return Message(
//       id: json['id'].toString(),
//       content: json['content'],
//       senderId: json['sender_id']?.toString() ?? json['sender']['id'].toString(),
//       senderName: json['sender']?['full_name'] ?? '',
//       senderEmail: json['sender']?['email'] ?? '',
//       timestamp: DateTime.parse(json['timestamp']),
//       isRead: json['is_read'] ?? false,
//       isOwnMessage: json['is_own_message'] ?? false,
//       sender: json['is_own_message'] == true ? MessageSender.user : MessageSender.other,
//     );
//   }

//   Map<String, dynamic> toJson() => _$MessageToJson(this);
// }

// enum MessageSender { user, other }

// class StoredMessage {
//   final String id;
//   final String text;
//   final DateTime timestamp;
//   final MessageSender sender;
//   final String senderId;
//   final String? senderImageUrl;
//   final MessageStatus status;
//   final String? clientMessageId;

//   StoredMessage({
//     required this.id,
//     required this.text,
//     required this.timestamp,
//     required this.sender,
//     required this.senderId,
//     this.senderImageUrl,
//     this.status = MessageStatus.sent,
//     this.clientMessageId,
//   });

//   Map<String, dynamic> toJson() {
//     return {
//       'id': id,
//       'text': text,
//       'timestamp': timestamp.toIso8601String(),
//       'sender': sender.name,
//       'senderId': senderId,
//       'senderImageUrl': senderImageUrl,
//       'status': status.name,
//       'clientMessageId': clientMessageId,
//     };
//   }

//   factory StoredMessage.fromJson(Map<String, dynamic> json) {
//     return StoredMessage(
//       id: json['id'] ?? '',
//       text: json['text'] ?? '',
//       timestamp: DateTime.parse(json['timestamp']),
//       sender: MessageSender.values.firstWhere(
//             (e) => e.name == json['sender'],
//         orElse: () => MessageSender.other,
//       ),
//       senderId: json['senderId'] ?? '',
//       senderImageUrl: json['senderImageUrl'],
//       status: MessageStatus.values.firstWhere(
//             (e) => e.name == json['status'],
//         orElse: () => MessageStatus.sent,
//       ),
//       clientMessageId: json['clientMessageId'],
//     );
//   }

//   StoredMessage copyWith({
//     String? id,
//     String? text,
//     DateTime? timestamp,
//     MessageSender? sender,
//     int? senderId,
//     String? senderImageUrl,
//     MessageStatus? status,
//     String? clientMessageId,
//   }) {
//     return StoredMessage(
//       id: id ?? this.id,
//       text: text ?? this.text,
//       timestamp: timestamp ?? this.timestamp,
//       sender: sender ?? this.sender,
//       senderId: senderId?.toString() ?? this.senderId,
//       senderImageUrl: senderImageUrl ?? this.senderImageUrl,
//       status: status ?? this.status,
//       clientMessageId: clientMessageId ?? this.clientMessageId,
//     );
//   }
// }

// enum MessageStatus { sending, sent, delivered, seen, failed }

// class UserSearchResult {
//   final int id;
//   final String fullName;
//   final String email;
//   final String? profilePhotoUrl;
//   final bool isOnline;

//   UserSearchResult({
//     required this.id,
//     required this.fullName,
//     required this.email,
//     this.profilePhotoUrl,
//     required this.isOnline,
//   });
// }

// class Chat {
//   final String conversationId;
//   final String name;
//   final String lastMessage;
//   final String time;
//   final String imageUrl;
//   final int unreadCount;
//   final bool isOnline;
//   final ChatMessageStatus status;
//   final bool isGroupChat;
//   final bool? isCurrentUserAdminInGroup;
//   final List<dynamic> participants;
//   final String currentUserId;
//   final GroupChat? groupChat;

//   const Chat({
//     required this.conversationId,
//     required this.name,
//     required this.lastMessage,
//     required this.time,
//     required this.imageUrl,
//     this.unreadCount = 0,
//     this.isOnline = false,
//     this.status = ChatMessageStatus.seen,
//     this.isGroupChat = false,
//     this.isCurrentUserAdminInGroup,
//     this.participants = const [],
//     this.currentUserId = '',
//     this.groupChat,
//   });

//   factory Chat.fromJson(Map<String, dynamic> json, {required String currentUserId}) {
//     final lastMsg = json['last_message'];
//     final participants = json['participants'] as List<dynamic>? ?? [];
//     final firstParticipant = participants.isNotEmpty ? participants[0] : null;
    
//     // Find the other participant for single chats
//     final otherParticipant = participants.firstWhere(
//       (p) => p['id'].toString() != currentUserId.toString(),
//       orElse: () => null,
//     );
    
//     // For single chats, use the other participant's name; for group chats, use display_name
//     String chatName;
//     if (json['is_group'] == true) {
//       chatName = json['display_name'] ?? json['name'] ?? 'Unknown Group';
//     } else {
//       chatName = otherParticipant?['full_name'] ?? json['display_name'] ?? json['name'] ?? 'Unknown';
//     }
    
//     return Chat(
//       conversationId: json['conversationId'] ?? json['id'] ?? 'Unknown',
//       name: chatName,
//       lastMessage: lastMsg != null ? lastMsg['content'] ?? '' : '',
//       time: lastMsg != null ? lastMsg['timestamp'] ?? '' : '',
//       imageUrl: 'assets/images/default_user.png',
//       unreadCount: json['unread_count'] ?? 0,
//       isOnline: firstParticipant != null ? firstParticipant['is_online'] ?? false : false,
//       status: ChatMessageStatus.seen,
//       isGroupChat: json['is_group'] ?? false,
//       isCurrentUserAdminInGroup: json['user_role'] == 'admin',
//       participants: participants,
//       currentUserId: currentUserId,
//     );
//   }
// }

// class GroupChat {
//   final String id;
//   final String? name;
//   final bool isGroup;
//   final List<Participant> participants;
//   final String? lastMessage;
//   final String? lastMessageTime;
//   final int unreadCount;
//   final String? displayName;
//   final String? displayPhoto;
//   final int participantCount;
//   final String? userRole;
//   final ChatMessageStatus status;
//   final String currentUserId;
//   final bool isCurrentUserAdminInGroup;

//   GroupChat({
//     required this.currentUserId,
//     required this.id,
//     this.name,
//     required this.isGroup,
//     required this.participants,
//     this.lastMessage,
//     this.lastMessageTime,
//     this.unreadCount = 0,
//     this.displayName,
//     this.displayPhoto,
//     required this.participantCount,
//     this.userRole,
//     this.status = ChatMessageStatus.seen,
//     required this.isCurrentUserAdminInGroup,
//   });

//   factory GroupChat.fromJson(Map<String, dynamic> json, {required String currentUserId}) {
//     final lastMessage = json['last_message'] != null ? Message.fromJson(json['last_message']) : null;
//     return GroupChat(
//       currentUserId: currentUserId,
//       id: json['id'].toString(),
//       name: json['name'],
//       isGroup: json['is_group'] ?? false,
//       participants: (json['participants'] as List<dynamic>?)
//           ?.map((p) => Participant.fromJson(p))
//           .toList() ??
//           [],
//       lastMessage: lastMessage?.content,
//       lastMessageTime: lastMessage != null ? DateFormat('yyyy-MM-dd HH:mm:ss').format(lastMessage.timestamp) : null,
//       unreadCount: json['unread_count'] ?? 0,
//       displayName: json['display_name'],
//       displayPhoto: json['display_photo'] ?? AppAssets.groupChatIcon,
//       participantCount: json['participant_count'] ?? 0,
//       userRole: json['user_role'],
//       status: ChatMessageStatus.seen,
//       isCurrentUserAdminInGroup: json['user_role'] == 'admin',
//     );
//   }
// }

// class GroupInfo {
//   final String id;
//   final String name;
//   final int memberCount;
//   final DateTime createdAt;
//   final Participant createdBy;

//   GroupInfo({
//     required this.id,
//     required this.name,
//     required this.memberCount,
//     required this.createdAt,
//     required this.createdBy,
//   });

//   factory GroupInfo.fromJson(Map<String, dynamic> json) {
//     return GroupInfo(
//       id: json['id'].toString(),
//       name: json['name'] ?? '',
//       memberCount: json['member_count'] ?? 0,
//       createdAt: DateTime.parse(json['created_at']),
//       createdBy: Participant.fromJson(json['created_by']),
//     );
//   }
// }

// class UserPermissions {
//   final bool canAddMembers;
//   final bool canRemoveMembers;
//   final bool canChangeName;
//   final bool canPromoteMembers;
//   final bool isAdmin;
//   final bool canLeave;

//   UserPermissions({
//     required this.canAddMembers,
//     required this.canRemoveMembers,
//     required this.canChangeName,
//     required this.canPromoteMembers,
//     required this.isAdmin,
//     required this.canLeave,
//   });

//   factory UserPermissions.fromJson(Map<String, dynamic> json) {
//     return UserPermissions(
//       canAddMembers: json['can_add_members'] ?? false,
//       canRemoveMembers: json['can_remove_members'] ?? false,
//       canChangeName: json['can_change_name'] ?? false,
//       canPromoteMembers: json['can_promote_members'] ?? false,
//       isAdmin: json['is_admin'] ?? false,
//       canLeave: json['can_leave'] ?? false,
//     );
//   }
// }

// class GroupMembersResponse {
//   final GroupInfo groupInfo;
//   final List<Participant> members;
//   final UserPermissions userPermissions;

//   GroupMembersResponse({
//     required this.groupInfo,
//     required this.members,
//     required this.userPermissions,
//   });

//   factory GroupMembersResponse.fromJson(Map<String, dynamic> json) {
//     return GroupMembersResponse(
//       groupInfo: GroupInfo.fromJson(json['group_info']),
//       members: (json['members'] as List<dynamic>).map((memberJson) => Participant.fromJson(memberJson)).toList(),
//       userPermissions: UserPermissions.fromJson(json['user_permissions']),
//     );
//   }
// }

// enum MemberRole { admin, member }

// class GroupMember {
//   final String id;
//   final String name;
//   final String email;
//   final String children;
//   final String? imageUrl;
//   final MemberRole role;

//   GroupMember({
//     required this.id,
//     required this.name,
//     required this.email,
//     required this.children,
//     this.imageUrl,
//     required this.role,
//     required bool isCurrentUserAdmin,
//   });

//   factory GroupMember.fromJson(Map<String, dynamic> json) {
//     bool isAdmin = false;
//     if (json.containsKey('is_admin')) {
//       isAdmin = json['is_admin'] == true;
//     } else if (json.containsKey('is_staff')) {
//       isAdmin = json['is_staff'] == true;
//     } else if (json.containsKey('role')) {
//       isAdmin = (json['role']?.toString().toLowerCase() == 'admin');
//     }

//     String? imageUrl;
//     if (json['avatar'] != null && json['avatar'].toString().isNotEmpty) {
//       imageUrl = json['avatar'];
//     } else if (json['image_url'] != null && json['image_url'].toString().isNotEmpty) {
//       imageUrl = json['image_url'];
//     } else if (json['profile_image'] != null && json['profile_image'].toString().isNotEmpty) {
//       imageUrl = json['profile_image'];
//     } else if (json['profile_photo_url'] != null && json['profile_photo_url'].toString().isNotEmpty) {
//       imageUrl = json['profile_photo_url'];
//     }

//     return GroupMember(
//       id: (json['id'] ?? json['user_id'] ?? '').toString(),
//       name: (json['name'] ?? json['full_name'] ?? json['username'] ?? 'Unknown').toString(),
//       email: (json['email'] ?? '').toString(),
//       children: (json['children'] ?? '').toString(),
//       imageUrl: imageUrl,
//       role: isAdmin ? MemberRole.admin : MemberRole.member,
//       isCurrentUserAdmin: false,
//     );
//   }
// }