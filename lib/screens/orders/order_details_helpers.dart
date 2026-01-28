import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:ilaba/constants/ilaba_colors.dart';

/// Supabase configuration constants
class SupabaseConfig {
  static const String projectUrl = 'https://nkcfolnwxxnsskaerkyq.supabase.co';
  static const String productBucket = 'product-images';
}

/// Formatting and utility functions for order details
class OrderDetailsHelpers {
  /// Get effective display status from order by reading handling JSONB
  /// Main statuses: pending, processing, completed, cancelled
  /// Handling contains: pickup.status and delivery.status
  static String getEffectiveStatus(Map<String, dynamic> order) {
    final mainStatus = (order['status'] as String?)?.toLowerCase() ?? 'pending';
    
    // Parse handling JSONB - it may be a String or a Map
    Map<String, dynamic> handling = {};
    final handlingData = order['handling'];
    if (handlingData is String) {
      try {
        if (handlingData.isNotEmpty) {
          final decoded = jsonDecode(handlingData);
          if (decoded is Map) {
            handling = Map<String, dynamic>.from(decoded);
          }
        }
      } catch (e) {
        debugPrint('⚠️ Error parsing handling JSON: $e');
      }
    } else if (handlingData is Map) {
      handling = Map<String, dynamic>.from(handlingData);
    }
    
    final pickupData = handling['pickup'] as Map<String, dynamic>? ?? {};
    final deliveryData = handling['delivery'] as Map<String, dynamic>? ?? {};
    
    final pickupStatus = (pickupData['status'] as String?)?.toLowerCase() ?? 'pending';
    final deliveryStatus = (deliveryData['status'] as String?)?.toLowerCase() ?? 'pending';
    
    debugPrint('📊 getEffectiveStatus: main=$mainStatus, pickup=$pickupStatus, delivery=$deliveryStatus');
    
    // Determine effective status for display
    // The badge should reflect the ACTUAL current step, not generalized
    
    // 1. Cancelled always takes priority
    if (mainStatus == 'cancelled') {
      return 'cancelled';
    }
    
    // 2. Completed - when main status is completed or delivery is done
    if (mainStatus == 'completed' || deliveryStatus == 'completed') {
      return 'completed';
    }
    
    // 3. For Delivery - when delivery is in progress
    if (deliveryStatus == 'in_progress') {
      return 'for_delivery';
    }
    
    // 4. For Pick-up - when pickup is in progress (BEFORE checking processing!)
    if (pickupStatus == 'in_progress') {
      return 'for_pick-up';
    }
    
    // 5. Processing - when pickup is done but delivery hasn't started
    if ((pickupStatus == 'completed' || pickupStatus == 'skipped') && 
        deliveryStatus == 'pending') {
      return 'processing';
    }
    
    // 6. Main status is processing (fallback)
    if (mainStatus == 'processing') {
      return 'processing';
    }
    
    // 7. Default to pending
    return 'pending';
  }

  /// Get product image URL from Supabase bucket
  static String getProductImageUrl(dynamic imageData) {
    if (imageData == null) {
      print('🖼️ Product image: null');
      return '';
    }

    final imageStr = imageData.toString().trim();
    if (imageStr.isEmpty) {
      print('🖼️ Product image: empty string');
      return '';
    }

    // If it's already a full URL, return it
    if (imageStr.startsWith('http://') || imageStr.startsWith('https://')) {
      print('🖼️ Product image (full URL): $imageStr');
      return imageStr;
    }

    // If it's just a filename/path, construct the full URL
    final fullUrl =
        '${SupabaseConfig.projectUrl}/storage/v1/object/public/${SupabaseConfig.productBucket}/$imageStr';
    print('🖼️ Product image (constructed): $fullUrl');
    return fullUrl;
  }

  /// Format date strings to readable format
  static String formatDate(String? dateString) {
    if (dateString == null) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      final period = date.hour >= 12 ? 'PM' : 'AM';
      final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
      return '${months[date.month - 1]} ${date.day}, ${date.year} • ${hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')} $period';
    } catch (e) {
      return dateString;
    }
  }

  /// Format amounts to currency format
  static String formatCurrency(dynamic amount) {
    if (amount == null) return '₱0.00';
    if (amount is String) {
      return '₱${(double.tryParse(amount) ?? 0).toStringAsFixed(2)}';
    } else if (amount is num) {
      return '₱${amount.toDouble().toStringAsFixed(2)}';
    }
    return '₱0.00';
  }

  /// Format labels to title case
  static String formatLabel(String label) {
    return label
        .replaceAll('_', ' ')
        .split(' ')
        .map(
          (word) => word.isEmpty
              ? ''
              : word[0].toUpperCase() + word.substring(1).toLowerCase(),
        )
        .join(' ')
        .replaceAllMapped(
          RegExp(r'\(([^)]+)\)'),
          (match) => '(${match.group(1)?.toLowerCase()})',
        );
  }

  /// Normalize status to match app's expected format
  /// Handles variations from website: for_pickup, for_pick-up, pickup, pick-up, for pickup, etc.
  static String normalizeStatus(String? status) {
    if (status == null || status.isEmpty) return 'pending';
    
    final lowerStatus = status.toLowerCase().trim();
    
    // Handle all pickup variations
    if (lowerStatus.contains('pick') && lowerStatus.contains('up')) {
      return 'for_pick-up';
    }
    if (lowerStatus == 'pickup' || lowerStatus == 'pick-up' || lowerStatus == 'pick_up') {
      return 'for_pick-up';
    }
    
    // Handle all delivery variations
    if (lowerStatus.contains('delivery') || lowerStatus == 'for_delivery' || lowerStatus == 'fordelivery') {
      return 'for_delivery';
    }
    
    // Return as-is for other statuses
    return lowerStatus;
  }

  /// Get color based on status
  static Color getStatusColor(String? status) {
    final normalizedStatus = normalizeStatus(status);
    switch (normalizedStatus) {
      case 'pending':
        return Colors.orange;
      case 'for_pick-up':
        return Colors.indigo;
      case 'processing':
        return Colors.blue;
      case 'for_delivery':
        return Colors.purple;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  /// Get icon based on status
  static IconData getStatusIcon(String? status) {
    final normalizedStatus = normalizeStatus(status);
    switch (normalizedStatus) {
      case 'pending':
        return Icons.schedule;
      case 'for_pick-up':
        return Icons.local_shipping;
      case 'processing':
        return Icons.local_laundry_service;
      case 'for_delivery':
        return Icons.delivery_dining;
      case 'completed':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }

  /// Get status label
  static String getStatusLabel(String? status) {
    final normalizedStatus = normalizeStatus(status);
    switch (normalizedStatus) {
      case 'pending':
        return 'Pending';
      case 'for_pick-up':
        return 'For Pick-up';
      case 'processing':
        return 'Processing';
      case 'for_delivery':
        return 'For Delivery';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return formatLabel(status ?? 'Unknown');
    }
  }
}

/// Safe number conversion
class SafeConversion {
  /// Safely convert any value to a number (num)
  static num toNum(dynamic value, [num defaultValue = 0]) {
    if (value == null) return defaultValue;
    if (value is num) return value;
    if (value is String) {
      try {
        return num.parse(value);
      } catch (e) {
        return defaultValue;
      }
    }
    if (value is Map) return defaultValue; // Maps can't be converted to num
    return defaultValue;
  }

  /// Safely convert any value to an int
  static int toInt(dynamic value, [int defaultValue = 0]) {
    return toNum(value, defaultValue).toInt();
  }

  /// Safely convert any value to a double
  static double toDouble(dynamic value, [double defaultValue = 0.0]) {
    return toNum(value, defaultValue).toDouble();
  }
}

/// Data extraction helpers
class OrderDataExtractor {
  /// Extract customer name from customer data
  static String extractCustomerName(
    Map<String, dynamic>? customerData,
    Map<String, dynamic> order,
  ) {
    if (customerData == null) return 'N/A';

    if (customerData['first_name'] != null &&
        customerData['last_name'] != null) {
      return '${customerData['first_name']} ${customerData['last_name']}';
    }
    return customerData['email_address'] ?? customerData['email'] ?? 'N/A';
  }

  /// Extract staff/cashier name
  static String extractStaffName(
    Map<String, dynamic>? staffData,
    Map<String, dynamic> order,
  ) {
    if (staffData == null) return 'N/A';

    if (staffData['first_name'] != null && staffData['last_name'] != null) {
      return '${staffData['first_name']} ${staffData['last_name']}';
    }
    return staffData['full_name'] ?? staffData['name'] ?? 'N/A';
  }

  /// Extract phone number
  static String extractPhoneNumber(
    Map<String, dynamic>? customerData,
    Map<String, dynamic> order,
  ) {
    if (customerData == null) return 'N/A';
    return customerData['phone_number'] ??
        customerData['phone'] ??
        order['customer_phone'] ??
        'N/A';
  }

  /// Extract email
  static String extractEmail(
    Map<String, dynamic>? customerData,
    Map<String, dynamic> order,
  ) {
    if (customerData == null) return 'N/A';
    return customerData['email_address'] ??
        customerData['email'] ??
        order['customer_email'] ??
        'N/A';
  }

  /// Extract pickup address from handling JSONB
  static String extractPickupAddress(Map<String, dynamic> order) {
    final handlingData = order['handling'] as Map<String, dynamic>? ?? {};
    final address =
        (handlingData['pickup'] as Map?)?['address'] ?? order['pickup_address'];
    return (address == null || address.toString().isEmpty)
        ? 'In-store'
        : address.toString();
  }

  /// Extract delivery address from handling JSONB
  static String extractDeliveryAddress(Map<String, dynamic> order) {
    final handlingData = order['handling'] as Map<String, dynamic>? ?? {};
    final address =
        (handlingData['delivery'] as Map?)?['address'] ??
        order['delivery_address'];
    return (address == null || address.toString().isEmpty)
        ? 'In-store'
        : address.toString();
  }

  /// Extract breakdown data
  static Map<String, dynamic> extractBreakdown(Map<String, dynamic> order) {
    return order['breakdown'] as Map<String, dynamic>? ?? {};
  }

  /// Extract breakdown summary
  static Map<String, dynamic> extractBreakdownSummary(
    Map<String, dynamic> breakdown,
  ) {
    return (breakdown['summary'] as Map<String, dynamic>?) ?? {};
  }

  /// Get final total (grand_total with VAT, fallback to total_amount)
  static num getGrandTotal(
    Map<String, dynamic> order,
    Map<String, dynamic> summary,
  ) {
    return (summary['grand_total'] ?? order['total_amount']) ?? 0;
  }

  /// Extract items list
  static List<dynamic> extractItems(Map<String, dynamic> breakdown) {
    return (breakdown['items'] as List?) ?? [];
  }

  /// Extract baskets list
  static List<dynamic> extractBaskets(Map<String, dynamic> breakdown) {
    return (breakdown['baskets'] as List?) ?? [];
  }

  /// Extract fees list
  static List<dynamic> extractFees(Map<String, dynamic> breakdown) {
    return (breakdown['fees'] as List?) ?? [];
  }

  /// Extract discounts list
  static List<dynamic> extractDiscounts(Map<String, dynamic> breakdown) {
    return (breakdown['discounts'] as List?) ?? [];
  }

  /// Extract payment info
  static Map<String, dynamic> extractPayment(Map<String, dynamic> breakdown) {
    return (breakdown['payment'] as Map<String, dynamic>?) ?? {};
  }

  /// Extract audit log
  static List<dynamic> extractAuditLog(Map<String, dynamic> breakdown) {
    return (breakdown['audit_log'] as List?) ?? [];
  }

  /// Extract cancellation info (if exists)
  static Map<String, dynamic>? extractCancellation(Map<String, dynamic> order) {
    return order['cancellation'] as Map<String, dynamic>?;
  }
}
