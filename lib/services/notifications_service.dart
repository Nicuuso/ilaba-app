import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ilaba/models/notification_model.dart';

/// Service to manage order status notifications
class NotificationsService {
  static final NotificationsService _instance = NotificationsService._internal();

  factory NotificationsService() {
    return _instance;
  }

  NotificationsService._internal();

  final supabase = Supabase.instance.client;

  /// Status change messages - professional and kind
  static const Map<String, Map<String, String>> statusMessages = {
    'pending': {
      'title': 'Order Confirmed! 🎉',
      'message': 'We\'ve received your order and will get it ready for you shortly.',
    },
    'for_pick-up': {
      'title': 'Ready for Pickup! 📦',
      'message': 'Your order is ready and waiting for you. Stop by whenever you\'re ready!',
    },
    'processing': {
      'title': 'Processing Your Order 🧺',
      'message': 'Our team is now processing your laundry with care.',
    },
    'for_delivery': {
      'title': 'On the Way! 🚚',
      'message': 'Your order is out for delivery. It will arrive soon!',
    },
    'completed': {
      'title': 'Order Complete! ✨',
      'message': 'Your order has been successfully delivered. Thank you for choosing us!',
    },
    'cancelled': {
      'title': 'Order Cancelled',
      'message': 'Your order has been cancelled. Please contact us if you have any questions.',
    },
  };

  /// Create a notification when order status changes
  Future<NotificationModel?> createStatusChangeNotification({
    required String customerId,
    required String orderId,
    required String newStatus,
    String? previousStatus,
  }) async {
    try {
      print('📲 Creating status change notification');
      print('   Order ID: $orderId');
      print('   Previous: $previousStatus → New: $newStatus');

      // Generate simple ID using timestamp and random
      final notificationId = '${DateTime.now().millisecondsSinceEpoch}_${orderId.substring(0, 8)}';
      final now = DateTime.now();

      // Get message template
      final messageData = statusMessages[newStatus] ?? {
        'title': 'Order Updated',
        'message': 'Your order status has been updated.',
      };

      final notification = NotificationModel(
        id: notificationId,
        customerId: customerId,
        orderId: orderId,
        title: messageData['title']!,
        message: messageData['message']!,
        status: newStatus,
        type: 'status_change',
        createdAt: now,
        isRead: false,
        metadata: {
          'previous_status': previousStatus,
          'new_status': newStatus,
        },
      );

      // Store in Supabase
      await supabase.from('notifications').insert(
        notification.toJson(),
      );

      print('✅ Notification created successfully');
      return notification;
    } catch (e) {
      print('❌ Error creating notification: $e');
      return null;
    }
  }

  /// Fetch all notifications for a customer
  Future<List<NotificationModel>> fetchCustomerNotifications(
    String customerId, {
    int limit = 50,
  }) async {
    try {
      print('📲 Fetching notifications for customer: $customerId');

      final response = await supabase
          .from('notifications')
          .select()
          .eq('customer_id', customerId)
          .order('created_at', ascending: false)
          .limit(limit);

      print('✅ Fetched ${response.length} notifications');

      return (response as List)
          .map((item) => NotificationModel.fromJson(
              item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('❌ Error fetching notifications: $e');
      return [];
    }
  }

  /// Fetch unread notification count
  Future<int> getUnreadCount(String customerId) async {
    try {
      final response = await supabase
          .from('notifications')
          .select()
          .eq('customer_id', customerId)
          .eq('is_read', false);

      return (response as List).length;
    } catch (e) {
      print('❌ Error fetching unread count: $e');
      return 0;
    }
  }

  /// Mark notification as read
  Future<bool> markAsRead(String notificationId) async {
    try {
      await supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('id', notificationId);

      return true;
    } catch (e) {
      print('❌ Error marking notification as read: $e');
      return false;
    }
  }

  /// Mark all notifications as read for a customer
  Future<bool> markAllAsRead(String customerId) async {
    try {
      await supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('customer_id', customerId)
          .eq('is_read', false);

      return true;
    } catch (e) {
      print('❌ Error marking all as read: $e');
      return false;
    }
  }

  /// Delete a notification
  Future<bool> deleteNotification(String notificationId) async {
    try {
      await supabase
          .from('notifications')
          .delete()
          .eq('id', notificationId);

      return true;
    } catch (e) {
      print('❌ Error deleting notification: $e');
      return false;
    }
  }

  /// Delete all notifications for a customer
  Future<bool> deleteAllNotifications(String customerId) async {
    try {
      await supabase
          .from('notifications')
          .delete()
          .eq('customer_id', customerId);

      return true;
    } catch (e) {
      print('❌ Error deleting all notifications: $e');
      return false;
    }
  }
}
