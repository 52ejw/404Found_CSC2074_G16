import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../core/widgets/post_card.dart';
import '../../core/widgets/state_views.dart';
import '../../providers/feed_provider.dart';
import '../posts/post_details_screen.dart';
import '../posts/post_form_screen.dart';

/// Home / community feed (FR05). Header + promo banner + Lost/Found filter
/// chips + a live list of posts bound to [FeedProvider].
class FeedScreen extends StatelessWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final feed = context.watch<FeedProvider>();
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _PromoBanner(),
          const SizedBox(height: AppSpacing.sm),
          Expanded(child: _FeedBody(feed: feed)),
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
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.xs,
      ),
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
                  const Text(
                    'Lost something on campus?',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.accentText,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Post it in seconds — the campus is looking',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.accentText.withValues(alpha: 0.9),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  FilledButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const PostFormScreen()),
                    ),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 34),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Post now',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.school_outlined,
              size: 40,
              color: Color(0xFFE0A93B),
            ),
          ],
        ),
      ),
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
        icon: Icons.school_outlined,
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
        itemBuilder: (context, i) => PostCard(
          post: feed.posts[i],
          onTap: () => Navigator.of(
            context,
          ).push(PostDetailsScreen.route(context, postId: feed.posts[i].id)),
        ),
      ),
    );
  }
}
