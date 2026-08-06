import '../models/claim_request.dart';
import '../models/enums.dart';

abstract class ClaimRepository {
  Future<ClaimRequest> createClaim(ClaimRequest claim);

  Stream<List<ClaimRequest>> watchClaimsForPost(String postId);

  Stream<List<ClaimRequest>> watchClaimsByUser(String userId);

  Future<void> resolveClaim(String claimId, ClaimStatus status);
}
