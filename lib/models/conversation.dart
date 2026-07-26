import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/utils/firestore_converters.dart';

/// Corresponds to a document in the `conversations/{conversationId}`
/// collection. Messages live in the `messages` subcollection ([Message]).
class Conversation {
  final String id;
  final List<String> participantIds;
  final String relatedPostId;
  final String lastMessage;
  final DateTime lastMessageAt;

  /// Unread message count per participant, keyed by userId, so each user's
  /// chat list badge can be read without scanning the messages subcollection.
  final Map<String, int> unreadCounts;

  const Conversation({
    required this.id,
    required this.participantIds,
    required this.relatedPostId,
    this.lastMessage = '',
    required this.lastMessageAt,
    this.unreadCounts = const {},
  });

  factory Conversation.fromMap(String id, Map<String, dynamic> map) {
    return Conversation(
      id: id,
      participantIds: List<String>.from(map['participantIds'] as List? ?? const []),
      relatedPostId: map['relatedPostId'] as String? ?? '',
      lastMessage: map['lastMessage'] as String? ?? '',
      lastMessageAt: dateTimeFromFirestore(map['lastMessageAt']),
      unreadCounts: Map<String, int>.from(map['unreadCounts'] as Map? ?? const {}),
    );
  }

  factory Conversation.fromDocument(DocumentSnapshot<Map<String, dynamic>> doc) {
    return Conversation.fromMap(doc.id, doc.data() ?? const {});
  }

  Map<String, dynamic> toMap() {
    return {
      'participantIds': participantIds,
      'relatedPostId': relatedPostId,
      'lastMessage': lastMessage,
      'lastMessageAt': Timestamp.fromDate(lastMessageAt),
      'unreadCounts': unreadCounts,
    };
  }
}
