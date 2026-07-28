import 'package:flutter/material.dart';

import '../../app/constants.dart';
import '../../app/theme.dart';
import '../feed/feed_screen.dart';
import '../feed/search_screen.dart';

/// Main app shell with RedNote-style layout (blueprint 4.1).
///
/// Top bar: Hamburger menu | Title/Tabs | Search icon
/// Bottom nav: Home | Matches | Create Post (large center +) | Messages | Profile
///
/// Frontend Developer 1 owns the shell + Feed tab. Post, Matches and Chats
/// tabs are placeholders that Frontend Developer 2's screens slot into.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;
  int _selectedTab = 0; // 0=Following, 1=Explore, 2=Nearby

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      const FeedScreen(),
      const _ComingSoon(
          icon: Icons.auto_awesome_outlined,
          label: 'Matches',
          owner: 'Frontend 2'),
      const _ComingSoon(
          icon: Icons.add_circle_outline,
          label: 'Create post',
          owner: 'Frontend 2'),
      const _ComingSoon(
          icon: Icons.chat_bubble_outline,
          label: 'Messages',
          owner: 'Frontend 2'),
      const _ComingSoon(
          icon: Icons.person_outline,
          label: 'Profile',
          owner: 'Frontend 2'),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {},
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _TopTab(
              label: 'Following',
              isSelected: _selectedTab == 0,
              onTap: () => setState(() => _selectedTab = 0),
            ),
            const SizedBox(width: AppSpacing.lg),
            _TopTab(
              label: 'Explore',
              isSelected: _selectedTab == 1,
              onTap: () => setState(() => _selectedTab = 1),
            ),
            const SizedBox(width: AppSpacing.lg),
            _TopTab(
              label: 'Nearby',
              isSelected: _selectedTab == 2,
              onTap: () => setState(() => _selectedTab = 2),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SearchScreen()),
            ),
          ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, animation) =>
            FadeTransition(opacity: animation, child: child),
        child: IndexedStack(
          key: ValueKey<int>(_index),
          index: 0,
          children: pages,
        ),
      ),
      extendBody: true,
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.md),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _BottomNavItem(
              icon: Icons.home_outlined,
              label: 'Home',
              isSelected: _index == 0,
              onTap: () => setState(() => _index = 0),
            ),
            _BottomNavItem(
              icon: Icons.auto_awesome_outlined,
              label: 'Matches',
              isSelected: _index == 1,
              onTap: () => setState(() => _index = 1),
            ),
            // Center + button (Create Post)
            GestureDetector(
              onTap: () => setState(() => _index = 2),
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.add,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
            _BottomNavItem(
              icon: Icons.chat_bubble_outline,
              label: 'Messages',
              isSelected: _index == 3,
              onTap: () => setState(() => _index = 3),
            ),
            _BottomNavItem(
              icon: Icons.person_outline,
              label: 'Me',
              isSelected: _index == 4,
              onTap: () => setState(() => _index = 4),
            ),
          ],
        ),
      ),
    );
  }
}

/// Top navigation tab (Following, Explore, Nearby)
class _TopTab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TopTab({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              color: isSelected ? theme.colorScheme.onSurface : theme.colorScheme.outline,
            ),
          ),
          if (isSelected) ...[
            const SizedBox(height: 4),
            Container(
              width: 24,
              height: 2,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Bottom navigation item (icon + label)
class _BottomNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _BottomNavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected ? AppColors.primary : theme.colorScheme.outline,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: isSelected ? AppColors.primary : theme.colorScheme.outline,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

/// Placeholder body for tabs owned by Frontend Developer 2
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
