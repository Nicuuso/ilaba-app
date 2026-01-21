/// Web API compatible order models
/// Matches the backend order structure for /api/orders/transactional-create
library;

import 'dart:math';

// Simple UUID-like ID generator (matches UUIDs when displayed)
String _generateId() {
  const String chars = '0123456789abcdef';
  final random = Random();
  final buffer = StringBuffer();
  
  for (var i = 0; i < 36; i++) {
    if (i == 8 || i == 13 || i == 18 || i == 23) {
      buffer.write('-');
    } else {
      buffer.write(chars[random.nextInt(16)]);
    }
  }
  
  return buffer.toString();
}

// ============================================================================
// BREAKDOWN MODELS
// ============================================================================

class OrderItem {
  final String id;
  final String productId;
  final String productName;
  final int quantity;
  final double unitPrice;
  final double unitCost;
  final double subtotal;
  final Map<String, dynamic> discount;

  OrderItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.unitCost,
    required this.subtotal,
    this.discount = const {'amount': 0, 'reason': null},
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'product_name': productName,
      'quantity': quantity,
      'unit_price': unitPrice,
      'unit_cost': unitCost,
      'subtotal': subtotal,
      'discount': discount,
    };
  }
}

class OrderService {
  final String id;
  final String serviceId;
  final String serviceName;
  final bool isPremium;
  final int multiplier;
  final double ratePerKg;
  final double subtotal;
  final String status;
  final String? startedAt;
  final String? completedAt;
  final String? completedBy;
  final int? durationInMinutes;

  OrderService({
    required this.id,
    required this.serviceId,
    required this.serviceName,
    required this.isPremium,
    required this.multiplier,
    required this.ratePerKg,
    required this.subtotal,
    this.status = 'pending',
    this.startedAt,
    this.completedAt,
    this.completedBy,
    this.durationInMinutes,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'service_id': serviceId,
      'service_name': serviceName,
      'is_premium': isPremium,
      'multiplier': multiplier,
      'rate_per_kg': ratePerKg,
      'subtotal': subtotal,
      'status': status,
      'started_at': startedAt,
      'completed_at': completedAt,
      'completed_by': completedBy,
      'duration_in_minutes': durationInMinutes,
    };
  }
}

class OrderBasket {
  final int basketNumber;
  final double weight;
  final String? basketNotes;
  final List<OrderService> services;
  final double total;
  final String?
  approvalStatus; // "pending" | "approved" | "rejected" | null (for web)
  final String? approvedAt;
  final String? approvedBy;
  final String? rejectionReason;

  OrderBasket({
    required this.basketNumber,
    required this.weight,
    required this.services,
    required this.total,
    this.basketNotes,
    this.approvalStatus,
    this.approvedAt,
    this.approvedBy,
    this.rejectionReason,
  });

  Map<String, dynamic> toJson() {
    return {
      'basket_number': basketNumber,
      'weight': weight,
      'basket_notes': basketNotes,
      'services': services.map((s) => s.toJson()).toList(),
      'total': total,
      'approval_status': approvalStatus,
      'approved_at': approvedAt,
      'approved_by': approvedBy,
      'rejection_reason': rejectionReason,
    };
  }
}

class OrderFee {
  final String id;
  final String type;
  final String description;
  final double amount;

  OrderFee({
    required this.id,
    required this.type,
    required this.description,
    required this.amount,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'description': description,
      'amount': amount,
    };
  }
}

class PaymentTotals {
  final double? productSubtotal;
  final double? basketSubtotal;
  final double? serviceFee;
  final double? handlingFee;
  final double taxRate;
  final double taxIncluded;
  final double total;
  final String vatModel; // "inclusive" by default

  PaymentTotals({
    this.productSubtotal,
    this.basketSubtotal,
    this.serviceFee,
    this.handlingFee,
    required this.taxRate,
    required this.taxIncluded,
    required this.total,
    this.vatModel = 'inclusive',
  });

  Map<String, dynamic> toJson() {
    return {
      'subtotal_products': productSubtotal,
      'subtotal_services': basketSubtotal,
      'service_fee': serviceFee,
      'handling': handlingFee,
      'vat_rate': taxRate,
      'vat_amount': taxIncluded,
      'vat_model': vatModel,
      'grand_total': total,
    };
  }
}

class GCashReceipt {
  final String? screenshotUrl;
  final String? transactionId;
  final bool verified;

  GCashReceipt({this.screenshotUrl, this.transactionId, this.verified = false});

  Map<String, dynamic> toJson() {
    return {
      'screenshot_url': screenshotUrl,
      'transaction_id': transactionId,
      'verified': verified,
    };
  }
}

class OrderPayment {
  final String method;
  final String paymentStatus;
  final double amountPaid;
  final double changeAmount;
  final String? completedAt;
  final GCashReceipt gcashReceipt;

  OrderPayment({
    required this.method,
    required this.paymentStatus,
    required this.amountPaid,
    this.changeAmount = 0,
    this.completedAt,
    required this.gcashReceipt,
  });

  Map<String, dynamic> toJson() {
    return {
      'method': method,
      'payment_status': paymentStatus,
      'amount_paid': amountPaid,
      'change_amount': changeAmount,
      'completed_at': completedAt,
      'gcash_receipt': gcashReceipt.toJson(),
    };
  }
}

class AuditLogEntry {
  final String timestamp;
  final String? changedBy;
  final String action;
  final Map<String, dynamic> details;

  AuditLogEntry({
    required this.timestamp,
    this.changedBy,
    required this.action,
    required this.details,
  });

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp,
      'changed_by': changedBy,
      'action': action,
      'details': details,
    };
  }
}

class OrderBreakdown {
  final List<OrderItem> items;
  final List<OrderBasket> baskets;
  final List<OrderFee> fees;
  final PaymentTotals totals;
  final OrderPayment payment;
  final List<AuditLogEntry> auditLog;

  OrderBreakdown({
    required this.items,
    required this.baskets,
    required this.fees,
    required this.totals,
    required this.payment,
    required this.auditLog,
  });

  Map<String, dynamic> toJson() {
    return {
      'items': items.map((i) => i.toJson()).toList(),
      'baskets': baskets.map((b) => b.toJson()).toList(),
      'fees': fees.map((f) => f.toJson()).toList(),
      'summary': totals.toJson(),
      'payment': payment.toJson(),
      'audit_log': auditLog.map((a) => a.toJson()).toList(),
    };
  }
}

// ============================================================================
// HANDLING MODELS
// ============================================================================

class HandlingLocation {
  final String? address;
  final double? latitude;
  final double? longitude;
  final String? notes;
  final String status;
  final String? startedAt;
  final String? completedAt;
  final String? completedBy;
  final int? durationInMinutes;

  HandlingLocation({
    this.address,
    this.latitude,
    this.longitude,
    this.notes,
    this.status = 'pending',
    this.startedAt,
    this.completedAt,
    this.completedBy,
    this.durationInMinutes,
  });

  Map<String, dynamic> toJson() {
    return {
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'notes': notes,
      'status': status,
      'started_at': startedAt,
      'completed_at': completedAt,
      'completed_by': completedBy,
      'duration_in_minutes': durationInMinutes,
    };
  }
}

class OrderHandling {
  final HandlingLocation pickup;
  final HandlingLocation delivery;

  OrderHandling({required this.pickup, required this.delivery});

  Map<String, dynamic> toJson() {
    return {'pickup': pickup.toJson(), 'delivery': delivery.toJson()};
  }
}

// ============================================================================
// ORDER PAYLOAD MODELS
// ============================================================================

class CustomerData {
  final String id;
  final String? phoneNumber;
  final String? emailAddress;

  CustomerData({required this.id, this.phoneNumber, this.emailAddress});

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phone_number': phoneNumber,
      'email_address': emailAddress,
    };
  }
}

// ============================================================================
// API PAYLOAD MODELS (for backend endpoint)
// ============================================================================

class BackendServicePayload {
  final String serviceId;
  final String serviceName;
  final double rate;
  final double subtotal;

  BackendServicePayload({
    required this.serviceId,
    required this.serviceName,
    required this.rate,
    required this.subtotal,
  });

  Map<String, dynamic> toJson() {
    return {
      'service_id': serviceId,
      'service_name': serviceName,
      'rate': rate,
      'subtotal': subtotal,
    };
  }
}

class BackendBasketPayload {
  final double weight;
  final double subtotal;
  final String? notes;
  final List<BackendServicePayload> services;

  BackendBasketPayload({
    required this.weight,
    required this.subtotal,
    required this.services,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'weight': weight,
      'subtotal': subtotal,
      'notes': notes,
      'services': services.map((s) => s.toJson()).toList(),
    };
  }
}

class BackendProductPayload {
  final String productId;
  final int quantity;
  final double unitPrice;
  final double subtotal;

  BackendProductPayload({
    required this.productId,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
  });

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'quantity': quantity,
      'unit_price': unitPrice,
      'subtotal': subtotal,
    };
  }
}

class CreateOrderPayload {
  final String customerId;
  final double total;
  final List<BackendBasketPayload> baskets;
  final List<BackendProductPayload> products;
  final String? pickupAddress;
  final String? deliveryAddress;
  final double shippingFee;
  final String source;
  final String? gcashReceiptUrl;

  CreateOrderPayload({
    required this.customerId,
    required this.total,
    required this.baskets,
    required this.products,
    this.pickupAddress,
    this.deliveryAddress,
    this.shippingFee = 0,
    this.source = 'app',
    this.gcashReceiptUrl,
  });

  Map<String, dynamic> toJson() {
    // Calculate totals
    final subtotalProducts = products.fold(0.0, (sum, p) => sum + p.subtotal);
    final subtotalServices = baskets.fold(0.0, (sum, b) => sum + b.subtotal);
    final serviceFee = baskets.isNotEmpty ? 10.0 : 0.0; // Service fee for baskets
    final vatAmount = total * (12 / 112); // 12% VAT (inclusive model)

    // Build handling JSONB structure (matches POS format)
    final handling = {
      'pickup': {
        'address': pickupAddress ?? '',
        'latitude': null,
        'longitude': null,
        'notes': null,
        'status': 'pending',
        'started_at': null,
        'completed_at': null,
        'completed_by': null,
        'duration_in_minutes': null,
      },
      'delivery': {
        'address': deliveryAddress,
        'latitude': null,
        'longitude': null,
        'notes': null,
        'status': deliveryAddress != null ? 'pending' : 'skipped',
        'started_at': null,
        'completed_at': null,
        'completed_by': null,
        'duration_in_minutes': null,
      },
    };

    // Build breakdown JSONB structure (matches POS format)
    final breakdown = {
      'items': products.map((p) {
        return {
          'id': _generateId(),
          'discount': {'amount': 0, 'reason': null},
          'quantity': p.quantity,
          'subtotal': p.subtotal,
          'product_id': p.productId,
          'unit_price': p.unitPrice,
          'product_name': '', // Product name not available in payload
        };
      }).toList(),
      'baskets': baskets.asMap().entries.map((entry) {
        final index = entry.key + 1;
        final b = entry.value;
        return {
          'id': _generateId(),
          'total': b.subtotal,
          'status': 'pending',
          'weight': b.weight,
          'services': b.services.map((s) {
            return {
              'id': _generateId(),
              'status': 'pending',
              'subtotal': s.subtotal,
              'is_premium': false,
              'multiplier': 1,
              'service_id': s.serviceId,
              'started_at': null,
              'started_by': null,
              'rate_per_kg': s.rate,
              'completed_at': null,
              'completed_by': null,
              'service_name': s.serviceName,
              'duration_in_minutes': null,
            };
          }).toList(),
          'basket_notes': b.notes,
          'completed_at': null,
          'basket_number': index,
        };
      }).toList(),
      'payment': {
        'change': 0.0,
        'method': 'gcash',
        'amount_paid': total,
        'completed_at': DateTime.now().toIso8601String(),
        'payment_status': 'successful',
      },
      'summary': {
        'handling': shippingFee,
        'vat_rate': 12,
        'discounts': null,
        'vat_model': 'inclusive',
        'vat_amount': vatAmount,
        'grand_total': total,
        'service_fee': serviceFee,
        'subtotal_products': subtotalProducts,
        'subtotal_services': subtotalServices,
      },
      'audit_log': [
        {
          'action': 'created',
          'timestamp': DateTime.now().toIso8601String(),
          'changed_by': customerId,
        }
      ],
      'discounts': null,
      'fees': [
        if (serviceFee > 0)
          {
            'id': _generateId(),
            'type': 'service_fee',
            'amount': serviceFee,
            'description': 'Service fee (${baskets.length} basket${baskets.length > 1 ? 's' : ''})',
          },
        if (shippingFee > 0)
          {
            'id': _generateId(),
            'type': 'handling_fee',
            'amount': shippingFee,
            'description': 'Delivery Fee',
          },
      ],
    };

    // Return POS format structure
    return {
      'source': source,
      'customer_id': customerId,
      'cashier_id': null, // Mobile orders have no cashier initially
      'status': 'pending', // Mobile orders start as pending
      'total_amount': total,
      'breakdown': breakdown,
      'handling': handling,
      'order_note': null,
      if (gcashReceiptUrl != null) 'gcash_receipt_url': gcashReceiptUrl,
    };
  }
}

class CreateOrderRequest {
  final CustomerData customer;
  final CreateOrderPayload orderPayload;

  CreateOrderRequest({required this.customer, required this.orderPayload});

  Map<String, dynamic> toJson() {
    return {
      'customer': customer.toJson(),
      'orderPayload': {
        'customer_id': orderPayload.customerId,
        'total': orderPayload.total,
        'baskets': orderPayload.baskets.map((b) => b.toJson()).toList(),
        'products': orderPayload.products.map((p) => p.toJson()).toList(),
        'pickupAddress': orderPayload.pickupAddress,
        'deliveryAddress': orderPayload.deliveryAddress,
        'shippingFee': orderPayload.shippingFee,
        'source': orderPayload.source,
        'payments': [
          {'amount': orderPayload.total, 'method': 'gcash'},
        ],
      },
    };
  }
}

class CreateOrderResponse {
  final bool success;
  final String orderId;
  final Map<String, dynamic>? order;
  final String? error;
  final List<Map<String, dynamic>>? insufficientItems;

  CreateOrderResponse({
    required this.success,
    required this.orderId,
    this.order,
    this.error,
    this.insufficientItems,
  });

  factory CreateOrderResponse.fromJson(Map<String, dynamic> json) {
    return CreateOrderResponse(
      success: json['success'] as bool,
      orderId: json['orderId'] as String? ?? '',
      order: json['order'] as Map<String, dynamic>?,
      error: json['error'] as String?,
      insufficientItems: (json['insufficientItems'] as List?)
          ?.cast<Map<String, dynamic>>(),
    );
  }
}
