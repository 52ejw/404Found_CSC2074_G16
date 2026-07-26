import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/errors/app_exception.dart';
import '../models/enums.dart';
import '../models/item_post.dart';
import '../services/firestore_service.dart';
import 'post_repository.dart';

class FirestorePostRepository implements PostRepository {
  final FirestoreService _firestore;

  FirestorePostRepository({FirestoreService? firestore}) : _firestore = firestore ?? FirestoreService();

  @override
  Future<ItemPost> createPost(ItemPost post) async {
    try {
      final docRef = _firestore.posts.doc();
      final withId = ItemPost.fromMap(docRef.id, post.toMap());
      await docRef.set(withId);
      return withId;
    } on FirebaseException catch (e) {
      throw RepositoryException('Failed to create post: ${e.message}');
    }
  }

  @override
  Future<ItemPost?> getPostById(String postId) async {
    try {
      final doc = await _firestore.posts.doc(postId).get();
      return doc.data();
    } on FirebaseException catch (e) {
      throw RepositoryException('Failed to load post: ${e.message}');
    }
  }

  @override
  Stream<List<ItemPost>> watchFeed({
    PostType? type,
    String? category,
    List<String>? keywords,
    int limit = 50,
  }) {
    Query<ItemPost> query = _firestore.posts;

    if (type != null) {
      query = query.where('postType', isEqualTo: type.name);
    }
    if (category != null && category.isNotEmpty) {
      query = query.where('category', isEqualTo: category);
    }
    if (keywords != null && keywords.isNotEmpty) {
      // Firestore caps arrayContainsAny at 30 values.
      query = query.where('searchKeywords', arrayContainsAny: keywords.take(30).toList());
    }

    query = query.orderBy('createdAt', descending: true).limit(limit);

    return query.snapshots().map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  @override
  Stream<List<ItemPost>> watchUserPosts(String userId) {
    return _firestore.posts
        .where('ownerId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  @override
  Future<void> updatePost(ItemPost post, {required String requesterId}) async {
    await _assertOwnership(post.id, requesterId);
    try {
      await _firestore.posts.doc(post.id).set(
            post.copyWith(updatedAt: DateTime.now()),
          );
    } on FirebaseException catch (e) {
      throw RepositoryException('Failed to update post: ${e.message}');
    }
  }

  @override
  Future<void> deletePost(String postId, {required String requesterId}) async {
    await _assertOwnership(postId, requesterId);
    try {
      await _firestore.posts.doc(postId).delete();
    } on FirebaseException catch (e) {
      throw RepositoryException('Failed to delete post: ${e.message}');
    }
  }

  @override
  Future<void> updateStatus(String postId, PostStatus status) async {
    try {
      await _firestore.posts.doc(postId).update({
        'status': status.name,
        'updatedAt': Timestamp.now(),
      });
    } on FirebaseException catch (e) {
      throw RepositoryException('Failed to update post status: ${e.message}');
    }
  }

  /// Client-side guard so the UI can show a clear error immediately; the
  /// authoritative check still lives in `firestore.rules` (NFR07).
  Future<void> _assertOwnership(String postId, String requesterId) async {
    final existing = await getPostById(postId);
    if (existing == null) {
      throw const NotFoundException('Post not found.');
    }
    if (existing.ownerId != requesterId) {
      throw const PermissionDeniedException('Only the post owner can edit or delete this post.');
    }
  }
}
