import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/constants.dart';
import '../../app/theme.dart';
import '../../core/widgets/state_views.dart';
import '../../providers/auth_provider.dart';

/// "Me" tab — profile header, activity counts, quick actions and the user's
/// own content split across tabs (FR02).
///
/// Layout follows the social-app pattern the team picked: a coloured header
/// with the avatar and stats, a row of quick-action cards, then a tab bar over
/// the user's posts. Content sections are stubbed until the post-history
/// queries land.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  void _soon(String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label — coming soon')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverToBoxAdapter(
            child: _ProfileHeader(
              userId: auth.userId,
              onEdit: () => _soon('Edit profile'),
              onSignOut: () => _confirmSignOut(context),
              onQuickAction: _soon,
            ),
          ),
        ],
        body: Column(
          children: [
            // Content tabs
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                border: Border(
                  bottom: BorderSide(
                      color: AppColors.placeholder.withValues(alpha: 0.5)),
                ),
              ),
              child: TabBar(
                controller: _tabs,
                // Four fixed tabs share the width evenly.
                isScrollable: false,
                labelPadding: EdgeInsets.zero,
                labelColor: AppColors.primary,
                unselectedLabelColor: Theme.of(context).colorScheme.outline,
                indicatorColor: AppColors.accent,
                indicatorWeight: 3,
                labelStyle: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600),
                tabs: const [
                  Tab(text: 'My posts'),
                  Tab(text: 'Saved'),
                  Tab(text: 'Claims'),
                  Tab(text: 'Returned'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabs,
                children: const [
                  _TabEmpty(
                    icon: Icons.article_outlined,
                    title: 'No posts yet',
                    subtitle:
                        'Items you report lost or found will show up here.',
                  ),
                  _TabEmpty(
                    icon: Icons.bookmark_border,
                    title: 'Nothing saved',
                    subtitle:
                        'Bookmark a post from the feed to keep an eye on it.',
                  ),
                  _TabEmpty(
                    icon: Icons.assignment_turned_in_outlined,
                    title: 'No claims',
                    subtitle:
                        'Claims you submit or receive will be tracked here.',
                  ),
                  _TabEmpty(
                    icon: Icons.check_circle_outline,
                    title: 'Nothing returned yet',
                    subtitle:
                        'Successful handovers get recorded here as your record.',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Confirms, then signs out. The auth gate in `app.dart` reacts to the
  /// auth-state change and routes back to the login screen automatically.
  Future<void> _confirmSignOut(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text('You will need to log in again to post or chat.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await auth.logout();
    }
  }
}

/// Navy gradient header: actions, avatar, campus ID, counts, bio and the
/// quick-action cards.
class _ProfileHeader extends StatelessWidget {
  final String? userId;
  final VoidCallback onEdit;
  final VoidCallback onSignOut;
  final void Function(String) onQuickAction;

  const _ProfileHeader({
    required this.userId,
    required this.onEdit,
    required this.onSignOut,
    required this.onQuickAction,
  });

  @override
  Widget build(BuildContext context) {
    final shortId = (userId == null || userId!.isEmpty)
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
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top action row
              Row(
                children: [
                  _HeaderChip(label: 'Edit profile', icon: Icons.edit_outlined, onTap: onEdit),
                  const Spacer(),
                  _HeaderIcon(
                      icon: Icons.settings_outlined,
                      tooltip: 'Settings',
                      onTap: () => onQuickAction('Settings')),
                  const SizedBox(width: AppSpacing.sm),
                  _HeaderIcon(
                      icon: Icons.logout,
                      tooltip: 'Sign out',
                      onTap: onSignOut),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              // Avatar + identity
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.accent, width: 2),
                    ),
                    child: const Icon(Icons.person,
                        size: 40, color: AppColors.accent),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: AppSpacing.xs),
                        const Text(
                          'Student',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        _MetaLine(label: 'Campus ID', value: shortId),
                        const SizedBox(height: 2),
                        _MetaLine(
                            label: 'Campus',
                            value: AppConstants.universityName),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              // Counts
              Row(
                children: [
                  _Stat(value: '0', label: 'Posts'),
                  const SizedBox(width: AppSpacing.xl),
                  _Stat(value: '0', label: 'Matches'),
                  const SizedBox(width: AppSpacing.xl),
                  _Stat(value: '0', label: 'Returned'),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              // Bio
              InkWell(
                onTap: () => onQuickAction('Bio'),
                child: Text(
                  'Tap here to add a note for people who find your things',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetaLine extends StatelessWidget {
  final String label;
  final String value;
  const _MetaLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text('$label: ',
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6), fontSize: 12)),
        Flexible(
          child: Text(
            value,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  final String value;
  final String label;
  const _Stat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 19,
                fontWeight: FontWeight.w700,
                height: 1.1)),
        const SizedBox(width: 5),
        Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: Text(label,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.75), fontSize: 13)),
        ),
      ],
    );
  }
}

class _HeaderChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _HeaderChip(
      {required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.16),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: Colors.white),
              const SizedBox(width: 6),
              Text(label,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderIcon extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  const _HeaderIcon(
      {required this.icon, required this.tooltip, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      tooltip: tooltip,
      icon: Icon(icon, color: Colors.white, size: 21),
      style: IconButton.styleFrom(
        backgroundColor: Colors.white.withValues(alpha: 0.12),
        minimumSize: const Size(36, 36),
        padding: EdgeInsets.zero,
      ),
    );
  }
}

class _TabEmpty extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _TabEmpty({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return EmptyView(icon: icon, title: title, subtitle: subtitle);
  }
}
