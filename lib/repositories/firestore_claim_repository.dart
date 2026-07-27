import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/errors/app_exception.dart';
import '../models/claim_request.dart';
import '../models/enums.dart';
import '../services/firestore_service.dart';
import 'claim_repository.dart';

class FirestoreClaimRepository implements ClaimRepository {
  final FirestoreService _firestore;

  FirestoreClaimRepository({FirestoreService? firestore})
    : _firestore = firestore ?? FirestoreService();

  @override
  Future<ClaimRequest> createClaim(ClaimRequest claim) async {
    try {
      final docRef = _firestore.claims.doc();
      final withId = ClaimRequest.fromMap(docRef.id, claim.toMap());
      await docRef.set(withId);
      return withId;
    } on FirebaseException catch (e) {
      throw RepositoryException('Failed to create claim: ${e.message}');
    }
  }

  @override
  Stream<List<ClaimRequest>> watchClaimsForPost(String postId) {
    return _firestore.claims
        .where('postId', isEqualTo: postId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  @override
  Stream<List<ClaimRequest>> watchClaimsByUser(String userId) {
    return _firestore.claims
        .where(
          Filter.or(
            Filter('claimantId', isEqualTo: userId),
            Filter('finderId', isEqualTo: userId),
          ),
        )
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  @override
  Future<void> resolveClaim(String claimId, ClaimStatus status) async {
    try {
      await _firestore.claims.doc(claimId).update({
        'status': status.name,
        'resolvedAt': Timestamp.now(),
      });
    } on FirebaseException catch (e) {
      throw RepositoryException('Failed to resolve claim: ${e.message}');
    }
  }
}
