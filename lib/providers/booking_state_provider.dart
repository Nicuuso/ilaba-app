import 'package:flutter/material.dart';
import 'package:ilaba/models/pos_types.dart';
import 'package:ilaba/services/pos_service.dart';

/// Booking state constants
const double TAX_RATE = 0.12; // 12% VAT
const double SERVICE_FEE_PER_BASKET = 10;
const double DEFAULT_DELIVERY_FEE = 50;

/// Enum for active pane in booking flow
enum BookingPane { customer, handling, products, basket, receipt }

/// Payment state
class PaymentState {
  final String method; // 'cash' or 'gcash'
  final double? amount;
  final double? amountPaid;
  final String? referenceNumber;

  PaymentState({
    this.method = 'cash',
    this.amount,
    this.amountPaid,
    this.referenceNumber,
  });

  PaymentState copyWith({
    String? method,
    double? amount,
    double? amountPaid,
    String? referenceNumber,
  }) {
    return PaymentState(
      method: method ?? this.method,
      amount: amount ?? this.amount,
      amountPaid: amountPaid ?? this.amountPaid,
      referenceNumber: referenceNumber ?? this.referenceNumber,
    );
  }
}

/// Handling/delivery state
class HandlingState {
  final bool pickup;
  final bool deliver;
  final String pickupAddress;
  final String deliveryAddress;
  final double deliveryFee;
  final String courierRef;
  final String instructions;

  HandlingState({
    this.pickup = true,
    this.deliver = false,
    this.pickupAddress = '',
    this.deliveryAddress = '',
    this.deliveryFee = DEFAULT_DELIVERY_FEE,
    this.courierRef = '',
    this.instructions = '',
  });

  HandlingState copyWith({
    bool? pickup,
    bool? deliver,
    String? pickupAddress,
    String? deliveryAddress,
    double? deliveryFee,
    String? courierRef,
    String? instructions,
  }) {
    return HandlingState(
      pickup: pickup ?? this.pickup,
      deliver: deliver ?? this.deliver,
      pickupAddress: pickupAddress ?? this.pickupAddress,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      courierRef: courierRef ?? this.courierRef,
      instructions: instructions ?? this.instructions,
    );
  }
}

/// Complete receipt/computation result
class ComputedReceipt {
  final List<ReceiptProductLine> productLines;
  final List<ReceiptBasketLine> basketLines;
  final double productSubtotal;
  final double basketSubtotal;
  final double handlingFee;
  final double taxIncluded;
  final double total;

  ComputedReceipt({
    required this.productLines,
    required this.basketLines,
    required this.productSubtotal,
    required this.basketSubtotal,
    required this.handlingFee,
    required this.taxIncluded,
    required this.total,
  });
}

/// Main booking state provider
class BookingStateNotifier extends ChangeNotifier {
  // --- Products ---
  List<Product> products = [];
  bool loadingProducts = true;

  // --- Customer ---
  Customer? customer;
  String customerQuery = '';
  List<Customer> customerSuggestions = [];

  // --- Services ---
  List<LaundryService> services = [];

  // --- Baskets ---
  List<Basket> baskets = [];
  int activeBasketIndex = 0;

  // --- Product orders ---
  Map<String, int> orderProductCounts = {};

  // --- UI State ---
  BookingPane activePane = BookingPane.customer;
  HandlingState handling = HandlingState();
  PaymentState payment = PaymentState();
  bool showConfirm = false;
  bool isProcessing = false;

  // --- Services ---
  late POSService _posService;

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
      services = await _posService.getServices();
      notifyListeners();
    } catch (e) {
      debugPrint('Service load error: $e');
      services = [];
    }
  }

  /// Load products from API
  Future<void> loadProducts() async {
    loadingProducts = true;
    notifyListeners();
    try {
      products = await _posService.getProducts();
    } catch (e) {
      debugPrint('Failed to load products: $e');
      products = [];
    }
    loadingProducts = false;
    notifyListeners();
  }

  /// Search customers
  Future<void> searchCustomers(String query) async {
    customerQuery = query;
    if (query.isEmpty) {
      customerSuggestions = [];
      notifyListeners();
      return;
    }

    try {
      customerSuggestions = await _posService.searchCustomers(query);
      notifyListeners();
    } catch (e) {
      debugPrint('Customer search error: $e');
      customerSuggestions = [];
    }
  }

  /// Select a customer
  void setCustomer(Customer? cust) {
    customer = cust;
    notifyListeners();
  }

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

  /// Calculate basket duration in minutes
  int calculateBasketDuration(Basket basket) {
    int totalMinutes = 0;

    if (basket.washCount > 0) {
      final service = getServiceByType('wash', basket.washPremium);
      if (service != null) {
        totalMinutes += service.baseDurationMinutes * basket.washCount;
      }
    }

    if (basket.dryCount > 0) {
      final service = getServiceByType('dry', basket.dryPremium);
      if (service != null) {
        totalMinutes += service.baseDurationMinutes * basket.dryCount;
      }
    }

    if (basket.spinCount > 0) {
      final service = getServiceByType('spin', false);
      if (service != null) {
        totalMinutes += service.baseDurationMinutes * basket.spinCount;
      }
    }

    if (basket.iron) {
      final service = getServiceByType('iron', false);
      if (service != null) {
        totalMinutes += service.baseDurationMinutes;
      }
    }

    if (basket.fold) {
      final service = getServiceByType('fold', false);
      if (service != null) {
        totalMinutes += service.baseDurationMinutes;
      }
    }

    return totalMinutes;
  }

  /// Compute receipt with all calculations
  ComputedReceipt computeReceipt() {
    // Product lines
    final productLines = orderProductCounts.entries.map((entry) {
      final product = products.firstWhere((p) => p.id == entry.key);
      final qty = entry.value;
      final lineTotal = product.unitPrice * qty;
      return ReceiptProductLine(
        id: entry.key,
        name: product.itemName,
        qty: qty,
        price: product.unitPrice,
        lineTotal: lineTotal,
      );
    }).toList();

    final productSubtotal =
        productLines.fold(0.0, (sum, line) => sum + line.lineTotal);

    // Basket lines
    final basketLines = baskets.map((b) {
      final weight = b.weightKg;

      final washService = getServiceByType('wash', b.washPremium);
      final washPrice = b.washCount > 0 && washService != null
          ? washService.ratePerKg * weight * b.washCount
          : 0.0;

      final dryService = getServiceByType('dry', b.dryPremium);
      final dryPrice = b.dryCount > 0 && dryService != null
          ? dryService.ratePerKg * weight * b.dryCount
          : 0.0;

      final spinService = getServiceByType('spin', false);
      final spinPrice = b.spinCount > 0 && spinService != null
          ? spinService.ratePerKg * weight * b.spinCount
          : 0.0;

      final ironService = getServiceByType('iron', false);
      final ironPrice =
          b.iron && ironService != null ? ironService.ratePerKg * weight : 0.0;

      final foldService = getServiceByType('fold', false);
      final foldPrice =
          b.fold && foldService != null ? foldService.ratePerKg * weight : 0.0;

      final subtotal = washPrice + dryPrice + spinPrice + ironPrice + foldPrice;

      return ReceiptBasketLine(
        id: b.id,
        name: b.name,
        weightKg: b.weightKg,
        breakdown: {
          'wash': washPrice,
          'dry': dryPrice,
          'spin': spinPrice,
          'iron': ironPrice,
          'fold': foldPrice,
        },
        premiumFlags: {
          'wash': b.washPremium,
          'dry': b.dryPremium,
        },
        notes: b.notes,
        total: subtotal,
        estimatedDurationMinutes: calculateBasketDuration(b),
      );
    }).toList();

    final basketSubtotal =
        basketLines.fold(0.0, (sum, line) => sum + line.total);

    // Handling fee
    final handlingFee = handling.deliver ? handling.deliveryFee : 0.0;

    final subtotalBeforeTax = productSubtotal + basketSubtotal + handlingFee;

    // VAT calculation
    final vatIncluded =
        subtotalBeforeTax * (TAX_RATE / (1 + TAX_RATE));

    return ComputedReceipt(
      productLines: productLines,
      basketLines: basketLines,
      productSubtotal: productSubtotal,
      basketSubtotal: basketSubtotal,
      handlingFee: handlingFee,
      taxIncluded: vatIncluded,
      total: subtotalBeforeTax,
    );
  }

  /// Save order to backend
  Future<String?> saveOrder() async {
    if (isProcessing) return null;
    isProcessing = true;
    notifyListeners();

    try {
      final receipt = computeReceipt();

      // Prepare order payload matching the web API format
      final orderData = {
        'customerId': customer?.id,
        'total': receipt.total,
        'baskets': baskets.map((b) {
          final serviceTypes = ['wash', 'dry', 'spin', 'iron', 'fold'];
          final premiumMap = {
            'wash': b.washPremium,
            'dry': b.dryPremium,
            'spin': false,
            'iron': false,
            'fold': false,
          };

          final basketServices = serviceTypes
              .map((type) {
                late int count;
                late bool isActive;

                switch (type) {
                  case 'wash':
                    count = b.washCount;
                    isActive = count > 0;
                  case 'dry':
                    count = b.dryCount;
                    isActive = count > 0;
                  case 'spin':
                    count = b.spinCount;
                    isActive = count > 0;
                  case 'iron':
                    isActive = b.iron;
                    count = b.iron ? 1 : 0;
                  case 'fold':
                    isActive = b.fold;
                    count = b.fold ? 1 : 0;
                  default:
                    isActive = false;
                    count = 0;
                }

                if (!isActive) return null;

                final service = getServiceByType(type, premiumMap[type] ?? false);
                if (service == null) return null;

                final subtotal = (service.ratePerKg * b.weightKg * count);

                return {
                  'service_id': service.id,
                  'rate': service.ratePerKg,
                  'subtotal': subtotal,
                };
              })
              .whereType<Map<String, dynamic>>()
              .toList();

          return {
            'machine_id': b.machineId,
            'weight': b.weightKg,
            'notes': b.notes.isNotEmpty ? b.notes : null,
            'subtotal': receipt.basketLines
                .firstWhere((bl) => bl.id == b.id, orElse: () => throw Exception('Basket not found'))
                .total,
            'services': basketServices,
          };
        }).toList(),
        'products': orderProductCounts.entries.map((entry) {
          final product = products.firstWhere((p) => p.id == entry.key);
          return {
            'product_id': entry.key,
            'quantity': entry.value,
            'unit_price': product.unitPrice,
            'subtotal': product.unitPrice * entry.value,
          };
        }).toList(),
        'payments': [
          {
            'amount': receipt.total,
            'method': payment.method,
            'reference': payment.referenceNumber,
          }
        ],
        'pickupAddress': handling.pickup ? handling.pickupAddress.isNotEmpty ? handling.pickupAddress : null : null,
        'deliveryAddress': handling.deliver ? handling.deliveryAddress.isNotEmpty ? handling.deliveryAddress : null : null,
        'shippingFee': handling.deliver ? handling.deliveryFee : 0,
      };

      // Call service to save order (will use the unified API)
      final orderId = await _posService.saveOrder(orderData);

      // Reset state
      resetBooking();

      return orderId;
    } catch (e) {
      debugPrint('Save order error: $e');
      isProcessing = false;
      notifyListeners();
      return null;
    }
  }

  /// Reset entire booking state
  void resetBooking() {
    customer = null;
    customerQuery = '';
    customerSuggestions = [];
    baskets = [_createNewBasket(0)];
    activeBasketIndex = 0;
    orderProductCounts = {};
    handling = HandlingState();
    payment = PaymentState();
    activePane = BookingPane.customer;
    showConfirm = false;
    isProcessing = false;
    notifyListeners();
  }

  /// Update handling state
  void setHandling(HandlingState newHandling) {
    handling = newHandling;
    notifyListeners();
  }

  /// Update payment state
  void setPayment(PaymentState newPayment) {
    payment = newPayment;
    notifyListeners();
  }

  /// Set active pane
  void setActivePane(BookingPane pane) {
    activePane = pane;
    notifyListeners();
  }

  /// Set active basket
  void setActiveBasketIndex(int index) {
    if (index >= 0 && index < baskets.length) {
      activeBasketIndex = index;
      notifyListeners();
    }
  }

  /// Toggle confirm dialog
  void setShowConfirm(bool show) {
    showConfirm = show;
    notifyListeners();
  }
}
