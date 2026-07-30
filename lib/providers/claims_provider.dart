import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/claim_request.dart';
import '../models/enums.dart';
import '../models/item_post.dart';
import '../repositories/claim_repository.dart';
import '../repositories/post_repository.dart';
import '../repositories/user_repository.dart';

/// ViewModel for submitting, tracking and resolving item claims.
class ClaimsProvider extends ChangeNotifier {
  ClaimsProvider({
    required ClaimRepository claimRepository,
    required PostRepository postRepository,
    required UserRepository userRepository,
  }) : _claimRepository = claimRepository,
       _postRepository = postRepository,
       _userRepository = userRepository;

  final ClaimRepository _claimRepository;
  final PostRepository _postRepository;
  final UserRepository _userRepository;

  StreamSubscription<List<ClaimRequest>>? _claimsSub;
  String? _userId;
  bool _isDisposed = false;

  List<ClaimRequest> _claims = const [];
  List<ClaimRequest> get claims => _claims;

  Map<String, ItemPost> _postsById = const {};
  ItemPost? postFor(String postId) => _postsById[postId];

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isSubmitting = false;
  bool get isSubmitting => _isSubmitting;

  String? _error;
  String? get error => _error;

  List<ClaimRequest> get incomingClaims => _claims
      .where((claim) => claim.finderId == _userId)
      .toList(growable: false);

  List<ClaimRequest> get submittedClaims => _claims
      .where((claim) => claim.claimantId == _userId)
      .toList(growable: false);

  void setUserId(String? userId) {
    if (_userId == userId) return;
    _userId = userId;
    _subscribe();
  }

  void retry() => _subscribe();

  Future<bool> submitClaim({
    required ItemPost post,
    required String proofDescription,
  }) async {
    final uid = _userId;
    if (uid == null) return _fail('You must be signed in to submit a claim.');
    if (uid == post.ownerId) return _fail('You cannot claim your own post.');
    if (post.status == PostStatus.returned ||
        post.status == PostStatus.closed) {
      return _fail('This item is no longer open for claims.');
    }
    final alreadyClaimed = _claims.any(
      (claim) =>
          claim.postId == post.id &&
          claim.claimantId == uid &&
          (claim.status == ClaimStatus.pending ||
              claim.status == ClaimStatus.accepted),
    );
    if (alreadyClaimed) {
      return _fail('You already have an active claim for this item.');
    }

    _setSubmitting(true);
    try {
      await _claimRepository.createClaim(
        ClaimRequest(
          id: '',
          postId: post.id,
          claimantId: uid,
          finderId: post.ownerId,
          proofDescription: proofDescription.trim(),
          createdAt: DateTime.now(),
        ),
      );
      await _postRepository.updateStatus(post.id, PostStatus.claimRequested);
      return true;
    } catch (error) {
      _error = _friendly(error);
      return false;
    } finally {
      _setSubmitting(false);
    }
  }

  Future<bool> resolveClaim(ClaimRequest claim, ClaimStatus status) async {
    final uid = _userId;
    if (uid == null) return _fail('You must be signed in to update a claim.');
    if (claim.finderId != uid) {
      return _fail('Only the person who posted the found item can respond.');
    }

    _setSubmitting(true);
    try {
      await _claimRepository.resolveClaim(claim.id, status);
      if (status == ClaimStatus.returned) {
        await _postRepository.updateStatus(claim.postId, PostStatus.returned);
        await _userRepository.incrementSuccessfulRecoveries(claim.claimantId);
        await _userRepository.incrementSuccessfulRecoveries(claim.finderId);
      }
      return true;
    } catch (error) {
      _error = _friendly(error);
      return false;
    } finally {
      _setSubmitting(false);
    }
  }

  bool _fail(String message) {
    _error = message;
    notifyListeners();
    return false;
  }

  void _setSubmitting(bool value) {
    _isSubmitting = value;
    if (value) _error = null;
    notifyListeners();
  }

  void _subscribe() {
    _claimsSub?.cancel();
    _claims = const [];
    _postsById = const {};
    _error = null;
    final uid = _userId;
    _isLoading = uid != null;
    notifyListeners();
    if (uid == null) return;

    _claimsSub = _claimRepository
        .watchClaimsByUser(uid)
        .listen(
          (claims) {
            _claims = claims;
            _isLoading = false;
            _error = null;
            notifyListeners();
            unawaited(_loadPosts(claims));
          },
          onError: (Object error) {
            _error = _friendly(error);
            _isLoading = false;
            notifyListeners();
          },
        );
  }

  Future<void> _loadPosts(List<ClaimRequest> claims) async {
    final ids = claims.map((claim) => claim.postId).toSet();
    final loaded = <String, ItemPost>{};
    await Future.wait(
      ids.map((id) async {
        try {
          final post = await _postRepository.getPostById(id);
          if (post != null) loaded[id] = post;
        } catch (_) {
          // A deleted or inaccessible post still leaves a useful claim row.
        }
      }),
    );
    if (_isDisposed) return;
    _postsById = loaded;
    notifyListeners();
  }

  String _friendly(Object error) {
    final value = error.toString();
    return value.startsWith('Exception: ')
        ? value.substring('Exception: '.length)
        : value;
  }

  @override
  void dispose() {
    _isDisposed = true;
    _claimsSub?.cancel();
    super.dispose();
  }
}
