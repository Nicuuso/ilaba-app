/// Mobile Booking Success Screen
/// Displayed after successful order submission
/// Shows order confirmation, receipt details, and next steps

import 'package:flutter/material.dart';
import 'package:ilaba/models/order_models.dart';
import 'package:ilaba/constants/ilaba_colors.dart';

class MobileBookingSuccessScreen extends StatelessWidget {
  final OrderResponse response;

  const MobileBookingSuccessScreen({required this.response, Key? key})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 32),

                // Success Icon
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.green.shade100,
                  ),
                  child: Center(
                    child: Icon(
                      Icons.check_circle,
                      size: 60,
                      color: Colors.green.shade700,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Success Message
                Text(
                  'Order Created Successfully!',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
                ),
                const SizedBox(height: 12),

                // Order ID
                if (response.orderId != null)
                  Column(
                    children: [
                      Text(
                        'Order ID',
                        style: TextStyle(color: ILabaColors.lightText),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          response.orderId!,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),

                // Receipt Details
                if (response.receipt != null)
                  _buildReceiptDetails(context, response.receipt!),

                const SizedBox(height: 32),

                // Next Steps
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    border: Border.all(color: Colors.blue.shade200),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info, color: Colors.blue.shade700),
                          const SizedBox(width: 8),
                          Text(
                            'What happens next?',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildNextStep(
                        '1',
                        'Confirmation Email',
                        'A receipt email has been sent to your registered email address',
                      ),
                      const SizedBox(height: 12),
                      _buildNextStep(
                        '2',
                        'Order Processing',
                        'Your laundry will be processed and ready within the estimated time',
                      ),
                      const SizedBox(height: 12),
                      _buildNextStep(
                        '3',
                        'Pickup / Delivery',
                        'You will receive an SMS update when your order is ready',
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Action Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(
                      context,
                    ).popUntil((route) => route.isFirst),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      foregroundColor: ILabaColors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Return to Home'),
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Build receipt details section
  Widget _buildReceiptDetails(BuildContext context, OrderReceipt receipt) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: ILabaColors.lightGray),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Order Details',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          // Customer
          Row(
            children: [
              Icon(Icons.person, color: ILabaColors.lightText, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Customer',
                      style: TextStyle(
                        fontSize: 12,
                        color: ILabaColors.lightText,
                      ),
                    ),
                    Text(
                      receipt.customerName,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Baskets Count
          Row(
            children: [
              Icon(
                Icons.shopping_basket,
                color: ILabaColors.lightText,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Baskets',
                      style: TextStyle(
                        fontSize: 12,
                        color: ILabaColors.lightText,
                      ),
                    ),
                    Text(
                      '${receipt.baskets.length} basket${receipt.baskets.length > 1 ? 's' : ''}',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Products Count
          if (receipt.items.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.shopping_cart,
                  color: ILabaColors.lightText,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Products',
                        style: TextStyle(
                          fontSize: 12,
                          color: ILabaColors.lightText,
                        ),
                      ),
                      Text(
                        '${receipt.items.length} item${receipt.items.length > 1 ? 's' : ''}',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],

          // Payment Method
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.payment, color: ILabaColors.lightText, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Payment Method',
                      style: TextStyle(
                        fontSize: 12,
                        color: ILabaColors.lightText,
                      ),
                    ),
                    Text(
                      receipt.paymentMethod.toUpperCase(),
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Total
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Amount',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                '₱${receipt.total.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.indigo,
                ),
              ),
            ],
          ),

          // Loyalty Details
          if (receipt.loyalty != null) ...[
            const Divider(height: 24),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                border: Border.all(color: Colors.amber.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.card_giftcard,
                        color: Colors.amber.shade700,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Loyalty Summary',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (receipt.loyalty!.tier != null)
                    Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Discount Applied',
                              style: TextStyle(fontSize: 12),
                            ),
                            Text(
                              receipt.loyalty!.tier == LoyaltyTier.tier1
                                  ? 'Tier 1 (5%)'
                                  : 'Tier 2 (15%)',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Points Deducted',
                              style: TextStyle(fontSize: 12),
                            ),
                            Text(
                              '-${receipt.loyalty!.pointsUsed}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.orange,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Discount Savings',
                              style: TextStyle(fontSize: 12),
                            ),
                            Text(
                              '₱${receipt.loyalty!.discountAmount.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ],
                    )
                  else
                    const Text(
                      'No discount applied - earning 1 point',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  if (receipt.finalLoyaltyPoints != null) ...[
                    const SizedBox(height: 12),
                    const Divider(height: 1),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Final Points Balance',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          '${receipt.finalLoyaltyPoints}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.amber.shade700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Build next step item
  Widget _buildNextStep(String number, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.blue.shade200,
          ),
          child: Center(
            child: Text(
              number,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade700,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text(
                description,
                style: TextStyle(fontSize: 12, color: ILabaColors.lightText),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
