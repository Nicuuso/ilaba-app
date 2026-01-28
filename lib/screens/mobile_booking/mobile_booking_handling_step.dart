/// Step 3: Handling & Schedule
/// Choose pickup or delivery option
/// Select date and time for handling
/// Pickup and delivery addresses pre-loaded from profile

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ilaba/providers/mobile_booking_provider.dart';
import 'package:ilaba/screens/mobile_booking/order_summary_expandable.dart';
import 'package:ilaba/constants/ilaba_colors.dart';

class MobileBookingHandlingStep extends StatefulWidget {
  const MobileBookingHandlingStep({Key? key}) : super(key: key);

  @override
  State<MobileBookingHandlingStep> createState() => _MobileBookingHandlingStepState();
}

class _MobileBookingHandlingStepState extends State<MobileBookingHandlingStep> {
  late TextEditingController _pickupAddressController;
  late TextEditingController _deliveryAddressController;
  bool _sameDaySelected = true;

  @override
  void initState() {
    super.initState();
    final provider = context.read<MobileBookingProvider>();
    _pickupAddressController = TextEditingController(text: provider.pickupAddress);
    _deliveryAddressController = TextEditingController(text: provider.deliveryAddress);
  }

  @override
  void dispose() {
    _pickupAddressController.dispose();
    _deliveryAddressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MobileBookingProvider>(
      builder: (context, provider, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // HIDDEN: Delivery Date Selection
              // _buildDeliveryDateSelection(context, provider),
              // const SizedBox(height: 16),

              // Pickup Address
              _buildPickupAddressDisplay(context, provider),
              const SizedBox(height: 16),

              // Delivery Address
              _buildDeliveryAddressDisplay(context, provider),
              const SizedBox(height: 16),

              // Delivery Reminder
              _buildDeliveryReminder(context, provider),
              const SizedBox(height: 16),

              // Summary
              _buildOrderSummary(context, provider),
            ],
          ),
        );
      },
    );
  }



  /// Build pickup address input
  Widget _buildPickupAddressDisplay(
    BuildContext context,
    MobileBookingProvider provider,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Pickup Address',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        const Text(
          'Where we will pick up your laundry',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 10),
        TextField(
          maxLines: 3,
          controller: _pickupAddressController,
          decoration: InputDecoration(
            hintText: 'Enter your pickup address',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            prefixIcon: const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Icon(Icons.location_on, color: ILabaColors.burgundy),
            ),
            contentPadding: const EdgeInsets.all(12),
          ),
          onChanged: (value) => provider.setPickupAddress(value),
        ),
      ],
    );
  }

  /// Build delivery address input
  Widget _buildDeliveryAddressDisplay(
    BuildContext context,
    MobileBookingProvider provider,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Delivery Address',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        const Text(
          'Where we will deliver your laundry',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 10),
        TextField(
          maxLines: 3,
          controller: _deliveryAddressController,
          decoration: InputDecoration(
            hintText: 'Enter your delivery address',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            prefixIcon: const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Icon(Icons.local_shipping_outlined, color: ILabaColors.burgundy),
            ),
            contentPadding: const EdgeInsets.all(12),
          ),
          onChanged: (value) => provider.setDeliveryAddress(value),
        ),
      ],
    );
  }

  /// Build delivery date selection
  Widget _buildDeliveryDateSelection(
    BuildContext context,
    MobileBookingProvider provider,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Delivery Date',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildDeliveryDateOption(
                context,
                provider,
                label: 'Same Day',
                description: 'Available time slots today',
                isSelected: _sameDaySelected,
                isSameDay: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildDeliveryDateOption(
                context,
                provider,
                label: 'Pick Date',
                description: 'Choose future date',
                isSelected: !_sameDaySelected,
                isSameDay: false,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Build delivery date option
  Widget _buildDeliveryDateOption(
    BuildContext context,
    MobileBookingProvider provider, {
    required String label,
    required String description,
    required bool isSelected,
    required bool isSameDay,
  }) {
    return GestureDetector(
      onTap: () {
        if (isSameDay) {
          // Same Day button
          setState(() {
            _sameDaySelected = true;
          });
        } else {
          // Pick Date button
          setState(() {
            _sameDaySelected = false;
          });
          _showDatePicker(context);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [ILabaColors.burgundy, ILabaColors.burgundyDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : LinearGradient(
                  colors: [ILabaColors.white, ILabaColors.lightGray],
                ),
          border: Border.all(
            color: isSelected
                ? ILabaColors.burgundy.withOpacity(0.2)
                : ILabaColors.lightGray,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(6),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: ILabaColors.burgundy.withOpacity(0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
        ),
        child: Column(
          children: [
            Icon(
              isSelected ? Icons.calendar_today : Icons.calendar_month,
              size: 32,
              color: isSelected ? ILabaColors.white : Colors.grey,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected ? ILabaColors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: isSelected ? ILabaColors.white.withOpacity(0.9) : ILabaColors.lightText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDatePicker(BuildContext context) async {
    final selected = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now().add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (selected != null) {
      debugPrint('📅 Selected delivery date: $selected');
    }
  }

  /// Build delivery reminder box
  Widget _buildDeliveryReminder(
    BuildContext context,
    MobileBookingProvider provider,
  ) {
    return GestureDetector(
      onTap: () {
        provider.setDeliveryReminderAcknowledged(!provider.deliveryReminderAcknowledged);
      },
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.orange.shade300),
              borderRadius: BorderRadius.circular(8),
              color: Colors.orange.shade50,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange.shade700, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'Delivery Reminder',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Delivery attempt will be between 11am - 3pm. Please check your notifications for updates.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.orange.shade900),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Checkbox(
                      value: provider.deliveryReminderAcknowledged,
                      onChanged: (value) => provider.setDeliveryReminderAcknowledged(value ?? false),
                      activeColor: Colors.orange.shade700,
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'I understand',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Build order summary
  Widget _buildOrderSummary(
    BuildContext context,
    MobileBookingProvider provider,
  ) {
    return OrderSummaryExpandable(
      provider: provider,
      showProductBreakdown: true,
      showDeliveryFee: true,
    );
  }
}
