import '../models/notification_item.dart';

/// Contract for the `notifications` collection (FR14).
///
/// Interface owned by Backend Developer 1 as part of the shared repository
/// contracts; the concrete implementation is owned by Backend Developer 2.
abstract class NotificationRepository {
  Stream<List<NotificationItem>> watchNotifications(String userId);

  Future<void> createNotification(NotificationItem notification);

  Future<void> markAsRead(String notificationId);
}
