import 'package:flutter/material.dart';
import 'package:ilaba/constants/ilaba_colors.dart';

class FAQScreen extends StatelessWidget {
  const FAQScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final faqs = [
      {
        "question": "Why isn't Cash on Delivery available as a payment option?",
        "answer": "To avoid fraudulent and \"No Show\" customers, we require orders that are outside of the Bagumbong Area to pay through GCash",
      },
      {
        "question": "How is the delivery fee calculated?",
        "answer": "For deliveries within Bagumbong and nearby areas, we charge a base fee of ₱50. For locations outside this coverage, we add ₱50 for every additional kilometer.",
      },
      {
        "question": "What are your operating hours?",
        "answer": "Katflix is open daily from 7:00 AM to 8:00 PM.",
      },
      {
        "question": "What hours are pickup and delivery available?",
        "answer": "Pickup and delivery are available only between 11:00 AM and 3:00 PM. If you try to book outside these hours, you'll need to reschedule your order for the next available window.",
      },
      {
        "question": "What happens if I'm not home when my order arrives?",
        "answer": "If there's no response within 30 minutes, our staff will attempt to contact you. You may then reschedule the delivery or provide alternate instructions for pickup or drop-off.",
      },
      {
        "question": "How do I report a missing or damaged item?",
        "answer": "Go to your Orders tab and select the order where the issue occurred. You'll find a 'Report an Issue' button at the bottom of the order details. Include a detailed description of the problem so we can resolve it quickly.",
      },
      {
        "question": "How do I report a staff-related concern or miscommunication?",
        "answer": "Navigate to your Orders, select the affected order, and use the 'Report an Issue' button at the bottom. Provide your order number and details of the incident. We're here to make things right.",
      },
      {
        "question": "Can I change or cancel my order after placing it?",
        "answer": "Yes, you can request changes or cancellations as long as the order hasn't been prepared or dispatched. Go to your Orders and use the Report Issue feature to contact us right away.",
      },
      {
        "question": "What areas do you deliver to?",
        "answer": "We deliver to Bagumbong and surrounding areas. If you're unsure whether we cover your location, please reach out via the Report Issue feature on any of your orders.",
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("FAQs"),
        backgroundColor: ILabaColors.white,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: ILabaColors.burgundy),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: faqs.length,
        itemBuilder: (context, index) {
          final item = faqs[index];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ExpansionTile(
              title: Text(
                item["question"]!,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    item["answer"]!,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
