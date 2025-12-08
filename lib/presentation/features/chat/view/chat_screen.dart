// presentation/pages/one_to_one_conversation_page.dart

import 'dart:async';
import 'package:circleslate/core/services/message_read_service.dart';
import 'package:circleslate/core/services/message_storage_service.dart';
import 'package:circleslate/core/services/one_to_one_chat_provider.dart';
import 'package:circleslate/presentation/common_providers/chat_list_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:circleslate/core/constants/app_colors.dart';
import 'package:circleslate/core/utils/user_image_helper.dart';
import '../widgets/professional_message_bubble.dart';

class OneToOneConversationPage extends StatefulWidget {
  final String conversationId;
  final String currentUserId;
  final String chatPartnerId;
  final String chatPartnerName;
  final String? chatPartnerImageUrl;

  const OneToOneConversationPage({
    super.key,
    required this.conversationId,
    required this.currentUserId,
    required this.chatPartnerId,
    required this.chatPartnerName,
    this.chatPartnerImageUrl,
  });

  @override
  State<OneToOneConversationPage> createState() =>
      _OneToOneConversationPageState();
}

class _OneToOneConversationPageState extends State<OneToOneConversationPage>
    with WidgetsBindingObserver {
  late final ConversationProvider _provider;
  bool _hasMarkedAsRead = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _provider = ConversationProvider(
      context: context,
      currentUserId: widget.currentUserId,
      chatPartnerId: widget.chatPartnerId,
      chatPartnerName: widget.chatPartnerName,
      initialConversationId: widget.conversationId.isNotEmpty
          ? widget.conversationId
          : null,
      initialChatPartnerImageUrl: widget.chatPartnerImageUrl,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _markConversationAsReadOnOpen();
    });
  }

  Future<void> _markConversationAsReadOnOpen() async {
    if (_hasMarkedAsRead) return;
    _hasMarkedAsRead = true;

    debugPrint('[1:1 Chat] 📖 Page opened → Setting as visible');

    _provider.setPageVisible(true);

    if (mounted) {
      final chatListProvider = Provider.of<ChatListProvider>(
        context,
        listen: false,
      );
      chatListProvider.markChatAsRead(widget.conversationId);
    }

    await Future.delayed(const Duration(milliseconds: 300));

    if (mounted) {
      debugPrint('[1:1 Chat] 📨 Explicitly triggering mark as read');
      await _provider.markAllUnreadAsRead();
    }

    debugPrint('[1:1 Chat] ✅ All operations complete');
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    _provider.setPageVisible(false);

    if (mounted) {
      final chatListProvider = Provider.of<ChatListProvider>(
        context,
        listen: false,
      );
      chatListProvider.refreshChats(silent: true, force: true);
    }

    _provider.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _provider.setPageVisible(true);
      _provider.resume();

      if (mounted) {
        Provider.of<ChatListProvider>(
          context,
          listen: false,
        ).refreshChats(silent: true);
      }
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _provider.setPageVisible(false);
      _provider.pause();
    }
  }

  Future<bool> _onWillPop() async {
    if (mounted) {
      Provider.of<ChatListProvider>(
        context,
        listen: false,
      ).refreshChats(silent: true, force: true);
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    // ignore: deprecated_member_use
    return WillPopScope(
      onWillPop: _onWillPop,
      child: ChangeNotifierProvider<ConversationProvider>.value(
        value: _provider,
        child: Scaffold(
          backgroundColor: Color.fromARGB(255, 22, 9, 80),
          appBar: AppBar(
            backgroundColor: Color.fromARGB(255, 22, 9, 80),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () {
                Provider.of<ChatListProvider>(
                  context,
                  listen: false,
                ).refreshChats(silent: true, force: true);
                Navigator.of(context).pop();
              },
            ),
            title: Consumer<ConversationProvider>(
              builder: (context, provider, child) {
                return Row(
                  children: [
                    UserImageHelper.buildUserAvatarWithErrorHandling(
                      imageUrl: provider.partnerImageUrl,
                      radius: 18,
                      backgroundColor: Colors.white,
                      iconColor: Colors.grey[600],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.chatPartnerName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (provider.partnerTyping)
                            const Text(
                              'Typing...',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          body: Column(
            children: [
              Expanded(
                child: Consumer<ConversationProvider>(
                  builder: (context, provider, child) {
                    if (provider.isLoading && provider.messages.isEmpty) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (provider.messages.isEmpty) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.chat_bubble_outline,
                              size: 64,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No messages yet. Start the conversation!',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      controller: provider.scrollController,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount:
                          provider.messages.length +
                          (provider.partnerTyping ? 1 : 0),
                      itemBuilder: (context, i) {
                        if (i == provider.messages.length &&
                            provider.partnerTyping) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: TypingIndicator(
                              userName: widget.chatPartnerName,
                            ),
                          );
                        }

                        final msg = provider.messages[i];

                        return ProfessionalMessageBubble(
                          key: ValueKey(msg.id),
                          message: msg,
                          currentUserId: widget.currentUserId,
                          showAvatar: true,
                          showTimestamp: true,
                          isGroupChat: false,
                          onRetry: msg.status == MessageStatus.failed
                              ? () => provider.sendMessage(
                                  msg.text,
                                  retryMessageId: msg.id,
                                )
                              : null,
                        );
                      },
                    );
                  },
                ),
              ),
              SafeArea(
                minimum: const EdgeInsets.only(bottom: 8),
                child: Consumer<ConversationProvider>(
                  builder: (context, provider, child) =>
                      _buildInputBar(provider),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputBar(ConversationProvider provider) {
    final canSend =
        provider.inputReady &&
        provider.messageController.text.trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: provider.messageController,
              enabled: provider.inputReady,
              maxLines: null,
              textCapitalization: TextCapitalization.sentences,
              keyboardType: TextInputType.multiline,
              decoration: InputDecoration(
                hintText: provider.inputReady
                    ? 'Type a message...'
                    : 'Preparing chat...',
                hintStyle: TextStyle(
                  color: provider.inputReady
                      ? Colors.grey[600]
                      : Colors.grey[400],
                ),
                filled: true,
                fillColor: AppColors.chatInputFillColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onSubmitted: (_) {
                if (canSend) provider.onSendPressed();
              },
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              color: canSend ? AppColors.primaryBlue : Colors.grey[300],
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: canSend ? provider.onSendPressed : null,
              icon: Icon(
                Icons.send,
                color: canSend ? Colors.white : Colors.grey[600],
                size: 20,
              ),
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            ),
          ),
        ],
      ),
    );
  }
}

class TypingIndicator extends StatelessWidget {
  final String userName;

  const TypingIndicator({super.key, required this.userName});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(width: 40),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text(
              '$userName is typing...',
              style: const TextStyle(
                fontStyle: FontStyle.italic,
                color: Colors.grey,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
