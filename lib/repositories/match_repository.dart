import '../models/enums.dart';
import '../models/match_result.dart';

/// Contract for the `matches` collection (FR09 smart matching, section 7).
///
/// Interface owned by Backend Developer 1 as part of the shared repository
/// contracts; the concrete implementation and the matching algorithm itself
/// are owned by Backend Developer 2.
abstract class MatchRepository {
  Stream<List<MatchResult>> watchMatchesForPost(String postId);

  Stream<List<MatchResult>> watchMatchesForUser(String userId);

  Future<void> updateMatchStatus(String matchId, MatchStatus status);
}
