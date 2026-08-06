import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/app_user.dart';
import '../repositories/auth_repository.dart';
import '../repositories/user_repository.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepository;
  final UserRepository _userRepository;

  AuthProvider({
    required AuthRepository authRepository,
    required UserRepository userRepository,
  }) : _authRepository = authRepository,
       _userRepository = userRepository {
    _sub = _authRepository.authStateChanges().listen(_onAuthChanged);
  }

  StreamSubscription<String?>? _sub;
  StreamSubscription<AppUser?>? _userSub;

  AuthStatus _status = AuthStatus.unknown;
  AuthStatus get status => _status;

  String? _userId;
  String? get userId => _userId;

  AppUser? _user;
  AppUser? get user => _user;

  bool _isProfileLoading = false;
  bool get isProfileLoading => _isProfileLoading;

  String? _profileError;
  String? get profileError => _profileError;

  bool _isSubmitting = false;
  bool get isSubmitting => _isSubmitting;

  String? _error;
  String? get error => _error;

  void _onAuthChanged(String? uid) {
    _userSub?.cancel();
    _userId = uid;
    _user = null;
    _profileError = null;
    _isProfileLoading = uid != null;
    _status = uid == null
        ? AuthStatus.unauthenticated
        : AuthStatus.authenticated;
    notifyListeners();

    if (uid == null) return;
    _watchUser(uid);
  }

  void retryProfile() {
    final uid = _userId;
    if (uid == null) return;
    _userSub?.cancel();
    _isProfileLoading = true;
    _profileError = null;
    notifyListeners();
    _watchUser(uid);
  }

  void _watchUser(String uid) {
    _userSub = _userRepository
        .watchUser(uid)
        .listen(
          (user) {
            _user = user;
            _isProfileLoading = false;
            _profileError = null;
            notifyListeners();
          },
          onError: (Object error) {
            _profileError = _friendly(error);
            _isProfileLoading = false;
            notifyListeners();
          },
        );
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
      final uid = await _authRepository.register(
        email: email,
        password: password,
      );
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

  Future<bool> updateProfile({
    required String name,
    String? faculty,
    String? contact,
    String? profileImageUrl,
  }) {
    final uid = _userId;
    if (uid == null) {
      _error = 'You must be signed in to update your profile.';
      notifyListeners();
      return Future<bool>.value(false);
    }
    return _run(
      () => _userRepository.updateUserProfile(
        uid,
        name: name.trim(),
        faculty: _nullableTrimmed(faculty),
        contact: _nullableTrimmed(contact),
        profileImageUrl: _nullableTrimmed(profileImageUrl),
      ),
    );
  }

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

  String? _nullableTrimmed(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  @override
  void dispose() {
    _sub?.cancel();
    _userSub?.cancel();
    super.dispose();
  }
}
