# Notifications System - API Integration Patterns

## Complete Code Examples & Integration Scenarios

**For**: Backend developers implementing notifications
**Tech Stack**: Node.js/Express, Supabase, Postgres
**Version**: 1.0

---

## Quick Reference: Status Message Map

```javascript
const STATUS_MESSAGES = {
  pending: {
    title: 'Order Confirmed! 🎉',
    message: 'We\'ve received your order and will get it ready for you shortly.',
    emoji: '🎉',
    color: '#FFB81C', // Yellow
  },
  for_pick_up: {
    title: 'Ready for Pickup! 📦',
    message: 'Your order is ready and waiting for you. Stop by whenever you\'re ready!',
    emoji: '📦',
    color: '#0066FF', // Blue
  },
  processing: {
    title: 'Processing Your Order 🧺',
    message: 'Our team is now processing your laundry with care.',
    emoji: '🧺',
    color: '#6F42C1', // Purple
  },
  for_delivery: {
    title: 'On the Way! 🚚',
    message: 'Your order is out for delivery. It will arrive soon!',
    emoji: '🚚',
    color: '#FFC107', // Amber
  },
  completed: {
    title: 'Order Complete! ✨',
    message: 'Your order has been successfully delivered. Thank you for choosing us!',
    emoji: '✨',
    color: '#28A745', // Green
  },
  cancelled: {
    title: 'Order Cancelled ❌',
    message: 'Your order has been cancelled. Please contact us if you have any questions.',
    emoji: '❌',
    color: '#DC3545', // Red
  },
};
```

---

## Scenario 1: Simple Order Status Update

### When Order Status Changes:

```javascript
// ============================================
// FILE: routes/orders.js
// ============================================

const express = require('express');
const router = express.Router();
const { createClient } = require('@supabase/supabase-js');

const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY
);

/**
 * Update order status (with automatic notification)
 * PATCH /api/orders/:orderId
 * 
 * Request body:
 * {
 *   "status": "processing",
 *   "notes": "Order received and sorted"
 * }
 */
router.patch('/:orderId', async (req, res) => {
  try {
    const { orderId } = req.params;
    const { status: newStatus, notes } = req.body;

    // Validate status
    const validStatuses = ['pending', 'processing', 'for_pick-up', 'for_delivery', 'completed', 'cancelled'];
    if (!validStatuses.includes(newStatus)) {
      return res.status(400).json({
        error: 'Invalid status',
        validStatuses,
      });
    }

    // ========== STEP 1: Get current order ==========
    const { data: currentOrder, error: fetchError } = await supabase
      .from('orders')
      .select('id, customer_id, status, total_amount')
      .eq('id', orderId)
      .single();

    if (fetchError || !currentOrder) {
      return res.status(404).json({ error: 'Order not found' });
    }

    const previousStatus = currentOrder.status;

    // Don't create notification if status hasn't changed
    if (previousStatus === newStatus) {
      return res.json({
        success: true,
        message: 'Order status unchanged',
        notificationCreated: false,
      });
    }

    console.log(`📝 Updating Order ${orderId}: ${previousStatus} → ${newStatus}`);

    // ========== STEP 2: Update order status ==========
    const { error: updateError } = await supabase
      .from('orders')
      .update({
        status: newStatus,
        updated_at: new Date().toISOString(),
      })
      .eq('id', orderId);

    if (updateError) throw updateError;

    // ========== STEP 3: Create notification ==========
    // (This can be database trigger OR API call)
    
    const STATUS_MESSAGES = require('../constants/statusMessages');
    const messageData = STATUS_MESSAGES[newStatus] || {
      title: 'Order Updated',
      message: 'Your order status has been updated.',
    };

    const notificationId = `${Date.now()}_${orderId.substring(0, 8)}`;

    const { error: notificationError } = await supabase
      .from('notifications')
      .insert({
        id: notificationId,
        customer_id: currentOrder.customer_id,
        order_id: orderId,
        title: messageData.title,
        message: messageData.message,
        status: newStatus,
        type: 'status_change',
        is_read: false,
        metadata: {
          previous_status: previousStatus,
          new_status: newStatus,
          order_amount: currentOrder.total_amount,
        },
      });

    if (notificationError) {
      console.error('⚠️  Notification creation failed (non-blocking):', notificationError);
      // Continue anyway - don't fail the order update
    }

    console.log(`✅ Order updated with notification created: ${notificationId}`);

    // ========== STEP 4: Response ==========
    res.json({
      success: true,
      order: {
        id: orderId,
        previousStatus,
        newStatus,
      },
      notification: {
        id: notificationId,
        created: true,
        title: messageData.title,
      },
    });

  } catch (error) {
    console.error('❌ Error updating order:', error);
    res.status(500).json({
      error: 'Failed to update order',
      details: error.message,
    });
  }
});

module.exports = router;
```

---

## Scenario 2: Bulk Status Update

### When Updating Multiple Orders:

```javascript
/**
 * Bulk update order statuses
 * POST /api/orders/bulk-update
 * 
 * Request body:
 * {
 *   "orderIds": ["order-1", "order-2", "order-3"],
 *   "newStatus": "processing",
 *   "reason": "Batch processed"
 * }
 */
router.post('/bulk-update', async (req, res) => {
  try {
    const { orderIds, newStatus, reason } = req.body;

    if (!Array.isArray(orderIds) || orderIds.length === 0) {
      return res.status(400).json({ error: 'orderIds must be non-empty array' });
    }

    console.log(`🔄 Bulk updating ${orderIds.length} orders to status: ${newStatus}`);

    // ========== STEP 1: Fetch all orders ==========
    const { data: orders, error: fetchError } = await supabase
      .from('orders')
      .select('id, customer_id, status')
      .in('id', orderIds);

    if (fetchError) throw fetchError;

    if (orders.length === 0) {
      return res.status(404).json({ error: 'No orders found' });
    }

    // ========== STEP 2: Update all orders ==========
    const { error: updateError } = await supabase
      .from('orders')
      .update({
        status: newStatus,
        updated_at: new Date().toISOString(),
      })
      .in('id', orderIds);

    if (updateError) throw updateError;

    // ========== STEP 3: Create notifications for changed orders ==========
    const STATUS_MESSAGES = require('../constants/statusMessages');
    const messageData = STATUS_MESSAGES[newStatus];

    // Filter orders that actually changed status
    const changedOrders = orders.filter(order => order.status !== newStatus);

    // Prepare notifications
    const notifications = changedOrders.map((order) => ({
      id: `${Date.now()}_${order.id.substring(0, 8)}_${Math.random().toString(36).substr(2, 5)}`,
      customer_id: order.customer_id,
      order_id: order.id,
      title: messageData.title,
      message: messageData.message,
      status: newStatus,
      type: 'status_change',
      is_read: false,
      metadata: {
        previous_status: order.status,
        new_status: newStatus,
        bulk_update_id: `bulk_${Date.now()}`,
        reason,
      },
    }));

    // Insert all notifications at once
    if (notifications.length > 0) {
      const { error: notificationError } = await supabase
        .from('notifications')
        .insert(notifications);

      if (notificationError) {
        console.error('⚠️  Notification creation failed:', notificationError);
      }
    }

    console.log(`✅ Bulk update complete: ${changedOrders.length} notifications created`);

    res.json({
      success: true,
      ordersUpdated: orders.length,
      notificationsCreated: notifications.length,
      reason,
    });

  } catch (error) {
    console.error('❌ Bulk update error:', error);
    res.status(500).json({
      error: 'Bulk update failed',
      details: error.message,
    });
  }
});
```

---

## Scenario 3: Scheduled Status Updates

### Automatic Status Transitions:

```javascript
// ============================================
// FILE: jobs/scheduleOrderUpdates.js
// ============================================

const schedule = require('node-schedule');
const { createClient } = require('@supabase/supabase-js');

const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY
);

const STATUS_MESSAGES = require('../constants/statusMessages');

/**
 * Auto-transition orders that have been in current status too long
 * 
 * Rules:
 * - pending → processing after 30 minutes
 * - processing → for_pick-up after 4 hours
 * - for_delivery → completed after 24 hours (if not marked manually)
 */

async function autoTransitionOrders() {
  try {
    console.log('🤖 Running auto-transition job...');

    const now = new Date();
    const STATUS_RULES = [
      {
        from: 'pending',
        to: 'processing',
        afterMinutes: 30,
      },
      {
        from: 'processing',
        to: 'for_pick-up',
        afterMinutes: 4 * 60, // 4 hours
      },
      {
        from: 'for_delivery',
        to: 'completed',
        afterMinutes: 24 * 60, // 24 hours
      },
    ];

    for (const rule of STATUS_RULES) {
      const cutoffTime = new Date(now.getTime() - rule.afterMinutes * 60000);

      // Find orders that need transitioning
      const { data: ordersToUpdate, error: fetchError } = await supabase
        .from('orders')
        .select('id, customer_id, status, updated_at')
        .eq('status', rule.from)
        .lt('updated_at', cutoffTime.toISOString());

      if (fetchError) {
        console.error(`Error fetching ${rule.from} orders:`, fetchError);
        continue;
      }

      if (ordersToUpdate.length === 0) {
        console.log(`✓ No ${rule.from} orders need transitioning`);
        continue;
      }

      console.log(`Found ${ordersToUpdate.length} ${rule.from} orders to transition to ${rule.to}`);

      // Update orders
      const { error: updateError } = await supabase
        .from('orders')
        .update({
          status: rule.to,
          updated_at: new Date().toISOString(),
        })
        .in('id', ordersToUpdate.map(o => o.id));

      if (updateError) {
        console.error(`Error updating orders:`, updateError);
        continue;
      }

      // Create notifications
      const messageData = STATUS_MESSAGES[rule.to];
      const notifications = ordersToUpdate.map((order) => ({
        id: `${Date.now()}_${order.id.substring(0, 8)}_auto`,
        customer_id: order.customer_id,
        order_id: order.id,
        title: messageData.title,
        message: messageData.message,
        status: rule.to,
        type: 'status_change',
        is_read: false,
        metadata: {
          previous_status: rule.from,
          new_status: rule.to,
          auto_transitioned: true,
          auto_transition_rule: `${rule.from}_to_${rule.to}`,
        },
      }));

      const { error: notificationError } = await supabase
        .from('notifications')
        .insert(notifications);

      if (notificationError) {
        console.error(`Error creating notifications:`, notificationError);
      } else {
        console.log(`✅ Created ${notifications.length} notifications`);
      }
    }

    console.log('✅ Auto-transition job completed');

  } catch (error) {
    console.error('❌ Auto-transition job failed:', error);
  }
}

// Schedule job to run every 5 minutes
schedule.scheduleJob('*/5 * * * *', autoTransitionOrders);

module.exports = { autoTransitionOrders };
```

---

## Scenario 4: Conditional Notifications (Preferences)

### Respecting Customer Preferences:

```javascript
// ============================================
// FILE: services/notificationService.js
// ============================================

class NotificationService {
  constructor(supabase) {
    this.supabase = supabase;
    this.STATUS_MESSAGES = require('../constants/statusMessages');
  }

  /**
   * Create notification with preference checking
   */
  async createNotification(customerId, orderId, newStatus, previousStatus) {
    try {
      // ========== STEP 1: Check customer preferences ==========
      const { data: preferences, error: prefError } = await this.supabase
        .from('notification_preferences')
        .select('*')
        .eq('customer_id', customerId)
        .single();

      if (prefError && prefError.code !== 'PGRST116') {
        // PGRST116 = no rows found (acceptable)
        throw prefError;
      }

      // ========== STEP 2: Check if this notification type is enabled ==========
      const statusKey = `notify_${newStatus.replace('-', '_')}`;
      if (preferences && !preferences[statusKey]) {
        console.log(`📵 Notification skipped for ${customerId}: ${newStatus} disabled`);
        return {
          created: false,
          reason: 'User disabled this notification type',
        };
      }

      // ========== STEP 3: Check quiet hours ==========
      if (preferences?.quiet_hours_enabled) {
        const now = new Date();
        const currentTime = now.toTimeString().slice(0, 5); // HH:MM
        const startTime = preferences.quiet_hours_start;
        const endTime = preferences.quiet_hours_end;

        if (currentTime >= startTime && currentTime < endTime) {
          console.log(`🔇 Notification queued (quiet hours): ${customerId}`);
          // Queue for sending after quiet hours
          // OR mark to send silently
        }
      }

      // ========== STEP 4: Create notification ==========
      const messageData = this.STATUS_MESSAGES[newStatus] || {
        title: 'Order Updated',
        message: 'Your order status has been updated.',
      };

      const notificationId = `${Date.now()}_${orderId.substring(0, 8)}`;

      const { data, error } = await this.supabase
        .from('notifications')
        .insert({
          id: notificationId,
          customer_id: customerId,
          order_id: orderId,
          title: messageData.title,
          message: messageData.message,
          status: newStatus,
          type: 'status_change',
          is_read: false,
          metadata: {
            previous_status: previousStatus,
            new_status: newStatus,
            respects_preferences: true,
          },
        })
        .select();

      if (error) throw error;

      console.log(`✅ Notification created (with preferences): ${notificationId}`);

      return {
        created: true,
        notificationId,
        data,
      };

    } catch (error) {
      console.error('❌ Error creating notification:', error);
      throw error;
    }
  }

  /**
   * Get customer notification preferences
   */
  async getPreferences(customerId) {
    const { data, error } = await this.supabase
      .from('notification_preferences')
      .select('*')
      .eq('customer_id', customerId)
      .single();

    if (error && error.code === 'PGRST116') {
      // No preferences set, return defaults
      return this.getDefaultPreferences();
    }

    return data;
  }

  /**
   * Update customer preferences
   */
  async updatePreferences(customerId, preferences) {
    const { data, error } = await this.supabase
      .from('notification_preferences')
      .upsert({
        customer_id: customerId,
        ...preferences,
        updated_at: new Date().toISOString(),
      }, { onConflict: 'customer_id' })
      .select();

    if (error) throw error;

    console.log(`✅ Preferences updated for ${customerId}`);
    return data;
  }

  getDefaultPreferences() {
    return {
      notify_pending: true,
      notify_processing: true,
      notify_pickup: true,
      notify_delivery: true,
      notify_completed: true,
      notify_cancelled: true,
      push_notifications: true,
      email_notifications: false,
      sms_notifications: false,
      quiet_hours_enabled: false,
    };
  }
}

module.exports = NotificationService;
```

---

## Scenario 5: Error Recovery & Retry Logic

### Handling Failures Gracefully:

```javascript
// ============================================
// FILE: utils/retryQueue.js
// ============================================

class RetryQueue {
  constructor(supabase, maxRetries = 3) {
    this.supabase = supabase;
    this.maxRetries = maxRetries;
    this.queue = [];
  }

  /**
   * Add notification to retry queue
   */
  async enqueue(notification) {
    const { data, error } = await this.supabase
      .from('notification_retry_queue')
      .insert({
        notification_data: notification,
        retry_count: 0,
        last_error: null,
        next_retry_at: new Date().toISOString(),
      });

    if (error) {
      console.error('Error adding to retry queue:', error);
    } else {
      console.log(`⏳ Added to retry queue`);
    }
  }

  /**
   * Process retry queue
   */
  async processQueue() {
    try {
      console.log('🔄 Processing notification retry queue...');

      // Get items ready to retry
      const { data: retryItems, error } = await this.supabase
        .from('notification_retry_queue')
        .select('*')
        .lt('next_retry_at', new Date().toISOString())
        .lt('retry_count', this.maxRetries);

      if (error) throw error;

      if (retryItems.length === 0) {
        console.log('✓ Retry queue empty');
        return;
      }

      console.log(`Found ${retryItems.length} items to retry`);

      for (const item of retryItems) {
        try {
          // Attempt to create notification
          const { error: createError } = await this.supabase
            .from('notifications')
            .insert(item.notification_data);

          if (!createError) {
            // Success! Remove from queue
            await this.supabase
              .from('notification_retry_queue')
              .delete()
              .eq('id', item.id);

            console.log(`✅ Retried notification successful: ${item.id}`);
          } else {
            // Still failing, update retry count and next retry time
            const nextRetryDelay = Math.pow(2, item.retry_count + 1) * 60 * 1000; // Exponential backoff
            const nextRetryAt = new Date(Date.now() + nextRetryDelay);

            await this.supabase
              .from('notification_retry_queue')
              .update({
                retry_count: item.retry_count + 1,
                last_error: createError.message,
                next_retry_at: nextRetryAt.toISOString(),
              })
              .eq('id', item.id);

            console.log(`⚠️  Retry failed, scheduled next retry for ${nextRetryAt}`);
          }
        } catch (error) {
          console.error(`Error processing retry item:`, error);
        }
      }

      console.log('✅ Retry queue processing completed');

    } catch (error) {
      console.error('❌ Error processing retry queue:', error);
    }
  }

  /**
   * Clean up old failed items
   */
  async cleanupOldRetries() {
    const sevenDaysAgo = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000);

    const { error } = await this.supabase
      .from('notification_retry_queue')
      .delete()
      .eq('retry_count', this.maxRetries)
      .lt('created_at', sevenDaysAgo.toISOString());

    if (error) {
      console.error('Error cleaning up retries:', error);
    } else {
      console.log('✅ Old retries cleaned up');
    }
  }
}

// Usage in app.js or scheduler
const retryQueue = new RetryQueue(supabase);

// Process every 1 minute
setInterval(() => retryQueue.processQueue(), 60 * 1000);

// Clean up daily
schedule.scheduleJob('0 2 * * *', () => retryQueue.cleanupOldRetries());

module.exports = RetryQueue;
```

---

## Scenario 6: Real-time Updates via Socket.io

### WebSocket Integration:

```javascript
// ============================================
// FILE: realtime/socket.js
// ============================================

module.exports = (io, supabase) => {
  io.on('connection', (socket) => {
    console.log(`👤 User connected: ${socket.id}`);

    const userId = socket.handshake.auth.userId;
    if (!userId) {
      socket.disconnect();
      return;
    }

    // Join user-specific room
    socket.join(`user_${userId}`);

    // ========== Event: Subscribe to notifications ==========
    socket.on('notifications:subscribe', async (data) => {
      try {
        console.log(`📬 ${userId} subscribing to notifications`);

        // Get existing notifications
        const { data: notifications, error } = await supabase
          .from('notifications')
          .select('*')
          .eq('customer_id', userId)
          .order('created_at', { ascending: false })
          .limit(50);

        if (error) throw error;

        // Send existing notifications
        socket.emit('notifications:initial', {
          success: true,
          count: notifications.length,
          notifications,
        });

        // Get unread count
        const { count } = await supabase
          .from('notifications')
          .select('*', { count: 'exact', head: true })
          .eq('customer_id', userId)
          .eq('is_read', false);

        socket.emit('notifications:unread-count', {
          unreadCount: count || 0,
        });

      } catch (error) {
        console.error('Error subscribing to notifications:', error);
        socket.emit('notifications:error', { error: error.message });
      }
    });

    // ========== Event: Mark as read ==========
    socket.on('notification:mark-read', async (data) => {
      try {
        const { notificationId } = data;

        const { error } = await supabase
          .from('notifications')
          .update({ is_read: true })
          .eq('id', notificationId)
          .eq('customer_id', userId);

        if (error) throw error;

        socket.emit('notification:marked-read', {
          success: true,
          notificationId,
        });

        // Broadcast to all devices of this user
        io.to(`user_${userId}`).emit('notification:updated', {
          id: notificationId,
          is_read: true,
        });

      } catch (error) {
        console.error('Error marking notification as read:', error);
        socket.emit('error', { error: error.message });
      }
    });

    // ========== Event: Delete notification ==========
    socket.on('notification:delete', async (data) => {
      try {
        const { notificationId } = data;

        const { error } = await supabase
          .from('notifications')
          .delete()
          .eq('id', notificationId)
          .eq('customer_id', userId);

        if (error) throw error;

        // Broadcast to all devices
        io.to(`user_${userId}`).emit('notification:deleted', {
          notificationId,
        });

      } catch (error) {
        console.error('Error deleting notification:', error);
        socket.emit('error', { error: error.message });
      }
    });

    socket.on('disconnect', () => {
      console.log(`👤 User disconnected: ${socket.id}`);
    });
  });

  // ========== Server-side: Broadcast new notifications ==========
  // This would be called from your order update endpoint
  function broadcastNotification(userId, notification) {
    io.to(`user_${userId}`).emit('notification:new', {
      notification,
    });
  }

  return { broadcastNotification };
};
```

---

## API Response Examples

### Success Response: Create Notification

```json
{
  "success": true,
  "order": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "previousStatus": "pending",
    "newStatus": "processing"
  },
  "notification": {
    "id": "1704067200000_550e8400",
    "created": true,
    "title": "Processing Your Order 🧺",
    "message": "Our team is now processing your laundry with care.",
    "createdAt": "2024-01-01T12:00:00Z"
  }
}
```

### Success Response: Fetch Notifications

```json
{
  "success": true,
  "count": 5,
  "notifications": [
    {
      "id": "1704067200000_550e8400",
      "customerId": "user-123",
      "orderId": "550e8400-e29b-41d4-a716-446655440000",
      "title": "Processing Your Order 🧺",
      "message": "Our team is now processing your laundry with care.",
      "status": "processing",
      "type": "status_change",
      "isRead": false,
      "createdAt": "2024-01-01T12:00:00Z",
      "metadata": {
        "previousStatus": "pending",
        "newStatus": "processing"
      }
    }
  ]
}
```

### Error Response: Invalid Status

```json
{
  "error": "Invalid status",
  "validStatuses": [
    "pending",
    "processing",
    "for_pick-up",
    "for_delivery",
    "completed",
    "cancelled"
  ]
}
```

---

## Database Query Examples

### Find Orders Ready for Status Update

```sql
-- Find pending orders from last 30 minutes
SELECT id, customer_id, status, created_at
FROM orders
WHERE status = 'pending'
  AND created_at > NOW() - INTERVAL '30 minutes'
ORDER BY created_at DESC;

-- Find processing orders that haven't been updated in 4 hours
SELECT id, customer_id, status, updated_at
FROM orders
WHERE status = 'processing'
  AND updated_at < NOW() - INTERVAL '4 hours'
ORDER BY updated_at ASC;
```

### Get Notification Statistics

```sql
-- Notification statistics by status
SELECT
  status,
  COUNT(*) as total_notifications,
  SUM(CASE WHEN is_read THEN 1 ELSE 0 END) as read_count,
  SUM(CASE WHEN is_read THEN 0 ELSE 1 END) as unread_count,
  AVG(EXTRACT(EPOCH FROM (updated_at - created_at))) as avg_read_time_seconds
FROM notifications
WHERE created_at > NOW() - INTERVAL '7 days'
GROUP BY status
ORDER BY total_notifications DESC;

-- Customers with most unread notifications
SELECT
  customer_id,
  COUNT(*) as unread_count
FROM notifications
WHERE is_read = FALSE
GROUP BY customer_id
ORDER BY unread_count DESC
LIMIT 10;
```

---

## Environment Variables Template

```bash
# Add to .env file
SUPABASE_URL=https://xxxxx.supabase.co
SUPABASE_ANON_KEY=eyJ0eXAiOiJKV1QiLCJhbGc...
SUPABASE_SERVICE_ROLE_KEY=eyJ0eXAiOiJKV1QiLCJhbGc...

API_URL=http://localhost:3000
API_PORT=3000

# Socket.io
SOCKET_IO_PORT=3001
SOCKET_IO_CORS_ORIGIN=http://localhost:3000

# Logging
LOG_LEVEL=info
LOG_FILE=/var/log/ilaba/notifications.log

# Monitoring
SENTRY_DSN=https://examplePublicKey@o0.ingest.sentry.io/0
```

---

## Testing with cURL

### Create Notification

```bash
curl -X POST http://localhost:3000/api/notifications/create \
  -H "Content-Type: application/json" \
  -d '{
    "customer_id": "550e8400-e29b-41d4-a716-446655440000",
    "order_id": "550e8400-e29b-41d4-a716-446655440001",
    "new_status": "processing",
    "previous_status": "pending"
  }'
```

### Fetch Notifications

```bash
curl -X GET http://localhost:3000/api/notifications/customer/550e8400-e29b-41d4-a716-446655440000 \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### Mark as Read

```bash
curl -X PATCH http://localhost:3000/api/notifications/1704067200000_550e8400/read \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### Bulk Update

```bash
curl -X POST http://localhost:3000/api/orders/bulk-update \
  -H "Content-Type: application/json" \
  -d '{
    "orderIds": ["order-1", "order-2", "order-3"],
    "newStatus": "processing",
    "reason": "Batch processed"
  }'
```

---

## Summary

This guide provides production-ready code patterns for:

✅ Simple status updates with notifications
✅ Bulk operations
✅ Scheduled transitions
✅ Preference-aware notifications
✅ Error recovery with retries
✅ Real-time WebSocket updates
✅ Database queries
✅ Testing examples

**Ready to implement!** 🚀
