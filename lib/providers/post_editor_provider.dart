import 'dart:io';

import 'package:flutter/foundation.dart';

import '../core/utils/search_keywords.dart';
import '../models/enums.dart';
import '../models/item_post.dart';
import '../repositories/post_repository.dart';
import '../services/storage_service.dart';

/// ViewModel for create/edit post forms (FR03, FR04 and FR08).
///
/// The UI supplies validated values; this class owns repository calls, image
/// upload sequencing and the shared loading/error contract.
class PostEditorProvider extends ChangeNotifier {
  final PostRepository _postRepository;
  final StorageService _storageService;

  PostEditorProvider({
    required PostRepository postRepository,
    required StorageService storageService,
  }) : _postRepository = postRepository,
       _storageService = storageService;

  bool _isSubmitting = false;
  bool get isSubmitting => _isSubmitting;

  String? _error;
  String? get error => _error;

  ItemPost? _savedPost;
  ItemPost? get savedPost => _savedPost;

  Future<ItemPost?> save({
    ItemPost? existing,
    required String ownerId,
    required String ownerName,
    required PostType postType,
    required String itemName,
    required String category,
    required String description,
    required String location,
    required DateTime eventDate,
    required ContactPreference contactPreference,
    File? selectedImage,
    bool removeExistingImage = false,
  }) async {
    _isSubmitting = true;
    _error = null;
    _savedPost = null;
    notifyListeners();

    final now = DateTime.now();
    final keywords = buildSearchKeywords(
      itemName: itemName,
      category: category,
      location: location,
      description: description,
    );

    try {
      if (existing == null) {
        var created = await _postRepository.createPost(
          ItemPost(
            id: '',
            ownerId: ownerId,
            ownerName: ownerName,
            postType: postType,
            itemName: itemName.trim(),
            category: category,
            description: description.trim(),
            location: location,
            eventDate: eventDate,
            contactPreference: contactPreference,
            createdAt: now,
            updatedAt: now,
            searchKeywords: keywords,
          ),
        );

        if (selectedImage != null) {
          final imageUrl = await _storageService.uploadPostImage(
            ownerId: ownerId,
            postId: created.id,
            file: selectedImage,
          );
          created = created.copyWith(imageUrls: [imageUrl]);
          await _postRepository.updatePost(created, requesterId: ownerId);
        }
        _savedPost = created;
      } else {
        var imageUrls = removeExistingImage
            ? <String>[]
            : List<String>.from(existing.imageUrls);
        if (selectedImage != null) {
          final imageUrl = await _storageService.uploadPostImage(
            ownerId: ownerId,
            postId: existing.id,
            file: selectedImage,
          );
          imageUrls = [imageUrl];
        }

        final updated = ItemPost(
          id: existing.id,
          ownerId: existing.ownerId,
          ownerName: ownerName,
          postType: postType,
          itemName: itemName.trim(),
          category: category,
          description: description.trim(),
          location: location,
          eventDate: eventDate,
          imageUrls: imageUrls,
          contactPreference: contactPreference,
          status: existing.status,
          createdAt: existing.createdAt,
          updatedAt: now,
          searchKeywords: keywords,
        );
        await _postRepository.updatePost(updated, requesterId: ownerId);

        if ((removeExistingImage || selectedImage != null) &&
            existing.imageUrls.isNotEmpty) {
          await _storageService.deleteImage(existing.imageUrls.first);
        }
        _savedPost = updated;
      }
    } catch (e) {
      _error = _friendly(e);
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
    return _savedPost;
  }

  Future<bool> delete(ItemPost post, {required String requesterId}) async {
    _isSubmitting = true;
    _error = null;
    notifyListeners();
    try {
      await _postRepository.deletePost(post.id, requesterId: requesterId);
      for (final imageUrl in post.imageUrls) {
        await _storageService.deleteImage(imageUrl);
      }
      return true;
    } catch (e) {
      _error = _friendly(e);
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  void clearError() {
    if (_error == null) return;
    _error = null;
    notifyListeners();
  }

  String _friendly(Object error) {
    final message = error.toString();
    return message.startsWith('Exception: ')
        ? message.substring('Exception: '.length)
        : message;
  }
}
