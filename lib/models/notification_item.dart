import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/utils/firestore_converters.dart';
import 'enums.dart';

/// Corresponds to a document in the `notifications/{notificationId}`
/// collection.
class NotificationItem {
  final String id;
  final String userId;
  final NotificationType type;
  final String title;
  final String body;
  final String relatedEntityId;
  final bool isRead;
  final DateTime createdAt;

  const NotificationItem({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    required this.relatedEntityId,
    this.isRead = false,
    required this.createdAt,
  });

  factory NotificationItem.fromMap(String id, Map<String, dynamic> map) {
    return NotificationItem(
      id: id,
      userId: map['userId'] as String? ?? '',
      type: enumFromName(
        NotificationType.values,
        map['type'] as String?,
        NotificationType.message,
      ),
      title: map['title'] as String? ?? '',
      body: map['body'] as String? ?? '',
      relatedEntityId: map['relatedEntityId'] as String? ?? '',
      isRead: map['isRead'] as bool? ?? false,
      createdAt: dateTimeFromFirestore(map['createdAt']),
    );
  }

  factory NotificationItem.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    return NotificationItem.fromMap(doc.id, doc.data() ?? const {});
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'type': type.name,
      'title': title,
      'body': body,
      'relatedEntityId': relatedEntityId,
      'isRead': isRead,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
