import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:ilaba/providers/booking_state_provider.dart';
import 'package:ilaba/providers/auth_provider.dart';
import 'package:ilaba/providers/loyalty_provider.dart';
import 'package:ilaba/models/pos_types.dart';
import 'package:ilaba/models/order_models.dart';
import 'package:ilaba/screens/booking_handling_screen.dart';
import 'package:ilaba/screens/booking_products_screen.dart';
import 'package:ilaba/screens/booking_baskets_screen.dart';
import 'package:ilaba/screens/booking_receipt_payment_screen.dart';
import 'package:ilaba/screens/order_success_screen.dart';
import 'package:ilaba/services/order_creation_service.dart';
import 'dart:convert';

/// Main booking flow screen with sequential navigation
class BookingFlowScreen extends StatefulWidget {
  const BookingFlowScreen({super.key});

  @override
  State<BookingFlowScreen> createState() => _BookingFlowScreenState();
}

class _BookingFlowScreenState extends State<BookingFlowScreen> {
  late PageController _pageController;
  int _currentPage = 0;
  bool _isSubmitting = false;
  Map<String, dynamic>? _lastPayload;

  final List<BookingPane> _pages = [
    BookingPane.handling,
    BookingPane.basket,
    BookingPane.products,
    BookingPane.receipt,
  ];

  final List<String> _pageLabels = [
    'Handling',
    'Baskets',
    'Products',
    'Receipt',
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    // Initialize with current user's information and fetch fresh loyalty points
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final authProvider = context.read<AuthProvider>();
      final bookingProvider = context.read<BookingStateNotifier>();
      final user = authProvider.currentUser;

      if (user != null && bookingProvider.customer == null) {
        final customer = Customer(
          id: user.id,
          firstName: user.firstName,
          lastName: user.lastName,
          phoneNumber: user.phoneNumber,
          emailAddress: user.emailAddress,
          address: user.address,
        );
        bookingProvider.setCustomer(customer);
      }

      // Fresh pull of loyalty points from auth provider every time screen opens
      if (user != null) {
        debugPrint(
          '📱 BookingFlowScreen OPENED - Fetching fresh loyalty points',
        );
        await _refreshLoyaltyPoints(user.id, bookingProvider, authProvider);
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToNextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _goToPreviousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  /// Fetch updated loyalty points from loyalty service
  Future<void> _refreshLoyaltyPoints(
    String customerId,
    BookingStateNotifier bookingProvider,
    AuthProvider authProvider,
  ) async {
    try {
      debugPrint('🎁 PULLING loyalty points from loyalty service');

      final loyaltyProvider = context.read<LoyaltyProvider>();
      await loyaltyProvider.fetchLoyaltyCard(customerId);

      final loyaltyPoints = loyaltyProvider.pointsBalance;
      bookingProvider.setLoyaltyPointsBalance(loyaltyPoints);
      debugPrint('✅ LOYALTY POINTS SET: $loyaltyPoints points');
    } catch (e) {
      debugPrint('❌ ERROR accessing loyalty points: $e');
    }
  }

  bool _canGoNext() {
    final state = context.read<BookingStateNotifier>();
    switch (_pages[_currentPage]) {
      case BookingPane.handling:
        // Both pickup and delivery addresses must be filled
        return state.handling.pickupAddress.isNotEmpty &&
            state.handling.deliveryAddress.isNotEmpty;
      case BookingPane.basket:
        // At least one basket must have weight > 0 AND have services
        if (state.baskets.isEmpty) return false;

        // Check that all baskets with weight have services (no incomplete baskets)
        for (final basket in state.baskets) {
          if (basket.weightKg > 0) {
            final hasService =
                basket.washCount > 0 ||
                basket.dryCount > 0 ||
                basket.spinCount > 0 ||
                basket.iron ||
                basket.fold;
            if (!hasService) return false;
          }
        }

        // Check that at least one basket has weight and services
        final hasValidBasket = state.baskets.any((basket) {
          if (basket.weightKg <= 0) return false;
          return basket.washCount > 0 ||
              basket.dryCount > 0 ||
              basket.spinCount > 0 ||
              basket.iron ||
              basket.fold;
        });
        return hasValidBasket;
      case BookingPane.products:
        // Check if there is at least one valid basket (>0kg with services)
        if (state.baskets.isEmpty) return false;
        final hasValidBasket = state.baskets.any((basket) {
          if (basket.weightKg <= 0) return false;
          return basket.washCount > 0 ||
              basket.dryCount > 0 ||
              basket.spinCount > 0 ||
              basket.iron ||
              basket.fold;
        });
        return hasValidBasket;
      case BookingPane.receipt:
        return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BookingStateNotifier>(
      builder: (context, state, _) {
        return Scaffold(
          appBar: AppBar(
            title: Text('Order Booking - ${_pageLabels[_currentPage]}'),
            elevation: 2,
          ),
          body: Column(
            children: [
              // Progress indicator
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                color: Colors.grey[100],
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _pages.length,
                    (index) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: CircleAvatar(
                        radius: 16,
                        backgroundColor: index <= _currentPage
                            ? Colors.blue
                            : Colors.grey[300],
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            color: index <= _currentPage
                                ? Colors.white
                                : Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // Page content
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  children: [
                    const BookingHandlingScreen(),
                    const BookingBasketsScreen(),
                    const BookingProductsScreen(),
                    const BookingReceiptPaymentScreen(),
                  ],
                ),
              ),
              // Navigation buttons
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  border: Border(top: BorderSide(color: Colors.grey[300]!)),
                ),
                child: Row(
                  children: [
                    // Previous button
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _currentPage > 0 ? _goToPreviousPage : null,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Previous'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Next/Submit button
                    Expanded(
                      child: Consumer<BookingStateNotifier>(
                        builder: (context, bookingState, _) {
                          bool submitDisabled = false;
                          if (_currentPage == _pages.length - 1) {
                            // On receipt page: disable if no receipt uploaded
                            submitDisabled =
                                bookingState.gcashReceiptUrl == null;
                          }
                          return ElevatedButton(
                            onPressed: _currentPage < _pages.length - 1
                                ? _canGoNext()
                                      ? _goToNextPage
                                      : null
                                : (submitDisabled || _isSubmitting
                                      ? null
                                      : _submitOrder),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child:
                                _isSubmitting &&
                                    _currentPage == _pages.length - 1
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : Text(
                                    _currentPage == _pages.length - 1
                                        ? 'Submit'
                                        : 'Next',
                                  ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _submitOrder() async {
    setState(() {
      _isSubmitting = true;
    });

    String currentStep = 'Initialization';
    try {
      currentStep = 'Reading booking state';
      final bookingState = context.read<BookingStateNotifier>();
      final authState = context.read<AuthProvider>();

      if (authState.currentUser == null) {
        throw Exception('User not authenticated');
      }

      currentStep = 'Validating user';
      final user = authState.currentUser!;

      debugPrint('👤 Current User Debug:');
      debugPrint('   User ID: ${user.id}');
      debugPrint('   User ID is empty: ${user.id.isEmpty}');
      debugPrint('   User First Name: ${user.firstName}');
      debugPrint('   User Phone: ${user.phoneNumber}');

      if (user.id.isEmpty) {
        throw Exception('Customer ID is missing. Please log in again.');
      }

      currentStep = 'Computing receipt';
      final receipt = bookingState.computeReceipt();
      debugPrint('✓ Receipt computed: Total = ${receipt.total}');

      // Build baskets payload for backend
      currentStep = 'Building baskets';
      final baskets = <BackendBasketPayload>[];
      for (final basket in bookingState.baskets) {
        if (basket.weightKg <= 0) continue; // Skip empty baskets

        final services = <BackendServicePayload>[];
        double basketTotal = 0;

        // Wash
        if (basket.washCount > 0) {
          final service = bookingState.getServiceByType(
            'wash',
            basket.washPremium,
          );
          if (service != null) {
            final subtotal =
                basket.weightKg * service.ratePerKg * basket.washCount;
            services.add(
              BackendServicePayload(
                serviceId: service.id,
                serviceName: service.name,
                rate: service.ratePerKg,
                subtotal: subtotal,
              ),
            );
            basketTotal += subtotal;
          }
        }

        // Dry
        if (basket.dryCount > 0) {
          final service = bookingState.getServiceByType(
            'dry',
            basket.dryPremium,
          );
          if (service != null) {
            final subtotal =
                basket.weightKg * service.ratePerKg * basket.dryCount;
            services.add(
              BackendServicePayload(
                serviceId: service.id,
                serviceName: service.name,
                rate: service.ratePerKg,
                subtotal: subtotal,
              ),
            );
            basketTotal += subtotal;
          }
        }

        // Spin
        if (basket.spinCount > 0) {
          final service = bookingState.getServiceByType('spin', false);
          if (service != null) {
            final subtotal =
                basket.weightKg * service.ratePerKg * basket.spinCount;
            services.add(
              BackendServicePayload(
                serviceId: service.id,
                serviceName: service.name,
                rate: service.ratePerKg,
                subtotal: subtotal,
              ),
            );
            basketTotal += subtotal;
          }
        }

        // Iron
        if (basket.iron) {
          final service = bookingState.getServiceByType('iron', false);
          if (service != null) {
            final subtotal = basket.weightKg * service.ratePerKg;
            services.add(
              BackendServicePayload(
                serviceId: service.id,
                serviceName: service.name,
                rate: service.ratePerKg,
                subtotal: subtotal,
              ),
            );
            basketTotal += subtotal;
          }
        }

        // Fold
        if (basket.fold) {
          final service = bookingState.getServiceByType('fold', false);
          if (service != null) {
            final subtotal = basket.weightKg * service.ratePerKg;
            services.add(
              BackendServicePayload(
                serviceId: service.id,
                serviceName: service.name,
                rate: service.ratePerKg,
                subtotal: subtotal,
              ),
            );
            basketTotal += subtotal;
          }
        }

        if (services.isNotEmpty) {
          baskets.add(
            BackendBasketPayload(
              weight: basket.weightKg,
              subtotal: basketTotal,
              services: services,
              notes: basket.notes.isNotEmpty ? basket.notes : null,
            ),
          );
        }
      }
      debugPrint('✓ Baskets built: ${baskets.length} baskets');

      // Build products payload for backend
      currentStep = 'Building products';
      final products = <BackendProductPayload>[];
      for (final entry in bookingState.orderProductCounts.entries) {
        final product = bookingState.products.firstWhere(
          (p) => p.id == entry.key,
        );
        final subtotal = product.unitPrice * entry.value;
        debugPrint(
          '📦 Product: id=${product.id}, name="${product.itemName}", price=${product.unitPrice}',
        );
        products.add(
          BackendProductPayload(
            productId: product.id,
            productName: product.itemName.isNotEmpty
                ? product.itemName
                : 'Product ${product.id}',
            quantity: entry.value,
            unitPrice: product.unitPrice,
            subtotal: subtotal,
          ),
        );
      }
      debugPrint('✓ Products built: ${products.length} products');

      // Create order payload for backend API
      currentStep = 'Creating order payload';
      debugPrint(
        '🎁 Loyalty state - Points: ${bookingState.loyaltyPointsUsed}, Discount %: ${bookingState.loyaltyDiscountPercentage}, Amount: ₱${bookingState.loyaltyDiscountAmount.toStringAsFixed(2)}',
      );

      final finalTotal = bookingState.loyaltyPointsUsed > 0
          ? receipt.total - bookingState.loyaltyDiscountAmount
          : receipt.total;
      debugPrint(
        '💰 Original total: ₱${receipt.total.toStringAsFixed(2)}, Final total: ₱${finalTotal.toStringAsFixed(2)}',
      );

      final orderPayload = CreateOrderPayload(
        customerId: user.id,
        total: receipt.total,
        baskets: baskets,
        products: products,
        pickupAddress: bookingState.handling.pickupAddress,
        deliveryAddress: bookingState.handling.deliveryAddress,
        shippingFee: bookingState.handling.deliver ? 50.0 : 0.0,
        source: 'app',
        gcashReceiptUrl: bookingState.gcashReceiptUrl,
        loyaltyPointsUsed: bookingState.loyaltyPointsUsed,
        loyaltyDiscountAmount: bookingState.loyaltyDiscountAmount,
        loyaltyDiscountPercentage: bookingState.loyaltyDiscountPercentage,
      );
      debugPrint('✓ Order payload created');

      // Create request with customer data
      currentStep = 'Creating order request';
      final request = CreateOrderRequest(
        customer: CustomerData(
          id: user.id,
          phoneNumber: user.phoneNumber,
          emailAddress: user.emailAddress,
        ),
        orderPayload: orderPayload,
      );
      debugPrint('✓ Order request created');

      debugPrint('👤 Customer ID being sent: ${user.id}');
      debugPrint('📊 Full Payload: ${request.toJson()}');

      _lastPayload = request.toJson();

      // Submit order
      currentStep = 'Submitting order to API';
      final orderService = OrderCreationServiceImpl();
      final response = await orderService.createOrder(
        request,
        phoneNumber: user.phoneNumber,
        emailAddress: user.emailAddress,
      );
      debugPrint('✓ Order submitted successfully');

      if (!mounted) return;

      if (response.success) {
        currentStep = 'Resetting booking state';
        // Reset booking state
        bookingState.resetForNewOrder();

        currentStep = 'Refreshing loyalty points';
        // Refresh loyalty points after successful order
        try {
          final loyaltyProvider = context.read<LoyaltyProvider>();
          await loyaltyProvider.refreshLoyaltyCard(user.id);
          debugPrint('✓ Loyalty points refreshed after order');
        } catch (e) {
          debugPrint('⚠️ Could not refresh loyalty points: $e');
        }

        currentStep = 'Navigating to success screen';
        // Navigate to success screen
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => OrderSuccessScreen(
              orderId: response.orderId,

              totalAmount: receipt.total,
              customerName: '${user.firstName} ${user.lastName}',
              customerEmail: user.emailAddress,
            ),
          ),
        );
      } else {
        _showErrorDialog(
          response.error ?? 'Failed to create order',
          response.insufficientItems,
          response: response,
          payload: _lastPayload,
          failedStep: currentStep,
        );
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog(
          e.toString().replaceAll('Exception: ', ''),
          null,
          errorException: e.toString(),
          payload: _lastPayload,
          failedStep: currentStep,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _showErrorDialog(
    String message,
    List<Map<String, dynamic>>? insufficientItems, {
    CreateOrderResponse? response,
    String? errorException,
    Map<String, dynamic>? payload,
    String? failedStep,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('❌ Order Submission Failed'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Main error message
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  border: Border.all(color: Colors.red.shade200),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  message,
                  style: TextStyle(
                    color: Colors.red.shade900,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              // Failed Step section
              if (failedStep != null) ...[
                const SizedBox(height: 16),
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
                      const Text(
                        '⚠️ Failed At:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: Colors.amber,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        failedStep,
                        style: TextStyle(
                          fontSize: 11,
                          fontFamily: 'monospace',
                          color: Colors.amber.shade900,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Insufficient items section
              if (insufficientItems != null &&
                  insufficientItems.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  '📦 Unavailable Items:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                ...insufficientItems.map((item) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• '),
                        Expanded(
                          child: Text(
                            '${item['productName']}\nRequested: ${item['requested']}, Available: ${item['available']}',
                            style: const TextStyle(fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],

              // Debug section
              const SizedBox(height: 16),
              ExpansionTile(
                title: const Text(
                  '🔧 Debug Information',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Error Type
                        _buildErrorTypeIndicator(
                          response: response,
                          errorException: errorException,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Error: $message',
                          style: const TextStyle(
                            fontSize: 10,
                            fontFamily: 'monospace',
                          ),
                        ),
                        if (errorException != null) ...[
                          const SizedBox(height: 8),
                          const Text(
                            'Exception:',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            errorException,
                            style: const TextStyle(
                              fontSize: 9,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                        if (response != null) ...[
                          const SizedBox(height: 8),
                          const Text(
                            'Response:',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Success: ${response.success}\nOrder ID: ${response.orderId.isEmpty ? 'N/A' : response.orderId}',
                            style: const TextStyle(
                              fontSize: 9,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                        if (payload != null) ...[
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Payload Sent:',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                onPressed: () {
                                  final jsonString = jsonEncode(payload);
                                  Clipboard.setData(
                                    ClipboardData(text: jsonString),
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Text(
                                        '✅ Payload copied to clipboard',
                                      ),
                                      backgroundColor: Colors.green.shade700,
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.copy, size: 16),
                                tooltip: 'Copy payload JSON',
                                constraints: const BoxConstraints(
                                  minWidth: 30,
                                  minHeight: 30,
                                ),
                                padding: EdgeInsets.zero,
                              ),
                            ],
                          ),
                          Text(
                            'customer_id: ${payload['customer_id']}\ntotal: ${payload['total']}\nbaskets: ${payload['baskets']?.length ?? 0}\nproducts: ${payload['products']?.length ?? 0}',
                            style: const TextStyle(
                              fontSize: 9,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorTypeIndicator({
    required CreateOrderResponse? response,
    required String? errorException,
  }) {
    // Determine error type
    String errorType = 'Unknown';
    Color bgColor = Colors.grey.shade200;
    Color textColor = Colors.grey.shade900;

    if (response != null && !response.success) {
      // API Error - we got a response from the server
      errorType = '🌐 API Error';
      bgColor = Colors.orange.shade100;
      textColor = Colors.orange.shade900;
    } else if (errorException != null &&
        (errorException.contains('SocketException') ||
            errorException.contains('timeout') ||
            errorException.contains('Connection') ||
            errorException.contains('Failed host lookup'))) {
      // Network Error
      errorType = '📡 Network Error';
      bgColor = Colors.red.shade100;
      textColor = Colors.red.shade900;
    } else if (errorException != null) {
      // Client/App Error
      errorType = '⚙️ App Error';
      bgColor = Colors.blue.shade100;
      textColor = Colors.blue.shade900;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        errorType,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }
}
