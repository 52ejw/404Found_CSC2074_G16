import 'package:flutter/foundation.dart';

import '../models/claim_request.dart';
import '../models/conversation.dart';
import '../models/enums.dart';
import '../models/item_post.dart';
import '../repositories/chat_repository.dart';
import '../repositories/claim_repository.dart';
import '../repositories/post_repository.dart';

/// Route-scoped state for post details and its claims.
class PostDetailProvider extends ChangeNotifier {
  final PostRepository _postRepository;
  final ClaimRepository _claimRepository;
  final ChatRepository _chatRepository;
  final String postId;

  PostDetailProvider({
    required PostRepository postRepository,
    required ClaimRepository claimRepository,
    required ChatRepository chatRepository,
    required this.postId,
  }) : _postRepository = postRepository,
       _claimRepository = claimRepository,
       _chatRepository = chatRepository {
    load();
  }

  ItemPost? _post;
  ItemPost? get post => _post;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  bool _isSubmitting = false;
  bool get isSubmitting => _isSubmitting;

  String? _busyClaimId;
  String? get busyClaimId => _busyClaimId;

  String? _error;
  String? get error => _error;

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _post = await _postRepository.getPostById(postId);
      if (_post == null) {
        _error = 'This post is no longer available.';
      }
    } catch (e) {
      _error = _friendly(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> submitClaim({
    required String claimantId,
    required String proofDescription,
  }) async {
    final currentPost = _post;
    if (currentPost == null || claimantId == currentPost.ownerId) return false;
    _isSubmitting = true;
    _error = null;
    notifyListeners();
    try {
      await _claimRepository.createClaim(
        ClaimRequest(
          id: '',
          postId: currentPost.id,
          claimantId: claimantId,
          finderId: currentPost.ownerId,
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

  Future<bool> resolveClaim(ClaimRequest claim, ClaimStatus status) async {
    _busyClaimId = claim.id;
    _error = null;
    notifyListeners();
    try {
      await _claimRepository.resolveClaim(claim.id, status);
      if (status == ClaimStatus.accepted) {
        await _postRepository.updateStatus(postId, PostStatus.claimRequested);
        _post = _post?.copyWith(
          status: PostStatus.claimRequested,
          updatedAt: DateTime.now(),
        );
      } else if (status == ClaimStatus.returned) {
        await _postRepository.updateStatus(postId, PostStatus.returned);
        _post = _post?.copyWith(
          status: PostStatus.returned,
          updatedAt: DateTime.now(),
        );
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

  Future<Conversation?> startConversation(String currentUserId) async {
    final currentPost = _post;
    if (currentPost == null || currentPost.ownerId == currentUserId)
      return null;
    _isSubmitting = true;
    _error = null;
    notifyListeners();
    try {
      return await _chatRepository.getOrCreateConversation(
        relatedPostId: currentPost.id,
        participantIds: [currentUserId, currentPost.ownerId],
      );
    } catch (e) {
      _error = _friendly(e);
      return null;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  String _friendly(Object error) {
    final message = error.toString();
    return message.startsWith('Exception: ')
        ? message.substring('Exception: '.length)
        : message;
  }
}
