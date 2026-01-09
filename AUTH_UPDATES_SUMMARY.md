# Auth System Updates - Summary

## Overview
Updated authentication system and signup flow to match the new database schema. All changes enforce required `birthdate` and `gender` fields per the refactored schema.

---

## Changes Made

### 1. **User Model** (`lib/models/user.dart`) ✅
**What Changed:**
- `birthdate` changed from `DateTime?` → `DateTime` (required)
- `gender` changed from `String?` → `String` (required)
- `phoneNumber` changed from `String?` → `String` (required)
- Added `updatedAt: DateTime?` field (maps to database `updated_at`)

**Why:**
- New schema enforces these as NOT NULL columns
- Ensures data integrity at the model level
- Prevents invalid user objects from being created

**Code:**
```dart
final DateTime birthdate;      // NOW REQUIRED
final String gender;            // NOW REQUIRED: 'male', 'female', 'other'
final String phoneNumber;       // NOW REQUIRED
final DateTime? updatedAt;      // NEW
```

---

### 2. **Auth Service** (`lib/services/auth_service.dart`) ✅
**What Changed:**
- Added `birthdate: DateTime` and `gender: String` to signup method signature
- Updated `AuthServiceImpl.signup()` to accept and store birthdate & gender
- Passes new required fields to User model constructor

**Why:**
- Service layer must enforce schema requirements
- Ensures only valid users with complete profiles can be created
- Prevents partial user creation

**Code:**
```dart
Future<models.User> signup({
  required String firstName,
  required String lastName,
  required String email,
  required String phoneNumber,
  required DateTime birthdate,   // NEW
  required String gender,         // NEW
  String? middleName,
  String? address,
  required String password,
});
```

---

### 3. **Auth Provider** (`lib/providers/auth_provider.dart`) ✅
**What Changed:**
- Updated `signup()` method to accept `birthdate` and `gender` parameters
- Passes them to auth service
- Updated method signature to match service layer

**Why:**
- Provider is the bridge between UI and service
- Must validate and pass all required data to services
- Ensures consistent state management

---

### 4. **Signup Screen** (`lib/screens/signup_screen.dart`) ✅ **COMPLETELY REWRITTEN**
**What Changed:**
- Converted from stateless to stateful widget
- Added comprehensive form validation
- Implemented proper UI with all required fields:
  - First Name (required)
  - Middle Name (optional)
  - Last Name (required)
  - **Birthdate picker** (required) ← NEW
  - **Gender dropdown** (required) ← NEW
  - Phone Number (required)
  - Email Address (required)
  - Address (optional)
  - Password (required, min 6 chars)
  - Confirm Password (required, must match)

**UI Improvements:**
- Material Design 3 compliant
- Date picker for birthdate selection
- Dropdown for gender selection (male, female, other)
- Icon prefixes for all fields
- Password visibility toggles
- Form validation with error messages
- Loading state on signup button
- Consistent styling

**Why:**
- New schema requires birthdate and gender at signup
- Original stub was just placeholder UI
- Users must provide complete profile information upfront
- Better UX with proper date/gender pickers

**Code Highlights:**
```dart
// Birthdate selection
GestureDetector(
  onTap: () => _selectBirthdate(context),
  child: InputDecorator(
    decoration: InputDecoration(labelText: 'Birthdate *'),
    child: Text(_selectedBirthdate?.toString() ?? 'Select birthdate'),
  ),
)

// Gender selection
DropdownButton<String>(
  value: _selectedGender,
  items: [
    DropdownMenuItem(value: 'male', child: Text('Male')),
    DropdownMenuItem(value: 'female', child: Text('Female')),
    DropdownMenuItem(value: 'other', child: Text('Other')),
  ],
  onChanged: (value) => setState(() => _selectedGender = value),
)

// Complete validation
if (_passwordController.text != _confirmPasswordController.text) {
  _showErrorSnackbar('Passwords do not match');
  return;
}
```

---

## Data Flow

### Before
```
SignupScreen (stub) → AuthProvider.signup() → AuthService.signup() 
                      ↓
                    User model (incomplete fields)
                      ↓
                    Supabase customers table (NULL violations!)
```

### After
```
SignupScreen (form with validation)
    ↓
  Collect: firstName, lastName, birthdate, gender, phone, email, password
    ↓
  Validate: all required, dates valid, passwords match, email format
    ↓
  AuthProvider.signup(birthdate, gender, ...)
    ↓
  AuthService.signup(birthdate, gender, ...)
    ↓
  Create User object (all required fields present)
    ↓
  Supabase customers table INSERT (all NOT NULL constraints satisfied)
    ↓
  Success → Home screen
```

---

## Validation Rules Enforced

1. **First Name** - Required, non-empty
2. **Last Name** - Required, non-empty
3. **Phone Number** - Required, non-empty
4. **Email Address** - Required, non-empty, format validation recommended
5. **Birthdate** - Required, must be 13+ years old
6. **Gender** - Required, must be one of: 'male', 'female', 'other'
7. **Password** - Required, minimum 6 characters
8. **Confirm Password** - Must match password field
9. **Middle Name** - Optional, can be empty
10. **Address** - Optional, can be empty

---

## Database Mapping

| Field | Type | Null | Description |
|-------|------|------|-------------|
| `id` | UUID | NO | PK - Generated |
| `auth_id` | UUID | YES | Supabase Auth ID |
| `first_name` | TEXT | NO | From signup form |
| `middle_name` | TEXT | YES | From signup form (optional) |
| `last_name` | TEXT | NO | From signup form |
| `birthdate` | DATE | NO | From date picker ✨ NEW |
| `gender` | TEXT | NO | From dropdown ✨ NEW (values: male, female, other) |
| `phone_number` | TEXT | NO | From signup form |
| `email_address` | TEXT | YES | From signup form |
| `address` | TEXT | YES | From signup form (optional) |
| `loyalty_points` | INT | YES | Default 0 |
| `created_at` | TIMESTAMP | NO | Auto-set |
| `updated_at` | TIMESTAMP | NO | Auto-set |

---

## Breaking Changes

⚠️ **Existing Code Expecting Optional Birthdate/Gender:**

If any code still references these as nullable:
```dart
// ❌ OLD (will fail)
User user = ...;
DateTime? birthdate = user.birthdate;
String? gender = user.gender;

// ✅ NEW (correct)
User user = ...;
DateTime birthdate = user.birthdate;  // Always non-null
String gender = user.gender;          // Always non-null
```

**Search & Update:**
- Grep for `user.birthdate?` → remove the `?`
- Grep for `user.gender?` → remove the `?`
- Grep for `user.phoneNumber?` → remove the `?`

---

## Files Modified

1. ✅ `lib/models/user.dart` - Added required fields, JSON serialization
2. ✅ `lib/services/auth_service.dart` - Updated signup signature
3. ✅ `lib/providers/auth_provider.dart` - Updated signup with new parameters
4. ✅ `lib/screens/signup_screen.dart` - Complete UI rewrite with validation

---

## Testing Checklist

- [ ] Test birthdate picker works and validates 13+ year minimum
- [ ] Test gender dropdown shows all 3 options
- [ ] Test password validation (min 6 chars, match confirmation)
- [ ] Test signup success creates user with all fields
- [ ] Test signup failure shows proper error messages
- [ ] Test required field validation
- [ ] Test navigation to home screen after successful signup
- [ ] Verify database contains all fields (birthdate, gender, updated_at)

---

## Next Steps

1. **Remove `unit` field from Product model** (schema change)
2. **Update order/booking models** to use JSON structure (handling, breakdown)
3. **Update order creation** to send `source='app'` field
4. **Handle new order statuses** (for_pick-up, for_delivery)

