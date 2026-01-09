import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ilaba/providers/booking_state_provider.dart';
import 'package:ilaba/widgets/custom_text_field.dart';

class BookingHandlingScreen extends StatefulWidget {
  const BookingHandlingScreen({Key? key}) : super(key: key);

  @override
  State<BookingHandlingScreen> createState() => _BookingHandlingScreenState();
}

class _BookingHandlingScreenState extends State<BookingHandlingScreen> {
  late TextEditingController _pickupAddressController;
  late TextEditingController _deliveryAddressController;
  late TextEditingController _instructionsController;

  @override
  void initState() {
    super.initState();
    final state = context.read<BookingStateNotifier>();
    _pickupAddressController = TextEditingController(
      text: state.handling.pickupAddress,
    );
    _deliveryAddressController = TextEditingController(
      text: state.handling.deliveryAddress,
    );
    _instructionsController = TextEditingController(
      text: state.handling.instructions,
    );
  }

  @override
  void dispose() {
    _pickupAddressController.dispose();
    _deliveryAddressController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BookingStateNotifier>(
      builder: (context, state, _) {
        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Pickup & Delivery',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                // Pickup Address
                const Text(
                  'Pickup Address',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                CustomTextField(
                  controller: _pickupAddressController,
                  hintText: 'Enter pickup address',
                  maxLines: 2,
                  onChanged: (value) {
                    context.read<BookingStateNotifier>().setHandling(
                      state.handling.copyWith(pickupAddress: value),
                    );
                  },
                ),
                const SizedBox(height: 16),

                // Delivery Address
                const Text(
                  'Delivery Address',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                CustomTextField(
                  controller: _deliveryAddressController,
                  hintText: 'Enter delivery address',
                  maxLines: 2,
                  onChanged: (value) {
                    context.read<BookingStateNotifier>().setHandling(
                      state.handling.copyWith(deliveryAddress: value),
                    );
                  },
                ),

                // Special Instructions (always visible)
                const Text(
                  'Special Instructions',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                CustomTextField(
                  controller: _instructionsController,
                  hintText: 'Special Instructions (Optional)',
                  maxLines: 3,
                  onChanged: (value) {
                    context.read<BookingStateNotifier>().setHandling(
                      state.handling.copyWith(instructions: value),
                    );
                  },
                ),

                const SizedBox(height: 16),

                // Handling Summary
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Summary:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (state.handling.pickupAddress.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.storefront,
                                size: 18,
                                color: Colors.green,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Pickup',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      state.handling.pickupAddress,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (state.handling.deliveryAddress.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.local_shipping,
                                    size: 18,
                                    color: Colors.green,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Delivery',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              Padding(
                                padding: const EdgeInsets.only(left: 26),
                                child: Text(
                                  state.handling.deliveryAddress,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(
                                  left: 26,
                                  top: 4,
                                ),
                                child: Text(
                                  'Handling Fee: ₱${state.handling.deliveryFee.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (state.handling.instructions.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Instructions: ${state.handling.instructions}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
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
