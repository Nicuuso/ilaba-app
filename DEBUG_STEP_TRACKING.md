# Order Creation Step Tracking - Enhanced Debug Output

## Summary of Changes

The order submission flow in `booking_flow_screen.dart` now includes **detailed step-by-step tracking** to identify exactly where order creation fails.

## Changes Made

### 1. Enhanced `_submitOrder()` Method
- **Location**: [booking_flow_screen.dart](booking_flow_screen.dart#L228)
- **Changes**:
  - Added `String currentStep` variable to track each phase
  - Added `debugPrint()` calls showing:
    - ✓ Step start (e.g., "Reading booking state")
    - ✓ Step completion with details
    - ✓ Expected results at each phase
  - Wraps each major section in try-catch with step tracking

### 2. Step Tracking Points

The following steps now emit debug output:

```
✓ Reading booking state
✓ Validating user  
✓ Computing receipt → Total = $X.XX
✓ Building baskets → 2 baskets built
✓ Building products → 3 products built
✓ Building payments → Payments built
✓ Creating order payload
✓ Creating order request
✓ Submitting order to API
✓ Order submitted successfully
✓ Resetting booking state
✓ Navigating to success screen
```

If any step fails:
```
❌ ERROR AT UNKNOWN STEP: [error details]
```

### 3. Enhanced Error Dialog

**Location**: [booking_flow_screen.dart](booking_flow_screen.dart#L512)

**New Section**: Failed Step Indicator
- Shows exactly which step failed (e.g., "Submitting order to API")
- Displayed in amber warning box in error dialog
- Appears between error message and debug details

**Enhanced Parameters**:
```dart
void _showErrorDialog(
  String message,
  List<Map<String, dynamic>>? insufficientItems, {
  CreateOrderResponse? response,
  String? errorException,
  Map<String, dynamic>? payload,
  String? failedStep,  // NEW: Shows which step failed
})
```

## Debug Output Example

When order submission fails, you'll now see in the console:

```
✓ Reading booking state
✓ Validating user
   User ID: a1b2c3d4-e5f6-7890-abcd-ef1234567890
   User ID is empty: false
   User First Name: John
   User Phone: +1234567890
✓ Receipt computed: Total = 450.0
✓ Baskets built: 2 baskets
✓ Products built: 1 products
✓ Payments built: 1 payments
✓ Order payload created
✓ Order request created
👤 Customer ID being sent: a1b2c3d4-e5f6-7890-abcd-ef1234567890
📊 Full Payload: {customerId: "...", total: 450.0, ...}
✓ Order submitted successfully
❌ ERROR AT UNKNOWN STEP: [response error or exception]
```

## Error Dialog Display

The error dialog now shows:

1. **Main Error Message** (red box)
   - What went wrong

2. **Failed At Step** (amber box) - NEW
   - Which operation failed
   - Examples: "Reading booking state", "Submitting order to API"

3. **Insufficient Items** (if applicable)
   - Products that are out of stock

4. **Technical Details** (expandable)
   - Exception details
   - API response
   - Full payload sent

## How to Use This for Debugging

### When order fails in production:

1. **Check the console** for debug output
2. **Look for the ✓ markers** - stops where failure occurs
3. **Check the error dialog** - "Failed At" section shows the step
4. **Expand "Technical Details"** for full payload and response

### Example Troubleshooting Scenarios:

**Scenario 1: Fails at "Validating user"**
```
❌ Fails at step: Validating user
→ Check: Is customer ID empty? Did user log out?
```

**Scenario 2: Fails at "Building baskets"**
```
❌ Fails at step: Building baskets
→ Check: Is service type missing? Is weight 0?
```

**Scenario 3: Fails at "Submitting order to API"**
```
❌ Fails at step: Submitting order to API
→ Check: Is customer ID correct? Are there network issues?
→ Expand "Technical Details" to see API response
```

## Testing the Enhanced Debugging

Test cases to verify step tracking:

1. ✅ **Successful order**
   - All steps show complete with ✓
   - No error dialog appears

2. ❌ **Missing user**
   - Fails at: "Validating user"
   - Error: "User not authenticated"

3. ❌ **Network error**
   - Fails at: "Submitting order to API"
   - Error: Network-related exception

4. ❌ **Backend validation error**
   - Fails at: "Submitting order to API"
   - Error: Backend response error in Technical Details

## Code Locations

- **Main method**: [_submitOrder()](booking_flow_screen.dart#L228)
- **Error dialog**: [_showErrorDialog()](booking_flow_screen.dart#L512)
- **Step tracking**: Throughout _submitOrder() method

## Related Files

- `order_creation_service.dart` - API endpoint
- `order_models_legacy.dart` - Payload models
- `booking_state_provider.dart` - State management
- `MOBILE_APP_ORDER_PAYLOAD.md` - API specification
