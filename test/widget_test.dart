import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import 'package:found404/app/app.dart';
import 'package:found404/core/widgets/post_card.dart';
import 'package:found404/core/widgets/type_badge.dart';
import 'package:found404/models/app_user.dart';
import 'package:found404/models/claim_request.dart';
import 'package:found404/models/conversation.dart';
import 'package:found404/models/enums.dart';
import 'package:found404/models/item_post.dart';
import 'package:found404/models/match_result.dart';
import 'package:found404/models/message.dart';
import 'package:found404/models/notification_item.dart';
import 'package:found404/features/posts/post_form_screen.dart';
import 'package:found404/providers/post_provider.dart';
import 'package:found404/repositories/auth_repository.dart';
import 'package:found404/repositories/chat_repository.dart';
import 'package:found404/repositories/claim_repository.dart';
import 'package:found404/repositories/match_repository.dart';
import 'package:found404/repositories/notification_repository.dart';
import 'package:found404/repositories/post_repository.dart';
import 'package:found404/repositories/user_repository.dart';
import 'package:found404/services/firestore_service.dart';
import 'package:found404/services/matching_service.dart';
import 'package:found404/services/storage_service.dart';

class _MockFirebaseStorage extends Mock implements FirebaseStorage {}

class _MockFirebaseFirestore extends Mock implements FirebaseFirestore {}

/// Minimal fakes so the app can be pumped without a real Firebase backend.
class _FakeAuthRepository implements AuthRepository {
  @override
  String? get currentUserId => null;

  @override
  Stream<String?> authStateChanges() => Stream<String?>.value(null);

  @override
  Future<String> login({
    required String email,
    required String password,
  }) async => 'uid';

  @override
  Future<String> register({
    required String email,
    required String password,
  }) async => 'uid';

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
  Future<void> updateUserProfile(
    String userId, {
    String? name,
    String? faculty,
    String? contact,
    String? profileImageUrl,
  }) async {}

  @override
  Future<void> incrementSuccessfulRecoveries(String userId) async {}
}

class _FakePostRepository implements PostRepository {
  ItemPost? createdPost;

  @override
  Future<ItemPost> createPost(ItemPost post) async {
    createdPost = post;
    return post;
  }

  @override
  Future<ItemPost?> getPostById(String postId) async => null;

  @override
  Stream<List<ItemPost>> watchFeed({
    PostType? type,
    String? category,
    List<String>? keywords,
    int limit = 50,
  }) => Stream<List<ItemPost>>.value(const []);

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

class _FakeClaimRepository implements ClaimRepository {
  @override
  Future<ClaimRequest> createClaim(ClaimRequest claim) async => claim;

  @override
  Future<void> resolveClaim(String claimId, ClaimStatus status) async {}

  @override
  Stream<List<ClaimRequest>> watchClaimsByUser(String userId) =>
      Stream<List<ClaimRequest>>.value(const []);

  @override
  Stream<List<ClaimRequest>> watchClaimsForPost(String postId) =>
      Stream<List<ClaimRequest>>.value(const []);
}

class _FakeChatRepository implements ChatRepository {
  @override
  Future<Conversation> getOrCreateConversation({
    required String relatedPostId,
    required List<String> participantIds,
  }) async => Conversation(
    id: 'conversation',
    participantIds: participantIds,
    relatedPostId: relatedPostId,
    lastMessageAt: DateTime.now(),
  );

  @override
  Future<void> markMessagesRead({
    required String conversationId,
    required String userId,
  }) async {}

  @override
  Future<void> sendMessage({
    required String conversationId,
    required String senderId,
    required String text,
  }) async {}

  @override
  Stream<List<Conversation>> watchConversations(String userId) =>
      Stream<List<Conversation>>.value(const []);

  @override
  Stream<List<Message>> watchMessages(String conversationId) =>
      Stream<List<Message>>.value(const []);
}

class _FakeMatchRepository implements MatchRepository {
  @override
  Future<void> updateMatchStatus(String matchId, MatchStatus status) async {}

  @override
  Stream<List<MatchResult>> watchMatchesForPost(String postId) =>
      Stream<List<MatchResult>>.value(const []);

  @override
  Stream<List<MatchResult>> watchMatchesForUser(String userId) =>
      Stream<List<MatchResult>>.value(const []);
}

class _FakeNotificationRepository implements NotificationRepository {
  @override
  Future<void> createNotification(NotificationItem notification) async {}

  @override
  Future<void> markAsRead(String notificationId) async {}

  @override
  Stream<List<NotificationItem>> watchNotifications(String userId) =>
      Stream<List<NotificationItem>>.value(const []);
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
  testWidgets('unauthenticated user lands on the login screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      App(
        authRepository: _FakeAuthRepository(),
        userRepository: _FakeUserRepository(),
        postRepository: _FakePostRepository(),
        claimRepository: _FakeClaimRepository(),
        chatRepository: _FakeChatRepository(),
        matchRepository: _FakeMatchRepository(),
        notificationRepository: _FakeNotificationRepository(),
      ),
    );
    // Let the auth-state stream emit null (unauthenticated).
    await tester.pumpAndSettle();

    expect(find.text('Sign in'), findsOneWidget);
    expect(find.text('Sign up'), findsOneWidget);
  });

  testWidgets('PostCard shows the item name and a Lost badge', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: PostCard(post: _samplePost())),
      ),
    );

    expect(find.text('Blue backpack'), findsOneWidget);
    expect(find.byType(TypeBadge), findsOneWidget);
    expect(find.text('Lost'), findsOneWidget);
  });

  testWidgets('PostCard exposes a descriptive accessibility label', (
    WidgetTester tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PostCard(post: _samplePost(), onTap: () {}),
        ),
      ),
    );

    expect(
      find.bySemanticsLabel('lost item, Blue backpack, Bags, Main Library'),
      findsOneWidget,
    );
    semantics.dispose();
  });

  testWidgets('create-post form validates required fields', (
    WidgetTester tester,
  ) async {
    final repository = _FakePostRepository();
    final provider = PostProvider(
      postRepository: repository,
      storageService: StorageService(storage: _MockFirebaseStorage()),
      matchingService: MatchingService(
        postRepository: repository,
        notificationRepository: _FakeNotificationRepository(),
        firestore: FirestoreService(firestore: _MockFirebaseFirestore()),
      ),
    )..setIdentity(userId: 'u1', ownerName: 'Tess');

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: provider,
        child: const MaterialApp(home: PostFormScreen()),
      ),
    );
    await tester.scrollUntilVisible(
      find.byKey(const Key('save-post-button')),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const Key('save-post-button')));
    await tester.pump();

    await tester.scrollUntilVisible(
      find.byKey(const Key('post-item-name')),
      -500,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();
    expect(find.text('Item name is required'), findsOneWidget);
    expect(repository.createdPost, isNull);
  });
}
