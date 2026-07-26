import '../models/claim_request.dart';
import '../models/enums.dart';

/// Contract for the `claims` collection (FR11/FR12 claim request and
/// resolution).
///
/// Interface owned by Backend Developer 1 as part of the shared repository
/// contracts; the concrete implementation is owned by Backend Developer 2.
abstract class ClaimRepository {
  Future<ClaimRequest> createClaim(ClaimRequest claim);

  Stream<List<ClaimRequest>> watchClaimsForPost(String postId);

  Stream<List<ClaimRequest>> watchClaimsByUser(String userId);

  /// Finder accepts/rejects (FR12); accepted claims may later transition to
  /// [ClaimStatus.returned].
  Future<void> resolveClaim(String claimId, ClaimStatus status);
}
