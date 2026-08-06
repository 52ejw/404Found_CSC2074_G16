import '../models/enums.dart';
import '../models/match_result.dart';

abstract class MatchRepository {
  Stream<List<MatchResult>> watchMatchesForPost(String postId);

  Stream<List<MatchResult>> watchMatchesForUser(String userId);

  Future<void> updateMatchStatus(String matchId, MatchStatus status);
}
