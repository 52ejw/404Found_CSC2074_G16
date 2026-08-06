import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/errors/app_exception.dart';
import '../models/enums.dart';
import '../models/item_post.dart';
import '../models/match_result.dart';
import '../models/notification_item.dart';
import '../repositories/notification_repository.dart';
import '../repositories/post_repository.dart';
import 'firestore_service.dart';

class MatchingService {
  static const double matchThreshold = 60;

  final PostRepository _postRepository;
  final NotificationRepository _notificationRepository;
  final FirestoreService _firestore;

  MatchingService({
    required PostRepository postRepository,
    required NotificationRepository notificationRepository,
    FirestoreService? firestore,
  }) : _postRepository = postRepository,
       _notificationRepository = notificationRepository,
       _firestore = firestore ?? FirestoreService();

  List<MatchResult> scoreMatches(ItemPost target, List<ItemPost> candidates) {
    final results = <MatchResult>[];

    for (final candidate in candidates) {
      if (candidate.postType == target.postType) continue;
      if (candidate.status != PostStatus.open) continue;

      final categoryScore = _categoryScore(target, candidate);
      final keywordScore = _keywordScore(target, candidate);
      final locationScore = _locationScore(target, candidate);
      final dateScore = _dateScore(target, candidate);
      final total = categoryScore + keywordScore + locationScore + dateScore;

      if (total < matchThreshold) continue;

      final isLost = target.postType == PostType.lost;
      final lostPost = isLost ? target : candidate;
      final foundPost = isLost ? candidate : target;

      results.add(
        MatchResult(
          id: '',
          lostPostId: lostPost.id,
          foundPostId: foundPost.id,
          lostPostOwnerId: lostPost.ownerId,
          foundPostOwnerId: foundPost.ownerId,
          categoryScore: categoryScore,
          keywordScore: keywordScore,
          locationScore: locationScore,
          dateScore: dateScore,
          totalScore: total,
          createdAt: DateTime.now(),
        ),
      );
    }

    results.sort((a, b) => b.totalScore.compareTo(a.totalScore));
    return results;
  }

  Future<List<MatchResult>> generateMatchesForNewPost(ItemPost newPost) async {
    final oppositeType = newPost.postType == PostType.lost
        ? PostType.found
        : PostType.lost;
    final candidates = await _postRepository
        .watchFeed(type: oppositeType, limit: 200)
        .first;

    final matches = scoreMatches(newPost, candidates);

    for (final match in matches) {
      final saved = await _saveMatch(match);
      await _postRepository.updateStatus(
        saved.lostPostId,
        PostStatus.possibleMatch,
      );
      await _postRepository.updateStatus(
        saved.foundPostId,
        PostStatus.possibleMatch,
      );
      for (final ownerId in {saved.lostPostOwnerId, saved.foundPostOwnerId}) {
        await _notifyOwner(ownerId, saved);
      }
    }

    return matches;
  }

  Future<MatchResult> _saveMatch(MatchResult match) async {
    try {
      final docRef = _firestore.matches.doc();
      final withId = MatchResult.fromMap(docRef.id, match.toMap());
      await docRef.set(withId);
      return withId;
    } on FirebaseException catch (e) {
      throw RepositoryException('Failed to save match: ${e.message}');
    }
  }

  Future<void> _notifyOwner(String ownerId, MatchResult match) {
    return _notificationRepository.createNotification(
      NotificationItem(
        id: '',
        userId: ownerId,
        type: NotificationType.match,
        title: 'Possible match found',
        body:
            'A post you own has a ${match.totalScore.round()}% possible match.',
        relatedEntityId: match.id,
        createdAt: DateTime.now(),
      ),
    );
  }

  double _categoryScore(ItemPost a, ItemPost b) =>
      a.category.toLowerCase() == b.category.toLowerCase() ? 35.0 : 0.0;

  double _keywordScore(ItemPost a, ItemPost b) {
    final aWords = a.searchKeywords.toSet();
    final bWords = b.searchKeywords.toSet();
    if (aWords.isEmpty || bWords.isEmpty) return 0;
    final shared = aWords.intersection(bWords).length;
    final possible = min(aWords.length, bWords.length);
    if (possible == 0) return 0;
    return 30 * shared / possible;
  }

  double _locationScore(ItemPost a, ItemPost b) =>
      a.location.toLowerCase() == b.location.toLowerCase() ? 20.0 : 0.0;

  double _dateScore(ItemPost a, ItemPost b) {
    final daysApart = a.eventDate.difference(b.eventDate).inDays.abs();
    if (daysApart <= 2) return 15.0;
    if (daysApart <= 5) return 8.0;
    return 0.0;
  }
}
