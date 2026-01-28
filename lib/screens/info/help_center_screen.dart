import 'package:flutter/material.dart';
import 'package:ilaba/constants/ilaba_colors.dart';

class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final historyReports = [
      {
        "issue": "Delayed delivery",
        "status": "Resolved",
        "order": "ORD12345",
        "description": "Delivery was 2 hours late.",
      },
      {
        "issue": "Damaged clothing",
        "status": "Pending",
        "order": "ORD67890",
        "description": "Shirt had noticeable tears after laundry.",
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Help Center"),
        backgroundColor: const Color.fromARGB(255, 253, 132, 174),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Report Form
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: ILabaColors.white,

                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color.fromARGB(255, 253, 132, 174),
                  width: 1.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Report an Issue",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 253, 132, 174),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    decoration: InputDecoration(
                      labelText: "Order Number",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: "Issue",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: "Description (if applicable)",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Contact & Submit Row
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                              color: Color.fromARGB(255, 253, 132, 174),
                            ),
                            foregroundColor: const Color.fromARGB(
                              255,
                              253,
                              132,
                              174,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: () {
                            // TODO: call or open dialer
                          },
                          icon: const Icon(Icons.phone),
                          label: const Text("+09123456789"),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color.fromARGB(
                              255,
                              253,
                              132,
                              174,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: () {
                            // TODO: submit report logic
                          },
                          child: const Text(
                            "Submit Report",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // History Section
            const Text(
              "History",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 253, 132, 174),
              ),
            ),
            const SizedBox(height: 12),

            ...historyReports.map((report) {
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
                child: ExpansionTile(
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        report["issue"]!,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        report["status"]!,
                        style: TextStyle(
                          color: report["status"] == "Resolved"
                              ? Colors.green
                              : Colors.orange,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  children: [
                    ListTile(
                      title: const Text("Report Details"),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Order Number: ${report["order"]}"),
                          const SizedBox(height: 4),
                          Text("Description: ${report["description"]}"),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
