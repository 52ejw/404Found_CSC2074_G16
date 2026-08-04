import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/utils/search_keywords.dart';
import '../models/enums.dart';
import '../models/item_post.dart';
import '../repositories/post_repository.dart';

/// ViewModel for the community feed (FR05/FR06). Subscribes to
/// `PostRepository.watchFeed` and re-subscribes whenever the type filter,
/// category or search query changes, exposing loading/empty/error state to
/// the feed and search screens.
///
/// Part of Frontend Developer 2's Provider layer; this is the agreed contract
/// Frontend 1's feed screen is built against.
class FeedProvider extends ChangeNotifier {
  final PostRepository _postRepository;

  FeedProvider({required PostRepository postRepository})
      : _postRepository = postRepository {
    _subscribe();
  }

  StreamSubscription<List<ItemPost>>? _sub;

  List<ItemPost> _posts = const [];
  List<ItemPost> get posts => _posts;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  PostType? _type;
  PostType? get typeFilter => _type;

  String? _category;
  String? get category => _category;

  String _query = '';
  String get query => _query;

  /// Newest-first by default (FR06). Sorting is applied after the stream
  /// arrives rather than in the query, so it needs no extra Firestore index.
  bool _newestFirst = true;
  bool get newestFirst => _newestFirst;

  /// Optional "posted within the last N days" filter. Null means any date.
  int? _withinDays;
  int? get withinDays => _withinDays;

  bool get hasActiveFilters =>
      _type != null ||
      _category != null ||
      _withinDays != null ||
      _query.trim().isNotEmpty;

  void setSort({required bool newestFirst}) {
    if (_newestFirst == newestFirst) return;
    _newestFirst = newestFirst;
    _applyView();
  }

  void setWithinDays(int? days) {
    if (_withinDays == days) return;
    _withinDays = days;
    _applyView();
  }

  void setType(PostType? type) {
    if (_type == type) return;
    _type = type;
    _subscribe();
  }

  void setCategory(String? category) {
    final normalized =
        (category == null || category.isEmpty) ? null : category;
    if (_category == normalized) return;
    _category = normalized;
    _subscribe();
  }

  void search(String text) {
    if (_query == text) return;
    _query = text;
    _subscribe();
  }

  void clearFilters() {
    if (!hasActiveFilters) return;
    _type = null;
    _category = null;
    _withinDays = null;
    _query = '';
    _subscribe();
  }

  void retry() => _subscribe();

  /// Unfiltered results straight from the repository. The date filter and
  /// sort are applied on top of this, so changing either does not need a new
  /// database query.
  List<ItemPost> _raw = const [];

  /// Rebuilds [posts] from [_raw] using the current date filter and sort.
  void _applyView({bool notify = true}) {
    var view = _raw;

    if (_withinDays != null) {
      final cutoff = DateTime.now().subtract(Duration(days: _withinDays!));
      view = view.where((p) => p.createdAt.isAfter(cutoff)).toList();
    } else {
      view = List<ItemPost>.of(view);
    }

    view.sort((a, b) => _newestFirst
        ? b.createdAt.compareTo(a.createdAt)
        : a.createdAt.compareTo(b.createdAt));

    _posts = view;
    if (notify) notifyListeners();
  }

  void _subscribe() {
    _sub?.cancel();
    _isLoading = true;
    _error = null;
    notifyListeners();

    final keywords = _query.trim().isEmpty ? null : tokenizeQuery(_query);

    _sub = _postRepository
        .watchFeed(type: _type, category: _category, keywords: keywords)
        .listen(
      (posts) {
        _raw = posts;
        _applyView(notify: false);
        _isLoading = false;
        _error = null;
        notifyListeners();
      },
      onError: (Object e) {
        _error = e.toString();
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
