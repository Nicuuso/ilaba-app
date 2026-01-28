/// Step 2: Products Selection
/// Browse and add retail products to order
/// - Search products
/// - View product details
/// - Add/remove products with quantity
/// - See running subtotal

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ilaba/providers/mobile_booking_provider.dart';
import 'package:ilaba/screens/mobile_booking/order_summary_expandable.dart';
import 'package:ilaba/constants/ilaba_colors.dart';

class MobileBookingProductsStep extends StatefulWidget {
  const MobileBookingProductsStep({Key? key}) : super(key: key);

  @override
  State<MobileBookingProductsStep> createState() =>
      _MobileBookingProductsStepState();
}

class _MobileBookingProductsStepState extends State<MobileBookingProductsStep> {
  late TextEditingController _searchController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MobileBookingProvider>(
      builder: (context, provider, _) {
        final filteredProducts = provider.products
            .where(
              (p) =>
                  p.itemName.toLowerCase().contains(_searchQuery.toLowerCase()),
            )
            .toList();

        return Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search products...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
            ),

            // Products List
            Expanded(
              child: filteredProducts.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.shopping_cart_outlined,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _searchQuery.isEmpty
                                ? 'No products available'
                                : 'No products found',
                            style: TextStyle(
                              color: ILabaColors.lightText,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: filteredProducts.length,
                      itemBuilder: (context, index) {
                        final product = filteredProducts[index];
                        final quantity =
                            provider.selectedProducts[product.id] ?? 0;

                        return _buildProductCard(
                          context,
                          provider,
                          product,
                          quantity,
                        );
                      },
                    ),
            ),

            // Order Summary - Always visible
            OrderSummaryExpandable(
              provider: provider,
              showProductBreakdown: true,
              showDeliveryFee: false,
            ),
          ],
        );
      },
    );
  }

  /// Build product card
  Widget _buildProductCard(
    BuildContext context,
    MobileBookingProvider provider,
    product,
    int quantity,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Product Image or Icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: product.imageUrl != null
                  ? Image.network(
                      product.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Center(
                          child: Icon(
                            Icons.image_not_supported,
                            color: Colors.grey.shade400,
                          ),
                        );
                      },
                    )
                  : Center(
                      child: Icon(
                        Icons.shopping_bag,
                        color: Colors.grey.shade400,
                      ),
                    ),
            ),
            const SizedBox(width: 12),

            // Product Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.itemName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₱${product.unitPrice.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: ILabaColors.burgundy,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Stock: ${product.quantityInStock}',
                    style: TextStyle(
                      fontSize: 12,
                      color: product.quantityInStock > 0
                          ? Colors.green
                          : Colors.red,
                    ),
                  ),
                ],
              ),
            ),

            // Quantity Controls
            if (quantity == 0)
              ElevatedButton(
                onPressed: product.quantityInStock > 0
                    ? () => provider.addProduct(product.id)
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ILabaColors.burgundy,
                  foregroundColor: ILabaColors.white,
                  disabledBackgroundColor: Colors.grey.shade300,
                  disabledForegroundColor: Colors.grey.shade500,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                child: Text(product.quantityInStock > 0 ? 'Add' : 'Out of Stock'),
              )
            else
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove),
                        onPressed: () => provider.setProductQuantity(
                          product.id,
                          quantity - 1,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 36,
                          minHeight: 36,
                        ),
                        padding: const EdgeInsets.all(0),
                      ),
                      Container(
                        width: 40,
                        alignment: Alignment.center,
                        child: Text(
                          '$quantity',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.add,
                          color: quantity >= product.quantityInStock
                              ? Colors.grey.shade400
                              : null,
                        ),
                        onPressed: quantity >= product.quantityInStock
                            ? null
                            : () => provider.setProductQuantity(
                                  product.id,
                                  quantity + 1,
                                ),
                        constraints: const BoxConstraints(
                          minWidth: 36,
                          minHeight: 36,
                        ),
                        padding: const EdgeInsets.all(0),
                      ),
                    ],
                  ),
                  Text(
                    '₱${(product.unitPrice * quantity).toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: ILabaColors.burgundy,
                    ),
                  ),
                  if (quantity >= product.quantityInStock)
                    Text(
                      'Max stock reached',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.orange.shade700,
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
