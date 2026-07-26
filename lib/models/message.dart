import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/utils/firestore_converters.dart';

/// Corresponds to a document in the
/// `conversations/{conversationId}/messages/{messageId}` subcollection.
class Message {
  final String id;
  final String conversationId;
  final String senderId;
  final String text;
  final DateTime sentAt;
  final bool isRead;

  const Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.text,
    required this.sentAt,
    this.isRead = false,
  });

  factory Message.fromMap(String id, Map<String, dynamic> map) {
    return Message(
      id: id,
      conversationId: map['conversationId'] as String? ?? '',
      senderId: map['senderId'] as String? ?? '',
      text: map['text'] as String? ?? '',
      sentAt: dateTimeFromFirestore(map['sentAt']),
      isRead: map['isRead'] as bool? ?? false,
    );
  }

  factory Message.fromDocument(DocumentSnapshot<Map<String, dynamic>> doc) {
    return Message.fromMap(doc.id, doc.data() ?? const {});
  }

  Map<String, dynamic> toMap() {
    return {
      'conversationId': conversationId,
      'senderId': senderId,
      'text': text,
      'sentAt': Timestamp.fromDate(sentAt),
      'isRead': isRead,
    };
  }
}
