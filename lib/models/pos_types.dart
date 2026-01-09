class Product {
  final String id;
  final String itemName;
  final double unitPrice;
  final double quantity;
  final double? reorderLevel;
  final double? unitCost;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? lastUpdated;

  Product({
    required this.id,
    required this.itemName,
    required this.unitPrice,
    this.quantity = 0,
    this.reorderLevel = 0,
    this.unitCost = 0,
    this.isActive = true,
    this.createdAt,
    this.lastUpdated,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] ?? '',
      itemName: json['item_name'] ?? '',
      unitPrice: (json['unit_price'] ?? 0).toDouble(),
      quantity: (json['quantity'] ?? 0).toDouble(),
      reorderLevel: json['reorder_level'] != null
          ? (json['reorder_level'] as num).toDouble()
          : 0,
      unitCost: json['unit_cost'] != null
          ? (json['unit_cost'] as num).toDouble()
          : 0,
      isActive: json['is_active'] ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      lastUpdated: json['last_updated'] != null
          ? DateTime.parse(json['last_updated'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'item_name': itemName,
      'unit_price': unitPrice,
      'quantity': quantity,
      'reorder_level': reorderLevel,
      'unit_cost': unitCost,
      'is_active': isActive,
      'created_at': createdAt?.toIso8601String(),
      'last_updated': lastUpdated?.toIso8601String(),
    };
  }
}

class Customer {
  final String? id;
  final String? firstName;
  final String? middleName;
  final String? lastName;
  final String? birthdate;
  final String? gender;
  final String? phoneNumber;
  final String? emailAddress;
  final String? address;

  Customer({
    this.id,
    this.firstName,
    this.middleName,
    this.lastName,
    this.birthdate,
    this.gender,
    this.phoneNumber,
    this.emailAddress,
    this.address,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'],
      firstName: json['first_name'],
      middleName: json['middle_name'],
      lastName: json['last_name'],
      birthdate: json['birthdate'],
      gender: json['gender'],
      phoneNumber: json['phone_number'],
      emailAddress: json['email_address'],
      address: json['address'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (firstName != null) 'first_name': firstName,
      if (middleName != null) 'middle_name': middleName,
      if (lastName != null) 'last_name': lastName,
      if (birthdate != null) 'birthdate': birthdate,
      if (gender != null) 'gender': gender,
      if (phoneNumber != null) 'phone_number': phoneNumber,
      if (emailAddress != null) 'email_address': emailAddress,
      if (address != null) 'address': address,
    };
  }

  String getDisplayName() {
    final parts = [
      firstName,
      lastName,
    ].where((part) => part != null && part.isNotEmpty).toList();
    return parts.isNotEmpty ? parts.join(' ') : 'Unknown Customer';
  }
}

class Basket {
  final String id;
  final String name;
  final int originalIndex;
  final String? machineId;
  double weightKg;
  int washCount;
  int dryCount;
  int spinCount;
  bool washPremium;
  bool dryPremium;
  bool iron;
  bool fold;
  String notes;

  Basket({
    required this.id,
    required this.name,
    required this.originalIndex,
    this.machineId,
    this.weightKg = 0,
    this.washCount = 0,
    this.dryCount = 0,
    this.spinCount = 0,
    this.washPremium = false,
    this.dryPremium = false,
    this.iron = false,
    this.fold = false,
    this.notes = '',
  });

  Basket copyWith({
    String? id,
    String? name,
    int? originalIndex,
    String? machineId,
    double? weightKg,
    int? washCount,
    int? dryCount,
    int? spinCount,
    bool? washPremium,
    bool? dryPremium,
    bool? iron,
    bool? fold,
    String? notes,
  }) {
    return Basket(
      id: id ?? this.id,
      name: name ?? this.name,
      originalIndex: originalIndex ?? this.originalIndex,
      machineId: machineId ?? this.machineId,
      weightKg: weightKg ?? this.weightKg,
      washCount: washCount ?? this.washCount,
      dryCount: dryCount ?? this.dryCount,
      spinCount: spinCount ?? this.spinCount,
      washPremium: washPremium ?? this.washPremium,
      dryPremium: dryPremium ?? this.dryPremium,
      iron: iron ?? this.iron,
      fold: fold ?? this.fold,
      notes: notes ?? this.notes,
    );
  }
}

class ReceiptBasketLine {
  final String id;
  final String name;
  final double weightKg;
  final Map<String, double> breakdown;
  final Map<String, bool> premiumFlags;
  final String notes;
  final double total;
  final int estimatedDurationMinutes;

  ReceiptBasketLine({
    required this.id,
    required this.name,
    required this.weightKg,
    required this.breakdown,
    required this.premiumFlags,
    required this.notes,
    required this.total,
    required this.estimatedDurationMinutes,
  });
}

class ReceiptProductLine {
  final String id;
  final String name;
  final int qty;
  final double price;
  final double lineTotal;

  ReceiptProductLine({
    required this.id,
    required this.name,
    required this.qty,
    required this.price,
    required this.lineTotal,
  });
}

class LaundryService {
  final String id;
  final String serviceType;
  final String name;
  final String? description;
  final int baseDurationMinutes;
  final double ratePerKg;
  final bool isActive;

  LaundryService({
    required this.id,
    required this.serviceType,
    required this.name,
    this.description,
    required this.baseDurationMinutes,
    required this.ratePerKg,
    required this.isActive,
  });

  factory LaundryService.fromJson(Map<String, dynamic> json) {
    return LaundryService(
      id: json['id'] ?? '',
      serviceType: json['service_type'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      baseDurationMinutes: json['base_duration_minutes'] ?? 0,
      ratePerKg: (json['rate_per_kg'] ?? 0).toDouble(),
      isActive: json['is_active'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'service_type': serviceType,
      'name': name,
      'description': description,
      'base_duration_minutes': baseDurationMinutes,
      'rate_per_kg': ratePerKg,
      'is_active': isActive,
    };
  }
}

class Payment {
  final String method; // 'cash' or 'gcash'
  final double? amount;
  final double? amountPaid;
  final String? referenceNumber;

  Payment({
    required this.method,
    this.amount,
    this.amountPaid,
    this.referenceNumber,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      method: json['method'] ?? 'cash',
      amount: json['amount']?.toDouble(),
      amountPaid: json['amountPaid']?.toDouble(),
      referenceNumber: json['reference_number'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'method': method,
      if (amount != null) 'amount': amount,
      if (amountPaid != null) 'amountPaid': amountPaid,
      if (referenceNumber != null) 'reference_number': referenceNumber,
    };
  }
}

class Receipt {
  final List<ReceiptProductLine> productLines;
  final List<ReceiptBasketLine> basketLines;
  final double productSubtotal;
  final double basketSubtotal;
  final double handlingFee;
  final double taxIncluded;
  final double total;

  Receipt({
    required this.productLines,
    required this.basketLines,
    required this.productSubtotal,
    required this.basketSubtotal,
    required this.handlingFee,
    required this.taxIncluded,
    required this.total,
  });
}
