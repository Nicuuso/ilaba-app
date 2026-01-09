# Database Schema Migration Analysis

## 🔄 Summary of Changes

The new schema represents a **major architectural shift** from a simple mobile app to an **enterprise POS system** supporting both mobile and store operations. The changes affect authentication, data modeling, and order management significantly.

---

## 📊 Critical Schema Changes

### 1. **CUSTOMERS TABLE** ✏️ MODIFIED
**Before:**
```dart
class User {
  String id, authId, firstName, lastName, phoneNumber
  String? middleName, address, emailAddress
  DateTime? birthdate, createdAt
  int? loyaltyPoints
}
```

**After (SQL):**
```sql
CREATE TABLE customers (
  id UUID PRIMARY KEY,
  auth_id UUID UNIQUE,
  first_name TEXT NOT NULL,
  middle_name TEXT,
  last_name TEXT NOT NULL,
  birthdate DATE NOT NULL,           -- ✨ NOW REQUIRED
  gender TEXT NOT NULL,              -- ✨ NEW REQUIRED FIELD
  address TEXT,
  phone_number TEXT NOT NULL,
  email_address TEXT,
  loyalty_points INTEGER DEFAULT 0,
  created_at TIMESTAMP,
  updated_at TIMESTAMP               -- ✨ NEW FIELD
)
```

**Changes:**
- `birthdate` is now **NOT NULL** (required at signup)
- `gender` is **NEW** and **NOT NULL** (required: 'male', 'female', 'other')
- `updated_at` timestamp added for tracking modifications
- `phone_number` is now **NOT NULL** (was optional)

**Impact:** Signup form must now require birthdate and gender selection.

---

### 2. **STAFF TABLE** 🆕 NEW
```sql
CREATE TABLE staff (
  id UUID PRIMARY KEY,
  auth_id UUID UNIQUE,
  first_name, middle_name, last_name TEXT,
  birthdate DATE NOT NULL,
  gender TEXT NOT NULL,
  address TEXT NOT NULL,
  phone_number TEXT NOT NULL,
  email_address TEXT NOT NULL UNIQUE,
  is_active BOOLEAN DEFAULT TRUE,
  created_at, updated_at TIMESTAMP,
  updated_by UUID REFERENCES staff(id)
)
```

**Purpose:** Separate employee management from customers. Enables role-based access control.

**Note:** Mobile app is **customer-only**, but backend may need staff auth endpoints.

---

### 3. **ROLES & STAFF_ROLES TABLES** 🆕 NEW
```sql
CREATE TABLE roles (
  id TEXT PRIMARY KEY
  -- Values: 'admin', 'cashier', 'attendant', 'rider'
)

CREATE TABLE staff_roles (
  staff_id UUID REFERENCES staff(id),
  role_id TEXT REFERENCES roles(id),
  PRIMARY KEY (staff_id, role_id)
)
```

**Purpose:** RBAC (Role-Based Access Control) for staff members.

**Impact:** Mobile app doesn't need this, but auth service could validate user type.

---

### 4. **PRODUCTS TABLE** ✏️ MODIFIED
**Before:**
```dart
class Product {
  String id, itemName, unit
  double unitPrice
}
```

**After (SQL):**
```sql
CREATE TABLE products (
  id UUID PRIMARY KEY,
  item_name TEXT NOT NULL,
  unit_price NUMERIC(10,2) NOT NULL,
  quantity NUMERIC(10,2) NOT NULL DEFAULT 0,        -- ✨ NEW
  reorder_level NUMERIC(10,2) NOT NULL DEFAULT 0,   -- ✨ NEW
  unit_cost NUMERIC(10,2) DEFAULT 0,                -- ✨ NEW
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP,
  last_updated TIMESTAMP                            -- ✨ NEW
)
```

**Changes:**
- Removed `unit` field (no longer in schema!)
- Added **inventory tracking**: `quantity`, `reorder_level`, `unit_cost`
- Added `last_updated` timestamp
- `is_active` flag for soft deletes

**Impact:** 
- Product model needs updating (remove `unit` field)
- Inventory management now tracked via `product_transactions` table instead of direct quantity updates

---

### 5. **SERVICES TABLE** ✏️ MODIFIED
**Before:**
```dart
class LaundryService {
  String id, serviceType, name
  String? description
  int baseDurationMinutes
  double ratePerKg
  bool isActive
}
```

**After (SQL):**
```sql
CREATE TABLE services (
  id UUID PRIMARY KEY,
  service_type TEXT NOT NULL,  -- ✨ UPDATED ENUM
  name TEXT NOT NULL,
  description TEXT,
  base_duration_minutes NUMERIC,
  rate_per_kg NUMERIC(10,2),
  is_active BOOLEAN DEFAULT TRUE,
  created_at, updated_at TIMESTAMP
)
```

**Changes:**
- `service_type` enum **expanded**: now includes `'pickup'` and `'delivery'`
- Was: 'wash', 'dry', 'spin', 'iron', 'fold'
- Now: 'pickup', 'wash', 'spin', 'dry', 'iron', 'fold', 'delivery'

**Impact:** Separate service entries needed for pickup/delivery (not just handling states).

---

### 6. **MACHINES TABLE** 🆕 NEW
```sql
CREATE TABLE machines (
  id UUID PRIMARY KEY,
  machine_name TEXT NOT NULL,
  machine_type TEXT NOT NULL,    -- 'wash', 'dry', 'iron'
  status TEXT,                   -- 'available', 'running', 'maintenance'
  last_serviced_at TIMESTAMP,
  created_at, updated_at TIMESTAMP
)
```

**Purpose:** Track laundry equipment availability and maintenance.

**Impact:** Backend feature; mobile doesn't directly use this.

---

### 7. **ORDERS TABLE** 🔥 MAJOR REFACTOR
**Before:**
```dart
class Booking {
  String id, userId, status
  int weightKg
  List<BookingService> services
  List<String> addOns
  String pickupAddress, deliveryAddress
  DateTime pickupDate, deliveryDate
  double totalPrice
  String paymentMethod
  String? notes
  DateTime createdAt, completedAt
}
```

**After (SQL):**
```sql
CREATE TABLE orders (
  id UUID PRIMARY KEY,
  source TEXT NOT NULL,              -- ✨ NEW: 'store' | 'app'
  customer_id UUID NOT NULL,         -- ✨ RENAMED from user_id
  cashier_id UUID,                   -- ✨ NEW: POS cashier reference
  
  status TEXT NOT NULL DEFAULT 'pending',  -- ✨ NEW STATUS WORKFLOW
  -- 'pending', 'for_pick-up', 'processing', 'for_delivery', 'completed', 'cancelled'
  
  created_at TIMESTAMP NOT NULL,
  approved_at TIMESTAMP,             -- ✨ NEW: when mobile user approves
  completed_at TIMESTAMP,
  cancelled_at TIMESTAMP,            -- ✨ NEW
  
  total_amount NUMERIC(10,2) NOT NULL,
  order_note TEXT,
  
  handling JSONB NOT NULL,           -- ✨ NEW: Pickup & delivery details (JSON)
  breakdown JSONB NOT NULL,          -- ✨ NEW: Complete order breakdown (JSON)
  cancellation JSONB                 -- ✨ NEW: Cancellation details (JSON)
)
```

**Major Changes:**
1. **JSON-based storage** for complex nested data (handling, breakdown, cancellation)
2. **New workflow states**: 'for_pick-up', 'for_delivery' (logistics tracking)
3. **Approval workflow**: `approved_at` for mobile orders awaiting approval
4. **Source tracking**: distinguish store POS orders from app orders
5. **Cashier reference**: link to staff member who processed order
6. **All dates preserved**: created, approved, completed, cancelled timestamps

**Impact on Mobile App:**
- Orders now track `source='app'`
- New status workflow to handle
- `handling` and `breakdown` are JSON - mobile sends complete snapshots to backend

---

### 8. **PRODUCT_TRANSACTIONS TABLE** 🆕 NEW (Audit Log)
```sql
CREATE TABLE product_transactions (
  id UUID PRIMARY KEY,
  product_id UUID NOT NULL,
  staff_id UUID,
  order_id UUID,
  
  change_type TEXT,  -- 'add', 'remove', 'consume', 'adjust'
  quantity NUMERIC(10,2) NOT NULL,
  reason TEXT,
  
  created_at TIMESTAMP
)
```

**Purpose:** Immutable audit trail for all inventory changes. Replaces direct quantity updates.

**Impact:** Inventory management is append-only, not editable.

---

### 9. **ISSUES TABLE** 🆕 NEW (Problem Tracking)
```sql
CREATE TABLE issues (
  id UUID PRIMARY KEY,
  order_id UUID,
  basket_number INTEGER,
  
  description TEXT NOT NULL,
  status TEXT,           -- 'open', 'resolved', 'cancelled'
  severity TEXT,         -- 'low', 'medium', 'high', 'critical'
  
  reported_by UUID REFERENCES staff(id),
  resolved_by UUID,
  resolved_at TIMESTAMP,
  
  created_at, updated_at TIMESTAMP
)
```

**Purpose:** Track quality issues, defects, or problems with orders.

**Impact:** Mobile may need to report issues during order processing.

---

## 📋 Required Code Updates

### Priority 1: Critical Auth & Signup
- [ ] Update `User` model: add `gender` field, make `birthdate` required
- [ ] Update signup form: add gender selection (radio/dropdown)
- [ ] Update auth service: validate birthdate and gender
- [ ] Update customer profile screen: allow editing gender, birthdate

### Priority 2: Models
- [ ] Remove `unit` field from `Product` model
- [ ] Add inventory fields to `Product` model (optional for mobile)
- [ ] Update `LaundryService` to handle new service types (pickup, delivery)
- [ ] Refactor `Booking` → `Order` model to match new structure
- [ ] Create new models: `Staff`, `Role`, `Machine` (optional for mobile)

### Priority 3: Order Management
- [ ] Update order creation to send `source='app'`
- [ ] Handle new order statuses in UI (for_pick-up, for_delivery)
- [ ] Update order tracking/status screens
- [ ] Implement order approval workflow for mobile

### Priority 4: API Integration
- [ ] Update `saveOrder()` to send `handling` and `breakdown` as JSON
- [ ] Update order fetch to handle JSON columns
- [ ] Implement order status polling/listener

---

## 🎯 Schema Mapping: Old → New

| Old Field | New Field | Notes |
|-----------|-----------|-------|
| `Booking.userId` | `orders.customer_id` | Renamed |
| `Booking.services` | `breakdown.baskets` | Now nested in JSON |
| `Booking.addOns` | `breakdown.addons` | Now nested in JSON |
| `Booking.pickupAddress` | `handling.pickup.address` | Now nested in JSON |
| `Booking.deliveryAddress` | `handling.delivery.address` | Now nested in JSON |
| `Booking.paymentMethod` | `breakdown.payment.method` | Now nested in JSON |
| (none) | `orders.source` | NEW: 'app' or 'store' |
| (none) | `orders.approved_at` | NEW: approval timestamp |
| `Booking.status` | `orders.status` | Expanded enum |
| `Product.unit` | (removed) | No longer in schema |

---

## 🗂️ Table Hierarchy

```
customers (base customer)
├── orders (customer's orders)
│   ├── {handling: JSONB}     -- pickup & delivery details
│   ├── {breakdown: JSONB}    -- items, baskets, payment
│   └── {cancellation: JSONB} -- cancellation reason
├── product_transactions (inventory audit)
└── issues (quality tracking)

staff (employees)
├── staff_roles
└── roles

machines (equipment)
services (laundry service catalog)
products (inventory items)
```

---

## 📱 Mobile App Impact Summary

**High Impact:**
1. Signup must require `birthdate` and `gender`
2. Orders saved with JSON `handling` and `breakdown`
3. New order status workflow ('for_pick-up', 'for_delivery')
4. Remove `unit` field from products

**Medium Impact:**
1. Update order status screens to show new statuses
2. Handle approval workflow (`approved_at`)
3. Implement order history retrieval with JSON parsing

**Low Impact:**
1. Staff/roles tables (POS only, not mobile)
2. Machines table (backend only)
3. Issues table (optional feature)
4. Product transactions (audit log, not needed in app UI)

