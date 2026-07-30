import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/constants.dart';
import '../../app/theme.dart';
import '../../core/widgets/app_logo.dart';
import '../../providers/auth_provider.dart';
import '../matches/matches_screen.dart';
import '../profile/profile_screen.dart';
import '../profile/settings_screen.dart';

/// Side menu opened from the hamburger icon in [MainShell]'s top bar.
/// Gives quick access to the user's own activity, saved items and settings,
/// plus sign-out. Destinations owned by other developers are stubbed for now.
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthProvider>();

    void soon(String label) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$label — coming soon')));
    }

    void open(Widget screen) {
      Navigator.of(context).pop();
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
    }

    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Account header on the Sunway navy banner
            Container(
              color: AppColors.primary,
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  const AppLogo(size: 52),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppConstants.displayName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          AppConstants.universityName,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.75),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          auth.user?.name ??
                              (auth.userId == null ? 'Guest' : 'Signed in'),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppColors.accent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Main destinations
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                children: [
                  _DrawerItem(
                    icon: Icons.article_outlined,
                    label: 'My posts',
                    subtitle: 'Items you reported lost or found',
                    onTap: () => open(const ProfileScreen()),
                  ),
                  _DrawerItem(
                    icon: Icons.bookmark_border,
                    label: 'Saved items',
                    subtitle: 'Posts you bookmarked',
                    onTap: () => soon('Saved items'),
                  ),
                  _DrawerItem(
                    icon: Icons.auto_awesome_outlined,
                    label: 'My matches',
                    subtitle: 'Possible matches for your items',
                    onTap: () => open(const MatchesScreen()),
                  ),
                  _DrawerItem(
                    icon: Icons.drafts_outlined,
                    label: 'Drafts',
                    subtitle: 'Posts you started but never published',
                    onTap: () => soon('Drafts'),
                  ),
                  _DrawerItem(
                    icon: Icons.check_circle_outline,
                    label: 'Resolved',
                    subtitle: 'Items already returned',
                    onTap: () => open(const ProfileScreen(initialTab: 3)),
                  ),
                  const Divider(height: AppSpacing.xl),
                  _DrawerItem(
                    icon: Icons.settings_outlined,
                    label: 'Settings',
                    onTap: () => open(const SettingsScreen()),
                  ),
                  _DrawerItem(
                    icon: Icons.help_outline,
                    label: 'Help & guidelines',
                    onTap: () => soon('Help & guidelines'),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),
            _DrawerItem(
              icon: Icons.logout,
              label: 'Sign out',
              danger: true,
              onTap: () async {
                Navigator.of(context).pop();
                await context.read<AuthProvider>().logout();
              },
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final bool danger;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.subtitle,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = danger
        ? theme.colorScheme.error
        : theme.colorScheme.onSurface;
    return ListTile(
      leading: Icon(
        icon,
        color: danger ? theme.colorScheme.error : AppColors.primary,
      ),
      title: Text(
        label,
        style: theme.textTheme.bodyLarge?.copyWith(
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: subtitle == null
          ? null
          : Text(
              subtitle!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
      onTap: onTap,
    );
  }
}
