import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ilaba/providers/auth_provider.dart';

class OrderStatusScreen extends StatefulWidget {
  const OrderStatusScreen({super.key});

  @override
  State<OrderStatusScreen> createState() => _OrderStatusScreenState();
}

class _OrderStatusScreenState extends State<OrderStatusScreen>
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

      // Fetch active orders (not completed or cancelled)
      final orders = await supabase
          .from('orders')
          .select()
          .eq('customer_id', customerId)
          .neq('status', 'completed')
          .neq('status', 'cancelled')
          .order('created_at', ascending: false);

      // Enrich each order with baskets and services
      List<Map<String, dynamic>> enrichedOrders = [];

      for (var order in orders) {
        final orderId = order['id'];

        // Fetch baskets for this order
        final baskets = await supabase
            .from('baskets')
            .select()
            .eq('order_id', orderId);

        List<Map<String, dynamic>> basketsWithServices = [];
        for (var basket in baskets) {
          final basketServices = await supabase
              .from('basket_services')
              .select('*, services(id, name, description)')
              .eq('basket_id', basket['id']);

          basketsWithServices.add({...basket, 'services': basketServices});
        }

        enrichedOrders.add({...order, 'baskets': basketsWithServices});
      }

      return enrichedOrders;
    } catch (e) {
      debugPrint('Error fetching active orders: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> _fetchOrderHistory(
    String customerId,
  ) async {
    try {
      final supabase = Supabase.instance.client;

      // Fetch all orders for the customer (including completed and cancelled)
      final orders = await supabase
          .from('orders')
          .select()
          .eq('customer_id', customerId)
          .order('created_at', ascending: false);

      // Enrich each order with baskets and services
      List<Map<String, dynamic>> enrichedOrders = [];

      for (var order in orders) {
        final orderId = order['id'];

        // Fetch payments
        final payments = await supabase
            .from('payments')
            .select()
            .eq('order_id', orderId);

        // Fetch baskets for this order
        final baskets = await supabase
            .from('baskets')
            .select()
            .eq('order_id', orderId);

        List<Map<String, dynamic>> basketsWithServices = [];
        for (var basket in baskets) {
          final basketServices = await supabase
              .from('basket_services')
              .select('*, services(id, name, description)')
              .eq('basket_id', basket['id']);

          basketsWithServices.add({...basket, 'services': basketServices});
        }

        enrichedOrders.add({
          ...order,
          'payments': payments,
          'baskets': basketsWithServices,
        });
      }

      return enrichedOrders;
    } catch (e) {
      debugPrint('Error fetching order history: $e');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Order Tracking'), elevation: 0),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _activeOrdersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary,
                ),
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load orders',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: () {
                      setState(() {
                        _loadOrders();
                      });
                    },
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
                      color: Theme.of(context).colorScheme.primaryContainer,
                    ),
                    child: Icon(
                      Icons.shopping_bag_outlined,
                      size: 50,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'No Active Orders',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'All your orders are completed',
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
              final orderId = order['id'];
              final status = order['status'] ?? 'processing';
              final baskets = order['baskets'] as List? ?? [];

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: Theme.of(context).colorScheme.outlineVariant,
                    width: 1,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Order header
                      Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _getStatusColor(status).withOpacity(0.2),
                            ),
                            child: Icon(
                              Icons.shopping_bag_outlined,
                              color: _getStatusColor(status),
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
                                  style: Theme.of(context).textTheme.labelLarge
                                      ?.copyWith(fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(
                                      status,
                                    ).withOpacity(0.12),
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

                      // Baskets timeline
                      if (baskets.isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ...List.generate(baskets.length, (basketIndex) {
                              final basket = baskets[basketIndex];
                              final basketServices =
                                  basket['services'] as List? ?? [];

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (basketIndex > 0)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12.0,
                                      ),
                                      child: Divider(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .outlineVariant
                                            .withOpacity(0.2),
                                        height: 1,
                                      ),
                                    ),
                                  // Basket header
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.local_laundry_service_outlined,
                                        size: 18,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Basket #${basket['basket_number']}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelLarge
                                            ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                      const Spacer(),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _getStatusColor(
                                            basket['status'],
                                          ).withOpacity(0.12),
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: Text(
                                          (basket['status'] ?? 'N/A')
                                              .toString()
                                              .toUpperCase(),
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: _getStatusColor(
                                              basket['status'],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),

                                  // Services timeline
                                  if (basketServices.isNotEmpty)
                                    Column(
                                      children: List.generate(basketServices.length, (
                                        serviceIndex,
                                      ) {
                                        final service =
                                            basketServices[serviceIndex];
                                        final serviceName =
                                            service['services']?['name'] ??
                                            'Unknown Service';
                                        final serviceStatus =
                                            service['status'] ?? 'pending';
                                        final isCompleted =
                                            serviceStatus == 'completed';
                                        final isInProgress =
                                            serviceStatus == 'in_progress';

                                        return Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 12.0,
                                          ),
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              // Timeline dot and line
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
                                                        color: _getStatusColor(
                                                          serviceStatus,
                                                        ),
                                                        width: 2,
                                                      ),
                                                    ),
                                                    child: Center(
                                                      child: Icon(
                                                        isCompleted
                                                            ? Icons
                                                                  .check_rounded
                                                            : _getStatusIcon(
                                                                serviceStatus,
                                                              ),
                                                        size: 12,
                                                        color: _getStatusColor(
                                                          serviceStatus,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  // Line below (except last)
                                                  if (serviceIndex <
                                                      basketServices.length - 1)
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
                                              // Service details
                                              Expanded(
                                                child: Container(
                                                  padding: const EdgeInsets.all(
                                                    12,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: _getStatusColor(
                                                      serviceStatus,
                                                    ).withOpacity(0.08),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                    border: Border.all(
                                                      color: _getStatusColor(
                                                        serviceStatus,
                                                      ).withOpacity(0.2),
                                                      width: 1,
                                                    ),
                                                  ),
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .spaceBetween,
                                                        children: [
                                                          Expanded(
                                                            child: Text(
                                                              serviceName,
                                                              style: Theme.of(context)
                                                                  .textTheme
                                                                  .bodySmall
                                                                  ?.copyWith(
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w600,
                                                                    color: Theme.of(
                                                                      context,
                                                                    ).colorScheme.onSurface,
                                                                  ),
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                            width: 8,
                                                          ),
                                                          if (isInProgress)
                                                            SizedBox(
                                                              width: 14,
                                                              height: 14,
                                                              child: CircularProgressIndicator(
                                                                strokeWidth: 2,
                                                                valueColor:
                                                                    AlwaysStoppedAnimation<
                                                                      Color
                                                                    >(
                                                                      _getStatusColor(
                                                                        serviceStatus,
                                                                      ),
                                                                    ),
                                                              ),
                                                            ),
                                                          if (isCompleted)
                                                            Icon(
                                                              Icons
                                                                  .check_circle,
                                                              size: 14,
                                                              color:
                                                                  _getStatusColor(
                                                                    serviceStatus,
                                                                  ),
                                                            ),
                                                        ],
                                                      ),
                                                      const SizedBox(height: 6),
                                                      Text(
                                                        'Amount: ₱${service['subtotal']}',
                                                        style: Theme.of(context)
                                                            .textTheme
                                                            .labelSmall
                                                            ?.copyWith(
                                                              color: Theme.of(context)
                                                                  .colorScheme
                                                                  .onSurfaceVariant,
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
                          ],
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
