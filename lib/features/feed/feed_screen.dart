import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/constants.dart';
import '../../app/theme.dart';
import '../../core/widgets/post_card.dart';
import '../../core/widgets/state_views.dart';
import '../../models/enums.dart';
import '../../providers/feed_provider.dart';
import 'search_screen.dart';

/// Home / community feed (FR05). Header + promo banner + Lost/Found filter
/// chips + a live list of posts bound to [FeedProvider].
class FeedScreen extends StatelessWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final feed = context.watch<FeedProvider>();
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _Header(),
            _SearchBar(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SearchScreen()),
              ),
            ),
            const _PromoBanner(),
            _TypeFilter(feed: feed),
            Expanded(child: _FeedBody(feed: feed)),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.sm),
      child: Row(
        children: [
          const Icon(Icons.menu),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppConstants.displayName,
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w500)),
                Text('Find what you lost',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.outline)),
              ],
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_none),
            tooltip: 'Notifications',
          ),
        ],
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final VoidCallback onTap;
  const _SearchBar({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
              child: Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                  border: Border.all(color: AppColors.placeholder),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search, size: 20),
                    const SizedBox(width: AppSpacing.sm),
                    Text('Search item, place',
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.outline)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
              ),
              child: const Icon(Icons.tune, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

class _PromoBanner extends StatelessWidget {
  const _PromoBanner();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xs),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.accentSoft,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Lost something?',
                      style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: AppColors.accentText)),
                  const SizedBox(height: 2),
                  Text('Post it in seconds',
                      style: TextStyle(
                          fontSize: 12,
                          color: AppColors.accentText.withValues(alpha: 0.9))),
                  const SizedBox(height: AppSpacing.sm),
                  FilledButton(
                    onPressed: () {},
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 34),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Post now',
                        style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ),
            const Icon(Icons.search, size: 40, color: Color(0xFFE6C34D)),
          ],
        ),
      ),
    );
  }
}

class _TypeFilter extends StatelessWidget {
  final FeedProvider feed;
  const _TypeFilter({required this.feed});

  @override
  Widget build(BuildContext context) {
    Widget chip(String label, PostType? value) => Padding(
          padding: const EdgeInsets.only(right: AppSpacing.sm),
          child: ChoiceChip(
            label: Text(label),
            selected: feed.typeFilter == value,
            onSelected: (_) => feed.setType(value),
          ),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xs),
          child: Text('Recent posts',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w500)),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Row(
            children: [
              chip('All', null),
              chip('Lost', PostType.lost),
              chip('Found', PostType.found),
            ],
          ),
        ),
      ],
    );
  }
}

class _FeedBody extends StatelessWidget {
  final FeedProvider feed;
  const _FeedBody({required this.feed});

  @override
  Widget build(BuildContext context) {
    if (feed.isLoading) return const LoadingView();
    if (feed.error != null) {
      return ErrorRetryView(message: feed.error!, onRetry: feed.retry);
    }
    if (feed.posts.isEmpty) {
      return EmptyView(
        icon: Icons.travel_explore,
        title: feed.hasActiveFilters ? 'No posts match' : 'No posts yet',
        subtitle: feed.hasActiveFilters
            ? 'Try clearing the filters.'
            : 'Lost or found something? Be the first to post it.',
        action: feed.hasActiveFilters
            ? OutlinedButton(
                onPressed: feed.clearFilters,
                child: const Text('Clear filters'),
              )
            : null,
      );
    }
    return RefreshIndicator(
      onRefresh: () async => feed.retry(),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        itemCount: feed.posts.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (_, i) => PostCard(post: feed.posts[i]),
      ),
    );
  }
}
