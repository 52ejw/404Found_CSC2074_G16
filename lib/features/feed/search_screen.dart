import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/constants.dart';
import '../../app/theme.dart';
import '../../core/widgets/post_card.dart';
import '../../core/widgets/state_views.dart';
import '../../models/enums.dart';
import '../../providers/feed_provider.dart';

/// Focused search + filter + sort over the shared [FeedProvider] (FR06).
/// Uses the same provider instance as the feed, so filters set here are
/// reflected consistently.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        TextEditingController(text: context.read<FeedProvider>().query);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final feed = context.watch<FeedProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search'),
        leading: const BackButton(),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.sm),
              child: TextField(
                controller: _controller,
                autofocus: true,
                textInputAction: TextInputAction.search,
                onChanged: feed.search,
                decoration: InputDecoration(
                  hintText: 'Search item, place',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: feed.query.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            _controller.clear();
                            feed.search('');
                          },
                        ),
                ),
              ),
            ),
            _TypeChips(feed: feed),
            _CategoryChips(feed: feed),
            _ResultsHeader(count: feed.posts.length),
            Expanded(child: _Results(feed: feed)),
          ],
        ),
      ),
    );
  }
}

class _TypeChips extends StatelessWidget {
  final FeedProvider feed;
  const _TypeChips({required this.feed});

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

    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Wrap(
          children: [
            chip('All', null),
            chip('Lost', PostType.lost),
            chip('Found', PostType.found),
          ],
        ),
      ),
    );
  }
}

class _CategoryChips extends StatelessWidget {
  final FeedProvider feed;
  const _CategoryChips({required this.feed});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 0),
      child: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.xs,
        children: [
          for (final category in AppConstants.categories)
            FilterChip(
              label: Text(category),
              selected: feed.category == category,
              onSelected: (selected) =>
                  feed.setCategory(selected ? category : null),
            ),
        ],
      ),
    );
  }
}

class _ResultsHeader extends StatelessWidget {
  final int count;
  const _ResultsHeader({required this.count});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('$count result${count == 1 ? '' : 's'}',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.outline)),
          Row(
            children: [
              const Icon(Icons.swap_vert, size: 16),
              const SizedBox(width: AppSpacing.xs),
              Text('Newest', style: theme.textTheme.bodySmall),
            ],
          ),
        ],
      ),
    );
  }
}

class _Results extends StatelessWidget {
  final FeedProvider feed;
  const _Results({required this.feed});

  @override
  Widget build(BuildContext context) {
    if (feed.isLoading) return const LoadingView();
    if (feed.error != null) {
      return ErrorRetryView(message: feed.error!, onRetry: feed.retry);
    }
    if (feed.posts.isEmpty) {
      return const EmptyView(
        icon: Icons.search_off,
        title: 'No matching posts',
        subtitle: 'Try a different keyword, category or filter.',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      itemCount: feed.posts.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (_, i) => PostCard(post: feed.posts[i]),
    );
  }
}
