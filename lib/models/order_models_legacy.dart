/// Legacy POS API compatible order models
/// Matches the /api/pos/newOrder endpoint structure
library;

// ============================================================================
// BACKEND PAYLOAD MODELS
// ============================================================================

class BackendServicePayload {
  final String serviceId;
  final double rate;
  final double subtotal;

  BackendServicePayload({
    required this.serviceId,
    required this.rate,
    required this.subtotal,
  });

  Map<String, dynamic> toJson() {
    return {'service_id': serviceId, 'rate': rate, 'subtotal': subtotal};
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

class BackendPaymentPayload {
  final double amount;
  final String method;
  final String? reference;

  BackendPaymentPayload({
    required this.amount,
    required this.method,
    this.reference,
  });

  Map<String, dynamic> toJson() {
    return {'amount': amount, 'method': method, 'reference': reference};
  }
}

// ============================================================================
// CREATE ORDER PAYLOAD (for /api/pos/newOrder)
// ============================================================================

class CreateOrderPayload {
  final String customerId;
  final double total;
  final List<BackendBasketPayload> baskets;
  final List<BackendProductPayload> products;
  final List<BackendPaymentPayload> payments;
  final String? pickupAddress;
  final String? deliveryAddress;
  final double shippingFee;
  final String source;

  CreateOrderPayload({
    required this.customerId,
    required this.total,
    required this.baskets,
    required this.products,
    required this.payments,
    this.pickupAddress,
    this.deliveryAddress,
    this.shippingFee = 0,
    this.source = 'mobile',
  });

  Map<String, dynamic> toJson() {
    return {
      'customerId': customerId,
      'total': total,
      'baskets': baskets.map((b) => b.toJson()).toList(),
      'products': products.map((p) => p.toJson()).toList(),
      'payments': payments.map((p) => p.toJson()).toList(),
      'pickupAddress': pickupAddress,
      'deliveryAddress': deliveryAddress,
      'shippingFee': shippingFee,
      'source': source,
    };
  }
}

// ============================================================================
// ORDER REQUEST & RESPONSE
// ============================================================================

class CreateOrderRequest {
  final CreateOrderPayload payload;

  CreateOrderRequest({required this.payload});

  Map<String, dynamic> toJson() => payload.toJson();
}

class CreateOrderResponse {
  final bool success;
  final String orderId;
  final String? error;
  final List<Map<String, dynamic>>? insufficientItems;

  CreateOrderResponse({
    required this.success,
    required this.orderId,
    this.error,
    this.insufficientItems,
  });

  factory CreateOrderResponse.fromJson(Map<String, dynamic> json) {
    return CreateOrderResponse(
      success: json['success'] as bool? ?? false,
      orderId: json['orderId'] as String? ?? '',
      error: json['error'] as String?,
      insufficientItems: (json['insufficientItems'] as List?)
          ?.cast<Map<String, dynamic>>(),
    );
  }
}
