import 'dart:convert';
import 'package:circleslate/core/constants/app_assets.dart';
import 'package:circleslate/core/constants/app_colors.dart';
import 'package:circleslate/presentation/routes/app_router.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../../../../core/services/user_search_service.dart';
import '../../../../data/models/user_search_result_model.dart';
import '../../../routes/route_observer.dart';
import '../conversation_service.dart';
import '../../../data/models/chat_model.dart';
import '../../../common_providers/auth_provider.dart';

class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> with RouteAware {
  final TextEditingController _searchController = TextEditingController();
  List<UserSearchResult> _userSearchResults = [];
  List<Chat> _userList = [];
  final UserSearchService _userSearchService = UserSearchService();
  bool _isSearching = false;
  String? _searchError;
  bool _isLoadingProfile = false;

  // Get current user ID from AuthProvider
  String? get currentUserId {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    return authProvider.currentUserId;
  }

  // Ensure user profile is loaded
  Future<void> _ensureUserProfileLoaded() async {
    if (currentUserId == null || currentUserId!.isEmpty) {
      setState(() {
        _isLoadingProfile = true;
      });

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.fetchUserProfile();

      setState(() {
        _isLoadingProfile = false;
      });
    }
  }

  DateTime _parseChatTime(String timeStr) {
    if (timeStr.isEmpty) {
      return DateTime.fromMillisecondsSinceEpoch(0);
    }

    DateTime? dateTime = DateTime.tryParse(timeStr);
    if (dateTime != null) {
      return dateTime;
    }

    int? timestamp = int.tryParse(timeStr);
    if (timestamp != null) {
      if (timestamp < 1000000000000) {
        return DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
      } else {
        return DateTime.fromMillisecondsSinceEpoch(timestamp);
      }
    }

    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  void _sortChatsByUnreadAndRecent() {
    _userList.sort((a, b) {
      if (b.unreadCount != a.unreadCount) {
        return b.unreadCount.compareTo(a.unreadCount);
      }
      final dateA = _parseChatTime(a.time);
      final dateB = _parseChatTime(b.time);
      return dateB.compareTo(dateA);
    });
  }

  void _refreshChats() {
    ChatService.fetchChats().then((chatList) {
      setState(() {
        _userList = chatList;
        _sortChatsByUnreadAndRecent();
      });
      debugPrint('[ChatListPage] Refreshed chats: ${_userList.length} chats loaded');
    }).catchError((e) {
      debugPrint('[ChatListPage] Error refreshing chat list: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to refresh chats: $e')),
      );
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _userSearchService.dispose();
    super.dispose();
  }

  @override
  void didPopNext() {
    _refreshChats();
  }

  @override
  void didPush() {
    _refreshChats();
  }

  @override
  void initState() {
    super.initState();
    _ensureUserProfileLoaded().then((_) {
      _refreshChats();
    });
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _userSearchResults.clear();
        _isSearching = false;
        _searchError = null;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _searchError = null;
    });

    _performSearch(query);
  }

  void _performSearch(String query) async {
    try {
      debugPrint('[ChatListPage] Performing search for: "$query"');
      final results = await _userSearchService.searchUsers(query);
      debugPrint('[ChatListPage] Search returned ${results.length} results');

      if (mounted) {
        setState(() {
          _userSearchResults = results;
          _isSearching = false;
          _searchError = null;
        });
        debugPrint('[ChatListPage] Search results updated in UI');
      }
    } catch (e) {
      debugPrint('[ChatListPage] Search error: $e');
      if (mounted) {
        setState(() {
          _userSearchResults.clear();
          _isSearching = false;
          _searchError = 'Search failed: ${e.toString()}';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSearchMode = _searchController.text.trim().isNotEmpty;

    if (_isLoadingProfile) {
      return Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: AppColors.primaryBlue,
          elevation: 0,
          title: const Text(
            'Chat',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20.0,
              fontWeight: FontWeight.w500,
              fontFamily: 'Poppins',
            ),
          ),
          centerTitle: true,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'Loading user profile...',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: AppColors.primaryBlue,
        elevation: 0,
        title: const Text(
          'Chat',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20.0,
            fontWeight: FontWeight.w500,
            fontFamily: 'Poppins',
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () async {
              try {
                if (currentUserId == null || currentUserId!.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('User ID is missing. Please log in again.')),
                  );
                  return;
                }

                debugPrint('[ChatListPage] Navigating to CreateGroupPage with currentUserId: $currentUserId');
                await context.push(
                  RoutePaths.creategrouppage,
                  extra: {'currentUserId': currentUserId},
                );
                _refreshChats();
              } catch (e) {
                debugPrint('[ChatListPage] Error navigating to CreateGroupPage: $e');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error navigating to Create Group: $e')),
                );
              }
            },
            child: const Text(
              'Create Group',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14.0,
                fontWeight: FontWeight.w500,
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search users...',
                hintStyle: const TextStyle(
                  color: AppColors.textColorSecondary,
                  fontFamily: 'Poppins',
                ),
                prefixIcon: const Icon(Icons.search, color: AppColors.textColorPrimary),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                  },
                )
                    : null,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 12.0,
                  horizontal: 16.0,
                ),
              ),
            ),
          ),
          Expanded(
            child: isSearchMode ? _buildSearchResults() : _buildChatList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_searchError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              _searchError!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _performSearch(_searchController.text.trim()),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_userSearchResults.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No users found',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      itemCount: _userSearchResults.length,
      itemBuilder: (context, index) {
        final user = _userSearchResults[index];
        return _buildUserSearchItem(context, user);
      },
    );
  }

  Widget _buildUserSearchItem(BuildContext context, UserSearchResult user) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      elevation: 0,
      color: Colors.white,
      child: ListTile(
        contentPadding: const EdgeInsets.all(16.0),
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundImage: user.profilePhotoUrl != null
                  ? NetworkImage(user.profilePhotoUrl!)
                  : const AssetImage(AppAssets.johnProfile) as ImageProvider,
            ),
            if (user.isOnline)
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
          ],
        ),
        title: Text(
          user.fullName,
          style: const TextStyle(
            fontSize: 16.0,
            fontWeight: FontWeight.w500,
            color: Color(0xFF1A1A1A),
            fontFamily: 'Poppins',
          ),
        ),
        subtitle: Text(
          user.email,
          style: const TextStyle(
            fontSize: 14.0,
            color: AppColors.textColorSecondary,
            fontFamily: 'Poppins',
          ),
        ),
        trailing: Icon(
          user.isOnline ? Icons.circle : Icons.circle_outlined,
          color: user.isOnline ? Colors.green : Colors.grey,
          size: 12,
        ),
        onTap: () async {
          try {
            await _ensureUserProfileLoaded();
            if (currentUserId == null || currentUserId!.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('User ID is missing. Please log in again.')),
              );
              return;
            }

            debugPrint('[ChatListPage] Starting chat with user: ${user.fullName}, imageUrl: ${user.profilePhotoUrl}');
            final conversationId = await ChatService.getOrCreateConversation(
              currentUserId!,
              user.id,
              partnerName: user.fullName,
            );

            if (!mounted) return;

            context.push(
              RoutePaths.onetooneconversationpage,
              extra: {
                'chatPartnerName': user.fullName,
                'chatPartnerId': user.id,
                'currentUserId': currentUserId,
                'chatPartnerImageUrl': user.profilePhotoUrl, // Pass profile photo
                'isGroupChat': false,
                'isCurrentUserAdminInGroup': false,
                'conversationId': conversationId,
              },
            );
          } catch (e) {
            debugPrint('[ChatListPage] Error starting chat: $e');
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to start chat. Please try again.')),
            );
          }
        },
      ),
    );
  }

  Widget _buildChatList() {
    if (_userList.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No active chats',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      itemCount: _userList.length,
      itemBuilder: (context, index) {
        final chat = _userList[index];
        return _buildChatItem(context, chat);
      },
    );
  }

  Widget _buildChatItem(BuildContext context, Chat chat) {
    return GestureDetector(
      onTap: () {
        if (!chat.isGroupChat && chat.participants.isNotEmpty) {
          final partner = chat.participants.firstWhere(
                (p) => p['id'].toString() != currentUserId,
            orElse: () => null,
          );

          if (partner == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Chat partner not found')),
            );
            return;
          }

          debugPrint('[ChatListPage] Navigating to OneToOneConversationPage with imageUrl: ${chat.imageUrl}');
          print( "=====++++" + chat.imageUrl.toString());
          context.push(
            RoutePaths.onetooneconversationpage,
            extra: {
              'chatPartnerName': chat.name,
              'chatPartnerId': partner['id'].toString(),
              'currentUserId': currentUserId,
              'chatPartnerImageUrl': chat.imageUrl,
              'isGroupChat': false,
              'isCurrentUserAdminInGroup': false,
              'conversationId': chat.conversationId,
            },
          );
        } else {
          debugPrint('[ChatListPage] Navigating to GroupConversationPage with imageUrl: ${chat.imageUrl}');

          context.push(
            RoutePaths.groupConversationPage,
            extra: {
              'groupName': chat.name,
              'isGroupChat': true,
              'isCurrentUserAdminInGroup': chat.isCurrentUserAdminInGroup ?? false,
              'currentUserId': currentUserId,
              'conversationId': chat.conversationId,
              'groupImageUrl': chat.imageUrl, // Pass group image if needed
            },
          );
        }
      },
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
        elevation: 0,
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.blueGrey[100],
                    radius: 28,
                    backgroundImage: chat.imageUrl.isNotEmpty
                        ? (chat.imageUrl.startsWith('http')
                        ? NetworkImage(chat.imageUrl)
                        : AssetImage(chat.imageUrl) as ImageProvider)
                        : null,
                    onBackgroundImageError: chat.imageUrl.isNotEmpty
                        ? (_, __) {
                      debugPrint('[ChatListPage] Failed to load image: ${chat.imageUrl}');
                    }
                        : null,
                    child: chat.imageUrl.isEmpty
                        ? (chat.isGroupChat
                        ? const Icon(Icons.group, size: 28, color: Colors.grey)
                        : const Icon(Icons.person, size: 28, color: Colors.grey))
                        : null,
                  ),




                  // CircleAvatar(
                  //   radius: 28,
                  //   backgroundImage: chat.imageUrl.startsWith('http')
                  //       ? NetworkImage(chat.imageUrl)
                  //       : AssetImage(chat.imageUrl) as ImageProvider,
                  //   onBackgroundImageError: (_, __) {
                  //     debugPrint('[ChatListPage] Failed to load image: ${chat.imageUrl}');
                  //   },
                  //   child: chat.imageUrl.isEmpty ? const Icon(Icons.person) : null,
                  // ),
                ],
              ),
              const SizedBox(width: 16.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            chat.name,
                            style: const TextStyle(
                              fontSize: 12.0,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF1A1A1A),
                              fontFamily: 'Poppins',
                            ),
                            softWrap: false,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        if (chat.isGroupChat)
                          Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: Icon(
                              Icons.group,
                              size: 12,
                              color: AppColors.textColorSecondary,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      chat.lastMessage,
                      style: TextStyle(
                        fontSize: 9.0,
                        color: chat.unreadCount > 0
                            ? AppColors.textColorPrimary
                            : AppColors.textColorSecondary,
                        fontWeight: chat.unreadCount > 0 ? FontWeight.w500 : FontWeight.w400,
                        fontFamily: 'Poppins',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      softWrap: false,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12.0),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            chat.time,
                            style: const TextStyle(fontSize: 12.0, fontFamily: 'Poppins'),
                            softWrap: false,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        const SizedBox(width: 4.0),
                        if (chat.status == ChatMessageStatus.sent)
                          Icon(Icons.check, size: 14, color: AppColors.textColorSecondary),
                        if (chat.status == ChatMessageStatus.delivered)
                          Row(
                            children: const [
                              Icon(Icons.check, size: 14, color: AppColors.textColorSecondary),
                              Icon(Icons.check, size: 14, color: AppColors.textColorSecondary),
                            ],
                          ),
                        if (chat.status == ChatMessageStatus.seen)
                          CircleAvatar(
                            radius: 8,
                            backgroundImage: chat.imageUrl.startsWith('http')
                                ? NetworkImage(chat.imageUrl)
                                : AssetImage(chat.imageUrl) as ImageProvider,
                            onBackgroundImageError: (_, __) {
                              debugPrint('[ChatListPage] Failed to load avatar for seen indicator');
                            },
                          ),
                      ],
                    ),
                    // if (chat.unreadCount > 0)
                    //   Padding(
                    //     padding: const EdgeInsets.only(top: 4.0),
                    //     child: Container(
                    //       padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                    //       decoration: BoxDecoration(
                    //         color: AppColors.primaryBlue,
                    //         borderRadius: BorderRadius.circular(12.0),
                    //       ),
                    //       child: Text(
                    //         '${chat.unreadCount}',
                    //         style: const TextStyle(
                    //           color: Colors.white,
                    //           fontSize: 10.0,
                    //           fontWeight: FontWeight.w600,
                    //         ),
                    //       ),
                    //     ),
                    //   ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}