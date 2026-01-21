# Booking UI Fixes - January 21, 2026

## Issues Fixed

### 1. Premium Service Disabling Logic ✅

**Problem**: Premium toggle buttons were not disabling properly when their variants weren't available.

**Solution**: Implemented separate validation for basic and premium service variants.

**Changes in `lib/screens/booking_baskets_screen.dart`**:

#### Added Helper Method

```dart
/// Check if premium variant of a service is active
bool _isPremiumServiceActive(List<LaundryService> services, String serviceType) {
  try {
    final service = services.firstWhere(
      (s) => s.serviceType == serviceType && s.name.toLowerCase().contains('premium'),
    );
    return service.isActive;
  } catch (e) {
    return false;
  }
}
```

#### Updated Service Disabling Logic

For services with premium variants (Wash, Dry), the disabled state now checks:

```dart
disabled: activeBasket.weightKg == 0 ||                                    // No weight
         (!activeBasket.washPremium && !_isServiceActive(..., 'wash')) ||  // Basic not active
         (activeBasket.washPremium && !_isPremiumServiceActive(..., 'wash')) // Premium not active
```

**How it works**:

- If user hasn't selected premium (`washPremium = false`), check if basic variant is active
- If user has selected premium (`washPremium = true`), check if premium variant is active
- Service is disabled if either the weight is 0 OR the appropriate variant is not available

---

### 2. Product Image Loading ✅

**Problem**: Images weren't displaying in the products pane with no loading feedback.

**Solution**: Enhanced image loading with loading states, better error handling, and proper feedback.

**Changes in `lib/screens/booking_products_screen.dart`**:

#### Added Loading State Tracking

```dart
class _BookingProductsScreenState extends State<BookingProductsScreen> {
  late TextEditingController _searchController;
  final Map<String, bool> _imageLoadingStates = {};
```

#### Improved Image Widget

```dart
child: Stack(
  fit: StackFit.expand,
  children: [
    // Loading indicator
    if (!(_imageLoadingStates[product.id] ?? false))
      Container(
        color: Colors.grey[200],
        child: Center(
          child: CircularProgressIndicator(...),
        ),
      ),
    // Image with proper callbacks
    Image.network(
      product.imageUrl!,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          // Mark as loaded when complete
          setState(() {
            _imageLoadingStates[product.id] = true;
          });
          return child;
        }
        return const SizedBox.expand();
      },
      errorBuilder: (context, error, stackTrace) {
        // Show helpful error message
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.image_not_supported, ...),
              Text('Image failed to load', ...),
            ],
          ),
        );
      },
    ),
  ],
),
```

**Features**:

- Shows loading spinner while image is downloading
- Replaces spinner with image once loaded
- Shows error icon + message if image fails to load
- Handles missing/null imageUrl gracefully

---

## Testing Checklist

### Premium Services

- [ ] Create a basket with weight
- [ ] Toggle wash between basic and premium
  - Should disable premium toggle if premium "Wash" service is `isActive: false`
  - Should disable basic toggle if basic "Wash" service is `isActive: false`
  - Both should disable when weight = 0
- [ ] Same for Dry service
- [ ] Non-premium services (Spin, Iron, Fold) should only disable on weight = 0

### Product Images

- [ ] Verify images with valid URLs display correctly
- [ ] Check loading spinner appears briefly while loading
- [ ] Test broken image URLs show error icon + "Image failed to load"
- [ ] Test products without images don't break the UI
- [ ] Verify performance with multiple products

---

## Technical Details

### Service Database Structure

For premium services to work correctly, your services table should have entries like:

```sql
-- Basic service
INSERT INTO laundry_services (id, service_type, name, is_active, ...)
VALUES ('wash-basic', 'wash', 'Wash', true, ...);

-- Premium variant
INSERT INTO laundry_services (id, service_type, name, is_active, ...)
VALUES ('wash-premium', 'wash', 'Wash (Premium)', true, ...);
```

The key is:

- Same `service_type` value for both
- Different names (basic doesn't contain "premium", premium variant does)
- Can set `is_active` independently for each variant

### Product Images URL Format

The `imageUrl` field in products table should contain:

- Full URLs: `https://example.com/images/product.jpg`
- Supabase storage URLs: `https://project.supabase.co/storage/v1/object/public/...`
- Relative paths (if serving from public folder): `/products/product.jpg`

---

## Implementation Guide Reference

See `POS_IMPLEMENTATION_GUIDE.md` section:

- "1. Handling Premium Basket Services Disabling Logic"
- "2. Loading Product Images in Products Pane"
