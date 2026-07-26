import 'package:flutter_test/flutter_test.dart';
import 'package:found404/models/enums.dart';
import 'package:found404/models/item_post.dart';

void main() {
  test('ItemPost round-trips through toMap/fromMap', () {
    final now = DateTime(2026, 1, 15, 10, 30);
    final post = ItemPost(
      id: 'post1',
      ownerId: 'user1',
      ownerName: 'Alex',
      postType: PostType.lost,
      itemName: 'Water Bottle',
      category: 'Accessories',
      description: 'Blue, dented cap',
      location: 'Library',
      eventDate: now,
      imageUrls: const ['https://example.com/a.jpg'],
      status: PostStatus.open,
      createdAt: now,
      updatedAt: now,
      searchKeywords: const ['water', 'bottle', 'accessories', 'library'],
    );

    final roundTripped = ItemPost.fromMap(post.id, post.toMap());

    expect(roundTripped.id, post.id);
    expect(roundTripped.ownerId, post.ownerId);
    expect(roundTripped.postType, PostType.lost);
    expect(roundTripped.status, PostStatus.open);
    expect(roundTripped.imageUrls, post.imageUrls);
    expect(roundTripped.searchKeywords, post.searchKeywords);
    expect(roundTripped.eventDate, now);
  });

  test('ItemPost.fromMap falls back to defaults for missing fields', () {
    final post = ItemPost.fromMap('post2', const {});

    expect(post.postType, PostType.lost);
    expect(post.status, PostStatus.open);
    expect(post.imageUrls, isEmpty);
    expect(post.searchKeywords, isEmpty);
  });

  test('copyWith updates only the given fields', () {
    final now = DateTime(2026, 1, 15);
    final post = ItemPost(
      id: 'post1',
      ownerId: 'user1',
      ownerName: 'Alex',
      postType: PostType.found,
      itemName: 'Umbrella',
      category: 'Other',
      description: 'Black umbrella',
      location: 'Cafeteria',
      eventDate: now,
      createdAt: now,
      updatedAt: now,
    );

    final updated = post.copyWith(status: PostStatus.returned);

    expect(updated.status, PostStatus.returned);
    expect(updated.itemName, post.itemName);
    expect(updated.ownerId, post.ownerId);
  });
}
