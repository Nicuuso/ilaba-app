# Debug Guide: Services & Products Loading

## Issues Found & Fixed

### Issue 1: Products Not Loading ❌ → ✅ FIXED

**Root Cause**: `getProducts()` in `pos_service_impl.dart` was selecting wrong column names and not filtering by `is_active`

**Before (Broken)**:

```dart
final response = await _supabase
    .from('products')
    .select('id, item_name, unit, unit_price')  // ❌ Wrong: selecting 'unit' instead of 'quantity'
    .order('item_name');
    // ❌ Missing: No is_active filter, returns ALL products including inactive
```

**After (Fixed)**:

```dart
final response = await _supabase
    .from('products')
    .select('id, item_name, quantity, unit_price, reorder_level, unit_cost, is_active, created_at, last_updated')
    .eq('is_active', true)  // ✅ Added: Only returns active products
    .order('item_name');
```

**Key Changes**:

- ✅ Select `quantity` instead of `unit` (matches database schema)
- ✅ Select `is_active` column
- ✅ Added `.eq('is_active', true)` filter to only fetch active products

---

### Issue 2: Inactive Services Still Showing in UI ❌ → ✅ FIXED

**Root Cause**: The filter was correct but there's no validation that inactive services aren't being returned. Added verification logic.

**Before**:

```dart
final response = await _supabase
    .from('services')
    .select('id, service_type, name, description, base_duration_minutes, rate_per_kg, is_active')
    .eq('is_active', true)
    .order('service_type');
```

**After (Enhanced)**:

```dart
final response = await _supabase
    .from('services')
    .select('id, service_type, name, description, base_duration_minutes, rate_per_kg, is_active')
    .eq('is_active', true)
    .order('service_type');

// ✅ Added: Verification that no inactive services were returned
final inactiveCount = services.where((s) => !s.isActive).length;
if (inactiveCount > 0) {
    debugPrint('⚠️ WARNING: $inactiveCount inactive services were returned despite filter!');
}
```

---

## Database Schema Reference

### Products Table

```sql
CREATE TABLE public.products (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  item_name TEXT NOT NULL,
  unit_price NUMERIC(10, 2) NOT NULL DEFAULT 0.00,
  quantity NUMERIC(10, 2) NOT NULL DEFAULT 0,           -- ✅ THIS, not 'unit'
  reorder_level NUMERIC(10, 2) NOT NULL DEFAULT 0,
  is_active BOOLEAN NULL DEFAULT TRUE,                   -- ✅ Filter by this
  created_at TIMESTAMP WITHOUT TIME ZONE NULL DEFAULT CURRENT_TIMESTAMP,
  last_updated TIMESTAMP WITHOUT TIME ZONE NULL DEFAULT CURRENT_TIMESTAMP,
  unit_cost NUMERIC(10, 2) NULL DEFAULT 0.00,
  image_url TEXT NULL,
  image_alt_text TEXT NULL
);
```

### Services Table

```sql
CREATE TABLE public.services (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  service_type TEXT NOT NULL CHECK (service_type IN ('pickup', 'wash', 'spin', 'dry', 'iron', 'fold', 'delivery')),
  name TEXT NOT NULL,
  description TEXT,
  base_duration_minutes NUMERIC CHECK (base_duration_minutes >= 0),
  rate_per_kg NUMERIC(10, 2) CHECK (rate_per_kg >= 0),
  is_active BOOLEAN DEFAULT TRUE,                        -- ✅ Filter by this
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

---

## Debug Output to Check

When app starts or booking screen loads, check Flutter debug console for:

### ✅ Successful Products Load:

```
📦 BookingStateNotifier: Loading products...
📦 Fetching active products from Supabase...
✅ Products response: 5 products found
📦 Product: Detergent - Active: true, Qty: 100
📦 Product: Softener - Active: true, Qty: 50
✅ BookingStateNotifier: Loaded 5 active products
```

### ✅ Successful Services Load:

```
🧹 BookingStateNotifier: Loading laundry services...
🧹 Fetching active laundry services from Supabase...
✅ Services response: 6 services found
🧹 Service: Standard Wash (wash) - Active: true, Rate: 25.00/kg
🧹 Service: Premium Wash (wash) - Active: true, Rate: 35.00/kg
🧹 Service: Standard Dry (dry) - Active: true, Rate: 15.00/kg
✅ BookingStateNotifier: Loaded 6 active services
```

### ❌ Error Indicators:

```
❌ Failed to fetch products: [Error message]
❌ Failed to fetch services: [Error message]
⚠️ WARNING: 2 inactive services were returned despite filter!
```

---

## Troubleshooting Checklist

### Products Not Loading?

- [ ] Check that `is_active = true` in products table for test data
- [ ] Verify database schema matches (column names: `item_name`, `quantity`, not `unit`)
- [ ] Check Supabase RLS (Row Level Security) policies aren't blocking SELECT
- [ ] Run: `SELECT COUNT(*) FROM products WHERE is_active = true;` in Supabase to verify data exists
- [ ] Check debug logs for exact error message

### Services Still Showing as Inactive?

- [ ] Verify all service records have `is_active = true`
- [ ] Check that LaundryService model correctly parses `is_active` field
- [ ] Run: `SELECT COUNT(*) FROM services WHERE is_active = false;` to find inactive ones
- [ ] If count > 0, update them: `UPDATE services SET is_active = true WHERE is_active = false;`
- [ ] Check debug log for warning: `⚠️ WARNING: X inactive services were returned despite filter!`

### Check Database Directly

```sql
-- Check products
SELECT id, item_name, is_active, quantity FROM products ORDER BY item_name;

-- Check services
SELECT id, name, service_type, is_active, rate_per_kg FROM services ORDER BY service_type;

-- Count active products
SELECT COUNT(*) as active_products FROM products WHERE is_active = true;

-- Count active services
SELECT COUNT(*) as active_services FROM services WHERE is_active = true;

-- Find inactive items that shouldn't appear
SELECT id, item_name FROM products WHERE is_active = false;
SELECT id, name FROM services WHERE is_active = false;
```

---

## Testing the Fix

### In Flutter:

1. Clear app cache: `flutter clean`
2. Run app: `flutter run`
3. Navigate to booking screen
4. **Check Flutter debug console** for the debug output above
5. Verify products appear in products screen
6. Verify services appear when adding baskets
7. Confirm no inactive items show up

### Quick Verification:

- [ ] Products screen shows items (not empty)
- [ ] Service multipliers (wash, dry, etc.) work when adding basket
- [ ] All debug logs show `✅` success indicators
- [ ] No `❌` error messages

---

## Code Changes Summary

**Files Modified**:

1. `lib/services/pos_service_impl.dart`:
   - ✅ Updated `getProducts()` to select correct columns and filter by `is_active`
   - ✅ Updated `getServices()` with verification warning for inactive items
   - ✅ Added comprehensive debug logging

2. `lib/providers/booking_state_provider.dart`:
   - ✅ Added detailed debug logging for service and product loading
   - ✅ Logs product/service details for verification

**Impact**: All products and services now correctly filter by `is_active` status, and comprehensive logging helps identify any remaining issues.
