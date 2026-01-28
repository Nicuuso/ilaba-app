// Example: How to Integrate Notifications into Orders Screen
// This shows how to trigger notifications when order status changes

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ilaba/providers/notifications_provider.dart';

/// Example function showing how to update order status and trigger notification
Future<void> updateOrderStatusExample(
  BuildContext context,
  String orderId,
  String currentStatus,
  String newStatus,
) async {
  try {
    // Step 1: Update order status in database
    // TODO: Replace with your actual order update API call
    print('📝 Updating order status in database...');
    // await supabase.from('orders')
    //     .update({'status': newStatus})
    //     .eq('id', orderId);

    // Step 2: Create notification for status change
    print('📲 Creating notification...');
    await context.read<NotificationsProvider>().notifyStatusChange(
      orderId: orderId,
      newStatus: newStatus,
      previousStatus: currentStatus,
    );

    // Step 3: Show success message
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Order status updated to $newStatus'),
          backgroundColor: Colors.green,
        ),
      );
    }

    print('✅ Order status updated and customer notified!');
  } catch (e) {
    print('❌ Error updating order status: $e');
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

/// Example widget showing integration in a button
class UpdateOrderStatusButtonExample extends StatelessWidget {
  final String orderId;
  final String currentStatus;
  final String newStatus;

  const UpdateOrderStatusButtonExample({
    required this.orderId,
    required this.currentStatus,
    required this.newStatus,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        updateOrderStatusExample(
          context,
          orderId,
          currentStatus,
          newStatus,
        );
      },
      child: Text('Update to $newStatus'),
    );
  }
}

/// Example: Integration in main.dart for app initialization
void initializeNotificationsExample(
  BuildContext context,
  String currentUserId,
) {
  // Call this in your HomeScreen or main app initialization
  context.read<NotificationsProvider>().initialize(currentUserId);
}

/// Example: Add to AppBar
class AppBarWithNotificationsExample extends StatelessWidget {
  const AppBarWithNotificationsExample({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Text('Orders'),
      elevation: 0,
      actions: const [
        // Add the notification bell widget here
        // NotificationBellWidget(),
      ],
    );
  }
}

/// Example: Status transition flow
class OrderStatusTransitionExample {
  static Future<void> transitionToProcessing(
    BuildContext context,
    String orderId,
  ) async {
    await updateOrderStatusExample(
      context,
      orderId,
      'pending',
      'processing',
    );
  }

  static Future<void> transitionToPickup(
    BuildContext context,
    String orderId,
  ) async {
    await updateOrderStatusExample(
      context,
      orderId,
      'processing',
      'for_pick-up',
    );
  }

  static Future<void> transitionToDelivery(
    BuildContext context,
    String orderId,
  ) async {
    await updateOrderStatusExample(
      context,
      orderId,
      'for_pick-up',
      'for_delivery',
    );
  }

  static Future<void> transitionToCompleted(
    BuildContext context,
    String orderId,
  ) async {
    await updateOrderStatusExample(
      context,
      orderId,
      'for_delivery',
      'completed',
    );
  }

  static Future<void> transitionToCancelled(
    BuildContext context,
    String orderId,
  ) async {
    await updateOrderStatusExample(
      context,
      orderId,
      'pending', // Can be cancelled from any status
      'cancelled',
    );
  }
}

// =============================================================================
// Integration Points in Your Existing Code
// =============================================================================

/*
STEP 1: In main.dart - Add NotificationsProvider to MultiProvider
────────────────────────────────────────────────────────────────

import 'package:ilaba/providers/notifications_provider.dart';

MultiProvider(
  providers: [
    // ... existing providers
    ChangeNotifierProvider(create: (_) => NotificationsProvider()),
  ],
  child: MyApp(),
)


STEP 2: In HomeMenuScreen or Dashboard - Initialize Provider
────────────────────────────────────────────────────────────────

class HomeMenuScreen extends StatefulWidget {
  @override
  State<HomeMenuScreen> createState() => _HomeMenuScreenState();
}

class _HomeMenuScreenState extends State<HomeMenuScreen> {
  @override
  void initState() {
    super.initState();
    // Initialize notifications for current user
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      final currentUser = authProvider.currentUser;
      
      if (currentUser != null) {
        context.read<NotificationsProvider>().initialize(currentUser.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Menu'),
        actions: const [
          NotificationBellWidget(), // Add this!
        ],
      ),
      // ... rest of screen
    );
  }
}


STEP 3: In Your Order Management Code - Trigger Notifications
────────────────────────────────────────────────────────────────

// When you update an order status:

// OLD CODE:
await supabase.from('orders')
    .update({'status': 'processing'})
    .eq('id', orderId);

// NEW CODE:
await supabase.from('orders')
    .update({'status': 'processing'})
    .eq('id', orderId);

// Add this notification:
await context.read<NotificationsProvider>().notifyStatusChange(
  orderId: orderId,
  newStatus: 'processing',
  previousStatus: 'pending',
);


STEP 4: In orders_screen.dart - Add notification trigger
────────────────────────────────────────────────────────────────

// When order status button is clicked:
TextButton(
  onPressed: () {
    updateOrderStatusExample(context, orderId, 'pending', 'processing');
  },
  child: const Text('Mark as Processing'),
)
*/

// =============================================================================
// Testing the Notifications System
// =============================================================================

/*
MANUAL TEST STEPS:
─────────────────

1. Start the app
2. Ensure you're logged in (customer ID available)
3. Open the Notifications Center (bell icon)
4. Should be empty initially

5. In your backend admin panel or API:
   - Update any order status to a new status
   - The notification should appear in the app

6. Test all status transitions:
   - pending → processing
   - processing → for_pick-up
   - for_pick-up → for_delivery
   - for_delivery → completed

7. Test notification actions:
   - Click notification to mark as read
   - Use "Mark all as read" button
   - Delete individual notifications
   - Use "Delete all" button

8. Check badge count:
   - Bell icon should show "1" for 1 unread
   - Should show "99+" for 99+ unread
   - Should disappear when all read
*/

// =============================================================================
// Troubleshooting Guide
// =============================================================================

/*
ISSUE: Notifications not appearing
SOLUTION:
- Verify Supabase 'notifications' table exists
- Check customer ID is correctly passed to initialize()
- Ensure NotificationsProvider is in MultiProvider
- Check Supabase connection is working

ISSUE: Badge shows wrong count
SOLUTION:
- Call refreshUnreadCount() after marking as read
- Provider auto-refreshes every 30 seconds
- Force refresh with fetchNotifications()

ISSUE: Notifications not disappearing after delete
SOLUTION:
- Call deleteNotification() properly
- Provider automatically updates list
- Pull to refresh if UI is stale

ISSUE: Old notifications showing
SOLUTION:
- Implement retention policy in Supabase
- Auto-delete after 30 days
- Or archive old notifications
*/
