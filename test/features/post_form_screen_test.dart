import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import 'package:found404/features/posts/post_form_screen.dart';
import 'package:found404/models/enums.dart';
import 'package:found404/models/item_post.dart';
import 'package:found404/providers/post_editor_provider.dart';
import 'package:found404/repositories/post_repository.dart';
import 'package:found404/services/storage_service.dart';

class _FakePostRepository implements PostRepository {
  @override
  Future<ItemPost> createPost(ItemPost post) async => post;

  @override
  Future<void> deletePost(String postId, {required String requesterId}) async {}

  @override
  Future<ItemPost?> getPostById(String postId) async => null;

  @override
  Future<void> updatePost(ItemPost post, {required String requesterId}) async {}

  @override
  Future<void> updateStatus(String postId, PostStatus status) async {}

  @override
  Stream<List<ItemPost>> watchFeed({
    PostType? type,
    String? category,
    List<String>? keywords,
    int limit = 50,
  }) => Stream.value(const []);

  @override
  Stream<List<ItemPost>> watchUserPosts(String userId) =>
      Stream.value(const []);
}

class _MockStorageService extends Mock implements StorageService {}

void main() {
  Widget testApp() {
    return ChangeNotifierProvider(
      create: (_) => PostEditorProvider(
        postRepository: _FakePostRepository(),
        storageService: _MockStorageService(),
      ),
      child: const MaterialApp(home: PostFormScreen()),
    );
  }

  testWidgets('create post form exposes all required fields', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(testApp());

    expect(find.text('Create post'), findsOneWidget);
    expect(find.text('Item name'), findsOneWidget);
    expect(find.text('Category'), findsOneWidget);
    expect(find.text('Description'), findsOneWidget);
    expect(find.text('Campus location'), findsOneWidget);
    expect(find.text('Publish post'), findsOneWidget);
  });

  testWidgets('create post form reports missing required values', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(testApp());

    await tester.ensureVisible(find.text('Publish post'));
    await tester.tap(find.text('Publish post'));
    await tester.pump();

    expect(find.text('Item name is required'), findsOneWidget);
    expect(find.text('Category is required'), findsOneWidget);
    expect(
      find.text('Description must be at least 10 characters'),
      findsOneWidget,
    );
    expect(find.text('Location is required'), findsOneWidget);
  });
}
