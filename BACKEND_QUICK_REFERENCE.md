# Backend Implementation Quick Reference

## For Coding Agents & Developers

---

## Status Messages (Copy-Paste Ready)

```javascript
const NOTIFICATION_MESSAGES = {
  'pending': {
    title: 'Order Confirmed! 🎉',
    message: 'We\'ve received your order and will get it ready for you shortly.',
    color: '#FFB81C'
  },
  'for_pick-up': {
    title: 'Ready for Pickup! 📦',
    message: 'Your order is ready and waiting for you. Stop by whenever you\'re ready!',
    color: '#0066FF'
  },
  'processing': {
    title: 'Processing Your Order 🧺',
    message: 'Our team is now processing your laundry with care.',
    color: '#6F42C1'
  },
  'for_delivery': {
    title: 'On the Way! 🚚',
    message: 'Your order is out for delivery. It will arrive soon!',
    color: '#FFC107'
  },
  'completed': {
    title: 'Order Complete! ✨',
    message: 'Your order has been successfully delivered. Thank you for choosing us!',
    color: '#28A745'
  },
  'cancelled': {
    title: 'Order Cancelled ❌',
    message: 'Your order has been cancelled. Please contact us if you have any questions.',
    color: '#DC3545'
  }
};
```

---

## Database Setup (Copy-Paste Ready SQL)

```sql
-- Create main notifications table
CREATE TABLE public.notifications (
  id TEXT PRIMARY KEY,
  customer_id UUID NOT NULL REFERENCES public.customers(id) ON DELETE CASCADE,
  order_id UUID NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  status TEXT NOT NULL CHECK (status IN ('pending', 'for_pick-up', 'processing', 'for_delivery', 'completed', 'cancelled')),
  type TEXT NOT NULL DEFAULT 'order_update' CHECK (type IN ('status_change', 'order_update', 'system')),
  is_read BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  metadata JSONB
);

-- Create indexes
CREATE INDEX idx_notifications_customer_id ON notifications(customer_id DESC);
CREATE INDEX idx_notifications_order_id ON notifications(order_id);
CREATE INDEX idx_notifications_created_at ON notifications(created_at DESC);
CREATE INDEX idx_notifications_is_read ON notifications(is_read, customer_id);
CREATE INDEX idx_notifications_status ON notifications(status);
CREATE INDEX idx_notifications_customer_read ON notifications(customer_id, is_read DESC, created_at DESC);

-- Enable RLS
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Users view own notifications"
  ON public.notifications FOR SELECT
  USING (auth.uid()::text = customer_id::text);

CREATE POLICY "Users update own notifications"
  ON public.notifications FOR UPDATE
  USING (auth.uid()::text = customer_id::text)
  WITH CHECK (auth.uid()::text = customer_id::text);
```

---

## Node.js Supabase Client (Copy-Paste Ready)

```javascript
const { createClient } = require('@supabase/supabase-js');

const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY
);

module.exports = supabase;
```

---

## Create Notification Function (Copy-Paste Ready)

```javascript
async function createNotification(customerId, orderId, newStatus, previousStatus) {
  const MESSAGES = {
    'pending': { title: 'Order Confirmed! 🎉', message: 'We\'ve received your order and will get it ready for you shortly.' },
    'processing': { title: 'Processing Your Order 🧺', message: 'Our team is now processing your laundry with care.' },
    'for_pick-up': { title: 'Ready for Pickup! 📦', message: 'Your order is ready and waiting for you.' },
    'for_delivery': { title: 'On the Way! 🚚', message: 'Your order is out for delivery. It will arrive soon!' },
    'completed': { title: 'Order Complete! ✨', message: 'Your order has been successfully delivered. Thank you!' },
    'cancelled': { title: 'Order Cancelled ❌', message: 'Your order has been cancelled.' }
  };

  const msg = MESSAGES[newStatus] || { title: 'Order Updated', message: 'Status updated.' };
  const notificationId = `${Date.now()}_${orderId.substring(0, 8)}`;

  const { data, error } = await supabase
    .from('notifications')
    .insert({
      id: notificationId,
      customer_id: customerId,
      order_id: orderId,
      title: msg.title,
      message: msg.message,
      status: newStatus,
      type: 'status_change',
      is_read: false,
      metadata: { previous_status: previousStatus, new_status: newStatus }
    });

  if (error) console.error('Error creating notification:', error);
  return data;
}
```

---

## All API Endpoints

```javascript
// 1. Create notification
POST /api/notifications/create
Body: {
  customer_id: "UUID",
  order_id: "UUID",
  new_status: "processing",
  previous_status: "pending"
}

// 2. Get notifications
GET /api/notifications/customer/:customerId?limit=50&offset=0
Response: { notifications: [], unreadCount: 5 }

// 3. Mark as read
PATCH /api/notifications/:notificationId/read
Response: { success: true }

// 4. Mark all as read
PATCH /api/notifications/customer/:customerId/read-all
Response: { success: true }

// 5. Delete notification
DELETE /api/notifications/:notificationId
Response: { success: true }

// 6. Get unread count
GET /api/notifications/customer/:customerId/unread-count
Response: { unreadCount: 5 }

// 7. Update order with auto-notification
PATCH /api/orders/:orderId
Body: { status: "processing" }
Response: { success: true, notificationCreated: true }

// 8. Bulk update orders
POST /api/orders/bulk-update
Body: {
  orderIds: ["id1", "id2", "id3"],
  newStatus: "processing",
  reason: "Batch processed"
}
```

---

## Database Trigger (Copy-Paste Ready)

```sql
CREATE OR REPLACE FUNCTION notify_on_order_update()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.status IS DISTINCT FROM OLD.status THEN
    WITH msg AS (
      SELECT 
        CASE NEW.status
          WHEN 'pending' THEN 'Order Confirmed! 🎉'
          WHEN 'processing' THEN 'Processing Your Order 🧺'
          WHEN 'for_pick-up' THEN 'Ready for Pickup! 📦'
          WHEN 'for_delivery' THEN 'On the Way! 🚚'
          WHEN 'completed' THEN 'Order Complete! ✨'
          WHEN 'cancelled' THEN 'Order Cancelled ❌'
          ELSE 'Order Updated'
        END AS title,
        CASE NEW.status
          WHEN 'pending' THEN 'We\'ve received your order and will get it ready for you shortly.'
          WHEN 'processing' THEN 'Our team is now processing your laundry with care.'
          WHEN 'for_pick-up' THEN 'Your order is ready and waiting for you.'
          WHEN 'for_delivery' THEN 'Your order is out for delivery. It will arrive soon!'
          WHEN 'completed' THEN 'Your order has been successfully delivered. Thank you!'
          WHEN 'cancelled' THEN 'Your order has been cancelled.'
          ELSE 'Your order status has been updated.'
        END AS message
    )
    INSERT INTO notifications (id, customer_id, order_id, title, message, status, type, is_read, metadata)
    SELECT
      TO_CHAR(CURRENT_TIMESTAMP, 'YYYYMMDDHH24MISSUS') || '_' || SUBSTRING(NEW.id::TEXT, 1, 8),
      NEW.customer_id,
      NEW.id,
      msg.title,
      msg.message,
      NEW.status,
      'status_change',
      FALSE,
      jsonb_build_object('previous_status', OLD.status, 'new_status', NEW.status)
    FROM msg;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER on_order_status_change AFTER UPDATE ON orders
  FOR EACH ROW EXECUTE FUNCTION notify_on_order_update();
```

---

## Scheduled Jobs (Copy-Paste Ready)

```javascript
const schedule = require('node-schedule');

// Auto-transition: pending → processing (after 30 minutes)
schedule.scheduleJob('*/5 * * * *', async () => {
  const thirtyMinutesAgo = new Date(Date.now() - 30 * 60 * 1000);
  const { data: orders } = await supabase
    .from('orders')
    .select('id, customer_id')
    .eq('status', 'pending')
    .lt('updated_at', thirtyMinutesAgo.toISOString());

  for (const order of orders || []) {
    await supabase.from('orders').update({ status: 'processing' }).eq('id', order.id);
    await createNotification(order.customer_id, order.id, 'processing', 'pending');
  }
});

// Cleanup: Delete notifications older than 90 days
schedule.scheduleJob('0 2 * * *', async () => {
  const ninetyDaysAgo = new Date();
  ninetyDaysAgo.setDate(ninetyDaysAgo.getDate() - 90);
  await supabase.from('notifications').delete().lt('created_at', ninetyDaysAgo.toISOString());
});
```

---

## Testing with cURL

```bash
# 1. Create notification
curl -X POST http://localhost:3000/api/notifications/create \
  -H "Content-Type: application/json" \
  -d '{
    "customer_id": "550e8400-e29b-41d4-a716-446655440000",
    "order_id": "550e8400-e29b-41d4-a716-446655440001",
    "new_status": "processing",
    "previous_status": "pending"
  }'

# 2. Get all notifications
curl http://localhost:3000/api/notifications/customer/550e8400-e29b-41d4-a716-446655440000

# 3. Mark as read
curl -X PATCH http://localhost:3000/api/notifications/1704067200000_550e8400/read

# 4. Get unread count
curl http://localhost:3000/api/notifications/customer/550e8400-e29b-41d4-a716-446655440000/unread-count

# 5. Update order
curl -X PATCH http://localhost:3000/api/orders/550e8400-e29b-41d4-a716-446655440001 \
  -H "Content-Type: application/json" \
  -d '{"status": "processing"}'

# 6. Bulk update
curl -X POST http://localhost:3000/api/orders/bulk-update \
  -H "Content-Type: application/json" \
  -d '{
    "orderIds": ["order-1", "order-2", "order-3"],
    "newStatus": "processing"
  }'
```

---

## .env File Template

```bash
# Supabase
SUPABASE_URL=https://xxxxx.supabase.co
SUPABASE_ANON_KEY=eyJ0eXAiOiJKV1QiLCJhbGc...
SUPABASE_SERVICE_ROLE_KEY=eyJ0eXAiOiJKV1QiLCJhbGc...

# Server
API_PORT=3000
NODE_ENV=production

# Logging
LOG_LEVEL=info
LOG_FILE=/var/log/ilaba/notifications.log
```

---

## Monitoring SQL Queries

```sql
-- Notifications by status (last 7 days)
SELECT status, COUNT(*) FROM notifications 
WHERE created_at > NOW() - INTERVAL '7 days'
GROUP BY status;

-- Unread notifications
SELECT customer_id, COUNT(*) as unread_count FROM notifications 
WHERE is_read = FALSE
GROUP BY customer_id ORDER BY unread_count DESC;

-- Notification creation rate (hourly)
SELECT DATE_TRUNC('hour', created_at), COUNT(*) FROM notifications 
WHERE created_at > NOW() - INTERVAL '24 hours'
GROUP BY DATE_TRUNC('hour', created_at);

-- Average read time
SELECT AVG(EXTRACT(EPOCH FROM (updated_at - created_at)) / 60) as avg_minutes 
FROM notifications WHERE is_read = TRUE;
```

---

## Error Handling Pattern

```javascript
async function safeNotificationCreate(data, maxRetries = 3) {
  for (let attempt = 1; attempt <= maxRetries; attempt++) {
    try {
      return await createNotification(
        data.customerId,
        data.orderId,
        data.newStatus,
        data.previousStatus
      );
    } catch (error) {
      console.error(`Attempt ${attempt} failed:`, error);
      if (attempt === maxRetries) throw error;
      
      const delay = Math.pow(2, attempt) * 1000;
      console.log(`Retrying in ${delay}ms...`);
      await new Promise(resolve => setTimeout(resolve, delay));
    }
  }
}
```

---

## Verification Checklist

```bash
# 1. Database tables exist
psql -c "SELECT tablename FROM pg_tables WHERE schemaname='public' AND tablename LIKE 'notification%';"
# Should show: notifications, notification_preferences, notification_audit_log, notification_retry_queue

# 2. Indexes created
psql -c "SELECT indexname FROM pg_indexes WHERE tablename='notifications' ORDER BY indexname;"
# Should show: 6 indexes (idx_notifications_customer_id, etc.)

# 3. RLS enabled
psql -c "SELECT tablename, rowsecurity FROM pg_tables WHERE schemaname='public' AND tablename='notifications';"
# Should show: rowsecurity = true

# 4. API running
curl http://localhost:3000/api/notifications/customer/test
# Should return: JSON response or 404 (not connection refused)

# 5. Test notification creation
curl -X POST http://localhost:3000/api/notifications/create -H "Content-Type: application/json" \
  -d '{"customer_id": "test", "order_id": "test", "new_status": "pending", "previous_status": null}'
# Should return: { "success": true, "notificationId": "..." }
```

---

## Common Status Transitions

```
pending (0 min)
   ↓ 30 minutes
processing (30 min - 4 hours)
   ↓ 4 hours
for_pick-up
   ↓ (customer picks up)
for_delivery (variable)
   ↓ (delivery time)
completed ✅

(any status) → cancelled ❌
```

---

## Key Integration Points

1. **When order is created**: Create "pending" notification
2. **When order status updates**: Create corresponding notification
3. **Bulk order operations**: Create batch of notifications
4. **Scheduled jobs**: Auto-transition old orders and create notifications
5. **Customer preferences**: Check before creating (optional)
6. **Error handling**: Retry failed notifications with backoff
7. **Monitoring**: Track metrics, log all operations

---

## Performance Tips

```javascript
// ✅ Good: Batch insert multiple notifications
await supabase.from('notifications').insert([
  { id: 'n1', customer_id: 'c1', ... },
  { id: 'n2', customer_id: 'c2', ... },
  { id: 'n3', customer_id: 'c3', ... }
]);

// ✅ Good: Use indexes in queries
SELECT * FROM notifications 
WHERE customer_id = '...' AND is_read = FALSE
ORDER BY created_at DESC;

// ✅ Good: Pagination
SELECT * FROM notifications LIMIT 50 OFFSET 0;

// ❌ Avoid: Full table scans
SELECT * FROM notifications WHERE title LIKE '%Order%';

// ❌ Avoid: Missing WHERE clauses
SELECT * FROM notifications ORDER BY created_at DESC; -- Slow if table is large
```

---

## One-Minute Setup

```bash
# 1. Install dependencies
npm install @supabase/supabase-js express cors

# 2. Create .env
echo "SUPABASE_URL=https://xxx.supabase.co" > .env
echo "SUPABASE_SERVICE_ROLE_KEY=xxx" >> .env

# 3. Create notification function in your code (copy from above)

# 4. Create Supabase tables (copy SQL from above)

# 5. Test
npm start
curl http://localhost:3000/api/notifications/customer/test

# Done! 🎉
```

---

## Support Resources

| Issue | Solution |
|-------|----------|
| Notifications not creating | Check RLS policies, verify customer_id format |
| Slow queries | Run ANALYZE, verify indexes exist |
| Real-time not working | Enable in Supabase, verify publication |
| Duplicate notifications | Check order update logic, use idempotency key |
| API not starting | Check port availability, verify env vars |

---

**Print this page for quick reference!** 📋

Last Updated: January 28, 2026  
Version: 1.0  
Status: Production Ready ✅
