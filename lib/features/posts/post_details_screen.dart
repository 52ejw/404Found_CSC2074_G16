import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/state_views.dart';
import '../../core/widgets/type_badge.dart';
import '../../models/claim_request.dart';
import '../../models/enums.dart';
import '../../models/item_post.dart';
import '../../providers/auth_provider.dart';
import '../../providers/claims_provider.dart';
import '../../providers/post_detail_provider.dart';
import '../../providers/post_editor_provider.dart';
import '../../repositories/chat_repository.dart';
import '../../repositories/claim_repository.dart';
import '../../repositories/post_repository.dart';
import '../chat/chat_screen.dart';
import 'post_form_screen.dart';

/// Complete post view with owner editing, chat and claim workflows.
class PostDetailsScreen extends StatefulWidget {
  const PostDetailsScreen({super.key});

  static Route<void> route(BuildContext context, {required String postId}) {
    final postRepository = context.read<PostRepository>();
    final claimRepository = context.read<ClaimRepository>();
    final chatRepository = context.read<ChatRepository>();
    return MaterialPageRoute(
      builder: (_) => ChangeNotifierProvider(
        create: (_) => PostDetailProvider(
          postRepository: postRepository,
          claimRepository: claimRepository,
          chatRepository: chatRepository,
          postId: postId,
        ),
        child: const PostDetailsScreen(),
      ),
    );
  }

  @override
  State<PostDetailsScreen> createState() => _PostDetailsScreenState();
}

class _PostDetailsScreenState extends State<PostDetailsScreen> {
  String? _claimsUserId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final userId = context.watch<AuthProvider>().userId;
    if (userId != null && _claimsUserId != userId) {
      _claimsUserId = userId;
      context.read<ClaimsProvider>().load(userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final detail = context.watch<PostDetailProvider>();
    final userId = context.watch<AuthProvider>().userId;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Post details'),
        actions: [
          if (detail.post?.ownerId == userId)
            PopupMenuButton<String>(
              tooltip: 'Post actions',
              onSelected: (value) {
                if (value == 'edit') _edit(detail.post!);
                if (value == 'delete') _delete(detail.post!);
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'edit', child: Text('Edit post')),
                PopupMenuItem(value: 'delete', child: Text('Delete post')),
              ],
            ),
        ],
      ),
      body: _body(detail, userId),
    );
  }

  Widget _body(PostDetailProvider detail, String? userId) {
    if (detail.isLoading) {
      return const LoadingView(message: 'Loading post');
    }
    if (detail.error != null && detail.post == null) {
      return ErrorRetryView(message: detail.error!, onRetry: detail.load);
    }
    final post = detail.post;
    if (post == null) {
      return const EmptyView(
        icon: Icons.article_outlined,
        title: 'Post unavailable',
      );
    }

    final isOwner = userId == post.ownerId;
    final claims = context
        .watch<ClaimsProvider>()
        .claims
        .where((claim) => claim.postId == post.id)
        .toList();

    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        _PostHero(post: post),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  TypeBadge(type: post.postType),
                  const SizedBox(width: AppSpacing.sm),
                  _StatusChip(status: post.status),
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
                post.description,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: AppSpacing.xl),
              _InfoRow(
                icon: Icons.category_outlined,
                label: 'Category',
                value: post.category,
              ),
              _InfoRow(
                icon: Icons.location_on_outlined,
                label: 'Location',
                value: post.location,
              ),
              _InfoRow(
                icon: Icons.calendar_today_outlined,
                label: post.postType == PostType.lost
                    ? 'Date lost'
                    : 'Date found',
                value:
                    '${post.eventDate.day}/${post.eventDate.month}/${post.eventDate.year}',
              ),
              _InfoRow(
                icon: Icons.person_outline,
                label: 'Posted by',
                value: isOwner ? '${post.ownerName} (you)' : post.ownerName,
              ),
              _InfoRow(
                icon: Icons.contact_mail_outlined,
                label: 'Preferred contact',
                value: _contactLabel(post.contactPreference),
              ),
              if (detail.error != null) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  detail.error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
              if (!isOwner && userId != null) ...[
                FilledButton.icon(
                  onPressed: detail.isSubmitting
                      ? null
                      : () => _startChat(post),
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: const Text('Message owner'),
                ),
                if (post.postType == PostType.found &&
                    post.status != PostStatus.returned &&
                    post.status != PostStatus.closed) ...[
                  const SizedBox(height: AppSpacing.md),
                  OutlinedButton.icon(
                    onPressed: detail.isSubmitting
                        ? null
                        : () => _showClaimForm(post),
                    icon: const Icon(Icons.assignment_turned_in_outlined),
                    label: const Text('Claim this item'),
                  ),
                ],
              ],
              if (isOwner) ...[
                const Divider(height: AppSpacing.xl * 2),
                Text(
                  'Claim requests',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                _OwnerClaims(
                  claims: claims,
                  busyClaimId: detail.busyClaimId,
                  onResolve: detail.resolveClaim,
                ),
              ] else if (claims.isNotEmpty) ...[
                const Divider(height: AppSpacing.xl * 2),
                _MyClaimStatus(claim: claims.first),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _edit(ItemPost post) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => PostFormScreen(existingPost: post)),
    );
    if (changed == true && mounted) {
      context.read<PostDetailProvider>().load();
    }
  }

  Future<void> _delete(ItemPost post) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete this post?'),
        content: const Text(
          'This removes it from the campus feed and cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final userId = context.read<AuthProvider>().userId;
    if (userId == null) return;
    final deleted = await context.read<PostEditorProvider>().delete(
      post,
      requesterId: userId,
    );
    if (!mounted) return;
    if (deleted) {
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.read<PostEditorProvider>().error ??
                'The post could not be deleted.',
          ),
        ),
      );
    }
  }

  Future<void> _startChat(ItemPost post) async {
    final userId = context.read<AuthProvider>().userId;
    if (userId == null) return;
    final conversation = await context
        .read<PostDetailProvider>()
        .startConversation(userId);
    if (!mounted || conversation == null) return;
    await Navigator.of(context).push(
      ChatScreen.route(
        context,
        conversation: conversation,
        title: post.itemName,
        currentUserId: userId,
      ),
    );
  }

  Future<void> _showClaimForm(ItemPost post) async {
    final userId = context.read<AuthProvider>().userId;
    if (userId == null) return;
    final proof = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _ClaimFormSheet(),
    );
    if (proof == null || !mounted) return;
    final success = await context.read<PostDetailProvider>().submitClaim(
      claimantId: userId,
      proofDescription: proof,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Claim request sent to the finder.'
              : context.read<PostDetailProvider>().error ??
                    'The claim could not be sent.',
        ),
      ),
    );
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
}

class _PostHero extends StatelessWidget {
  final ItemPost post;
  const _PostHero({required this.post});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: 'Photo of ${post.itemName}',
      child: AspectRatio(
        aspectRatio: 4 / 3,
        child: post.imageUrls.isEmpty
            ? Container(
                color: AppColors.placeholder,
                child: const Icon(
                  Icons.image_outlined,
                  size: 64,
                  color: Colors.white,
                ),
              )
            : Image.network(
                post.imageUrls.first,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: AppColors.placeholder,
                  child: const Icon(Icons.broken_image_outlined, size: 64),
                ),
              ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

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
              style: TextStyle(color: Theme.of(context).colorScheme.outline),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final PostStatus status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    return Chip(
      visualDensity: VisualDensity.compact,
      label: Text(_label),
      avatar: Icon(_icon, size: 16),
    );
  }

  String get _label {
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

  IconData get _icon {
    switch (status) {
      case PostStatus.open:
        return Icons.public;
      case PostStatus.possibleMatch:
        return Icons.auto_awesome;
      case PostStatus.claimRequested:
        return Icons.assignment_outlined;
      case PostStatus.returned:
        return Icons.check_circle_outline;
      case PostStatus.closed:
        return Icons.lock_outline;
    }
  }
}

class _ClaimFormSheet extends StatefulWidget {
  const _ClaimFormSheet();

  @override
  State<_ClaimFormSheet> createState() => _ClaimFormSheetState();
}

class _ClaimFormSheetState extends State<_ClaimFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _proof = TextEditingController();

  @override
  void dispose() {
    _proof.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        MediaQuery.viewInsetsOf(context).bottom + AppSpacing.xl,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Prove this item is yours',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Describe a detail that is not obvious in the public post. '
              'Do not include passwords or payment information.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(
              controller: _proof,
              label: 'Identifying detail',
              hint: 'e.g. a sticker, mark, or what is inside',
              icon: Icons.verified_user_outlined,
              minLines: 3,
              maxLines: 5,
              maxLength: 300,
              validator: (value) =>
                  Validators.minLength(value, 10, fieldName: 'Proof'),
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  Navigator.of(context).pop(_proof.text.trim());
                }
              },
              child: const Text('Send claim request'),
            ),
          ],
        ),
      ),
    );
  }
}

class _OwnerClaims extends StatelessWidget {
  final List<ClaimRequest> claims;
  final String? busyClaimId;
  final Future<bool> Function(ClaimRequest, ClaimStatus) onResolve;

  const _OwnerClaims({
    required this.claims,
    required this.busyClaimId,
    required this.onResolve,
  });

  @override
  Widget build(BuildContext context) {
    if (claims.isEmpty) {
      return const Text('No one has claimed this item yet.');
    }
    return Column(
      children: [
        for (final claim in claims)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    claim.proofDescription,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Status: ${claim.status.name}',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  if (claim.status == ClaimStatus.pending) ...[
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: busyClaimId == claim.id
                                ? null
                                : () => onResolve(claim, ClaimStatus.rejected),
                            child: const Text('Reject'),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: FilledButton(
                            onPressed: busyClaimId == claim.id
                                ? null
                                : () => onResolve(claim, ClaimStatus.accepted),
                            child: const Text('Accept'),
                          ),
                        ),
                      ],
                    ),
                  ] else if (claim.status == ClaimStatus.accepted) ...[
                    const SizedBox(height: AppSpacing.md),
                    FilledButton.icon(
                      onPressed: busyClaimId == claim.id
                          ? null
                          : () => onResolve(claim, ClaimStatus.returned),
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('Confirm item returned'),
                    ),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _MyClaimStatus extends StatelessWidget {
  final ClaimRequest claim;
  const _MyClaimStatus({required this.claim});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.assignment_turned_in_outlined),
      title: const Text('Your claim request'),
      subtitle: Text('Status: ${claim.status.name}'),
    );
  }
}
