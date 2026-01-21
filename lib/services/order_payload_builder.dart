import 'package:flutter/foundation.dart';
import 'package:ilaba/models/order_models.dart';
import 'package:ilaba/models/pos_types.dart';

/// Builds order breakdown and handling payloads from booking state
class OrderPayloadBuilder {
  /// Build breakdown JSON from current selections
  static OrderBreakdown buildBreakdown({
    required Map<String, int> orderProductCounts,
    required List<Product> products,
    required List<Basket> baskets,
    required List<LaundryService> services,
    required bool includeDelivery,
  }) {
    // 1. Build items array from product selections
    final items = <OrderItem>[];
    double productSubtotal = 0;

    for (final entry in orderProductCounts.entries) {
      final productId = entry.key;
      final quantity = entry.value;

      final product = products.firstWhere(
        (p) => p.id == productId,
        orElse: () => throw Exception('Product $productId not found'),
      );

      final subtotal = product.unitPrice * quantity;
      productSubtotal += subtotal;

      items.add(
        OrderItem(
          id: _generateId(),
          productId: productId,
          productName: product.itemName,
          quantity: quantity,
          unitPrice: product.unitPrice,
          unitCost: product.unitCost ?? 0,
          subtotal: subtotal,
          discount: {'amount': 0, 'reason': null},
        ),
      );
    }

    // 2. Build baskets array with services
    final basketsArray = <OrderBasket>[];
    double basketSubtotal = 0;

    for (final basket in baskets) {
      if (basket.weightKg <= 0) continue; // Skip empty baskets

      final basketServices = <OrderService>[];
      double basketTotal = 0;

      // Wash
      if (basket.washCount > 0) {
        final service = _findService(services, 'wash', basket.washPremium);
        final subtotal = basket.weightKg * service.ratePerKg * basket.washCount;
        basketServices.add(
          OrderService(
            id: _generateId(),
            serviceId: service.id,
            serviceName: service.name,
            isPremium: basket.washPremium,
            multiplier: basket.washCount,
            ratePerKg: service.ratePerKg,
            subtotal: subtotal,
            durationInMinutes: (service.baseDurationMinutes * basket.washCount)
                .toInt(),
          ),
        );
        basketTotal += subtotal;
      }

      // Dry
      if (basket.dryCount > 0) {
        final service = _findService(services, 'dry', basket.dryPremium);
        final subtotal = basket.weightKg * service.ratePerKg * basket.dryCount;
        basketServices.add(
          OrderService(
            id: _generateId(),
            serviceId: service.id,
            serviceName: service.name,
            isPremium: basket.dryPremium,
            multiplier: basket.dryCount,
            ratePerKg: service.ratePerKg,
            subtotal: subtotal,
            durationInMinutes: (service.baseDurationMinutes * basket.dryCount)
                .toInt(),
          ),
        );
        basketTotal += subtotal;
      }

      // Spin (if available)
      if (basket.spinCount > 0) {
        try {
          final service = _findService(services, 'spin', false);
          final subtotal =
              basket.weightKg * service.ratePerKg * basket.spinCount;
          basketServices.add(
            OrderService(
              id: _generateId(),
              serviceId: service.id,
              serviceName: service.name,
              isPremium: false,
              multiplier: basket.spinCount,
              ratePerKg: service.ratePerKg,
              subtotal: subtotal,
              durationInMinutes:
                  (service.baseDurationMinutes * basket.spinCount).toInt(),
            ),
          );
          basketTotal += subtotal;
        } catch (e) {
          debugPrint('Spin service not available: $e');
        }
      }

      // Iron
      if (basket.iron) {
        final service = _findService(services, 'iron', false);
        final subtotal = basket.weightKg * service.ratePerKg;
        basketServices.add(
          OrderService(
            id: _generateId(),
            serviceId: service.id,
            serviceName: service.name,
            isPremium: false,
            multiplier: 1,
            ratePerKg: service.ratePerKg,
            subtotal: subtotal,
            durationInMinutes: service.baseDurationMinutes,
          ),
        );
        basketTotal += subtotal;
      }

      // Fold
      if (basket.fold) {
        final service = _findService(services, 'fold', false);
        final subtotal = basket.weightKg * service.ratePerKg;
        basketServices.add(
          OrderService(
            id: _generateId(),
            serviceId: service.id,
            serviceName: service.name,
            isPremium: false,
            multiplier: 1,
            ratePerKg: service.ratePerKg,
            subtotal: subtotal,
            durationInMinutes: service.baseDurationMinutes,
          ),
        );
        basketTotal += subtotal;
      }

      if (basketServices.isNotEmpty) {
        basketsArray.add(
          OrderBasket(
            basketNumber: basket.originalIndex,
            weight: basket.weightKg,
            services: basketServices,
            total: basketTotal,
            basketNotes: basket.notes.isNotEmpty ? basket.notes : null,
            approvalStatus: 'pending', // Mobile app orders need approval
            approvedAt: null,
            approvedBy: null,
            rejectionReason: null,
          ),
        );
        basketSubtotal += basketTotal;
      }
    }

    // 3. Calculate fees
    const serviceFee = 40.0; // PHP 40 per order if has baskets
    final handlingFee = includeDelivery ? 50.0 : 0.0; // PHP 50 for delivery

    final fees = <OrderFee>[];
    if (basketsArray.isNotEmpty) {
      fees.add(
        OrderFee(
          id: _generateId(),
          type: 'service_fee',
          description: 'Service Fee',
          amount: serviceFee,
        ),
      );
    }
    if (includeDelivery) {
      fees.add(
        OrderFee(
          id: _generateId(),
          type: 'handling_fee',
          description: 'Delivery Fee',
          amount: handlingFee,
        ),
      );
    }

    // 4. Calculate totals with 12% VAT
    const taxRate = 0.12;
    final subtotalBeforeTax =
        productSubtotal +
        basketSubtotal +
        (basketsArray.isNotEmpty ? serviceFee : 0) +
        handlingFee;

    // Tax is calculated on subtotal
    final taxIncluded = subtotalBeforeTax * (taxRate / (1 + taxRate));
    final total = subtotalBeforeTax;

    // 5. Build payment object
    final payment = OrderPayment(
      method: 'gcash',
      paymentStatus: 'pending', // Pending until cashier approves
      amountPaid: total,
      changeAmount: 0,
      completedAt: null, // Will be set when cashier approves
      gcashReceipt: GCashReceipt(
        screenshotUrl: null,
        transactionId: null,
        verified: false,
      ),
    );

    // 6. Build audit log
    final auditLog = [
      AuditLogEntry(
        timestamp: DateTime.now().toIso8601String(),
        changedBy: null,
        action: 'Order created via mobile app - pending cashier approval',
        details: {
          'source': 'app',
          'payment_method': 'gcash',
          'items_count': items.length,
          'baskets_count': basketsArray.length,
        },
      ),
    ];

    return OrderBreakdown(
      items: items,
      baskets: basketsArray,
      fees: fees,
      totals: PaymentTotals(
        productSubtotal: productSubtotal > 0 ? productSubtotal : null,
        basketSubtotal: basketSubtotal > 0 ? basketSubtotal : null,
        serviceFee: basketsArray.isNotEmpty ? serviceFee : null,
        handlingFee: includeDelivery ? handlingFee : null,
        taxRate: taxRate,
        taxIncluded: taxIncluded,
        total: total,
        vatModel: 'inclusive',
      ),
      payment: payment,
      auditLog: auditLog,
    );
  }

  /// Build handling JSON from handling state
  static OrderHandling buildHandling({
    required bool pickupEnabled,
    required String? pickupAddress,
    required bool deliveryEnabled,
    required String? deliveryAddress,
    required String? instructions,
  }) {
    return OrderHandling(
      pickup: HandlingLocation(
        address:
            (pickupEnabled && pickupAddress != null && pickupAddress.isNotEmpty)
            ? pickupAddress
            : null,
        latitude: null,
        longitude: null,
        notes: (instructions != null && instructions.isNotEmpty)
            ? instructions
            : null,
        status:
            (pickupEnabled && pickupAddress != null && pickupAddress.isNotEmpty)
            ? 'pending'
            : 'skipped',
      ),
      delivery: HandlingLocation(
        address:
            (deliveryEnabled &&
                deliveryAddress != null &&
                deliveryAddress.isNotEmpty)
            ? deliveryAddress
            : null,
        latitude: null,
        longitude: null,
        notes: (instructions != null && instructions.isNotEmpty)
            ? instructions
            : null,
        status:
            (deliveryEnabled &&
                deliveryAddress != null &&
                deliveryAddress.isNotEmpty)
            ? 'pending'
            : 'skipped',
      ),
    );
  }

  /// Find a service by type and premium flag
  static LaundryService _findService(
    List<LaundryService> services,
    String serviceType,
    bool isPremium,
  ) {
    try {
      final service = services.firstWhere((s) => s.serviceType == serviceType);
      return service;
    } catch (e) {
      throw Exception('Service type "$serviceType" not found');
    }
  }

  /// Generate UUID-like ID
  static String _generateId() {
    return 'id_${DateTime.now().millisecondsSinceEpoch}_${(DateTime.now().microsecond % 1000).toString().padLeft(3, '0')}';
  }
}
