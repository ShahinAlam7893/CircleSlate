// lib/core/widgets/professional_message_bubble.dart

import 'package:circleslate/core/services/message_storage_service.dart';
import 'package:circleslate/core/services/one_to_one_chat_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/user_image_helper.dart';

class ProfessionalMessageBubble extends StatelessWidget {
  final StoredMessage message;
  final String currentUserId;
  final bool showAvatar;
  final bool showTimestamp;
  final VoidCallback? onRetry;
  final bool isGroupChat;
  final VoidCallback? onLongPress;

  const ProfessionalMessageBubble({
    Key? key,
    required this.message,
    required this.currentUserId,
    this.showAvatar = true,
    this.showTimestamp = true,
    this.onRetry,
    this.isGroupChat = false,
    this.onLongPress,
  }) : super(key: key);

  bool get isCurrentUser => message.senderId == currentUserId;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // onLongPress: isCurrentUser ? () => _showMessageOptions(context) : null,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 6.h, horizontal: 12.w),
        child: Column(
          crossAxisAlignment: isCurrentUser
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            // Group sender name
            if (isGroupChat && !isCurrentUser)
              Padding(
                padding: EdgeInsets.only(left: 52.w, bottom: 4.h),
                child: Text(
                  message.senderName ?? '',
                  style: TextStyle(fontSize: 10.sp, color: Colors.white70),
                ),
              ),

            Row(
              mainAxisAlignment: isCurrentUser
                  ? MainAxisAlignment.end
                  : MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Other user avatar
                if (!isCurrentUser && showAvatar)
                  Padding(
                    padding: EdgeInsets.only(right: 10.w),
                    child: UserImageHelper.buildUserAvatarWithErrorHandling(
                      imageUrl: message.senderImageUrl,
                      radius: 18.r,
                    ),
                  ),

                // Bubble + Time/Status
                Flexible(
                  child: Column(
                    crossAxisAlignment: isCurrentUser
                        ? CrossAxisAlignment.end
                        : CrossAxisAlignment.start,
                    children: [
                      // Message Bubble
                      Container(
                        constraints: BoxConstraints(maxWidth: 0.75.sw),
                        padding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 12.h,
                        ),
                        decoration: BoxDecoration(
                          color: isCurrentUser
                              ? AppColors.primaryBlue
                              : const Color(0xFFE4E6EB),
                          borderRadius: _bubbleBorderRadius(),
                        ),
                        child: Text(
                          message.text,
                          style: TextStyle(
                            fontSize: 12.sp,
                            height: 1.35,
                            color: isCurrentUser
                                ? Colors.white
                                : Colors.black87,
                          ),
                        ),
                      ),

                      // Time + Status + "edited" label
                      Padding(
                        padding: EdgeInsets.only(
                          top: 4.h,
                          left: isCurrentUser ? 0 : 52.w,
                          right: isCurrentUser ? 8.w : 0,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              DateFormat(
                                'h:mm a',
                              ).format(message.timestamp).toLowerCase(),
                              style: TextStyle(
                                fontSize: 11.5.sp,
                                color: Colors.grey[600],
                              ),
                            ),

                            // "edited" label
                            if (message.isEdited) ...[
                              SizedBox(width: 4.w),
                              Text(
                                '· edited',
                                style: TextStyle(
                                  fontSize: 10.sp,
                                  color: Colors.grey[600],
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],

                            SizedBox(width: 6.w),
                            if (isCurrentUser) _buildStatusIcon(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Current user avatar
                if (isCurrentUser && showAvatar)
                  Padding(
                    padding: EdgeInsets.only(left: 10.w),
                    child: UserImageHelper.buildUserAvatarWithErrorHandling(
                      imageUrl: message.senderImageUrl,
                      radius: 18.r,
                    ),
                  ),
              ],
            ),

            // Failed retry
            if (message.status == MessageStatus.failed && isCurrentUser)
              Padding(
                padding: EdgeInsets.only(top: 6.h, right: 12.w),
                child: GestureDetector(
                  onTap: onRetry,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline, size: 14.sp, color: Colors.red),
                      SizedBox(width: 6.w),
                      Text(
                        "Tap to retry",
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showMessageOptions(BuildContext context) {
    final provider = context.read<ConversationProvider>();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Edit Option
            ListTile(
              leading: Icon(Icons.edit_outlined, color: Colors.blue),
              title: Text('Edit Message'),
              onTap: () {
                Navigator.pop(ctx);
                provider.startEditing(message);
              },
            ),

            // Delete Option
            ListTile(
              leading: Icon(Icons.delete_outline, color: Colors.red),
              title: Text(
                'Delete Message',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _confirmDelete(context);
              },
            ),

            // Cancel
            ListTile(
              title: Text('Cancel', style: TextStyle(color: Colors.grey[700])),
              onTap: () => Navigator.pop(ctx),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 10.h),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context) {
    final controller = TextEditingController(text: message.text);
    final provider = context.read<ConversationProvider>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Edit Message'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: null,
          decoration: InputDecoration(
            hintText: 'Type your message',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final newText = controller.text.trim();
              if (newText.isNotEmpty && newText != message.text) {
                provider.editMessage(message.id, newText);
              }
              Navigator.pop(ctx);
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete Message?'),
        content: Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<ConversationProvider>().deleteMessage(message.id);
              Navigator.pop(ctx);
            },
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  BorderRadius _bubbleBorderRadius() {
    const double big = 20;
    const double small = 6;

    return isCurrentUser
        ? BorderRadius.only(
            topLeft: Radius.circular(big),
            topRight: Radius.circular(big),
            bottomLeft: Radius.circular(big),
            bottomRight: Radius.circular(small),
          )
        : BorderRadius.only(
            topLeft: Radius.circular(big),
            topRight: Radius.circular(big),
            bottomLeft: Radius.circular(small),
            bottomRight: Radius.circular(big),
          );
  }

  Widget _buildStatusIcon() {
    switch (message.status) {
      case MessageStatus.sending:
        return Icon(Icons.access_time, size: 14.sp, color: Colors.grey[600]);
      case MessageStatus.sent:
        return Icon(Icons.check, size: 14.sp, color: Colors.grey[600]);
      case MessageStatus.delivered:
        return Icon(Icons.done_all, size: 14.sp, color: Colors.grey[600]);
      case MessageStatus.seen:
        return Icon(Icons.done_all, size: 14.sp, color: AppColors.primaryBlue);
      default:
        return const SizedBox.shrink();
    }
  }
}

// Tail painter (unchanged)
class _MessageTailPainter extends CustomPainter {
  final Color color;
  final bool isOutgoing;

  _MessageTailPainter({required this.color, required this.isOutgoing});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path();

    if (isOutgoing) {
      path.moveTo(0, 0);
      path.lineTo(size.width, size.height / 2);
      path.lineTo(0, size.height);
    } else {
      path.moveTo(size.width, 0);
      path.lineTo(0, size.height / 2);
      path.lineTo(size.width, size.height);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// TypingIndicator (unchanged)
class TypingIndicator extends StatefulWidget {
  final String userName;
  final bool isGroupChat;

  const TypingIndicator({
    Key? key,
    required this.userName,
    this.isGroupChat = false,
  }) : super(key: key);

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with TickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 12.w),
      child: Row(
        children: [
          UserImageHelper.buildUserAvatarWithErrorHandling(
            imageUrl: null,
            radius: 18.r,
          ),
          SizedBox(width: 10.w),
          Container(
            width: 80.w,
            height: 38.h,
            decoration: BoxDecoration(
              color: const Color(0xFFE4E6EB),
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (i) {
                return AnimatedBuilder(
                  animation: _controller,
                  builder: (_, __) {
                    final delay = i * 0.2;
                    final t = ((_controller.value + delay) % 1.0);
                    final scale = t < 0.5 ? t * 2 : (1 - t) * 2;
                    return Transform.scale(
                      scale: 0.7 + scale * 0.3,
                      child: Container(
                        width: 9.r,
                        height: 9.r,
                        margin: EdgeInsets.symmetric(horizontal: 4.w),
                        decoration: BoxDecoration(
                          color: Colors.grey[700],
                          shape: BoxShape.circle,
                        ),
                      ),
                    );
                  },
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
