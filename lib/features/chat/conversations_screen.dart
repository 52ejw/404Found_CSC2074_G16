import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../core/widgets/state_views.dart';
import '../../models/conversation.dart';
import '../../providers/auth_provider.dart';
import '../../providers/conversations_provider.dart';
import 'chat_screen.dart';

/// Messages tab: realtime conversation list with unread badges (FR10).
class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({super.key});

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  String? _loadedUserId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final userId = context.watch<AuthProvider>().userId;
    if (userId != null && userId != _loadedUserId) {
      _loadedUserId = userId;
      context.read<ConversationsProvider>().load(userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ConversationsProvider>();
    final userId = context.watch<AuthProvider>().userId;
    return Scaffold(
      appBar: AppBar(title: const Text('Messages')),
      body: _body(provider, userId),
    );
  }

  Widget _body(ConversationsProvider provider, String? userId) {
    if (userId == null) {
      return const EmptyView(
        icon: Icons.lock_outline,
        title: 'Sign in to view messages',
      );
    }
    if (provider.isLoading) {
      return const LoadingView(message: 'Loading conversations');
    }
    if (provider.error != null) {
      return ErrorRetryView(message: provider.error!, onRetry: provider.retry);
    }
    if (provider.conversations.isEmpty) {
      return const EmptyView(
        icon: Icons.chat_bubble_outline,
        title: 'No conversations yet',
        subtitle: 'Open a post and tap Message owner to start a private chat.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 100),
      itemCount: provider.conversations.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final conversation = provider.conversations[index];
        final post = provider.relatedPost(conversation.relatedPostId);
        return _ConversationTile(
          conversation: conversation,
          userId: userId,
          title: post?.itemName ?? 'Item conversation',
          onTap: () => Navigator.of(context).push(
            ChatScreen.route(
              context,
              conversation: conversation,
              title: post?.itemName ?? 'Item conversation',
              currentUserId: userId,
            ),
          ),
        );
      },
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final Conversation conversation;
  final String userId;
  final String title;
  final VoidCallback onTap;

  const _ConversationTile({
    required this.conversation,
    required this.userId,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final unread = conversation.unreadCounts[userId] ?? 0;
    final lastMessage = conversation.lastMessage.trim().isEmpty
        ? 'Conversation started'
        : conversation.lastMessage;
    return Semantics(
      button: true,
      label: unread == 0
          ? '$title. $lastMessage'
          : '$title. $unread unread messages. $lastMessage',
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.xs,
        ),
        leading: CircleAvatar(
          backgroundColor: AppColors.accentSoft,
          foregroundColor: AppColors.primary,
          child: const Icon(Icons.inventory_2_outlined),
        ),
        title: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontWeight: unread > 0 ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        subtitle: Text(
          lastMessage,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _shortTime(conversation.lastMessageAt),
              style: Theme.of(context).textTheme.labelSmall,
            ),
            if (unread > 0) ...[
              const SizedBox(height: AppSpacing.xs),
              Badge(
                label: Text(unread > 99 ? '99+' : '$unread'),
                backgroundColor: AppColors.sunwayRed,
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _shortTime(DateTime value) {
    final now = DateTime.now();
    if (now.year == value.year &&
        now.month == value.month &&
        now.day == value.day) {
      return '${value.hour.toString().padLeft(2, '0')}:'
          '${value.minute.toString().padLeft(2, '0')}';
    }
    return '${value.day}/${value.month}';
  }
}
