import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'order_details_helpers.dart';
import 'order_details_widgets.dart';

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
      print('📋 Customer ID: ${widget.order['customer_id']}');
      print('📋 Staff ID: ${widget.order['staff_id']}');

      // Fetch customer data
      print('🔍 Fetching customer from customers table...');
      final customerData = widget.order['customer_id'] != null
          ? await supabase
                .from('customers')
                .select()
                .eq('id', widget.order['customer_id'])
                .single()
          : null;
      print('✅ Customer data: $customerData');

      // Fetch cashier/staff data
      print('🔍 Fetching staff from staff table...');
      final staffData = widget.order['staff_id'] != null
          ? await supabase
                .from('staff')
                .select()
                .eq('id', widget.order['staff_id'])
                .single()
          : null;
      print('✅ Staff data: $staffData');

      // Extract product IDs from breakdown items
      final breakdown =
          widget.order['breakdown'] as Map<String, dynamic>? ?? {};
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

      return {
        'order': widget.order,
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
    final pickupAddress = OrderDataExtractor.extractPickupAddress(order);
    final deliveryAddress = OrderDataExtractor.extractDeliveryAddress(order);

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
              _buildSummaryCard(context, summary),
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
      final services = (basket['services'] as List?) ?? [];

      return Card(
        margin: const EdgeInsets.only(bottom: 8),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: Colors.grey[200]!, width: 0.8),
        ),
        color: Colors.white,
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
                ..._buildServiceItems(context, services),
              ],
            ],
          ),
        ),
      );
    }).toList();
  }

  /// Build service items
  List<Widget> _buildServiceItems(
    BuildContext context,
    List<dynamic> services,
  ) {
    return services.map((service) {
      final svc = service as Map<String, dynamic>;
      print('🔧 Service data: $svc');
      print('🔧 Service keys: ${svc.keys.toList()}');
      
      // Try multiple field names for service name
      String serviceName = svc['service_type'] ?? 
                          svc['service_name'] ?? 
                          svc['name'] ?? 
                          svc['type'] ?? 
                          'Service';
      print('🔧 Service name extracted: $serviceName');
      
      final subtotal = SafeConversion.toNum(svc['subtotal']);

      return Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.7),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.grey[300]!, width: 0.5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      OrderDetailsHelpers.formatLabel(serviceName),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    if (svc['quantity'] != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Qty: ${svc['quantity']}',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if ((subtotal ?? 0) > 0)
                Text(
                  OrderDetailsHelpers.formatCurrency(subtotal),
                  style: TextStyle(
                    color: Colors.green[700],
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
            ],
          ),
        ),
      );
    }).toList();
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
            color: Colors.white,
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

  /// Build summary card - Modernized layout with two-column grid
  Widget _buildSummaryCard(BuildContext context, Map<String, dynamic> summary) {
    final subtotalProducts = summary['subtotal_products'] ?? 0;
    final subtotalServices = summary['subtotal_services'] ?? 0;
    final handling = summary['handling'] ?? 0;
    final serviceFee = summary['service_fee'] ?? 0;
    final discounts = summary['discounts'] ?? 0;
    final vatAmount = summary['vat_amount'] ?? 0;
    final grandTotal = summary['grand_total'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: Colors.grey[200]!, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🧮 Line items in two-column grid
          if (subtotalProducts > 0 || subtotalServices > 0 || handling > 0 || serviceFee > 0)
            Wrap(
              runSpacing: 10,
              spacing: 16,
              children: [
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
                if (handling > 0)
                  Expanded(
                    child: OrderDetailsWidgets.buildSummaryRow(
                      context,
                      'Handling',
                      OrderDetailsHelpers.formatCurrency(handling),
                      isHighlight: false,
                    ),
                    flex: 1,
                  ),
                if (serviceFee > 0)
                  Expanded(
                    child: OrderDetailsWidgets.buildSummaryRow(
                      context,
                      'Service Fee',
                      OrderDetailsHelpers.formatCurrency(serviceFee),
                      isHighlight: false,
                    ),
                    flex: 1,
                  ),
              ],
            ),
          if (subtotalProducts > 0 || subtotalServices > 0 || handling > 0 || serviceFee > 0)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Container(height: 0.8, color: Colors.grey[200]),
            ),

          // 💰 Subtotal & Adjustments
          OrderDetailsWidgets.buildSummaryRow(
            context,
            'Subtotal',
            OrderDetailsHelpers.formatCurrency(subtotalProducts + subtotalServices),
            isHighlight: true,
          ),
          if (discounts > 0) ...[
            const SizedBox(height: 8),
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
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: Colors.grey[200]!, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
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
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green[700],
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Text(
                  OrderDetailsHelpers.formatLabel(method),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
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
                    color: Colors.white,
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
                  padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
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
                    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
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
