import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/constants.dart';
import '../../app/theme.dart';
import '../../core/widgets/post_card.dart';
import '../../core/widgets/state_views.dart';
import '../../models/app_user.dart';
import '../../models/claim_request.dart';
import '../../models/enums.dart';
import '../../models/item_post.dart';
import '../../providers/auth_provider.dart';
import '../../providers/claims_provider.dart';
import '../../providers/profile_provider.dart';
import '../posts/post_details_screen.dart';
import 'edit_profile_screen.dart';
import 'settings_screen.dart';

/// Realtime profile, own posts and claim history (FR02, FR11–FR13).
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  String? _loadedUserId;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final userId = context.watch<AuthProvider>().userId;
    if (userId != null && userId != _loadedUserId) {
      _loadedUserId = userId;
      context.read<ProfileProvider>().load(userId);
      context.read<ClaimsProvider>().load(userId);
    }
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileProvider>();
    final claims = context.watch<ClaimsProvider>();

    if (profile.isLoading) {
      return const Scaffold(body: LoadingView(message: 'Loading profile'));
    }
    if (profile.error != null && profile.user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: ErrorRetryView(message: profile.error!, onRetry: profile.retry),
      );
    }

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverToBoxAdapter(
            child: _ProfileHeader(
              user: profile.user,
              postCount: profile.posts.length,
              claimCount: claims.claims.length,
              onEdit: profile.user == null
                  ? null
                  : () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => EditProfileScreen(user: profile.user!),
                      ),
                    ),
              onSettings: () => Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
            ),
          ),
        ],
        body: Column(
          children: [
            TabBar(
              controller: _tabs,
              labelColor: AppColors.primary,
              indicatorColor: AppColors.accent,
              indicatorWeight: 3,
              tabs: const [
                Tab(text: 'My posts'),
                Tab(text: 'Claims'),
                Tab(text: 'Returned'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabs,
                children: [
                  _PostList(posts: profile.posts),
                  _ClaimsList(claims: claims),
                  _ReturnedList(
                    posts: profile.posts
                        .where((post) => post.status == PostStatus.returned)
                        .toList(),
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
  final AppUser? user;
  final int postCount;
  final int claimCount;
  final VoidCallback? onEdit;
  final VoidCallback onSettings;

  const _ProfileHeader({
    required this.user,
    required this.postCount,
    required this.claimCount,
    required this.onEdit,
    required this.onSettings,
  });

  @override
  Widget build(BuildContext context) {
    final shortId = user?.id.isNotEmpty == true
        ? user!.id.substring(0, user!.id.length.clamp(0, 8)).toUpperCase()
        : '—';
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primaryDark, AppColors.primary],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              Row(
                children: [
                  FilledButton.tonalIcon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Edit profile'),
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Settings',
                    onPressed: onSettings,
                    color: Colors.white,
                    icon: const Icon(Icons.settings_outlined),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Semantics(
                    image: true,
                    label: '${user?.name ?? 'Student'} profile photo',
                    child: CircleAvatar(
                      radius: 38,
                      backgroundColor: Colors.white.withValues(alpha: 0.16),
                      foregroundColor: AppColors.accent,
                      backgroundImage: user?.profileImageUrl == null
                          ? null
                          : NetworkImage(user!.profileImageUrl!),
                      child: user?.profileImageUrl == null
                          ? const Icon(Icons.person, size: 40)
                          : null,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.name.isNotEmpty == true
                              ? user!.name
                              : 'Student',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          user?.faculty?.trim().isNotEmpty == true
                              ? user!.faculty!
                              : AppConstants.universityName,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.78),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Campus ID: $shortId',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.65),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _Stat(value: postCount, label: 'Posts'),
                  _Stat(value: claimCount, label: 'Claims'),
                  _Stat(
                    value: user?.successfulRecoveries ?? 0,
                    label: 'Recovered',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final int value;
  final String label;
  const _Stat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$value $label',
      child: Column(
        children: [
          Text(
            '$value',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            label,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.75)),
          ),
        ],
      ),
    );
  }
}

class _PostList extends StatelessWidget {
  final List<ItemPost> posts;
  const _PostList({required this.posts});

  @override
  Widget build(BuildContext context) {
    if (posts.isEmpty) {
      return const EmptyView(
        icon: Icons.article_outlined,
        title: 'No posts yet',
        subtitle: 'Items you report lost or found will show up here.',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        100,
      ),
      itemCount: posts.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) => PostCard(
        post: posts[index],
        onTap: () => Navigator.of(
          context,
        ).push(PostDetailsScreen.route(context, postId: posts[index].id)),
      ),
    );
  }
}

class _ClaimsList extends StatelessWidget {
  final ClaimsProvider claims;
  const _ClaimsList({required this.claims});

  @override
  Widget build(BuildContext context) {
    if (claims.isLoading) {
      return const LoadingView(message: 'Loading claims');
    }
    if (claims.error != null && claims.claims.isEmpty) {
      return ErrorRetryView(message: claims.error!, onRetry: claims.retry);
    }
    if (claims.claims.isEmpty) {
      return const EmptyView(
        icon: Icons.assignment_turned_in_outlined,
        title: 'No claims',
        subtitle: 'Claims you submit or receive will be tracked here.',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 100),
      itemCount: claims.claims.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final claim = claims.claims[index];
        final isFinder = claim.finderId == context.read<AuthProvider>().userId;
        return _ClaimTile(
          claim: claim,
          isFinder: isFinder,
          isBusy: claims.busyClaimId == claim.id,
          onResolve: (status) => claims.resolve(claim, status),
          onOpen: () => Navigator.of(
            context,
          ).push(PostDetailsScreen.route(context, postId: claim.postId)),
        );
      },
    );
  }
}

class _ClaimTile extends StatelessWidget {
  final ClaimRequest claim;
  final bool isFinder;
  final bool isBusy;
  final ValueChanged<ClaimStatus> onResolve;
  final VoidCallback onOpen;

  const _ClaimTile({
    required this.claim,
    required this.isFinder,
    required this.isBusy,
    required this.onResolve,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      leading: const Icon(Icons.assignment_turned_in_outlined),
      title: Text(isFinder ? 'Claim received' : 'Claim submitted'),
      subtitle: Text('Status: ${claim.status.name}'),
      trailing: const Icon(Icons.expand_more),
      childrenPadding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(claim.proofDescription),
        ),
        const SizedBox(height: AppSpacing.md),
        OutlinedButton(
          onPressed: onOpen,
          child: const Text('View related post'),
        ),
        if (isFinder && claim.status == ClaimStatus.pending)
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: isBusy
                      ? null
                      : () => onResolve(ClaimStatus.rejected),
                  child: const Text('Reject'),
                ),
              ),
              Expanded(
                child: FilledButton(
                  onPressed: isBusy
                      ? null
                      : () => onResolve(ClaimStatus.accepted),
                  child: const Text('Accept'),
                ),
              ),
            ],
          ),
        if (isFinder && claim.status == ClaimStatus.accepted)
          FilledButton.icon(
            onPressed: isBusy ? null : () => onResolve(ClaimStatus.returned),
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('Confirm returned'),
          ),
      ],
    );
  }
}

class _ReturnedList extends StatelessWidget {
  final List<ItemPost> posts;
  const _ReturnedList({required this.posts});

  @override
  Widget build(BuildContext context) {
    if (posts.isEmpty) {
      return const EmptyView(
        icon: Icons.check_circle_outline,
        title: 'Nothing returned yet',
        subtitle: 'Successful handovers are recorded here.',
      );
    }
    return _PostList(posts: posts);
  }
}
