import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/enums.dart';
import '../models/item_post.dart';
import '../models/match_result.dart';
import '../repositories/match_repository.dart';
import '../repositories/post_repository.dart';

/// ViewModel for explainable match suggestions.
class MatchesProvider extends ChangeNotifier {
  MatchesProvider({
    required MatchRepository matchRepository,
    required PostRepository postRepository,
  }) : _matchRepository = matchRepository,
       _postRepository = postRepository;

  final MatchRepository _matchRepository;
  final PostRepository _postRepository;
  StreamSubscription<List<MatchResult>>? _sub;
  String? _userId;
  bool _isDisposed = false;

  List<MatchResult> _matches = const [];
  List<MatchResult> get matches => _matches;

  /// Matches not yet accepted/dismissed — drives the Matches tab's nav badge.
  int get suggestedCount =>
      _matches.where((match) => match.status == MatchStatus.suggested).length;

  Map<String, ItemPost> _postsById = const {};
  ItemPost? postFor(String postId) => _postsById[postId];

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isUpdating = false;
  bool get isUpdating => _isUpdating;

  String? _error;
  String? get error => _error;

  void setUserId(String? userId) {
    if (_userId == userId) return;
    _userId = userId;
    _subscribe();
  }

  Future<bool> updateStatus(MatchResult match, MatchStatus status) async {
    _isUpdating = true;
    _error = null;
    notifyListeners();
    try {
      await _matchRepository.updateMatchStatus(match.id, status);
      return true;
    } catch (error) {
      _error = error.toString();
      return false;
    } finally {
      _isUpdating = false;
      notifyListeners();
    }
  }

  void retry() => _subscribe();

  void _subscribe() {
    _sub?.cancel();
    _matches = const [];
    _postsById = const {};
    _error = null;
    final uid = _userId;
    _isLoading = uid != null;
    notifyListeners();
    if (uid == null) return;

    _sub = _matchRepository
        .watchMatchesForUser(uid)
        .listen(
          (matches) {
            _matches = matches;
            _isLoading = false;
            _error = null;
            notifyListeners();
            unawaited(_loadPosts(matches));
          },
          onError: (Object error) {
            _error = error.toString();
            _isLoading = false;
            notifyListeners();
          },
        );
  }

  Future<void> _loadPosts(List<MatchResult> matches) async {
    final ids = matches
        .expand((match) => [match.lostPostId, match.foundPostId])
        .toSet();
    final posts = <String, ItemPost>{};
    await Future.wait(
      ids.map((id) async {
        try {
          final post = await _postRepository.getPostById(id);
          if (post != null) posts[id] = post;
        } catch (_) {
          // Keep showing the score even if one referenced post was removed.
        }
      }),
    );
    if (_isDisposed) return;
    _postsById = posts;
    notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _sub?.cancel();
    super.dispose();
  }
}
