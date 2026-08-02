import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../core/widgets/state_views.dart';
import '../../models/claim_request.dart';
import '../../models/enums.dart';
import '../../models/item_post.dart';
import '../../models/match_result.dart';
import '../../providers/auth_provider.dart';
import '../../providers/claims_provider.dart';
import '../../providers/matches_provider.dart';
import '../posts/post_details_screen.dart';

/// Combined match suggestions and claim activity destination.
class MatchesScreen extends StatelessWidget {
  const MatchesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Matches & claims'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Matches'),
              Tab(text: 'Claims'),
            ],
          ),
        ),
        body: const TabBarView(children: [_MatchesList(), ClaimsListView()]),
      ),
    );
  }
}

class _MatchesList extends StatelessWidget {
  const _MatchesList();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MatchesProvider>();
    if (provider.isLoading) {
      return const LoadingView(message: 'Looking for possible matches…');
    }
    if (provider.error != null && provider.matches.isEmpty) {
      return ErrorRetryView(message: provider.error!, onRetry: provider.retry);
    }
    if (provider.matches.isEmpty) {
      return const EmptyView(
        icon: Icons.auto_awesome_outlined,
        title: 'No matches yet',
        subtitle:
            'We will compare category, keywords, location and date as new posts arrive.',
      );
    }

    return RefreshIndicator(
      onRefresh: () async => provider.retry(),
      child: ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.lg),
        itemCount: provider.matches.length,
        itemBuilder: (context, index) {
          final match = provider.matches[index];
          return _MatchCard(
            match: match,
            lostPost: provider.postFor(match.lostPostId),
            foundPost: provider.postFor(match.foundPostId),
          );
        },
      ),
    );
  }
}

class _MatchCard extends StatelessWidget {
  const _MatchCard({
    required this.match,
    required this.lostPost,
    required this.foundPost,
  });

  final MatchResult match;
  final ItemPost? lostPost;
  final ItemPost? foundPost;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MatchesProvider>();
    final currentUserId = context.watch<AuthProvider>().userId;
    final userOwnsLost = lostPost != null && lostPost!.ownerId == currentUserId;
    final otherPost = userOwnsLost ? foundPost : lostPost;
    final otherPostLabel = userOwnsLost ? 'View found post' : 'View lost post';
    final percentage = match.totalScore.clamp(0, 100).round();
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome, color: AppColors.accentText),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    '$percentage% match',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                _StatusChip(label: _matchStatusLabel(match.status)),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            LinearProgressIndicator(
              value: (match.totalScore / 100).clamp(0, 1),
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
              semanticsLabel: 'Match confidence',
              semanticsValue: '$percentage percent',
            ),
            const SizedBox(height: AppSpacing.md),
            _PostPairRow(label: 'Lost', post: lostPost),
            const SizedBox(height: AppSpacing.xs),
            _PostPairRow(label: 'Found', post: foundPost),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: [
                _ScoreChip(
                  label: 'Category',
                  score: match.categoryScore,
                  maxScore: 35,
                ),
                _ScoreChip(
                  label: 'Words',
                  score: match.keywordScore,
                  maxScore: 30,
                ),
                _ScoreChip(
                  label: 'Place',
                  score: match.locationScore,
                  maxScore: 20,
                ),
                _ScoreChip(label: 'Date', score: match.dateScore, maxScore: 15),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            if (otherPost != null)
              OutlinedButton.icon(
                onPressed: () => _openPost(context, otherPost),
                icon: const Icon(Icons.visibility_outlined),
                label: Text(otherPostLabel),
              ),
            if (match.status == MatchStatus.suggested)
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: provider.isUpdating
                          ? null
                          : () => provider.updateStatus(
                              match,
                              MatchStatus.dismissed,
                            ),
                      child: const Text('Not a match'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: FilledButton(
                      onPressed: provider.isUpdating
                          ? null
                          : () => provider.updateStatus(
                              match,
                              MatchStatus.accepted,
                            ),
                      child: const Text('Looks right'),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _PostPairRow extends StatelessWidget {
  const _PostPairRow({required this.label, required this.post});

  final String label;
  final ItemPost? post;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 52,
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
        ),
        Expanded(
          child: Text(
            post?.itemName ?? 'Post unavailable',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _ScoreChip extends StatelessWidget {
  const _ScoreChip({
    required this.label,
    required this.score,
    required this.maxScore,
  });

  final String label;
  final double score;
  final double maxScore;

  @override
  Widget build(BuildContext context) {
    final pct = maxScore == 0
        ? 0
        : (score / maxScore * 100).clamp(0, 100).round();
    return Chip(
      visualDensity: VisualDensity.compact,
      label: Text('$label $pct%'),
    );
  }
}

/// Claim list reused by the activity destination and profile screen.
class ClaimsListView extends StatelessWidget {
  const ClaimsListView({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ClaimsProvider>();
    final userId = context.watch<AuthProvider>().userId;
    if (provider.isLoading) {
      return const LoadingView(message: 'Loading claims…');
    }
    if (provider.error != null && provider.claims.isEmpty) {
      return ErrorRetryView(message: provider.error!, onRetry: provider.retry);
    }
    if (provider.claims.isEmpty) {
      return const EmptyView(
        icon: Icons.assignment_turned_in_outlined,
        title: 'No claims yet',
        subtitle:
            'Claims you submit or receive will appear here with their status.',
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(compact ? AppSpacing.sm : AppSpacing.lg),
      itemCount: provider.claims.length,
      itemBuilder: (context, index) {
        final claim = provider.claims[index];
        return _ClaimCard(
          claim: claim,
          post: provider.postFor(claim.postId),
          isIncoming: claim.finderId == userId,
        );
      },
    );
  }
}

class _ClaimCard extends StatelessWidget {
  const _ClaimCard({
    required this.claim,
    required this.post,
    required this.isIncoming,
  });

  final ClaimRequest claim;
  final ItemPost? post;
  final bool isIncoming;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ClaimsProvider>();
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    post?.itemName ?? 'Item post',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                _StatusChip(label: _claimStatusLabel(claim.status)),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              isIncoming ? 'Claim received' : 'Claim submitted',
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(color: AppColors.primary),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              claim.proofDescription,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
            if (post != null) ...[
              const SizedBox(height: AppSpacing.md),
              TextButton.icon(
                onPressed: () => _openPost(context, post!),
                icon: const Icon(Icons.visibility_outlined),
                label: const Text('View post'),
              ),
            ],
            if (isIncoming && claim.status == ClaimStatus.pending) ...[
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: provider.isSubmitting
                          ? null
                          : () => provider.resolveClaim(
                              claim,
                              ClaimStatus.rejected,
                            ),
                      child: const Text('Reject'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: FilledButton(
                      onPressed: provider.isSubmitting
                          ? null
                          : () => provider.resolveClaim(
                              claim,
                              ClaimStatus.accepted,
                            ),
                      child: const Text('Accept'),
                    ),
                  ),
                ],
              ),
            ],
            if (isIncoming && claim.status == ClaimStatus.accepted) ...[
              const SizedBox(height: AppSpacing.sm),
              FilledButton.icon(
                onPressed: provider.isSubmitting
                    ? null
                    : () => provider.resolveClaim(claim, ClaimStatus.returned),
                icon: const Icon(Icons.handshake_outlined),
                label: const Text('Mark item returned'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.accentSoft,
        borderRadius: BorderRadius.circular(AppSpacing.controlRadius),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: AppColors.accentText,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

void _openPost(BuildContext context, ItemPost post) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => PostDetailsScreen(postId: post.id, initialPost: post),
    ),
  );
}

String _matchStatusLabel(MatchStatus status) {
  switch (status) {
    case MatchStatus.suggested:
      return 'Suggested';
    case MatchStatus.accepted:
      return 'Accepted';
    case MatchStatus.dismissed:
      return 'Dismissed';
  }
}

String _claimStatusLabel(ClaimStatus status) {
  switch (status) {
    case ClaimStatus.pending:
      return 'Pending';
    case ClaimStatus.accepted:
      return 'Accepted';
    case ClaimStatus.rejected:
      return 'Rejected';
    case ClaimStatus.returned:
      return 'Returned';
  }
}
