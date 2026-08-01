import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/notification_item.dart';
import '../repositories/notification_repository.dart';

/// ViewModel for the notification bell + list (FR14).
class NotificationsProvider extends ChangeNotifier {
  NotificationsProvider({required NotificationRepository notificationRepository})
    : _notificationRepository = notificationRepository;

  final NotificationRepository _notificationRepository;

  StreamSubscription<List<NotificationItem>>? _sub;
  String? _userId;

  List<NotificationItem> _notifications = const [];
  List<NotificationItem> get notifications => _notifications;

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  void setUserId(String? userId) {
    if (_userId == userId) return;
    _userId = userId;
    _subscribe();
  }

  void retry() => _subscribe();

  Future<void> markAsRead(NotificationItem notification) async {
    if (notification.isRead) return;
    try {
      await _notificationRepository.markAsRead(notification.id);
    } catch (error) {
      debugPrint('Failed to mark notification as read: $error');
    }
  }

  void _subscribe() {
    _sub?.cancel();
    _notifications = const [];
    _error = null;
    final uid = _userId;
    _isLoading = uid != null;
    notifyListeners();
    if (uid == null) return;

    _sub = _notificationRepository.watchNotifications(uid).listen(
      (items) {
        _notifications = items;
        _isLoading = false;
        _error = null;
        notifyListeners();
      },
      onError: (Object error) {
        _error = _friendly(error);
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  String _friendly(Object error) {
    final value = error.toString();
    return value.startsWith('Exception: ') ? value.substring('Exception: '.length) : value;
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
