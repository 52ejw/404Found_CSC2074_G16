import '../models/enums.dart';
import '../models/item_post.dart';

abstract class PostRepository {
  Future<ItemPost> createPost(ItemPost post);

  Future<ItemPost?> getPostById(String postId);
  Stream<List<ItemPost>> watchFeed({
    PostType? type,
    String? category,
    List<String>? keywords,
    int limit = 50,
  });

  /// A single user's own posts, for the Profile screen.
  Stream<List<ItemPost>> watchUserPosts(String userId);

  Future<void> updatePost(ItemPost post, {required String requesterId});

  Future<void> deletePost(String postId, {required String requesterId});

  Future<void> updateStatus(String postId, PostStatus status);
}
