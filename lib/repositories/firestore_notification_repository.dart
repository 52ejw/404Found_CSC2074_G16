import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/errors/app_exception.dart';
import '../models/notification_item.dart';
import '../services/firestore_service.dart';
import 'notification_repository.dart';

class FirestoreNotificationRepository implements NotificationRepository {
  final FirestoreService _firestore;

  FirestoreNotificationRepository({FirestoreService? firestore})
    : _firestore = firestore ?? FirestoreService();

  @override
  Stream<List<NotificationItem>> watchNotifications(String userId) {
    return _firestore.notifications
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  @override
  Future<void> createNotification(NotificationItem notification) async {
    try {
      final docRef = _firestore.notifications.doc();
      final withId = NotificationItem.fromMap(docRef.id, notification.toMap());
      await docRef.set(withId);
    } on FirebaseException catch (e) {
      throw RepositoryException('Failed to create notification: ${e.message}');
    }
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore.notifications.doc(notificationId).update({
        'isRead': true,
      });
    } on FirebaseException catch (e) {
      throw RepositoryException(
        'Failed to mark notification as read: ${e.message}',
      );
    }
  }
}
