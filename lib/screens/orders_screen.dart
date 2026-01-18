import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ilaba/providers/auth_provider.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late Future<List<Map<String, dynamic>>> _activeOrdersFuture;
  late Future<List<Map<String, dynamic>>> _orderHistoryFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadOrders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadOrders() {
    final authProvider = context.read<AuthProvider>();
    final customerId = authProvider.currentUser?.id;

    if (customerId != null) {
      _activeOrdersFuture = _fetchActiveOrders(customerId);
      _orderHistoryFuture = _fetchOrderHistory(customerId);
    } else {
      _activeOrdersFuture = Future.value([]);
      _orderHistoryFuture = Future.value([]);
    }
  }

  Future<List<Map<String, dynamic>>> _fetchActiveOrders(
    String customerId,
  ) async {
    try {
      final supabase = Supabase.instance.client;

      final orders = await supabase
          .from('orders')
          .select()
          .eq('customer_id', customerId)
          .neq('status', 'completed')
          .neq('status', 'cancelled')
          .order('created_at', ascending: false);

      // Orders now have all data in JSON columns (breakdown, handling)
      return orders.cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('❌ Error fetching active orders: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> _fetchOrderHistory(
    String customerId,
  ) async {
    try {
      final supabase = Supabase.instance.client;

      final orders = await supabase
          .from('orders')
          .select()
          .eq('customer_id', customerId)
          .order('created_at', ascending: false);

      // Orders now have all data in JSON columns (breakdown, handling)
      // No need for additional fetches
      return orders.cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('❌ Error fetching order history: $e');
      rethrow;
    }
  }

  String _getOrderStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'processing':
        return 'Processing';
      case 'pick-up':
        return 'Pick-up';
      case 'delivering':
        return 'Delivering';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'in_progress':
        return Colors.orange;
      case 'pending':
        return Colors.blue;
      case 'processing':
        return Colors.orange;
      case 'pick-up':
        return Colors.indigo;
      case 'delivering':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String? status) {
    switch (status?.toLowerCase()) {
      case 'completed':
        return Icons.check_circle;
      case 'in_progress':
        return Icons.hourglass_top;
      case 'pending':
        return Icons.schedule;
      case 'processing':
        return Icons.local_laundry_service;
      case 'pick-up':
        return Icons.local_shipping;
      case 'delivering':
        return Icons.delivery_dining;
      default:
        return Icons.help_outline;
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return '${date.month}/${date.day}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Orders'),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.pink.shade400,
          labelColor: Colors.pink.shade400,
          unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
          tabs: const [
            Tab(icon: Icon(Icons.local_shipping_outlined), text: 'Active'),
            Tab(icon: Icon(Icons.history), text: 'History'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildActiveOrdersTab(), _buildOrderHistoryTab()],
      ),
    );
  }

  Widget _buildActiveOrdersTab() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _activeOrdersFuture,
      builder: (context, snapshot) => _buildOrdersList(
        snapshot,
        isPink: true,
        emptyTitle: 'No Active Orders',
        emptyDesc: 'All your orders are completed',
      ),
    );
  }

  Widget _buildOrderHistoryTab() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _orderHistoryFuture,
      builder: (context, snapshot) => _buildOrdersList(
        snapshot,
        isPink: false,
        emptyTitle: 'No Orders Yet',
        emptyDesc: 'Start booking laundry services today',
      ),
    );
  }

  Widget _buildOrdersList(
    AsyncSnapshot<List<Map<String, dynamic>>> snapshot, {
    required bool isPink,
    required String emptyTitle,
    required String emptyDesc,
  }) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(
            isPink ? Colors.pink.shade400 : Colors.blue.shade400,
          ),
        ),
      );
    }

    if (snapshot.hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
            const SizedBox(height: 16),
            Text(
              'Failed to load orders',
              style: Theme.of(context).textTheme.titleLarge,
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
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isPink ? Colors.pink.shade100 : Colors.blue.shade100,
              ),
              child: Icon(
                Icons.shopping_bag_outlined,
                size: 50,
                color: isPink ? Colors.pink.shade400 : Colors.blue.shade400,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              emptyTitle,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              emptyDesc,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        return isPink
            ? _buildActiveOrderCard(order)
            : _buildHistoryOrderCard(order);
      },
    );
  }

  Widget _buildActiveOrderCard(Map<String, dynamic> order) {
    final color = Colors.pink.shade400;
    final orderId = order['id'];
    final status = order['status'] ?? 'processing';
    final baskets = order['baskets'] as List? ?? [];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: color.withOpacity(0.06),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withOpacity(0.1),
                  ),
                  child: Icon(
                    Icons.shopping_bag_outlined,
                    color: color,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order #${orderId.toString().substring(0, 8)}',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(status).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _getOrderStatusLabel(status),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _getStatusColor(status),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildServiceTimeline(baskets),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryOrderCard(Map<String, dynamic> order) {
    final color = Colors.blue.shade400;
    final orderId = order['id'];
    final status = order['status'] ?? 'pending';
    final createdAt = _formatDate(order['created_at']);

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => _OrderHistoryDetailsPage(order: order),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: 0,
        color: color.withOpacity(0.06),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.shopping_bag_outlined, size: 18, color: color),
                  const SizedBox(width: 8),
                  Text(
                    'Order #${orderId.toString().substring(0, 8)}',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 14,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    createdAt,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(status).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: _getStatusColor(status),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.arrow_forward, size: 16, color: color),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildServiceTimeline(List baskets) {
    if (baskets.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(baskets.length, (basketIndex) {
        final basket = baskets[basketIndex];
        final basketServices = basket['services'] as List? ?? [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (basketIndex > 0)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Divider(
                  color: Colors.pink.shade200.withOpacity(0.15),
                  height: 1,
                ),
              ),
            Row(
              children: [
                Icon(
                  Icons.local_laundry_service_outlined,
                  size: 18,
                  color: Colors.pink.shade400,
                ),
                const SizedBox(width: 8),
                Text(
                  'Basket #${basket['basket_number']}',
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(basket['status']).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    (basket['status'] ?? 'N/A').toString().toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: _getStatusColor(basket['status']),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (basketServices.isNotEmpty)
              Column(
                children: List.generate(basketServices.length, (serviceIndex) {
                  final service = basketServices[serviceIndex];
                  final serviceName = service['services']?['name'] ?? 'Service';
                  final serviceStatus = service['status'] ?? 'pending';
                  final isCompleted = serviceStatus == 'completed';
                  final isInProgress = serviceStatus == 'in_progress';

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _getStatusColor(
                                  serviceStatus,
                                ).withOpacity(0.2),
                                border: Border.all(
                                  color: _getStatusColor(serviceStatus),
                                  width: 2,
                                ),
                              ),
                              child: Center(
                                child: Icon(
                                  isCompleted
                                      ? Icons.check_rounded
                                      : _getStatusIcon(serviceStatus),
                                  size: 12,
                                  color: _getStatusColor(serviceStatus),
                                ),
                              ),
                            ),
                            if (serviceIndex < basketServices.length - 1)
                              Container(
                                width: 2,
                                height: 40,
                                color: _getStatusColor(
                                  serviceStatus,
                                ).withOpacity(0.3),
                              ),
                          ],
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _getStatusColor(
                                serviceStatus,
                              ).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        serviceName,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    if (isInProgress)
                                      SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                _getStatusColor(serviceStatus),
                                              ),
                                        ),
                                      ),
                                    if (isCompleted)
                                      Icon(
                                        Icons.check_circle,
                                        size: 14,
                                        color: _getStatusColor(serviceStatus),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Amount: ₱${service['subtotal']}',
                                  style: Theme.of(context).textTheme.labelSmall
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
                      ],
                    ),
                  );
                }),
              ),
          ],
        );
      }),
    );
  }

  Widget _buildBasketsSection(List baskets, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Baskets',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        ...baskets.map((basket) {
          final basketServices = basket['services'] as List? ?? [];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.local_laundry_service_outlined,
                            size: 18,
                            color: color,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Basket #${basket['basket_number']}',
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(
                            basket['status'],
                          ).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          (basket['status'] ?? 'N/A').toString().toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: _getStatusColor(basket['status']),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (basket['weight'] != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Icon(
                            Icons.scale,
                            size: 16,
                            color: color.withOpacity(0.6),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Weight: ${basket['weight']} kg',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  if (basket['price'] != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Icon(Icons.attach_money, size: 16, color: color),
                          const SizedBox(width: 8),
                          Text(
                            '₱${basket['price']}',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: color,
                                ),
                          ),
                        ],
                      ),
                    ),
                  if (basketServices.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      'Services',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    ...basketServices.map((service) {
                      final serviceName =
                          service['services']?['name'] ?? 'Unknown';
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                '• $serviceName',
                                style: Theme.of(context).textTheme.bodySmall,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '₱${service['subtotal']}',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: color,
                                  ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildPaymentsSection(List payments, Color color, List baskets) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (baskets.isNotEmpty) const SizedBox(height: 16),
        Text(
          'Payment',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        ...payments.map((payment) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.payment_outlined, size: 18, color: color),
                          const SizedBox(width: 8),
                          Text(
                            '₱${payment['amount']}',
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: color,
                                ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(
                            payment['status'],
                          ).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          (payment['status'] ?? 'N/A').toString().toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: _getStatusColor(payment['status']),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(
                        Icons.account_balance_wallet_outlined,
                        size: 16,
                        color: color.withOpacity(0.6),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Method: ${payment['method'] ?? 'N/A'}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  if (payment['reference_number'] != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Row(
                        children: [
                          Icon(
                            Icons.receipt_long_outlined,
                            size: 16,
                            color: color.withOpacity(0.6),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Ref: ${payment['reference_number']}',
                              style: Theme.of(context).textTheme.bodySmall,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }
}

// History Details Page
class _OrderHistoryDetailsPage extends StatelessWidget {
  final Map<String, dynamic> order;

  const _OrderHistoryDetailsPage({required this.order});

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
      final period = date.hour >= 12 ? 'PM' : 'AM';
      final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
      return '${months[date.month - 1]} ${date.day}, ${date.year} ${hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')} $period';
    } catch (e) {
      return dateString;
    }
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'processing':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderId = order['id'];
    final status = order['status'] ?? 'N/A';
    final createdAt = _formatDate(order['created_at']);
    final breakdown = order['breakdown'] as Map<String, dynamic>? ?? {};
    final handling = order['handling'] as Map<String, dynamic>? ?? {};
    final cancellation = order['cancellation'] as Map<String, dynamic>?;
    final totalAmount = (order['total_amount'] ?? 0).toString();

    // Parse breakdown structure
    final breakdownItems = (breakdown['items'] as List?) ?? [];
    final breakdownBaskets = (breakdown['baskets'] as List?) ?? [];
    final breakdownFees = (breakdown['fees'] as List?) ?? [];
    final breakdownDiscounts = (breakdown['discounts'] as List?) ?? [];
    final breakdownSummary =
        (breakdown['summary'] as Map<String, dynamic>?) ?? {};
    final breakdownPayment =
        (breakdown['payment'] as Map<String, dynamic>?) ?? {};
    final breakdownAuditLog = (breakdown['audit_log'] as List?) ?? [];

    // Parse handling
    final pickupData = (handling['pickup'] as Map<String, dynamic>?) ?? {};
    final deliveryData = (handling['delivery'] as Map<String, dynamic>?) ?? {};

    return Scaffold(
      appBar: AppBar(
        title: Text('Order #${orderId.toString().substring(0, 8)}'),
        elevation: 0,
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🎯 Order Summary Card
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _getStatusColor(status).withOpacity(0.15),
                    _getStatusColor(status).withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _getStatusColor(status).withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Order Status',
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: _getStatusColor(status),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              status.toUpperCase(),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Total Amount',
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '₱$totalAmount',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: _getStatusColor(status),
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildInfoItem(
                        context,
                        Icons.calendar_today_outlined,
                        'Created',
                        createdAt,
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: Theme.of(context).dividerColor,
                      ),
                      _buildInfoItem(
                        context,
                        Icons.receipt_outlined,
                        'Order ID',
                        orderId.toString().substring(0, 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // 🛍️ Product Items Section
            if (breakdownItems.isNotEmpty) ...[
              _buildSectionHeader(
                context,
                Icons.shopping_bag_outlined,
                'Products',
                breakdownItems.length.toString(),
              ),
              const SizedBox(height: 12),
              ...breakdownItems.asMap().entries.map((entry) {
                final item = entry.value as Map<String, dynamic>;
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey[300]!, width: 1),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['product_name'] ?? 'Unknown Product',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Qty: ${item['quantity'] ?? 0}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            Text(
                              '₱${item['unit_price'] ?? 0} each',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            Text(
                              'Subtotal: ₱${item['subtotal'] ?? 0}',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        if (item['discount'] != null) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red[50],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Discount: -₱${item['discount']['amount']}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.red[700],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }).toList(),
              const SizedBox(height: 28),
            ],

            // 🧺 Laundry Baskets Section
            if (breakdownBaskets.isNotEmpty) ...[
              _buildSectionHeader(
                context,
                Icons.local_laundry_service_outlined,
                'Laundry Baskets',
                breakdownBaskets.length.toString(),
              ),
              const SizedBox(height: 12),
              ...breakdownBaskets.asMap().entries.map((entry) {
                final basket = entry.value as Map<String, dynamic>;
                final services = (basket['services'] as List?) ?? [];

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(
                      color: Colors.blue.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  color: Colors.blue.withOpacity(0.06),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Basket #${basket['basket_number'] ?? 'N/A'}',
                                  style: Theme.of(context).textTheme.titleSmall
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: _getStatusColor(
                                  basket['status'],
                                ).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                (basket['status'] ?? 'N/A')
                                    .toString()
                                    .toUpperCase(),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: _getStatusColor(basket['status']),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 16,
                          runSpacing: 8,
                          children: [
                            if (basket['weight'] != null)
                              _buildMetricChip(
                                Icons.scale,
                                '${basket['weight']} kg',
                                Colors.orange,
                              ),
                            if (basket['total'] != null)
                              _buildMetricChip(
                                Icons.attach_money,
                                '₱${basket['total']}',
                                Colors.green,
                              ),
                          ],
                        ),
                        if (basket['basket_notes'] != null &&
                            (basket['basket_notes'] as String).isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.orange[50],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.note_outlined,
                                  size: 16,
                                  color: Colors.orange[700],
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    basket['basket_notes'] ?? '',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.labelSmall,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        if (services.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          Text(
                            'Services',
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 10),
                          ...services.map((service) {
                            final svc = service as Map<String, dynamic>;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.blue.withOpacity(0.1),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            svc['service_name'] ?? 'Unknown',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _getStatusColor(
                                              svc['status'],
                                            ).withOpacity(0.15),
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: Text(
                                            (svc['status'] ?? 'pending')
                                                .toString()
                                                .toUpperCase(),
                                            style: TextStyle(
                                              fontSize: 9,
                                              fontWeight: FontWeight.w700,
                                              color: _getStatusColor(
                                                svc['status'],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Qty: ${svc['multiplier'] ?? 1}x @ ₱${svc['rate_per_kg'] ?? 0}/kg',
                                          style: Theme.of(
                                            context,
                                          ).textTheme.labelSmall,
                                        ),
                                        Text(
                                          '₱${svc['subtotal'] ?? 0}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelSmall
                                              ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.green,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ],
                      ],
                    ),
                  ),
                );
              }).toList(),
              const SizedBox(height: 28),
            ],

            // 📋 Fees Section
            if (breakdownFees.isNotEmpty) ...[
              _buildSectionHeader(
                context,
                Icons.receipt_long_outlined,
                'Fees',
                '',
              ),
              const SizedBox(height: 12),
              ...breakdownFees.map((fee) {
                final f = fee as Map<String, dynamic>;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amber[50],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              f['description'] ?? 'Fee',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            Text(
                              'Type: ${f['type'] ?? 'Unknown'}',
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '₱${f['amount']}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.amber[900],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              const SizedBox(height: 28),
            ],

            // 🎁 Discounts Section
            if (breakdownDiscounts.isNotEmpty) ...[
              _buildSectionHeader(
                context,
                Icons.local_offer_outlined,
                'Discounts Applied',
                '',
              ),
              const SizedBox(height: 12),
              ...breakdownDiscounts.map((discount) {
                final d = discount as Map<String, dynamic>;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${d['type']?.toString().toUpperCase() ?? 'Discount'} - ${d['value']}${d['value_type'] == 'percentage' ? '%' : ''}',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            if (d['reason'] != null)
                              Text(
                                d['reason'],
                                style: Theme.of(context).textTheme.labelSmall,
                              ),
                          ],
                        ),
                      ),
                      Text(
                        '-₱${d['applied_amount'] ?? 0}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.red[700],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              const SizedBox(height: 28),
            ],

            // 💰 Order Summary Section
            _buildSectionHeader(
              context,
              Icons.receipt_long_outlined,
              'Order Summary',
              '',
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.grey[50]!, Colors.grey[100]!],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSummaryRow(
                    context,
                    'Subtotal (Products)',
                    '₱${breakdownSummary['subtotal_products'] ?? 0}',
                    isHighlight: false,
                  ),
                  _buildSummaryRow(
                    context,
                    'Subtotal (Services)',
                    '₱${breakdownSummary['subtotal_services'] ?? 0}',
                    isHighlight: false,
                  ),
                  if ((breakdownSummary['handling'] ?? 0) > 0)
                    _buildSummaryRow(
                      context,
                      'Handling',
                      '₱${breakdownSummary['handling'] ?? 0}',
                      isHighlight: false,
                    ),
                  if ((breakdownSummary['service_fee'] ?? 0) > 0)
                    _buildSummaryRow(
                      context,
                      'Service Fee',
                      '₱${breakdownSummary['service_fee'] ?? 0}',
                      isHighlight: false,
                    ),
                  const Divider(height: 16),
                  _buildSummaryRow(
                    context,
                    'Subtotal',
                    '₱${(breakdownSummary['subtotal_products'] ?? 0) + (breakdownSummary['subtotal_services'] ?? 0)}',
                    isHighlight: true,
                  ),
                  if ((breakdownSummary['discounts'] ?? 0) > 0)
                    _buildSummaryRow(
                      context,
                      'Discounts',
                      '-₱${breakdownSummary['discounts'] ?? 0}',
                      isHighlight: true,
                      isNegative: true,
                    ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'VAT (${(breakdownSummary['vat_rate'] ?? 12).toStringAsFixed(0)}%)',
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                        Text(
                          '₱${breakdownSummary['vat_amount'] ?? 0}',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          '(Inclusive)',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 16),
                  _buildSummaryRow(
                    context,
                    'GRAND TOTAL',
                    '₱${breakdownSummary['grand_total'] ?? 0}',
                    isHighlight: true,
                    isTotal: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // 💳 Payment Section
            if (breakdownPayment.isNotEmpty) ...[
              _buildSectionHeader(
                context,
                Icons.payment_outlined,
                'Payment',
                '',
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green[300]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Method',
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green[700],
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            (breakdownPayment['method'] ?? 'Unknown')
                                .toString()
                                .toUpperCase(),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildSummaryRow(
                      context,
                      'Amount Paid',
                      '₱${breakdownPayment['amount_paid'] ?? 0}',
                    ),
                    if ((breakdownPayment['change'] ?? 0) > 0)
                      _buildSummaryRow(
                        context,
                        'Change',
                        '₱${breakdownPayment['change'] ?? 0}',
                        isNegative: true,
                      ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _getStatusColor(
                          breakdownPayment['payment_status'],
                        ).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Status',
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _getStatusColor(
                                breakdownPayment['payment_status'],
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              (breakdownPayment['payment_status'] ?? 'N/A')
                                  .toString()
                                  .toUpperCase(),
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (breakdownPayment['reference_number'] != null) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.receipt_outlined,
                              size: 16,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Ref Number',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(color: Colors.grey[600]),
                                  ),
                                  Text(
                                    breakdownPayment['reference_number'] ?? '',
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 28),
            ],

            // 📍 Handling Section
            if (pickupData.isNotEmpty || deliveryData.isNotEmpty) ...[
              _buildSectionHeader(
                context,
                Icons.local_shipping_outlined,
                'Fulfillment',
                '',
              ),
              const SizedBox(height: 12),
              if (pickupData.isNotEmpty) ...[
                _buildHandlingCard(context, 'Pickup', pickupData, Colors.blue),
                const SizedBox(height: 12),
              ],
              if (deliveryData.isNotEmpty) ...[
                _buildHandlingCard(
                  context,
                  'Delivery',
                  deliveryData,
                  Colors.purple,
                ),
                const SizedBox(height: 12),
              ],
              const SizedBox(height: 16),
            ],

            // ⛔ Cancellation Section
            if (cancellation != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red[300]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.cancel_outlined,
                          color: Colors.red[700],
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Order Cancelled',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                color: Colors.red[700],
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Reason: ${cancellation['reason'] ?? 'N/A'}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    if (cancellation['notes'] != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Notes: ${cancellation['notes']}',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red[700],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Refund: ${cancellation['refund_status']?.toString().toUpperCase() ?? 'N/A'}',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
            ],

            // 📝 Audit Log Timeline
            if (breakdownAuditLog.isNotEmpty) ...[
              _buildSectionHeader(
                context,
                Icons.history_outlined,
                'Activity Timeline',
                '',
              ),
              const SizedBox(height: 12),
              _buildAuditLogTimeline(context, breakdownAuditLog),
              const SizedBox(height: 20),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildMetricChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    IconData icon,
    String title,
    String badge,
  ) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 10),
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const Spacer(),
        if (badge.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              badge,
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
      ],
    );
  }

  Widget _buildJsonViewer(BuildContext context, Map<String, dynamic> data) {
    final jsonString = _formatJson(data);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[700]!, width: 1),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              jsonString,
              style: const TextStyle(
                fontSize: 11,
                fontFamily: 'monospace',
                color: Color(0xFF4EC9B0),
                height: 1.5,
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatJson(Map<String, dynamic> map, [int indent = 0]) {
    final buffer = StringBuffer();
    final indentStr = '  ' * indent;
    final nextIndentStr = '  ' * (indent + 1);

    buffer.write('{\n');

    final entries = map.entries.toList();
    for (var i = 0; i < entries.length; i++) {
      final entry = entries[i];
      buffer.write('$nextIndentStr"${entry.key}": ');

      if (entry.value is Map) {
        buffer.write(
          _formatJson(entry.value as Map<String, dynamic>, indent + 1),
        );
      } else if (entry.value is List) {
        final list = entry.value as List;
        buffer.write('[\n');
        for (var j = 0; j < list.length; j++) {
          if (list[j] is Map) {
            buffer.write(
              '$nextIndentStr  ${_formatJson(list[j] as Map<String, dynamic>, indent + 2)}\n',
            );
          } else {
            buffer.write('$nextIndentStr  ${list[j]}\n');
          }
          if (j < list.length - 1) buffer.write(',');
        }
        buffer.write('$nextIndentStr]');
      } else if (entry.value is String) {
        buffer.write('"${entry.value}"');
      } else {
        buffer.write('${entry.value}');
      }

      if (i < entries.length - 1) buffer.write(',');
      buffer.write('\n');
    }

    buffer.write('$indentStr}');
    return buffer.toString();
  }

  Widget _buildSummaryRow(
    BuildContext context,
    String label,
    String value, {
    bool isHighlight = true,
    bool isNegative = false,
    bool isTotal = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: isTotal || isHighlight
                  ? FontWeight.bold
                  : FontWeight.normal,
              fontSize: isTotal ? 14 : 12,
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
              color: isNegative
                  ? Colors.red[700]
                  : (isTotal ? Colors.green[700] : null),
              fontSize: isTotal ? 14 : 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHandlingCard(
    BuildContext context,
    String title,
    Map<String, dynamic> data,
    Color color,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withOpacity(0.2), width: 1),
      ),
      color: color.withOpacity(0.06),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                if (data['status'] != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(data['status']).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      data['status'].toString().toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: _getStatusColor(data['status']),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (data['address'] != null) ...[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: color.withOpacity(0.1)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.location_on_outlined, size: 16, color: color),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Address',
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                          Text(
                            data['address'],
                            style: Theme.of(context).textTheme.bodySmall,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],
            if (data['notes'] != null &&
                (data['notes'] as String).isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.note_outlined,
                      size: 16,
                      color: Colors.orange[700],
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        data['notes'],
                        style: Theme.of(context).textTheme.labelSmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],
            if (data['started_at'] != null || data['completed_at'] != null) ...[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (data['started_at'] != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(
                          'Started: ${data['started_at']}',
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ),
                    if (data['completed_at'] != null)
                      Text(
                        'Completed: ${data['completed_at']}',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAuditLogTimeline(BuildContext context, List auditLog) {
    return Column(
      children: auditLog.asMap().entries.map((entry) {
        final log = entry.value as Map<String, dynamic>;
        final action = log['action'] ?? 'Unknown';

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check_circle, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      action.replaceAll('_', ' ').toUpperCase(),
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Time: ${log['timestamp'] ?? 'N/A'}',
                      style: Theme.of(
                        context,
                      ).textTheme.labelSmall?.copyWith(color: Colors.grey[600]),
                    ),
                    if (log['changed_by'] != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'By: ${log['changed_by']}',
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ),
                    if (log['details'] != null &&
                        (log['details'] as Map).isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'Details: ${log['details'].toString()}',
                          style: Theme.of(context).textTheme.labelSmall,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
