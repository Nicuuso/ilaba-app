import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ilaba/providers/auth_provider.dart';
import 'package:ilaba/screens/info/faq_screen.dart';
import 'package:ilaba/screens/loyalty/loyalty_card_screen.dart';
import 'package:ilaba/screens/navigation/menu_side_screen.dart';
import 'package:ilaba/screens/orders/orders_screen.dart';
import 'package:ilaba/screens/mobile_booking/mobile_booking_flow_screen.dart';
import 'package:ilaba/screens/notifications/notifications_center_screen.dart';
import 'package:ilaba/widgets/menu_card.dart';
import 'package:ilaba/constants/ilaba_colors.dart';

class HomeMenuScreen extends StatelessWidget {
  const HomeMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        // Guard: Redirect to login if not authenticated
        if (!authProvider.isLoggedIn) {
          // Navigate to login and remove home screen from stack
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pushReplacementNamed('/login');
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          appBar: AppBar(
            leading: Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
              ),
            ),
            title: const Text('iLABa'),
            backgroundColor: ILabaColors.white,
            elevation: 1,
            iconTheme: const IconThemeData(color: ILabaColors.burgundy),
            titleTextStyle: const TextStyle(
              color: ILabaColors.darkText,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                color: ILabaColors.burgundy,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NotificationsCenterScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
          drawer: const MenuSideScreen(),
          backgroundColor: ILabaColors.white,
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Modern Laundry Shop Banner
                Container(
                  height: 180,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        ILabaColors.burgundy,
                        ILabaColors.burgundyDark,
                      ],
                    ),
                    boxShadow: ILabaColors.mediumShadow,
                  ),
                  child: Stack(
                    children: [
                      // Decorative circles in background
                      Positioned(
                        top: -40,
                        right: -40,
                        child: Container(
                          width: 150,
                          height: 150,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: ILabaColors.white.withOpacity(0.1),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: -50,
                        left: -50,
                        child: Container(
                          width: 180,
                          height: 180,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: ILabaColors.white.withOpacity(0.08),
                          ),
                        ),
                      ),
                      // Content
                      Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: ILabaColors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.local_laundry_service,
                                    color: ILabaColors.white,
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Welcome to iLABa',
                                        style: TextStyle(
                                          color: ILabaColors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      Text(
                                        'Professional Laundry Services',
                                        style: TextStyle(
                                          color: ILabaColors.white.withOpacity(0.9),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const Text(
                              'Fast • Fresh • Reliable Laundry Service',
                              style: TextStyle(
                                color: ILabaColors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                // Menu Cards
                MenuCard(
                  title: "Book a Service",
                  description: "Schedule your laundry pick-up and delivery.",
                  icon: Icons.shopping_bag,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MobileBookingFlowScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
                MenuCard(
                  title: "Check Order Status",
                  description: "Track your laundry orders and history.",
                  icon: Icons.track_changes,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const OrdersScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
                MenuCard(
                  title: "Loyalty Card",
                  description: "Check your rewards and discounts.",
                  icon: Icons.card_membership,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoyaltyCardScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
                
                // Spacer to push button to bottom
                const Spacer(),

                // FAQ & Help Center button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ILabaColors.burgundy,
                      foregroundColor: ILabaColors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 2,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const FAQScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.help_outline),
                    label: const Text(
                      "FAQ & Help Center",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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
