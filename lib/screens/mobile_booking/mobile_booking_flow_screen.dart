/// Mobile Booking Flow Screen
/// Main orchestrator for 4-step booking flow with PageView
///
/// Navigation:
/// Step 1 → Step 2 → Step 3 → Step 4 → Success Screen

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ilaba/providers/mobile_booking_provider.dart';
import 'package:ilaba/screens/mobile_booking/mobile_booking_baskets_step.dart';
import 'package:ilaba/screens/mobile_booking/mobile_booking_products_step.dart';
import 'package:ilaba/screens/mobile_booking/mobile_booking_handling_step.dart';
import 'package:ilaba/screens/mobile_booking/mobile_booking_payment_step.dart';
import 'package:ilaba/screens/mobile_booking/mobile_booking_success_screen.dart';
import 'package:ilaba/constants/ilaba_colors.dart';

class MobileBookingFlowScreen extends StatefulWidget {
  const MobileBookingFlowScreen({Key? key}) : super(key: key);

  @override
  State<MobileBookingFlowScreen> createState() =>
      _MobileBookingFlowScreenState();
}

class _MobileBookingFlowScreenState extends State<MobileBookingFlowScreen> {
  late PageController _pageController;
  int _currentStep = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Navigate to next step with validation
  void _goToNextStep(BuildContext context) {
    final provider = context.read<MobileBookingProvider>();

    // For Step 3 (handling/delivery), show detailed validation with snackbar
    if (_currentStep == 2) { // Current step is 2 (0-indexed), going to step 3
      final validationResult = provider.getStep3ValidationDetails();
      if (!validationResult.isValid) {
        // Show snackbar with missing fields list
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Please complete all required fields:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 8),
                ...validationResult.missingFields.map((field) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text('• $field'),
                  );
                }).toList(),
              ],
            ),
            backgroundColor: Colors.red.shade600,
            duration: const Duration(seconds: 5),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
          ),
        );
        return;
      }
    } else {
      // For other steps, use standard validation
      final error = provider.validateCurrentStep(_currentStep + 1);
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: Colors.red),
        );
        return;
      }
    }

    // Move to next step
    if (_currentStep < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  /// Navigate to previous step
  void _goToPreviousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_currentStep > 0) {
          _goToPreviousStep();
          return false;
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Book Laundry Service'),
          elevation: 0,
          backgroundColor: ILabaColors.burgundy,
          foregroundColor: ILabaColors.white,
          centerTitle: true,
        ),
        body: Consumer<MobileBookingProvider>(
          builder: (context, provider, _) {
            if (provider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            return Column(
              children: [
                // Step Indicator
                _buildStepIndicator(),

                // Error Message
                if (provider.errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        border: Border.all(color: Colors.red.shade200),
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error, color: Colors.red.shade700, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              provider.errorMessage!,
                              style: TextStyle(color: Colors.red.shade700, fontSize: 13),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.close, color: Colors.red.shade700, size: 20),
                            onPressed: provider.clearError,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ),
                  ),

                // PageView with Steps
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() {
                        _currentStep = index;
                      });
                    },
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      // Step 1: Baskets
                      const MobileBookingBasketsStep(),

                      // Step 2: Products
                      const MobileBookingProductsStep(),

                      // Step 3: Handling
                      const MobileBookingHandlingStep(),

                      // Step 4: Payment
                      const MobileBookingPaymentStep(),
                    ],
                  ),
                ),

                // Navigation Buttons
                _buildNavigationButtons(context),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Build step indicator (1/2/3/4)
  Widget _buildStepIndicator() {
    return Container(
      color: ILabaColors.lightGray,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (int i = 0; i < 4; i++) ...[
            if (i > 0)
              Expanded(
                child: Container(
                  height: 1.5,
                  color: _currentStep > i
                      ? ILabaColors.burgundy
                      : Colors.grey.shade200,
                ),
              ),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _currentStep >= i ? ILabaColors.burgundy : Colors.grey.shade200,
              ),
              child: Center(
                child: Text(
                  '${i + 1}',
                  style: TextStyle(
                    color: _currentStep >= i ? ILabaColors.white : Colors.grey.shade500,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Build navigation buttons with basket selector (Previous/Next)
  Widget _buildNavigationButtons(BuildContext context) {
    final provider = context.read<MobileBookingProvider>();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [ILabaColors.white, ILabaColors.lightGray],
        ),
        border: Border(
          top: BorderSide(color: ILabaColors.burgundy.withOpacity(0.2), width: 2),
        ),
        boxShadow: [
          BoxShadow(
            color: ILabaColors.burgundy.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Basket selector only on step 1
          if (_currentStep == 0) ...[
            _buildBasketSelector(context, provider),
            const SizedBox(height: 10),
            _buildBasketActions(context, provider),
            const SizedBox(height: 12),
          ],
          // Navigation buttons
          Row(
            children: [
              // Previous Button
              if (_currentStep > 0)
                Expanded(
                  child: OutlinedButton(
                    onPressed: _goToPreviousStep,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(color: ILabaColors.lightGray),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: const Text('Previous', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey)),
                  ),
                ),

              SizedBox(width: _currentStep > 0 ? 12 : 0),

              // Next/Submit Button
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [ILabaColors.burgundy, ILabaColors.burgundyDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [
                      BoxShadow(
                        color: ILabaColors.burgundy.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: provider.isSubmitting
                        ? null
                        : () => _currentStep < 3
                              ? _goToNextStep(context)
                              : _submitOrder(context),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: Colors.transparent,
                      foregroundColor: ILabaColors.white,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: provider.isSubmitting
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(ILabaColors.white),
                            ),
                          )
                        : Text(
                            _currentStep < 3 ? 'Next' : 'Submit Order',
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build basket selector
  Widget _buildBasketSelector(BuildContext context, MobileBookingProvider provider) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (int i = 0; i < provider.baskets.length; i++)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => provider.setActiveBasketIndex(i),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: provider.activeBasketIndex == i
                        ? ILabaColors.burgundy
                        : Colors.grey.shade100,
                    border: Border.all(
                      color: provider.activeBasketIndex == i
                          ? ILabaColors.burgundy
                          : ILabaColors.lightGray,
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Basket ${i + 1}',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                      color: provider.activeBasketIndex == i
                          ? ILabaColors.white
                          : ILabaColors.lightText,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Build basket action buttons
  Widget _buildBasketActions(BuildContext context, MobileBookingProvider provider) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => provider.addBasket(),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add Basket'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 10),
              side: BorderSide(color: ILabaColors.lightGray),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: provider.baskets.length > 1
                ? () => provider.deleteBasket(provider.activeBasketIndex)
                : null,
            icon: const Icon(Icons.delete, size: 18),
            label: const Text('Remove'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 10),
              side: BorderSide(
                color: provider.baskets.length > 1
                    ? Colors.red.shade300
                    : Colors.grey.shade200,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Submit order and navigate to success screen
  Future<void> _submitOrder(BuildContext context) async {
    final provider = context.read<MobileBookingProvider>();

    try {
      final response = await provider.submitOrder(provider.currentUser);

      if (!mounted) return;

      if (response.success && response.orderId != null) {
        // Navigate to success screen
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) =>
                MobileBookingSuccessScreen(response: response),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
