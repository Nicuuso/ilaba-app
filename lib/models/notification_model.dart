/// Notification model for order status updates
class NotificationModel {
  final String id;
  final String customerId;
  final String orderId;
  final String title;
  final String message;
  final String status; // pending, for_pick-up, processing, for_delivery, completed, cancelled
  final String type; // 'status_change', 'order_update', 'system'
  final DateTime createdAt;
  final bool isRead;
  final Map<String, dynamic>? metadata; // Additional data like previous status

  NotificationModel({
    required this.id,
    required this.customerId,
    required this.orderId,
    required this.title,
    required this.message,
    required this.status,
    required this.type,
    required this.createdAt,
    this.isRead = false,
    this.metadata,
  });

  /// Convert notification to JSON
  Map<String, dynamic> toJson() => {
    'id': id,
    'customer_id': customerId,
    'order_id': orderId,
    'title': title,
    'message': message,
    'status': status,
    'type': type,
    'created_at': createdAt.toIso8601String(),
    'is_read': isRead,
    'metadata': metadata,
  };

  /// Create notification from JSON
  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String? ?? '',
      customerId: json['customer_id'] as String? ?? '',
      orderId: json['order_id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      message: json['message'] as String? ?? '',
      status: json['status'] as String? ?? '',
      type: json['type'] as String? ?? 'order_update',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      isRead: json['is_read'] as bool? ?? false,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Create a copy with modified fields
  NotificationModel copyWith({
    String? id,
    String? customerId,
    String? orderId,
    String? title,
    String? message,
    String? status,
    String? type,
    DateTime? createdAt,
    bool? isRead,
    Map<String, dynamic>? metadata,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      orderId: orderId ?? this.orderId,
      title: title ?? this.title,
      message: message ?? this.message,
      status: status ?? this.status,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      metadata: metadata ?? this.metadata,
    );
  }
}
