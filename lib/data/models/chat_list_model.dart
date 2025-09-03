// class chatlistmodel {
//   List<Conversations>? conversations;
//   int? count;
//
//   chatlistmodel({this.conversations, this.count});
//
//   chatlistmodel.fromJson(Map<String, dynamic> json) {
//     if (json['conversations'] != null) {
//       conversations = <Conversations>[];
//       json['conversations'].forEach((v) {
//         conversations!.add(new Conversations.fromJson(v));
//       });
//     }
//     count = json['count'];
//   }
//
//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = new Map<String, dynamic>();
//     if (this.conversations != null) {
//       data['conversations'] =
//           this.conversations!.map((v) => v.toJson()).toList();
//     }
//     data['count'] = this.count;
//     return data;
//   }
// }
//
// class Conversations {
//   String? id;
//   String? name;
//   bool? isGroup;
//   List<Participants>? participants;
//   String? createdAt;
//   String? updatedAt;
//   LastMessage? lastMessage;
//   int? unreadCount;
//   String? displayName;
//   String? displayPhoto;
//   int? participantCount;
//   String? userRole;
//
//   Conversations(
//       {this.id,
//         this.name,
//         this.isGroup,
//         this.participants,
//         this.createdAt,
//         this.updatedAt,
//         this.lastMessage,
//         this.unreadCount,
//         this.displayName,
//         this.displayPhoto,
//         this.participantCount,
//         this.userRole});
//
//   Conversations.fromJson(Map<String, dynamic> json) {
//     id = json['id'];
//     name = json['name'];
//     isGroup = json['is_group'];
//     if (json['participants'] != null) {
//       participants = <Participants>[];
//       json['participants'].forEach((v) {
//         participants!.add(new Participants.fromJson(v));
//       });
//     }
//     createdAt = json['created_at'];
//     updatedAt = json['updated_at'];
//     lastMessage = json['last_message'] != null
//         ? new LastMessage.fromJson(json['last_message'])
//         : null;
//     unreadCount = json['unread_count'];
//     displayName = json['display_name'];
//     displayPhoto = json['display_photo'];
//     participantCount = json['participant_count'];
//     userRole = json['user_role'];
//   }
//
//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = new Map<String, dynamic>();
//     data['id'] = this.id;
//     data['name'] = this.name;
//     data['is_group'] = this.isGroup;
//     if (this.participants != null) {
//       data['participants'] = this.participants!.map((v) => v.toJson()).toList();
//     }
//     data['created_at'] = this.createdAt;
//     data['updated_at'] = this.updatedAt;
//     if (this.lastMessage != null) {
//       data['last_message'] = this.lastMessage!.toJson();
//     }
//     data['unread_count'] = this.unreadCount;
//     data['display_name'] = this.displayName;
//     data['display_photo'] = this.displayPhoto;
//     data['participant_count'] = this.participantCount;
//     data['user_role'] = this.userRole;
//     return data;
//   }
// }
//
// class Participants {
//   int? id;
//   String? email;
//   String? fullName;
//   String? profilePhotoUrl;
//   bool? isOnline;
//   String? role;
//   bool? canRemove;
//
//   Participants(
//       {this.id,
//         this.email,
//         this.fullName,
//         this.profilePhotoUrl,
//         this.isOnline,
//         this.role,
//         this.canRemove});
//
//   Participants.fromJson(Map<String, dynamic> json) {
//     id = json['id'];
//     email = json['email'];
//     fullName = json['full_name'];
//     profilePhotoUrl = json['profile_photo_url'];
//     isOnline = json['is_online'];
//     role = json['role'];
//     canRemove = json['can_remove'];
//   }
//
//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = new Map<String, dynamic>();
//     data['id'] = this.id;
//     data['email'] = this.email;
//     data['full_name'] = this.fullName;
//     data['profile_photo_url'] = this.profilePhotoUrl;
//     data['is_online'] = this.isOnline;
//     data['role'] = this.role;
//     data['can_remove'] = this.canRemove;
//     return data;
//   }
// }
//
// class LastMessage {
//   String? id;
//   String? sender;
//   String? content;
//   String? timestamp;
//   String? messageType;
//
//   LastMessage(
//       {this.id, this.sender, this.content, this.timestamp, this.messageType});
//
//   LastMessage.fromJson(Map<String, dynamic> json) {
//     id = json['id'];
//     sender = json['sender'];
//     content = json['content'];
//     timestamp = json['timestamp'];
//     messageType = json['message_type'];
//   }
//
//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = new Map<String, dynamic>();
//     data['id'] = this.id;
//     data['sender'] = this.sender;
//     data['content'] = this.content;
//     data['timestamp'] = this.timestamp;
//     data['message_type'] = this.messageType;
//     return data;
//   }
// }
