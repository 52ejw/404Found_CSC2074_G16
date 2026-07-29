import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/constants.dart';
import '../../app/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import 'edit_profile_screen.dart';

/// Account, privacy and support settings.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<ProfileProvider>().user;
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const _SectionTitle('Account'),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Edit profile'),
            subtitle: Text(user?.email ?? 'Update your account details'),
            trailing: const Icon(Icons.chevron_right),
            enabled: user != null,
            onTap: user == null
                ? null
                : () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => EditProfileScreen(user: user),
                    ),
                  ),
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Sign out'),
            onTap: () => _confirmSignOut(context),
          ),
          const Divider(),
          const _SectionTitle('Privacy and safety'),
          const ListTile(
            leading: Icon(Icons.privacy_tip_outlined),
            title: Text('Protect your information'),
            subtitle: Text(
              'Use in-app chat and never share passwords or payment details.',
            ),
          ),
          const ListTile(
            leading: Icon(Icons.groups_outlined),
            title: Text('Safe handovers'),
            subtitle: Text(
              'Meet in a public campus area and bring a friend when possible.',
            ),
          ),
          const Divider(),
          const _SectionTitle('About'),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text(AppConstants.displayName),
            subtitle: Text('Version 1.0.0 · CSC2074 Group 16'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmSignOut(BuildContext context) async {
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
    if (confirmed == true && context.mounted) {
      await context.read<AuthProvider>().logout();
    }
  }
}

class _SectionTitle extends StatelessWidget {
  final String label;
  const _SectionTitle(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
