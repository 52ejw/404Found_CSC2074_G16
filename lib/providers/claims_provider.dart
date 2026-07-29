import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/claim_request.dart';
import '../models/enums.dart';
import '../repositories/claim_repository.dart';
import '../repositories/post_repository.dart';

/// ViewModel for claim creation, history and finder-side resolution.
class ClaimsProvider extends ChangeNotifier {
  final ClaimRepository _claimRepository;
  final PostRepository _postRepository;

  ClaimsProvider({
    required ClaimRepository claimRepository,
    required PostRepository postRepository,
  }) : _claimRepository = claimRepository,
       _postRepository = postRepository;

  StreamSubscription<List<ClaimRequest>>? _sub;
  String? _userId;

  List<ClaimRequest> _claims = const [];
  List<ClaimRequest> get claims => _claims;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  bool _isSubmitting = false;
  bool get isSubmitting => _isSubmitting;

  String? _busyClaimId;
  String? get busyClaimId => _busyClaimId;

  String? _error;
  String? get error => _error;

  void load(String userId) {
    if (_userId == userId) return;
    _userId = userId;
    _sub?.cancel();
    _isLoading = true;
    _error = null;
    notifyListeners();
    _sub = _claimRepository
        .watchClaimsByUser(userId)
        .listen(
          (claims) {
            _claims = claims;
            _isLoading = false;
            _error = null;
            notifyListeners();
          },
          onError: (Object error) {
            _error = _friendly(error);
            _isLoading = false;
            notifyListeners();
          },
        );
  }

  Future<bool> submit({
    required String postId,
    required String claimantId,
    required String finderId,
    required String proofDescription,
  }) async {
    _isSubmitting = true;
    _error = null;
    notifyListeners();
    try {
      await _claimRepository.createClaim(
        ClaimRequest(
          id: '',
          postId: postId,
          claimantId: claimantId,
          finderId: finderId,
          proofDescription: proofDescription.trim(),
          createdAt: DateTime.now(),
        ),
      );
      return true;
    } catch (e) {
      _error = _friendly(e);
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<bool> resolve(ClaimRequest claim, ClaimStatus status) async {
    _busyClaimId = claim.id;
    _error = null;
    notifyListeners();
    try {
      await _claimRepository.resolveClaim(claim.id, status);
      if (status == ClaimStatus.accepted) {
        await _postRepository.updateStatus(
          claim.postId,
          PostStatus.claimRequested,
        );
      } else if (status == ClaimStatus.returned) {
        await _postRepository.updateStatus(claim.postId, PostStatus.returned);
      }
      return true;
    } catch (e) {
      _error = _friendly(e);
      return false;
    } finally {
      _busyClaimId = null;
      notifyListeners();
    }
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
