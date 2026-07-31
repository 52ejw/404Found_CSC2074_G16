import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/enums.dart';
import '../models/item_post.dart';
import '../repositories/post_repository.dart';

/// Realtime activity displayed on the signed-in user's profile.
class ProfileProvider extends ChangeNotifier {
  ProfileProvider({required PostRepository postRepository})
    : _postRepository = postRepository;

  final PostRepository _postRepository;
  StreamSubscription<List<ItemPost>>? _postsSub;
  String? _userId;

  List<ItemPost> _posts = const [];
  List<ItemPost> get posts => _posts;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  List<ItemPost> get returnedPosts => _posts
      .where(
        (post) =>
            post.status == PostStatus.returned ||
            post.status == PostStatus.closed,
      )
      .toList(growable: false);

  void setUserId(String? userId) {
    if (_userId == userId) return;
    _userId = userId;
    _subscribe();
  }

  void retry() => _subscribe();

  void _subscribe() {
    _postsSub?.cancel();
    _posts = const [];
    _error = null;
    final uid = _userId;
    _isLoading = uid != null;
    notifyListeners();
    if (uid == null) return;

    _postsSub = _postRepository
        .watchUserPosts(uid)
        .listen(
          (posts) {
            _posts = posts;
            _isLoading = false;
            _error = null;
            notifyListeners();
          },
          onError: (Object error) {
            _error = error.toString();
            _isLoading = false;
            notifyListeners();
          },
        );
  }

  @override
  void dispose() {
    _postsSub?.cancel();
    super.dispose();
  }
}
