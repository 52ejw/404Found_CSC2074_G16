import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/constants.dart';
import '../../app/theme.dart';
import '../../core/widgets/post_card.dart';
import '../../core/widgets/state_views.dart';
import '../../models/app_user.dart';
import '../../models/item_post.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import '../matches/matches_screen.dart';
import '../posts/post_details_screen.dart';
import 'edit_profile_screen.dart';
import 'settings_screen.dart';

/// Profile, personal post history, claims and successful returns.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(
      length: 4,
      vsync: this,
      initialIndex: widget.initialTab.clamp(0, 3),
    );
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final profile = context.watch<ProfileProvider>();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _ProfileHeader(
              user: auth.user,
              userId: auth.userId,
              postCount: profile.posts.length,
              onEdit: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const EditProfileScreen()),
              ),
              onSettings: () => Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
            ),
            if (auth.profileError != null)
              Semantics(
                liveRegion: true,
                child: MaterialBanner(
                  content: Text(auth.profileError!),
                  actions: [
                    TextButton(
                      onPressed: auth.retryProfile,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            TabBar(
              controller: _tabs,
              labelPadding: EdgeInsets.zero,
              labelColor: AppColors.primary,
              unselectedLabelColor: Theme.of(context).colorScheme.outline,
              indicatorColor: AppColors.accent,
              tabs: const [
                Tab(text: 'My posts'),
                Tab(text: 'Saved'),
                Tab(text: 'Claims'),
                Tab(text: 'Returned'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabs,
                children: [
                  _PostList(
                    posts: profile.posts,
                    isLoading: profile.isLoading,
                    error: profile.error,
                    onRetry: profile.retry,
                    emptyTitle: 'No posts yet',
                    emptySubtitle:
                        'Items you report lost or found will show up here.',
                  ),
                  const EmptyView(
                    icon: Icons.bookmark_border,
                    title: 'Nothing saved',
                    subtitle:
                        'Bookmark support is not enabled for this project yet.',
                  ),
                  const ClaimsListView(compact: true),
                  _PostList(
                    posts: profile.returnedPosts,
                    isLoading: profile.isLoading,
                    error: profile.error,
                    onRetry: profile.retry,
                    emptyTitle: 'Nothing returned yet',
                    emptySubtitle:
                        'Completed handovers will become part of your record.',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.user,
    required this.userId,
    required this.postCount,
    required this.onEdit,
    required this.onSettings,
  });

  final AppUser? user;
  final String? userId;
  final int postCount;
  final VoidCallback onEdit;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    final name = user?.name.trim().isNotEmpty == true
        ? user!.name
        : 'Campus member';
    final shortId = userId == null || userId!.isEmpty
        ? '—'
        : userId!.substring(0, userId!.length.clamp(0, 8)).toUpperCase();

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primaryDark, AppColors.primary],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Spacer(),
              IconButton(
                tooltip: 'Settings',
                onPressed: onSettings,
                color: Colors.white,
                icon: const Icon(Icons.settings_outlined),
              ),
            ],
          ),
          Row(
            children: [
              _Avatar(user: user),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      user?.faculty?.trim().isNotEmpty == true
                          ? user!.faculty!
                          : AppConstants.universityName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white70),
                    ),
                    Text(
                      'Campus ID $shortId',
                      style: Theme.of(
                        context,
                      ).textTheme.labelSmall?.copyWith(color: Colors.white60),
                    ),
                  ],
                ),
              ),
              OutlinedButton(
                onPressed: onEdit,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white54),
                ),
                child: const Text('Edit'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              _Stat(value: '$postCount', label: 'Posts'),
              _Stat(
                value: '${user?.successfulRecoveries ?? 0}',
                label: 'Recoveries',
              ),
              _Stat(
                value: user?.role.name ?? 'student',
                label: 'Role',
                capitalize: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.user});

  final AppUser? user;

  @override
  Widget build(BuildContext context) {
    final imageUrl = user?.profileImageUrl;
    return Semantics(
      image: true,
      label: 'Profile photo',
      child: CircleAvatar(
        radius: 36,
        backgroundColor: Colors.white24,
        foregroundImage: imageUrl == null || imageUrl.isEmpty
            ? null
            : NetworkImage(imageUrl),
        child: imageUrl == null || imageUrl.isEmpty
            ? const Icon(Icons.person, size: 38, color: AppColors.accent)
            : null,
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.value,
    required this.label,
    this.capitalize = false,
  });

  final String value;
  final String label;
  final bool capitalize;

  @override
  Widget build(BuildContext context) {
    final shownValue = capitalize && value.isNotEmpty
        ? '${value[0].toUpperCase()}${value.substring(1)}'
        : value;
    return Expanded(
      child: Semantics(
        label: '$shownValue $label',
        child: Column(
          children: [
            Text(
              shownValue,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 17,
              ),
            ),
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _PostList extends StatelessWidget {
  const _PostList({
    required this.posts,
    required this.isLoading,
    required this.error,
    required this.onRetry,
    required this.emptyTitle,
    required this.emptySubtitle,
  });

  final List<ItemPost> posts;
  final bool isLoading;
  final String? error;
  final VoidCallback onRetry;
  final String emptyTitle;
  final String emptySubtitle;

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const LoadingView(message: 'Loading your posts…');
    if (error != null) {
      return ErrorRetryView(message: error!, onRetry: onRetry);
    }
    if (posts.isEmpty) {
      return EmptyView(
        icon: Icons.article_outlined,
        title: emptyTitle,
        subtitle: emptySubtitle,
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      itemCount: posts.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final post = posts[index];
        return PostCard(
          post: post,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) =>
                  PostDetailsScreen(postId: post.id, initialPost: post),
            ),
          ),
        );
      },
    );
  }
}
