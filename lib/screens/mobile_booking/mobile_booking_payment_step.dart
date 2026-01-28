/// Step 4: Payment & Summary
/// Display order summary with all breakdowns
/// Edit customer info (phone, email)
/// Upload GCash receipt (REQUIRED)
/// Enter GCash reference number
/// Apply loyalty discount

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:ilaba/models/order_models.dart';
import 'package:ilaba/providers/mobile_booking_provider.dart';
import 'package:ilaba/constants/ilaba_colors.dart';

class MobileBookingPaymentStep extends StatefulWidget {
  const MobileBookingPaymentStep({Key? key}) : super(key: key);

  @override
  State<MobileBookingPaymentStep> createState() =>
      _MobileBookingPaymentStepState();
}

class _MobileBookingPaymentStepState extends State<MobileBookingPaymentStep> {
  final ImagePicker _imagePicker = ImagePicker();
  File? _selectedReceiptImage;
  late TextEditingController _gcashReferenceController;

  @override
  void initState() {
    super.initState();
    final provider = context.read<MobileBookingProvider>();
    _gcashReferenceController = TextEditingController(text: provider.gcashReference);
  }

  @override
  void dispose() {
    _gcashReferenceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MobileBookingProvider>(
      builder: (context, provider, _) {
        final breakdown = provider.calculateOrderTotal();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Customer Info
              _buildCustomerInfo(context, provider),
              const SizedBox(height: 16),

              // Order Breakdown
              _buildOrderBreakdown(context, provider, breakdown),
              const SizedBox(height: 16),

              // Loyalty Discount
              if (provider.loyaltyPoints > 0)
                Column(
                  children: [
                    _buildLoyaltySection(context, provider, breakdown),
                    const SizedBox(height: 16),
                  ],
                ),

              // GCash Payment Section (combined receipt and reference)
              _buildGCashPaymentSection(context, provider),
              const SizedBox(height: 16),

              // Final Total
              _buildFinalTotal(context, provider, breakdown),
            ],
          ),
        );
      },
    );
  }

  /// Build customer info display/edit
  Widget _buildCustomerInfo(
    BuildContext context,
    MobileBookingProvider provider,
  ) {
    final user = provider.currentUser;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: ILabaColors.lightGray),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Customer Information',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () => _showCustomerInfoEditDialog(context, provider),
                child: const Text('Edit', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (user != null) ...[
            Row(
              children: [
                const Icon(Icons.person, size: 20),
                const SizedBox(width: 12),
                Text(
                  '${user.firstName} ${user.lastName}',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.phone, size: 20),
                const SizedBox(width: 12),
                Text(user.phoneNumber),
              ],
            ),
            if (user.emailAddress != null) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.email, size: 18),
                  const SizedBox(width: 10),
                  Expanded(child: Text(user.emailAddress ?? '', style: const TextStyle(fontSize: 12))),
                ],
              ),
            ],
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.location_on, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    provider.pickupAddress.isNotEmpty ? provider.pickupAddress : 'Not provided',
                    style: const TextStyle(fontSize: 12),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.local_shipping, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    provider.deliveryAddress.isNotEmpty ? provider.deliveryAddress : 'Not provided',
                    style: const TextStyle(fontSize: 12),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// Build order breakdown
  Widget _buildOrderBreakdown(
    BuildContext context,
    MobileBookingProvider provider,
    OrderBreakdown breakdown,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ILabaColors.lightGray,
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Order Breakdown',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          Divider(color: Colors.grey.shade200, height: 1),
          const SizedBox(height: 10),

          // Baskets
          if (breakdown.baskets.isNotEmpty) ...[
            const Text(
              'Laundry Baskets',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
            ),
            ...breakdown.baskets.map((basket) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Basket header with subtotal
                  Padding(
                    padding: const EdgeInsets.only(top: 3, bottom: 2),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Basket ${basket.basketNumber}',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                        ),
                        Text(
                          '₱${basket.subtotal.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                  // Service breakdown for this basket
                  Padding(
                    padding: const EdgeInsets.only(left: 12, bottom: 2),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (basket.services.wash != 'off')
                          Text(
                            '• ${basket.services.wash.toUpperCase()} Wash: ₱${_getServicePrice(provider, 'wash', basket.services.wash).toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 10, color: Colors.grey),
                          ),
                        if (basket.services.dry != 'off')
                          Text(
                            '• ${basket.services.dry.toUpperCase()} Dry: ₱${_getServicePrice(provider, 'dry', basket.services.dry).toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 10, color: Colors.grey),
                          ),
                        if (basket.services.spin)
                          Text(
                            '• Spin: ₱${_getServicePrice(provider, 'spin', null).toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 10, color: Colors.grey),
                          ),
                        if (basket.services.ironWeightKg > 0)
                          Text(
                            '• Iron (${basket.services.ironWeightKg}kg): ₱${(basket.services.ironWeightKg * _getServicePrice(provider, 'iron', null)).toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 10, color: Colors.grey),
                          ),
                        if (basket.services.fold)
                          Text(
                            '• Fold: ₱${_getServicePrice(provider, 'fold', null).toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 10, color: Colors.grey),
                          ),
                        // HIDDEN: Plastic Bags option
                        // if (basket.services.plasticBags > 0)
                        //   Text(
                        //     '• Plastic Bags x${basket.services.plasticBags}: ₱${(basket.services.plasticBags * _getProductPrice(provider, 'plastic')).toStringAsFixed(2)}',
                        //     style: const TextStyle(fontSize: 10, color: Colors.grey),
                        //   ),
                      ],
                    ),
                  ),
                ],
              );
            }),
            const SizedBox(height: 6),
          ],

          // Products
          if (breakdown.items.isNotEmpty) ...[
            const Text(
              'Products',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
            ),
            ...breakdown.items.map((item) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${item.productName} x${item.quantity}',
                      style: const TextStyle(fontSize: 11),
                    ),
                    Text(
                      '₱${item.totalPrice.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 11),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 8),
          ],

          // Fees
          if (breakdown.summary.staffServiceFee > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Staff Service Fee',
                    style: TextStyle(fontSize: 12),
                  ),
                  Text(
                    '₱${breakdown.summary.staffServiceFee.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          if (breakdown.summary.deliveryFee > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Delivery Fee', style: TextStyle(fontSize: 12)),
                  Text(
                    '₱${breakdown.summary.deliveryFee.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('VAT (12%)', style: TextStyle(fontSize: 12)),
                Text(
                  '₱${breakdown.summary.vatAmount.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build loyalty discount section
  Widget _buildLoyaltySection(
    BuildContext context,
    MobileBookingProvider provider,
    OrderBreakdown breakdown,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
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
              const Icon(Icons.card_giftcard, color: Colors.amber),
              const SizedBox(width: 8),
              Text(
                'Loyalty Points: ${provider.loyaltyPoints}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // No Discount Option
          _buildLoyaltyOption(
            context,
            provider,
            tier: null,
            label: 'No Discount',
            description: 'Earn 1 point per order',
            requiresPoints: false,
          ),
          const SizedBox(height: 12),
          // Tier 1 Option
          _buildLoyaltyOption(
            context,
            provider,
            tier: LoyaltyTier.tier1,
            label: 'Tier 1 Discount - 5% Off',
            description: 'Deduct 10 points',
            requiresPoints: 10,
            breakdown: breakdown,
          ),
          const SizedBox(height: 12),
          // Tier 2 Option
          _buildLoyaltyOption(
            context,
            provider,
            tier: LoyaltyTier.tier2,
            label: 'Tier 2 Discount - 15% Off',
            description: 'Deduct 20 points',
            requiresPoints: 20,
            breakdown: breakdown,
          ),
        ],
      ),
    );
  }

  /// Build loyalty option (supports null for no discount, tier1, or tier2)
  Widget _buildLoyaltyOption(
    BuildContext context,
    MobileBookingProvider provider, {
    required LoyaltyTier? tier,
    required String label,
    required String description,
    required dynamic requiresPoints, // bool or int
    OrderBreakdown? breakdown,
  }) {
    final isSelected = provider.selectedLoyaltyTier == tier;
    final hasEnoughPoints = requiresPoints is bool 
      ? true 
      : provider.loyaltyPoints >= requiresPoints;
    
    double discount = 0;
    if (tier != null && breakdown != null && hasEnoughPoints) {
      discount = provider.calculateLoyaltyDiscount(
        breakdown.summary.total,
        tier,
      );
    }

    return GestureDetector(
      onTap: hasEnoughPoints ? () {
        if (isSelected) {
          provider.setLoyaltyTier(null);
        } else {
          provider.setLoyaltyTier(tier);
        }
      } : null,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: hasEnoughPoints 
              ? (isSelected ? Colors.amber : Colors.amber.shade200)
              : ILabaColors.lightGray,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
          color: hasEnoughPoints
            ? (isSelected ? Colors.amber.shade100 : ILabaColors.white)
            : Colors.grey.shade100,
        ),
        child: Row(
          children: [
            Radio<LoyaltyTier?>(
              value: tier,
              groupValue: provider.selectedLoyaltyTier,
              onChanged: hasEnoughPoints ? (value) {
                provider.setLoyaltyTier(value);
              } : null,
              activeColor: Colors.amber,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: hasEnoughPoints ? Colors.black : ILabaColors.lightText,
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 11,
                          color: hasEnoughPoints ? ILabaColors.lightText : Colors.grey.shade500,
                        ),
                      ),
                      if (tier != null && discount > 0)
                        Text(
                          'Save ₱${discount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      else if (!hasEnoughPoints && requiresPoints is int)
                        Text(
                          'Need ${requiresPoints - provider.loyaltyPoints} more',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.red.shade600,
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
  }

  /// Build receipt upload section
  Widget _buildReceiptUpload(
    BuildContext context,
    MobileBookingProvider provider,
  ) {
    final hasReceipt =
        provider.gcashReceiptPath != null &&
        provider.gcashReceiptPath!.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(
          color: hasReceipt ? Colors.green : Colors.red,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                hasReceipt ? Icons.check_circle : Icons.info,
                color: hasReceipt ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'GCash Receipt Upload (Required)',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: hasReceipt ? Colors.green : Colors.red,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (hasReceipt)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check, color: Colors.green, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Receipt uploaded successfully',
                          style: TextStyle(
                            color: Colors.green.shade700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => _pickReceiptImage(context, provider),
                  icon: const Icon(Icons.edit),
                  label: const Text('Change Receipt'),
                ),
              ],
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Please upload a photo of your GCash receipt to complete the payment',
                  style: TextStyle(fontSize: 12, color: ILabaColors.lightText),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () => _pickReceiptImage(context, provider),
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Upload Receipt'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ILabaColors.burgundy,
                    foregroundColor: ILabaColors.white,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  /// Build combined GCash payment section (receipt + reference)
  Widget _buildGCashPaymentSection(
    BuildContext context,
    MobileBookingProvider provider,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.orange.shade300),
        borderRadius: BorderRadius.circular(8),
        color: Colors.orange.shade50,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.payment, color: Colors.orange.shade700, size: 20),
              const SizedBox(width: 8),
              const Text(
                'GCash Payment',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Receipt Upload
          _buildReceiptUpload(context, provider),
          // HIDDEN: GCash Reference Number
          // const SizedBox(height: 12),
          // _buildGCashReference(context, provider),
        ],
      ),
    );
  }

  /// Build GCash reference input
  Widget _buildGCashReference(
    BuildContext context,
    MobileBookingProvider provider,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'GCash Reference Number (Required)',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _gcashReferenceController,
          decoration: InputDecoration(
            hintText: 'e.g., GCASH123456789',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            prefixIcon: const Icon(Icons.confirmation_number, size: 18),
          ),
          style: const TextStyle(fontSize: 12),
          onChanged: (value) => provider.setGcashReference(value),
        ),
        const SizedBox(height: 6),
        Text(
          'This is the reference number provided by GCash',
          style: TextStyle(fontSize: 11, color: ILabaColors.lightText),
        ),
      ],
    );
  }

  /// Build final total display
  Widget _buildFinalTotal(
    BuildContext context,
    MobileBookingProvider provider,
    OrderBreakdown breakdown,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ILabaColors.burgundy.withOpacity(0.1),
        border: Border.all(color: ILabaColors.burgundy),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (breakdown.summary.loyaltyDiscount > 0) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Subtotal:', style: TextStyle(fontSize: 12)),
                Text(
                  '₱${(breakdown.summary.total + breakdown.summary.loyaltyDiscount).toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Loyalty Discount:',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '-₱${breakdown.summary.loyaltyDiscount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 16),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'TOTAL AMOUNT:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: ILabaColors.burgundy,
                ),
              ),
              Text(
                '₱${breakdown.summary.total.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: ILabaColors.burgundy,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Payment method: GCash',
            style: TextStyle(fontSize: 12, color: ILabaColors.lightText),
          ),
        ],
      ),
    );
  }

  /// Get service price
  double _getServicePrice(
    MobileBookingProvider provider,
    String serviceType,
    String? tier,
  ) {
    try {
      final service = provider.services.firstWhere(
        (s) => s.serviceType == serviceType && (tier == null || s.tier == tier),
        orElse: () => Service(
          id: '',
          serviceType: '',
          name: '',
          basePrice: 0,
        ),
      );
      return service.basePrice;
    } catch (e) {
      return 0;
    }
  }

  /// Get product price
  double _getProductPrice(MobileBookingProvider provider, String keyword) {
    try {
      final product = provider.products.firstWhere(
        (p) => p.itemName.toLowerCase().contains(keyword.toLowerCase()),
        orElse: () => Product(
          id: '',
          itemName: '',
          unitPrice: 0,
          quantityInStock: 0,
        ),
      );
      return product.unitPrice;
    } catch (e) {
      return 0;
    }
  }

  /// Show edit dialog for customer info
  void _showCustomerInfoEditDialog(
    BuildContext context,
    MobileBookingProvider provider,
  ) {
    final user = provider.currentUser;
    if (user == null) return;

    final phoneController = TextEditingController(text: user.phoneNumber);
    final emailController = TextEditingController(text: user.emailAddress ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Contact Information'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // In a real app, you would update the user here
              // For now, just show confirmation and close
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Contact information updated'),
                ),
              );
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  /// Pick receipt image from gallery or camera
  Future<void> _pickReceiptImage(
    BuildContext context,
    MobileBookingProvider provider,
  ) async {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera),
              title: const Text('Take Photo'),
              onTap: () async {
                Navigator.pop(context);
                try {
                  final image = await _imagePicker.pickImage(
                    source: ImageSource.camera,
                  );
                  if (image != null) {
                    await provider.uploadGcashReceipt(File(image.path));
                  }
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.image),
              title: const Text('Choose from Gallery'),
              onTap: () async {
                Navigator.pop(context);
                try {
                  final image = await _imagePicker.pickImage(
                    source: ImageSource.gallery,
                  );
                  if (image != null) {
                    await provider.uploadGcashReceipt(File(image.path));
                  }
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
