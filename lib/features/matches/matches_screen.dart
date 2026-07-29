import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../core/widgets/state_views.dart';
import '../../models/enums.dart';
import '../../models/item_post.dart';
import '../../models/match_result.dart';
import '../../providers/auth_provider.dart';
import '../../providers/matches_provider.dart';
import '../posts/post_details_screen.dart';

/// Suggested lost/found pairs with an explainable score breakdown (FR09).
class MatchesScreen extends StatefulWidget {
  const MatchesScreen({super.key});

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen> {
  String? _loadedUserId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final userId = context.watch<AuthProvider>().userId;
    if (userId != null && userId != _loadedUserId) {
      _loadedUserId = userId;
      context.read<MatchesProvider>().load(userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MatchesProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Possible matches')),
      body: _body(provider),
    );
  }

  Widget _body(MatchesProvider provider) {
    if (provider.isLoading) {
      return const LoadingView(message: 'Checking possible matches');
    }
    if (provider.error != null && provider.matches.isEmpty) {
      return ErrorRetryView(message: provider.error!, onRetry: provider.retry);
    }
    if (provider.matches.isEmpty) {
      return const EmptyView(
        icon: Icons.auto_awesome_outlined,
        title: 'No matches yet',
        subtitle:
            'Suggestions appear here when a lost and found post share useful details.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        100,
      ),
      itemCount: provider.matches.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) {
        final match = provider.matches[index];
        return _MatchCard(
          match: match,
          lostPost: provider.post(match.lostPostId),
          foundPost: provider.post(match.foundPostId),
          isBusy: provider.busyMatchId == match.id,
          onOpen: (postId) => Navigator.of(
            context,
          ).push(PostDetailsScreen.route(context, postId: postId)),
          onStatus: (status) => provider.updateStatus(match, status),
        );
      },
    );
  }
}

class _MatchCard extends StatelessWidget {
  final MatchResult match;
  final ItemPost? lostPost;
  final ItemPost? foundPost;
  final bool isBusy;
  final ValueChanged<String> onOpen;
  final ValueChanged<MatchStatus> onStatus;

  const _MatchCard({
    required this.match,
    required this.lostPost,
    required this.foundPost,
    required this.isBusy,
    required this.onOpen,
    required this.onStatus,
  });

  @override
  Widget build(BuildContext context) {
    final percent = (match.totalScore * 100).round().clamp(0, 100);
    return Semantics(
      container: true,
      label: '$percent percent match between lost and found posts',
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.auto_awesome, color: AppColors.accent),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    '$percent% match',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Chip(label: Text(_statusLabel(match.status))),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              _PostMatchRow(
                label: 'Lost',
                post: lostPost,
                fallback: 'Lost post unavailable',
                onTap: () => onOpen(match.lostPostId),
              ),
              const Divider(),
              _PostMatchRow(
                label: 'Found',
                post: foundPost,
                fallback: 'Found post unavailable',
                onTap: () => onOpen(match.foundPostId),
              ),
              const SizedBox(height: AppSpacing.md),
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: EdgeInsets.zero,
                title: const Text('Why this matched'),
                children: [
                  _ScoreBar(label: 'Category', value: match.categoryScore),
                  _ScoreBar(label: 'Keywords', value: match.keywordScore),
                  _ScoreBar(label: 'Location', value: match.locationScore),
                  _ScoreBar(label: 'Date', value: match.dateScore),
                ],
              ),
              if (match.status == MatchStatus.suggested) ...[
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: isBusy
                            ? null
                            : () => onStatus(MatchStatus.dismissed),
                        child: const Text('Not a match'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: FilledButton(
                        onPressed: isBusy
                            ? null
                            : () => onStatus(MatchStatus.accepted),
                        child: isBusy
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Looks right'),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _statusLabel(MatchStatus status) {
    switch (status) {
      case MatchStatus.suggested:
        return 'Suggested';
      case MatchStatus.accepted:
        return 'Accepted';
      case MatchStatus.dismissed:
        return 'Dismissed';
    }
  }
}

class _PostMatchRow extends StatelessWidget {
  final String label;
  final ItemPost? post;
  final String fallback;
  final VoidCallback onTap;

  const _PostMatchRow({
    required this.label,
    required this.post,
    required this.fallback,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      onTap: post == null ? null : onTap,
      leading: CircleAvatar(child: Text(label.characters.first)),
      title: Text(post?.itemName ?? fallback),
      subtitle: post == null
          ? null
          : Text('${post!.category} · ${post!.location}'),
      trailing: post == null ? null : const Icon(Icons.chevron_right),
    );
  }
}

class _ScoreBar extends StatelessWidget {
  final String label;
  final double value;

  const _ScoreBar({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final safeValue = value.clamp(0.0, 1.0).toDouble();
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          SizedBox(width: 72, child: Text(label)),
          Expanded(
            child: LinearProgressIndicator(
              value: safeValue,
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          SizedBox(width: 38, child: Text('${(safeValue * 100).round()}%')),
        ],
      ),
    );
  }
}
