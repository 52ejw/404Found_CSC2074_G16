import 'package:flutter/material.dart';

import '../../app/constants.dart';
import '../../app/theme.dart';

/// Welcome/landing screen shown immediately after login, before entering the
/// main app shell. Brief onboarding to set the tone and prime the user for
/// the feed experience (like Trip.com's intro screen).
class LandingScreen extends StatefulWidget {
  final VoidCallback onGetStarted;

  const LandingScreen({super.key, required this.onGetStarted});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  bool _showContent = false;

  @override
  void initState() {
    super.initState();
    // Stagger the animation for a smooth reveal
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _showContent = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: AnimatedOpacity(
            opacity: _showContent ? 1 : 0,
            duration: const Duration(milliseconds: 600),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Brand mark
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.travel_explore,
                        size: 40, color: AppColors.primaryDark),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Welcome heading
                  Text(
                    'Welcome to ${AppConstants.displayName}',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Subtitle
                  Text(
                    'Find lost items and reunite belongings with their owners',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge
                        ?.copyWith(color: theme.colorScheme.outline),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Feature highlights
                  _FeatureCard(
                    icon: Icons.search,
                    title: 'Search & filter',
                    description: 'Browse through community posts instantly',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _FeatureCard(
                    icon: Icons.auto_awesome,
                    title: 'Smart matching',
                    description: 'Get suggestions when someone finds your item',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _FeatureCard(
                    icon: Icons.chat_bubble,
                    title: 'Connect safely',
                    description: 'Chat privately before exchanging items',
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // CTA button
                  FilledButton(
                    onPressed: onGetStarted,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                      child: Text('Get started', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 28),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w500)),
                const SizedBox(height: AppSpacing.xs),
                Text(description,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.outline)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
