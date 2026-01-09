# Auth Error Handling & Debugging Guide

## What Was Fixed

Enhanced error handling throughout the authentication system to provide clear, helpful error messages to users instead of raw exceptions.

---

## Error Message Flow

### **Login Flow**
```
User Input → Validation (Frontend)
    ↓
AuthProvider.login() → cleans error message
    ↓
AuthService.login() → specific Supabase error handling
    ↓
Error Message → Snackbar notification (UI)
```

### **Common Login Errors**

| Error | Cause | Solution |
|-------|-------|----------|
| "Invalid email or password" | Wrong email OR wrong password | Check both email and password |
| "Email not confirmed" | User clicked link in confirmation email | Check email (including spam) for confirmation link |
| "User profile not found" | Auth created but customer record missing | Contact support |
| "Please enter a valid email" | Email format invalid | Use format: user@domain.com |
| "Password must be at least 6 characters" | Password too short during input | Enter 6+ character password |

---

## Debug Logging

All auth operations now include debug prints visible in the Flutter console:

### **Login Logs**
```
🔐 Login attempt: user@example.com
✅ Auth successful, fetching customer profile...
✅ Customer profile fetched successfully
```

**OR**

```
🔐 Login attempt: user@example.com
❌ AuthException: 401 - Invalid login credentials
```

### **Signup Logs**
```
📝 Signup: Creating auth for user@example.com
✅ Auth created, storing customer profile...
✅ Signup complete
```

### **Password Reset Logs**
```
🔑 Password reset request for: user@example.com
✅ Password reset email sent
```

### **Error Logs**
```
❌ Login failed: Invalid email or password
❌ AuthException during signup: 400 - User already exists
❌ Password reset error: PostgrestException - ...
```

---

## How to Check Errors

### **1. Flutter Console Output**
Open the Flutter console/terminal and watch for debug prints:
- Look for 🔐, 📝, 🔑 emojis for operations
- Look for ❌ for errors
- Copy the full error message

### **2. In-App Error Messages**
Errors are displayed as floating snackbars at the bottom of the screen:
- Red background
- White text with the error message
- Visible for 3-4 seconds
- Can appear multiple times if multiple errors

### **3. Error Message Examples**

**Valid but wrong password:**
```
User: test@example.com
Password: wrongpass
Result: "Invalid email or password"
```

**Email not in database:**
```
User: notregistered@example.com
Result: "No account found with this email" (during password reset)
         "Invalid email or password" (during login)
```

**Email already registered:**
```
User: existing@example.com
Action: Try to signup again
Result: "Email address already registered. Please login or use a different email"
```

---

## Error Message Cleaning

**Before (Raw Exception):**
```
Exception: Invalid login credentials
Exception: Login failed: No user returned
```

**After (Cleaned):**
```
Invalid email or password
User profile not found. Please contact support
```

The "Exception: " prefix is automatically removed, and generic messages are replaced with user-friendly ones.

---

## Troubleshooting Checklist

### **"Login failed but no error message shown"**
- [ ] Check Flutter console for debug logs
- [ ] Ensure snackbars can be displayed (no navigator issues)
- [ ] Check if `authProvider.errorMessage` is null

### **"Cannot see what went wrong"**
- [ ] Look at the floating snackbar at bottom of screen
- [ ] Check Flutter console for 🔐 or ❌ emojis
- [ ] Wait for full error message (may be multi-line)

### **"Same error keeps appearing"**
- [ ] Clear the error with `authProvider.clearError()`
- [ ] Or refresh the page/navigate away and back

### **"Password reset not working"**
- [ ] Check email (including spam folder)
- [ ] Verify email address is registered
- [ ] Check console for "No account found" error
- [ ] Wait a moment before retrying (API throttling)

### **"Can't signup with valid email"**
- [ ] Check if email already registered
- [ ] Verify password is 6+ characters
- [ ] Check all required fields (birthdate, gender)
- [ ] Verify email format

---

## Files Modified

1. ✅ `lib/services/auth_service.dart` - Enhanced error handling with debug logs
2. ✅ `lib/providers/auth_provider.dart` - Clean error message extraction
3. ✅ `lib/screens/login_screen.dart` - Added validation + debug logs
4. ✅ `lib/screens/signup_screen.dart` - Added debug logs
5. ✅ `lib/screens/forgot_password_screen.dart` - Added debug logs

---

## Key Improvements

### **Service Layer (auth_service.dart)**
- ✅ Catch `AuthException` separately with status codes
- ✅ Map Supabase error codes to user-friendly messages
- ✅ Debug print every step: 🔐 🔑 📝 ✅ ❌
- ✅ Handle common error patterns
- ✅ Extract clean error messages

### **Provider Layer (auth_provider.dart)**
- ✅ Remove "Exception: " prefix from error messages
- ✅ Pass through service error messages unchanged
- ✅ Notify listeners of state changes
- ✅ Consistent error handling across all methods

### **UI Layer (screens)**
- ✅ Frontend validation before sending to backend
- ✅ Display clean error messages in snackbars
- ✅ Debug logs for each action
- ✅ User-friendly guidance for errors

---

## Testing Auth Errors

### **Test Invalid Login**
```
Email: wrong@example.com
Password: anypassword
Expected: "Invalid email or password"
```

### **Test Missing Customer Profile**
This is harder to test as it requires:
1. Manually create auth user in Supabase
2. Don't create corresponding customer record
3. Try to login with that user
Expected: "User profile not found. Please contact support"

### **Test Duplicate Signup**
```
Email: existing@example.com (already registered)
Expected: "Email address already registered. Please login or use a different email"
```

### **Test Password Reset for Non-existent Email**
```
Email: nonexistent@example.com
Expected: "No account found with this email address"
```

---

## Notes

- All error messages are user-friendly and actionable
- Debug logs show complete technical details for troubleshooting
- Snackbars appear automatically on error
- Errors are automatically cleared when starting new auth operations
- Loading state prevents multiple submissions
- Validation happens before sending to server

