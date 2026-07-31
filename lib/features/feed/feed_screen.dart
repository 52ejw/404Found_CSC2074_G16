import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../core/widgets/post_card.dart';
import '../../core/widgets/post_grid_card.dart';
import '../../core/widgets/state_views.dart';
import '../../models/item_post.dart';
import '../../providers/feed_provider.dart';
import '../posts/post_details_screen.dart';

/// Home / community feed (FR05). Header + promo banner + Lost/Found filter
/// chips + a live list/grid of posts bound to [FeedProvider]. Layout (list
/// vs. grid) is a local UI preference, not part of feed state.
class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key, this.onCreatePost});

  final VoidCallback? onCreatePost;

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  bool _isGridView = false;

  @override
  Widget build(BuildContext context) {
    final feed = context.watch<FeedProvider>();
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PromoBanner(onCreatePost: widget.onCreatePost),
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.xs, AppSpacing.lg, 0),
            child: Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                onPressed: () => setState(() => _isGridView = !_isGridView),
                icon: Icon(_isGridView ? Icons.view_list_outlined : Icons.grid_view_outlined),
                tooltip: _isGridView ? 'Switch to list view' : 'Switch to grid view',
              ),
            ),
          ),
          Expanded(child: _FeedBody(feed: feed, isGridView: _isGridView)),
        ],
      ),
    );
  }
}

class _PromoBanner extends StatelessWidget {
  const _PromoBanner({this.onCreatePost});

  final VoidCallback? onCreatePost;

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
                    onPressed: onCreatePost,
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
  final bool isGridView;
  const _FeedBody({required this.feed, required this.isGridView});

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
      child: isGridView ? _buildGrid(context) : _buildList(context),
    );
  }

  Widget _buildList(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      itemCount: feed.posts.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, i) {
        final post = feed.posts[i];
        return PostCard(post: post, onTap: () => _openDetails(context, post));
      },
    );
  }

  Widget _buildGrid(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(AppSpacing.lg),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: AppSpacing.md,
        mainAxisSpacing: AppSpacing.md,
        childAspectRatio: 0.72,
      ),
      itemCount: feed.posts.length,
      itemBuilder: (context, i) {
        final post = feed.posts[i];
        return PostGridCard(post: post, onTap: () => _openDetails(context, post));
      },
    );
  }

  void _openDetails(BuildContext context, ItemPost post) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PostDetailsScreen(postId: post.id, initialPost: post),
      ),
    );
  }
}
