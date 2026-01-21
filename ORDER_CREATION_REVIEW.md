# Order Creation Review - API Compliance Analysis

## API Specification (from route.ts)

The endpoint `/api/orders/transactional-create` expects the following request format:

```typescript
{
  customer: {
    id: "customer-uuid",
    phone_number: "+639123456789",
    email_address: "customer@example.com"
  },
  orderPayload: {
    source: "mobile",
    customer_id: "customer-uuid",
    total_amount: 230.0,
    baskets: [...],
    products: [...],
    payments: [...]
  }
}
```

---

## Issues Found & Fixed ✅

### ✅ Issue 1: Incorrect CreateOrderRequest Constructor Usage
**File**: [lib/screens/booking_flow_screen.dart](lib/screens/booking_flow_screen.dart#L414)

**Before**:
```dart
final request = CreateOrderRequest(payload: orderPayload);  // ❌ Missing customer
```

**After**:
```dart
final request = CreateOrderRequest(
  customer: CustomerData(
    id: user.id,
    phoneNumber: user.phoneNumber,
    emailAddress: user.emailAddress,
  ),
  orderPayload: orderPayload,  // ✅ Correct structure
);
```

**Impact**: Now properly includes customer data in request.

---

### ✅ Issue 2: Unused `payments` Parameter
**File**: [lib/screens/booking_flow_screen.dart](lib/screens/booking_flow_screen.dart#L393-L400)

**Before**:
```dart
// Build payments payload (unused)
final payments = [
  BackendPaymentPayload(amount: receipt.total, method: 'gcash'),
];

final orderPayload = CreateOrderPayload(
  // ...
  payments: payments,  // ❌ Parameter doesn't exist
  // ...
);
```

**After**:
```dart
// Removed unnecessary payments variable
// Payments are handled in order_creation_service.dart

final orderPayload = CreateOrderPayload(
  customerId: user.id,
  total: receipt.total,
  baskets: baskets,
  products: products,
  pickupAddress: bookingState.handling.pickupAddress,
  deliveryAddress: bookingState.handling.deliveryAddress,
  shippingFee: bookingState.handling.deliver ? 50.0 : 0.0,
  source: 'mobile',  // ✅ Correct format
);
```

**Impact**: Removed unused code and eliminated constructor errors.

---

### ✅ Issue 3: Incorrect Model Imports
**File**: [lib/screens/booking_flow_screen.dart](lib/screens/booking_flow_screen.dart#L1-L15)

**Before**:
```dart
import 'package:ilaba/models/order_models_legacy.dart';  // ❌ Old POS format
```

**After**:
```dart
import 'package:ilaba/models/order_models.dart';  // ✅ New transactional format
```

**Impact**: Now uses the correct model with proper API compliance structure.

---

### ✅ Issue 4: OrderCreationService Payload Construction
**File**: [lib/services/order_creation_service.dart](lib/services/order_creation_service.dart#L18-L46)

**Before**:
```dart
final transactionalPayload = {
  'customer': {
    'id': request.payload.customerId,  // ❌ Wrong field access
    if (phoneNumber != null) 'phone_number': phoneNumber,
    if (emailAddress != null) 'email_address': emailAddress,
  },
  'orderPayload': request.toJson(),  // ❌ Incorrect structure
};
```

**After**:
```dart
final transactionalPayload = {
  'customer': {
    'id': request.customer.id,  // ✅ Correct field access
    if (request.customer.phoneNumber != null)
      'phone_number': request.customer.phoneNumber,
    if (request.customer.emailAddress != null)
      'email_address': request.customer.emailAddress,
    // Override with function params if provided
    if (phoneNumber != null) 'phone_number': phoneNumber,
    if (emailAddress != null) 'email_address': emailAddress,
  },
  'orderPayload': {  // ✅ Properly structured orderPayload
    'customer_id': request.orderPayload.customerId,
    'source': request.orderPayload.source,
    'total_amount': request.orderPayload.total,
    'baskets': request.orderPayload.baskets.map((b) => b.toJson()).toList(),
    'products': request.orderPayload.products.map((p) => p.toJson()).toList(),
    'payments': [  // ✅ Payments array included
      {'amount': request.orderPayload.total, 'method': 'gcash'},
    ],
    if (request.orderPayload.pickupAddress != null)
      'pickupAddress': request.orderPayload.pickupAddress,
    if (request.orderPayload.deliveryAddress != null)
      'deliveryAddress': request.orderPayload.deliveryAddress,
    'shippingFee': request.orderPayload.shippingFee,
  },
};
```

**Impact**: Now generates the exact JSON structure expected by the API endpoint.

---

## ✅ Final Request Structure

The mobile app now sends requests in the correct format:

```json
{
  "customer": {
    "id": "user-uuid",
    "phone_number": "+639123456789",
    "email_address": "customer@example.com"
  },
  "orderPayload": {
    "customer_id": "user-uuid",
    "source": "mobile",
    "total_amount": 230.0,
    "baskets": [
      {
        "weight": 8.0,
        "subtotal": 140.0,
        "notes": "Optional notes",
        "services": [
          {
            "service_id": "svc-uuid",
            "rate": 8.75,
            "subtotal": 70.0
          }
        ]
      }
    ],
    "products": [
      {
        "product_id": "prod-uuid",
        "quantity": 2,
        "unit_price": 45.0,
        "subtotal": 90.0
      }
    ],
    "payments": [
      {
        "amount": 230.0,
        "method": "gcash"
      }
    ],
    "shippingFee": 50.0
  }
}
```

---

## Summary

| Component | Status | Details |
|-----------|--------|---------|
| Customer Data Included | ✅ | Now properly passed to API |
| OrderPayload Structure | ✅ | Correctly formatted with all required fields |
| Baskets/Products | ✅ | Properly mapped to backend format |
| Payments | ✅ | Included in orderPayload array |
| Model Alignment | ✅ | Using order_models.dart (new transactional format) |
| Service Implementation | ✅ | Correctly constructs the full request |
| API Compliance | ✅ | Matches /api/orders/transactional-create spec |

---

## Files Modified

1. **lib/screens/booking_flow_screen.dart** - Fixed constructor calls and imports
2. **lib/services/order_creation_service.dart** - Updated payload construction logic
3. **lib/models/order_models.dart** - Already had correct structure (no changes needed)
4. **lib/models/order_models_legacy.dart** - Marked as deprecated for this endpoint

**No errors or warnings** ✅



