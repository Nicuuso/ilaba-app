import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ilaba/providers/notifications_provider.dart';
import 'package:ilaba/models/notification_model.dart';
import 'package:intl/intl.dart';
import 'package:ilaba/constants/ilaba_colors.dart';

class NotificationsCenterScreen extends StatefulWidget {
  const NotificationsCenterScreen({super.key});

  @override
  State<NotificationsCenterScreen> createState() =>
      _NotificationsCenterScreenState();
}

class _NotificationsCenterScreenState extends State<NotificationsCenterScreen> {
  /// Track which notifications are expanded
  final Map<String, bool> _expandedNotifications = {};

  @override
  void initState() {
    super.initState();
    // Refresh notifications when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        context.read<NotificationsProvider>().fetchNotifications();
      } catch (e) {
        debugPrint('Error accessing NotificationsProvider: $e');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Notifications',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: ILabaColors.darkText,
          ),
        ),
        elevation: 0,
        backgroundColor: ILabaColors.white,
        centerTitle: false,
        iconTheme: const IconThemeData(color: ILabaColors.burgundy),
        actions: [
          Consumer<NotificationsProvider>(
            builder: (context, provider, _) {
              if (provider.notifications.isEmpty) return const SizedBox.shrink();

              return PopupMenuButton(
                onSelected: (value) {
                  if (value == 'mark_all') {
                    provider.markAllAsRead();
                  } else if (value == 'delete_all') {
                    _showDeleteAllConfirmation(context, provider);
                  }
                },
                itemBuilder: (BuildContext context) => [
                  const PopupMenuItem(
                    value: 'mark_all',
                    child: Row(
                      children: [
                        Icon(Icons.done_all, size: 20),
                        SizedBox(width: 12),
                        Text('Mark all as read'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete_all',
                    child: Row(
                      children: [
                        Icon(Icons.delete_sweep, size: 20),
                        SizedBox(width: 12),
                        Text('Delete all'),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: Consumer<NotificationsProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (provider.notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No notifications yet',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'We\'ll notify you when your order status changes',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[500],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => provider.fetchNotifications(),
            child: ListView.builder(
              itemCount: provider.notifications.length,
              padding: const EdgeInsets.all(12),
              itemBuilder: (context, index) {
                final notification = provider.notifications[index];
                return _buildNotificationCard(context, notification, provider);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildNotificationCard(
    BuildContext context,
    NotificationModel notification,
    NotificationsProvider provider,
  ) {
    final isRead = notification.isRead;
    final statusColor = _getStatusColor(notification.status);
    final isExpanded = _expandedNotifications[notification.id] ?? false;

    return GestureDetector(
      onTap: () {
        // Mark as read when first tapped
        if (!isRead) {
          provider.markAsRead(notification.id);
        }
        // Toggle expansion
        setState(() {
          _expandedNotifications[notification.id] = !isExpanded;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isRead ? ILabaColors.white : Colors.blue[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isRead ? Colors.grey[200]! : statusColor.withOpacity(0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: ILabaColors.darkText.withOpacity(isExpanded ? 0.08 : 0.04),
              blurRadius: isExpanded ? 12 : 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row (always visible)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status indicator dot
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isRead ? Colors.grey[400] : statusColor,
                    ),
                    margin: const EdgeInsets.only(top: 4),
                  ),
                  const SizedBox(width: 12),
                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                notification.title,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                  fontWeight: isRead
                                      ? FontWeight.w500
                                      : FontWeight.w700,
                                  color: Colors.grey[900],
                                ),
                              ),
                            ),
                            if (!isRead)
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: statusColor,
                                ),
                                margin: const EdgeInsets.only(left: 8),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          notification.message,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[700],
                            height: 1.4,
                          ),
                          maxLines: isExpanded ? null : 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Expand/Collapse icon
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 300),
                    child: Icon(
                      Icons.expand_more,
                      color: statusColor,
                      size: 24,
                    ),
                  ),
                ],
              ),
              // Expanded details section
              AnimatedCrossFade(
                firstChild: const SizedBox.shrink(),
                secondChild: _buildExpandedDetails(
                  context,
                  notification,
                  statusColor,
                  provider,
                  isRead,
                ),
                crossFadeState: isExpanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 300),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpandedDetails(
    BuildContext context,
    NotificationModel notification,
    Color statusColor,
    NotificationsProvider provider,
    bool isRead,
  ) {
    final orderId = notification.orderId;
    final status = notification.status;
    final metadata = notification.metadata ?? {};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Divider(color: Colors.grey[300], thickness: 1),
        const SizedBox(height: 12),
        // Order details section
        _buildDetailRow(
          context,
          'Order ID',
          orderId,
          Icons.receipt_long_outlined,
          statusColor,
        ),
        const SizedBox(height: 10),
        _buildDetailRow(
          context,
          'Status',
          _getStatusLabel(status),
          Icons.info_outline,
          statusColor,
        ),
        const SizedBox(height: 10),
        _buildDetailRow(
          context,
          'Time',
          _formatTime(notification.createdAt),
          Icons.access_time,
          statusColor,
        ),
        // Additional metadata if available
        if (metadata.isNotEmpty) ...[
          const SizedBox(height: 10),
          if (metadata.containsKey('pickup_time'))
            _buildDetailRow(
              context,
              'Pickup Time',
              metadata['pickup_time'] as String,
              Icons.location_on_outlined,
              statusColor,
            ),
          if (metadata.containsKey('delivery_address'))
            _buildDetailRow(
              context,
              'Delivery Address',
              metadata['delivery_address'] as String,
              Icons.location_on_outlined,
              statusColor,
            ),
          if (metadata.containsKey('notes'))
            _buildDetailRow(
              context,
              'Notes',
              metadata['notes'] as String,
              Icons.notes,
              statusColor,
            ),
        ],
        const SizedBox(height: 12),
        // Action buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (!isRead)
              TextButton.icon(
                onPressed: () {
                  provider.markAsRead(notification.id);
                },
                icon: const Icon(Icons.done, size: 16),
                label: const Text('Mark Read'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            const SizedBox(width: 8),
            TextButton.icon(
              onPressed: () {
                _showDeleteConfirmation(
                  context,
                  notification.id,
                  provider,
                );
              },
              icon: const Icon(Icons.delete_outline, size: 16),
              label: const Text('Delete'),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                visualDensity: VisualDensity.compact,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color accentColor,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 18,
          color: accentColor,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[800],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Normalize status to match app's expected format
  /// Handles variations from website: for_pickup, for_pick-up, pickup, pick-up, for pickup, etc.
  String _normalizeStatus(String? status) {
    if (status == null || status.isEmpty) return 'pending';
    
    final lowerStatus = status.toLowerCase().trim();
    
    // Handle all pickup variations
    if (lowerStatus.contains('pick') && lowerStatus.contains('up')) {
      return 'for_pick-up';
    }
    if (lowerStatus == 'pickup' || lowerStatus == 'pick-up' || lowerStatus == 'pick_up') {
      return 'for_pick-up';
    }
    
    // Handle all delivery variations
    if (lowerStatus.contains('delivery') || lowerStatus == 'for_delivery' || lowerStatus == 'fordelivery') {
      return 'for_delivery';
    }
    
    // Return as-is for other statuses
    return lowerStatus;
  }

  String _getStatusLabel(String status) {
    final normalizedStatus = _normalizeStatus(status);
    switch (normalizedStatus) {
      case 'pending':
        return 'Order Pending 🎉';
      case 'for_pick-up':
        return 'Ready for Pickup 📦';
      case 'processing':
        return 'Processing 🧺';
      case 'for_delivery':
        return 'On the Way 🚚';
      case 'completed':
        return 'Order Complete ✨';
      case 'cancelled':
        return 'Order Cancelled ❌';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    final normalizedStatus = _normalizeStatus(status);
    switch (normalizedStatus) {
      case 'pending':
        return Colors.orange;
      case 'for_pick-up':
        return Colors.indigo;
      case 'processing':
        return Colors.blue;
      case 'for_delivery':
        return Colors.purple;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d').format(dateTime);
    }
  }

  void _showDeleteConfirmation(
    BuildContext context,
    String notificationId,
    NotificationsProvider provider,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Notification'),
          content: const Text('Are you sure you want to delete this notification?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                provider.deleteNotification(notificationId);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Notification deleted')),
                );
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteAllConfirmation(
    BuildContext context,
    NotificationsProvider provider,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete All Notifications'),
          content:
              const Text('Are you sure you want to delete all notifications?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                provider.deleteAllNotifications();
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('All notifications deleted')),
                );
              },
              child: const Text('Delete All',
                  style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}
