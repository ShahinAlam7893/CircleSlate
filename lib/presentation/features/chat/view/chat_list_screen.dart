// lib/presentation/pages/chat_list_page.dart

import 'package:circleslate/presentation/common_providers/chat_list_provider.dart';
import 'package:circleslate/presentation/data/models/chat_model.dart';
import 'package:circleslate/core/services/conversation_manager.dart'; // ← NEW IMPORT
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:circleslate/core/constants/app_colors.dart';
import 'package:circleslate/presentation/common_providers/auth_provider.dart';
import 'package:circleslate/presentation/routes/app_router.dart';
import 'package:circleslate/data/models/user_search_result_model.dart';

class ChatListPage extends StatelessWidget {
  const ChatListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ChatListProvider(),
      child: const _ChatListView(),
    );
  }
}

class _ChatListView extends StatefulWidget {
  const _ChatListView();

  @override
  State<_ChatListView> createState() => _ChatListViewState();
}

class _ChatListViewState extends State<_ChatListView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final provider = Provider.of<ChatListProvider>(context, listen: false);
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        provider.ensureUserProfileLoaded(authProvider);
        provider.refreshChats();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ChatListProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final isSearchMode =
        provider.searchResults.isNotEmpty || provider.isSearching;

    if (provider.isLoadingProfile) {
      return Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          backgroundColor: AppColors.primaryBlue,
          title: const Text(
            'Chat',
            style: TextStyle(color: Colors.white, fontFamily: 'Poppins'),
          ),
          centerTitle: true,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
        title: const Text(
          'Chat',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Poppins',
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () => context.push(
              RoutePaths.creategrouppage,
              extra: {'currentUserId': authProvider.currentUserId},
            ),
            child: const Text(
              'Create Group',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: provider.onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search users...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: provider.isSearching
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: isSearchMode
                ? _buildSearchResults(context, provider)
                : _buildChatList(context, provider, authProvider.currentUserId),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults(BuildContext context, ChatListProvider provider) {
    if (provider.isSearching)
      return const Center(child: CircularProgressIndicator());
    if (provider.searchError != null)
      return Center(
        child: Text(
          provider.searchError!,
          style: const TextStyle(color: Colors.red),
        ),
      );
    if (provider.searchResults.isEmpty)
      return const Center(child: Text('No users found'));

    return ListView.builder(
      itemCount: provider.searchResults.length,
      itemBuilder: (context, i) =>
          _UserSearchTile(user: provider.searchResults[i]),
    );
  }

  Widget _buildChatList(
    BuildContext context,
    ChatListProvider provider,
    String? currentUserId,
  ) {
    if (provider.chats.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
            Text('No active chats'),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: provider.chats.length,
      itemBuilder: (context, i) {
        final chat = provider.chats[i];
        return _ChatTile(chat: chat, currentUserId: currentUserId);
      },
    );
  }
}

class _UserSearchTile extends StatelessWidget {
  final UserSearchResult user;
  const _UserSearchTile({required this.user});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: NetworkImage(user.profilePhotoUrl ?? ''),
        backgroundColor: Colors.blue,
        child: user.profilePhotoUrl == null ? const Icon(Icons.person) : null,
      ),
      title: Text(
        user.fullName,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(user.email),
      onTap: () async {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final chatListProvider = Provider.of<ChatListProvider>(
          context,
          listen: false,
        );

        if (authProvider.currentUserId == null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('User not logged in')));
          return;
        }

        try {
          final result = await ConversationManager.getOrCreateConversation(
            authProvider.currentUserId!,
            user.id.toString(),
            partnerName: user.fullName,
          );

          final conversationId = result['conversation']?['id']?.toString();

          if (conversationId == null || conversationId.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to create chat. Please try again.'),
              ),
            );
            return;
          }

          if (!context.mounted) return;

          debugPrint(
            'Opening 1:1 chat → ID: $conversationId | Partner: ${user.fullName}',
          );

          await context.push(
            RoutePaths.onetooneconversationpage,
            extra: {
              'conversationId': conversationId,
              'chatPartnerName': user.fullName,
              'chatPartnerId': user.id.toString(),
              'currentUserId': authProvider.currentUserId!,
              'chatPartnerImageUrl': user.profilePhotoUrl ?? '',
            },
          );

          if (context.mounted) {
            chatListProvider.refreshChats(silent: true);
          }
        } catch (e) {
          debugPrint('Error starting chat: $e');
          if (context.mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
          }
        }
      },
    );
  }
}

class _ChatTile extends StatelessWidget {
  final Chat chat;
  final String? currentUserId;

  const _ChatTile({required this.chat, required this.currentUserId});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ChatListProvider>(context);
    final hasUnread = chat.unreadCount > 0;
    final time = provider.formatChatTime(chat.time);

    return GestureDetector(
      onTap: () async {
        final chatListProvider = Provider.of<ChatListProvider>(
          context,
          listen: false,
        );

        if (chat.unreadCount > 0) {
          chatListProvider.markChatAsRead(chat.conversationId);
          debugPrint(
            '[ChatTile] Badge instantly removed for ${chat.conversationId}',
          );
        }

        if (!chat.isGroupChat) {
          await context.push(
            RoutePaths.onetooneconversationpage,
            extra: {
              'conversationId': chat.conversationId,
              'chatPartnerName': chat.name ?? 'Chat',
              'chatPartnerId': currentUserId != null
                  ? chat.participants
                            .firstWhere(
                              (p) => p['id'].toString() != currentUserId,
                              orElse: () => {},
                            )['id']
                            ?.toString() ??
                        ''
                  : '',
              'currentUserId': currentUserId,
              'chatPartnerImageUrl': chat.imageUrl,
            },
          );
        } else {
          await context.push(
            RoutePaths.groupConversationPage,
            extra: {
              'groupName': chat.name,
              'isGroupChat': true,
              'isCurrentUserAdminInGroup':
                  chat.isCurrentUserAdminInGroup ?? false,
              'currentUserId': currentUserId,
              'conversationId': chat.conversationId,
              'groupImageUrl': chat.imageUrl,
            },
          );
        }

        if (context.mounted) {
          chatListProvider.refreshChats(silent: true);
        }
      },
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundImage: chat.imageUrl.startsWith('http')
                    ? NetworkImage(chat.imageUrl)
                    : null,
                child: chat.imageUrl.isEmpty
                    ? Icon(
                        chat.isGroupChat ? Icons.group : Icons.person,
                        size: 28,
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      chat.name ?? 'Chat',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: hasUnread
                            ? FontWeight.bold
                            : FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      chat.lastMessage,
                      style: TextStyle(
                        fontSize: 14,
                        color: hasUnread ? Colors.black87 : Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    time,
                    style: TextStyle(
                      fontSize: 12,
                      color: hasUnread
                          ? Colors.green.shade600
                          : Colors.grey[600],
                      fontWeight: hasUnread ? FontWeight.w500 : null,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (hasUnread)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        chat.unreadCount > 99 ? '99+' : '${chat.unreadCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  else
                    _statusIcon(chat),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusIcon(Chat chat) {
    if (chat.status == ChatMessageStatus.seen) {
      return const Icon(Icons.done_all, size: 18, color: Colors.blue);
    } else if (chat.status == ChatMessageStatus.delivered) {
      return const Icon(Icons.done_all, size: 18, color: Colors.grey);
    } else if (chat.status == ChatMessageStatus.sent) {
      return const Icon(Icons.check, size: 18, color: Colors.grey);
    }
    return const SizedBox.shrink();
  }
}
