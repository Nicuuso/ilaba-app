# Baskets Screen Update - Implementation Summary

## Overview
The baskets screen has been completely redesigned using a tile-based interface inspired by the web POS, adapted for mobile with a 2-column grid layout. Services are now fetched from the Supabase database.

## What Changed

### 1. **Screen Design (booking_baskets_screen.dart)**

#### Layout Improvements:
- **Tab Navigation**: Horizontal scrollable basket tabs with delete button overlay
- **Empty State**: Icon and message when no baskets exist
- **Grid-Based Services**: 2-column grid for service tiles (Wash, Dry, Spin, Iron, Fold)
- **Compact Controls**: Increment/decrement buttons in tile footer
- **Premium Indicators**: Built-in premium toggle in service tiles
- **Visual Feedback**: Color-coded tiles with disabled state

#### Mobile Optimizations:
- Responsive 2x3 grid for 6 service tiles
- Compact basket tabs with delete button positioning
- Scrollable layout with summary always visible
- Touch-friendly buttons and controls
- Clear visual hierarchy with sections

#### Key Features:
```
[Basket Tabs] [Add Basket]

Weight Input

Service Tiles Grid:
  [Wash]  [Dry]
  [Spin]  [Iron]
  [Fold]  

Premium Services Info (conditional)

Special Notes Input

Estimated Duration Box

Basket Summary
```

### 2. **Service Tile Component (_ServiceTile Widget)**

Custom widget that displays:
- Service title
- Count indicator
- Premium badge (for Wash/Dry)
- Increment/Decrement controls
- Premium toggle button (where applicable)
- Disabled state (grayed out when weight = 0)

**Service Types Supported:**
- **Wash**: Countable, with Premium option
- **Dry**: Countable, with Premium option
- **Spin**: Countable, no premium
- **Iron**: Toggle-only (0 or 1)
- **Fold**: Toggle-only (0 or 1)

### 3. **Database Integration**

#### Services Table Structure:
```sql
CREATE TABLE services (
  id UUID PRIMARY KEY,
  service_type TEXT NOT NULL,  -- 'wash', 'dry', 'spin', 'iron', 'fold'
  name TEXT NOT NULL,
  description TEXT,
  base_duration_minutes INTEGER,
  rate_per_kg NUMERIC(10,2),
  is_active BOOLEAN
)
```

#### Basket Services Table:
```sql
CREATE TABLE basket_services (
  id UUID PRIMARY KEY,
  basket_id UUID REFERENCES baskets(id),
  service_id UUID REFERENCES services(id),
  rate NUMERIC(10,2) NOT NULL,
  subtotal NUMERIC(10,2) NOT NULL,
  status TEXT
)
```

### 4. **Database Fetching (pos_service_impl.dart)**

The `getServices()` method fetches services from Supabase:
```dart
Future<List<LaundryService>> getServices() async {
  final response = await _supabase
      .from('services')
      .select('id, service_type, name, base_duration_minutes, rate_per_kg, is_active')
      .eq('is_active', true)
      .order('service_type');
  
  return (response as List)
      .map((service) => LaundryService.fromJson(service))
      .toList();
}
```

### 5. **State Management Integration**

Services are loaded in `BookingStateNotifier` via `loadServices()`:
- Fetches from database automatically
- Updates available services list
- Used for duration calculations
- Pricing calculations based on service rates

### 6. **Visual Design Elements**

#### Color Coding:
- **Wash**: Blue
- **Dry**: Orange
- **Spin**: Cyan
- **Iron**: Amber
- **Fold**: Teal

#### State Indicators:
- **Selected**: Bold border, light background color
- **Disabled**: Grayed out (when weight = 0)
- **Premium**: Purple background/text

### 7. **Mobile Responsiveness**

- 2-column grid fits typical phone screens
- Scrollable content with bottom alignment
- Compact controls without overflow
- Touch-friendly button sizing
- Clear section separation with spacing

## Functional Features

### Weight Dependency
- All services (except notes) are disabled if basket weight = 0
- Visual feedback with gray overlay
- Clear UX to prevent configuration without weight

### Premium Services
- Only Wash and Dry support premium
- Premium toggle at bottom of tile
- Visual indicator (purple when selected)
- Affects pricing in receipt calculation

### Toggle vs Count Services
- **Wash, Dry, Spin**: Count-based (0, 1, 2, 3...)
- **Iron, Fold**: Toggle-only (0 or 1)
- Visual difference: Icon display (✓ for toggles, number for count)

### Summary Display
- Weight
- Service breakdown (only non-zero services)
- Premium indicators
- Special notes (if present)

## Database Mapping

Services from database are mapped as:
- `id` → `id`
- `service_type` → `serviceType` (matches tile title lookup)
- `name` → `name`
- `base_duration_minutes` → `baseDurationMinutes` (for duration estimation)
- `rate_per_kg` → `ratePerKg` (for pricing)
- `is_active` → `isActive`

## Ready for Backend

Implementation is complete. You need to:
1. ✅ Create `services` table in Supabase
2. ✅ Add service records (wash, dry, spin, iron, fold)
3. ✅ Create `basket_services` junction table
4. ✅ Application will auto-fetch services on flow start

## Sample Service Data

```sql
INSERT INTO services (service_type, name, base_duration_minutes, rate_per_kg, is_active) VALUES
  ('wash', 'Standard Wash', 30, 50.00, true),
  ('wash', 'Premium Wash', 45, 75.00, true),
  ('dry', 'Standard Dry', 20, 40.00, true),
  ('dry', 'Premium Dry', 30, 65.00, true),
  ('spin', 'Spin Cycle', 5, 20.00, true),
  ('iron', 'Iron Service', 15, 30.00, true),
  ('fold', 'Fold Service', 10, 25.00, true);
```

## Architecture Notes

The design follows web POS patterns:
- Tile-based interface for quick interaction
- Color-coded services for visual distinction
- Context-aware controls (disabled when invalid)
- Pricing integrated with service selection
- Real-time duration estimation

Mobile adaptations:
- 2-column grid instead of 4-column
- Vertical tab scroll instead of horizontal
- Compact spacing for small screens
- Touch-friendly button sizes
