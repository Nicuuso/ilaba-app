/// Expandable Order Summary Widget
/// Shows compact view by default (just total with chevron)
/// Expands to full breakdown on tap
/// Scrolls naturally with page content

import 'package:flutter/material.dart';
import 'package:ilaba/providers/mobile_booking_provider.dart';
import 'package:ilaba/constants/ilaba_colors.dart';

class OrderSummaryExpandable extends StatefulWidget {
  final MobileBookingProvider provider;
  final bool showProductBreakdown;
  final bool showDeliveryFee;

  const OrderSummaryExpandable({
    Key? key,
    required this.provider,
    this.showProductBreakdown = false,
    this.showDeliveryFee = false,
  }) : super(key: key);

  @override
  State<OrderSummaryExpandable> createState() =>
      _OrderSummaryExpandableState();
}

class _OrderSummaryExpandableState extends State<OrderSummaryExpandable>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
    if (_isExpanded) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final breakdown = widget.provider.calculateOrderTotal();
    final total = breakdown.summary.total;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: ILabaColors.white,
        border: Border.all(
          color: ILabaColors.burgundy.withOpacity(0.15),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: ILabaColors.softShadow,
      ),
      child: Column(
        children: [
          // Collapsed Header - Always Visible
          GestureDetector(
            onTap: _toggleExpanded,
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order Total',
                        style: TextStyle(
                          fontSize: 12,
                          color: ILabaColors.lightText,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₱${total.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: ILabaColors.burgundy,
                        ),
                      ),
                    ],
                  ),
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 300),
                    child: Icon(
                      Icons.expand_more,
                      size: 28,
                      color: ILabaColors.burgundy,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Expanded Content
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: _isExpanded
                ? Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: ILabaColors.burgundy.withOpacity(0.2),
                        ),
                      ),
                      color: ILabaColors.burgundy.withOpacity(0.03),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Services Breakdown
                        _buildServiceBreakdown(breakdown),

                        const SizedBox(height: 12),

                        // Products Breakdown (if applicable)
                        if (widget.showProductBreakdown &&
                            breakdown.items.isNotEmpty)
                          Column(
                            children: [
                              _buildProductsBreakdown(breakdown),
                              const SizedBox(height: 12),
                            ],
                          ),

                        // Staff Fee
                        if (breakdown.summary.staffServiceFee > 0)
                          Column(
                            children: [
                              _buildLineItem(
                                'Staff Fee',
                                '₱${breakdown.summary.staffServiceFee.toStringAsFixed(2)}',
                                isSubtle: true,
                              ),
                              const SizedBox(height: 8),
                            ],
                          ),

                        // Delivery Fee
                        if (widget.showDeliveryFee &&
                            breakdown.summary.deliveryFee > 0)
                          Column(
                            children: [
                              _buildLineItem(
                                'Delivery Fee',
                                '₱${breakdown.summary.deliveryFee.toStringAsFixed(2)}',
                                isSubtle: true,
                              ),
                              const SizedBox(height: 8),
                            ],
                          ),

                        // VAT
                        _buildLineItem(
                          'VAT (12%)',
                          '₱${breakdown.summary.vatAmount.toStringAsFixed(2)}',
                          isSubtle: true,
                        ),

                        const SizedBox(height: 12),

                        // Divider
                        Divider(
                          color: ILabaColors.burgundy.withOpacity(0.2),
                          height: 1,
                        ),

                        const SizedBox(height: 12),

                        // Total (repeated for clarity in expanded view)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '₱${total.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: ILabaColors.burgundy,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  /// Build services breakdown from baskets
  Widget _buildServiceBreakdown(dynamic breakdown) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Services',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: ILabaColors.burgundy,
              ),
            ),
            Text(
              '₱${breakdown.summary.subtotalBaskets.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: ILabaColors.burgundy,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _buildServicesList(),
      ],
    );
  }

  /// Build services list with descriptions
  Widget _buildServicesList() {
    final services = <String, double>{};
    
    // Aggregate services from baskets
    for (final basket in widget.provider.baskets) {
      if (basket.services.wash != 'off') {
        final service = widget.provider.services.firstWhere(
          (s) => s.serviceType == 'wash' && s.tier == basket.services.wash,
          orElse: () => widget.provider.services.firstWhere(
            (s) => s.serviceType == 'wash',
          ),
        );
        services['Wash: ${service.name}'] = service.basePrice;
      }
      if (basket.services.dry != 'off') {
        final service = widget.provider.services.firstWhere(
          (s) => s.serviceType == 'dry' && s.tier == basket.services.dry,
          orElse: () => widget.provider.services.firstWhere(
            (s) => s.serviceType == 'dry',
          ),
        );
        services['Dry: ${service.name}'] = service.basePrice;
      }
      if (basket.services.spin) {
        final spinServices = widget.provider.services
            .where((s) => s.serviceType == 'spin')
            .toList();
        if (spinServices.isNotEmpty) {
          services['Spin'] = spinServices.first.basePrice;
        }
      }
      if (basket.services.ironWeightKg > 0) {
        final ironServices = widget.provider.services
            .where((s) => s.serviceType == 'iron')
            .toList();
        if (ironServices.isNotEmpty) {
          services['Iron (${basket.services.ironWeightKg}kg)'] =
              ironServices.first.basePrice * basket.services.ironWeightKg;
        }
      }
    }

    return Column(
      children: services.entries.map((entry) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: _buildLineItem(
            entry.key,
            '₱${entry.value.toStringAsFixed(2)}',
          ),
        );
      }).toList(),
    );
  }

  /// Build products breakdown
  Widget _buildProductsBreakdown(dynamic breakdown) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Add-Ons',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: ILabaColors.burgundy,
              ),
            ),
            Text(
              '₱${breakdown.summary.subtotalProducts.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: ILabaColors.burgundy,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...breakdown.items.map((item) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: _buildLineItem(
              '${item.productName} x${item.quantity}',
              '₱${item.totalPrice.toStringAsFixed(2)}',
            ),
          );
        }).toList(),
      ],
    );
  }

  /// Build a single line item
  Widget _buildLineItem(
    String label,
    String value, {
    bool isSubtle = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isSubtle ? ILabaColors.lightText : ILabaColors.darkText,
            fontWeight: isSubtle ? FontWeight.w400 : FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSubtle ? ILabaColors.lightText : ILabaColors.darkText,
          ),
        ),
      ],
    );
  }
}
