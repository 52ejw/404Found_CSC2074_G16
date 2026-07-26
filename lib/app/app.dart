import 'package:flutter/material.dart';

import '../repositories/firestore_post_repository.dart';
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

class _PlaceholderHome extends StatefulWidget {
  const _PlaceholderHome();

  @override
  State<_PlaceholderHome> createState() => _PlaceholderHomeState();
}

class _PlaceholderHomeState extends State<_PlaceholderHome> {
  String _status = 'Checking Firebase connection...';

  @override
  void initState() {
    super.initState();
    _checkFirebaseConnection();
  }

  /// One-shot read against the live `posts` collection. Unauthenticated
  /// reads are rejected by firestore.rules, so a `permission-denied` result
  /// here actually confirms the round trip reached the real project and
  /// rules were evaluated — a generic network/host failure would surface a
  /// different error instead.
  Future<void> _checkFirebaseConnection() async {
    try {
      await FirestorePostRepository().watchFeed(limit: 1).first;
      setState(() => _status = 'Connected to Firebase — read the posts collection successfully.');
    } catch (e) {
      final message = e.toString();
      final reachedFirestore = message.contains('permission-denied');
      setState(() {
        _status = reachedFirestore
            ? 'Connected to Firebase — Firestore reachable, read blocked by '
                'security rules as expected for an unauthenticated user.'
            : 'Firebase connection check failed: $message';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppConstants.appName)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Backend foundation ready: models, repositories and Firebase '
                'services are wired up.\n\nReplace this screen with the real '
                'Splash → Login/Register → Main App Shell navigation.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(_status, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}
