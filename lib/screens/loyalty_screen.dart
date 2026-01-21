import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ilaba/providers/loyalty_provider.dart';
import 'package:ilaba/providers/auth_provider.dart';

class LoyaltyProgramScreen extends StatefulWidget {
  const LoyaltyProgramScreen({super.key});

  @override
  State<LoyaltyProgramScreen> createState() => _LoyaltyProgramScreenState();
}

class _LoyaltyProgramScreenState extends State<LoyaltyProgramScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch fresh loyalty data when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final authProvider = context.read<AuthProvider>();
      final loyaltyProvider = context.read<LoyaltyProvider>();
      final user = authProvider.currentUser;

      if (user != null) {
        debugPrint('🎁 LoyaltyProgramScreen OPENED - Fetching fresh loyalty data');
        await loyaltyProvider.fetchLoyaltyCard(user.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LoyaltyProvider>(
      builder: (context, loyaltyProvider, _) {
        final currentPoints = loyaltyProvider.pointsBalance;
        final isLoading = loyaltyProvider.isLoading;

        return Scaffold(
          appBar: AppBar(
            title: const Text("Loyalty Program"),
            backgroundColor: Color.fromARGB(255, 253, 132, 174),
            elevation: 0,
          ),
          body: isLoading
              ? const Center(
                  child: CircularProgressIndicator(),
                )
              : Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        "Earn Discounts as You Book!",
                        style: TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),

                      // Current Points Card
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Color.fromARGB(255, 253, 132, 174),
                              Color.fromARGB(255, 230, 100, 150),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Color.fromARGB(255, 253, 132, 174)
                                  .withOpacity(0.3),
                              offset: const Offset(4, 4),
                              blurRadius: 12,
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            const Text(
                              "Your Loyalty Points",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white70,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "$currentPoints",
                              style: const TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              loyaltyProvider.tierLevel.toUpperCase(),
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),

                      const Text(
                        "Available Benefits",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),

                      // Rewards
                      Expanded(
                        child: ListView(
                          children: [
                            _rewardCard(
                              label: "10 Points",
                              discount: "10% Discount",
                              achieved: currentPoints >= 10,
                              progress:
                                  (currentPoints / 10).clamp(0, 1).toDouble(),
                            ),
                            const SizedBox(height: 16),
                            _rewardCard(
                              label: "20 Points",
                              discount: "15% Discount",
                              achieved: currentPoints >= 20,
                              progress:
                                  (currentPoints / 20).clamp(0, 1).toDouble(),
                              isBest: true,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),
                      // Info Section
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.info_outline,
                                    size: 20,
                                    color: Colors.blue.shade700),
                                const SizedBox(width: 8),
                                Text(
                                  "How to Earn Points",
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.blue.shade700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Earn 1 point for every successful order. Use your points at checkout to get instant discounts!",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue.shade600,
                                height: 1.5,
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

  Widget _rewardCard({
    required String label,
    required String discount,
    required bool achieved,
    required double progress,
    bool isBest = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: achieved
            ? LinearGradient(
                colors: [Colors.green.shade400, Colors.green.shade700],
              )
            : LinearGradient(
                colors: [Colors.grey.shade300, Colors.grey.shade400],
              ),
        borderRadius: BorderRadius.circular(16),
        border: isBest && achieved
            ? Border.all(
                color: Colors.yellow.shade600,
                width: 2,
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: achieved ? Colors.green.shade200 : Colors.grey.shade500,
            offset: const Offset(4, 4),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: achieved ? Colors.white : Colors.black87,
                        ),
                      ),
                      if (isBest && achieved)
                        const Padding(
                          padding: EdgeInsets.only(left: 8),
                          child: Text(
                            "⭐ Best",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.yellow,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    discount,
                    style: TextStyle(
                      fontSize: 16,
                      color: achieved ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ],
              ),
              Icon(
                achieved ? Icons.check_circle : Icons.lock,
                size: 40,
                color: achieved ? Colors.white : Colors.black45,
              ),
            ],
          ),
          if (!achieved) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: Colors.black.withOpacity(0.2),
                valueColor: AlwaysStoppedAnimation<Color>(
                  Colors.white.withOpacity(0.6),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
