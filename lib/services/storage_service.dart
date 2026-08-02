import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';

import '../core/errors/app_exception.dart';

/// Thin wrapper around [FirebaseStorage] for post and profile images.
///
/// Uploads take raw bytes ([Uint8List]) rather than `dart:io File`, since
/// `File`-based uploads (`putFile`) are unsupported on Flutter web — bytes
/// via `putData` work identically on every platform. Callers read bytes from
/// an `XFile` (image_picker) with `await file.readAsBytes()`.
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
    required Uint8List bytes,
    required String fileName,
  }) {
    final path = 'posts/$ownerId/$postId/${DateTime.now().millisecondsSinceEpoch}_$fileName';
    return _upload(path, bytes, fileName);
  }

  Future<String> uploadProfileImage({
    required String userId,
    required Uint8List bytes,
    required String fileName,
  }) {
    final path = 'profiles/$userId/profile_${DateTime.now().millisecondsSinceEpoch}_$fileName';
    return _upload(path, bytes, fileName);
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

  Future<String> _upload(String path, Uint8List bytes, String fileName) async {
    try {
      final ref = _storage.ref().child(path);
      // storage.rules checks contentType.matches('image/.*') — putData leaves
      // this as application/octet-stream unless set explicitly, which would
      // fail that check even with valid image bytes.
      final task = await ref.putData(bytes, SettableMetadata(contentType: _contentTypeOf(fileName)));
      return task.ref.getDownloadURL();
    } on FirebaseException catch (e) {
      throw StorageException('Failed to upload image: ${e.message}');
    }
  }

  String _contentTypeOf(String fileName) {
    final extension = fileName.contains('.') ? fileName.split('.').last.toLowerCase() : '';
    switch (extension) {
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'heic':
        return 'image/heic';
      default:
        return 'image/jpeg';
    }
  }
}
