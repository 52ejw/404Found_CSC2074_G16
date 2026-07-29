import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../core/widgets/coach_marks.dart';
import '../../models/enums.dart';
import '../../providers/feed_provider.dart';
import '../feed/feed_screen.dart';
import '../feed/search_screen.dart';
import '../chat/conversations_screen.dart';
import '../matches/matches_screen.dart';
import '../posts/post_form_screen.dart';
import '../profile/profile_screen.dart';
import 'app_drawer.dart';

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
  int _selectedTab = 0; // 0=All, 1=Lost, 2=Found

  /// First-run walkthrough. Shown once per app launch after the shell has
  /// laid out, so the coach marks can measure their targets.
  bool _showTutorial = false;
  static bool _tutorialSeen = false;

  // Targets highlighted by the walkthrough.
  final _menuKey = GlobalKey();
  final _tabsKey = GlobalKey();
  final _searchKey = GlobalKey();
  final _matchesKey = GlobalKey();
  final _createKey = GlobalKey();
  final _messagesKey = GlobalKey();
  final _meKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    if (_tutorialSeen) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _showTutorial = true);
    });
  }

  void _finishTutorial() {
    _tutorialSeen = true;
    setState(() => _showTutorial = false);
  }

  List<CoachMark> get _coachMarks => [
    CoachMark(
      key: _tabsKey,
      title: 'Browse All, Lost or Found',
      body:
          'Tap a tab to switch the feed between everything, items people '
          'have lost, and items that have been handed in.',
    ),
    CoachMark(
      key: _searchKey,
      circle: true,
      title: 'Search and filter',
      body:
          'Look up an item or a campus spot, then narrow it down by '
          'category, post time and type.',
    ),
    CoachMark(
      key: _createKey,
      circle: true,
      title: 'Post an item',
      body:
          'Lost or found something? Add a photo, category and where it '
          'happened — it appears in the feed straight away.',
    ),
    CoachMark(
      key: _matchesKey,
      title: 'Check your matches',
      body:
          'When a found post looks like your lost item, it shows up here '
          'as a suggested match.',
    ),
    CoachMark(
      key: _messagesKey,
      title: 'Message safely',
      body:
          'Chat privately with the other student to confirm details before '
          'you arrange a handover.',
    ),
    CoachMark(
      key: _meKey,
      title: 'Your account',
      body:
          'Your posts, saved items and sign-out live here. The menu at the '
          'top left has the same shortcuts.',
    ),
    CoachMark(
      key: _menuKey,
      circle: true,
      title: 'The campus menu',
      body:
          'Open this any time for your posts, saved items, notifications '
          'and settings. That is everything — enjoy!',
    ),
  ];

  /// Top tabs double as the feed's Lost/Found filter (FR05).
  void _selectTab(int tab, PostType? type) {
    setState(() => _selectedTab = tab);
    context.read<FeedProvider>().setType(type);
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      const FeedScreen(),
      const MatchesScreen(),
      PostFormScreen(
        onSaved: () {
          context.read<FeedProvider>().retry();
          setState(() => _index = 0);
        },
      ),
      const ConversationsScreen(),
      const ProfileScreen(),
    ];

    // Only the Home tab uses the shell's top bar; the other tabs bring their
    // own AppBar so the header always matches the content.
    final showShellAppBar = _index == 0;

    final shell = Scaffold(
      drawer: const AppDrawer(),
      appBar: !showShellAppBar
          ? null
          : AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: Builder(
                builder: (context) => IconButton(
                  key: _menuKey,
                  icon: const Icon(Icons.menu),
                  tooltip: 'Menu',
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              ),
              title: Row(
                key: _tabsKey,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _TopTab(
                    label: 'All',
                    isSelected: _selectedTab == 0,
                    onTap: () => _selectTab(0, null),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  _TopTab(
                    label: 'Lost',
                    isSelected: _selectedTab == 1,
                    onTap: () => _selectTab(1, PostType.lost),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  _TopTab(
                    label: 'Found',
                    isSelected: _selectedTab == 2,
                    onTap: () => _selectTab(2, PostType.found),
                  ),
                ],
              ),
              centerTitle: true,
              actions: [
                IconButton(
                  key: _searchKey,
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
          index: _index,
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
              key: _matchesKey,
              icon: Icons.auto_awesome_outlined,
              label: 'Matches',
              isSelected: _index == 1,
              onTap: () => setState(() => _index = 1),
            ),
            // Center + button (Create Post)
            Semantics(
              button: true,
              selected: _index == 2,
              label: 'Create post',
              child: GestureDetector(
                key: _createKey,
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
                  child: const Icon(Icons.add, color: Colors.white, size: 28),
                ),
              ),
            ),
            _BottomNavItem(
              key: _messagesKey,
              icon: Icons.chat_bubble_outline,
              label: 'Messages',
              isSelected: _index == 3,
              onTap: () => setState(() => _index = 3),
            ),
            _BottomNavItem(
              key: _meKey,
              icon: Icons.person_outline,
              label: 'Me',
              isSelected: _index == 4,
              onTap: () => setState(() => _index = 4),
            ),
          ],
        ),
      ),
    );

    // The walkthrough floats above the shell so it can spotlight real widgets.
    return Stack(
      children: [
        shell,
        if (_showTutorial)
          CoachMarkOverlay(steps: _coachMarks, onFinish: _finishTutorial),
      ],
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
              color: isSelected
                  ? theme.colorScheme.onSurface
                  : theme.colorScheme.outline,
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
    super.key,
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      selected: isSelected,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: SizedBox(
          width: 56,
          height: 48,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected
                    ? AppColors.primary
                    : theme.colorScheme.outline,
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: isSelected
                      ? AppColors.primary
                      : theme.colorScheme.outline,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
