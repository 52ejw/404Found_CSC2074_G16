import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../core/widgets/state_views.dart';
import '../../core/widgets/type_badge.dart';
import '../../models/enums.dart';
import '../../models/item_post.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/post_provider.dart';
import '../chat/chat_screen.dart';
import '../claims/claim_form_sheet.dart';
import 'post_form_screen.dart';

/// Full lost/found post details with owner and contact actions.
class PostDetailsScreen extends StatefulWidget {
  const PostDetailsScreen({super.key, required this.postId, this.initialPost});

  final String postId;
  final ItemPost? initialPost;

  @override
  State<PostDetailsScreen> createState() => _PostDetailsScreenState();
}

class _PostDetailsScreenState extends State<PostDetailsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<PostProvider>().loadPost(
        widget.postId,
        initialPost: widget.initialPost,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PostProvider>();
    final post = provider.selectedPost?.id == widget.postId
        ? provider.selectedPost
        : widget.initialPost;
    final isOwner =
        post != null && post.ownerId == context.watch<AuthProvider>().userId;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Post details'),
        actions: [
          if (post != null && isOwner)
            PopupMenuButton<_OwnerAction>(
              tooltip: 'Post actions',
              onSelected: (action) => _handleOwnerAction(action, post),
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: _OwnerAction.edit,
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.edit_outlined),
                    title: Text('Edit post'),
                  ),
                ),
                PopupMenuItem(
                  value: _OwnerAction.delete,
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.delete_outline),
                    title: Text('Delete post'),
                  ),
                ),
              ],
            ),
        ],
      ),
      body: _buildBody(provider, post),
      bottomNavigationBar: post == null
          ? null
          : _ActionBar(post: post, isOwner: isOwner),
    );
  }

  Widget _buildBody(PostProvider provider, ItemPost? post) {
    if (post == null && provider.isLoadingDetails) {
      return const LoadingView(message: 'Loading post…');
    }
    if (post == null && provider.detailsError != null) {
      return ErrorRetryView(
        message: provider.detailsError!,
        onRetry: () => provider.loadPost(widget.postId),
      );
    }
    if (post == null) {
      return const EmptyView(
        icon: Icons.article_outlined,
        title: 'Post unavailable',
        subtitle: 'It may have been removed by its owner.',
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.loadPost(widget.postId),
      child: ListView(
        padding: const EdgeInsets.only(bottom: 112),
        children: [
          _PostImage(post: post),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    TypeBadge(type: post.postType),
                    const SizedBox(width: AppSpacing.sm),
                    _StatusPill(status: post.status),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  post.itemName,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Posted by ${post.ownerName.isEmpty ? 'Campus member' : post.ownerName}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                _DetailRow(
                  icon: Icons.category_outlined,
                  label: 'Category',
                  value: post.category,
                ),
                _DetailRow(
                  icon: Icons.location_on_outlined,
                  label: 'Location',
                  value: post.location,
                ),
                _DetailRow(
                  icon: Icons.calendar_today_outlined,
                  label: post.postType == PostType.lost
                      ? 'Date lost'
                      : 'Date found',
                  value: _formatDate(post.eventDate),
                ),
                _DetailRow(
                  icon: Icons.contact_mail_outlined,
                  label: 'Preferred contact',
                  value: _contactLabel(post.contactPreference),
                ),
                const Divider(height: AppSpacing.xl * 2),
                Text(
                  'Description',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(post.description),
                if (provider.error != null) ...[
                  const SizedBox(height: AppSpacing.lg),
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      provider.error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleOwnerAction(_OwnerAction action, ItemPost post) async {
    switch (action) {
      case _OwnerAction.edit:
        await _edit(post);
      case _OwnerAction.delete:
        await _delete(post);
    }
  }

  Future<void> _edit(ItemPost post) async {
    final updated = await Navigator.of(context).push<ItemPost>(
      MaterialPageRoute(builder: (_) => PostFormScreen(existingPost: post)),
    );
    if (updated != null && mounted) {
      await context.read<PostProvider>().loadPost(
        updated.id,
        initialPost: updated,
      );
    }
  }

  Future<void> _delete(ItemPost post) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete this post?'),
        content: const Text(
          'This cannot be undone. Existing chats and claim history may still reference it.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final deleted = await context.read<PostProvider>().deletePost(post);
    if (deleted && mounted) Navigator.of(context).pop();
  }
}

class _PostImage extends StatelessWidget {
  const _PostImage({required this.post});

  final ItemPost post;

  @override
  Widget build(BuildContext context) {
    final image = post.imageUrls.isEmpty ? null : post.imageUrls.first;
    return Semantics(
      image: true,
      label: 'Photo of ${post.itemName}',
      child: AspectRatio(
        aspectRatio: 16 / 10,
        child: image == null
            ? _placeholder()
            : Image.network(
                image,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _placeholder(),
              ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: AppColors.placeholder,
      alignment: Alignment.center,
      child: const Icon(Icons.image_outlined, size: 64, color: Colors.white),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: AppSpacing.md),
          SizedBox(
            width: 112,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final PostStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppSpacing.controlRadius),
      ),
      child: Text(
        _statusLabel(status),
        style: Theme.of(context).textTheme.labelSmall,
      ),
    );
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({required this.post, required this.isOwner});

  final ItemPost post;
  final bool isOwner;

  @override
  Widget build(BuildContext context) {
    final postProvider = context.watch<PostProvider>();
    return Material(
      elevation: 12,
      color: Theme.of(context).colorScheme.surface,
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.all(AppSpacing.md),
        child: isOwner
            ? Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: postProvider.isSubmitting
                          ? null
                          : () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    PostFormScreen(existingPost: post),
                              ),
                            ),
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Edit'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed:
                          postProvider.isSubmitting ||
                              post.status == PostStatus.closed
                          ? null
                          : () => postProvider.updateStatus(
                              post,
                              PostStatus.closed,
                            ),
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('Close post'),
                    ),
                  ),
                ],
              )
            : Row(
                children: [
                  if (post.postType == PostType.found &&
                      post.status != PostStatus.returned &&
                      post.status != PostStatus.closed) ...[
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => showModalBottomSheet<bool>(
                          context: context,
                          isScrollControlled: true,
                          showDragHandle: true,
                          builder: (_) => ClaimFormSheet(post: post),
                        ),
                        icon: const Icon(Icons.verified_user_outlined),
                        label: const Text('Claim'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                  ],
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _startChat(context, post),
                      icon: const Icon(Icons.chat_bubble_outline),
                      label: const Text('Message'),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _startChat(BuildContext context, ItemPost post) async {
    final conversation = await context.read<ChatProvider>().startConversation(
      post,
    );
    if (!context.mounted) return;
    if (conversation == null) {
      final error = context.read<ChatProvider>().error;
      if (error != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error)));
      }
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ChatScreen(conversation: conversation)),
    );
  }
}

enum _OwnerAction { edit, delete }

String _formatDate(DateTime date) {
  const months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}

String _contactLabel(ContactPreference preference) {
  switch (preference) {
    case ContactPreference.inAppChat:
      return 'In-app chat';
    case ContactPreference.email:
      return 'Email';
    case ContactPreference.phone:
      return 'Phone';
  }
}

String _statusLabel(PostStatus status) {
  switch (status) {
    case PostStatus.open:
      return 'Open';
    case PostStatus.possibleMatch:
      return 'Possible match';
    case PostStatus.claimRequested:
      return 'Claim requested';
    case PostStatus.returned:
      return 'Returned';
    case PostStatus.closed:
      return 'Closed';
  }
}
