import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/errors/app_exception.dart';
import '../models/enums.dart';
import '../models/match_result.dart';
import '../services/firestore_service.dart';
import 'match_repository.dart';

class FirestoreMatchRepository implements MatchRepository {
  final FirestoreService _firestore;

  FirestoreMatchRepository({FirestoreService? firestore})
      : _firestore = firestore ?? FirestoreService();

  @override
  Stream<List<MatchResult>> watchMatchesForPost(String postId) {
    return _firestore.matches
        .where(
          Filter.or(
            Filter('lostPostId', isEqualTo: postId),
            Filter('foundPostId', isEqualTo: postId),
          ),
        )
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  @override
  Stream<List<MatchResult>> watchMatchesForUser(String userId) {
    return _firestore.matches
        .where(
          Filter.or(
            Filter('lostPostOwnerId', isEqualTo: userId),
            Filter('foundPostOwnerId', isEqualTo: userId),
          ),
        )
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  @override
  Future<void> updateMatchStatus(String matchId, MatchStatus status) async {
    try {
      await _firestore.matches.doc(matchId).update({'status': status.name});
    } on FirebaseException catch (e) {
      throw RepositoryException('Failed to update match status: ${e.message}');
    }
  }
}
