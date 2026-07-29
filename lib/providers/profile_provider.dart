import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/app_user.dart';
import '../models/item_post.dart';
import '../repositories/post_repository.dart';
import '../repositories/user_repository.dart';

/// Realtime profile and post-history state used by Profile and Settings.
class ProfileProvider extends ChangeNotifier {
  final UserRepository _userRepository;
  final PostRepository _postRepository;

  ProfileProvider({
    required UserRepository userRepository,
    required PostRepository postRepository,
  }) : _userRepository = userRepository,
       _postRepository = postRepository;

  StreamSubscription<AppUser?>? _userSub;
  StreamSubscription<List<ItemPost>>? _postSub;
  String? _userId;

  AppUser? _user;
  AppUser? get user => _user;

  List<ItemPost> _posts = const [];
  List<ItemPost> get posts => _posts;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  bool _isSaving = false;
  bool get isSaving => _isSaving;

  String? _error;
  String? get error => _error;

  void load(String userId) {
    if (_userId == userId) return;
    _userId = userId;
    _userSub?.cancel();
    _postSub?.cancel();
    _isLoading = true;
    _error = null;
    notifyListeners();

    var userReady = false;
    var postsReady = false;
    void ready() {
      _isLoading = !(userReady && postsReady);
      notifyListeners();
    }

    _userSub = _userRepository.watchUser(userId).listen((user) {
      _user = user;
      userReady = true;
      ready();
    }, onError: _handleError);
    _postSub = _postRepository.watchUserPosts(userId).listen((posts) {
      _posts = posts;
      postsReady = true;
      ready();
    }, onError: _handleError);
  }

  Future<bool> updateProfile({
    required String name,
    String? faculty,
    String? contact,
    String? profileImageUrl,
  }) async {
    final userId = _userId;
    if (userId == null) return false;
    _isSaving = true;
    _error = null;
    notifyListeners();
    try {
      await _userRepository.updateUserProfile(
        userId,
        name: name.trim(),
        faculty: faculty?.trim(),
        contact: contact?.trim(),
        profileImageUrl: profileImageUrl,
      );
      return true;
    } catch (e) {
      _error = _friendly(e);
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  void retry() {
    final userId = _userId;
    _userId = null;
    if (userId != null) load(userId);
  }

  void _handleError(Object error) {
    _error = _friendly(error);
    _isLoading = false;
    notifyListeners();
  }

  String _friendly(Object error) {
    final message = error.toString();
    return message.startsWith('Exception: ')
        ? message.substring('Exception: '.length)
        : message;
  }

  @override
  void dispose() {
    _userSub?.cancel();
    _postSub?.cancel();
    super.dispose();
  }
}
