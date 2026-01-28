import 'package:flutter/material.dart';
import 'package:ilaba/models/notification_model.dart';
import 'package:ilaba/services/notifications_service.dart';

/// Provider for managing notifications state
class NotificationsProvider extends ChangeNotifier {
  final NotificationsService _notificationsService = NotificationsService();

  List<NotificationModel> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  String? _error;

  // Getters
  List<NotificationModel> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  String? get error => _error;

  String? _currentCustomerId;

  /// Initialize provider with customer ID
  void initialize(String customerId) {
    _currentCustomerId = customerId;
    fetchNotifications();
    _startPolling();
  }

  /// Start periodic polling for new notifications
  void _startPolling() {
    // Poll every 30 seconds for new notifications
    Future.delayed(const Duration(seconds: 30), () {
      if (_currentCustomerId != null) {
        fetchNotifications();
        _startPolling();
      }
    });
  }

  /// Fetch all notifications
  Future<void> fetchNotifications() async {
    if (_currentCustomerId == null) return;

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _notifications = await _notificationsService
          .fetchCustomerNotifications(_currentCustomerId!);
      
      // Calculate unread count
      _unreadCount = _notifications.where((n) => !n.isRead).length;

      print('✅ Fetched ${_notifications.length} notifications');
      print('   Unread: $_unreadCount');
    } catch (e) {
      _error = 'Failed to fetch notifications: $e';
      print('❌ $_error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Create a status change notification
  Future<void> notifyStatusChange({
    required String orderId,
    required String newStatus,
    String? previousStatus,
  }) async {
    if (_currentCustomerId == null) return;

    try {
      final notification = await _notificationsService
          .createStatusChangeNotification(
        customerId: _currentCustomerId!,
        orderId: orderId,
        newStatus: newStatus,
        previousStatus: previousStatus,
      );

      if (notification != null) {
        _notifications.insert(0, notification);
        _unreadCount++;
        notifyListeners();
        print('✅ Status change notification added to list');
      }
    } catch (e) {
      print('❌ Error creating notification: $e');
    }
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _notificationsService.markAsRead(notificationId);

      // Update local state
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _notifications[index] = _notifications[index].copyWith(isRead: true);
        _unreadCount = (_unreadCount - 1).clamp(0, _unreadCount);
        notifyListeners();
      }
    } catch (e) {
      print('❌ Error marking notification as read: $e');
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    if (_currentCustomerId == null) return;

    try {
      await _notificationsService.markAllAsRead(_currentCustomerId!);

      // Update local state
      _notifications = _notifications
          .map((n) => n.copyWith(isRead: true))
          .toList();
      _unreadCount = 0;
      notifyListeners();
    } catch (e) {
      print('❌ Error marking all as read: $e');
    }
  }

  /// Delete a notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _notificationsService.deleteNotification(notificationId);

      // Update local state
      _notifications.removeWhere((n) => n.id == notificationId);
      notifyListeners();
    } catch (e) {
      print('❌ Error deleting notification: $e');
    }
  }

  /// Delete all notifications
  Future<void> deleteAllNotifications() async {
    if (_currentCustomerId == null) return;

    try {
      await _notificationsService.deleteAllNotifications(_currentCustomerId!);
      _notifications.clear();
      _unreadCount = 0;
      notifyListeners();
    } catch (e) {
      print('❌ Error deleting all notifications: $e');
    }
  }

  /// Get unread count
  Future<void> refreshUnreadCount() async {
    if (_currentCustomerId == null) return;

    try {
      _unreadCount = await _notificationsService.getUnreadCount(_currentCustomerId!);
      notifyListeners();
    } catch (e) {
      print('❌ Error refreshing unread count: $e');
    }
  }
}
