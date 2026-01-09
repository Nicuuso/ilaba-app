class OrderHandling {
  final Map<String, dynamic>? pickup;
  final Map<String, dynamic>? delivery;

  OrderHandling({this.pickup, this.delivery});

  factory OrderHandling.fromJson(Map<String, dynamic> json) {
    return OrderHandling(
      pickup: json['pickup'] as Map<String, dynamic>?,
      delivery: json['delivery'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (pickup != null) 'pickup': pickup,
      if (delivery != null) 'delivery': delivery,
    };
  }
}

class OrderBreakdown {
  final List<Map<String, dynamic>>? baskets;
  final List<Map<String, dynamic>>? addons;
  final double? subtotal;
  final double? handlingFee;
  final double? tax;
  final double? total;

  OrderBreakdown({
    this.baskets,
    this.addons,
    this.subtotal,
    this.handlingFee,
    this.tax,
    this.total,
  });

  factory OrderBreakdown.fromJson(Map<String, dynamic> json) {
    return OrderBreakdown(
      baskets: (json['baskets'] as List<dynamic>?)
          ?.map((e) => e as Map<String, dynamic>)
          .toList(),
      addons: (json['addons'] as List<dynamic>?)
          ?.map((e) => e as Map<String, dynamic>)
          .toList(),
      subtotal: (json['subtotal'] as num?)?.toDouble(),
      handlingFee: (json['handling_fee'] as num?)?.toDouble(),
      tax: (json['tax'] as num?)?.toDouble(),
      total: (json['total'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (baskets != null) 'baskets': baskets,
      if (addons != null) 'addons': addons,
      if (subtotal != null) 'subtotal': subtotal,
      if (handlingFee != null) 'handling_fee': handlingFee,
      if (tax != null) 'tax': tax,
      if (total != null) 'total': total,
    };
  }
}

class BookingService {
  final String name;
  final int quantity;
  final bool isPremium;

  BookingService({
    required this.name,
    required this.quantity,
    required this.isPremium,
  });

  factory BookingService.fromJson(Map<String, dynamic> json) {
    return BookingService(
      name: json['name'] as String,
      quantity: json['quantity'] as int,
      isPremium: json['is_premium'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {'name': name, 'quantity': quantity, 'is_premium': isPremium};
  }
}

class Booking {
  final String id;
  final String source; // 'app' or 'store'
  final String customerId;
  final String? cashierId;
  final String
  status; // pending, for_pick-up, processing, for_delivery, completed, cancelled
  final int weightKg;
  final List<BookingService> services;
  final List<String> addOns; // fold, iron, eco_bag, etc.
  final String pickupAddress;
  final String? deliveryAddress;
  final DateTime pickupDate;
  final DateTime? deliveryDate;
  final double totalPrice;
  final String paymentMethod; // cash, card, online
  final String? notes;
  final DateTime createdAt;
  final DateTime? approvedAt;
  final DateTime? completedAt;
  final DateTime? cancelledAt;
  final OrderHandling? handling;
  final OrderBreakdown? breakdown;
  final Map<String, dynamic>? cancellation;

  Booking({
    required this.id,
    this.source = 'app',
    required this.customerId,
    this.cashierId,
    required this.status,
    required this.weightKg,
    required this.services,
    required this.addOns,
    required this.pickupAddress,
    this.deliveryAddress,
    required this.pickupDate,
    this.deliveryDate,
    required this.totalPrice,
    required this.paymentMethod,
    this.notes,
    required this.createdAt,
    this.approvedAt,
    this.completedAt,
    this.cancelledAt,
    this.handling,
    this.breakdown,
    this.cancellation,
  });

  // Keep old userId property for backwards compatibility
  String get userId => customerId;

  factory Booking.fromJson(Map<String, dynamic> json) {
    // Handle both old field names (user_id) and new field names (customer_id) for backwards compatibility
    final customerId =
        json['customer_id'] as String? ?? json['user_id'] as String;

    return Booking(
      id: json['id'] as String,
      source: json['source'] as String? ?? 'app',
      customerId: customerId,
      cashierId: json['cashier_id'] as String?,
      status: json['status'] as String,
      weightKg: json['weight_kg'] as int? ?? 0,
      services:
          (json['services'] as List<dynamic>?)
              ?.map((s) => BookingService.fromJson(s as Map<String, dynamic>))
              .toList() ??
          [],
      addOns: List<String>.from(
        json['add_ons'] as List<dynamic>? ??
            json['addons'] as List<dynamic>? ??
            [],
      ),
      pickupAddress: json['pickup_address'] as String? ?? '',
      deliveryAddress: json['delivery_address'] as String?,
      pickupDate: json['pickup_date'] != null
          ? DateTime.parse(json['pickup_date'] as String)
          : DateTime.now(),
      deliveryDate: json['delivery_date'] != null
          ? DateTime.parse(json['delivery_date'] as String)
          : null,
      totalPrice:
          (json['total_amount'] as num? ?? json['total_price'] as num? ?? 0)
              .toDouble(),
      paymentMethod: json['payment_method'] as String? ?? 'cash',
      notes: json['order_note'] as String? ?? json['notes'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      approvedAt: json['approved_at'] != null
          ? DateTime.parse(json['approved_at'] as String)
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      cancelledAt: json['cancelled_at'] != null
          ? DateTime.parse(json['cancelled_at'] as String)
          : null,
      handling: json['handling'] != null
          ? OrderHandling.fromJson(json['handling'] as Map<String, dynamic>)
          : null,
      breakdown: json['breakdown'] != null
          ? OrderBreakdown.fromJson(json['breakdown'] as Map<String, dynamic>)
          : null,
      cancellation: json['cancellation'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'source': source,
      'customer_id': customerId,
      'cashier_id': cashierId,
      'status': status,
      'weight_kg': weightKg,
      'services': services.map((s) => s.toJson()).toList(),
      'addons': addOns,
      'pickup_address': pickupAddress,
      'delivery_address': deliveryAddress,
      'pickup_date': pickupDate.toIso8601String(),
      'delivery_date': deliveryDate?.toIso8601String(),
      'total_amount': totalPrice,
      'payment_method': paymentMethod,
      'order_note': notes,
      'created_at': createdAt.toIso8601String(),
      'approved_at': approvedAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'cancelled_at': cancelledAt?.toIso8601String(),
      'handling': handling?.toJson(),
      'breakdown': breakdown?.toJson(),
      'cancellation': cancellation,
    };
  }

  Booking copyWith({
    String? id,
    String? source,
    String? customerId,
    String? cashierId,
    String? status,
    int? weightKg,
    List<BookingService>? services,
    List<String>? addOns,
    String? pickupAddress,
    String? deliveryAddress,
    DateTime? pickupDate,
    DateTime? deliveryDate,
    double? totalPrice,
    String? paymentMethod,
    String? notes,
    DateTime? createdAt,
    DateTime? approvedAt,
    DateTime? completedAt,
    DateTime? cancelledAt,
    OrderHandling? handling,
    OrderBreakdown? breakdown,
    Map<String, dynamic>? cancellation,
  }) {
    return Booking(
      id: id ?? this.id,
      source: source ?? this.source,
      customerId: customerId ?? this.customerId,
      cashierId: cashierId ?? this.cashierId,
      status: status ?? this.status,
      weightKg: weightKg ?? this.weightKg,
      services: services ?? this.services,
      addOns: addOns ?? this.addOns,
      pickupAddress: pickupAddress ?? this.pickupAddress,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      pickupDate: pickupDate ?? this.pickupDate,
      deliveryDate: deliveryDate ?? this.deliveryDate,
      totalPrice: totalPrice ?? this.totalPrice,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      approvedAt: approvedAt ?? this.approvedAt,
      completedAt: completedAt ?? this.completedAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      handling: handling ?? this.handling,
      breakdown: breakdown ?? this.breakdown,
      cancellation: cancellation ?? this.cancellation,
    );
  }
}
