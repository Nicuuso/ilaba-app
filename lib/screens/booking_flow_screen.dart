import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ilaba/providers/booking_state_provider.dart';
import 'package:ilaba/providers/auth_provider.dart';
import 'package:ilaba/models/pos_types.dart';
import 'package:ilaba/screens/booking_handling_screen.dart';
import 'package:ilaba/screens/booking_products_screen.dart';
import 'package:ilaba/screens/booking_baskets_screen.dart';
import 'package:ilaba/screens/booking_receipt_payment_screen.dart';

/// Main booking flow screen with sequential navigation
class BookingFlowScreen extends StatefulWidget {
  const BookingFlowScreen({Key? key}) : super(key: key);

  @override
  State<BookingFlowScreen> createState() => _BookingFlowScreenState();
}

class _BookingFlowScreenState extends State<BookingFlowScreen> {
  late PageController _pageController;
  int _currentPage = 0;

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

    // Initialize with current user's information
    WidgetsBinding.instance.addPostFrameCallback((_) {
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

  bool _canGoNext() {
    final state = context.read<BookingStateNotifier>();
    switch (_pages[_currentPage]) {
      case BookingPane.handling:
        return state.handling.pickup || state.handling.deliver;
      case BookingPane.basket:
        return state.baskets.isNotEmpty &&
            state.baskets.any(
              (b) =>
                  b.washCount > 0 ||
                  b.dryCount > 0 ||
                  b.iron ||
                  b.fold,
            );
      case BookingPane.products:
        return state.orderProductCounts.isNotEmpty;
      case BookingPane.receipt:
        return true;
      default:
        return false;
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
                  border: Border(
                    top: BorderSide(color: Colors.grey[300]!),
                  ),
                ),
                child: Row(
                  children: [
                    // Previous button
                    Expanded(
                      child: OutlinedButton(
                        onPressed:
                            _currentPage > 0 ? _goToPreviousPage : null,
                        style: OutlinedButton.styleFrom(
                          padding:
                              const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Previous'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Next button
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _currentPage < _pages.length - 1
                            ? _canGoNext()
                                ? _goToNextPage
                                : null
                            : null,
                        style: ElevatedButton.styleFrom(
                          padding:
                              const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(
                          _currentPage == _pages.length - 1
                              ? 'Submit'
                              : 'Next',
                        ),
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
}
