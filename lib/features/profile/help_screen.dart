import 'package:flutter/material.dart';

import '../../app/constants.dart';
import '../../app/theme.dart';

/// Static how-it-works and community guidelines page, opened from the app
/// drawer's "Help & guidelines" shortcut.
class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Help & guidelines')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: const [
          _Section(
            title: 'How ${AppConstants.displayName} works',
            items: [
              _HelpItem(
                icon: Icons.edit_note_outlined,
                title: 'Report an item',
                body:
                    'Lost or found something on campus? Tap the + button and fill in '
                    'the item, category, location and date. A clear description '
                    'and a photo make it much easier for the right person to find you.',
              ),
              _HelpItem(
                icon: Icons.auto_awesome_outlined,
                title: 'Check your matches',
                body:
                    'The app automatically compares new posts against opposite '
                    'reports (lost vs. found) by category, keywords, location and '
                    'date, and surfaces likely matches in the Matches tab.',
              ),
              _HelpItem(
                icon: Icons.verified_user_outlined,
                title: 'Submit or resolve a claim',
                body:
                    'Think a found post is yours? Submit a claim with proof it '
                    'belongs to you. The finder can accept or reject it, and mark '
                    'the item returned once it changes hands.',
              ),
              _HelpItem(
                icon: Icons.chat_bubble_outline,
                title: 'Chat privately',
                body:
                    'Message the other student directly through the app to '
                    'confirm details and arrange a handover, without sharing '
                    'personal contact info unless you choose to.',
              ),
            ],
          ),
          SizedBox(height: AppSpacing.lg),
          _Section(
            title: 'Community guidelines',
            items: [
              _HelpItem(
                icon: Icons.fact_check_outlined,
                title: 'Be accurate',
                body:
                    'Only post items you genuinely lost or found. False reports '
                    'and claims waste other students\' time and may be removed.',
              ),
              _HelpItem(
                icon: Icons.privacy_tip_outlined,
                title: 'Protect your privacy',
                body:
                    'Never share passwords, banking details or one-time '
                    'verification codes through chat. The app never asks for these.',
              ),
              _HelpItem(
                icon: Icons.groups_outlined,
                title: 'Meet safely',
                body:
                    'Arrange handovers in a public campus location during daylight '
                    'hours where possible. Bring a friend or loop in campus '
                    'security if you feel unsure about a meetup.',
              ),
            ],
          ),
          SizedBox(height: AppSpacing.lg),
          _Section(
            title: 'Need more help?',
            items: [
              _HelpItem(
                icon: Icons.support_agent_outlined,
                title: 'Contact campus security',
                body:
                    'For urgent, high-value or suspicious items, report to campus '
                    'security or the lost-property counter directly rather than '
                    'relying solely on the app.',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.items});

  final String title;
  final List<_HelpItem> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppSpacing.sm),
        ...items,
      ],
    );
  }
}

class _HelpItem extends StatelessWidget {
  const _HelpItem({required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  body,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
