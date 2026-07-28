import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../feed/feed_screen.dart';

/// Main app shell with the 5-tab bottom navigation (blueprint 4.1).
///
/// Frontend Developer 1 owns the shell + the Feed tab. The Post, Matches and
/// Chats tabs are placeholders that Frontend Developer 2's screens slot into;
/// [IndexedStack] keeps each tab's state alive when switching.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      const FeedScreen(),
      const _ComingSoon(
          icon: Icons.add_circle_outline,
          label: 'Create post',
          owner: 'Frontend 2'),
      const _ComingSoon(
          icon: Icons.auto_awesome_outlined,
          label: 'Matches',
          owner: 'Frontend 2'),
      const _ComingSoon(
          icon: Icons.chat_bubble_outline,
          label: 'Chats',
          owner: 'Frontend 2'),
      const _ComingSoon(
          icon: Icons.person_outline,
          label: 'Profile',
          owner: 'Frontend 2'),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Feed'),
          NavigationDestination(
              icon: Icon(Icons.add_circle_outline), label: 'Post'),
          NavigationDestination(
              icon: Icon(Icons.auto_awesome_outlined), label: 'Matches'),
          NavigationDestination(
              icon: Icon(Icons.chat_bubble_outline), label: 'Chats'),
          NavigationDestination(
              icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }
}

/// Placeholder body for tabs owned by Frontend Developer 2, so the shell and
/// navigation are demoable before those features land.
class _ComingSoon extends StatelessWidget {
  final IconData icon;
  final String label;
  final String owner;

  const _ComingSoon({
    required this.icon,
    required this.label,
    required this.owner,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(label)),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: AppColors.placeholder),
            const SizedBox(height: AppSpacing.md),
            Text('$label — coming soon',
                style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            Text('Owned by $owner',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.outline)),
          ],
        ),
      ),
    );
  }
}
