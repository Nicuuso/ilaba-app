/// Mobile Booking State Provider
/// Manages complete state for 4-step booking flow
///
/// Handles:
/// - Loading services and products
/// - Managing baskets and services selection
/// - Managing products selection
/// - Handling selection and time slots
/// - GCash receipt upload
/// - Loyalty discount
/// - Order submission
/// - Real-time calculations

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:ilaba/models/order_models.dart';
import 'package:ilaba/models/user.dart' as user_model;
import 'package:ilaba/services/gcash_receipt_service.dart';
import 'package:ilaba/services/loyalty_service.dart';
import 'package:ilaba/services/mobile_order_service.dart';
import 'package:ilaba/services/products_repository.dart';
import 'package:ilaba/services/services_repository.dart';
import 'package:ilaba/utils/order_calculations.dart';

/// Create new basket with default services
Basket createNewBasket(int basketNumber) {
  return Basket(
    basketNumber: basketNumber,
    weightKg: 0,
    services: BasketServices(),
    notes: '',
  );
}

class MobileBookingProvider extends ChangeNotifier {
  // Services
  final ServicesRepository servicesRepository;
  final ProductsRepository productsRepository;
  final MobileOrderService mobileOrderService;
  final GCashReceiptService gcashReceiptService;
  final LoyaltyService loyaltyService;

  // State - Step 1: Baskets
  List<Basket> _baskets = [createNewBasket(1)];
  int _activeBasketIndex = 0;
  List<Service> _services = [];

  // State - Step 2: Products
  Map<String, int> _selectedProducts = {}; // productId -> quantity
  List<Product> _products = [];

  // State - Step 3: Handling
  HandlingType _handlingType = HandlingType.pickup;
  String _pickupAddress = '';
  String _deliveryAddress = '';
  bool _deliveryReminderAcknowledged = false;
  TimeSlot? _timeSlot;
  String _specialInstructions = '';

  // State - Step 4: Payment & Loyalty
  String _gcashReference = '';
  String? _gcashReceiptPath;
  int _loyaltyPoints = 0;
  LoyaltyTier? _selectedLoyaltyTier;

  // Metadata
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _errorMessage;
  user_model.User? _currentUser;

  MobileBookingProvider({
    required this.servicesRepository,
    required this.productsRepository,
    required this.mobileOrderService,
    required this.gcashReceiptService,
    required this.loyaltyService,
  }) {
    _initialize();
  }

  // ============================================================================
  // GETTERS
  // ============================================================================

  // Step 1
  List<Basket> get baskets => _baskets;
  int get activeBasketIndex => _activeBasketIndex;
  Basket get activeBasket => _baskets[_activeBasketIndex];
  List<Service> get services => _services;

  // Step 2
  Map<String, int> get selectedProducts => _selectedProducts;
  List<Product> get products => _products;
  List<OrderItem> get selectedProductItems {
    return _selectedProducts.entries.map((entry) {
      final product = _products.firstWhere(
        (p) => p.id == entry.key,
        orElse: () {
          throw Exception('Product not found: ${entry.key}');
        },
      );
      return OrderItem(
        productId: product.id,
        productName: product.itemName,
        quantity: entry.value,
        unitPrice: product.unitPrice,
      );
    }).toList();
  }

  // Step 3
  HandlingType get handlingType => _handlingType;
  String get pickupAddress => _pickupAddress;
  String get deliveryAddress => _deliveryAddress;
  bool get deliveryReminderAcknowledged => _deliveryReminderAcknowledged;
  TimeSlot? get timeSlot => _timeSlot;
  String get specialInstructions => _specialInstructions;

  // Step 4
  String get gcashReference => _gcashReference;
  String? get gcashReceiptPath => _gcashReceiptPath;
  int get loyaltyPoints => _loyaltyPoints;
  LoyaltyTier? get selectedLoyaltyTier => _selectedLoyaltyTier;

  // Metadata
  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;
  user_model.User? get currentUser => _currentUser;

  // ============================================================================
  // INITIALIZATION
  // ============================================================================

  /// Initialize: load services, products, and loyalty points
  Future<void> _initialize() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      // Load services and products in parallel
      await Future.wait([
        _loadServices(),
        _loadProducts(),
        _loadLoyaltyPoints(),
      ]);

      _isLoading = false;
      notifyListeners();

      debugPrint('✅ MobileBookingProvider: Initialized successfully');
    } catch (e) {
      _errorMessage = 'Failed to load data: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      debugPrint('❌ MobileBookingProvider: Initialization error: $e');
    }
  }

  Future<void> _loadServices() async {
    try {
      _services = await servicesRepository.getServices();
      debugPrint(
        '✅ MobileBookingProvider: Loaded ${_services.length} services',
      );
    } catch (e) {
      debugPrint('⚠️ MobileBookingProvider: Error loading services: $e');
      // Don't fail initialization, user can still proceed
    }
  }

  Future<void> _loadProducts() async {
    try {
      _products = await productsRepository.getProducts();
      debugPrint(
        '✅ MobileBookingProvider: Loaded ${_products.length} products',
      );
    } catch (e) {
      debugPrint('⚠️ MobileBookingProvider: Error loading products: $e');
      // Don't fail initialization, user can still proceed
    }
  }

  Future<void> _loadLoyaltyPoints() async {
    try {
      final user = await loyaltyService.refreshLoyaltyPoints();
      if (user != null) {
        _currentUser = user;
        _loyaltyPoints = user.loyaltyPoints ?? 0;
        _selectedLoyaltyTier = determineLoyaltyTier(_loyaltyPoints);
        debugPrint(
          '✅ MobileBookingProvider: Loaded loyalty points: $_loyaltyPoints',
        );
      }
    } catch (e) {
      debugPrint('⚠️ MobileBookingProvider: Error loading loyalty points: $e');
      // Don't fail initialization
    }
  }

  // ============================================================================
  // STEP 1: BASKET MANAGEMENT
  // ============================================================================

  /// Normalize iron weight to be between 0 and 8kg
  int normalizeIronWeight(double value) {
    final intValue = value.toInt();
    return intValue.clamp(0, 8);
  }

  /// Update service option for active basket
  void updateBasketService(String serviceKey, dynamic value) {
    final basket = _baskets[_activeBasketIndex];
    final services = basket.services;

    BasketServices updated;
    switch (serviceKey) {
      case 'wash':
        updated = services.copyWith(wash: value as String);
        break;
      case 'dry':
        updated = services.copyWith(dry: value as String);
        break;
      case 'spin':
        updated = services.copyWith(spin: value as bool);
        break;
      case 'ironWeightKg':
        final normalized = normalizeIronWeight((value as num).toDouble());
        updated = services.copyWith(ironWeightKg: normalized);
        break;
      case 'fold':
        updated = services.copyWith(fold: value as bool);
        break;
      case 'additionalDryMinutes':
        updated = services.copyWith(additionalDryMinutes: value as int);
        break;
      case 'plasticBags':
        updated = services.copyWith(plasticBags: value as int);
        break;
      default:
        return;
    }

    _baskets[_activeBasketIndex] = basket.copyWith(services: updated);
    notifyListeners();
    debugPrint(
      '📝 MobileBookingProvider: Updated basket $_activeBasketIndex - $serviceKey = $value',
    );
  }

  /// Add new basket
  void addBasket() {
    final nextNumber =
        _baskets.map((b) => b.basketNumber).reduce((a, b) => a > b ? a : b) + 1;
    _baskets.add(createNewBasket(nextNumber));
    _activeBasketIndex = _baskets.length - 1;
    notifyListeners();
    debugPrint('✅ MobileBookingProvider: Added basket #$nextNumber');
  }

  /// Delete basket by index
  void deleteBasket(int index) {
    if (_baskets.length <= 1) {
      _errorMessage = 'At least one basket is required';
      notifyListeners();
      return;
    }

    _baskets.removeAt(index);

    if (_activeBasketIndex >= _baskets.length) {
      _activeBasketIndex = _baskets.length - 1;
    }

    notifyListeners();
    debugPrint('🗑️ MobileBookingProvider: Deleted basket #$index');
  }

  /// Set active basket
  void setActiveBasketIndex(int index) {
    if (index < 0 || index >= _baskets.length) return;
    _activeBasketIndex = index;
    notifyListeners();
  }

  // ============================================================================
  // STEP 2: PRODUCT MANAGEMENT
  // ============================================================================

  /// Add product to order (increment quantity if exists)
  void addProduct(String productId) {
    _selectedProducts[productId] = (_selectedProducts[productId] ?? 0) + 1;
    notifyListeners();
    debugPrint(
      '➕ MobileBookingProvider: Added product $productId - Qty: ${_selectedProducts[productId]}',
    );
  }

  /// Remove product from order
  void removeProduct(String productId) {
    _selectedProducts.remove(productId);
    notifyListeners();
    debugPrint('➖ MobileBookingProvider: Removed product $productId');
  }

  /// Set product quantity
  void setProductQuantity(String productId, int quantity) {
    if (quantity <= 0) {
      removeProduct(productId);
    } else {
      _selectedProducts[productId] = quantity;
      notifyListeners();
      debugPrint(
        '📝 MobileBookingProvider: Set product $productId quantity to $quantity',
      );
    }
  }

  // ============================================================================
  // STEP 3: HANDLING MANAGEMENT
  // ============================================================================

  /// Set handling type (pickup or delivery)
  void setHandlingType(HandlingType type) {
    _handlingType = type;
    // Clear delivery address if switching to pickup
    if (type == HandlingType.pickup) {
      _deliveryAddress = '';
    }
    notifyListeners();
    debugPrint('🚗 MobileBookingProvider: Set handling type to ${type.name}');
  }

  /// Set delivery address
  void setDeliveryAddress(String address) {
    _deliveryAddress = address;
    notifyListeners();
  }

  /// Set pickup address
  void setPickupAddress(String address) {
    _pickupAddress = address;
    notifyListeners();
  }

  /// Set delivery reminder acknowledged
  void setDeliveryReminderAcknowledged(bool acknowledged) {
    _deliveryReminderAcknowledged = acknowledged;
    notifyListeners();
  }

  /// Set time slot
  void setTimeSlot(TimeSlot? slot) {
    _timeSlot = slot;
    notifyListeners();
    debugPrint('⏰ MobileBookingProvider: Set time slot to ${slot?.label}');
  }

  /// Set special instructions
  void setSpecialInstructions(String instructions) {
    _specialInstructions = instructions;
    notifyListeners();
  }

  // ============================================================================
  // STEP 4: PAYMENT & LOYALTY MANAGEMENT
  // ============================================================================

  /// Set GCash reference number
  void setGcashReference(String reference) {
    _gcashReference = reference;
    notifyListeners();
  }

  /// Upload GCash receipt image
  Future<void> uploadGcashReceipt(File imageFile) async {
    try {
      debugPrint('📸 MobileBookingProvider: Uploading GCash receipt...');
      final url = await gcashReceiptService.uploadReceipt(imageFile);
      _gcashReceiptPath = url;
      notifyListeners();
      debugPrint(
        '✅ MobileBookingProvider: Receipt uploaded: $_gcashReceiptPath',
      );
    } catch (e) {
      _errorMessage = 'Failed to upload receipt: ${e.toString()}';
      notifyListeners();
      debugPrint('❌ MobileBookingProvider: Receipt upload error: $e');
      rethrow;
    }
  }

  /// Set loyalty tier for discount
  void setLoyaltyTier(LoyaltyTier? tier) {
    _selectedLoyaltyTier = tier;
    notifyListeners();
    debugPrint('🎁 MobileBookingProvider: Set loyalty tier to ${tier?.name}');
  }

  // ============================================================================
  // CALCULATIONS
  // ============================================================================

  /// Calculate complete order breakdown with all fees and totals
  OrderBreakdown calculateOrderTotal() {
    // Check if delivery address is set (not empty or just spaces)
    final hasDeliveryAddress = _deliveryAddress.trim().isNotEmpty;
    
    final breakdown = buildOrderBreakdown(
      baskets: _baskets,
      items: selectedProductItems,
      isDelivery: hasDeliveryAddress,
      deliveryFeeOverride: null,
      services: _services,
      products: _products,
    );

    // Apply loyalty discount if selected
    if (_selectedLoyaltyTier != null) {
      final discount = calculateLoyaltyDiscount(
        breakdown.summary.total,
        _selectedLoyaltyTier,
      );

      return OrderBreakdown(
        items: breakdown.items,
        baskets: breakdown.baskets,
        fees: breakdown.fees,
        summary: breakdown.summary.copyWith(
          loyaltyDiscount: discount,
          total: breakdown.summary.total - discount,
        ),
      );
    }

    return breakdown;
  }

  // ============================================================================
  // VALIDATION
  // ============================================================================

  /// Validate current step
  String? validateCurrentStep(int stepNumber) {
    switch (stepNumber) {
      case 1:
        return validateStep1(_baskets);
      case 2:
        return validateStep2(selectedProductItems);
      case 3:
        final handling = OrderHandling(
          handlingType: _handlingType,
          pickupAddress: _pickupAddress,
          deliveryAddress: _deliveryAddress,
          timeSlot: _timeSlot,
          paymentMethod: PaymentMethod.gcash,
          amountPaid: 0,
          deliveryReminderAcknowledged: _deliveryReminderAcknowledged,
        );
        final result = validateStep3(handling);
        // Return error message for backward compatibility (used in step submission)
        return result.isValid ? null : result.errorMessage;
      case 4:
        final handling = OrderHandling(
          handlingType: _handlingType,
          pickupAddress: _pickupAddress,
          deliveryAddress: _deliveryAddress,
          timeSlot: _timeSlot,
          specialInstructions: _specialInstructions,
          paymentMethod: PaymentMethod.gcash,
          amountPaid: 0,
          gcashReference: _gcashReference,
          gcashReceiptPath: _gcashReceiptPath,
          deliveryReminderAcknowledged: _deliveryReminderAcknowledged,
        );
        return validateStep4(handling);
      default:
        return null;
    }
  }

  /// Get detailed Step 3 validation result with missing fields
  Step3ValidationResult getStep3ValidationDetails() {
    final handling = OrderHandling(
      handlingType: _handlingType,
      pickupAddress: _pickupAddress,
      deliveryAddress: _deliveryAddress,
      timeSlot: _timeSlot,
      paymentMethod: PaymentMethod.gcash,
      amountPaid: 0,
      deliveryReminderAcknowledged: _deliveryReminderAcknowledged,
    );
    return validateStep3(handling);
  }

  // ============================================================================
  // ORDER SUBMISSION
  // ============================================================================

  /// Build and submit complete order
  Future<OrderResponse> submitOrder(user_model.User? user) async {
    try {
      // Validate all steps
      for (int i = 1; i <= 4; i++) {
        final error = validateCurrentStep(i);
        if (error != null) {
          throw Exception('Step $i validation failed: $error');
        }
      }

      _isSubmitting = true;
      _errorMessage = null;
      notifyListeners();

      debugPrint('📤 MobileBookingProvider: Building order...');

      // Build order breakdown
      final breakdown = calculateOrderTotal();

      // Build handling
      final handling = OrderHandling(
        handlingType: _handlingType,
        pickupAddress: _pickupAddress,
        deliveryAddress: _deliveryAddress,
        timeSlot: _timeSlot,
        specialInstructions: _specialInstructions,
        paymentMethod: PaymentMethod.gcash,
        amountPaid: breakdown.summary.total,
        gcashReference: _gcashReference,
        gcashReceiptPath: _gcashReceiptPath,
        deliveryReminderAcknowledged: _deliveryReminderAcknowledged,
      );

      // Build loyalty discount
      LoyaltyDiscount? loyalty;
      if (_selectedLoyaltyTier != null) {
        loyalty = LoyaltyDiscount(
          tier: _selectedLoyaltyTier,
          pointsUsed: _selectedLoyaltyTier == LoyaltyTier.tier1 ? 10 : 20,
          discountAmount: breakdown.summary.loyaltyDiscount,
        );
      }

      // Build customer data
      CustomerData? customerData;
      String? customerId;

      if (user != null) {
        customerId = user.id;
        customerData = CustomerData(
          firstName: user.firstName,
          lastName: user.lastName,
          phoneNumber: user.phoneNumber,
          email: user.emailAddress,
        );
      }

      // Build complete order
      final bookingOrder = BookingOrder(
        customerId: customerId,
        customerData: customerData,
        breakdown: breakdown,
        handling: handling,
        loyalty: loyalty,
      );

      debugPrint('✅ MobileBookingProvider: Order built, submitting...');

      // Submit to API
      final response = await mobileOrderService.createOrder(bookingOrder);

      if (!response.success) {
        throw Exception(response.error ?? 'Order submission failed');
      }

      _isSubmitting = false;
      notifyListeners();

      debugPrint(
        '✅ MobileBookingProvider: Order submitted - ID: ${response.orderId}',
      );

      return response;
    } catch (e) {
      _errorMessage = 'Order submission failed: ${e.toString()}';
      _isSubmitting = false;
      notifyListeners();
      debugPrint('❌ MobileBookingProvider: Order submission error: $e');
      rethrow;
    }
  }

  // ============================================================================
  // RESET & CLEANUP
  // ============================================================================

  /// Reset all state for new order
  void resetOrder() {
    _baskets = [createNewBasket(1)];
    _activeBasketIndex = 0;
    _selectedProducts = {};
    _handlingType = HandlingType.pickup;
    _deliveryAddress = '';
    _timeSlot = null;
    _specialInstructions = '';
    _gcashReference = '';
    _gcashReceiptPath = null;
    _selectedLoyaltyTier = null;
    _errorMessage = null;
    _isSubmitting = false;
    notifyListeners();
    debugPrint('🔄 MobileBookingProvider: Order reset');
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Refresh loyalty points
  Future<void> refreshLoyaltyPoints() async {
    try {
      await _loadLoyaltyPoints();
      notifyListeners();
    } catch (e) {
      debugPrint('❌ MobileBookingProvider: Error refreshing loyalty: $e');
    }
  }

  // ============================================================================
  // HELPER: Copy with for OrderSummary
  // ============================================================================
  // UTILITY METHODS
  // ============================================================================

  /// Determine loyalty tier based on points
  LoyaltyTier? determineLoyaltyTier(int points) {
    if (points >= 20) return LoyaltyTier.tier2;
    if (points >= 10) return LoyaltyTier.tier1;
    return null;
  }

  /// Calculate loyalty discount based on total and tier
  double calculateLoyaltyDiscount(double total, LoyaltyTier? tier) {
    if (tier == null) return 0;
    final percent = tier == LoyaltyTier.tier1 ? 0.05 : 0.15;
    return total * percent;
  }

  // ============================================================================

  @override
  void dispose() {
    super.dispose();
    debugPrint('🗑️ MobileBookingProvider: Disposed');
  }
}

// Extension to OrderSummary for copyWith
extension OrderSummaryCopyWith on OrderSummary {
  OrderSummary copyWith({
    double? subtotalProducts,
    double? subtotalBaskets,
    double? staffServiceFee,
    double? deliveryFee,
    double? subtotalBeforeVat,
    double? vatAmount,
    double? loyaltyDiscount,
    double? total,
  }) {
    return OrderSummary(
      subtotalProducts: subtotalProducts ?? this.subtotalProducts,
      subtotalBaskets: subtotalBaskets ?? this.subtotalBaskets,
      staffServiceFee: staffServiceFee ?? this.staffServiceFee,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      subtotalBeforeVat: subtotalBeforeVat ?? this.subtotalBeforeVat,
      vatAmount: vatAmount ?? this.vatAmount,
      loyaltyDiscount: loyaltyDiscount ?? this.loyaltyDiscount,
      total: total ?? this.total,
    );
  }
}
