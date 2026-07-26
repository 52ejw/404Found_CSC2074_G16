import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/utils/firestore_converters.dart';
import 'enums.dart';

/// Corresponds to a document in the `claims/{claimId}` collection.
class ClaimRequest {
  final String id;
  final String postId;
  final String claimantId;
  final String finderId;
  final String proofDescription;
  final ClaimStatus status;
  final DateTime createdAt;
  final DateTime? resolvedAt;

  const ClaimRequest({
    required this.id,
    required this.postId,
    required this.claimantId,
    required this.finderId,
    required this.proofDescription,
    this.status = ClaimStatus.pending,
    required this.createdAt,
    this.resolvedAt,
  });

  factory ClaimRequest.fromMap(String id, Map<String, dynamic> map) {
    return ClaimRequest(
      id: id,
      postId: map['postId'] as String? ?? '',
      claimantId: map['claimantId'] as String? ?? '',
      finderId: map['finderId'] as String? ?? '',
      proofDescription: map['proofDescription'] as String? ?? '',
      status: enumFromName(ClaimStatus.values, map['status'] as String?, ClaimStatus.pending),
      createdAt: dateTimeFromFirestore(map['createdAt']),
      resolvedAt: nullableDateTimeFromFirestore(map['resolvedAt']),
    );
  }

  factory ClaimRequest.fromDocument(DocumentSnapshot<Map<String, dynamic>> doc) {
    return ClaimRequest.fromMap(doc.id, doc.data() ?? const {});
  }

  Map<String, dynamic> toMap() {
    return {
      'postId': postId,
      'claimantId': claimantId,
      'finderId': finderId,
      'proofDescription': proofDescription,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'resolvedAt': resolvedAt == null ? null : Timestamp.fromDate(resolvedAt!),
    };
  }
}
