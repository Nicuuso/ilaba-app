import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ilaba/providers/booking_state_provider.dart';
import 'package:ilaba/providers/auth_provider.dart';
import 'package:ilaba/models/pos_types.dart';
import 'package:ilaba/screens/booking_handling_screen.dart';
import 'package:ilaba/screens/booking_products_screen.dart';
import 'package:ilaba/screens/booking_baskets_screen.dart';
import 'package:ilaba/screens/booking_receipt_payment_screen.dart';

/// Main booking flow screen
class BookingFlowScreen extends StatefulWidget {
  const BookingFlowScreen({Key? key}) : super(key: key);

  @override
  State<BookingFlowScreen> createState() => _BookingFlowScreenState();
}

class _BookingFlowScreenState extends State<BookingFlowScreen> {
  @override
  void initState() {
    super.initState();
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
  Widget build(BuildContext context) {
    return Consumer<BookingStateNotifier>(
      builder: (context, state, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Order Booking'),
            elevation: 2,
          ),
          body: Column(
            children: [
              // Tab/Step indicator
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 12,
                ),
                color: Colors.grey[100],
                child: SizedBox(
                  height: 50,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _buildStepButton(
                        context,
                        'Handling',
                        BookingPane.handling,
                        state.handling.pickup || state.handling.deliver,
                      ),
                      _buildStepButton(
                        context,
                        'Products',
                        BookingPane.products,
                        state.orderProductCounts.isNotEmpty,
                      ),
                      _buildStepButton(
                        context,
                        'Baskets',
                        BookingPane.basket,
                        state.baskets.isNotEmpty &&
                            state.baskets.any((b) => b.washCount > 0 || b.dryCount > 0 || b.iron || b.fold),
                      ),
                      _buildStepButton(
                        context,
                        'Receipt',
                        BookingPane.receipt,
                        state.baskets.isNotEmpty &&
                            state.baskets.any((b) => b.washCount > 0 || b.dryCount > 0 || b.iron || b.fold),
                      ),
                    ],
                  ),
                ),
              ),
              // Main content
              Expanded(
                child: IndexedStack(
                  index: _paneIndex(state.activePane),
                  children: [
                    const BookingHandlingScreen(),
                    const BookingProductsScreen(),
                    const BookingBasketsScreen(),
                    const BookingReceiptPaymentScreen(),
                    const BookingReceiptPaymentScreen(),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStepButton(
    BuildContext context,
    String label,
    BookingPane pane,
    bool isCompleted,
  ) {
    return Consumer<BookingStateNotifier>(
      builder: (context, state, _) {
        final isActive = state.activePane == pane;

        return Padding(
          padding: const EdgeInsets.only(right: 4),
          child: ElevatedButton(
            onPressed: () => context.read<BookingStateNotifier>().setActivePane(pane),
            style: ElevatedButton.styleFrom(
              backgroundColor: isActive ? Colors.blue : Colors.grey[300],
            ),
            child: Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
    );
  }

  int _paneIndex(BookingPane pane) {
    switch (pane) {
      case BookingPane.handling:
        return 0;
      case BookingPane.products:
        return 1;
      case BookingPane.basket:
        return 2;
      case BookingPane.receipt:
        return 4;
      default:
        return 0;
    }
  }
}
