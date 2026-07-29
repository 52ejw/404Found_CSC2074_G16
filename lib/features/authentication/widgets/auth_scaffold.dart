import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../core/widgets/app_logo.dart';
import 'campus_backdrop.dart';

/// Shared visual shell for the auth screens: the illustrated Sunway campus
/// backdrop, the university lockup, and a white rounded card holding the form.
///
/// Keeps [LoginScreen] and [RegisterScreen] visually identical without
/// duplicating the decoration code.
class AuthScaffold extends StatelessWidget {
  /// Big title inside the white card, e.g. "Welcome back".
  final String title;

  /// Optional supporting line under the title.
  final String? subtitle;

  /// Form content rendered inside the card.
  final Widget child;

  /// Shows the rounded "Back" chip in the top-left.
  final bool showBack;

  const AuthScaffold({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.showBack = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final media = MediaQuery.of(context);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Campus header: the illustrated university view with the lockup
          // over it. Sized to the top of the screen only, so the buildings sit
          // directly above the card instead of being hidden behind it.
          Flexible(
            flex: showBack ? 34 : 40,
            child: Stack(
              fit: StackFit.expand,
              children: [
                const CampusBackdrop(),
                SafeArea(
                  bottom: false,
                  child: Column(
                    children: [
                      if (showBack)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: const EdgeInsets.only(
                                left: AppSpacing.lg, top: AppSpacing.sm),
                            child: _BackChip(
                              onTap: () => Navigator.of(context).maybePop(),
                            ),
                          ),
                        ),
                      const Spacer(),
                      const _UniversityLockup(),
                      const Spacer(flex: 2),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // White card — fills the rest of the screen down to the bottom edge
          Flexible(
            flex: showBack ? 66 : 60,
            child: Container(
                    width: double.infinity,
                    transform: Matrix4.translationValues(0, -24, 0),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(32),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x330B2A6B),
                          blurRadius: 24,
                          offset: Offset(0, -6),
                        ),
                      ],
                    ),
                    child: SafeArea(
                      top: false,
                      child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                        AppSpacing.xl,
                        AppSpacing.xl + 24,
                        AppSpacing.xl,
                        AppSpacing.xl + media.viewInsets.bottom,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            title,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (subtitle != null) ...[
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              subtitle!,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.outline,
                              ),
                            ),
                          ],
                          const SizedBox(height: AppSpacing.xl),
                          child,
                        ],
                      ),
                    ),
                  ),
                ),
          ),
        ],
      ),
    );
  }
}

/// "SUNWAY UNIVERSITY / A Class Above" style lockup, rendered in type so it
/// scales cleanly and needs no image asset.
class _UniversityLockup extends StatelessWidget {
  const _UniversityLockup();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 404 brand mark
        const AppWordmark(),
        const SizedBox(height: AppSpacing.md),
        // Host-university pill
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.primaryDark.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            'Sunway University · Lost & Found',
            style: TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ],
    );
  }
}

class _BackChip extends StatelessWidget {
  final VoidCallback onTap;
  const _BackChip({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.18),
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.chevron_left, color: Colors.white, size: 20),
              SizedBox(width: 2),
              Text('Back',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }
}
