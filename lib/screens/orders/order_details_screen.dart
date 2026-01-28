import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'order_details_helpers.dart';
import 'order_details_widgets.dart';
import 'package:ilaba/constants/ilaba_colors.dart';
import 'report_issue_screen.dart';

class OrderDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> order;

  const OrderDetailsScreen({required this.order});

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  late Future<Map<String, dynamic>> _orderDataFuture;

  @override
  void initState() {
    super.initState();
    print('🔵 OrderDetailsScreen initState - Order ID: ${widget.order['id']}');
    _orderDataFuture = _fetchOrderData();
  }

  Future<void> _refreshOrderData() async {
    setState(() {
      _orderDataFuture = _fetchOrderData();
    });
    await _orderDataFuture;
  }

  Future<Map<String, dynamic>> _fetchOrderData() async {
    try {
      print('⏳ Starting _fetchOrderData...');
      final supabase = Supabase.instance.client;
      final orderId = widget.order['id'];
      print('📋 Order ID: $orderId');

      // IMPORTANT: Fetch the LATEST order data from the database
      // This ensures we get the current status, not the stale one passed to this screen
      print('� Fetching latest order data from orders table...');
      Map<String, dynamic> orderData;
      try {
        final freshOrder = await supabase
            .from('orders')
            .select()
            .eq('id', orderId)
            .single();
        orderData = freshOrder;
        print('✅ Fresh order status: ${orderData['status']}');
      } catch (e) {
        print('⚠️ Could not fetch fresh order, using passed order: $e');
        orderData = widget.order;
      }

      print('📋 Customer ID: ${orderData['customer_id']}');
      print('📋 Staff ID: ${orderData['staff_id']}');

      // Fetch customer data
      print('🔍 Fetching customer from customers table...');
      final customerData = orderData['customer_id'] != null
          ? await supabase
                .from('customers')
                .select()
                .eq('id', orderData['customer_id'])
                .single()
          : null;
      print('✅ Customer data: $customerData');

      // Fetch cashier/staff data
      print('🔍 Fetching staff from staff table...');
      final staffData = orderData['staff_id'] != null
          ? await supabase
                .from('staff')
                .select()
                .eq('id', orderData['staff_id'])
                .single()
          : null;
      print('✅ Staff data: $staffData');

      // Extract product IDs from breakdown items
      final breakdown =
          orderData['breakdown'] as Map<String, dynamic>? ?? {};
      final items = (breakdown['items'] as List?) ?? [];
      final productIds = <String>[];
      for (final item in items) {
        final productId = (item as Map<String, dynamic>)['product_id'];
        if (productId != null) {
          productIds.add(productId.toString());
        }
      }

      // Fetch product details with images
      Map<String, dynamic> productsMap = {};
      if (productIds.isNotEmpty) {
        print(
          '🔍 Fetching ${productIds.length} products from products table...',
        );
        final products = await supabase
            .from('products')
            .select()
            .inFilter('id', productIds);
        print('✅ Fetched products: ${products.length}');
        for (final product in products) {
          productsMap[product['id'].toString()] = product;
        }
        print('✅ Products map: $productsMap');
      }

      print('✅ All data fetched successfully!');
      print('🔄 Final order status being used: ${orderData['status']}');

      return {
        'order': orderData,
        'customer': customerData,
        'staff': staffData,
        'products': productsMap,
      };
    } catch (e) {
      print('❌ ERROR fetching order data: $e');
      return {
        'order': widget.order,
        'customer': null,
        'staff': null,
        'products': {},
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _orderDataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(title: const Text('Order Details'), elevation: 0),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Order Details'), elevation: 0),
            body: Center(child: Text('Error loading order: ${snapshot.error}')),
          );
        }

        final orderData = snapshot.data ?? {};
        final order = orderData['order'] as Map<String, dynamic>;
        final customerData =
            orderData['customer'] as Map<String, dynamic>? ?? {};
        final staffData = orderData['staff'] as Map<String, dynamic>? ?? {};
        final productsMap =
            orderData['products'] as Map<String, dynamic>? ?? {};

        return _buildOrderScreen(
          context,
          order,
          customerData,
          staffData,
          productsMap,
        );
      },
    );
  }

  Widget _buildOrderScreen(
    BuildContext context,
    Map<String, dynamic> order,
    Map<String, dynamic> customerData,
    Map<String, dynamic> staffData,
    Map<String, dynamic> productsMap,
  ) {
    final breakdown = OrderDataExtractor.extractBreakdown(order);
    final summary = OrderDataExtractor.extractBreakdownSummary(breakdown);
    final baskets = OrderDataExtractor.extractBaskets(breakdown);
    final items = OrderDataExtractor.extractItems(breakdown);
    final fees = OrderDataExtractor.extractFees(breakdown);
    final discounts = OrderDataExtractor.extractDiscounts(breakdown);
    final payment = OrderDataExtractor.extractPayment(breakdown);
    final auditLog = OrderDataExtractor.extractAuditLog(breakdown);
    final cancellation = OrderDataExtractor.extractCancellation(order);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Details'),
        elevation: 0,
        centerTitle: false,
      ),
      body: RefreshIndicator(
        onRefresh: _refreshOrderData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 📋 Order Details Card
              OrderDetailsWidgets.buildOrderDetailsCard(
                context,
                order,
                customerData.isEmpty ? null : customerData,
                staffData.isEmpty ? null : staffData,
              ),
              const SizedBox(height: 20),

              // 📊 Order Status Timeline - pass full order to read handling JSONB
              _buildStatusTimeline(context, order),
              const SizedBox(height: 20),

              // 🧺 Laundry Baskets Section
              if (baskets.isNotEmpty) ...[
                OrderDetailsWidgets.buildSectionHeader(
                  context,
                  Icons.local_laundry_service_outlined,
                  'Laundry Baskets',
                  baskets.length.toString(),
                ),
                const SizedBox(height: 8),
                ..._buildBasketCards(context, baskets),
                const SizedBox(height: 20),
              ],

              // 🛍️ Product Items Section
              if (items.isNotEmpty) ...[
                OrderDetailsWidgets.buildSectionHeader(
                  context,
                  Icons.shopping_bag_outlined,
                  'Products',
                  items.length.toString(),
                ),
                const SizedBox(height: 8),
                _buildProductsGrid(context, items, productsMap),
                const SizedBox(height: 20),
              ],

              // 📋 Fees & Discounts Section
              if (fees.isNotEmpty || discounts.isNotEmpty) ...[
                _buildFeesAndDiscounts(context, fees, discounts),
                const SizedBox(height: 20),
              ],

              // 💰 Order Summary Section
              OrderDetailsWidgets.buildSectionHeader(
                context,
                Icons.receipt_long_outlined,
                'Summary',
                '',
              ),
              const SizedBox(height: 8),
              _buildSummaryCard(context, summary, order, baskets, items, productsMap),
              const SizedBox(height: 20),

              // 💳 Payment Section
              if (payment.isNotEmpty) ...[
                OrderDetailsWidgets.buildSectionHeader(
                  context,
                  Icons.payment_outlined,
                  'Payment',
                  '',
                ),
                const SizedBox(height: 8),
                _buildPaymentCard(context, payment),
                const SizedBox(height: 20),
              ],

              // ⛔ Cancellation Section
              if (cancellation != null) ...[
                _buildCancellationCard(context, cancellation),
                const SizedBox(height: 20),
              ],

              // 📝 Audit Log Timeline
              if (auditLog.isNotEmpty) ...[
                OrderDetailsWidgets.buildSectionHeader(
                  context,
                  Icons.history_outlined,
                  'Activity Timeline',
                  '',
                ),
                const SizedBox(height: 8),
                ..._buildAuditLogCards(context, auditLog),
                const SizedBox(height: 20),
              ],

              // 🚨 Report Issue Button
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      ILabaColors.burgundy,
                      ILabaColors.burgundyDark,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ReportIssueScreen(
                          orderId: order['id'],
                          orderNumber: order['order_number'],
                          customerName: customerData['email'] ?? customerData['full_name'] ?? customerData['name'] ?? 'Customer',
                          customerId: order['customer_id'],
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.flag_outlined, size: 20),
                  label: const Text(
                    'Report an Issue',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: ILabaColors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  /// Build basket cards
  List<Widget> _buildBasketCards(BuildContext context, List<dynamic> baskets) {
    return baskets.asMap().entries.map((entry) {
      final basket = entry.value as Map<String, dynamic>;
      final services = (basket['services'] as Map<String, dynamic>?) ?? {};
      
      // Extract costs from various possible locations
      var costs = (basket['costs'] as Map<String, dynamic>?) ?? 
                  (basket['pricing'] as Map<String, dynamic>?) ?? 
                  (basket['prices'] as Map<String, dynamic>?);
      
      // If no costs found, build from service pricing objects
      if (costs == null || costs.isEmpty) {
        costs = {};
        // Extract from wash_pricing, dry_pricing, etc.
        if (services['wash_pricing'] is Map) {
          costs['wash'] = (services['wash_pricing'] as Map)['base_price'];
        }
        if (services['dry_pricing'] is Map) {
          costs['dry'] = (services['dry_pricing'] as Map)['base_price'];
        }
        if (services['iron_pricing'] is Map) {
          costs['iron'] = (services['iron_pricing'] as Map)['base_price'];
        }
        if (services['staff_service_pricing'] is Map) {
          costs['staff_service'] = (services['staff_service_pricing'] as Map)['base_price'];
        }
      }

      return Card(
        margin: const EdgeInsets.only(bottom: 8),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: Colors.grey[200]!, width: 0.8),
        ),
        color: ILabaColors.white,
        child: Padding(
          padding: const EdgeInsets.all(11),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Basket #${basket['basket_number'] ?? 'N/A'}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: OrderDetailsHelpers.getStatusColor(
                        basket['status'],
                      ).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      (basket['status'] ?? 'N/A').toString().toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: OrderDetailsHelpers.getStatusColor(
                          basket['status'],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 7),
              Wrap(
                spacing: 10,
                runSpacing: 5,
                children: [
                  if (basket['weight'] != null)
                    OrderDetailsWidgets.buildMetricChip(
                      Icons.scale,
                      '${basket['weight']} kg',
                      Colors.orange,
                    ),
                  if (basket['total'] != null)
                    OrderDetailsWidgets.buildMetricChip(
                      Icons.attach_money,
                      OrderDetailsHelpers.formatCurrency(basket['total']),
                      Colors.green,
                    ),
                ],
              ),
              if (services.isNotEmpty) ...[
                const SizedBox(height: 9),
                Text(
                  'Services',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 6),
                ..._buildServiceItems(context, services, costs),
              ],
            ],
          ),
        ),
      );
    }).toList();
  }

  /// Build service items from basket services map
  List<Widget> _buildServiceItems(
    BuildContext context,
    Map<String, dynamic> services,
    Map<String, dynamic>? costs,
  ) {
    final servicesList = <Widget>[];

    // Wash service
    if (services['wash'] != null && services['wash'] != 'off') {
      final washPrice = costs?['wash'] ?? costs?['wash_price'];
      servicesList.add(_buildServiceItem(
        'Wash: ${services['wash']?.toString().toUpperCase() ?? ''}',
        price: washPrice,
      ));
    }

    // Dry service
    if (services['dry'] != null && services['dry'] != 'off') {
      final dryPrice = costs?['dry'] ?? costs?['dry_price'];
      servicesList.add(_buildServiceItem(
        'Dry: ${services['dry']?.toString().toUpperCase() ?? ''}',
        price: dryPrice,
      ));
    }

    // Spin service
    if (services['spin'] == true) {
      final spinPrice = costs?['spin'] ?? costs?['spin_price'];
      servicesList.add(_buildServiceItem('Spin', price: spinPrice));
    }

    // Iron service
    final ironWeightKg = (services['iron_weight_kg'] as int?) ?? 0;
    if (ironWeightKg > 0) {
      final ironPrice = costs?['iron'] ?? costs?['iron_price'];
      servicesList.add(_buildServiceItem('Iron: ${ironWeightKg}kg', price: ironPrice));
    }

    // Staff service
    if (services['staff_service'] == true || costs?['staff_service'] != null) {
      final staffServicePrice = costs?['staff_service'] ?? costs?['staff_service_price'];
      servicesList.add(_buildServiceItem('Staff Service', price: staffServicePrice));
    }

    // Fold service
    if (services['fold'] == true) {
      final foldPrice = costs?['fold'] ?? costs?['fold_price'];
      servicesList.add(_buildServiceItem('Fold', price: foldPrice));
    }

    // Additional dry minutes
    final additionalDryMinutes = (services['additional_dry_minutes'] as int?) ?? 0;
    if (additionalDryMinutes > 0) {
      final additionalDryPrice = costs?['additional_dry'] ?? costs?['additional_dry_price'];
      servicesList.add(_buildServiceItem(
        'Additional Dry: $additionalDryMinutes min',
        price: additionalDryPrice,
      ));
    }

    // Plastic bags
    final plasticBags = (services['plastic_bags'] as int?) ?? 0;
    if (plasticBags > 0) {
      final plasticBagsPrice = costs?['plastic_bags'] ?? costs?['plastic_bags_price'];
      servicesList.add(_buildServiceItem('Plastic Bags: $plasticBags', price: plasticBagsPrice));
    }

    return servicesList;
  }

  /// Build individual service item widget
  Widget _buildServiceItem(String label, {dynamic price}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
        decoration: BoxDecoration(
          color: ILabaColors.white.withOpacity(0.7),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.grey[300]!, width: 0.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (price != null)
              Text(
                OrderDetailsHelpers.formatCurrency(price),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: ILabaColors.burgundy,
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Build products grid - compact horizontal list with square thumbnails
  Widget _buildProductsGrid(
    BuildContext context,
    List<dynamic> items,
    Map<String, dynamic> productsMap,
  ) {
    print('📦 Building products grid with ${items.length} items');
    print('📦 Products map contains: ${productsMap.keys.toList()}');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value as Map<String, dynamic>;

        print('\n📦 Product #${index + 1}:');
        print('  Item Keys: ${item.keys.toList()}');
        final productId = item['product_id']?.toString();
        print('  Product ID: $productId');

        // Lookup product details from productsMap
        final productDetails = productId != null
            ? productsMap[productId]
            : null;
        print('  Product details found: ${productDetails != null}');

        final imageUrl = OrderDetailsHelpers.getProductImageUrl(
          productDetails?['image_url'],
        );
        final name = item['product_name'] ?? 'Unknown Product';
        final quantity = SafeConversion.toInt(item['quantity']);
        final unitPrice = SafeConversion.toNum(item['unit_price']);
        final subtotal = SafeConversion.toNum(item['subtotal']);
        final discount = SafeConversion.toNum(item['discount']);

        print('  Final image URL: $imageUrl');
        print('  Name: $name, Qty: $quantity, Price: $unitPrice');

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: ILabaColors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey[200]!, width: 0.8),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Square thumbnail (80x80)
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(10),
                  bottomLeft: Radius.circular(10),
                ),
                child: Container(
                  width: 80,
                  height: 80,
                  color: Colors.grey[200],
                  child: imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            print('❌ Image load failed for: $imageUrl');
                            print('❌ Error: $error');
                            return Icon(
                              Icons.image_not_supported_outlined,
                              color: Colors.grey[400],
                              size: 28,
                            );
                          },
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) {
                              print('✅ Image loaded: $imageUrl');
                              return child;
                            }
                            return Center(
                              child: CircularProgressIndicator(
                                value:
                                    loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                    : null,
                                strokeWidth: 2,
                              ),
                            );
                          },
                        )
                      : Icon(
                          Icons.shopping_bag_outlined,
                          color: Colors.grey[400],
                          size: 28,
                        ),
                ),
              ),
              // Product info
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Product name
                      Text(
                        name,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      // Quantity and unit price on same row
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Qty: $quantity',
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 11,
                                  ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '@ ${OrderDetailsHelpers.formatCurrency(unitPrice)}',
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  fontSize: 11,
                                  color: Colors.grey[600],
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // Subtotal and discount
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Subtotal',
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(
                                      fontSize: 10,
                                      color: Colors.grey[600],
                                    ),
                              ),
                              Text(
                                OrderDetailsHelpers.formatCurrency(subtotal),
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                      color: Colors.grey[900],
                                    ),
                              ),
                            ],
                          ),
                          if (discount > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red[50],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '-${OrderDetailsHelpers.formatCurrency(discount)}',
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 11,
                                      color: Colors.red[700],
                                    ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  /// Build fees and discounts section
  Widget _buildFeesAndDiscounts(
    BuildContext context,
    List<dynamic> fees,
    List<dynamic> discounts,
  ) {
    if (fees.isNotEmpty && discounts.isNotEmpty) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                OrderDetailsWidgets.buildSectionHeader(
                  context,
                  Icons.receipt_long_outlined,
                  'Fees',
                  '',
                ),
                const SizedBox(height: 8),
                ..._buildFeeCards(context, fees),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                OrderDetailsWidgets.buildSectionHeader(
                  context,
                  Icons.local_offer_outlined,
                  'Discounts',
                  '',
                ),
                const SizedBox(height: 8),
                ..._buildDiscountCards(context, discounts),
              ],
            ),
          ),
        ],
      );
    } else if (fees.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OrderDetailsWidgets.buildSectionHeader(
            context,
            Icons.receipt_long_outlined,
            'Fees',
            '',
          ),
          const SizedBox(height: 8),
          ..._buildFeeCards(context, fees),
        ],
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OrderDetailsWidgets.buildSectionHeader(
            context,
            Icons.local_offer_outlined,
            'Discounts',
            '',
          ),
          const SizedBox(height: 8),
          ..._buildDiscountCards(context, discounts),
        ],
      );
    }
  }

  /// Build fee cards
  List<Widget> _buildFeeCards(BuildContext context, List<dynamic> fees) {
    return fees.map((fee) {
      final f = fee as Map<String, dynamic>;
      return Container(
        margin: const EdgeInsets.only(bottom: 7),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: Colors.grey[200]!, width: 0.5),
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
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Type: ${OrderDetailsHelpers.formatLabel(f['type'] ?? 'Unknown')}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Text(
              OrderDetailsHelpers.formatCurrency(f['amount']),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.amber[900],
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  /// Build discount cards
  List<Widget> _buildDiscountCards(
    BuildContext context,
    List<dynamic> discounts,
  ) {
    return discounts.map((discount) {
      final d = discount as Map<String, dynamic>;
      return Container(
        margin: const EdgeInsets.only(bottom: 7),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: Colors.grey[200]!, width: 0.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${OrderDetailsHelpers.formatCurrency(d['value'])} off',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  if (d['reason'] != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      'Reason: ${OrderDetailsHelpers.formatLabel(d['reason'])}',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Text(
              '-${OrderDetailsHelpers.formatCurrency(d['applied_amount'] ?? 0)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.red[700],
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  /// Parse JSON string to Map using dart:convert
  Map<String, dynamic> _parseJsonString(String jsonString) {
    try {
      if (jsonString.isEmpty) return {};
      final decoded = jsonDecode(jsonString);
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
      return {};
    } catch (e) {
      debugPrint('⚠️ JSON parse error: $e');
      return {};
    }
  }

  /// Determine the effective order progress status by combining main status + handling JSONB
  /// Main statuses: pending, processing, completed, cancelled
  /// Handling contains: pickup.status and delivery.status (pending, in_progress, completed, skipped)
  Map<String, dynamic> _getEffectiveOrderProgress(Map<String, dynamic> order) {
    final mainStatus = (order['status'] as String?)?.toLowerCase() ?? 'pending';
    
    // Parse handling JSONB - it may be a String or a Map
    Map<String, dynamic> handling = {};
    final handlingData = order['handling'];
    if (handlingData is String) {
      try {
        handling = Map<String, dynamic>.from(
          (handlingData.isNotEmpty) ? _parseJsonString(handlingData) : {}
        );
      } catch (e) {
        debugPrint('⚠️ Error parsing handling JSON: $e');
      }
    } else if (handlingData is Map) {
      handling = Map<String, dynamic>.from(handlingData);
    }
    
    final pickupData = handling['pickup'] as Map<String, dynamic>? ?? {};
    final deliveryData = handling['delivery'] as Map<String, dynamic>? ?? {};
    
    final pickupStatus = (pickupData['status'] as String?)?.toLowerCase() ?? 'pending';
    final deliveryStatus = (deliveryData['status'] as String?)?.toLowerCase() ?? 'pending';
    
    debugPrint('📊 Order Progress Analysis:');
    debugPrint('   Main status: $mainStatus');
    debugPrint('   Pickup status: $pickupStatus');
    debugPrint('   Delivery status: $deliveryStatus');
    
    // Determine which step we're on based on statuses
    // Flow: pending -> pickup (in_progress/completed) -> processing -> delivery (in_progress/completed) -> completed
    
    String effectiveStatus = 'pending';
    Map<String, bool> stepCompleted = {
      'pending': false,
      'for_pick-up': false,
      'processing': false,
      'for_delivery': false,
      'completed': false,
    };
    
    // Step 1: Pending - always starts here
    if (mainStatus == 'pending' && pickupStatus == 'pending') {
      effectiveStatus = 'pending';
      stepCompleted['pending'] = false;
    } 
    // Step 2: Pick-up in progress
    else if (pickupStatus == 'in_progress') {
      effectiveStatus = 'for_pick-up';
      stepCompleted['pending'] = true;
      stepCompleted['for_pick-up'] = false;
    }
    // Step 3: Processing (pickup completed or skipped, main status is processing)
    else if (mainStatus == 'processing' || 
             (pickupStatus == 'completed' || pickupStatus == 'skipped') && 
             mainStatus != 'completed' && deliveryStatus == 'pending') {
      effectiveStatus = 'processing';
      stepCompleted['pending'] = true;
      stepCompleted['for_pick-up'] = true;
      stepCompleted['processing'] = mainStatus == 'processing';
    }
    // Step 4: Delivery in progress
    else if (deliveryStatus == 'in_progress') {
      effectiveStatus = 'for_delivery';
      stepCompleted['pending'] = true;
      stepCompleted['for_pick-up'] = true;
      stepCompleted['processing'] = true;
      stepCompleted['for_delivery'] = false;
    }
    // Step 5: Completed
    else if (mainStatus == 'completed' || deliveryStatus == 'completed') {
      effectiveStatus = 'completed';
      stepCompleted['pending'] = true;
      stepCompleted['for_pick-up'] = true;
      stepCompleted['processing'] = true;
      stepCompleted['for_delivery'] = true;
      stepCompleted['completed'] = true;
    }
    // Cancelled
    else if (mainStatus == 'cancelled') {
      effectiveStatus = 'cancelled';
    }
    // Fallback: if pickup is completed/skipped but we're not yet at processing
    else if (pickupStatus == 'completed' || pickupStatus == 'skipped') {
      effectiveStatus = 'processing';
      stepCompleted['pending'] = true;
      stepCompleted['for_pick-up'] = true;
    }
    
    debugPrint('   Effective status: $effectiveStatus');
    debugPrint('   Step completion: $stepCompleted');
    
    return {
      'effectiveStatus': effectiveStatus,
      'stepCompleted': stepCompleted,
      'pickupStatus': pickupStatus,
      'deliveryStatus': deliveryStatus,
      'mainStatus': mainStatus,
    };
  }

  /// Build order status timeline using order data with handling JSONB
  Widget _buildStatusTimeline(BuildContext context, Map<String, dynamic> order) {
    final statuses = ['pending', 'for_pick-up', 'processing', 'for_delivery', 'completed'];
    final statusLabels = {
      'pending': 'Pending',
      'for_pick-up': 'Pick-up',
      'processing': 'Processing',
      'for_delivery': 'Delivery',
      'completed': 'Completed',
    };
    final statusMessages = {
      'pending': 'Your order has been placed',
      'for_pick-up': 'The rider is on the way to pick up your order',
      'processing': 'Your order is being processed',
      'for_delivery': 'Out for delivery to your location',
      'completed': 'Order successfully delivered',
    };
    
    // Get effective status from order + handling JSONB
    final progress = _getEffectiveOrderProgress(order);
    final effectiveStatus = progress['effectiveStatus'] as String;
    final stepCompleted = progress['stepCompleted'] as Map<String, bool>;
    final currentIndex = statuses.indexOf(effectiveStatus);
    
    // Debug print to verify status matching
    debugPrint('🔄 Order Progress Timeline:');
    debugPrint('   Effective status: $effectiveStatus');
    debugPrint('   Current index: $currentIndex');
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ILabaColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!, width: 1),
        boxShadow: [
          BoxShadow(
            color: ILabaColors.darkText.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order Progress',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          // Vertical timeline
          ...List.generate(statuses.length, (index) {
            final status = statuses[index];
            final isCompleted = stepCompleted[status] == true && index < currentIndex;
            final isCurrent = index == currentIndex;
            final isPending = index > currentIndex;
            final statusColor = OrderDetailsHelpers.getStatusColor(status);
            final statusIcon = OrderDetailsHelpers.getStatusIcon(status);
            final label = statusLabels[status] ?? status;
            final message = statusMessages[status] ?? '';

            return Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status circle with icon
                    Column(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isCompleted || isCurrent
                                ? statusColor
                                : Colors.grey[200],
                            border: isCurrent
                                ? Border.all(
                                    color: statusColor,
                                    width: 2.5,
                                  )
                                : null,
                          ),
                          child: Icon(
                            statusIcon,
                            color: isCompleted || isCurrent
                                ? ILabaColors.white
                                : Colors.grey[500],
                            size: 20,
                          ),
                        ),
                        // Vertical line to next status (except last)
                        if (index < statuses.length - 1)
                          Container(
                            width: 2,
                            height: 24,
                            color: isCompleted
                                ? statusColor
                                : Colors.grey[300],
                          ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    // Status label and message
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              label,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w600,
                                color: isCurrent ? statusColor : (isPending ? Colors.grey[600] : Colors.grey[900]),
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              message,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: isPending ? Colors.grey[500] : Colors.grey[700],
                                fontSize: 12,
                              ),
                            ),
                            // Status badge for current
                            if (isCurrent) ...[
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'Current',
                                  style: TextStyle(
                                    color: statusColor,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                // Space between items
                if (index < statuses.length - 1) const SizedBox(height: 8),
              ],
            );
          }),
        ],
      ),
    );
  }

  /// Build summary card - Modernized layout with two-column grid
  Widget _buildSummaryCard(
    BuildContext context,
    Map<String, dynamic> summary,
    Map<String, dynamic> order,
    List<dynamic> baskets,
    List<dynamic> items,
    Map<String, dynamic> productsMap,
  ) {
    // Calculate subtotals by summing actual line items
    num calculatedSubtotalServices = 0;
    num calculatedSubtotalProducts = 0;

    // Sum service prices from baskets
    for (final basketDyn in baskets) {
      if (basketDyn is! Map<String, dynamic>) continue;
      final basket = basketDyn;
      final services = (basket['services'] as Map<String, dynamic>?) ?? {};

      // Add individual service prices
      if (services['wash'] != null && services['wash'] != 'off') {
        final washPricing = services['wash_pricing'] as Map<String, dynamic>?;
        calculatedSubtotalServices += SafeConversion.toNum(washPricing?['base_price']);
      }
      if (services['dry'] != null && services['dry'] != 'off') {
        final dryPricing = services['dry_pricing'] as Map<String, dynamic>?;
        calculatedSubtotalServices += SafeConversion.toNum(dryPricing?['base_price']);
      }
      final ironWeightKg = (services['iron_weight_kg'] as int?) ?? 0;
      if (ironWeightKg > 0) {
        final ironPricing = services['iron_pricing'] as Map<String, dynamic>?;
        calculatedSubtotalServices += SafeConversion.toNum(ironPricing?['base_price']);
      }
      if (services['staff_service_pricing'] != null) {
        final staffPricing = services['staff_service_pricing'] as Map<String, dynamic>?;
        calculatedSubtotalServices += SafeConversion.toNum(staffPricing?['base_price']);
      }
      if (services['fold'] == true) {
        final foldPricing = services['fold_pricing'] as Map<String, dynamic>?;
        calculatedSubtotalServices += SafeConversion.toNum(foldPricing?['base_price']);
      }
      if (services['spin'] == true) {
        final spinPricing = services['spin_pricing'] as Map<String, dynamic>?;
        calculatedSubtotalServices += SafeConversion.toNum(spinPricing?['base_price']);
      }
      final additionalDryMinutes = (services['additional_dry_minutes'] as int?) ?? 0;
      if (additionalDryMinutes > 0) {
        final additionalDryPricing = services['additional_dry_pricing'] as Map<String, dynamic>?;
        calculatedSubtotalServices += SafeConversion.toNum(additionalDryPricing?['base_price']);
      }
      final plasticBags = (services['plastic_bags'] as int?) ?? 0;
      if (plasticBags > 0) {
        final plasticBagsPricing = services['plastic_bags_pricing'] as Map<String, dynamic>?;
        calculatedSubtotalServices += SafeConversion.toNum(plasticBagsPricing?['base_price']);
      }
    }

    // Sum product prices from items
    for (final itemDyn in items) {
      if (itemDyn is! Map<String, dynamic>) continue;
      final item = itemDyn;
      final quantity = SafeConversion.toInt(item['quantity']);
      final pricePerUnit = SafeConversion.toNum(item['price_per_unit']);
      calculatedSubtotalProducts += pricePerUnit * quantity;
    }

    // Use calculated values, with fallbacks to summary/order
    num subtotalProducts = calculatedSubtotalProducts > 0 ? calculatedSubtotalProducts : SafeConversion.toNum(summary['subtotal_products']);
    if (subtotalProducts == 0) subtotalProducts = SafeConversion.toNum(order['products_total']);
    
    num subtotalServices = calculatedSubtotalServices > 0 ? calculatedSubtotalServices : SafeConversion.toNum(summary['subtotal_services']);
    if (subtotalServices == 0) subtotalServices = SafeConversion.toNum(order['services_total']);
    
    num handling = SafeConversion.toNum(summary['handling']);
    if (handling == 0) handling = SafeConversion.toNum(order['handling_fee']);
    
    num serviceFee = SafeConversion.toNum(summary['service_fee']);
    if (serviceFee == 0) serviceFee = SafeConversion.toNum(order['service_fee']);
    
    num discounts = SafeConversion.toNum(summary['discounts']);
    if (discounts == 0) discounts = SafeConversion.toNum(order['discount_amount']);
    
    num vatAmount = SafeConversion.toNum(summary['vat_amount']);
    if (vatAmount == 0) vatAmount = SafeConversion.toNum(order['vat_amount']);
    
    // Use grand_total from summary, fallback to total_amount from order
    num grandTotal = SafeConversion.toNum(summary['grand_total']);
    if (grandTotal == 0) grandTotal = SafeConversion.toNum(order['total_amount']);
    
    // If grand total is still 0 but we have subtotals, calculate it
    if (grandTotal == 0 && (subtotalProducts > 0 || subtotalServices > 0)) {
      grandTotal = subtotalProducts + subtotalServices + handling + serviceFee - discounts;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ILabaColors.white,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: Colors.grey[200]!, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: ILabaColors.darkText.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🧮 Services & Products summary
          if (subtotalProducts > 0 || subtotalServices > 0)
            Wrap(
              runSpacing: 10,
              spacing: 16,
              children: [
                if (subtotalServices > 0)
                  Expanded(
                    child: OrderDetailsWidgets.buildSummaryRow(
                      context,
                      'Services',
                      OrderDetailsHelpers.formatCurrency(subtotalServices),
                      isHighlight: false,
                    ),
                    flex: 1,
                  ),
                if (subtotalProducts > 0)
                  Expanded(
                    child: OrderDetailsWidgets.buildSummaryRow(
                      context,
                      'Products',
                      OrderDetailsHelpers.formatCurrency(subtotalProducts),
                      isHighlight: false,
                    ),
                    flex: 1,
                  ),
              ],
            ),

          if (subtotalProducts > 0 || subtotalServices > 0)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Container(height: 0.8, color: Colors.grey[200]),
            ),

          // 💰 Subtotal
          OrderDetailsWidgets.buildSummaryRow(
            context,
            'Subtotal',
            OrderDetailsHelpers.formatCurrency(
              subtotalProducts + subtotalServices,
            ),
            isHighlight: true,
          ),

          // � Fees section (Delivery Fee, Staff Service Fee)
          if (handling > 0 || serviceFee > 0) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Container(height: 0.8, color: Colors.grey[200]),
            ),
            if (handling > 0)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: OrderDetailsWidgets.buildSummaryRow(
                  context,
                  'Delivery Fee',
                  OrderDetailsHelpers.formatCurrency(handling),
                  isHighlight: false,
                ),
              ),
            if (serviceFee > 0)
              OrderDetailsWidgets.buildSummaryRow(
                context,
                'Staff Service Fee',
                OrderDetailsHelpers.formatCurrency(serviceFee),
                isHighlight: false,
              ),
          ],

          if (discounts > 0) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Container(height: 0.8, color: Colors.grey[200]),
            ),
            OrderDetailsWidgets.buildSummaryRow(
              context,
              'Discounts',
              '-${OrderDetailsHelpers.formatCurrency(discounts)}',
              isHighlight: true,
              isNegative: true,
            ),
          ],

          const SizedBox(height: 12),

          // 🧮 VAT & Total in row
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(7),
                    border: Border.all(color: Colors.grey[200]!, width: 0.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'VAT (12%)',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        OrderDetailsHelpers.formatCurrency(vatAmount),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: Colors.grey[900],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(7),
                    border: Border.all(color: Colors.green[200]!, width: 1.2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TOTAL',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          color: Colors.green[900],
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        OrderDetailsHelpers.formatCurrency(grandTotal),
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              color: Colors.green[700],
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build payment card - Modernized layout
  Widget _buildPaymentCard(BuildContext context, Map<String, dynamic> payment) {
    final method = (payment['method'] ?? 'Unknown').toString();
    final amountPaid = payment['amount_paid'] ?? 0;
    final change = payment['change'] ?? 0;
    final paymentStatus = payment['payment_status'] ?? 'N/A';
    final referenceNumber = payment['reference_number'];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ILabaColors.white,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: Colors.grey[200]!, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: ILabaColors.darkText.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 💳 Method Badge + Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.green[700],
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Text(
                  OrderDetailsHelpers.formatLabel(method),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: ILabaColors.white,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: OrderDetailsHelpers.getStatusColor(paymentStatus),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  OrderDetailsHelpers.formatLabel(paymentStatus),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: ILabaColors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(height: 0.8, color: Colors.grey[200]),
          const SizedBox(height: 14),

          // 💰 Amount & Change in two-column
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[100]!, width: 0.8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Paid',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue[700],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        OrderDetailsHelpers.formatCurrency(amountPaid),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.blue[900],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (change > 0) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.amber[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber[100]!, width: 0.8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Change',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.amber[700],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          OrderDetailsHelpers.formatCurrency(change),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.amber[900],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (referenceNumber != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!, width: 0.5),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.qr_code_2_outlined,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      referenceNumber.toString(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                        fontFamily: 'monospace',
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Build cancellation card
  Widget _buildCancellationCard(
    BuildContext context,
    Map<String, dynamic> cancellation,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: Colors.grey[200]!, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.cancel_outlined, color: Colors.red[700], size: 18),
              const SizedBox(width: 7),
              Text(
                'Order Cancelled',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Colors.red[700],
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Reason: ${OrderDetailsHelpers.formatLabel(cancellation['reason'] ?? 'N/A')}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (cancellation['notes'] != null) ...[
            const SizedBox(height: 5),
            Text(
              'Notes: ${cancellation['notes']}',
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  /// Build audit log cards
  List<Widget> _buildAuditLogCards(
    BuildContext context,
    List<dynamic> auditLog,
  ) {
    return auditLog.map((log) {
      final l = log as Map<String, dynamic>;
      final action = OrderDetailsHelpers.formatLabel(l['action'] ?? 'Unknown');
      final timestamp = OrderDetailsHelpers.formatDate(l['timestamp'] ?? '');

      return Container(
        margin: const EdgeInsets.only(bottom: 7),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[200]!, width: 1),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: Colors.blue[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle,
                color: Colors.blue[700],
                size: 16,
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    action,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time_outlined,
                        size: 13,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 3),
                      Text(
                        timestamp,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  if (l['changed_by'] != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      'By: ${l['changed_by']}',
                      style: Theme.of(
                        context,
                      ).textTheme.labelSmall?.copyWith(fontSize: 11),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
    }).toList();
  }
}
