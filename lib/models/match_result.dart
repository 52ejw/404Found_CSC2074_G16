import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/utils/firestore_converters.dart';
import 'enums.dart';

/// Corresponds to a document in the `matches/{matchId}` collection.
///
/// Score fields are stored individually (not just [totalScore]) so the
/// match suggestions screen can show an explainable breakdown, per section
/// 7 of the blueprint.
class MatchResult {
  final String id;
  final String lostPostId;
  final String foundPostId;
  final double categoryScore;
  final double keywordScore;
  final double locationScore;
  final double dateScore;
  final double totalScore;
  final MatchStatus status;
  final DateTime createdAt;

  const MatchResult({
    required this.id,
    required this.lostPostId,
    required this.foundPostId,
    required this.categoryScore,
    required this.keywordScore,
    required this.locationScore,
    required this.dateScore,
    required this.totalScore,
    this.status = MatchStatus.suggested,
    required this.createdAt,
  });

  factory MatchResult.fromMap(String id, Map<String, dynamic> map) {
    return MatchResult(
      id: id,
      lostPostId: map['lostPostId'] as String? ?? '',
      foundPostId: map['foundPostId'] as String? ?? '',
      categoryScore: (map['categoryScore'] as num?)?.toDouble() ?? 0,
      keywordScore: (map['keywordScore'] as num?)?.toDouble() ?? 0,
      locationScore: (map['locationScore'] as num?)?.toDouble() ?? 0,
      dateScore: (map['dateScore'] as num?)?.toDouble() ?? 0,
      totalScore: (map['totalScore'] as num?)?.toDouble() ?? 0,
      status: enumFromName(MatchStatus.values, map['status'] as String?, MatchStatus.suggested),
      createdAt: dateTimeFromFirestore(map['createdAt']),
    );
  }

  factory MatchResult.fromDocument(DocumentSnapshot<Map<String, dynamic>> doc) {
    return MatchResult.fromMap(doc.id, doc.data() ?? const {});
  }

  Map<String, dynamic> toMap() {
    return {
      'lostPostId': lostPostId,
      'foundPostId': foundPostId,
      'categoryScore': categoryScore,
      'keywordScore': keywordScore,
      'locationScore': locationScore,
      'dateScore': dateScore,
      'totalScore': totalScore,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
