# Supabase Notifications Setup - Step-by-Step Configuration

## Complete Supabase Dashboard Setup Guide

**For**: DevOps, Backend engineers, Database administrators
**Time Estimate**: 30-45 minutes
**Prerequisites**: Supabase account, Admin access to project

---

## Table of Contents

1. [Project Setup](#project-setup)
2. [Database Table Creation](#database-table-creation)
3. [Row Level Security (RLS)](#row-level-security-rls)
4. [Indexes & Performance](#indexes--performance)
5. [Real-time Subscriptions](#real-time-subscriptions)
6. [Backup & Recovery](#backup--recovery)
7. [Monitoring & Logs](#monitoring--logs)
8. [Verification Checklist](#verification-checklist)

---

## Project Setup

### 1. Create New Supabase Project (or use existing)

```
Go to https://app.supabase.com
1. Click "New Project"
2. Enter project name: ilaba-notifications
3. Set database password (SAVE THIS!)
4. Choose region: Closest to your users
5. Click "Create new project"
6. Wait 2-3 minutes for setup
```

### 2. Get Connection Details

Navigate to: **Settings → Database**

You'll see:
- **Host**: `xyz.supabase.co`
- **Port**: `5432`
- **Database**: `postgres`
- **User**: `postgres`
- **Password**: Your chosen password

Navigate to: **Settings → API**

You'll see:
- **Project URL**: `https://xyz.supabase.co`
- **Anon Key**: For client applications
- **Service Role Secret**: For backend (KEEP SECRET!)

**⚠️ Store these in your `.env` file:**
```bash
SUPABASE_URL=https://xyz.supabase.co
SUPABASE_ANON_KEY=eyJ0eXAiOiJKV1QiLCJhbGc...
SUPABASE_SERVICE_ROLE_KEY=eyJ0eXAiOiJKV1QiLCJhbGc...
```

---

## Database Table Creation

### Step 1: Access SQL Editor

Go to **SQL Editor** in left sidebar

### Step 2: Execute Table Creation SQL

Copy and paste this complete SQL script:

```sql
-- ============================================
-- 1. CREATE NOTIFICATIONS TABLE
-- ============================================

CREATE TABLE IF NOT EXISTS public.notifications (
  -- Primary Key
  id TEXT PRIMARY KEY,
  
  -- Foreign Keys
  customer_id UUID NOT NULL REFERENCES public.customers(id) ON DELETE CASCADE,
  order_id UUID NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
  
  -- Content
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  status TEXT NOT NULL,
  type TEXT NOT NULL DEFAULT 'order_update',
  
  -- Status tracking
  is_read BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  
  -- Additional data
  metadata JSONB,
  
  -- Constraints
  CONSTRAINT status_valid CHECK (
    status IN ('pending', 'for_pick-up', 'processing', 'for_delivery', 'completed', 'cancelled')
  ),
  CONSTRAINT type_valid CHECK (
    type IN ('status_change', 'order_update', 'system')
  )
);

-- ============================================
-- 2. CREATE INDEXES FOR PERFORMANCE
-- ============================================

-- Primary lookup index
CREATE INDEX idx_notifications_customer_id 
  ON public.notifications(customer_id DESC);

-- Order lookup
CREATE INDEX idx_notifications_order_id 
  ON public.notifications(order_id);

-- Time-based queries
CREATE INDEX idx_notifications_created_at 
  ON public.notifications(created_at DESC);

-- Read status queries
CREATE INDEX idx_notifications_is_read 
  ON public.notifications(is_read, customer_id);

-- Status queries
CREATE INDEX idx_notifications_status 
  ON public.notifications(status);

-- Composite index for common queries (get unread notifications)
CREATE INDEX idx_notifications_customer_read 
  ON public.notifications(customer_id, is_read DESC, created_at DESC);

-- ============================================
-- 3. CREATE NOTIFICATION PREFERENCES TABLE
-- ============================================

CREATE TABLE IF NOT EXISTS public.notification_preferences (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  customer_id UUID NOT NULL REFERENCES public.customers(id) ON DELETE CASCADE,
  
  -- Notification type toggles
  notify_pending BOOLEAN DEFAULT TRUE,
  notify_processing BOOLEAN DEFAULT TRUE,
  notify_pickup BOOLEAN DEFAULT TRUE,
  notify_delivery BOOLEAN DEFAULT TRUE,
  notify_completed BOOLEAN DEFAULT TRUE,
  notify_cancelled BOOLEAN DEFAULT TRUE,
  
  -- Channel preferences (for future)
  push_notifications BOOLEAN DEFAULT TRUE,
  email_notifications BOOLEAN DEFAULT FALSE,
  sms_notifications BOOLEAN DEFAULT FALSE,
  
  -- Do not disturb
  quiet_hours_enabled BOOLEAN DEFAULT FALSE,
  quiet_hours_start TIME,
  quiet_hours_end TIME,
  
  -- Timestamps
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  
  -- Uniqueness
  UNIQUE(customer_id)
);

-- Index for preferences lookup
CREATE INDEX idx_notification_preferences_customer_id 
  ON public.notification_preferences(customer_id);

-- ============================================
-- 4. CREATE AUDIT LOG TABLE
-- ============================================

CREATE TABLE IF NOT EXISTS public.notification_audit_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  notification_id TEXT NOT NULL REFERENCES public.notifications(id) ON DELETE CASCADE,
  action TEXT NOT NULL,
  previous_state JSONB,
  new_state JSONB,
  actor TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Index for audit lookups
CREATE INDEX idx_notification_audit_notification_id 
  ON public.notification_audit_log(notification_id);

CREATE INDEX idx_notification_audit_created_at 
  ON public.notification_audit_log(created_at DESC);

-- ============================================
-- 5. CREATE RETRY QUEUE TABLE
-- ============================================

CREATE TABLE IF NOT EXISTS public.notification_retry_queue (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  notification_data JSONB NOT NULL,
  retry_count INTEGER DEFAULT 0,
  last_error TEXT,
  next_retry_at TIMESTAMP WITH TIME ZONE NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Index for retry processing
CREATE INDEX idx_notification_retry_next_retry 
  ON public.notification_retry_queue(next_retry_at);

CREATE INDEX idx_notification_retry_count 
  ON public.notification_retry_queue(retry_count);

-- ============================================
-- 6. ENABLE REALTIME (Optional but Recommended)
-- ============================================

-- Enable realtime for notifications table
ALTER PUBLICATION supabase_realtime ADD TABLE public.notifications;
ALTER PUBLICATION supabase_realtime ADD TABLE public.notification_preferences;

-- ============================================
-- 7. CREATE UTILITY FUNCTIONS
-- ============================================

-- Function to get unread notification count
CREATE OR REPLACE FUNCTION public.get_unread_notification_count(customer_id_param UUID)
RETURNS INTEGER AS $$
SELECT COUNT(*)::INTEGER
FROM public.notifications
WHERE customer_id = customer_id_param
  AND is_read = FALSE;
$$ LANGUAGE SQL;

-- Function to mark all notifications as read
CREATE OR REPLACE FUNCTION public.mark_all_notifications_read(customer_id_param UUID)
RETURNS INTEGER AS $$
UPDATE public.notifications
SET is_read = TRUE, updated_at = CURRENT_TIMESTAMP
WHERE customer_id = customer_id_param AND is_read = FALSE
RETURNING 1;
$$ LANGUAGE SQL;

-- ============================================
-- 8. ENABLE ROW LEVEL SECURITY
-- ============================================

ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notification_preferences ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notification_audit_log ENABLE ROW LEVEL SECURITY;

PRINT 'Tables created successfully! Now configure RLS policies.';
```

Click **"Run"** to execute. You should see "Success" message.

### Step 3: Verify Tables Created

Go to **Table Editor** in sidebar. You should see:
- ✅ `notifications`
- ✅ `notification_preferences`
- ✅ `notification_audit_log`
- ✅ `notification_retry_queue`

---

## Row Level Security (RLS)

### Step 1: Enable RLS on Notifications Table

In **SQL Editor**, run:

```sql
-- ============================================
-- CUSTOMER POLICIES
-- ============================================

-- Policy 1: Customers can view their own notifications
CREATE POLICY "Customers view own notifications"
  ON public.notifications
  FOR SELECT
  USING (
    auth.uid()::text = customer_id::text 
    OR
    customer_id::text = (SELECT auth.uid()::text)
  );

-- Policy 2: Customers can update their own notifications (mark as read)
CREATE POLICY "Customers update own notifications"
  ON public.notifications
  FOR UPDATE
  USING (auth.uid()::text = customer_id::text)
  WITH CHECK (auth.uid()::text = customer_id::text);

-- Policy 3: Customers can delete their own notifications
CREATE POLICY "Customers delete own notifications"
  ON public.notifications
  FOR DELETE
  USING (auth.uid()::text = customer_id::text);

-- ============================================
-- ADMIN/STAFF POLICIES
-- ============================================

-- Policy 4: Admin can view all notifications
CREATE POLICY "Admins view all notifications"
  ON public.notifications
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.staff
      WHERE staff.id = auth.uid()
      AND staff.role IN ('admin', 'manager')
    )
  );

-- Policy 5: Admin can insert notifications
CREATE POLICY "Admins insert notifications"
  ON public.notifications
  FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.staff
      WHERE staff.id = auth.uid()
      AND staff.role = 'admin'
    )
  );

-- ============================================
-- SERVICE ROLE POLICIES
-- ============================================

-- Policy 6: Service role can perform all operations
-- (Service role bypasses RLS automatically when using service key)
```

### Step 2: Configure Preferences RLS

```sql
-- ============================================
-- NOTIFICATION PREFERENCES POLICIES
-- ============================================

-- Customers view own preferences
CREATE POLICY "Customers view own preferences"
  ON public.notification_preferences
  FOR SELECT
  USING (auth.uid()::text = customer_id::text);

-- Customers update own preferences
CREATE POLICY "Customers update own preferences"
  ON public.notification_preferences
  FOR UPDATE
  USING (auth.uid()::text = customer_id::text)
  WITH CHECK (auth.uid()::text = customer_id::text);

-- Customers can insert their own preferences
CREATE POLICY "Customers insert own preferences"
  ON public.notification_preferences
  FOR INSERT
  WITH CHECK (auth.uid()::text = customer_id::text);

-- Admin can view all
CREATE POLICY "Admins view all preferences"
  ON public.notification_preferences
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.staff
      WHERE staff.id = auth.uid()
      AND staff.role IN ('admin', 'manager')
    )
  );
```

### Step 3: Configure Audit Log RLS

```sql
-- ============================================
-- NOTIFICATION AUDIT LOG POLICIES
-- ============================================

-- Only admins can view audit logs
CREATE POLICY "Admins view audit logs"
  ON public.notification_audit_log
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.staff
      WHERE staff.id = auth.uid()
      AND staff.role = 'admin'
    )
  );

-- Only system can insert (via triggers)
CREATE POLICY "System inserts audit logs"
  ON public.notification_audit_log
  FOR INSERT
  WITH CHECK (true);
```

---

## Indexes & Performance

### Step 1: Verify Indexes

Go to **SQL Editor** and run:

```sql
-- Check if all indexes exist
SELECT
  indexname,
  indexdef,
  tablename
FROM pg_indexes
WHERE schemaname = 'public'
  AND tablename = 'notifications'
ORDER BY indexname;
```

You should see 6 indexes:
- ✅ `idx_notifications_customer_id`
- ✅ `idx_notifications_order_id`
- ✅ `idx_notifications_created_at`
- ✅ `idx_notifications_is_read`
- ✅ `idx_notifications_status`
- ✅ `idx_notifications_customer_read` (composite)

### Step 2: Query Performance

Test query performance:

```sql
-- Test 1: Get customer's unread notifications (should use idx_notifications_customer_read)
EXPLAIN ANALYZE
SELECT * FROM notifications
WHERE customer_id = '550e8400-e29b-41d4-a716-446655440000'
  AND is_read = FALSE
ORDER BY created_at DESC
LIMIT 10;

-- Test 2: Get recent notifications (should use idx_notifications_created_at)
EXPLAIN ANALYZE
SELECT * FROM notifications
ORDER BY created_at DESC
LIMIT 50;

-- Test 3: Find notifications by status (should use idx_notifications_status)
EXPLAIN ANALYZE
SELECT * FROM notifications
WHERE status = 'processing'
ORDER BY created_at DESC;
```

Look for "Index Scan" in results (good!) vs "Seq Scan" (bad!)

---

## Real-time Subscriptions

### Step 1: Enable Real-time

Go to **Settings → Realtime** in Supabase dashboard

Click **"Enable Realtime"** (if not already enabled)

### Step 2: Configure Which Tables Broadcast

Go to **SQL Editor**:

```sql
-- Enable realtime for notifications
ALTER PUBLICATION supabase_realtime ADD TABLE public.notifications;

-- Verify configuration
SELECT * FROM pg_publication_tables 
WHERE pubname = 'supabase_realtime';
```

### Step 3: Test Real-time (Optional)

Use Supabase CLI:

```bash
# Install Supabase CLI if not already
npm install -g supabase

# Test real-time connection
supabase realtime test
```

---

## Backup & Recovery

### Step 1: Enable Automated Backups

Go to **Settings → Backup**

1. Enable "Automatic backups"
2. Set frequency: **Daily**
3. Retention: **7-30 days** (depending on data criticality)
4. Backup window: **2-4 AM** (off-peak hours)

### Step 2: Manual Backup

Go to **Settings → Backup**

Click **"Create manual backup"**

Name it: `notifications_full_backup_YYYY-MM-DD`

### Step 3: Export Data (Safety)

```bash
# Export notifications data as SQL
supabase db pull

# Export notifications as CSV
psql $DATABASE_URL \
  -c "COPY notifications TO STDOUT WITH CSV HEADER" \
  > notifications_backup.csv
```

### Step 4: Restore from Backup

```bash
# If needed to restore
supabase db reset

# Or restore specific table
psql $DATABASE_URL < notifications_backup.sql
```

---

## Monitoring & Logs

### Step 1: Access Logs

Go to **Logs** in sidebar

### Step 2: Query Slow Logs

```sql
-- Find slow queries
SELECT
  mean_exec_time,
  calls,
  query
FROM pg_stat_statements
WHERE query LIKE '%notifications%'
ORDER BY mean_exec_time DESC;
```

### Step 3: Monitor Table Size

```sql
-- Check table sizes
SELECT
  schemaname,
  tablename,
  pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size
FROM pg_tables
WHERE schemaname = 'public'
  AND tablename IN ('notifications', 'notification_preferences')
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;
```

### Step 4: Set Up Alerts

Go to **Settings → Monitoring**

Create alerts for:
- Database CPU > 80%
- Storage usage > 80%
- Connection pool saturation
- Query latency > 1s

---

## Verification Checklist

### Database Structure

Run this in SQL Editor to verify everything:

```sql
-- ========== VERIFY TABLES ==========
SELECT tablename FROM pg_tables 
WHERE schemaname = 'public' 
  AND tablename LIKE 'notification%'
ORDER BY tablename;
-- Expected: 4 tables (notifications, notification_preferences, notification_audit_log, notification_retry_queue)

-- ========== VERIFY COLUMNS ==========
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_schema = 'public' AND table_name = 'notifications'
ORDER BY ordinal_position;

-- ========== VERIFY INDEXES ==========
SELECT indexname FROM pg_indexes 
WHERE schemaname = 'public' AND tablename = 'notifications'
ORDER BY indexname;
-- Expected: 6 indexes

-- ========== VERIFY CONSTRAINTS ==========
SELECT constraint_name, constraint_type 
FROM information_schema.table_constraints 
WHERE table_schema = 'public' AND table_name = 'notifications';

-- ========== VERIFY RLS ENABLED ==========
SELECT tablename, rowsecurity 
FROM pg_tables 
WHERE schemaname = 'public' 
  AND tablename LIKE 'notification%';
-- Expected: rowsecurity = true for all tables

-- ========== VERIFY POLICIES ==========
SELECT schemaname, tablename, policyname 
FROM pg_policies 
WHERE schemaname = 'public' 
  AND tablename LIKE 'notification%'
ORDER BY tablename, policyname;

-- ========== VERIFY REALTIME ==========
SELECT * FROM pg_publication_tables 
WHERE pubname = 'supabase_realtime' 
  AND tablename LIKE 'notification%';
```

### Functional Tests

```sql
-- ========== TEST 1: Insert notification ==========
INSERT INTO public.notifications (
  id, customer_id, order_id, title, message, status, type
) VALUES (
  'test_1_' || TO_CHAR(CURRENT_TIMESTAMP, 'YYYYMMDDHH24MISSUS'),
  '550e8400-e29b-41d4-a716-446655440000',
  '550e8400-e29b-41d4-a716-446655440001',
  'Test Notification',
  'This is a test',
  'pending',
  'status_change'
);

-- ========== TEST 2: Query notifications ==========
SELECT * FROM notifications 
WHERE status = 'pending' 
LIMIT 1;

-- ========== TEST 3: Update notification ==========
UPDATE notifications 
SET is_read = TRUE, updated_at = CURRENT_TIMESTAMP
WHERE id LIKE 'test_1_%' 
LIMIT 1;

-- ========== TEST 4: Get unread count ==========
SELECT COUNT(*) FROM notifications 
WHERE is_read = FALSE;

-- ========== TEST 5: Create preferences ==========
INSERT INTO notification_preferences (
  customer_id, notify_pending, notify_processing, notify_delivery, notify_completed
) VALUES (
  '550e8400-e29b-41d4-a716-446655440000',
  TRUE, TRUE, TRUE, TRUE
);

-- ========== CLEANUP: Delete test data ==========
DELETE FROM notifications WHERE id LIKE 'test_%';
DELETE FROM notification_preferences 
WHERE customer_id = '550e8400-e29b-41d4-a716-446655440000';
```

---

## Configuration Summary

### Completed Setup ✅

- [x] Tables created (4 tables)
- [x] Columns defined with constraints
- [x] Indexes created (6 indexes) for performance
- [x] RLS enabled on all tables
- [x] Policies configured (customer, admin, service role)
- [x] Real-time enabled
- [x] Utility functions created
- [x] Backups configured

### Environment Variables Configured ✅

```bash
SUPABASE_URL=https://xyz.supabase.co
SUPABASE_ANON_KEY=eyJ0eXAiOiJKV1QiLCJhbGc...
SUPABASE_SERVICE_ROLE_KEY=eyJ0eXAiOiJKV1QiLCJhbGc...
```

### Ready for API Integration ✅

Your Supabase backend is now ready for:
- ✅ Creating notifications
- ✅ Fetching notifications
- ✅ Updating notification status
- ✅ Managing preferences
- ✅ Real-time subscriptions
- ✅ Audit logging

---

## Troubleshooting

### Issue: RLS Blocking Queries

**Symptom**: Getting "PGRST400" or permission denied errors

**Solution**:
```sql
-- Check if RLS is too restrictive
ALTER TABLE notifications DISABLE ROW LEVEL SECURITY;

-- Test without RLS
-- Then re-enable with corrected policies
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
```

### Issue: Slow Queries

**Symptom**: Queries taking > 1 second

**Solution**:
```sql
-- Check index usage
EXPLAIN ANALYZE SELECT * FROM notifications 
WHERE customer_id = '...';

-- Create missing index if needed
CREATE INDEX idx_notifications_custom ON notifications(customer_id, is_read);

-- Analyze table statistics
ANALYZE notifications;
```

### Issue: Real-time Not Working

**Symptom**: Changes not broadcasting to subscribers

**Solution**:
1. Verify table is in publication:
```sql
SELECT * FROM pg_publication_tables 
WHERE pubname = 'supabase_realtime';
```

2. Check RLS isn't blocking:
```sql
ALTER TABLE notifications DISABLE ROW LEVEL SECURITY;
-- Test real-time
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
```

3. Restart real-time: Go to **Settings → Realtime → Restart**

---

## Next Steps

1. ✅ Setup complete!
2. 📝 Deploy backend API using the Backend Implementation Guide
3. 🔄 Integrate with Flutter app
4. 📊 Monitor performance
5. 📈 Scale as needed

**You're all set!** 🚀
