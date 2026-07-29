import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../core/widgets/state_views.dart';
import '../../models/conversation.dart';
import '../../models/message.dart';
import '../../providers/conversations_provider.dart';
import '../../repositories/chat_repository.dart';

/// A private realtime conversation for a single post (FR10).
class ChatScreen extends StatefulWidget {
  final String title;

  const ChatScreen({super.key, required this.title});

  static Route<void> route(
    BuildContext context, {
    required Conversation conversation,
    required String title,
    required String currentUserId,
  }) {
    final repository = context.read<ChatRepository>();
    return MaterialPageRoute(
      builder: (_) => ChangeNotifierProvider(
        create: (_) => ChatProvider(
          chatRepository: repository,
          conversationId: conversation.id,
          currentUserId: currentUserId,
        ),
        child: ChatScreen(title: title),
      ),
    );
  }

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _message = TextEditingController();

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final provider = context.read<ChatProvider>();
    final sent = await provider.send(_message.text);
    if (sent) {
      _message.clear();
    } else if (provider.error != null && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(provider.error!)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChatProvider>();
    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            Text(widget.title),
            Text(
              'Private campus chat',
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: _messageBody(provider)),
            _Composer(
              controller: _message,
              isSending: provider.isSending,
              onSend: _send,
            ),
          ],
        ),
      ),
    );
  }

  Widget _messageBody(ChatProvider provider) {
    if (provider.isLoading) {
      return const LoadingView(message: 'Loading messages');
    }
    if (provider.error != null && provider.messages.isEmpty) {
      return ErrorRetryView(message: provider.error!, onRetry: provider.retry);
    }
    if (provider.messages.isEmpty) {
      return const EmptyView(
        icon: Icons.waving_hand_outlined,
        title: 'Start the conversation',
        subtitle:
            'Avoid sharing passwords or payment details. Meet in a public campus area.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: provider.messages.length,
      itemBuilder: (context, index) {
        final message = provider.messages[index];
        return _MessageBubble(
          message: message,
          isMine: message.senderId == provider.currentUserId,
        );
      },
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final Message message;
  final bool isMine;

  const _MessageBubble({required this.message, required this.isMine});

  @override
  Widget build(BuildContext context) {
    final time =
        '${message.sentAt.hour.toString().padLeft(2, '0')}:'
        '${message.sentAt.minute.toString().padLeft(2, '0')}';
    return Semantics(
      label:
          '${isMine ? 'You' : 'Other student'} said '
          '${message.text}. Sent at $time',
      child: Align(
        alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 300),
          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: isMine ? AppColors.primary : AppColors.placeholder,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(isMine ? 16 : 4),
              bottomRight: Radius.circular(isMine ? 4 : 16),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                message.text,
                style: TextStyle(color: isMine ? Colors.white : Colors.black87),
              ),
              const SizedBox(height: 2),
              Text(
                time,
                style: TextStyle(
                  fontSize: 10,
                  color: isMine
                      ? Colors.white.withValues(alpha: 0.75)
                      : Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  final TextEditingController controller;
  final bool isSending;
  final VoidCallback onSend;

  const _Composer({
    required this.controller,
    required this.isSending,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 8,
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
          AppSpacing.sm,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 4,
                maxLength: 1000,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: 'Write a message',
                  counterText: '',
                ),
                onSubmitted: (_) {
                  if (!isSending) onSend();
                },
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            IconButton.filled(
              tooltip: 'Send message',
              onPressed: isSending ? null : onSend,
              icon: isSending
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send),
            ),
          ],
        ),
      ),
    );
  }
}
