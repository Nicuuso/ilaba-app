import 'package:flutter/material.dart';
import 'package:ilaba/models/pos_types.dart';
import 'package:ilaba/services/pos_service.dart';

/// Booking state constants
const double TAX_RATE = 0.12; // 12% VAT
const double SERVICE_FEE_PER_BASKET = 40; // PHP 40
const double DEFAULT_DELIVERY_FEE = 50; // PHP 50

/// Enum for active pane in booking flow
enum BookingPane { handling, basket, products, receipt }

/// Simplified handling state for mobile app
class HandlingState {
  final bool pickup;
  final bool deliver;
  final String pickupAddress;
  final String deliveryAddress;
  final String instructions;

  HandlingState({
    this.pickup = true,
    this.deliver = false,
    this.pickupAddress = '',
    this.deliveryAddress = '',
    this.instructions = '',
  });

  HandlingState copyWith({
    bool? pickup,
    bool? deliver,
    String? pickupAddress,
    String? deliveryAddress,
    String? instructions,
  }) {
    return HandlingState(
      pickup: pickup ?? this.pickup,
      deliver: deliver ?? this.deliver,
      pickupAddress: pickupAddress ?? this.pickupAddress,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      instructions: instructions ?? this.instructions,
    );
  }
}

/// Simplified receipt for display
class ReceiptSummary {
  final double productSubtotal;
  final double basketSubtotal;
  final double serviceFee;
  final double handlingFee;
  final double tax;
  final double total;
  final List<ReceiptProductLine> productLines;
  final List<ReceiptBasketLine> basketLines;
  final int loyaltyPoints;
  final int loyaltyPointsUsed;
  final double loyaltyDiscountAmount;
  final int loyaltyDiscountPercentage;

  ReceiptSummary({
    required this.productSubtotal,
    required this.basketSubtotal,
    required this.serviceFee,
    required this.handlingFee,
    required this.tax,
    required this.total,
    required this.productLines,
    required this.basketLines,
    this.loyaltyPoints = 0,
    this.loyaltyPointsUsed = 0,
    this.loyaltyDiscountAmount = 0,
    this.loyaltyDiscountPercentage = 0,
  });
}

/// Main booking state provider - REFACTORED FOR WEB API COMPATIBILITY
class BookingStateNotifier extends ChangeNotifier {
  // --- Products ---
  List<Product> products = [];
  bool loadingProducts = true;

  // --- Customer (pre-authenticated from auth provider) ---
  Customer? customer;

  // --- Services ---
  List<LaundryService> services = [];

  // --- Baskets ---
  List<Basket> baskets = [];
  int activeBasketIndex = 0;

  // --- Product orders ---
  Map<String, int> orderProductCounts = {};

  // --- Loyalty System ---
  int loyaltyPointsBalance = 0; // Customer's current points balance
  int loyaltyPointsUsed = 0; // Points selected for this order (0, 10, or 20)
  double loyaltyDiscountAmount = 0; // Calculated discount in PHP
  int loyaltyDiscountPercentage = 0; // Discount % (10 or 15)
  bool loyaltyToggleEnabled = false; // User toggled discount ON/OFF

  // --- UI State ---
  HandlingState handling = HandlingState();
  bool isProcessing = false;
  String? gcashReceiptUrl; // URL of uploaded GCash receipt

  // --- Services ---
  late final POSService _posService;

  BookingStateNotifier(this._posService) {
    _initialize();
  }

  Future<void> _initialize() async {
    await loadServices();
    await loadProducts();
    baskets = [_createNewBasket(0)];
    notifyListeners();
  }

  /// Create a new basket
  Basket _createNewBasket(int index) {
    return Basket(
      id: 'b${DateTime.now().millisecondsSinceEpoch}$index',
      name: 'Basket ${index + 1}',
      originalIndex: index + 1,
      machineId: null,
      weightKg: 0,
      washCount: 0,
      dryCount: 0,
      spinCount: 0,
      washPremium: false,
      dryPremium: false,
      iron: false,
      fold: false,
      notes: '',
    );
  }

  /// Load laundry services from API
  Future<void> loadServices() async {
    try {
      debugPrint('🧹 BookingStateNotifier: Loading laundry services...');
      services = await _posService.getServices();
      debugPrint(
        '✅ BookingStateNotifier: Loaded ${services.length} active services',
      );
      for (var service in services) {
        debugPrint(
          '   - ${service.name} (${service.serviceType}): ₱${service.ratePerKg}/kg, Active: ${service.isActive}',
        );
      }
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Service load error: $e');
      services = [];
    }
  }

  /// Load products from API
  Future<void> loadProducts() async {
    loadingProducts = true;
    notifyListeners();
    try {
      debugPrint('📦 BookingStateNotifier: Loading products...');
      products = await _posService.getProducts();
      debugPrint(
        '✅ BookingStateNotifier: Loaded ${products.length} active products',
      );
      for (var product in products) {
        debugPrint(
          '   - ${product.itemName}: ₱${product.unitPrice}, Qty: ${product.quantity}, Active: ${product.isActive}',
        );
      }
    } catch (e) {
      debugPrint('❌ Failed to load products: $e');
      products = [];
    }
    loadingProducts = false;
    notifyListeners();
  }

  /// Set customer (called from auth context)
  void setCustomer(Customer? cust) {
    customer = cust;
    // Reset loyalty when customer changes
    resetLoyaltyState();
    notifyListeners();
  }

  // ============================================================================
  // LOYALTY MANAGEMENT
  // ============================================================================

  /// Set customer's loyalty points balance (fetched from API)
  void setLoyaltyPointsBalance(int points) {
    loyaltyPointsBalance = points;
    notifyListeners();
  }

  /// Calculate and apply loyalty discount
  void applyLoyaltyDiscount(int pointsToUse) {
    if (pointsToUse == 0) {
      resetLoyaltyState();
      return;
    }

    // Validate points
    if (pointsToUse != 10 && pointsToUse != 20) {
      debugPrint('❌ Invalid loyalty points: $pointsToUse (must be 10 or 20)');
      return;
    }

    if (pointsToUse > loyaltyPointsBalance) {
      debugPrint(
        '❌ Not enough loyalty points: have $loyaltyPointsBalance, need $pointsToUse',
      );
      return;
    }

    // Calculate discount
    final receipt = computeReceipt();
    final baseTotal = receipt.total; // Final total
    final percentage = pointsToUse == 10 ? 10 : 15;
    final discountAmount = baseTotal * (percentage / 100);

    loyaltyPointsUsed = pointsToUse;
    loyaltyDiscountPercentage = percentage;
    loyaltyDiscountAmount = discountAmount;
    loyaltyToggleEnabled = true;

    debugPrint(
      '✅ Loyalty discount applied: $pointsToUse points = $percentage% off = ₱${discountAmount.toStringAsFixed(2)}',
    );
    notifyListeners();
  }

  /// Toggle loyalty discount on/off
  void toggleLoyaltyDiscount() {
    if (!loyaltyToggleEnabled) {
      // If enabled points selected, use 20-point tier by default
      if (loyaltyPointsBalance >= 20) {
        applyLoyaltyDiscount(20);
      } else if (loyaltyPointsBalance >= 10) {
        applyLoyaltyDiscount(10);
      }
    } else {
      resetLoyaltyState();
    }
  }

  /// Reset loyalty state for new order
  void resetLoyaltyState() {
    loyaltyPointsUsed = 0;
    loyaltyDiscountAmount = 0;
    loyaltyDiscountPercentage = 0;
    loyaltyToggleEnabled = false;
    notifyListeners();
  }

  /// Get available loyalty tiers for UI display
  Map<int, int> getAvailableLoyaltyTiers() {
    final tiers = <int, int>{}; // points -> percentage
    if (loyaltyPointsBalance >= 20) {
      tiers[20] = 15; // Best deal
    }
    if (loyaltyPointsBalance >= 10) {
      tiers[10] = 10;
    }
    return tiers;
  }

  /// Get final total with loyalty discount applied
  double getFinalTotalWithLoyalty() {
    final receipt = computeReceipt();
    if (loyaltyToggleEnabled && loyaltyPointsUsed > 0) {
      return receipt.total - loyaltyDiscountAmount;
    }
    return receipt.total;
  }

  // ============================================================================
  // PRODUCT MANAGEMENT
  // ============================================================================

  /// Add product to order
  void addProduct(String productId) {
    orderProductCounts[productId] = (orderProductCounts[productId] ?? 0) + 1;
    notifyListeners();
  }

  /// Remove product from order
  void removeProduct(String productId) {
    final current = orderProductCounts[productId] ?? 0;
    if (current <= 1) {
      orderProductCounts.remove(productId);
    } else {
      orderProductCounts[productId] = current - 1;
    }
    notifyListeners();
  }

  /// Set product quantity
  void setProductQuantity(String productId, int quantity) {
    if (quantity <= 0) {
      orderProductCounts.remove(productId);
    } else {
      orderProductCounts[productId] = quantity;
    }
    notifyListeners();
  }

  // ============================================================================
  // BASKET MANAGEMENT
  // ============================================================================

  /// Add a new basket
  void addBasket() {
    baskets.add(_createNewBasket(baskets.length));
    notifyListeners();
  }

  /// Delete a basket
  void deleteBasket(int index) {
    if (baskets.length <= 1) return;
    baskets.removeAt(index);
    if (activeBasketIndex >= baskets.length) {
      activeBasketIndex = baskets.length - 1;
    }
    notifyListeners();
  }

  /// Update active basket
  void updateActiveBasket(Basket updatedBasket) {
    if (activeBasketIndex < baskets.length) {
      baskets[activeBasketIndex] = updatedBasket;
      notifyListeners();
    }
  }

  /// Set active basket by index
  void setActiveBasketIndex(int index) {
    if (index >= 0 && index < baskets.length) {
      activeBasketIndex = index;
      notifyListeners();
    }
  }

  // ============================================================================
  // HANDLING MANAGEMENT
  // ============================================================================

  /// Update handling state
  void setHandling(HandlingState newHandling) {
    // Auto-enable deliver flag if delivery address is provided
    final deliver = newHandling.deliveryAddress.isNotEmpty;
    handling = newHandling.copyWith(deliver: deliver);
    notifyListeners();
  }

  // ============================================================================
  // VALIDATION & CALCULATIONS
  // ============================================================================

  /// Check if handling is valid (at least one method selected with address)
  bool isHandlingValid() {
    final hasPickup = handling.pickup && handling.pickupAddress.isNotEmpty;
    final hasDelivery = handling.deliver && handling.deliveryAddress.isNotEmpty;
    return hasPickup || hasDelivery;
  }

  /// Check if at least one basket has services
  bool hasActiveBaskets() {
    return baskets.any(
      (b) =>
          b.weightKg > 0 &&
          (b.washCount > 0 ||
              b.dryCount > 0 ||
              b.spinCount > 0 ||
              b.iron ||
              b.fold),
    );
  }

  /// Check if there are any products selected
  bool hasProducts() {
    return orderProductCounts.isNotEmpty;
  }

  // ============================================================================
  // RECEIPT COMPUTATION (FOR DISPLAY ONLY)
  // ============================================================================

  /// Compute receipt summary for display
  ReceiptSummary computeReceipt() {
    final productLines = <ReceiptProductLine>[];
    double productSubtotal = 0;

    for (final entry in orderProductCounts.entries) {
      final product = products.firstWhere(
        (p) => p.id == entry.key,
        orElse: () => Product(id: entry.key, itemName: 'Unknown', unitPrice: 0),
      );

      final lineTotal = product.unitPrice * entry.value;
      productSubtotal += lineTotal;

      productLines.add(
        ReceiptProductLine(
          id: product.id,
          name: product.itemName,
          qty: entry.value,
          price: product.unitPrice,
          lineTotal: lineTotal,
        ),
      );
    }

    final basketLines = <ReceiptBasketLine>[];
    double basketSubtotal = 0;
    int estimatedDuration = 0;

    for (final basket in baskets) {
      if (basket.weightKg <= 0) continue;

      final breakdown = <String, double>{};
      double basketTotal = 0;

      if (basket.washCount > 0) {
        final service = getServiceByType('wash', basket.washPremium);
        if (service != null) {
          final amount = basket.weightKg * service.ratePerKg * basket.washCount;
          breakdown['wash'] = amount;
          basketTotal += amount;
          estimatedDuration += service.baseDurationMinutes * basket.washCount;
        }
      }

      if (basket.dryCount > 0) {
        final service = getServiceByType('dry', basket.dryPremium);
        if (service != null) {
          final amount = basket.weightKg * service.ratePerKg * basket.dryCount;
          breakdown['dry'] = amount;
          basketTotal += amount;
          estimatedDuration += service.baseDurationMinutes * basket.dryCount;
        }
      }

      if (basket.spinCount > 0) {
        final service = getServiceByType('spin', false);
        if (service != null) {
          final amount = basket.weightKg * service.ratePerKg * basket.spinCount;
          breakdown['spin'] = amount;
          basketTotal += amount;
          estimatedDuration += service.baseDurationMinutes * basket.spinCount;
        }
      }

      if (basket.iron) {
        final service = getServiceByType('iron', false);
        if (service != null) {
          final amount = basket.weightKg * service.ratePerKg;
          breakdown['iron'] = amount;
          basketTotal += amount;
          estimatedDuration += service.baseDurationMinutes;
        }
      }

      if (basket.fold) {
        final service = getServiceByType('fold', false);
        if (service != null) {
          final amount = basket.weightKg * service.ratePerKg;
          breakdown['fold'] = amount;
          basketTotal += amount;
          estimatedDuration += service.baseDurationMinutes;
        }
      }

      if (basketTotal > 0) {
        basketSubtotal += basketTotal;
        basketLines.add(
          ReceiptBasketLine(
            id: basket.id,
            name: basket.name,
            weightKg: basket.weightKg,
            breakdown: breakdown,
            premiumFlags: {
              'wash': basket.washPremium,
              'dry': basket.dryPremium,
            },
            notes: basket.notes,
            total: basketTotal,
            estimatedDurationMinutes: estimatedDuration,
          ),
        );
      }
    }

    final serviceFee = basketLines.isNotEmpty ? SERVICE_FEE_PER_BASKET : 0;
    final handlingFee = handling.deliver ? DEFAULT_DELIVERY_FEE : 0;
    final subtotalBeforeTax =
        productSubtotal + basketSubtotal + serviceFee + handlingFee;
    final tax = subtotalBeforeTax * (TAX_RATE / (1 + TAX_RATE));
    final total = subtotalBeforeTax;

    return ReceiptSummary(
      productSubtotal: productSubtotal,
      basketSubtotal: basketSubtotal,
      serviceFee: serviceFee.toDouble(),
      handlingFee: handlingFee.toDouble(),
      tax: tax,
      total: total,
      productLines: productLines,
      basketLines: basketLines,
      loyaltyPoints: loyaltyPointsBalance,
      loyaltyPointsUsed: loyaltyPointsUsed,
      loyaltyDiscountAmount: loyaltyDiscountAmount,
      loyaltyDiscountPercentage: loyaltyDiscountPercentage,
    );
  }

  /// Get service by type and premium flag
  LaundryService? getServiceByType(String type, bool premium) {
    final matches = services.where((s) => s.serviceType == type).toList();
    if (matches.isEmpty) return null;

    if (premium) {
      return matches.firstWhere(
        (s) => s.name.toLowerCase().contains('premium'),
        orElse: () => matches.first,
      );
    }

    return matches.firstWhere(
      (s) => !s.name.toLowerCase().contains('premium'),
      orElse: () => matches.first,
    );
  }

  // ============================================================================
  // RESET FOR NEW ORDER
  // ============================================================================

  /// Clear all booking state for a new order
  void resetForNewOrder() {
    orderProductCounts.clear();
    baskets = [_createNewBasket(0)];
    activeBasketIndex = 0;
    handling = HandlingState(
      pickup: true,
      pickupAddress: customer?.address ?? '',
    );
    gcashReceiptUrl = null; // Clear receipt
    resetLoyaltyState(); // Clear loyalty selections
    notifyListeners();
  }

  /// Set the GCash receipt URL after upload
  void setGCashReceiptUrl(String url) {
    gcashReceiptUrl = url;
    notifyListeners();
  }

  /// Clear the GCash receipt URL
  void clearGCashReceipt() {
    gcashReceiptUrl = null;
    notifyListeners();
  }
}
