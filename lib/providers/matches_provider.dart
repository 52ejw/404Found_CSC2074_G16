import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/enums.dart';
import '../models/item_post.dart';
import '../models/match_result.dart';
import '../repositories/match_repository.dart';
import '../repositories/post_repository.dart';

/// Realtime suggested matches with their lost/found post summaries.
class MatchesProvider extends ChangeNotifier {
  final MatchRepository _matchRepository;
  final PostRepository _postRepository;

  MatchesProvider({
    required MatchRepository matchRepository,
    required PostRepository postRepository,
  }) : _matchRepository = matchRepository,
       _postRepository = postRepository;

  StreamSubscription<List<MatchResult>>? _sub;
  String? _userId;

  List<MatchResult> _matches = const [];
  List<MatchResult> get matches => _matches;

  final Map<String, ItemPost?> _posts = {};
  ItemPost? post(String postId) => _posts[postId];

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  String? _busyMatchId;
  String? get busyMatchId => _busyMatchId;

  String? _error;
  String? get error => _error;

  void load(String userId) {
    if (_userId == userId) return;
    _userId = userId;
    _sub?.cancel();
    _isLoading = true;
    _error = null;
    notifyListeners();
    _sub = _matchRepository
        .watchMatchesForUser(userId)
        .listen(
          (matches) async {
            _matches = matches;
            _isLoading = false;
            _error = null;
            notifyListeners();
            await _loadPosts(matches);
          },
          onError: (Object error) {
            _error = _friendly(error);
            _isLoading = false;
            notifyListeners();
          },
        );
  }

  Future<bool> updateStatus(MatchResult match, MatchStatus status) async {
    _busyMatchId = match.id;
    _error = null;
    notifyListeners();
    try {
      await _matchRepository.updateMatchStatus(match.id, status);
      return true;
    } catch (e) {
      _error = _friendly(e);
      return false;
    } finally {
      _busyMatchId = null;
      notifyListeners();
    }
  }

  Future<void> _loadPosts(List<MatchResult> matches) async {
    final ids = <String>{
      for (final match in matches) match.lostPostId,
      for (final match in matches) match.foundPostId,
    }.where((id) => !_posts.containsKey(id)).toList();
    for (final id in ids) {
      try {
        _posts[id] = await _postRepository.getPostById(id);
      } catch (_) {
        _posts[id] = null;
      }
    }
    notifyListeners();
  }

  void retry() {
    final userId = _userId;
    _userId = null;
    if (userId != null) load(userId);
  }

  String _friendly(Object error) {
    final message = error.toString();
    return message.startsWith('Exception: ')
        ? message.substring('Exception: '.length)
        : message;
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
