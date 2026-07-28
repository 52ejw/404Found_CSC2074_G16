import 'package:flutter/material.dart';

import '../../app/constants.dart';
import '../../app/theme.dart';

/// Shown while [AuthProvider] is still resolving the initial auth state
/// (blueprint 4.2 — Splash checks authentication and routes on).
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(Icons.travel_explore,
                  size: 36, color: AppColors.primaryDark),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(AppConstants.displayName, style: theme.textTheme.headlineSmall),
            const SizedBox(height: AppSpacing.xl),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
