import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ilaba/providers/auth_provider.dart';
import 'package:ilaba/screens/booking_flow_screen.dart';
import 'package:ilaba/screens/faq_screen.dart';
import 'package:ilaba/screens/loyalty_screen.dart';
import 'package:ilaba/screens/menu_side_screen.dart';
import 'package:ilaba/screens/orders_screen.dart';
import 'package:ilaba/widgets/menu_card.dart';

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
            title: const Text('iLABa Home'),
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications),
                onPressed: () {
                  // TODO: Open Notifications
                },
              ),
            ],
          ),

          drawer: const MenuSideScreen(),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Container(
                  height: 180,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    image: const DecorationImage(
                      image: AssetImage('assets/images/banner.jpg'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Menu Cards
                Expanded(
                  child: ListView(
                    children: [
                      MenuCard(
                        title: "Book a Service",
                        description:
                            "Schedule your laundry pick-up and delivery.",
                        icon: Icons.shopping_bag,
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const BookingFlowScreen(),
                            ),
                          );
                        },
                      ),
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
                      MenuCard(
                        title: "Loyalty Card Program",
                        description: "Check your points and rewards.",
                        icon: Icons.card_membership,
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const LoyaltyProgramScreen(),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 20),

                      // FAQ & Help Center button
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color.fromARGB(255, 253, 132, 174),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            elevation: 0,
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
              ],
            ),
          ),
        );
      },
    );
  }
}
