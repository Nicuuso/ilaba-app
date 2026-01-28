# Notifications Center - Architecture Overview

## System Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                     ILABA APP - NOTIFICATIONS SYSTEM                 │
└─────────────────────────────────────────────────────────────────────┘

                              ┌──────────────────┐
                              │   USER LOGIN     │
                              │  (Customer ID)   │
                              └────────┬─────────┘
                                       │
                                       ▼
                         ┌─────────────────────────┐
                         │ NotificationsProvider   │
                         │ (State Management)      │
                         │                         │
                         │ • notifications[]       │
                         │ • unreadCount           │
                         │ • isLoading             │
                         │ • error                 │
                         │ • Auto polling (30s)    │
                         └──────────┬──────────────┘
                                    │
                    ┌───────────────┼───────────────┐
                    │               │               │
                    ▼               ▼               ▼
        ┌──────────────────┐  ┌────────────────┐  ┌──────────────────┐
        │ Notification     │  │     UI Layer   │  │ Service Layer    │
        │ Bell Widget      │  │ (Screens)      │  │ (Supabase API)   │
        │                  │  │                │  │                  │
        │ • Shows badge    │  │ • Center       │  │ • CRUD ops       │
        │ • Unread count   │  │ • Cards        │  │ • Error handling │
        │ • Navigation     │  │ • Actions      │  │ • Logging        │
        └────────┬─────────┘  └────────┬───────┘  └────────┬─────────┘
                 │                    │                    │
                 └────────────────────┼────────────────────┘
                                      │
                                      ▼
                          ┌────────────────────────┐
                          │ SUPABASE DATABASE      │
                          │                        │
                          │ notifications table    │
                          │ • id                   │
                          │ • customer_id          │
                          │ • order_id             │
                          │ • title                │
                          │ • message              │
                          │ • status               │
                          │ • is_read              │
                          │ • created_at           │
                          │ • metadata             │
                          └────────────────────────┘
```

---

## Data Flow Diagram

```
ORDER STATUS CHANGE EVENT
         │
         ▼
    Update Database
    (orders table)
         │
         ▼
    Trigger Notification
    notifyStatusChange()
         │
         ▼
    ┌─────────────────────────────────────┐
    │ NotificationsService                │
    │ • Create notification model         │
    │ • Insert into Supabase              │
    └────────────┬────────────────────────┘
                 │
                 ▼
    ┌─────────────────────────────────────┐
    │ Supabase INSERT notifications       │
    │ (Store in database)                 │
    └────────────┬────────────────────────┘
                 │
                 ▼
    ┌─────────────────────────────────────┐
    │ NotificationsProvider               │
    │ • Refresh notifications[]           │
    │ • Update unreadCount                │
    │ • notifyListeners()                 │
    └────────────┬────────────────────────┘
                 │
                 ▼
    ┌─────────────────────────────────────┐
    │ UI Updates                          │
    │ • Badge shows new count             │
    │ • Notification appears in list      │
    │ • Message displays to customer      │
    └─────────────────────────────────────┘
```

---

## Component Interaction Diagram

```
                     NotificationsCenterScreen
                              │
                    ┌─────────┼─────────┐
                    │         │         │
                    ▼         ▼         ▼
            AppBar    List    Actions
            (title)  (cards)  (buttons)
                    │
                    ├─ Read notification
                    ├─ Delete notification
                    ├─ Mark all as read
                    └─ Delete all
                         │
                         ▼
              NotificationsProvider
                    │
        ┌───────────┼───────────┐
        │           │           │
        ▼           ▼           ▼
    Mark   Delete  Fetch
    Read   Notif   Notifs
        │           │           │
        └───────────┼───────────┘
                    │
                    ▼
          NotificationsService
                    │
        ┌───────────┴───────────┐
        │                       │
        ▼                       ▼
    Supabase Query         Supabase Update
    (SELECT)               (UPDATE/DELETE)
        │                       │
        └───────────┬───────────┘
                    │
                    ▼
            Supabase Database
            (notifications)
```

---

## Status Transition Flow

```
Order Created (pending)
        │
        ├─ ✉️ Notification: "Your order has been placed" 🎉
        │
        ▼
    Staff Reviews
        │
        ├─ UPDATE order status → 'processing'
        │
        ├─ ✉️ Notification: "Your order is being processed" 🧺
        │
        ▼
    Processing Complete
        │
        ├─ UPDATE order status → 'for_pick-up'
        │
        ├─ ✉️ Notification: "Ready for pickup at our store" 📦
        │
        ▼
    (Branch: Pickup or Delivery)
        │
        ├─ If PICKUP:
        │  └─ Customer picks up (no status change)
        │     └─ UPDATE order status → 'completed'
        │        └─ ✉️ Notification: "Order successfully delivered" ✨
        │
        └─ If DELIVERY:
           └─ UPDATE order status → 'for_delivery'
              ├─ ✉️ Notification: "Out for delivery to your location" 🚚
              │
              └─ Delivered
                 └─ UPDATE order status → 'completed'
                    └─ ✉️ Notification: "Order successfully delivered" ✨
```

---

## Widget Tree

```
MyApp
  └─ MultiProvider
      ├─ NotificationsProvider (ChangeNotifier)
      └─ MyAppWidget
          └─ HomeMenuScreen
              ├─ AppBar
              │  └─ NotificationBellWidget ⭐
              │      ├─ Icon: notifications_outlined
              │      └─ Badge: unreadCount (red circle)
              │
              └─ Body
                  ├─ Orders List
                  └─ Other Navigation
                  
                  (When bell clicked:)
                  └─ Navigator.push()
                     └─ NotificationsCenterScreen ⭐
                         ├─ AppBar
                         │  ├─ Title: "Notifications"
                         │  └─ Menu: Mark all, Delete all
                         │
                         └─ ListView
                            └─ NotificationCard × N
                                ├─ Status indicator dot
                                ├─ Title
                                ├─ Message
                                ├─ Timestamp
                                └─ Actions
                                   ├─ Mark as read
                                   └─ Delete
```

---

## State Management Flow

```
NotificationsProvider
│
├─ initialize(customerId)
│  └─ Starts 30-second polling
│
├─ _notifications: List<NotificationModel>
│  └─ Updated by fetchNotifications()
│
├─ _unreadCount: int
│  └─ Calculated from _notifications.where(!isRead)
│
├─ _isLoading: bool
│  └─ During fetch operations
│
└─ _error: String?
   └─ Error messages

Actions trigger:
  ├─ fetchNotifications()
  ├─ notifyStatusChange()
  ├─ markAsRead()
  ├─ markAllAsRead()
  ├─ deleteNotification()
  └─ deleteAllNotifications()

Each action:
  1. Calls NotificationsService method
  2. Updates _notifications
  3. Calls notifyListeners()
  4. UI rebuilds automatically
```

---

## Polling Mechanism

```
App Starts
    │
    ▼
NotificationsProvider.initialize(customerId)
    │
    ├─ fetchNotifications() [immediate]
    │
    ├─ _startPolling()
    │  │
    │  └─ Schedule Future.delayed(30s)
    │     │
    │     ├─ fetchNotifications()
    │     │
    │     └─ _startPolling() [recursive]
    │
    └─ Repeats every 30 seconds...

This ensures:
  ✓ Initial load is quick
  ✓ Background sync continues
  ✓ No missed updates
  ✓ Reasonable battery usage
```

---

## Message Templates Map

```
StatusMessages (Constant Map)
│
├─ 'pending'
│  └─ title: "Order Confirmed! 🎉"
│     message: "We've received your order..."
│
├─ 'for_pick-up'
│  └─ title: "Ready for Pickup! 📦"
│     message: "Your order is ready..."
│
├─ 'processing'
│  └─ title: "Processing Your Order 🧺"
│     message: "Our team is processing..."
│
├─ 'for_delivery'
│  └─ title: "On the Way! 🚚"
│     message: "Your order is out for delivery..."
│
├─ 'completed'
│  └─ title: "Order Complete! ✨"
│     message: "Order has been delivered..."
│
└─ 'cancelled'
   └─ title: "Order Cancelled"
      message: "Your order has been cancelled..."
```

---

## Error Handling Flow

```
User Action (e.g., fetch notifications)
    │
    ▼
NotificationsProvider.fetchNotifications()
    │
    ├─ _isLoading = true
    │ _error = null
    │ notifyListeners()
    │
    ▼
Try: Call NotificationsService
    │
    ├─ Success:
    │  ├─ _notifications = result
    │  ├─ _unreadCount = calculated
    │  └─ _error = null
    │
    └─ Catch Error:
       ├─ _error = "Failed to fetch..."
       └─ Print error log

Finally:
    │
    ├─ _isLoading = false
    │
    └─ notifyListeners()

UI reflects:
  - If _isLoading: CircularProgressIndicator
  - If _error: Error message
  - If data: Notification list
```

---

## Integration Points

```
main.dart
  └─ Add NotificationsProvider to MultiProvider ✓

HomeMenuScreen (or Dashboard)
  ├─ Initialize provider: context.read<NotificationsProvider>()
  │                           .initialize(customerId) ✓
  │
  └─ Add to AppBar: actions: [NotificationBellWidget()] ✓

Orders Management (Backend)
  └─ After status update: context.read<NotificationsProvider>()
       .notifyStatusChange(orderId, newStatus, oldStatus) ✓

Route Setup
  └─ Navigator.push() → NotificationsCenterScreen ✓
```

---

## Summary

This architecture provides:
- ✅ **Clean separation of concerns** (Model, Service, Provider, UI)
- ✅ **Automatic state management** (Provider pattern)
- ✅ **Real-time updates** (30-second polling)
- ✅ **Professional UI** (Beautiful cards and cards)
- ✅ **Error resilience** (Graceful error handling)
- ✅ **Scalability** (Database indexes for performance)
- ✅ **Extensibility** (Easy to add features)

The system is designed for **production use** with a focus on **user experience** and **reliability**! 🚀
