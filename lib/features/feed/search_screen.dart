import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/constants.dart';
import '../../app/theme.dart';
import '../../core/widgets/post_card.dart';
import '../../core/widgets/state_views.dart';
import '../../models/enums.dart';
import '../../providers/feed_provider.dart';

/// Advanced search + filter screen (RedNote/Trip style).
/// Vertical collapsible filter panels: Type, Category, Date range, Sort.
/// Results displayed below filters (FR06).
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late final TextEditingController _controller;
  bool _expandType = false;
  bool _expandCategory = false;
  bool _expandDate = false;
  bool _expandSort = false;

  String? _selectedDateRange;

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
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Search'),
        leading: const BackButton(),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // Search input
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

            // Filter panels (scrollable, stacked vertically)
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppSpacing.sm),

                    // Type filter
                    _FilterPanel(
                      title: 'Type',
                      isExpanded: _expandType,
                      onExpandChanged: (v) =>
                          setState(() => _expandType = v),
                      child: Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.xs,
                        children: [
                          FilterChip(
                            label: const Text('All'),
                            selected: feed.typeFilter == null,
                            onSelected: (_) => feed.setType(null),
                          ),
                          FilterChip(
                            label: const Text('Lost'),
                            selected: feed.typeFilter == PostType.lost,
                            onSelected: (_) =>
                                feed.setType(PostType.lost),
                          ),
                          FilterChip(
                            label: const Text('Found'),
                            selected: feed.typeFilter == PostType.found,
                            onSelected: (_) =>
                                feed.setType(PostType.found),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Category filter
                    _FilterPanel(
                      title: 'Category',
                      isExpanded: _expandCategory,
                      onExpandChanged: (v) =>
                          setState(() => _expandCategory = v),
                      child: Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.xs,
                        children: [
                          FilterChip(
                            label: const Text('All'),
                            selected: feed.category == null,
                            onSelected: (_) => feed.setCategory(null),
                          ),
                          for (final cat in AppConstants.categories)
                            FilterChip(
                              label: Text(cat),
                              selected: feed.category == cat,
                              onSelected: (selected) =>
                                  feed.setCategory(selected ? cat : null),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Date range filter
                    _FilterPanel(
                      title: 'Post time',
                      isExpanded: _expandDate,
                      onExpandChanged: (v) =>
                          setState(() => _expandDate = v),
                      child: Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.xs,
                        children: [
                          FilterChip(
                            label: const Text('All'),
                            selected: _selectedDateRange == null,
                            onSelected: (_) =>
                                setState(() => _selectedDateRange = null),
                          ),
                          FilterChip(
                            label: const Text('Past 24 hours'),
                            selected: _selectedDateRange == '1d',
                            onSelected: (_) =>
                                setState(() => _selectedDateRange = '1d'),
                          ),
                          FilterChip(
                            label: const Text('Past week'),
                            selected: _selectedDateRange == '7d',
                            onSelected: (_) =>
                                setState(() => _selectedDateRange = '7d'),
                          ),
                          FilterChip(
                            label: const Text('Past month'),
                            selected: _selectedDateRange == '30d',
                            onSelected: (_) =>
                                setState(() => _selectedDateRange = '30d'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Sort options
                    _FilterPanel(
                      title: 'Sort by',
                      isExpanded: _expandSort,
                      onExpandChanged: (v) =>
                          setState(() => _expandSort = v),
                      child: Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.xs,
                        children: [
                          FilterChip(
                            label: const Text('Newest'),
                            selected: true,
                            onSelected: (_) {},
                          ),
                          FilterChip(
                            label: const Text('Oldest'),
                            selected: false,
                            onSelected: (_) {},
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // Results header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${feed.posts.length} result${feed.posts.length == 1 ? '' : 's'}',
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: theme.colorScheme.outline)),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                ),
              ),
            ),

            // Results list
            Expanded(
              child: _Results(feed: feed),
            ),
          ],
        ),
      ),
    );
  }
}

/// Collapsible filter section with expand/collapse icon
class _FilterPanel extends StatelessWidget {
  final String title;
  final bool isExpanded;
  final ValueChanged<bool> onExpandChanged;
  final Widget child;

  const _FilterPanel({
    required this.title,
    required this.isExpanded,
    required this.onExpandChanged,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => onExpandChanged(!isExpanded),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title,
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w500)),
              Icon(
                isExpanded ? Icons.expand_less : Icons.expand_more,
                color: theme.colorScheme.outline,
              ),
            ],
          ),
        ),
        if (isExpanded) ...[
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ],
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
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, i) => PostCard(post: feed.posts[i]),
    );
  }
}
