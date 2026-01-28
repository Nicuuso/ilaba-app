/// Order Calculation Utilities
/// Helper functions for pricing, breakdowns, and validation
///
/// Key Rules:
/// - VAT: 12% INCLUSIVE (not added on top)
/// - Staff service fee: ₱40 per ORDER (flat)
/// - Delivery fee: ₱50 minimum, can override but not below 50
/// - Iron: minimum 2kg (skip if < 2kg)
/// - Basket weight: max 8kg (auto-create new basket if exceeded)
/// - Services are toggles (no weight multipliers except iron)

import 'package:ilaba/models/order_models.dart';

// ============================================================================
// CONSTANTS
// ============================================================================

const double TAX_RATE = 0.12; // 12% VAT
const double STAFF_SERVICE_FEE = 40.0; // Per ORDER (flat)
const double DELIVERY_FEE_DEFAULT = 50.0;
const double DELIVERY_FEE_MIN = 50.0;
const double BASKET_WEIGHT_MAX = 8.0;
const double IRON_WEIGHT_MIN = 2.0;
const double IRON_WEIGHT_MAX = 8.0;
// Default fallback prices if services not found in database
const double IRON_PRICE_PER_KG_DEFAULT = 80.0;
const double SPIN_PRICE_DEFAULT = 20.0;
const double FOLD_PRICE_DEFAULT = 0.0;
const double ADDITIONAL_DRY_TIME_PRICE_DEFAULT = 15.0; // ₱15 per 8 minutes
const double PLASTIC_BAGS_PRICE_DEFAULT = 0.50; // ₱0.50 per bag fallback

// ============================================================================
// VALIDATION RESULT CLASS
// ============================================================================

/// Detailed validation result for Step 3 (Handling)
/// Contains both overall validity status and specific missing field information
class Step3ValidationResult {
  final bool isValid;
  final String errorMessage; // Single error message (for backward compatibility)
  final List<String> missingFields; // List of missing fields for detailed display

  Step3ValidationResult({
    required this.isValid,
    required this.errorMessage,
    required this.missingFields,
  });

  /// Check if a specific field is missing
  bool isFieldMissing(String fieldName) => missingFields.contains(fieldName);

  /// Get formatted list of missing fields for display
  String getMissingFieldsDisplay() {
    if (missingFields.isEmpty) return '';
    
    final formatted = missingFields.map((field) => '• $field').join('\n');
    return 'Please complete the following fields:\n\n$formatted';
  }
}

// ============================================================================
// SERVICE PRICING HELPERS
// ============================================================================

/// Get service price from database services
/// For wash/dry, check tier to get basic or premium price
/// For spin, iron, fold - return base price
double getServicePrice(
  List<Service> services,
  String serviceType,
  String? tier,
) {
  final matching = services.where((s) => s.serviceType == serviceType).toList();

  // Return appropriate default if not found
  if (matching.isEmpty) {
    if (serviceType == 'spin') return SPIN_PRICE_DEFAULT;
    if (serviceType == 'iron') return IRON_PRICE_PER_KG_DEFAULT;
    if (serviceType == 'fold') return FOLD_PRICE_DEFAULT;
    return 0;
  }

  // For wash/dry, filter by tier
  if ((serviceType == 'wash' || serviceType == 'dry') && tier != null) {
    final tiered = matching.firstWhere(
      (s) => s.tier == tier,
      orElse: () => matching.first,
    );
    return tiered.basePrice;
  }

  // Default: return first matching service price
  return matching.first.basePrice;
}

/// Get service duration from database services
int getServiceDuration(
  List<Service> services,
  String serviceType,
  String? tier,
) {
  final matching = services.where((s) => s.serviceType == serviceType).toList();

  if (matching.isEmpty) return 0;

  // For wash/dry, filter by tier
  if ((serviceType == 'wash' || serviceType == 'dry') && tier != null) {
    final tiered = matching.firstWhere(
      (s) => s.tier == tier,
      orElse: () => matching.first,
    );
    return tiered.baseDurationMinutes ?? 0;
  }

  // Default: return first matching service duration
  return matching.first.baseDurationMinutes ?? 0;
}

// ============================================================================
// BASKET CALCULATIONS
// ============================================================================

/// Calculate subtotal for a single basket based on services selected
double calculateBasketSubtotal(
  Basket basket,
  List<Service> services,
  List<Product> products,
) {
  double total = 0;

  // Wash
  if (basket.services.wash != 'off') {
    final price = getServicePrice(services, 'wash', basket.services.wash);
    total += price;
  }

  // Dry
  if (basket.services.dry != 'off') {
    final price = getServicePrice(services, 'dry', basket.services.dry);
    total += price;
  }

  // Spin - get actual price from database
  if (basket.services.spin) {
    final spinPrice = getServicePrice(services, 'spin', null);
    total += spinPrice;
  }

  // Iron (minimum 2kg, only if weight >= 2kg)
  if (basket.services.ironWeightKg >= IRON_WEIGHT_MIN.toInt()) {
    final ironPrice = getServicePrice(services, 'iron', null);
    total += basket.services.ironWeightKg * ironPrice;
  }

  // Fold
  if (basket.services.fold) {
    final foldPrice = getServicePrice(services, 'fold', null);
    total += foldPrice;
  }

  // Additional Dry Time - ₱15 per 8 minutes
  if (basket.services.additionalDryMinutes > 0) {
    final pricePerIncrement = ADDITIONAL_DRY_TIME_PRICE_DEFAULT; // ₱15
    final minutesPerIncrement = 8;
    final increments = (basket.services.additionalDryMinutes / minutesPerIncrement).ceil();
    total += increments * pricePerIncrement;
  }

  // Plastic bags - get actual price from products database
  if (basket.services.plasticBags > 0) {
    final plasticBagProduct = products.firstWhere(
      (p) =>
          p.itemName.toLowerCase().contains('plastic') ||
          p.itemName.toLowerCase().contains('bag'),
      orElse: () => Product(
        id: 'plastic-bags',
        itemName: 'Plastic Bags',
        unitPrice: PLASTIC_BAGS_PRICE_DEFAULT,
        quantityInStock: 1000,
      ),
    );
    total += basket.services.plasticBags * plasticBagProduct.unitPrice;
  }

  return total;
}

/// Calculate estimated duration for a basket
int calculateBasketDuration(Basket basket, List<Service> services) {
  int totalMinutes = 0;

  // Wash
  if (basket.services.wash != 'off') {
    final duration = getServiceDuration(services, 'wash', basket.services.wash);
    totalMinutes += duration;
  }

  // Dry
  if (basket.services.dry != 'off') {
    final duration = getServiceDuration(services, 'dry', basket.services.dry);
    totalMinutes += duration;
  }

  // Spin
  if (basket.services.spin) {
    final duration = getServiceDuration(services, 'spin', null);
    totalMinutes += duration;
  }

  // Iron
  if (basket.services.ironWeightKg >= IRON_WEIGHT_MIN.toInt()) {
    final duration = getServiceDuration(services, 'iron', null);
    totalMinutes += duration;
  }

  // Fold
  if (basket.services.fold) {
    final duration = getServiceDuration(services, 'fold', null);
    totalMinutes += duration;
  }

  return totalMinutes;
}

// ============================================================================
// DELIVERY FEE VALIDATION
// ============================================================================

/// Validate and normalize delivery fee
/// Must be >= 50, default is 50
double validateDeliveryFee(double? fee) {
  if (fee == null) return DELIVERY_FEE_DEFAULT;
  if (fee < DELIVERY_FEE_MIN) return DELIVERY_FEE_MIN;
  return fee;
}

// ============================================================================
// VAT & FEES CALCULATION
// ============================================================================

/// Calculate VAT amount (12% inclusive)
/// VAT is already included in prices, not added on top
/// To extract VAT from a subtotal:
/// vat = subtotal * (taxRate / (1 + taxRate))
/// = subtotal * (0.12 / 1.12)
double calculateVATAmount(double subtotal) {
  return subtotal * (TAX_RATE / (1 + TAX_RATE));
}

/// Calculate staff service fee
/// ₱40 flat if any basket has services, otherwise 0
double calculateStaffServiceFee(List<Basket> baskets) {
  // Check if any basket has any service selected
  final hasServices = baskets.any(
    (basket) =>
        basket.services.wash != 'off' ||
        basket.services.dry != 'off' ||
        basket.services.spin ||
        basket.services.ironWeightKg > 0 ||
        basket.services.fold ||
        basket.services.plasticBags > 0,
  );

  return hasServices ? STAFF_SERVICE_FEE : 0;
}

// ============================================================================
// ORDER BREAKDOWN CALCULATION
// ============================================================================

/// Build complete order breakdown with all calculations
OrderBreakdown buildOrderBreakdown({
  required List<Basket> baskets,
  required List<OrderItem> items,
  required bool isDelivery,
  double? deliveryFeeOverride,
  required List<Service> services,
  required List<Product> products,
}) {
  // Calculate product subtotal
  final subtotalProducts = items.fold<double>(
    0,
    (sum, item) => sum + item.totalPrice,
  );

  // Calculate basket subtotals and update baskets
  final basketsWithSubtotals = baskets.map((basket) {
    final subtotal = calculateBasketSubtotal(basket, services, products);
    final updated = basket.copyWith(subtotal: subtotal);
    return updated;
  }).toList();

  final subtotalServices = basketsWithSubtotals.fold<double>(
    0,
    (sum, basket) => sum + basket.subtotal,
  );

  // Calculate fees
  final staffServiceFee = calculateStaffServiceFee(baskets);
  final deliveryFee = isDelivery
      ? validateDeliveryFee(deliveryFeeOverride)
      : 0.0;

  // Subtotal before VAT (includes all items, services, and fees)
  final subtotalBeforeVAT =
      subtotalProducts + subtotalServices + staffServiceFee + deliveryFee;

  // Calculate VAT (12% inclusive)
  final vatAmount = calculateVATAmount(subtotalBeforeVAT);

  // Final total
  final total = subtotalBeforeVAT;

  // Build fees array
  final feesArray = <Fee>[];
  if (staffServiceFee > 0) {
    feesArray.add(
      Fee(
        type: 'staff_service_fee',
        amount: staffServiceFee,
        description: 'Staff service fee',
      ),
    );
  }
  if (deliveryFee > 0) {
    feesArray.add(
      Fee(
        type: 'delivery_fee',
        amount: deliveryFee,
        description: 'Delivery fee',
      ),
    );
  }
  feesArray.add(
    Fee(type: 'vat', amount: vatAmount, description: 'VAT (12% inclusive)'),
  );

  final summary = OrderSummary(
    subtotalProducts: subtotalProducts,
    subtotalBaskets: subtotalServices,
    staffServiceFee: staffServiceFee,
    deliveryFee: deliveryFee,
    subtotalBeforeVat: subtotalBeforeVAT,
    vatAmount: vatAmount,
    loyaltyDiscount: 0,
    total: total,
  );

  return OrderBreakdown(
    items: items,
    baskets: basketsWithSubtotals,
    fees: feesArray,
    summary: summary,
  );
}

// ============================================================================
// IRON WEIGHT VALIDATION
// ============================================================================

/// Validate iron weight
/// - Must be 0 (off) or between 2-8 kg
/// - Skip if < 2 kg (automatically set to 0)
int normalizeIronWeight(num weight) {
  if (weight < IRON_WEIGHT_MIN) return 0; // Skip iron
  if (weight > IRON_WEIGHT_MAX) return 8;
  return weight.toInt();
}

// ============================================================================
// PAYMENT VALIDATION
// ============================================================================

/// Calculate change for cash payment
double calculateChange(double amountPaid, double total) {
  final change = amountPaid - total;
  return change >= 0 ? change : 0;
}

/// Check if amount paid is sufficient
bool isAmountSufficient(double amountPaid, double total) {
  return amountPaid >= total;
}

// ============================================================================
// LOYALTY DISCOUNT CALCULATION
// ============================================================================

/// Calculate loyalty discount based on tier
double calculateLoyaltyDiscount(double total, LoyaltyTier? tier) {
  if (tier == null) return 0;

  final percent = tier == LoyaltyTier.tier1 ? 0.05 : 0.15;
  return total * percent;
}

/// Determine loyalty tier based on points
LoyaltyTier? determineLoyaltyTier(int loyaltyPoints) {
  if (loyaltyPoints >= 20) return LoyaltyTier.tier2;
  if (loyaltyPoints >= 10) return LoyaltyTier.tier1;
  return null;
}

// ============================================================================
// TIME SLOT VALIDATION
// ============================================================================

/// Check if time slot is valid (11am-3pm)
bool isValidTimeSlot(TimeSlot? timeSlot) {
  return timeSlot != null;
}

// ============================================================================
// ADDRESS VALIDATION
// ============================================================================

/// Basic address validation (not empty)
bool isValidDeliveryAddress(String? address) {
  return address != null && address.trim().isNotEmpty;
}

// ============================================================================
// STEP VALIDATION
// ============================================================================

/// Validate Step 1: At least one basket with services configured
String? validateStep1(List<Basket> baskets) {
  if (baskets.isEmpty) {
    return 'At least one basket is required';
  }

  // Check if at least one basket has services configured
  final hasServices = baskets.any((basket) {
    final services = basket.services;
    return services.wash != 'off' ||
        services.dry != 'off' ||
        services.spin ||
        services.ironWeightKg > 0 ||
        services.fold ||
        services.plasticBags > 0;
  });

  if (!hasServices) {
    return 'Please select at least one service for your baskets';
  }

  return null; // Valid
}

/// Validate Step 2: No specific validation needed (products are optional)
String? validateStep2(List<OrderItem> items) {
  return null; // Always valid (products optional)
}

/// Validate Step 3: ALL fields required (pickup address, delivery address, reminder acknowledgement)
Step3ValidationResult validateStep3(OrderHandling handling) {
  final missingFields = <String>[];

  // Pickup address is always required
  if (!isValidDeliveryAddress(handling.pickupAddress)) {
    missingFields.add('Pickup Address');
  }

  // Delivery address is ALWAYS required
  if (!isValidDeliveryAddress(handling.deliveryAddress)) {
    missingFields.add('Delivery Address');
  }

  // Delivery reminder acknowledgement is ALWAYS required
  if (!handling.deliveryReminderAcknowledged) {
    missingFields.add('Delivery Reminder Acknowledgement');
  }

  // If there are missing fields, return invalid result
  if (missingFields.isNotEmpty) {
    final errorMsg = missingFields.length == 1
        ? '${missingFields.first} is required'
        : 'Please complete all required fields';
    
    return Step3ValidationResult(
      isValid: false,
      errorMessage: errorMsg,
      missingFields: missingFields,
    );
  }

  // All validations passed
  return Step3ValidationResult(
    isValid: true,
    errorMessage: '',
    missingFields: [],
  );
}

/// Validate Step 4: GCash receipt required, payment reference required
String? validateStep4(OrderHandling handling) {
  if (handling.gcashReceiptPath == null || handling.gcashReceiptPath!.isEmpty) {
    return 'GCash receipt upload is required';
  }

  if (handling.paymentMethod == PaymentMethod.gcash) {
    if (handling.gcashReference == null ||
        handling.gcashReference!.trim().isEmpty) {
      return 'GCash reference number is required';
    }
  }

  return null; // Valid
}
