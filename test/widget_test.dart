import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:found404/app/app.dart';
import 'package:found404/core/widgets/post_card.dart';
import 'package:found404/core/widgets/type_badge.dart';
import 'package:found404/models/app_user.dart';
import 'package:found404/models/enums.dart';
import 'package:found404/models/item_post.dart';
import 'package:found404/repositories/auth_repository.dart';
import 'package:found404/repositories/post_repository.dart';
import 'package:found404/repositories/user_repository.dart';

/// Minimal fakes so the app can be pumped without a real Firebase backend.
class _FakeAuthRepository implements AuthRepository {
  @override
  String? get currentUserId => null;

  @override
  Stream<String?> authStateChanges() => Stream<String?>.value(null);

  @override
  Future<String> login({required String email, required String password}) async => 'uid';

  @override
  Future<String> register({required String email, required String password}) async => 'uid';

  @override
  Future<void> logout() async {}

  @override
  Future<void> sendPasswordResetEmail(String email) async {}
}

class _FakeUserRepository implements UserRepository {
  @override
  Future<void> createUserProfile(AppUser user) async {}

  @override
  Future<AppUser?> getUserById(String userId) async => null;

  @override
  Stream<AppUser?> watchUser(String userId) => Stream<AppUser?>.value(null);

  @override
  Future<void> updateUserProfile(String userId,
      {String? name, String? faculty, String? contact, String? profileImageUrl}) async {}

  @override
  Future<void> incrementSuccessfulRecoveries(String userId) async {}
}

class _FakePostRepository implements PostRepository {
  @override
  Future<ItemPost> createPost(ItemPost post) async => post;

  @override
  Future<ItemPost?> getPostById(String postId) async => null;

  @override
  Stream<List<ItemPost>> watchFeed(
          {PostType? type, String? category, List<String>? keywords, int limit = 50}) =>
      Stream<List<ItemPost>>.value(const []);

  @override
  Stream<List<ItemPost>> watchUserPosts(String userId) =>
      Stream<List<ItemPost>>.value(const []);

  @override
  Future<void> updatePost(ItemPost post, {required String requesterId}) async {}

  @override
  Future<void> deletePost(String postId, {required String requesterId}) async {}

  @override
  Future<void> updateStatus(String postId, PostStatus status) async {}
}

ItemPost _samplePost() => ItemPost(
      id: 'p1',
      ownerId: 'u1',
      ownerName: 'Tess',
      postType: PostType.lost,
      itemName: 'Blue backpack',
      category: 'Bags',
      description: 'Left in the library',
      location: 'Main Library',
      eventDate: DateTime.now(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

void main() {
  testWidgets('unauthenticated user lands on the login screen',
      (WidgetTester tester) async {
    await tester.pumpWidget(App(
      authRepository: _FakeAuthRepository(),
      userRepository: _FakeUserRepository(),
      postRepository: _FakePostRepository(),
    ));
    // Let the auth-state stream emit null (unauthenticated).
    await tester.pumpAndSettle();

    expect(find.text('Log in'), findsWidgets);
    expect(find.text('Create account'), findsOneWidget);
  });

  testWidgets('PostCard shows the item name and a Lost badge',
      (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: PostCard(post: _samplePost())),
    ));

    expect(find.text('Blue backpack'), findsOneWidget);
    expect(find.byType(TypeBadge), findsOneWidget);
    expect(find.text('Lost'), findsOneWidget);
  });
}
