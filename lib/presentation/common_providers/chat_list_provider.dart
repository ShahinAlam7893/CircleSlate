// lib/presentation/providers/chat_list_provider.dart
import 'dart:async';
import 'package:circleslate/presentation/data/models/chat_model.dart';
import 'package:circleslate/presentation/features/chat/conversation_service.dart';
import 'package:flutter/foundation.dart';
import 'package:circleslate/data/models/user_search_result_model.dart';
import 'package:circleslate/core/services/user_search_service.dart';
import 'package:circleslate/presentation/common_providers/auth_provider.dart';

class ChatListProvider with ChangeNotifier {
  final UserSearchService _userSearchService = UserSearchService();

  // State
  List<Chat> _chats = [];
  List<UserSearchResult> _searchResults = [];
  bool _isSearching = false;
  String? _searchError;
  bool _isLoadingProfile = false;
  Timer? _debounceTimer;
  String? _lastSearchQuery;
  Timer? _autoRefreshTimer;

  // NEW: Track pending refreshes to avoid duplicates
  bool _isRefreshing = false;
  DateTime? _lastRefreshTime;
  static const _minRefreshInterval = Duration(milliseconds: 500);

  // Getters
  List<Chat> get chats => _chats;
  List<UserSearchResult> get searchResults => _searchResults;
  bool get isSearching => _isSearching;
  String? get searchError => _searchError;
  bool get isLoadingProfile => _isLoadingProfile;

  ChatListProvider() {
    _initAutoRefresh();
  }

  // Private helpers
  DateTime _parseChatTime(String timeStr) {
    if (timeStr.isEmpty) return DateTime.fromMillisecondsSinceEpoch(0);
    DateTime? dt = DateTime.tryParse(timeStr);
    if (dt != null) return dt;
    int? ts = int.tryParse(timeStr);
    if (ts != null) {
      return ts < 1000000000000
          ? DateTime.fromMillisecondsSinceEpoch(ts * 1000)
          : DateTime.fromMillisecondsSinceEpoch(ts);
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  String formatChatTime(String timeStr) {
    if (timeStr.isEmpty) return '';
    final dt = _parseChatTime(timeStr);
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) {
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return days[dt.weekday - 1];
    }
    if (dt.year == now.year) {
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return '${dt.day} ${months[dt.month - 1]}';
    }
    return '${dt.day} ${_getMonth(dt.month)} ${dt.year}';
  }

  String _getMonth(int m) => [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ][m - 1];

  void _sortChats() {
    _chats.sort((a, b) {
      final cmp = _parseChatTime(b.time).compareTo(_parseChatTime(a.time));
      return cmp != 0 ? cmp : b.unreadCount.compareTo(a.unreadCount);
    });
  }

  /// Initialize auto-refresh to keep unread counts updated
  void _initAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      refreshChats(silent: true);
    });
  }

  // Public methods
  Future<void> ensureUserProfileLoaded(AuthProvider authProvider) async {
    if (authProvider.currentUserId == null ||
        authProvider.currentUserId!.isEmpty) {
      _isLoadingProfile = true;
      notifyListeners();
      await authProvider.fetchUserProfile();
      _isLoadingProfile = false;
      notifyListeners();
    }
  }

  /// Refresh chats from server with improved debouncing
  /// [silent] - if true, don't show loading indicator
  /// [force] - if true, ignore minimum refresh interval
  Future<void> refreshChats({bool silent = false, bool force = false}) async {
    // Prevent duplicate refreshes
    if (_isRefreshing) {
      debugPrint('[ChatListProvider] Refresh already in progress, skipping');
      return;
    }

    // Enforce minimum refresh interval unless forced
    if (!force && _lastRefreshTime != null) {
      final timeSinceLastRefresh = DateTime.now().difference(_lastRefreshTime!);
      if (timeSinceLastRefresh < _minRefreshInterval) {
        debugPrint('[ChatListProvider] Refresh too soon, skipping');
        return;
      }
    }

    _isRefreshing = true;

    try {
      if (!silent) {
        debugPrint('[ChatListProvider] Refreshing chats...');
      }

      final chatList = await ChatService.fetchChats();

      // IMPROVED: Better change detection including unread counts
      bool hasChanges = _chats.length != chatList.length;

      if (!hasChanges) {
        for (int i = 0; i < _chats.length; i++) {
          final oldChat = _chats[i];
          final newChat = chatList[i];

          if (oldChat.conversationId != newChat.conversationId ||
              oldChat.unreadCount != newChat.unreadCount ||
              oldChat.lastMessage != newChat.lastMessage ||
              oldChat.time != newChat.time ||
              oldChat.status != newChat.status) {
            hasChanges = true;
            debugPrint(
              '[ChatListProvider] Change detected in ${newChat.name}: '
              'unread ${oldChat.unreadCount} -> ${newChat.unreadCount}',
            );
            break;
          }
        }
      }

      if (hasChanges) {
        _chats = chatList;
        _sortChats();
        _lastRefreshTime = DateTime.now();

        debugPrint(
          '[ChatListProvider] Chats updated with ${_chats.length} conversations',
        );

        // Always notify when changes detected
        notifyListeners();
      } else if (!silent) {
        debugPrint('[ChatListProvider] No changes detected');
      }
    } catch (e) {
      debugPrint('[ChatListProvider] Refresh error: $e');
    } finally {
      _isRefreshing = false;
    }
  }

  /// Mark a specific chat as read (update unread count to 0) - IMMEDIATE UPDATE
  void markChatAsRead(String conversationId) {
    final chatIndex = _chats.indexWhere(
      (chat) => chat.conversationId == conversationId,
    );

    if (chatIndex != -1 && _chats[chatIndex].unreadCount > 0) {
      final oldUnreadCount = _chats[chatIndex].unreadCount;

      final updatedChat = Chat(
        conversationId: _chats[chatIndex].conversationId,
        name: _chats[chatIndex].name,
        lastMessage: _chats[chatIndex].lastMessage,
        time: _chats[chatIndex].time,
        imageUrl: _chats[chatIndex].imageUrl,
        unreadCount: 0, // ✅ Immediately set to 0
        isOnline: _chats[chatIndex].isOnline,
        status: _chats[chatIndex].status,
        isGroupChat: _chats[chatIndex].isGroupChat,
        isCurrentUserAdminInGroup: _chats[chatIndex].isCurrentUserAdminInGroup,
        participants: _chats[chatIndex].participants,
        currentUserId: _chats[chatIndex].currentUserId,
        groupChat: _chats[chatIndex].groupChat,
      );

      _chats[chatIndex] = updatedChat;
      _sortChats();

      debugPrint(
        '[ChatListProvider] Chat $conversationId marked as read '
        '(unread: $oldUnreadCount -> 0)',
      );

      notifyListeners();

      // Schedule a server refresh to confirm
      Future.delayed(const Duration(milliseconds: 1000), () {
        refreshChats(silent: true, force: false);
      });
    }
  }

  void onSearchChanged(String query) {
    query = query.trim();
    if (query == _lastSearchQuery) return;

    _debounceTimer?.cancel();
    _searchResults.clear();
    _searchError = null;

    if (query.isEmpty) {
      _isSearching = false;
      _lastSearchQuery = null;
      notifyListeners();
      return;
    }

    _isSearching = true;
    notifyListeners();

    _debounceTimer = Timer(
      const Duration(seconds: 2),
      () => _performSearch(query),
    );
  }

  Future<void> _performSearch(String query) async {
    if (query == _lastSearchQuery) {
      _isSearching = false;
      notifyListeners();
      return;
    }

    if (query.length < 2) {
      _searchResults.clear();
      _isSearching = false;
      _searchError = 'Enter at least 2 characters';
      _lastSearchQuery = query;
      notifyListeners();
      return;
    }

    try {
      final results = await _userSearchService.searchUsers(query);
      _searchResults = results;
      _searchError = null;
    } catch (e) {
      _searchError = 'Search failed';
      _searchResults.clear();
    } finally {
      _isSearching = false;
      _lastSearchQuery = query;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _autoRefreshTimer?.cancel();
    super.dispose();
  }
}
