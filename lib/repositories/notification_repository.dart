import '../models/notification_item.dart';

abstract class NotificationRepository {
  Stream<List<NotificationItem>> watchNotifications(String userId);

  Future<void> createNotification(NotificationItem notification);

  Future<void> markAsRead(String notificationId);
}
