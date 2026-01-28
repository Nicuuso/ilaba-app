import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ilaba/constants/ilaba_colors.dart';

class ReportIssueScreen extends StatefulWidget {
  final String orderId;
  final String? orderNumber;
  final String? customerName;
  final String? customerId;

  const ReportIssueScreen({
    required this.orderId,
    this.orderNumber,
    this.customerName,
    this.customerId,
  });

  @override
  State<ReportIssueScreen> createState() => _ReportIssueScreenState();
}

class _ReportIssueScreenState extends State<ReportIssueScreen> {
  late TextEditingController _descriptionController;
  late TextEditingController _basketNumberController;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController();
    _basketNumberController = TextEditingController();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _basketNumberController.dispose();
    super.dispose();
  }

  Future<void> _submitIssue() async {
    if (_descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please describe the issue'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final supabase = Supabase.instance.client;

      // Insert issue into database
      // Include customer name in the description for visibility
      final reporterName = widget.customerName ?? 'Customer';
      final fullDescription =
          '[Reported by: $reporterName]\n\n${_descriptionController.text.trim()}';

      await supabase.from('issues').insert({
        'order_id': widget.orderId,
        'basket_number':
            _basketNumberController.text.isNotEmpty
                ? int.tryParse(_basketNumberController.text)
                : null,
        'description': fullDescription,
        'severity': 'low',
        'status': 'open',
        'reported_by': null,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Issue reported successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error reporting issue: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Report Issue',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        centerTitle: false,
        backgroundColor: ILabaColors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: ILabaColors.burgundy),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order Number Card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: ILabaColors.burgundy.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: ILabaColors.burgundy.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: ILabaColors.burgundy.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.receipt_long,
                      color: ILabaColors.burgundy,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order',
                          style: TextStyle(
                            fontSize: 11,
                            color: ILabaColors.lightText,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.orderNumber ?? widget.orderId.substring(0, 8),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: ILabaColors.darkText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Issue Description
            Text(
              'What is the issue?',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descriptionController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText:
                    'Describe the issue in detail (e.g., damaged clothes, missing items, delivery issues)',
                hintStyle: TextStyle(
                  color: ILabaColors.lightText,
                  fontSize: 13,
                ),
                filled: true,
                fillColor: ILabaColors.lightGray,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
            const SizedBox(height: 20),

            // Basket Number (Optional)
            Text(
              'Basket Number (Optional)',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _basketNumberController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'Enter basket number if applicable',
                hintStyle: TextStyle(
                  color: ILabaColors.lightText,
                  fontSize: 13,
                ),
                filled: true,
                fillColor: ILabaColors.lightGray,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
            const SizedBox(height: 20),

            // Severity Selection - HIDDEN
            // Users don't select severity; it defaults to 'low'
            // Staff can update severity when reviewing the issue

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      ILabaColors.burgundy,
                      ILabaColors.burgundyDark,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitIssue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    disabledBackgroundColor: Colors.grey[300],
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              ILabaColors.white,
                            ),
                          ),
                        )
                      : const Text(
                          'Submit Report',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: ILabaColors.white,
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Info Text
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: Colors.blue[700],
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Our support team will review your report and contact you within 24 hours.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[700],
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
  }
}
