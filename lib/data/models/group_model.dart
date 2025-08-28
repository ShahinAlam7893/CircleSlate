import 'package:circleslate/core/constants/app_assets.dart';

enum ChatMessageStatus { sending, sent, delivered, seen, failed }

class GroupParticipant {
  final String id;
  final String email;
  final String fullName;
  final String? profilePhotoUrl;
  final bool isOnline;
  final String role;
  final String roleCode;
  final bool canRemove;
  final bool isCurrentUser;

  GroupParticipant({
    required this.id,
    required this.email,
    required this.fullName,
    this.profilePhotoUrl,
    required this.isOnline,
    required this.role,
    required this.roleCode,
    required this.canRemove,
    required this.isCurrentUser,
  });

  factory GroupParticipant.fromJson(Map<String, dynamic> json) {
    return GroupParticipant(
      id: json['id'].toString(),
      email: json['email'] ?? '',
      fullName: json['full_name'] ?? '',
      profilePhotoUrl: json['profile_photo_url'],
      isOnline: json['is_online'] ?? false,
      role: json['role'] ?? 'Member',
      roleCode: json['role_code'] ?? 'member',
      canRemove: json['can_be_removed'] ?? false,
      isCurrentUser: json['is_current_user'] ?? false,
    );
  }
}

class Message {
  final String id;
  final String senderId;
  final String content;
  final String timestamp;
  final String messageType;

  Message({
    required this.id,
    required this.senderId,
    required this.content,
    required this.timestamp,
    required this.messageType,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    String senderId;
    if (json.containsKey('sender') && json['sender'] != null && json['sender']['id'] != null) {
      senderId = json['sender']['id'].toString();
    } else if (json.containsKey('sender_id') && json['sender_id'] != null) {
      senderId = json['sender_id'].toString();
    } else if (json.containsKey('user_id') && json['user_id'] != null) {
      senderId = json['user_id'].toString();
    } else {
      senderId = 'unknown';
    }

    return Message(
      id: json['id'].toString(),
      senderId: senderId,
      content: json['content'],
      timestamp: json['timestamp'],
      messageType: json['message_type'] ?? 'text',
    );
  }
}

class GroupChat {
  final String id;
  final String? name;
  final bool isGroup;
  final List<GroupParticipant> GroupParticipants;
  final String? lastMessage;
  final String? lastMessageTime;
  final int unreadCount;
  final String? displayName;
  final String? displayPhoto;
  final int GroupParticipantCount;
  final String? userRole;
  final ChatMessageStatus status;
  final String currentUserId;

  final bool isCurrentUserAdminInGroup;

  GroupChat({
    required this.currentUserId,
    required this.id,
    this.name,
    required this.isGroup,
    required this.GroupParticipants,
    this.lastMessage,
    this.lastMessageTime,
    this.unreadCount = 0,
    this.displayName,
    this.displayPhoto,
    required this.GroupParticipantCount,
    this.userRole,
    this.status = ChatMessageStatus.seen,
    required this.isCurrentUserAdminInGroup,
  });

  factory GroupChat.fromJson(Map<String, dynamic> json, {required String currentUserId}) {
    final lastMessage = json['last_message'] != null
        ? Message.fromJson(json['last_message'])
        : null;

    return GroupChat(
      currentUserId: currentUserId,
      id: json['id'].toString(),
      name: json['name'],
      isGroup: json['is_group'] ?? false,
      GroupParticipants: (json['GroupParticipants'] as List<dynamic>?)
          ?.map((p) => GroupParticipant.fromJson(p))
          .toList() ?? [],
      lastMessage: lastMessage?.content,
      lastMessageTime: lastMessage?.timestamp,
      unreadCount: json['unread_count'] ?? 0,
      displayName: json['display_name'],
      displayPhoto: json['display_photo'] ?? AppAssets.groupChatIcon,
      GroupParticipantCount: json['GroupParticipant_count'] ?? 0,
      userRole: json['user_role'],
      status: ChatMessageStatus.seen, isCurrentUserAdminInGroup: true,
    );
  }
}

class GroupInfo {
  final String id;
  final String name;
  final int memberCount;
  final DateTime createdAt;
  final GroupParticipant createdBy;

  GroupInfo({
    required this.id,
    required this.name,
    required this.memberCount,
    required this.createdAt,
    required this.createdBy,
  });

  factory GroupInfo.fromJson(Map<String, dynamic> json) {
    return GroupInfo(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      memberCount: json['member_count'] ?? 0,
      createdAt: DateTime.parse(json['created_at']),
      createdBy: GroupParticipant.fromJson(json['created_by']),
    );
  }
}

class UserPermissions {
  final bool canAddMembers;
  final bool canRemoveMembers;
  final bool canChangeName;
  final bool canPromoteMembers;
  final bool isAdmin;
  final bool canLeave;

  UserPermissions({
    required this.canAddMembers,
    required this.canRemoveMembers,
    required this.canChangeName,
    required this.canPromoteMembers,
    required this.isAdmin,
    required this.canLeave,
  });

  factory UserPermissions.fromJson(Map<String, dynamic> json) {
    return UserPermissions(
      canAddMembers: json['can_add_members'] ?? false,
      canRemoveMembers: json['can_remove_members'] ?? false,
      canChangeName: json['can_change_name'] ?? false,
      canPromoteMembers: json['can_promote_members'] ?? false,
      isAdmin: json['is_admin'] ?? false,
      canLeave: json['can_leave'] ?? false,
    );
  }
}

class GroupMembersResponse {
  final GroupInfo groupInfo;
  final List<GroupParticipant> members;
  final UserPermissions userPermissions;

  GroupMembersResponse({
    required this.groupInfo,
    required this.members,
    required this.userPermissions,
  });

  factory GroupMembersResponse.fromJson(Map<String, dynamic> json) {
    return GroupMembersResponse(
      groupInfo: GroupInfo.fromJson(json['group_info']),
      members: (json['members'] as List<dynamic>)
          .map((memberJson) => GroupParticipant.fromJson(memberJson))
          .toList(),
      userPermissions: UserPermissions.fromJson(json['user_permissions']),
    );
  }
}


enum MemberRole { admin, member }

class GroupMember {
  final String id;
  final String name;
  final String email;
  final String children;
  final String? imageUrl;
  final MemberRole role;

  GroupMember({
    required this.id,
    required this.name,
    required this.email,
    required this.children,
    this.imageUrl,
    required this.role,
  });

  factory GroupMember.fromJson(Map<String, dynamic> json) {
    bool isAdmin = false;
    if (json.containsKey('is_admin')) {
      isAdmin = json['is_admin'] == true;
    } else if (json.containsKey('is_staff')) {
      isAdmin = json['is_staff'] == true;
    } else if (json.containsKey('role')) {
      isAdmin = (json['role']?.toString().toLowerCase() == 'admin');
    }

    String? imageUrl;
    if (json['avatar'] != null && json['avatar'].toString().isNotEmpty) {
      imageUrl = json['avatar'];
    } else if (json['image_url'] != null && json['image_url'].toString().isNotEmpty) {
      imageUrl = json['image_url'];
    } else if (json['profile_image'] != null && json['profile_image'].toString().isNotEmpty) {
      imageUrl = json['profile_image'];
    } else if (json['profile_photo_url'] != null && json['profile_photo_url'].toString().isNotEmpty) {
      imageUrl = json['profile_photo_url'];
    }

    return GroupMember(
      id: (json['id'] ?? json['user_id'] ?? '').toString(),
      name: (json['name'] ?? json['full_name'] ?? json['username'] ?? 'Unknown').toString(),
      email: (json['email'] ?? '').toString(),
      children: (json['children'] ?? '').toString(),
      imageUrl: imageUrl,
      role: isAdmin ? MemberRole.admin : MemberRole.member,
    );
  }
}
