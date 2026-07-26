import 'package:flutter/material.dart';

import 'constants.dart';
import 'theme.dart';

/// Root widget. Kept deliberately minimal: routing/navigation and the
/// Provider wiring are owned by Frontend Developer 1 (routes/design system)
/// and Frontend Developer 2 (Provider → repository wiring) respectively —
/// see blueprint section 8. This placeholder home screen exists only so the
/// project compiles and runs end-to-end from a fresh clone before those
/// pieces land.
class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      home: const _PlaceholderHome(),
    );
  }
}

class _PlaceholderHome extends StatelessWidget {
  const _PlaceholderHome();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppConstants.appName)),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Backend foundation ready: models, repositories and Firebase '
            'services are wired up.\n\nReplace this screen with the real '
            'Splash → Login/Register → Main App Shell navigation.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
