import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../core/widgets/state_views.dart';
import '../../models/conversation.dart';
import '../../providers/chat_provider.dart';
import 'chat_screen.dart';

/// Signed-in user's private conversation inbox.
class ConversationsScreen extends StatelessWidget {
  const ConversationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final chat = context.watch<ChatProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Messages')),
      body: _ConversationBody(chat: chat),
    );
  }
}

class _ConversationBody extends StatelessWidget {
  const _ConversationBody({required this.chat});

  final ChatProvider chat;

  @override
  Widget build(BuildContext context) {
    if (chat.isLoading) {
      return const LoadingView(message: 'Loading conversations…');
    }
    if (chat.error != null) {
      return ErrorRetryView(message: chat.error!, onRetry: chat.retry);
    }
    if (chat.conversations.isEmpty) {
      return const EmptyView(
        icon: Icons.forum_outlined,
        title: 'No conversations yet',
        subtitle: 'Open an item post and message its owner to get started.',
      );
    }

    return RefreshIndicator(
      onRefresh: () async => chat.retry(),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        itemCount: chat.conversations.length,
        separatorBuilder: (_, _) => const Divider(height: 1, indent: 80),
        itemBuilder: (context, index) {
          final conversation = chat.conversations[index];
          return _ConversationTile(
            conversation: conversation,
            partnerName: chat.partnerName(conversation),
            postTitle: chat.postTitle(conversation),
            unreadCount:
                conversation.unreadCounts[context
                    .read<ChatProvider>()
                    .userId] ??
                0,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ChatScreen(conversation: conversation),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({
    required this.conversation,
    required this.partnerName,
    required this.postTitle,
    required this.unreadCount,
    required this.onTap,
  });

  final Conversation conversation;
  final String partnerName;
  final String postTitle;
  final int unreadCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      label:
          'Conversation with $partnerName about $postTitle${unreadCount > 0 ? ', $unreadCount unread messages' : ''}',
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: AppColors.accentSoft,
          foregroundColor: AppColors.primary,
          child: Text(partnerName.isEmpty ? '?' : partnerName[0].toUpperCase()),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                partnerName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              _relativeTime(conversation.lastMessageAt),
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              postTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelMedium?.copyWith(
                color: AppColors.primary,
              ),
            ),
            Text(
              conversation.lastMessage.isEmpty
                  ? 'Start the conversation'
                  : conversation.lastMessage,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        trailing: unreadCount == 0
            ? const Icon(Icons.chevron_right)
            : Badge(label: Text(unreadCount > 99 ? '99+' : '$unreadCount')),
      ),
    );
  }

  String _relativeTime(DateTime value) {
    final difference = DateTime.now().difference(value);
    if (difference.inMinutes < 1) return 'Now';
    if (difference.inHours < 1) return '${difference.inMinutes}m';
    if (difference.inDays < 1) return '${difference.inHours}h';
    if (difference.inDays < 7) return '${difference.inDays}d';
    return '${value.day}/${value.month}';
  }
}
