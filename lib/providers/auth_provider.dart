import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/app_user.dart';
import '../repositories/auth_repository.dart';
import '../repositories/user_repository.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

/// ViewModel for authentication (FR01). Owns auth state and the
/// login/register/logout actions, and exposes loading + error so the auth
/// screens stay dumb.
///
/// Depends on the [AuthRepository]/[UserRepository] *interfaces* (not the
/// Firebase classes) so it can be unit-tested with fakes — see blueprint 5.2.
///
/// Note: the Provider/ViewModel layer is Frontend Developer 2's area in the
/// responsibility matrix; this implementation is the agreed contract the feed
/// and auth screens code against, and can be extended by FE2.
class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepository;
  final UserRepository _userRepository;

  AuthProvider({
    required AuthRepository authRepository,
    required UserRepository userRepository,
  })  : _authRepository = authRepository,
        _userRepository = userRepository {
    _sub = _authRepository.authStateChanges().listen(_onAuthChanged);
  }

  StreamSubscription<String?>? _sub;

  AuthStatus _status = AuthStatus.unknown;
  AuthStatus get status => _status;

  String? _userId;
  String? get userId => _userId;

  bool _isSubmitting = false;
  bool get isSubmitting => _isSubmitting;

  String? _error;
  String? get error => _error;

  void _onAuthChanged(String? uid) {
    _userId = uid;
    _status =
        uid == null ? AuthStatus.unauthenticated : AuthStatus.authenticated;
    notifyListeners();
  }

  Future<bool> login({required String email, required String password}) {
    return _run(() => _authRepository.login(email: email, password: password));
  }

  /// Registers, then creates the matching Firestore profile document
  /// (`AuthRepository.register` deliberately doesn't do this itself).
  Future<bool> register({
    required String name,
    required String email,
    required String password,
  }) {
    return _run(() async {
      final uid =
          await _authRepository.register(email: email, password: password);
      await _userRepository.createUserProfile(
        AppUser(
          id: uid,
          name: name.trim(),
          email: email.trim(),
          createdAt: DateTime.now(),
        ),
      );
      return uid;
    });
  }

  Future<void> logout() => _authRepository.logout();

  Future<bool> sendPasswordReset(String email) {
    return _run(() => _authRepository.sendPasswordResetEmail(email));
  }

  void clearError() {
    if (_error != null) {
      _error = null;
      notifyListeners();
    }
  }

  /// Runs an async action while managing [isSubmitting]/[error]. Returns
  /// `true` on success, `false` on failure (with [error] populated).
  Future<bool> _run(Future<Object?> Function() action) async {
    _isSubmitting = true;
    _error = null;
    notifyListeners();
    try {
      await action();
      _isSubmitting = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = _friendly(e);
      _isSubmitting = false;
      notifyListeners();
      return false;
    }
  }

  String _friendly(Object e) {
    final s = e.toString();
    const prefix = 'Exception: ';
    return s.startsWith(prefix) ? s.substring(prefix.length) : s;
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
