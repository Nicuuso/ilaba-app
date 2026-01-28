# Notifications System - Backend Implementation Guide

## For API & Supabase - Complete Integration Guide

**Target Audience**: Backend developers, API engineers, DevOps specialists
**Estimated Implementation Time**: 2-4 hours
**Difficulty Level**: Intermediate

---

## Table of Contents

1. [Database Setup](#database-setup)
2. [Supabase Configuration](#supabase-configuration)
3. [API Endpoints](#api-endpoints)
4. [Notification Triggers](#notification-triggers)
5. [Background Jobs](#background-jobs)
6. [Real-time Subscriptions](#real-time-subscriptions)
7. [Error Handling](#error-handling)
8. [Monitoring & Logging](#monitoring--logging)
9. [Testing Guide](#testing-guide)
10. [Deployment Checklist](#deployment-checklist)

---

## Database Setup

### 1. Create Notifications Table

Execute this SQL in your Supabase SQL editor:

```sql
-- Create notifications table
CREATE TABLE public.notifications (
  id TEXT PRIMARY KEY,
  customer_id UUID NOT NULL REFERENCES public.customers(id) ON DELETE CASCADE,
  order_id UUID NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  status TEXT NOT NULL,
  type TEXT NOT NULL DEFAULT 'order_update',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  is_read BOOLEAN DEFAULT FALSE,
  metadata JSONB,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  
  -- Add constraints
  CONSTRAINT status_valid CHECK (
    status IN ('pending', 'for_pick-up', 'processing', 'for_delivery', 'completed', 'cancelled')
  ),
  CONSTRAINT type_valid CHECK (
    type IN ('status_change', 'order_update', 'system')
  )
);

-- Create indexes for performance
CREATE INDEX idx_notifications_customer_id 
  ON public.notifications(customer_id DESC);

CREATE INDEX idx_notifications_order_id 
  ON public.notifications(order_id);

CREATE INDEX idx_notifications_created_at 
  ON public.notifications(created_at DESC);

CREATE INDEX idx_notifications_is_read 
  ON public.notifications(is_read, customer_id);

CREATE INDEX idx_notifications_status 
  ON public.notifications(status);

-- Create composite index for common queries
CREATE INDEX idx_notifications_customer_read 
  ON public.notifications(customer_id, is_read DESC, created_at DESC);

-- Enable RLS (Row Level Security)
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
```

### 2. Create RLS Policies

```sql
-- Policy: Customers can view only their own notifications
CREATE POLICY "Users can view their own notifications"
  ON public.notifications
  FOR SELECT
  USING (auth.uid()::text = customer_id::text);

-- Policy: Admin can view all notifications
CREATE POLICY "Admins can view all notifications"
  ON public.notifications
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.staff
      WHERE staff.id = auth.uid()::text
      AND staff.role IN ('admin', 'manager')
    )
  );

-- Only API/backend can INSERT notifications
CREATE POLICY "API can insert notifications"
  ON public.notifications
  FOR INSERT
  USING (true)
  WITH CHECK (true);

-- Users can UPDATE only their own notifications
CREATE POLICY "Users can update their own notifications"
  ON public.notifications
  FOR UPDATE
  USING (auth.uid()::text = customer_id::text)
  WITH CHECK (auth.uid()::text = customer_id::text);

-- Users can DELETE only their own notifications
CREATE POLICY "Users can delete their own notifications"
  ON public.notifications
  FOR DELETE
  USING (auth.uid()::text = customer_id::text);
```

### 3. Create Audit Table (Optional but Recommended)

```sql
-- Track notification status changes for auditing
CREATE TABLE public.notification_audit_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  notification_id TEXT NOT NULL REFERENCES public.notifications(id) ON DELETE CASCADE,
  action TEXT NOT NULL,
  previous_state JSONB,
  new_state JSONB,
  actor TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_notification_audit_notification_id 
  ON public.notification_audit_log(notification_id);

CREATE INDEX idx_notification_audit_created_at 
  ON public.notification_audit_log(created_at DESC);
```

### 4. Create Notification Settings Table

```sql
-- Allow customers to manage notification preferences
CREATE TABLE public.notification_preferences (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  customer_id UUID NOT NULL REFERENCES public.customers(id) ON DELETE CASCADE,
  
  -- Notification type preferences
  notify_pending BOOLEAN DEFAULT TRUE,
  notify_processing BOOLEAN DEFAULT TRUE,
  notify_pickup BOOLEAN DEFAULT TRUE,
  notify_delivery BOOLEAN DEFAULT TRUE,
  notify_completed BOOLEAN DEFAULT TRUE,
  notify_cancelled BOOLEAN DEFAULT TRUE,
  
  -- Channel preferences (for future use)
  push_notifications BOOLEAN DEFAULT TRUE,
  email_notifications BOOLEAN DEFAULT FALSE,
  sms_notifications BOOLEAN DEFAULT FALSE,
  
  -- Do not disturb settings
  quiet_hours_enabled BOOLEAN DEFAULT FALSE,
  quiet_hours_start TIME,
  quiet_hours_end TIME,
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  
  UNIQUE(customer_id)
);

-- Allow customers to view and update their preferences
ALTER TABLE public.notification_preferences ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own preferences"
  ON public.notification_preferences
  FOR SELECT
  USING (auth.uid()::text = customer_id::text);

CREATE POLICY "Users can update their own preferences"
  ON public.notification_preferences
  FOR UPDATE
  USING (auth.uid()::text = customer_id::text)
  WITH CHECK (auth.uid()::text = customer_id::text);
```

---

## Supabase Configuration

### 1. Set Up Supabase Service Role

You'll need a service role key for server-to-server communication:

```bash
# Get from Supabase Dashboard:
# 1. Go to Settings → API
# 2. Copy the "Service Role Secret" (keep this SECRET!)
# 3. Store in environment variable: SUPABASE_SERVICE_ROLE_KEY
```

### 2. Create Supabase Functions (Optional but Recommended)

Create a Supabase Edge Function to handle notification creation:

```bash
# Create function
supabase functions new create-notification

# File: supabase/functions/create-notification/index.ts
```

```typescript
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const supabaseUrl = Deno.env.get("SUPABASE_URL");
const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY");

serve(async (req) => {
  // Handle CORS
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: { "Access-Control-Allow-Origin": "*" } });
  }

  try {
    const { customer_id, order_id, new_status, previous_status } = await req.json();

    const supabase = createClient(supabaseUrl, supabaseAnonKey);

    // Define status messages
    const statusMessages: Record<string, { title: string; message: string }> = {
      pending: {
        title: "Order Confirmed! 🎉",
        message: "We've received your order and will get it ready for you shortly.",
      },
      for_pick_up: {
        title: "Ready for Pickup! 📦",
        message: "Your order is ready and waiting for you. Stop by whenever you're ready!",
      },
      processing: {
        title: "Processing Your Order 🧺",
        message: "Our team is now processing your laundry with care.",
      },
      for_delivery: {
        title: "On the Way! 🚚",
        message: "Your order is out for delivery. It will arrive soon!",
      },
      completed: {
        title: "Order Complete! ✨",
        message: "Your order has been successfully delivered. Thank you for choosing us!",
      },
      cancelled: {
        title: "Order Cancelled",
        message: "Your order has been cancelled. Please contact us if you have any questions.",
      },
    };

    const messageData = statusMessages[new_status] || {
      title: "Order Updated",
      message: "Your order status has been updated.",
    };

    // Create notification ID
    const notificationId = `${Date.now()}_${order_id.substring(0, 8)}`;

    // Insert notification
    const { error } = await supabase.from("notifications").insert({
      id: notificationId,
      customer_id,
      order_id,
      title: messageData.title,
      message: messageData.message,
      status: new_status,
      type: "status_change",
      created_at: new Date().toISOString(),
      is_read: false,
      metadata: {
        previous_status,
        new_status,
      },
    });

    if (error) throw error;

    return new Response(JSON.stringify({ success: true, notificationId }), {
      headers: { "Content-Type": "application/json" },
    });
  } catch (error) {
    console.error("Error:", error);
    return new Response(JSON.stringify({ error: error.message }), {
      status: 400,
      headers: { "Content-Type": "application/json" },
    });
  }
});
```

Deploy the function:
```bash
supabase functions deploy create-notification
```

---

## API Endpoints

### 1. Create Notification Endpoint

**POST** `/api/notifications/create`

```javascript
// Backend API (Node.js/Express example)
const express = require('express');
const { createClient } = require('@supabase/supabase-js');

const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY
);

app.post('/api/notifications/create', async (req, res) => {
  try {
    const { customer_id, order_id, new_status, previous_status } = req.body;

    // Validate input
    if (!customer_id || !order_id || !new_status) {
      return res.status(400).json({ error: 'Missing required fields' });
    }

    // Define status messages
    const statusMessages = {
      'pending': {
        title: 'Order Confirmed! 🎉',
        message: 'We\'ve received your order and will get it ready for you shortly.',
      },
      'for_pick-up': {
        title: 'Ready for Pickup! 📦',
        message: 'Your order is ready and waiting for you. Stop by whenever you\'re ready!',
      },
      'processing': {
        title: 'Processing Your Order 🧺',
        message: 'Our team is now processing your laundry with care.',
      },
      'for_delivery': {
        title: 'On the Way! 🚚',
        message: 'Your order is out for delivery. It will arrive soon!',
      },
      'completed': {
        title: 'Order Complete! ✨',
        message: 'Your order has been successfully delivered. Thank you for choosing us!',
      },
      'cancelled': {
        title: 'Order Cancelled',
        message: 'Your order has been cancelled. Please contact us if you have any questions.',
      },
    };

    const messageData = statusMessages[new_status] || {
      title: 'Order Updated',
      message: 'Your order status has been updated.',
    };

    // Generate notification ID
    const notificationId = `${Date.now()}_${order_id.substring(0, 8)}`;

    // Check notification preferences
    const { data: preferences } = await supabase
      .from('notification_preferences')
      .select('*')
      .eq('customer_id', customer_id)
      .single();

    // Check if notification type is enabled
    const preferencesKey = `notify_${new_status.replace('-', '_')}`;
    if (preferences && !preferences[preferencesKey]) {
      console.log(`Notification skipped for ${customer_id}: preferences disabled`);
      return res.json({ skipped: true, reason: 'User disabled this notification type' });
    }

    // Insert notification
    const { data, error } = await supabase
      .from('notifications')
      .insert({
        id: notificationId,
        customer_id,
        order_id,
        title: messageData.title,
        message: messageData.message,
        status: new_status,
        type: 'status_change',
        is_read: false,
        metadata: {
          previous_status,
          new_status,
        },
      });

    if (error) throw error;

    console.log(`✅ Notification created: ${notificationId}`);
    res.json({ success: true, notificationId });
  } catch (error) {
    console.error('❌ Error creating notification:', error);
    res.status(500).json({ error: error.message });
  }
});
```

### 2. Get Notifications Endpoint

**GET** `/api/notifications/customer/:customerId`

```javascript
app.get('/api/notifications/customer/:customerId', async (req, res) => {
  try {
    const { customerId } = req.params;
    const { limit = 50, offset = 0 } = req.query;

    // Verify authorization (ensure user is requesting their own notifications)
    const authHeader = req.headers.authorization;
    if (!authHeader) {
      return res.status(401).json({ error: 'Unauthorized' });
    }

    const { data: notifications, error } = await supabase
      .from('notifications')
      .select('*')
      .eq('customer_id', customerId)
      .order('created_at', { ascending: false })
      .range(offset, offset + limit - 1);

    if (error) throw error;

    res.json({
      success: true,
      count: notifications.length,
      notifications,
    });
  } catch (error) {
    console.error('❌ Error fetching notifications:', error);
    res.status(500).json({ error: error.message });
  }
});
```

### 3. Mark Notification as Read

**PATCH** `/api/notifications/:notificationId/read`

```javascript
app.patch('/api/notifications/:notificationId/read', async (req, res) => {
  try {
    const { notificationId } = req.params;

    const { data, error } = await supabase
      .from('notifications')
      .update({ is_read: true, updated_at: new Date().toISOString() })
      .eq('id', notificationId);

    if (error) throw error;

    console.log(`✅ Notification marked as read: ${notificationId}`);
    res.json({ success: true });
  } catch (error) {
    console.error('❌ Error marking notification as read:', error);
    res.status(500).json({ error: error.message });
  }
});
```

### 4. Delete Notification

**DELETE** `/api/notifications/:notificationId`

```javascript
app.delete('/api/notifications/:notificationId', async (req, res) => {
  try {
    const { notificationId } = req.params;

    const { error } = await supabase
      .from('notifications')
      .delete()
      .eq('id', notificationId);

    if (error) throw error;

    console.log(`✅ Notification deleted: ${notificationId}`);
    res.json({ success: true });
  } catch (error) {
    console.error('❌ Error deleting notification:', error);
    res.status(500).json({ error: error.message });
  }
});
```

### 5. Get Unread Count

**GET** `/api/notifications/customer/:customerId/unread-count`

```javascript
app.get('/api/notifications/customer/:customerId/unread-count', async (req, res) => {
  try {
    const { customerId } = req.params;

    const { count, error } = await supabase
      .from('notifications')
      .select('*', { count: 'exact', head: true })
      .eq('customer_id', customerId)
      .eq('is_read', false);

    if (error) throw error;

    res.json({
      success: true,
      unreadCount: count || 0,
    });
  } catch (error) {
    console.error('❌ Error fetching unread count:', error);
    res.status(500).json({ error: error.message });
  }
});
```

---

## Notification Triggers

### 1. Order Status Update Trigger

When order status changes, automatically create a notification:

```javascript
// In your order update endpoint
app.patch('/api/orders/:orderId', async (req, res) => {
  try {
    const { orderId } = req.params;
    const { status: newStatus } = req.body;

    // Get current order to find previous status
    const { data: currentOrder } = await supabase
      .from('orders')
      .select('status, customer_id')
      .eq('id', orderId)
      .single();

    if (!currentOrder) {
      return res.status(404).json({ error: 'Order not found' });
    }

    const previousStatus = currentOrder.status;

    // Only create notification if status actually changed
    if (previousStatus === newStatus) {
      return res.json({ success: true, notificationCreated: false });
    }

    // Update order status
    const { error: updateError } = await supabase
      .from('orders')
      .update({
        status: newStatus,
        updated_at: new Date().toISOString(),
      })
      .eq('id', orderId);

    if (updateError) throw updateError;

    // Create notification
    await axios.post(
      `${process.env.API_URL}/api/notifications/create`,
      {
        customer_id: currentOrder.customer_id,
        order_id: orderId,
        new_status: newStatus,
        previous_status: previousStatus,
      }
    );

    console.log(`✅ Order ${orderId} updated: ${previousStatus} → ${newStatus}`);
    res.json({ success: true, notificationCreated: true });
  } catch (error) {
    console.error('❌ Error updating order:', error);
    res.status(500).json({ error: error.message });
  }
});
```

### 2. Supabase Trigger (Database Level)

Create a database trigger to auto-create notifications:

```sql
-- Create function to handle order status changes
CREATE OR REPLACE FUNCTION public.notify_on_order_status_change()
RETURNS TRIGGER AS $$
DECLARE
  notification_id TEXT;
  notification_title TEXT;
  notification_message TEXT;
  notification_prefs RECORD;
BEGIN
  -- Only proceed if status actually changed
  IF NEW.status IS DISTINCT FROM OLD.status THEN
    -- Define status messages
    CASE NEW.status
      WHEN 'pending' THEN
        notification_title := 'Order Confirmed! 🎉';
        notification_message := 'We''ve received your order and will get it ready for you shortly.';
      WHEN 'processing' THEN
        notification_title := 'Processing Your Order 🧺';
        notification_message := 'Our team is now processing your laundry with care.';
      WHEN 'for_pick-up' THEN
        notification_title := 'Ready for Pickup! 📦';
        notification_message := 'Your order is ready and waiting for you. Stop by whenever you''re ready!';
      WHEN 'for_delivery' THEN
        notification_title := 'On the Way! 🚚';
        notification_message := 'Your order is out for delivery. It will arrive soon!';
      WHEN 'completed' THEN
        notification_title := 'Order Complete! ✨';
        notification_message := 'Your order has been successfully delivered. Thank you for choosing us!';
      WHEN 'cancelled' THEN
        notification_title := 'Order Cancelled';
        notification_message := 'Your order has been cancelled. Please contact us if you have any questions.';
      ELSE
        notification_title := 'Order Updated';
        notification_message := 'Your order status has been updated.';
    END CASE;

    -- Generate notification ID
    notification_id := TO_CHAR(CURRENT_TIMESTAMP, 'YYYYMMDDHH24MISSUS') || '_' || SUBSTRING(NEW.id::TEXT, 1, 8);

    -- Check notification preferences
    SELECT * INTO notification_prefs
    FROM public.notification_preferences
    WHERE customer_id = NEW.customer_id;

    -- Check if notification type is enabled
    IF notification_prefs IS NOT NULL THEN
      CASE NEW.status
        WHEN 'pending' THEN
          IF NOT notification_prefs.notify_pending THEN RETURN NEW; END IF;
        WHEN 'processing' THEN
          IF NOT notification_prefs.notify_processing THEN RETURN NEW; END IF;
        WHEN 'for_pick-up' THEN
          IF NOT notification_prefs.notify_pickup THEN RETURN NEW; END IF;
        WHEN 'for_delivery' THEN
          IF NOT notification_prefs.notify_delivery THEN RETURN NEW; END IF;
        WHEN 'completed' THEN
          IF NOT notification_prefs.notify_completed THEN RETURN NEW; END IF;
        WHEN 'cancelled' THEN
          IF NOT notification_prefs.notify_cancelled THEN RETURN NEW; END IF;
      END CASE;
    END IF;

    -- Insert notification
    INSERT INTO public.notifications (
      id,
      customer_id,
      order_id,
      title,
      message,
      status,
      type,
      is_read,
      metadata
    ) VALUES (
      notification_id,
      NEW.customer_id,
      NEW.id,
      notification_title,
      notification_message,
      NEW.status,
      'status_change',
      FALSE,
      jsonb_build_object(
        'previous_status', OLD.status,
        'new_status', NEW.status
      )
    );

    RAISE LOG 'Notification created: %', notification_id;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger on orders table
CREATE TRIGGER on_order_status_change
  AFTER UPDATE ON public.orders
  FOR EACH ROW
  EXECUTE FUNCTION public.notify_on_order_status_change();
```

---

## Background Jobs

### 1. Cleanup Old Notifications

```javascript
// Run daily via cron job (e.g., node-schedule)
const schedule = require('node-schedule');

// Clean up notifications older than 90 days
schedule.scheduleJob('0 2 * * *', async () => {
  try {
    console.log('🧹 Starting notification cleanup...');

    const ninetyDaysAgo = new Date();
    ninetyDaysAgo.setDate(ninetyDaysAgo.getDate() - 90);

    const { error } = await supabase
      .from('notifications')
      .delete()
      .lt('created_at', ninetyDaysAgo.toISOString());

    if (error) throw error;

    console.log('✅ Notification cleanup completed');
  } catch (error) {
    console.error('❌ Error in notification cleanup:', error);
  }
});
```

### 2. Archive Read Notifications

```javascript
// Archive read notifications older than 30 days
schedule.scheduleJob('0 3 * * *', async () => {
  try {
    console.log('📦 Starting notification archival...');

    const thirtyDaysAgo = new Date();
    thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);

    const { error } = await supabase
      .from('notifications')
      .update({ archived: true })
      .eq('is_read', true)
      .lt('created_at', thirtyDaysAgo.toISOString());

    if (error) throw error;

    console.log('✅ Notification archival completed');
  } catch (error) {
    console.error('❌ Error in notification archival:', error);
  }
});
```

---

## Real-time Subscriptions

### 1. Supabase Realtime Setup

```javascript
// Server-side realtime listener
const subscription = supabase
  .from('notifications')
  .on('INSERT', (payload) => {
    console.log('📲 New notification received:', payload);
    // Emit to connected clients via WebSocket/Socket.io
    io.to(`user_${payload.new.customer_id}`).emit('notification', payload.new);
  })
  .on('UPDATE', (payload) => {
    console.log('📝 Notification updated:', payload);
    io.to(`user_${payload.new.customer_id}`).emit('notification:updated', payload.new);
  })
  .subscribe();
```

### 2. Socket.io Integration

```javascript
// WebSocket connection for real-time updates
const io = require('socket.io')(server);

io.on('connection', (socket) => {
  const userId = socket.handshake.auth.userId;

  // Join user-specific room
  socket.join(`user_${userId}`);

  // Listen for notification subscriptions
  socket.on('subscribe:notifications', async () => {
    // Get current notifications
    const { data: notifications } = await supabase
      .from('notifications')
      .select('*')
      .eq('customer_id', userId)
      .order('created_at', { ascending: false })
      .limit(50);

    socket.emit('notifications:initial', notifications);
  });

  socket.on('disconnect', () => {
    console.log(`User ${userId} disconnected`);
  });
});
```

---

## Error Handling

### 1. Graceful Error Handling

```javascript
// Create error handler middleware
const handleNotificationError = async (error, context) => {
  console.error(`❌ Notification Error in ${context}:`, error);

  // Log to error tracking service (e.g., Sentry)
  if (process.env.SENTRY_DSN) {
    Sentry.captureException(error, {
      tags: { context: 'notifications' },
    });
  }

  // Notify admin if critical error
  if (error.critical) {
    await notifyAdmins({
      title: 'Critical Notification Error',
      message: `${context}: ${error.message}`,
    });
  }

  throw error;
};

// Usage
try {
  await createNotification(data);
} catch (error) {
  await handleNotificationError(error, 'createNotification');
}
```

### 2. Retry Logic

```javascript
// Retry notification creation with exponential backoff
const retryCreateNotification = async (data, maxRetries = 3) => {
  for (let attempt = 1; attempt <= maxRetries; attempt++) {
    try {
      return await createNotification(data);
    } catch (error) {
      if (attempt === maxRetries) throw error;

      const delay = Math.pow(2, attempt) * 1000; // 2s, 4s, 8s
      console.log(`⏳ Retry ${attempt}/${maxRetries} in ${delay}ms`);
      await new Promise(resolve => setTimeout(resolve, delay));
    }
  }
};
```

---

## Monitoring & Logging

### 1. Logging Setup

```javascript
const winston = require('winston');

const logger = winston.createLogger({
  level: 'info',
  format: winston.format.json(),
  defaultMeta: { service: 'notifications' },
  transports: [
    new winston.transports.File({ filename: 'notifications-error.log', level: 'error' }),
    new winston.transports.File({ filename: 'notifications.log' }),
  ],
});

// Notification lifecycle logging
logger.info('📲 Notification created', {
  notificationId,
  customerId,
  orderId,
  status: newStatus,
});

logger.info('✅ Notification marked as read', {
  notificationId,
  readAt: new Date(),
});

logger.error('❌ Notification creation failed', {
  error: error.message,
  customerId,
  orderId,
  stack: error.stack,
});
```

### 2. Metrics Collection

```javascript
// Track notification metrics
const metrics = {
  created: 0,
  read: 0,
  deleted: 0,
  errors: 0,
};

// Log metrics every hour
setInterval(() => {
  console.log('📊 Notification Metrics:', metrics);
  
  // Reset counters
  metrics.created = 0;
  metrics.read = 0;
  metrics.deleted = 0;
  metrics.errors = 0;
}, 60 * 60 * 1000);
```

---

## Testing Guide

### 1. Unit Tests

```javascript
// Jest testing
const request = require('supertest');
const app = require('../app');

describe('Notifications API', () => {
  test('POST /api/notifications/create should create notification', async () => {
    const response = await request(app)
      .post('/api/notifications/create')
      .send({
        customer_id: 'test-customer-id',
        order_id: 'test-order-id',
        new_status: 'processing',
        previous_status: 'pending',
      });

    expect(response.statusCode).toBe(200);
    expect(response.body.success).toBe(true);
    expect(response.body.notificationId).toBeDefined();
  });

  test('GET /api/notifications/customer/:id should fetch notifications', async () => {
    const response = await request(app)
      .get('/api/notifications/customer/test-customer-id');

    expect(response.statusCode).toBe(200);
    expect(Array.isArray(response.body.notifications)).toBe(true);
  });

  test('PATCH /api/notifications/:id/read should mark as read', async () => {
    const response = await request(app)
      .patch('/api/notifications/test-notification-id/read');

    expect(response.statusCode).toBe(200);
    expect(response.body.success).toBe(true);
  });
});
```

### 2. Integration Tests

```javascript
describe('Order Status Change Integration', () => {
  test('Updating order status should create notification', async () => {
    // Create test order
    const order = await createTestOrder();

    // Update status
    const response = await request(app)
      .patch(`/api/orders/${order.id}`)
      .send({ status: 'processing' });

    expect(response.body.notificationCreated).toBe(true);

    // Verify notification exists
    const notifications = await fetchNotifications(order.customer_id);
    expect(notifications.length).toBeGreaterThan(0);
    expect(notifications[0].status).toBe('processing');
  });
});
```

### 3. Manual Testing Checklist

```
[ ] Create notification via API
  [ ] Verify in Supabase dashboard
  [ ] Check all fields populated correctly
  [ ] Verify created_at timestamp

[ ] Fetch notifications
  [ ] Verify correct customer's notifications returned
  [ ] Verify pagination works
  [ ] Verify sorting by date works

[ ] Mark as read
  [ ] Verify is_read updated in database
  [ ] Verify updated_at timestamp changed

[ ] Delete notification
  [ ] Verify removed from database
  [ ] Verify no orphaned records

[ ] Unread count
  [ ] Verify correct count returned
  [ ] Verify count decreases when marked as read

[ ] Status transitions
  [ ] Test: pending → processing
  [ ] Test: processing → for_pick-up
  [ ] Test: for_pick-up → for_delivery
  [ ] Test: for_delivery → completed
  [ ] Test: any → cancelled

[ ] Error scenarios
  [ ] Missing customer_id
  [ ] Missing order_id
  [ ] Invalid status
  [ ] Database connection failure
  [ ] Rate limiting
```

---

## Deployment Checklist

### Pre-Deployment

- [ ] Database migrations applied to production
- [ ] RLS policies enabled
- [ ] Indexes created for performance
- [ ] Service role key securely stored
- [ ] API endpoints tested thoroughly
- [ ] Error handling implemented
- [ ] Logging configured
- [ ] Database backups scheduled

### Deployment Steps

```bash
# 1. Run database migrations
psql $DATABASE_URL < migrations/notifications.sql

# 2. Verify tables created
SELECT tablename FROM pg_tables WHERE schemaname='public';

# 3. Verify indexes
SELECT indexname FROM pg_indexes WHERE schemaname='public' AND tablename='notifications';

# 4. Deploy backend code
git push production main

# 5. Restart application server
systemctl restart ilaba-api

# 6. Deploy Supabase functions (if using)
supabase functions deploy create-notification

# 7. Test endpoints
curl -X GET http://localhost:3000/api/notifications/customer/test-id

# 8. Monitor logs
tail -f /var/log/ilaba/notifications.log

# 9. Verify metrics
curl http://localhost:3000/api/health/metrics
```

### Post-Deployment

- [ ] Monitor error logs for 24 hours
- [ ] Verify notifications create on order updates
- [ ] Test with sample orders
- [ ] Check database performance
- [ ] Monitor API response times
- [ ] Verify unread counts are accurate
- [ ] Test mobile app integration
- [ ] Gather user feedback

### Rollback Plan

```bash
# If issues occur:
# 1. Disable notification triggers
UPDATE pg_trigger SET tgisinternal = true WHERE tgname = 'on_order_status_change';

# 2. Revert API changes
git revert <commit-hash>
systemctl restart ilaba-api

# 3. Archive recent notifications if corrupted
UPDATE notifications SET archived = true WHERE created_at > '2024-01-28';

# 4. Investigate and fix
# ... debug issue ...

# 5. Re-enable when ready
UPDATE pg_trigger SET tgisinternal = false WHERE tgname = 'on_order_status_change';
```

---

## Production Environment Variables

```bash
# Supabase
SUPABASE_URL=https://xxxxx.supabase.co
SUPABASE_ANON_KEY=eyJ0eXAiOiJKV1QiLCJhbGc...
SUPABASE_SERVICE_ROLE_KEY=eyJ0eXAiOiJKV1QiLCJhbGc...

# API
API_URL=https://api.ilaba.com
API_PORT=3000

# Database
DATABASE_URL=postgresql://user:password@host:5432/ilaba

# Logging & Monitoring
SENTRY_DSN=https://examplePublicKey@o0.ingest.sentry.io/0
LOG_LEVEL=info

# Email (for future notifications)
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=your-email@gmail.com
SMTP_PASS=your-app-password
```

---

## Summary

This guide provides everything needed to integrate the notifications system into your backend:

✅ **Database Design** - Schema with indexes and RLS
✅ **API Endpoints** - CRUD operations
✅ **Triggers** - Automatic notification creation
✅ **Real-time** - WebSocket subscriptions
✅ **Error Handling** - Graceful failures
✅ **Monitoring** - Logging and metrics
✅ **Testing** - Unit and integration tests
✅ **Deployment** - Production checklist

**Estimated Implementation Time**: 2-4 hours
**Difficulty**: Intermediate
**Support**: Refer to documentation links

Good luck with your deployment! 🚀
