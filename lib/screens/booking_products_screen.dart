import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ilaba/providers/booking_state_provider.dart';
import 'package:ilaba/widgets/custom_text_field.dart';

class BookingProductsScreen extends StatefulWidget {
  const BookingProductsScreen({Key? key}) : super(key: key);

  @override
  State<BookingProductsScreen> createState() => _BookingProductsScreenState();
}

class _BookingProductsScreenState extends State<BookingProductsScreen> {
  late TextEditingController _searchController;

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
    return Consumer<BookingStateNotifier>(
      builder: (context, state, _) {
        // Filter products based on search
        final filteredProducts = state.products
            .where(
              (product) => product.itemName.toLowerCase().contains(
                _searchController.text.toLowerCase(),
              ),
            )
            .toList();

        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Select Products',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                // Search field
                CustomTextField(
                  controller: _searchController,
                  hintText: 'Search products...',
                  onChanged: (value) {
                    setState(() {});
                  },
                ),
                const SizedBox(height: 16),

                // Products list
                if (state.loadingProducts)
                  const Center(child: CircularProgressIndicator())
                else if (filteredProducts.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Column(
                        children: [
                          Icon(
                            Icons.shopping_bag_outlined,
                            size: 48,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _searchController.text.isEmpty
                                ? 'No products available'
                                : 'No products found',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filteredProducts.length,
                    itemBuilder: (context, index) {
                      final product = filteredProducts[index];
                      final quantity =
                          state.orderProductCounts[product.id] ?? 0;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 1,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Product name and price
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          product.itemName,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'PHP ${product.unitPrice.toStringAsFixed(2)}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '₱${product.unitPrice.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green,
                                        ),
                                      ),
                                      if (quantity > 0)
                                        Container(
                                          margin: const EdgeInsets.only(top: 4),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.blue,
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: Text(
                                            'Qty: $quantity',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Action buttons
                              Row(
                                children: [
                                  if (quantity > 0) ...[
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: () {
                                          context
                                              .read<BookingStateNotifier>()
                                              .removeProduct(product.id);
                                        },
                                        icon: const Icon(Icons.remove),
                                        label: const Text('Remove'),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.red,
                                          side: const BorderSide(
                                            color: Colors.red,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                  ],
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () {
                                        context
                                            .read<BookingStateNotifier>()
                                            .addProduct(product.id);
                                      },
                                      icon: const Icon(Icons.add),
                                      label: const Text('Add'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                const SizedBox(height: 16),

                // Products summary
                if (state.orderProductCounts.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      border: Border.all(color: Colors.blue),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Selected Products:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...state.orderProductCounts.entries.map((entry) {
                          final product = state.products.firstWhere(
                            (p) => p.id == entry.key,
                          );
                          final subtotal = product.unitPrice * entry.value;
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    '${product.itemName} x${entry.value}',
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ),
                                Text(
                                  '₱${subtotal.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        const Divider(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Products Subtotal:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              '₱${state.orderProductCounts.entries.fold<double>(0, (sum, entry) {
                                final product = state.products.firstWhere((p) => p.id == entry.key);
                                return sum + (product.unitPrice * entry.value);
                              }).toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
