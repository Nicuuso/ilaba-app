# Notifications API Developer Guide

## For Backend & Website API Teams

**Target**: Full-stack developers, API architects
**Time to Complete**: 30 minutes to understand, 4-6 hours to implement
**Complexity**: Intermediate

---

## Quick Start

### 1. Install Dependencies

```bash
# For Node.js/Express
npm install @supabase/supabase-js express cors body-parser node-schedule socket.io

# For Python/Flask
pip install supabase python-dotenv flask flask-cors

# For Go
go get github.com/supabase-community/supabase-go
```

### 2. Initialize Supabase Client

**Node.js:**
```javascript
const { createClient } = require('@supabase/supabase-js');

const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY
);

module.exports = supabase;
```

**Python:**
```python
from supabase import create_client, Client
import os

url = os.getenv("SUPABASE_URL")
key = os.getenv("SUPABASE_SERVICE_ROLE_KEY")
supabase: Client = create_client(url, key)
```

### 3. Create Notification on Order Update

**Node.js:**
```javascript
async function handleOrderStatusChange(orderId, newStatus, previousStatus, customerId) {
  const messages = {
    pending: {
      title: 'Order Confirmed! 🎉',
      message: 'We\'ve received your order and will get it ready for you shortly.'
    },
    processing: {
      title: 'Processing Your Order 🧺',
      message: 'Our team is now processing your laundry with care.'
    },
    for_delivery: {
      title: 'On the Way! 🚚',
      message: 'Your order is out for delivery. It will arrive soon!'
    },
    completed: {
      title: 'Order Complete! ✨',
      message: 'Your order has been successfully delivered. Thank you!'
    }
  };

  const msg = messages[newStatus] || { title: 'Order Updated', message: 'Your order status changed.' };

  const { data, error } = await supabase
    .from('notifications')
    .insert({
      id: `${Date.now()}_${orderId.substring(0, 8)}`,
      customer_id: customerId,
      order_id: orderId,
      title: msg.title,
      message: msg.message,
      status: newStatus,
      type: 'status_change',
      is_read: false,
      metadata: {
        previous_status: previousStatus,
        new_status: newStatus
      }
    });

  if (error) console.error('Error creating notification:', error);
  return data;
}
```

---

## Core Concepts

### Notification Model

Each notification has:
- `id` - Unique identifier
- `customer_id` - Owner of notification
- `order_id` - Related order
- `title` - Notification title
- `message` - Notification message
- `status` - Order status (pending, processing, for_delivery, completed, cancelled)
- `type` - Notification type (status_change, order_update, system)
- `is_read` - Read status
- `metadata` - Extra data (JSON)
- `created_at` - When created
- `updated_at` - Last update time

### Status Lifecycle

```
pending 
  ↓ (0-30 min)
processing 
  ↓ (30 min - 4 hours)
for_pick-up (OR)
  ↓
for_delivery 
  ↓ (variable)
completed ✅

(any status) → cancelled ❌
```

Each transition triggers an automatic notification.

---

## API Implementation Examples

### Complete Express.js Setup

```javascript
// ============================================
// FILE: server.js
// ============================================

const express = require('express');
const cors = require('cors');
const { createClient } = require('@supabase/supabase-js');
const schedule = require('node-schedule');

const app = express();

// Middleware
app.use(cors());
app.use(express.json());

// Initialize Supabase
const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY
);

// ============================================
// 1. CREATE NOTIFICATION
// ============================================

app.post('/api/notifications/create', async (req, res) => {
  try {
    const { customer_id, order_id, new_status, previous_status } = req.body;

    const STATUS_MESSAGES = {
      pending: {
        title: 'Order Confirmed! 🎉',
        message: 'We\'ve received your order and will get it ready for you shortly.',
        color: '#FFB81C'
      },
      for_pick_up: {
        title: 'Ready for Pickup! 📦',
        message: 'Your order is ready and waiting for you.',
        color: '#0066FF'
      },
      processing: {
        title: 'Processing Your Order 🧺',
        message: 'Our team is now processing your laundry with care.',
        color: '#6F42C1'
      },
      for_delivery: {
        title: 'On the Way! 🚚',
        message: 'Your order is out for delivery. It will arrive soon!',
        color: '#FFC107'
      },
      completed: {
        title: 'Order Complete! ✨',
        message: 'Your order has been successfully delivered. Thank you!',
        color: '#28A745'
      },
      cancelled: {
        title: 'Order Cancelled ❌',
        message: 'Your order has been cancelled.',
        color: '#DC3545'
      }
    };

    const messageData = STATUS_MESSAGES[new_status] || {
      title: 'Order Updated',
      message: 'Your order status has been updated.',
      color: '#6C757D'
    };

    const notificationId = `${Date.now()}_${order_id.substring(0, 8)}`;

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
          color: messageData.color
        }
      });

    if (error) throw error;

    res.json({
      success: true,
      notificationId,
      notification: messageData
    });

  } catch (error) {
    console.error('Error creating notification:', error);
    res.status(500).json({ error: error.message });
  }
});

// ============================================
// 2. GET NOTIFICATIONS FOR CUSTOMER
// ============================================

app.get('/api/notifications/customer/:customerId', async (req, res) => {
  try {
    const { customerId } = req.params;
    const { limit = 50, offset = 0 } = req.query;

    const { data: notifications, error } = await supabase
      .from('notifications')
      .select('*')
      .eq('customer_id', customerId)
      .order('created_at', { ascending: false })
      .range(offset, offset + limit - 1);

    if (error) throw error;

    // Get unread count
    const { count: unreadCount } = await supabase
      .from('notifications')
      .select('*', { count: 'exact', head: true })
      .eq('customer_id', customerId)
      .eq('is_read', false);

    res.json({
      success: true,
      count: notifications.length,
      unreadCount: unreadCount || 0,
      notifications
    });

  } catch (error) {
    console.error('Error fetching notifications:', error);
    res.status(500).json({ error: error.message });
  }
});

// ============================================
// 3. MARK NOTIFICATION AS READ
// ============================================

app.patch('/api/notifications/:notificationId/read', async (req, res) => {
  try {
    const { notificationId } = req.params;

    const { error } = await supabase
      .from('notifications')
      .update({
        is_read: true,
        updated_at: new Date().toISOString()
      })
      .eq('id', notificationId);

    if (error) throw error;

    res.json({ success: true });

  } catch (error) {
    console.error('Error marking as read:', error);
    res.status(500).json({ error: error.message });
  }
});

// ============================================
// 4. MARK ALL NOTIFICATIONS AS READ
// ============================================

app.patch('/api/notifications/customer/:customerId/read-all', async (req, res) => {
  try {
    const { customerId } = req.params;

    const { error } = await supabase
      .from('notifications')
      .update({
        is_read: true,
        updated_at: new Date().toISOString()
      })
      .eq('customer_id', customerId)
      .eq('is_read', false);

    if (error) throw error;

    res.json({ success: true });

  } catch (error) {
    console.error('Error marking all as read:', error);
    res.status(500).json({ error: error.message });
  }
});

// ============================================
// 5. DELETE NOTIFICATION
// ============================================

app.delete('/api/notifications/:notificationId', async (req, res) => {
  try {
    const { notificationId } = req.params;

    const { error } = await supabase
      .from('notifications')
      .delete()
      .eq('id', notificationId);

    if (error) throw error;

    res.json({ success: true });

  } catch (error) {
    console.error('Error deleting notification:', error);
    res.status(500).json({ error: error.message });
  }
});

// ============================================
// 6. GET UNREAD COUNT
// ============================================

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
      unreadCount: count || 0
    });

  } catch (error) {
    console.error('Error fetching unread count:', error);
    res.status(500).json({ error: error.message });
  }
});

// ============================================
// 7. UPDATE ORDER STATUS (with auto notification)
// ============================================

app.patch('/api/orders/:orderId', async (req, res) => {
  try {
    const { orderId } = req.params;
    const { status: newStatus } = req.body;

    // Get current order
    const { data: currentOrder, error: fetchError } = await supabase
      .from('orders')
      .select('id, customer_id, status')
      .eq('id', orderId)
      .single();

    if (fetchError) throw fetchError;

    const previousStatus = currentOrder.status;

    // Only proceed if status changed
    if (previousStatus === newStatus) {
      return res.json({
        success: true,
        notificationCreated: false,
        reason: 'Status unchanged'
      });
    }

    // Update order
    const { error: updateError } = await supabase
      .from('orders')
      .update({
        status: newStatus,
        updated_at: new Date().toISOString()
      })
      .eq('id', orderId);

    if (updateError) throw updateError;

    // Create notification
    const notificationResult = await createNotification({
      customer_id: currentOrder.customer_id,
      order_id: orderId,
      new_status: newStatus,
      previous_status: previousStatus
    });

    res.json({
      success: true,
      order: { id: orderId, previousStatus, newStatus },
      notification: notificationResult
    });

  } catch (error) {
    console.error('Error updating order:', error);
    res.status(500).json({ error: error.message });
  }
});

// ============================================
// SCHEDULED JOBS
// ============================================

// Auto-transition orders (every 5 minutes)
schedule.scheduleJob('*/5 * * * *', async () => {
  console.log('🔄 Running auto-transition job...');

  try {
    const now = new Date();
    const thirtyMinutesAgo = new Date(now.getTime() - 30 * 60 * 1000);

    // Find pending orders from 30 minutes ago
    const { data: orders, error } = await supabase
      .from('orders')
      .select('id, customer_id, status')
      .eq('status', 'pending')
      .lt('updated_at', thirtyMinutesAgo.toISOString());

    if (error) throw error;

    for (const order of orders) {
      await supabase
        .from('orders')
        .update({ status: 'processing', updated_at: new Date().toISOString() })
        .eq('id', order.id);

      // Create notification
      await createNotification({
        customer_id: order.customer_id,
        order_id: order.id,
        new_status: 'processing',
        previous_status: 'pending'
      });
    }

    console.log(`✅ Auto-transitioned ${orders.length} orders`);

  } catch (error) {
    console.error('Error in auto-transition job:', error);
  }
});

// Cleanup old notifications (daily at 2 AM)
schedule.scheduleJob('0 2 * * *', async () => {
  console.log('🧹 Running cleanup job...');

  try {
    const ninetyDaysAgo = new Date();
    ninetyDaysAgo.setDate(ninetyDaysAgo.getDate() - 90);

    const { error } = await supabase
      .from('notifications')
      .delete()
      .lt('created_at', ninetyDaysAgo.toISOString());

    if (error) throw error;

    console.log('✅ Cleanup completed');

  } catch (error) {
    console.error('Error in cleanup job:', error);
  }
});

// ============================================
// HELPER FUNCTION
// ============================================

async function createNotification(data) {
  return new Promise((resolve, reject) => {
    // Call the POST endpoint
    fetch('http://localhost:3000/api/notifications/create', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(data)
    })
    .then(res => res.json())
    .then(resolve)
    .catch(reject);
  });
}

// ============================================
// START SERVER
// ============================================

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`🚀 Server running on http://localhost:${PORT}`);
});
```

---

## Database Triggers (Alternative Approach)

Instead of calling the API, use a database trigger to auto-create notifications:

```sql
-- Create function to handle order status changes
CREATE OR REPLACE FUNCTION notify_on_order_update()
RETURNS TRIGGER AS $$
BEGIN
  -- Only proceed if status changed
  IF NEW.status IS DISTINCT FROM OLD.status THEN
    
    -- Define messages
    WITH status_msg AS (
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
          WHEN 'pending' THEN 'We''ve received your order and will get it ready for you shortly.'
          WHEN 'processing' THEN 'Our team is now processing your laundry with care.'
          WHEN 'for_pick-up' THEN 'Your order is ready and waiting for you.'
          WHEN 'for_delivery' THEN 'Your order is out for delivery. It will arrive soon!'
          WHEN 'completed' THEN 'Your order has been successfully delivered. Thank you!'
          WHEN 'cancelled' THEN 'Your order has been cancelled.'
          ELSE 'Your order status has been updated.'
        END AS message
    )
    INSERT INTO notifications (
      id,
      customer_id,
      order_id,
      title,
      message,
      status,
      type,
      is_read,
      metadata
    )
    SELECT
      TO_CHAR(CURRENT_TIMESTAMP, 'YYYYMMDDHH24MISSUS') || '_' || SUBSTRING(NEW.id::TEXT, 1, 8),
      NEW.customer_id,
      NEW.id,
      status_msg.title,
      status_msg.message,
      NEW.status,
      'status_change',
      FALSE,
      jsonb_build_object('previous_status', OLD.status, 'new_status', NEW.status)
    FROM status_msg;
    
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger
DROP TRIGGER IF EXISTS on_order_status_change ON orders;
CREATE TRIGGER on_order_status_change
  AFTER UPDATE ON orders
  FOR EACH ROW
  EXECUTE FUNCTION notify_on_order_update();
```

---

## Testing the API

### Using cURL

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

# 2. Get notifications
curl http://localhost:3000/api/notifications/customer/550e8400-e29b-41d4-a716-446655440000

# 3. Mark as read
curl -X PATCH http://localhost:3000/api/notifications/1704067200000_550e8400/read

# 4. Get unread count
curl http://localhost:3000/api/notifications/customer/550e8400-e29b-41d4-a716-446655440000/unread-count
```

### Using Postman

1. Create new Postman collection
2. Add requests above
3. Test each endpoint

---

## Environment Setup

**Create `.env` file:**
```bash
# Supabase
SUPABASE_URL=https://xyz.supabase.co
SUPABASE_ANON_KEY=eyJ0eXAiOiJKV1QiLCJhbGc...
SUPABASE_SERVICE_ROLE_KEY=eyJ0eXAiOiJKV1QiLCJhbGc...

# API
API_PORT=3000
NODE_ENV=production

# Logging
LOG_LEVEL=info
```

**Load environment:**
```javascript
require('dotenv').config();
```

---

## Error Handling

### Try-Catch Pattern

```javascript
async function safeNotificationCreate(data) {
  try {
    return await createNotification(data);
  } catch (error) {
    console.error('Notification creation failed:', error);
    // Log to Sentry or error tracking
    // Queue for retry
    // Return graceful failure
    return { success: false, error: error.message };
  }
}
```

### Retry Logic

```javascript
async function retryableNotificationCreate(data, maxRetries = 3) {
  for (let attempt = 1; attempt <= maxRetries; attempt++) {
    try {
      return await createNotification(data);
    } catch (error) {
      if (attempt === maxRetries) throw error;
      
      const delay = Math.pow(2, attempt) * 1000; // 2s, 4s, 8s
      console.log(`Retry ${attempt}/${maxRetries} in ${delay}ms`);
      await new Promise(resolve => setTimeout(resolve, delay));
    }
  }
}
```

---

## Monitoring

### Log Important Events

```javascript
// Log notification creation
console.log('📲 Notification created', {
  notificationId,
  customerId,
  orderId,
  status: newStatus,
  timestamp: new Date().toISOString()
});

// Log errors
console.error('❌ Notification failed', {
  error: error.message,
  customerId,
  orderId,
  stack: error.stack
});

// Log metrics
console.log('📊 Daily stats', {
  created: 1234,
  read: 956,
  unread: 278,
  errors: 5
});
```

### Export Metrics

```javascript
const metrics = {
  notifications_created_total: 0,
  notifications_read_total: 0,
  notifications_deleted_total: 0,
  notifications_errors_total: 0,
  notification_creation_time_ms: 0
};

// Track and export to monitoring service (DataDog, NewRelic, etc.)
```

---

## Deployment

### Docker Setup

```dockerfile
FROM node:18-alpine

WORKDIR /app

COPY package*.json ./
RUN npm ci --only=production

COPY . .

EXPOSE 3000

CMD ["node", "server.js"]
```

**Build and run:**
```bash
docker build -t ilaba-notifications-api .
docker run -p 3000:3000 --env-file .env ilaba-notifications-api
```

### Deploy to Cloud

**Heroku:**
```bash
heroku create ilaba-notifications-api
heroku config:set SUPABASE_URL=...
heroku config:set SUPABASE_SERVICE_ROLE_KEY=...
git push heroku main
```

**AWS Lambda + API Gateway:**
Use Serverless Framework or AWS SAM

**Google Cloud Run:**
```bash
gcloud run deploy ilaba-notifications-api \
  --source . \
  --platform managed \
  --region us-central1
```

---

## Performance Tips

1. **Use indexes** - Ensure database indexes on customer_id, created_at
2. **Batch operations** - Create multiple notifications in one query
3. **Cache unread counts** - Redis cache for fast lookups
4. **Pagination** - Limit query results (50 at a time)
5. **Connection pooling** - Supabase connection pool settings
6. **Async operations** - Don't block order update on notification creation

---

## Summary

You now have:
- ✅ Complete API implementation
- ✅ Database integration
- ✅ Error handling
- ✅ Scheduled jobs
- ✅ Testing examples
- ✅ Deployment guides

**Ready to deploy!** 🚀
