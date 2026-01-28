import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ilaba/providers/auth_provider.dart';
import 'package:ilaba/screens/orders/order_details_screen.dart';
import 'package:ilaba/screens/orders/order_details_helpers.dart';
import 'package:ilaba/constants/ilaba_colors.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  late Future<List<Map<String, dynamic>>> _ordersFuture;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  void _loadOrders() {
    final authProvider = context.read<AuthProvider>();
    final customerId = authProvider.currentUser?.id;

    if (customerId != null) {
      _ordersFuture = _fetchAllOrders(customerId);
    } else {
      _ordersFuture = Future.value([]);
    }
  }

  Future<void> _refreshOrders() async {
    setState(() {
      _loadOrders();
    });
    await _ordersFuture;
  }

  Future<List<Map<String, dynamic>>> _fetchAllOrders(String customerId) async {
    try {
      final supabase = Supabase.instance.client;

      final response = await supabase
          .from('orders')
          .select()
          .eq('customer_id', customerId)
          .order('created_at', ascending: false);

      // Supabase always returns a list, safely convert each item
      final List<dynamic> dataList = response as List<dynamic>;
      return dataList.map((item) {
        if (item is Map<String, dynamic>) {
          return item;
        } else if (item is Map) {
          return Map<String, dynamic>.from(item);
        } else {
          return <String, dynamic>{};
        }
      }).toList();
    } catch (e) {
      debugPrint('❌ Error fetching orders: $e');
      rethrow;
    }
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

  Color _getStatusColor(String? status) {
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

  IconData _getStatusIcon(String? status) {
    final normalizedStatus = _normalizeStatus(status);
    switch (normalizedStatus) {
      case 'pending':
        return Icons.schedule;
      case 'for_pick-up':
        return Icons.local_shipping;
      case 'processing':
        return Icons.local_laundry_service;
      case 'for_delivery':
        return Icons.delivery_dining;
      case 'completed':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }

  String _getStatusLabel(String? status) {
    final normalizedStatus = _normalizeStatus(status);
    switch (normalizedStatus) {
      case 'pending':
        return 'Pending';
      case 'for_pick-up':
        return 'Pick-up';
      case 'processing':
        return 'Processing';
      case 'for_delivery':
        return 'Delivery';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status?.toUpperCase() ?? 'Unknown';
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return '${months[date.month - 1]} ${date.day}, ${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  String _formatCurrency(dynamic amount) {
    if (amount == null) return '₱0.00';
    final value = amount is String
        ? double.tryParse(amount) ?? 0
        : (amount as num).toDouble();
    return '₱${value.toStringAsFixed(2)}';
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Orders',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: ILabaColors.darkText,
          ),
        ),
        backgroundColor: ILabaColors.white,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: ILabaColors.burgundy),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshOrders,
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _ordersFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: ILabaColors.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Failed to load orders',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: ILabaColors.darkText,
                          ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: () => setState(() => _loadOrders()),
                      child: const Text('Try Again'),
                    ),
                  ],
                ),
              );
            }

            final orders = snapshot.data ?? [];

            if (orders.isEmpty) {
              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: ILabaColors.burgundy.withOpacity(0.1),
                          ),
                          child: const Icon(
                            Icons.shopping_bag_outlined,
                            size: 50,
                            color: ILabaColors.burgundy,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'No Orders Yet',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Start booking laundry services today',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            return ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];
                return _buildOrderCard(order);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final orderId = order['id'].toString().substring(0, 12).toUpperCase();
    // Use effective status from handling JSONB instead of just main status
    final status = OrderDetailsHelpers.getEffectiveStatus(order);
    final totalAmount = _formatCurrency(order['total_amount']);
    final createdAt = _formatDate(order['created_at']);

    // Extract breakdown for item count
    final breakdown = order['breakdown'] as Map<String, dynamic>? ?? {};
    final items = (breakdown['items'] as List?) ?? [];
    final itemCount = items.length;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!, width: 0.8),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OrderDetailsScreen(order: order),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Order header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order #$orderId',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          createdAt,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(status).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getStatusIcon(status),
                          size: 16,
                          color: _getStatusColor(status),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _getStatusLabel(status),
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: _getStatusColor(status),
                                fontSize: 13,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Divider(color: Colors.grey[200], height: 1),
              const SizedBox(height: 12),
              // Order details
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Items',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$itemCount item${itemCount != 1 ? 's' : ''}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Total',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        totalAmount,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: Colors.green[700],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
