import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ilaba/providers/booking_state_provider.dart';
import 'package:ilaba/providers/auth_provider.dart';
import 'package:ilaba/services/gcash_receipt_upload_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BookingReceiptPaymentScreen extends StatefulWidget {
  const BookingReceiptPaymentScreen({super.key});

  @override
  State<BookingReceiptPaymentScreen> createState() =>
      _BookingReceiptPaymentScreenState();
}

class _BookingReceiptPaymentScreenState
    extends State<BookingReceiptPaymentScreen> {
  bool _isUploading = false;
  String? _uploadError;

  Future<void> _pickAndUploadImage(BuildContext context) async {
    try {
      setState(() {
        _uploadError = null;
      });

      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80, // Compress to keep under 2MB
      );

      if (image == null) return;

      // Check file size
      final fileSize = await image.length();
      final fileSizeMB = fileSize / 1024 / 1024;
      if (fileSizeMB > 2) {
        if (!mounted) return;
        setState(() {
          _uploadError =
              'File too large: ${fileSizeMB.toStringAsFixed(2)}MB (max: 2MB)';
        });
        return;
      }

      setState(() {
        _isUploading = true;
      });

      final authProvider = context.read<AuthProvider>();
      final userId = authProvider.currentUser?.id;

      if (userId == null) {
        if (!mounted) return;
        setState(() {
          _uploadError = 'User not authenticated';
          _isUploading = false;
        });
        return;
      }

      // Upload to Supabase using Supabase auth user ID (for RLS policy)
      final supabase = Supabase.instance.client;
      final supabaseUserId = supabase.auth.currentUser?.id;

      if (supabaseUserId == null) {
        if (!mounted) return;
        setState(() {
          _uploadError = 'Supabase auth not available';
          _isUploading = false;
        });
        return;
      }

      final url = await GCashReceiptUploadService.uploadReceipt(
        image.path,
        supabaseUserId, // Use Supabase auth user ID for RLS policy
      );

      if (!mounted) return;

      if (url != null) {
        // Save URL to booking state
        final bookingState = context.read<BookingStateNotifier>();
        bookingState.setGCashReceiptUrl(url);

        setState(() {
          _isUploading = false;
        });
      } else {
        setState(() {
          _uploadError = 'Upload failed. Please try again.';
          _isUploading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _uploadError = e.toString();
        _isUploading = false;
      });
      debugPrint('Upload error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BookingStateNotifier>(
      builder: (context, bookingState, _) {
        final receipt = bookingState.computeReceipt();
        final colorScheme = Theme.of(context).colorScheme;

        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Receipt & Payment',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                // Receipt Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'ORDER SUMMARY',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const Divider(),
                        const SizedBox(height: 12),

                        // Products
                        if (receipt.productLines.isNotEmpty) ...[
                          const Text(
                            'Products:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          ...receipt.productLines.map((line) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text('${line.name} x${line.qty}'),
                                  ),
                                  Text(
                                    '₱${line.lineTotal.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Subtotal:'),
                              Text(
                                '₱${receipt.productSubtotal.toStringAsFixed(2)}',
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Divider(),
                          const SizedBox(height: 8),
                        ],

                        // Services
                        if (receipt.basketLines.isNotEmpty) ...[
                          const Text(
                            'Laundry Services:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          ...receipt.basketLines.map((line) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '${line.name} (${line.weightKg}kg)',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        '₱${line.total.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      left: 12,
                                      top: 4,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        if ((line.breakdown['wash'] ?? 0) > 0)
                                          Text(
                                            'Wash${line.premiumFlags['wash'] ?? false ? ' (Premium)' : ''}: ₱${(line.breakdown['wash'] ?? 0).toStringAsFixed(2)}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                            ),
                                          ),
                                        if ((line.breakdown['dry'] ?? 0) > 0)
                                          Text(
                                            'Dry${line.premiumFlags['dry'] ?? false ? ' (Premium)' : ''}: ₱${(line.breakdown['dry'] ?? 0).toStringAsFixed(2)}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                            ),
                                          ),
                                        if ((line.breakdown['spin'] ?? 0) > 0)
                                          Text(
                                            'Spin: ₱${(line.breakdown['spin'] ?? 0).toStringAsFixed(2)}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                            ),
                                          ),
                                        if ((line.breakdown['iron'] ?? 0) > 0)
                                          Text(
                                            'Iron: ₱${(line.breakdown['iron'] ?? 0).toStringAsFixed(2)}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                            ),
                                          ),
                                        if ((line.breakdown['fold'] ?? 0) > 0)
                                          Text(
                                            'Fold: ₱${(line.breakdown['fold'] ?? 0).toStringAsFixed(2)}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Subtotal:'),
                              Text(
                                '₱${receipt.basketSubtotal.toStringAsFixed(2)}',
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Divider(),
                          const SizedBox(height: 8),
                        ],

                        // Fees
                        if (receipt.serviceFee > 0)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Service Fee:'),
                              Text('₱${receipt.serviceFee.toStringAsFixed(2)}'),
                            ],
                          ),
                        if (receipt.handlingFee > 0) ...[
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Delivery Fee:'),
                              Text(
                                '₱${receipt.handlingFee.toStringAsFixed(2)}',
                              ),
                            ],
                          ),
                        ],

                        if (receipt.serviceFee > 0 ||
                            receipt.handlingFee > 0) ...[
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Tax (12%):'),
                              Text('₱${receipt.tax.toStringAsFixed(2)}'),
                            ],
                          ),
                        ],

                        // Loyalty Discount Section
                        if (receipt.loyaltyPoints > 0) ...[
                          const SizedBox(height: 12),
                          const Divider(),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: colorScheme.primaryContainer.withOpacity(
                                0.5,
                              ),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: colorScheme.primary.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '💰 Loyalty Points: ${receipt.loyaltyPoints}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: colorScheme.primary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Consumer<BookingStateNotifier>(
                                          builder: (context, bookingState, _) {
                                            final availableTiers = bookingState
                                                .getAvailableLoyaltyTiers();
                                            if (availableTiers.isEmpty) {
                                              return const Text(
                                                'Need 10 points for discount',
                                                style: TextStyle(fontSize: 11),
                                              );
                                            }

                                            return Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: availableTiers.entries.map((
                                                entry,
                                              ) {
                                                final points = entry.key;
                                                final percentage = entry.value;
                                                final discountAmt =
                                                    receipt.total *
                                                    (percentage / 100);
                                                final isBestDeal = points == 20;

                                                return Text(
                                                  '• $points points: $percentage% off (Save ₱${discountAmt.toStringAsFixed(2)})${isBestDeal ? ' ⭐ Best' : ''}',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    color: colorScheme.primary,
                                                  ),
                                                );
                                              }).toList(),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                    Consumer<BookingStateNotifier>(
                                      builder: (context, bookingState, _) {
                                        final availableTiers = bookingState
                                            .getAvailableLoyaltyTiers();
                                        if (availableTiers.isEmpty) {
                                          return const SizedBox.shrink();
                                        }

                                        return GestureDetector(
                                          onTap: () {
                                            bookingState
                                                .toggleLoyaltyDiscount();
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 8,
                                            ),
                                            decoration: BoxDecoration(
                                              color:
                                                  bookingState
                                                      .loyaltyToggleEnabled
                                                  ? colorScheme.primary
                                                  : colorScheme.surface,
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                              border: Border.all(
                                                color: colorScheme.primary,
                                                width: 1.5,
                                              ),
                                            ),
                                            child: Text(
                                              bookingState.loyaltyToggleEnabled
                                                  ? '✓ Apply'
                                                  : 'Apply',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color:
                                                    bookingState
                                                        .loyaltyToggleEnabled
                                                    ? colorScheme.onPrimary
                                                    : colorScheme.primary,
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                                // Show applied discount
                                Consumer<BookingStateNotifier>(
                                  builder: (context, bookingState, _) {
                                    if (!bookingState.loyaltyToggleEnabled ||
                                        bookingState.loyaltyPointsUsed == 0) {
                                      return const SizedBox.shrink();
                                    }
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Text(
                                        '✅ ${bookingState.loyaltyPointsUsed} points applied: ${bookingState.loyaltyDiscountPercentage}% off',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.green[700],
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 12),
                        const Divider(),
                        const SizedBox(height: 12),

                        // Total (with loyalty discount if applied)
                        Consumer<BookingStateNotifier>(
                          builder: (context, bookingState, _) {
                            final finalTotal = bookingState
                                .getFinalTotalWithLoyalty();
                            return Column(
                              children: [
                                if (bookingState.loyaltyToggleEnabled &&
                                    bookingState.loyaltyPointsUsed > 0) ...[
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('Subtotal:'),
                                      Text(
                                        '₱${receipt.total.toStringAsFixed(2)}',
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Loyalty Discount (${bookingState.loyaltyDiscountPercentage}%):',
                                        style: TextStyle(
                                          color: Colors.green[700],
                                        ),
                                      ),
                                      Text(
                                        '-₱${bookingState.loyaltyDiscountAmount.toStringAsFixed(2)}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green[700],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  const Divider(),
                                  const SizedBox(height: 8),
                                ],
                                // Final Total
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'TOTAL:',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      '₱${finalTotal.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: colorScheme.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Handling & Delivery Details
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'HANDLING & DELIVERY',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const Divider(),
                        const SizedBox(height: 12),

                        // Pickup
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on,
                                  size: 16,
                                  color: colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Pickup:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Padding(
                              padding: const EdgeInsets.only(left: 24),
                              child: Consumer<BookingStateNotifier>(
                                builder: (context, bookingState, _) {
                                  return Text(
                                    bookingState.handling.pickupAddress.isEmpty
                                        ? '(Not specified)'
                                        : bookingState.handling.pickupAddress,
                                    style: const TextStyle(fontSize: 12),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Delivery
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.local_shipping,
                                  size: 16,
                                  color: colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Delivery:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Padding(
                              padding: const EdgeInsets.only(left: 24),
                              child: Consumer<BookingStateNotifier>(
                                builder: (context, bookingState, _) {
                                  if (!bookingState.handling.deliver) {
                                    return const Text(
                                      'Not included in this order',
                                      style: TextStyle(fontSize: 12),
                                    );
                                  }
                                  return Text(
                                    bookingState
                                            .handling
                                            .deliveryAddress
                                            .isEmpty
                                        ? '(Not specified)'
                                        : bookingState.handling.deliveryAddress,
                                    style: const TextStyle(fontSize: 12),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // GCash Payment Section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'GCash Payment',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onPrimaryContainer,
                            ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Please complete the following steps:',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildStepItem(
                              '1',
                              'Open your GCash app',
                              colorScheme,
                            ),
                            const SizedBox(height: 12),
                            Consumer<BookingStateNotifier>(
                              builder: (context, bookingState, _) {
                                final finalAmount = bookingState
                                    .getFinalTotalWithLoyalty();
                                return _buildStepItem(
                                  '2',
                                  'Send ₱${finalAmount.toStringAsFixed(2)} to the store',
                                  colorScheme,
                                );
                              },
                            ),
                            const SizedBox(height: 12),
                            _buildStepItem(
                              '3',
                              'Take a screenshot of the confirmation',
                              colorScheme,
                            ),
                            const SizedBox(height: 12),
                            _buildStepItem(
                              '4',
                              'Upload the screenshot of the confirmation',
                              colorScheme,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Upload receipt section
                      Consumer<BookingStateNotifier>(
                        builder: (context, bookingState, _) {
                          final hasReceipt =
                              bookingState.gcashReceiptUrl != null;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (_uploadError != null)
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  margin: const EdgeInsets.only(bottom: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.red[50],
                                    border: Border.all(color: Colors.red[300]!),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    _uploadError!,
                                    style: TextStyle(
                                      color: Colors.red[700],
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              if (hasReceipt)
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  margin: const EdgeInsets.only(bottom: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.green[50],
                                    border: Border.all(
                                      color: Colors.green[300]!,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.check_circle,
                                        color: Colors.green[700],
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          'Receipt uploaded successfully ✓',
                                          style: TextStyle(
                                            color: Colors.green[700],
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ElevatedButton.icon(
                                onPressed: _isUploading
                                    ? null
                                    : () => _pickAndUploadImage(context),
                                icon: _isUploading
                                    ? SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation(
                                            Colors.white,
                                          ),
                                        ),
                                      )
                                    : const Icon(Icons.upload_file),
                                label: Text(
                                  _isUploading
                                      ? 'Uploading...'
                                      : (hasReceipt
                                            ? 'Change Receipt'
                                            : 'Upload Receipt'),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: hasReceipt
                                      ? Colors.green.shade600
                                      : colorScheme.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                    horizontal: 16,
                                  ),
                                  elevation: hasReceipt ? 4 : 2,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Info message
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    border: Border.all(color: Colors.blue[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info, color: Colors.blue[700], size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Upload your GCash receipt and review your order. Then click Submit in the flow screen to complete.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.blue[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStepItem(String number, String text, ColorScheme colorScheme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: colorScheme.primary,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: colorScheme.onPrimary,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
      ],
    );
  }
}
