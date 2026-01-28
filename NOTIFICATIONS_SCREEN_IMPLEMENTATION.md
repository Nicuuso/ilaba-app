# Notifications Screen Implementation Guide

## 📋 Overview

A fully-featured Notifications screen has been implemented with the following capabilities:

- ✅ Accessible via bell icon on Home screen (top-right)
- ✅ Displays chronological list of user notifications
- ✅ Each notification references a specific order (e.g., "Order #12344556")
- ✅ Expandable/collapsible accordion notifications
- ✅ Additional order details revealed on expansion
- ✅ Smooth animations and professional UI
- ✅ Complete with read/delete functionality

---

## 🎯 Features Implemented

### 1. **Bell Icon Integration (Home Screen)**

**File:** `lib/screens/navigation/home_menu_screen.dart`

The bell icon in the top-right of the Home screen now opens the Notifications Center:

```dart
actions: [
  IconButton(
    icon: const Icon(Icons.notifications),
    onPressed: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const NotificationsCenterScreen(),
        ),
      );
    },
  ),
],
```

### 2. **Enhanced Notifications Center Screen**

**File:** `lib/screens/notifications/notifications_center_screen.dart`

#### Features:

- **State Management:** Uses `Map<String, bool>` to track expanded/collapsed state
- **Expandable Notifications:** Click to expand/collapse each notification
- **Smooth Animations:** `AnimatedContainer` and `AnimatedCrossFade` for transitions
- **Read Status:** Automatically marks as read when tapped
- **Empty State:** Beautiful empty state when no notifications exist

### 3. **Notification Card Design**

#### Collapsed State:
```
┌─────────────────────────────────────┐
│ ● Order Status Update          ↓    │
│   Order #12344556 has been      ▪    │
│   accepted and is scheduled...        │
└─────────────────────────────────────┘
```

#### Expanded State:
```
┌─────────────────────────────────────┐
│ ● Order Status Update          ↑    │
│   Order #12344556 has been...        │
│ ─────────────────────────────────── │
│                                      │
│ 📦 Order ID         Order #12344556  │
│ ℹ️  Status           Ready for Pickup│
│ 🕐 Time             2 hours ago      │
│ 📍 Pickup Time      3:00 PM          │
│ 📝 Notes            Handle with care │
│                                      │
│ [Mark Read]  [Delete]               │
└─────────────────────────────────────┘
```

---

## 📱 UI Components

### A. Notification Header Row
- Status indicator dot (colored circle)
- Notification title
- Unread badge (if unread)
- Expand/collapse icon (animated rotation)

### B. Notification Message
- Preview text (2 lines in collapsed state)
- Full text in expanded state
- Smooth ellipsis overflow handling

### C. Expanded Details Section
- **Order ID:** Reference number with icon
- **Status:** Current order status with emoji
- **Time:** Relative time (e.g., "2 hours ago")
- **Additional Metadata:** Pickup time, delivery address, notes (if available)
- **Action Buttons:** Mark Read, Delete

### D. Status Colors
```dart
pending       → 🟠 Orange (#FF9800)
processing    → 🔵 Blue (#2196F3)
for_pick-up   → 🟣 Indigo (#4F46E5)
for_delivery  → 🟡 Purple (#9C27B0)
completed     → 🟢 Green (#28A745)
cancelled     → 🔴 Red (#DC3545)
```

---

## 🔄 Animation Details

### 1. **Container Expansion**
```dart
AnimatedContainer(
  duration: const Duration(milliseconds: 300),
  curve: Curves.easeInOut,
  // ... shadow and decoration changes
)
```

### 2. **Details Reveal**
```dart
AnimatedCrossFade(
  firstChild: const SizedBox.shrink(),
  secondChild: _buildExpandedDetails(...),
  duration: const Duration(milliseconds: 300),
)
```

### 3. **Icon Rotation**
```dart
AnimatedRotation(
  turns: isExpanded ? 0.5 : 0,
  duration: const Duration(milliseconds: 300),
  child: Icon(Icons.expand_more),
)
```

---

## 💾 Data Model

### NotificationModel Structure
```dart
class NotificationModel {
  final String id;              // Unique notification ID
  final String customerId;      // Customer reference
  final String orderId;         // Order number (e.g., "12344556")
  final String title;           // "Order Status Update"
  final String message;         // Detailed message
  final String status;          // Order status type
  final String type;            // "status_change", "order_update", etc.
  final DateTime createdAt;     // When notification was created
  final bool isRead;            // Read/unread status
  final Map<String, dynamic>? metadata;  // Additional details
}
```

### Example Notification
```json
{
  "id": "notif_abc123",
  "customer_id": "cust_xyz789",
  "order_id": "12344556",
  "title": "Order Status Update",
  "message": "Order #12344556 has been accepted and is scheduled for pickup.",
  "status": "for_pick-up",
  "type": "status_change",
  "created_at": "2026-01-28T14:30:00Z",
  "is_read": false,
  "metadata": {
    "pickup_time": "3:00 PM",
    "notes": "Handle with care"
  }
}
```

---

## 🔌 Integration Points

### 1. **Notifications Provider**
Provides:
- `fetchNotifications()` - Load notifications from backend
- `markAsRead(id)` - Mark single notification as read
- `markAllAsRead()` - Mark all as read
- `deleteNotification(id)` - Delete single notification
- `deleteAllNotifications()` - Delete all notifications

### 2. **Notifications Service**
Connects to Supabase for:
- Real-time notifications via subscriptions
- Auto-refresh every 30 seconds
- CRUD operations on notifications

---

## 🎨 Styling & Design

### Color Scheme
- **Primary:** Blue (unread notifications)
- **Secondary:** Status-specific colors
- **Background:** White/light blue for unread, white for read
- **Text:** Dark grey (#1f2937) for primary, grey for secondary

### Typography
- **Title:** `bodyMedium` with `fontWeight.w700` (unread)
- **Message:** `bodySmall` with `fontWeight.w500`
- **Labels:** `labelSmall` with `fontWeight.w500`
- **Metadata:** `bodySmall` with `fontWeight.w500`

### Spacing
- Card margin: 12px bottom
- Internal padding: 14px all sides
- Divider: 12px before/after
- Detail rows: 10px spacing between items

### Shadows
- Collapsed: `blur: 8px, opacity: 0.04`
- Expanded: `blur: 12px, opacity: 0.08`

---

## 📲 User Interaction Flow

1. **Home Screen → Tap Bell Icon**
   - Navigates to NotificationsCenterScreen
   - Auto-fetches latest notifications

2. **View Notifications List**
   - Chronological order (newest first)
   - Pull-to-refresh capability
   - Mark all / Delete all options in menu

3. **Expand Notification**
   - Tap notification to toggle expansion
   - Smooth animation reveals details
   - Auto-marks as read

4. **View Order Details**
   - Order ID (clickable in future iterations)
   - Current status with emoji
   - Pickup/delivery information
   - Special notes if available

5. **Take Action**
   - Mark as read (if unread)
   - Delete individual notification
   - Return to list

---

## 🔧 Code Structure

### Main Screen Component
```
NotificationsCenterScreen (StatefulWidget)
├── _expandedNotifications Map (State)
├── AppBar with:
│   ├── Title: "Notifications"
│   └── Actions: Mark All, Delete All
├── Body: ListView.builder
│   └── _buildNotificationCard (for each notification)
└── Refresh Indicator
```

### Card Components
```
_buildNotificationCard
├── AnimatedContainer (main card)
│   ├── Header Row
│   │   ├── Status indicator dot
│   │   ├── Title & badge
│   │   └── Expand/collapse icon
│   ├── Message preview
│   └── AnimatedCrossFade (details section)
│       └── _buildExpandedDetails
│           ├── Divider
│           ├── Detail rows (4-5)
│           │   └── _buildDetailRow
│           └── Action buttons
└── Gesture handling
```

---

## ✨ Status Label Mapping

```dart
pending       → "Order Pending 🎉"
for_pick-up   → "Ready for Pickup 📦"
processing    → "Processing 🧺"
for_delivery  → "On the Way 🚚"
completed     → "Order Complete ✨"
cancelled     → "Order Cancelled ❌"
```

---

## 🚀 Testing Scenarios

### Scenario 1: View Notifications List
```
1. Tap bell icon on Home screen
2. See list of notifications in chronological order
3. Verify empty state shows when no notifications
```

### Scenario 2: Expand/Collapse
```
1. Tap a notification
2. Card expands smoothly with details
3. Tap again to collapse
4. Animation is smooth (300ms)
```

### Scenario 3: Mark as Read
```
1. Tap unread notification to expand
2. Status automatically changes to read
3. Blue background changes to white
4. Unread badge disappears
```

### Scenario 4: Delete Notification
```
1. Expand a notification
2. Tap Delete button
3. Confirmation dialog appears
4. Notification removed from list
```

### Scenario 5: Refresh Notifications
```
1. Pull down to refresh
2. List updates with latest notifications
3. Spinner shows during refresh
```

---

## 🔐 Security Considerations

- Notifications only show for authenticated users
- Each user only sees their own notifications
- Backend validates customer_id matches authenticated user
- Supabase RLS policies enforce data isolation

---

## 📊 Performance Optimization

1. **State Management:**
   - Map-based tracking for expanded state (O(1) lookup)
   - Provider pattern for efficient rebuilds

2. **Animations:**
   - Duration: 300ms for smooth UX
   - Curve: easeInOut for natural feel
   - Prevents animation jank with AnimatedCrossFade

3. **List Rendering:**
   - ListView.builder for efficient memory usage
   - Only visible items are rendered
   - Constant item heights for optimal performance

4. **Refresh:**
   - RefreshIndicator with callback to provider
   - Non-blocking network operations

---

## 🐛 Known Limitations & Future Enhancements

### Current Limitations
1. Order details are metadata-only (no full order fetch)
2. No notification grouping (all shown individually)
3. No notification filtering/search

### Potential Enhancements
1. **Click Order ID:** Navigate to full order details screen
2. **Filter Notifications:** By status, date range, type
3. **Batch Actions:** Select multiple notifications
4. **Notification Preferences:** Settings for notification types
5. **Push Notifications:** Integration with Firebase Cloud Messaging
6. **Notification Sounds:** Audio feedback for new notifications
7. **Archive Notifications:** Move to separate archive instead of deleting
8. **Notification Timestamps:** More granular time display options

---

## 📝 Files Modified

### 1. `lib/screens/notifications/notifications_center_screen.dart`
- **Changes:** Complete rewrite with accordion functionality
- **Lines:** ~400 lines
- **New Methods:**
  - `_buildNotificationCard()` - Enhanced card with animations
  - `_buildExpandedDetails()` - Expanded content section
  - `_buildDetailRow()` - Individual detail rows
  - `_getStatusLabel()` - Status to emoji mapping
  
- **State Variables:**
  - `_expandedNotifications` - Map to track expanded state

- **New Features:**
  - Expandable cards with smooth animations
  - Detailed metadata display
  - Enhanced visual design

### 2. `lib/screens/navigation/home_menu_screen.dart`
- **Changes:** Connected bell icon to NotificationsCenterScreen
- **Import Added:**
  - `import 'package:ilaba/screens/notifications/notifications_center_screen.dart';`
- **Code Changed:**
  - Bell icon `onPressed` handler now navigates to NotificationsCenterScreen

---

## ✅ Verification Checklist

- ✅ Bell icon on Home screen navigates to Notifications
- ✅ Notifications display in chronological order
- ✅ Each notification shows order reference
- ✅ Notifications expand on tap
- ✅ Smooth animation transitions (300ms)
- ✅ Expanded view shows order details
- ✅ Can collapse by tapping again
- ✅ Mark as read functionality works
- ✅ Delete functionality works
- ✅ Empty state displays correctly
- ✅ Pull-to-refresh works
- ✅ Status colors are correct
- ✅ No compiler errors
- ✅ No lint warnings
- ✅ Responsive design on different screen sizes

---

## 📞 Support & Debugging

### Issue: Notifications not showing
- Check that notifications are being fetched from backend
- Verify Supabase connection is active
- Check NotificationsProvider is properly initialized

### Issue: Animation not smooth
- Verify device has sufficient performance
- Check if other animations are running simultaneously
- Consider reducing animation duration

### Issue: Accordion not expanding
- Verify `_expandedNotifications` state is updating
- Check for any errors in `setState()` calls
- Ensure notification ID is unique

### Issue: Order details not displaying
- Check that metadata is populated in notification model
- Verify metadata keys match expected format
- Check for null values in metadata

---

## 🎓 Learning Resources

- Flutter AnimatedContainer: https://api.flutter.dev/flutter/widgets/AnimatedContainer-class.html
- AnimatedCrossFade: https://api.flutter.dev/flutter/widgets/AnimatedCrossFade-class.html
- ListView.builder: https://api.flutter.dev/flutter/widgets/ListView/ListView.builder.html
- Provider pattern: https://pub.dev/packages/provider

---

## 📋 Summary

The Notifications screen provides a professional, modern interface for users to view and manage their order notifications. The expandable accordion design allows for clean information hierarchy while maintaining all necessary details. Smooth animations and intuitive interactions create a polished user experience consistent with the ILABA app design language.

**Status: ✅ Complete and Ready for Production**

Version: 1.0
Last Updated: January 28, 2026
