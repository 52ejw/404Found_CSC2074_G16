import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../core/utils/search_keywords.dart';
import '../models/enums.dart';
import '../models/item_post.dart';
import '../repositories/post_repository.dart';
import '../services/matching_service.dart';
import '../services/storage_service.dart';

/// ViewModel for post creation, editing, details, deletion and status changes.
class PostProvider extends ChangeNotifier {
  PostProvider({
    required PostRepository postRepository,
    required MatchingService matchingService,
    StorageService? storageService,
  }) : _postRepository = postRepository,
       _matchingService = matchingService,
       _storageService = storageService ?? StorageService();

  final PostRepository _postRepository;
  final MatchingService _matchingService;
  final StorageService _storageService;

  String? _userId;
  String _ownerName = '';

  bool _isSubmitting = false;
  bool get isSubmitting => _isSubmitting;

  String? _error;
  String? get error => _error;

  ItemPost? _selectedPost;
  ItemPost? get selectedPost => _selectedPost;

  bool _isLoadingDetails = false;
  bool get isLoadingDetails => _isLoadingDetails;

  String? _detailsError;
  String? get detailsError => _detailsError;

  void setIdentity({required String? userId, String? ownerName}) {
    _userId = userId;
    _ownerName = ownerName?.trim() ?? '';
  }

  Future<void> loadPost(String postId, {ItemPost? initialPost}) async {
    if (initialPost != null && initialPost.id == postId) {
      _selectedPost = initialPost;
    }
    _isLoadingDetails = _selectedPost?.id != postId;
    _detailsError = null;
    notifyListeners();
    try {
      final post = await _postRepository.getPostById(postId);
      if (post == null) {
        _selectedPost = null;
        _detailsError = 'This post no longer exists.';
      } else {
        _selectedPost = post;
      }
    } catch (error) {
      _detailsError = _friendly(error);
    } finally {
      _isLoadingDetails = false;
      notifyListeners();
    }
  }

  Future<ItemPost?> savePost({
    ItemPost? existingPost,
    required PostType postType,
    required String itemName,
    required String category,
    required String description,
    required String location,
    required DateTime eventDate,
    required ContactPreference contactPreference,
    List<File> newImages = const [],
    List<String> keepImageUrls = const [],
  }) async {
    final uid = _userId;
    if (uid == null) {
      _error = 'You must be signed in to publish a post.';
      notifyListeners();
      return null;
    }

    _setSubmitting(true);
    try {
      final now = DateTime.now();
      final keywords = buildSearchKeywords(
        itemName: itemName,
        category: category,
        location: location,
        description: description,
      );

      ItemPost saved;
      if (existingPost == null) {
        saved = await _postRepository.createPost(
          ItemPost(
            id: '',
            ownerId: uid,
            ownerName: _ownerName.isEmpty ? 'Campus member' : _ownerName,
            postType: postType,
            itemName: itemName.trim(),
            category: category,
            description: description.trim(),
            location: location,
            eventDate: eventDate,
            contactPreference: contactPreference,
            imageUrls: keepImageUrls,
            createdAt: now,
            updatedAt: now,
            searchKeywords: keywords,
          ),
        );
        // Runs after the post is already saved so publishing feels instant;
        // matching failures shouldn't block or fail the post creation itself.
        unawaited(_runMatchingSafely(saved));
      } else {
        saved = existingPost.copyWith(
          itemName: itemName.trim(),
          category: category,
          description: description.trim(),
          location: location,
          eventDate: eventDate,
          contactPreference: contactPreference,
          imageUrls: keepImageUrls,
          updatedAt: now,
          searchKeywords: keywords,
        );
        await _postRepository.updatePost(saved, requesterId: uid);
      }

      if (newImages.isNotEmpty) {
        final uploaded = <String>[];
        for (final file in newImages) {
          uploaded.add(
            await _storageService.uploadPostImage(ownerId: uid, postId: saved.id, file: file),
          );
        }
        saved = saved.copyWith(
          imageUrls: [...saved.imageUrls, ...uploaded],
          updatedAt: DateTime.now(),
        );
        await _postRepository.updatePost(saved, requesterId: uid);
      }

      _selectedPost = saved;
      return saved;
    } catch (error) {
      _error = _friendly(error);
      return null;
    } finally {
      _setSubmitting(false);
    }
  }

  Future<bool> deletePost(ItemPost post) async {
    final uid = _userId;
    if (uid == null) {
      _error = 'You must be signed in to delete a post.';
      notifyListeners();
      return false;
    }
    _setSubmitting(true);
    try {
      await _postRepository.deletePost(post.id, requesterId: uid);
      if (_selectedPost?.id == post.id) _selectedPost = null;
      return true;
    } catch (error) {
      _error = _friendly(error);
      return false;
    } finally {
      _setSubmitting(false);
    }
  }

  Future<bool> updateStatus(ItemPost post, PostStatus status) async {
    _setSubmitting(true);
    try {
      await _postRepository.updateStatus(post.id, status);
      _selectedPost = post.copyWith(status: status, updatedAt: DateTime.now());
      return true;
    } catch (error) {
      _error = _friendly(error);
      return false;
    } finally {
      _setSubmitting(false);
    }
  }

  Future<void> _runMatchingSafely(ItemPost post) async {
    try {
      await _matchingService.generateMatchesForNewPost(post);
    } catch (error) {
      debugPrint('Matching failed for post ${post.id}: $error');
    }
  }

  void clearError() {
    if (_error == null) return;
    _error = null;
    notifyListeners();
  }

  void _setSubmitting(bool value) {
    _isSubmitting = value;
    if (value) _error = null;
    notifyListeners();
  }

  String _friendly(Object error) {
    final value = error.toString();
    return value.startsWith('Exception: ')
        ? value.substring('Exception: '.length)
        : value;
  }
}
