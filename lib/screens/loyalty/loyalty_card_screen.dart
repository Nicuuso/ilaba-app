import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ilaba/providers/auth_provider.dart';
import 'package:ilaba/constants/ilaba_colors.dart';

class LoyaltyCardScreen extends StatefulWidget {
  const LoyaltyCardScreen({Key? key}) : super(key: key);

  @override
  State<LoyaltyCardScreen> createState() => _LoyaltyCardScreenState();
}

class _LoyaltyCardScreenState extends State<LoyaltyCardScreen> {
  late Future<int> _completedOrdersFuture;

  @override
  void initState() {
    super.initState();
    _loadCompletedOrders();
  }

  void _loadCompletedOrders() {
    final authProvider = context.read<AuthProvider>();
    final customerId = authProvider.currentUser?.id;

    if (customerId != null) {
      _completedOrdersFuture = _fetchCompletedOrdersCount(customerId);
    } else {
      _completedOrdersFuture = Future.value(0);
    }
  }

  Future<int> _fetchCompletedOrdersCount(String customerId) async {
    try {
      final supabase = Supabase.instance.client;

      final orders = await supabase
          .from('orders')
          .select()
          .eq('customer_id', customerId)
          .eq('status', 'completed');

      return orders.length;
    } catch (e) {
      debugPrint('❌ Error fetching completed orders: $e');
      return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Loyalty Card',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: ILabaColors.darkText,
          ),
        ),
        elevation: 0,
        backgroundColor: ILabaColors.white,
        foregroundColor: ILabaColors.burgundy,
        iconTheme: const IconThemeData(color: ILabaColors.burgundy),
        centerTitle: false,
      ),
      body: FutureBuilder<int>(
        future: _completedOrdersFuture,
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
                  const Text('Failed to load loyalty information'),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => setState(() => _loadCompletedOrders()),
                    child: const Text('Try Again'),
                  ),
                ],
              ),
            );
          }

          final completedOrders = snapshot.data ?? 0;

          return Consumer<AuthProvider>(
            builder: (context, authProvider, _) {
              final loyaltyPoints = authProvider.currentUser?.loyaltyPoints ?? 0;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Card
                    _buildHeaderCard(
                      context,
                      loyaltyPoints,
                      completedOrders,
                    ),
                    const SizedBox(height: 32),

                    // Rewards Section Title
                    Text(
                      'Order-Based Rewards',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 10 Orders Reward
                    _buildRewardCard(
                      context: context,
                      title: '10% OFF Reward',
                      description: 'Complete 10 orders',
                      completedOrders: completedOrders,
                      targetOrders: 10,
                      discountPercent: 10,
                    ),
                    const SizedBox(height: 16),

                    // 20 Orders Reward
                    _buildRewardCard(
                      context: context,
                      title: '15% OFF Reward',
                      description: 'Complete 20 orders',
                      completedOrders: completedOrders,
                      targetOrders: 20,
                      discountPercent: 15,
                    ),
                    const SizedBox(height: 24),

                    // Info Section
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: ILabaColors.burgundy.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: ILabaColors.burgundy.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: ILabaColors.burgundy,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'About Your Loyalty Rewards',
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: ILabaColors.burgundy,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Every completed order brings you closer to exclusive discounts! '
                            'Once you reach 10 orders, unlock 10% OFF on your next order. '
                            'Reach 20 orders to enjoy 15% OFF. '
                            'Keep using our service and enjoy the rewards!',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: ILabaColors.burgundyDark,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildHeaderCard(
    BuildContext context,
    int loyaltyPoints,
    int completedOrders,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [ILabaColors.burgundy, ILabaColors.burgundyDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: ILabaColors.burgundy.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Loyalty Status',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white70,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: ILabaColors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.star,
                      color: Colors.amber,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Member',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: ILabaColors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Completed Orders',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      completedOrders.toString(),
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: ILabaColors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: ILabaColors.white.withOpacity(0.2),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Loyalty Points',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      loyaltyPoints.toString(),
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.amber,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRewardCard({
    required BuildContext context,
    required String title,
    required String description,
    required int completedOrders,
    required int targetOrders,
    required int discountPercent,
  }) {
    final progress = (completedOrders / targetOrders).clamp(0.0, 1.0);
    final ordersRemaining = (targetOrders - completedOrders).clamp(0, targetOrders);
    final isUnlocked = completedOrders >= targetOrders;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ILabaColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isUnlocked ? Colors.green.shade300 : ILabaColors.lightGray,
          width: isUnlocked ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: ILabaColors.darkText.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: ILabaColors.lightText,
                      ),
                    ),
                  ],
                ),
              ),
              if (isUnlocked)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Unlocked',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.green,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Text(
                  '$discountPercent% OFF',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: ILabaColors.burgundy,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Progress bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Progress',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: ILabaColors.lightText,
                    ),
                  ),
                  Text(
                    '$completedOrders / $targetOrders',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isUnlocked ? Colors.green : ILabaColors.burgundy,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isUnlocked ? Colors.green : ILabaColors.burgundy,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Status text
          if (!isUnlocked)
            Text(
              '$ordersRemaining ${ordersRemaining == 1 ? 'order' : 'orders'} away from unlocking this reward',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: ILabaColors.burgundy,
                fontWeight: FontWeight.w500,
              ),
            )
          else
            Text(
              'Congratulations! You\'ve unlocked this reward. Use it on your next order!',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.green,
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
    );
  }
}
