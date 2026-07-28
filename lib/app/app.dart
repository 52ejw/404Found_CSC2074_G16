import 'package:device_preview/device_preview.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../features/app_shell/main_shell.dart';
import '../features/authentication/login_screen.dart';
import '../features/authentication/splash_screen.dart';
import '../providers/auth_provider.dart';
import '../providers/feed_provider.dart';
import '../repositories/auth_repository.dart';
import '../repositories/firebase_auth_repository.dart';
import '../repositories/firestore_post_repository.dart';
import '../repositories/firestore_user_repository.dart';
import '../repositories/post_repository.dart';
import '../repositories/user_repository.dart';
import 'constants.dart';
import 'theme.dart';

/// Root widget. Wires the Provider layer over the repositories and hosts the
/// auth gate that routes Splash → Login → Landing → Main App Shell (blueprint 4.1).
///
/// Repositories are injectable so widget tests can supply fakes instead of
/// touching Firebase (blueprint 5.2 — testability).
class App extends StatelessWidget {
  final AuthRepository authRepository;
  final UserRepository userRepository;
  final PostRepository postRepository;

  App({
    super.key,
    AuthRepository? authRepository,
    UserRepository? userRepository,
    PostRepository? postRepository,
  })  : authRepository = authRepository ?? FirebaseAuthRepository(),
        userRepository = userRepository ?? FirestoreUserRepository(),
        postRepository = postRepository ?? FirestorePostRepository();

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(
            authRepository: authRepository,
            userRepository: userRepository,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => FeedProvider(postRepository: postRepository),
        ),
      ],
      child: MaterialApp(
        title: AppConstants.displayName,
        debugShowCheckedModeBanner: false,
        // DevicePreview hooks (no-ops in release builds).
        locale: DevicePreview.locale(context),
        builder: DevicePreview.appBuilder,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        // The screens are designed against the light palette (white cards,
        // navy headers). Dark mode is kept as an optional enhancement in the
        // blueprint, so pin the app to light until those styles are tuned.
        themeMode: ThemeMode.light,
        home: const _AuthGate(),
      ),
    );
  }
}

/// Watches [AuthProvider] and shows the right top-level screen for the
/// current auth state. Routes: Splash → Login → Main App Shell.
///
/// There is no separate landing page: after login the user lands straight on
/// the home feed, where [MainShell] runs a step-by-step walkthrough of the
/// navigation on first entry.
class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    final status = context.watch<AuthProvider>().status;

    switch (status) {
      case AuthStatus.unknown:
        return const SplashScreen();

      case AuthStatus.authenticated:
        return const MainShell();

      case AuthStatus.unauthenticated:
        return const LoginScreen();
    }
  }
}
