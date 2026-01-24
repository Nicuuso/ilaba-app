import 'package:flutter/material.dart';
import 'order_details_helpers.dart';

/// Reusable UI widgets for order details screen
class OrderDetailsWidgets {
  /// Build a detail row with icon, label, and value
  static Widget buildDetailRow(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontSize: 11,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[900],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Build compact info item with icon only (no label)
  static Widget buildCompactInfo(
    String value,
    IconData icon, {
    TextStyle? valueStyle,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(height: 4),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style:
                valueStyle ??
                const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
          ),
        ),
      ],
    );
  }

  /// Build inline info item with icon and value side-by-side
  static Widget buildInlineInfo(
    String value,
    IconData icon, {
    TextStyle? valueStyle,
    bool emphasize = false,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: emphasize ? 16 : 14, color: Colors.grey[600]),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style:
                valueStyle ??
                TextStyle(
                  fontSize: emphasize ? 14 : 12,
                  fontWeight: emphasize ? FontWeight.w700 : FontWeight.w600,
                  color: Colors.grey[900],
                ),
          ),
        ),
      ],
    );
  }

  /// Build metric chip (weight, total, etc.)
  static Widget buildMetricChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// Build section header with icon and title
  static Widget buildSectionHeader(
    BuildContext context,
    IconData icon,
    String title,
    String badge,
  ) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        const Spacer(),
        if (badge.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              badge,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }

  /// Build address card (pickup/delivery)
  static Widget buildAddressCard(
    BuildContext context,
    String title,
    String address,
    MaterialColor color,
  ) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.grey[200]!, width: 0.8),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.location_on_outlined, size: 13, color: color),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    address,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Build summary row (subtotal, total, etc.)
  static Widget buildSummaryRow(
    BuildContext context,
    String label,
    String value, {
    bool isHighlight = true,
    bool isNegative = false,
    bool isTotal = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: isTotal || isHighlight
                  ? FontWeight.w700
                  : (isHighlight ? FontWeight.w600 : FontWeight.normal),
              fontSize: isTotal ? 16 : (isHighlight ? 15 : 13),
              color: isHighlight ? Colors.grey[800] : Colors.grey[700],
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: isTotal
                  ? FontWeight.w800
                  : (isHighlight || isNegative
                        ? FontWeight.w700
                        : FontWeight.w600),
              color: isNegative
                  ? Colors.red[700]
                  : (isTotal
                        ? Colors.green[700]
                        : (isHighlight ? Colors.grey[800] : Colors.grey[700])),
              fontSize: isTotal ? 16 : (isHighlight ? 15 : 13),
            ),
          ),
        ],
      ),
    );
  }

  /// Build order details card (top section) - Modernized layout
  static Widget buildOrderDetailsCard(
    BuildContext context,
    Map<String, dynamic> order,
    Map<String, dynamic>? customerData,
    Map<String, dynamic>? staffData,
  ) {
    final customerName = OrderDataExtractor.extractCustomerName(
      customerData,
      order,
    );
    final customerPhone = OrderDataExtractor.extractPhoneNumber(
      customerData,
      order,
    );
    final customerEmail = OrderDataExtractor.extractEmail(customerData, order);
    final cashierName = OrderDataExtractor.extractStaffName(staffData, order);
    final status = order['status'] ?? 'N/A';
    final createdAt = OrderDetailsHelpers.formatDate(order['created_at']);
    final pickupAddress = OrderDataExtractor.extractPickupAddress(order);
    final deliveryAddress = OrderDataExtractor.extractDeliveryAddress(order);
    final orderId = order['id'].toString().substring(0, 12);

    // Calculate total
    final breakdown = OrderDataExtractor.extractBreakdown(order);
    final summary = OrderDataExtractor.extractBreakdownSummary(breakdown);
    final finalTotal = OrderDataExtractor.getGrandTotal(order, summary);
    final totalAmount = OrderDetailsHelpers.formatCurrency(finalTotal);
    final statusColor = OrderDetailsHelpers.getStatusColor(status);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🏆 Top Row: Customer Name + Status Badge + Total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customerName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 4),
                    buildInlineInfo(
                      customerPhone,
                      Icons.phone_outlined,
                      valueStyle: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    totalAmount,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(height: 0.8, color: Colors.grey[200]),
          const SizedBox(height: 14),

          // 📋 Two-Column Layout: Contact Info + Order Meta
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Column: Contact info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    buildInlineInfo(
                      customerEmail,
                      Icons.email_outlined,
                      valueStyle: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 10),
                    buildInlineInfo(
                      cashierName,
                      Icons.person_pin_outlined,
                      valueStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[900],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),

              // Right Column: ID & Timestamp
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    buildInlineInfo(
                      orderId,
                      Icons.receipt_outlined,
                      valueStyle: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(height: 10),
                    buildInlineInfo(
                      createdAt,
                      Icons.calendar_today_outlined,
                      valueStyle: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(height: 0.8, color: Colors.grey[200]),
          const SizedBox(height: 14),

          // 📍 Fulfillment: Pickup & Delivery in grid
          Row(
            children: [
              Expanded(
                child: buildInlineInfo(
                  pickupAddress,
                  Icons.location_on_outlined,
                  valueStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[900],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: buildInlineInfo(
                  deliveryAddress,
                  Icons.local_shipping_outlined,
                  valueStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[900],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build empty state
  static Widget buildEmptyState(BuildContext context, String message) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 60, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            message,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
