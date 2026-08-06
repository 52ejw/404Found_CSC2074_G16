import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';

import '../core/errors/app_exception.dart';

class StorageService {
  final FirebaseStorage _storage;

  StorageService({FirebaseStorage? storage})
    : _storage = storage ?? FirebaseStorage.instance;

  Future<String> uploadPostImage({
    required String ownerId,
    required String postId,
    required Uint8List bytes,
    required String fileName,
  }) {
    final path =
        'posts/$ownerId/$postId/${DateTime.now().millisecondsSinceEpoch}_$fileName';
    return _upload(path, bytes, fileName);
  }

  Future<String> uploadProfileImage({
    required String userId,
    required Uint8List bytes,
    required String fileName,
  }) {
    final path =
        'profiles/$userId/profile_${DateTime.now().millisecondsSinceEpoch}_$fileName';
    return _upload(path, bytes, fileName);
  }

  Future<void> deleteImage(String downloadUrl) async {
    try {
      await _storage.refFromURL(downloadUrl).delete();
    } on FirebaseException catch (e) {
      if (e.code != 'object-not-found') {
        throw StorageException('Failed to delete image: ${e.message}');
      }
    }
  }

  Future<String> _upload(String path, Uint8List bytes, String fileName) async {
    try {
      final ref = _storage.ref().child(path);
      final task = await ref.putData(
        bytes,
        SettableMetadata(contentType: _contentTypeOf(fileName)),
      );
      return task.ref.getDownloadURL();
    } on FirebaseException catch (e) {
      throw StorageException('Failed to upload image: ${e.message}');
    }
  }

  String _contentTypeOf(String fileName) {
    final extension = fileName.contains('.')
        ? fileName.split('.').last.toLowerCase()
        : '';
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
