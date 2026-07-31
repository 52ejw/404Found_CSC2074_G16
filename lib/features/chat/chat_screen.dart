import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../core/widgets/state_views.dart';
import '../../models/conversation.dart';
import '../../models/message.dart';
import '../../providers/chat_provider.dart';

/// Realtime message thread for a single conversation.
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.conversation});

  final Conversation conversation;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  ChatProvider? _chat;
  int _lastMessageCount = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_chat != null) return;
    _chat = context.read<ChatProvider>();
    _chat!.openConversation(widget.conversation);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _chat?.closeConversation();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chat = context.watch<ChatProvider>();
    // New message arrived (incoming or just sent) — follow it to the bottom
    // instead of leaving the user looking at whatever they last scrolled to.
    if (chat.messages.length != _lastMessageCount) {
      _lastMessageCount = chat.messages.length;
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    }
    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            Text(chat.partnerName(widget.conversation)),
            Text(
              chat.postTitle(widget.conversation),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: _MessagesBody(
                chat: chat,
                widget: widget,
                scrollController: _scrollController,
              ),
            ),
            _Composer(
              controller: _messageController,
              isSending: chat.isSending,
              error: chat.messagesError,
              onSend: _send,
            ),
          ],
        ),
      ),
    );
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  Future<void> _send() async {
    final text = _messageController.text;
    if (text.trim().isEmpty) return;
    final sent = await _chat!.sendMessage(
      widget.conversation,
      _messageController.text,
    );
    if (sent) _messageController.clear();
  }
}

class _MessagesBody extends StatelessWidget {
  const _MessagesBody({required this.chat, required this.widget, required this.scrollController});

  final ChatProvider chat;
  final ChatScreen widget;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    if (chat.isLoadingMessages) {
      return const LoadingView(message: 'Loading messages…');
    }
    if (chat.messagesError != null && chat.messages.isEmpty) {
      return ErrorRetryView(
        message: chat.messagesError!,
        onRetry: () => chat.retryMessages(widget.conversation),
      );
    }
    if (chat.messages.isEmpty) {
      return const EmptyView(
        icon: Icons.waving_hand_outlined,
        title: 'Say hello',
        subtitle:
            'Keep personal details private until you are comfortable arranging a handover.',
      );
    }

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: chat.messages.length,
      itemBuilder: (context, index) {
        final message = chat.messages[index];
        return _MessageBubble(message: message, isMine: chat.isMine(message));
      },
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.isMine});

  final Message message;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final time =
        '${message.sentAt.hour.toString().padLeft(2, '0')}:${message.sentAt.minute.toString().padLeft(2, '0')}';
    return Semantics(
      label:
          '${isMine ? 'You' : 'Other person'} said ${message.text}, sent at $time',
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
            color: isMine
                ? AppColors.primary
                : theme.colorScheme.surfaceContainer,
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
                style: TextStyle(
                  color: isMine ? Colors.white : theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$time${isMine && message.isRead ? '  Read' : ''}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: isMine ? Colors.white70 : theme.colorScheme.outline,
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
  const _Composer({
    required this.controller,
    required this.isSending,
    required this.error,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool isSending;
  final String? error;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 8,
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.sm,
          AppSpacing.sm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (error != null)
              Semantics(
                liveRegion: true,
                child: Text(
                  error!,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    key: const Key('message-input'),
                    controller: controller,
                    enabled: !isSending,
                    minLines: 1,
                    maxLines: 4,
                    maxLength: 1000,
                    buildCounter:
                        (
                          context, {
                          required currentLength,
                          required isFocused,
                          required maxLength,
                        }) => null,
                    textCapitalization: TextCapitalization.sentences,
                    textInputAction: TextInputAction.newline,
                    decoration: const InputDecoration(
                      hintText: 'Write a message',
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.sm,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                IconButton.filled(
                  key: const Key('send-message-button'),
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
          ],
        ),
      ),
    );
  }
}
