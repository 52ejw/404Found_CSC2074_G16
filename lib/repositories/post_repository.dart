import '../models/enums.dart';
import '../models/item_post.dart';

/// Contract for the `posts` collection — create/read/update/delete plus the
/// community feed (FR03-FR08). Owned by Backend Developer 1.
abstract class PostRepository {
  Future<ItemPost> createPost(ItemPost post);

  Future<ItemPost?> getPostById(String postId);

  /// Community feed (FR05) with optional Lost/Found and category filters
  /// (FR06), ordered newest-first. [keywords] should be lowercased tokens
  /// (see `core/utils/search_keywords.dart`) matched against
  /// [ItemPost.searchKeywords] for the search box.
  Stream<List<ItemPost>> watchFeed({
    PostType? type,
    String? category,
    List<String>? keywords,
    int limit = 50,
  });

  /// A single user's own posts, for the Profile screen.
  Stream<List<ItemPost>> watchUserPosts(String userId);

  /// Throws [PermissionDeniedException] if [requesterId] does not own the
  /// post (FR08 — owner-only edit).
  Future<void> updatePost(ItemPost post, {required String requesterId});

  /// Throws [PermissionDeniedException] if [requesterId] does not own the
  /// post (FR08 — owner-only delete).
  Future<void> deletePost(String postId, {required String requesterId});

  /// Used by the matching/claim workflow to progress FR13 status
  /// transitions (Open → Possible Match → Claim Requested → Returned/Closed).
  Future<void> updateStatus(String postId, PostStatus status);
}
