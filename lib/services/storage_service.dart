import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';

import '../core/errors/app_exception.dart';

/// Thin wrapper around [FirebaseStorage] for post and profile images.
///
/// Paths are namespaced by owner id so Storage security rules (see
/// `storage.rules`) can allow a user to write only under their own prefix
/// without inspecting file contents.
class StorageService {
  final FirebaseStorage _storage;

  StorageService({FirebaseStorage? storage}) : _storage = storage ?? FirebaseStorage.instance;

  Future<String> uploadPostImage({
    required String ownerId,
    required String postId,
    required File file,
  }) {
    final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.uri.pathSegments.last}';
    final path = 'posts/$ownerId/$postId/$fileName';
    return _upload(path, file);
  }

  Future<String> uploadProfileImage({required String userId, required File file}) {
    final fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}${_extensionOf(file)}';
    final path = 'profiles/$userId/$fileName';
    return _upload(path, file);
  }

  Future<void> deleteImage(String downloadUrl) async {
    try {
      await _storage.refFromURL(downloadUrl).delete();
    } on FirebaseException catch (e) {
      // Missing/already-deleted files shouldn't block the caller (e.g. a
      // post edit that swaps images) — anything else is a real failure.
      if (e.code != 'object-not-found') {
        throw StorageException('Failed to delete image: ${e.message}');
      }
    }
  }

  Future<String> _upload(String path, File file) async {
    try {
      final ref = _storage.ref().child(path);
      final task = await ref.putFile(file);
      return task.ref.getDownloadURL();
    } on FirebaseException catch (e) {
      throw StorageException('Failed to upload image: ${e.message}');
    }
  }

  String _extensionOf(File file) {
    final segments = file.uri.pathSegments;
    if (segments.isEmpty || !segments.last.contains('.')) return '.jpg';
    return '.${segments.last.split('.').last}';
  }
}
