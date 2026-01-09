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

    final productSubtotal = productLines.fold(
      0.0,
      (sum, line) => sum + line.lineTotal,
    );

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
      final ironPrice = b.iron && ironService != null
          ? ironService.ratePerKg * weight
          : 0.0;

      final foldService = getServiceByType('fold', false);
      final foldPrice = b.fold && foldService != null
          ? foldService.ratePerKg * weight
          : 0.0;

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
        premiumFlags: {'wash': b.washPremium, 'dry': b.dryPremium},
        notes: b.notes,
        total: subtotal,
        estimatedDurationMinutes: calculateBasketDuration(b),
      );
    }).toList();

    final basketSubtotal = basketLines.fold(
      0.0,
      (sum, line) => sum + line.total,
    );

    // Handling fee
    final handlingFee = handling.deliver ? handling.deliveryFee : 0.0;

    final subtotalBeforeTax = productSubtotal + basketSubtotal + handlingFee;

    // VAT calculation
    final vatIncluded = subtotalBeforeTax * (TAX_RATE / (1 + TAX_RATE));

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

  /// Save order to backend with new JSON structure
  Future<String?> saveOrder() async {
    if (isProcessing) return null;
    isProcessing = true;
    notifyListeners();

    try {
      final receipt = computeReceipt();

      if (customer?.id == null) {
        throw Exception('Customer not selected');
      }

      // Build breakdown JSON structure
      final breakdownJson = {
        'items': orderProductCounts.entries.map((entry) {
          final product = products.firstWhere((p) => p.id == entry.key);
          final subtotal = product.unitPrice * entry.value;
          return {
            'id': 'item_${entry.key}_${DateTime.now().millisecondsSinceEpoch}',
            'product_id': entry.key,
            'product_name': product.itemName,
            'quantity': entry.value,
            'unit_cost': product.unitCost ?? 0,
            'unit_price': product.unitPrice,
            'subtotal': subtotal,
          };
        }).toList(),
        'baskets': baskets.map((b) {
          final basketServices = <Map<String, dynamic>>[];

          // Build services array for this basket
          final serviceTypes = {
            'wash': b.washCount,
            'dry': b.dryCount,
            'spin': b.spinCount,
            'iron': b.iron ? 1 : 0,
            'fold': b.fold ? 1 : 0,
          };

          serviceTypes.forEach((type, count) {
            if (count > 0) {
              final service = getServiceByType(
                type,
                (type == 'wash' && b.washPremium) ||
                    (type == 'dry' && b.dryPremium),
              );
              if (service != null) {
                final subtotal = service.ratePerKg * b.weightKg * count;
                basketServices.add({
                  'id':
                      'svc_${type}_${b.id}_${DateTime.now().millisecondsSinceEpoch}',
                  'service_id': service.id,
                  'service_name': service.name,
                  'is_premium':
                      (type == 'wash' && b.washPremium) ||
                      (type == 'dry' && b.dryPremium),
                  'multiplier': count,
                  'rate_per_kg': service.ratePerKg,
                  'subtotal': subtotal,
                  'status': 'pending',
                  'started_at': null,
                  'completed_at': null,
                  'completed_by': null,
                  'duration_in_minutes': null,
                });
              }
            }
          });

          final basketLine = receipt.basketLines.firstWhere(
            (bl) => bl.id == b.id,
          );

          return {
            'basket_number': baskets.indexOf(b) + 1,
            'weight': b.weightKg,
            'basket_notes': b.notes.isNotEmpty ? b.notes : null,
            'services': basketServices,
            'total': basketLine.total,
          };
        }).toList(),
        'fees': <Map<String, dynamic>>[
          if (handling.deliver)
            {
              'id': 'fee_delivery_${DateTime.now().millisecondsSinceEpoch}',
              'type': 'handling_fee',
              'description': 'Delivery Fee',
              'amount': handling.deliveryFee,
            },
        ],
        'discounts': <Map<String, dynamic>>[],
        'summary': {
          'subtotal_products': receipt.productSubtotal,
          'subtotal_services': receipt.basketSubtotal,
          'handling': handling.deliver ? handling.deliveryFee : 0,
          'service_fee': 0,
          'discounts': 0,
          'vat_rate': 0.12,
          'vat_amount': receipt.taxIncluded,
          'vat_model': 'inclusive',
          'grand_total': receipt.total,
        },
        'payment': {
          'method': payment.method,
          'amount_paid': receipt.total,
          'change': 0,
          'reference_number': payment.referenceNumber,
          'payment_status': 'successful',
          'completed_at': DateTime.now().toIso8601String(),
        },
        'audit_log': <Map<String, dynamic>>[
          {
            'action': 'created',
            'timestamp': DateTime.now().toIso8601String(),
            'changed_by': null, // Mobile app - no staff user
            'details': {'source': 'mobile_app'},
          },
        ],
      };

      // Build handling JSON structure
      final handlingJson = {
        'pickup': {
          'address': handling.pickupAddress.isNotEmpty
              ? handling.pickupAddress
              : null,
          'latitude': null,
          'longitude': null,
          'notes': handling.instructions.isNotEmpty
              ? handling.instructions
              : null,
          'status': 'pending',
          'started_at': null,
          'completed_at': null,
          'completed_by': null,
          'duration_in_minutes': null,
        },
        'delivery': handling.deliver
            ? {
                'address': handling.deliveryAddress.isNotEmpty
                    ? handling.deliveryAddress
                    : null,
                'latitude': null,
                'longitude': null,
                'notes': null,
                'status': 'pending',
                'started_at': null,
                'completed_at': null,
                'completed_by': null,
                'duration_in_minutes': null,
              }
            : null,
      };

      // Build final order payload matching new schema
      final orderData = {
        'source': 'app',
        'customer_id': customer!.id,
        'cashier_id': null, // Mobile orders don't have cashier
        'status': 'pending',
        'total_amount': receipt.total,
        'order_note': handling.instructions.isNotEmpty
            ? handling.instructions
            : null,
        'handling': handlingJson,
        'breakdown': breakdownJson,
        'cancellation': null,
      };

      debugPrint('📦 Saving order with structure: ${orderData.toString()}');

      // Call service to save order
      final orderId = await _posService.saveOrder(orderData);

      debugPrint('✅ Order saved successfully: $orderId');
      resetBooking();

      return orderId;
    } catch (e) {
      debugPrint('❌ Save order error: $e');
      isProcessing = false;
      notifyListeners();
      rethrow;
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
