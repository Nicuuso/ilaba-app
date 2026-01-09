# 📊 Order Flow Diagram

## Current (Broken) Flow

```
┌─────────────────────────────────────────────────────────────────────┐
│ MOBILE APP (Flutter) - booking_flow_screen.dart                    │
│                                                                      │
│ User creates order:                                                 │
│  - Selects customer                                                 │
│  - Adds baskets with services                                       │
│  - Adds products                                                    │
│  - Confirms payment                                                 │
└──────────────────────┬──────────────────────────────────────────────┘
                       │
                       │ User taps "Complete Order"
                       ↓
┌─────────────────────────────────────────────────────────────────────┐
│ booking_state_provider.dart - saveOrder()                          │
│                                                                      │
│ Creates JSON structure:                                             │
│ {                                                                   │
│   breakdown: {                                                      │
│     items: [...],        ← Product quantities                       │
│     baskets: [...],      ← Services + weights                       │
│     payment: {...},      ← Payment info                             │
│     fees: [...],                                                    │
│     summary: {...}                                                  │
│   },                                                                │
│   handling: {                                                       │
│     pickup: {...},       ← Pickup address + status                 │
│     delivery: {...}      ← Delivery address + status                │
│   }                                                                 │
│ }                                                                   │
└──────────────────────┬──────────────────────────────────────────────┘
                       │
                       │ HTTP POST with JSON
                       ↓
┌─────────────────────────────────────────────────────────────────────┐
│ pos_service_impl.dart                                              │
│                                                                      │
│ Logs: "Order Data: {breakdown: {...}, handling: {...}}"            │
│ Sends to: http://localhost:3000/api/pos/newOrder                   │
└──────────────────────┬──────────────────────────────────────────────┘
                       │
          ┌────────────┴────────────┐
          │                         │
      ✅ API Running          ❌ API Down/Not Running
          │                         │
          ↓                         ↓
    ┌──────────────┐         ┌─────────────┐
    │ Next.js API  │         │ SocketEx:   │
    │ Receives req │         │ Connection  │
    └──────┬───────┘         │ refused     │
           │                 └─────────────┘
           │
           ↓
    ┌─────────────────────────────────────────┐
    │ /api/pos/newOrder handler              │
    │ ❌ PROBLEM: Old Code                    │
    │                                         │
    │ Tries to INSERT into:                   │
    │  - baskets (GONE in new schema)         │
    │  - basket_services (GONE)               │
    │  - order_products (GONE)                │
    │  - payments (GONE)                      │
    │                                         │
    │ Ignores:                                │
    │  - breakdown field                      │
    │  - handling field                       │
    │                                         │
    │ Result: 400/500 error OR partially     │
    │ saved order without JSON fields        │
    └─────────────────────────────────────────┘
           │
           ↓ (Error or incomplete save)
    ┌─────────────────────────────────────────┐
    │ Supabase orders table                   │
    │                                         │
    │ INSERT into orders:                     │
    │  ✅ id                                  │
    │  ✅ customer_id                         │
    │  ✅ status                              │
    │  ✅ total_amount                        │
    │  ❌ breakdown = NULL/MISSING            │
    │  ❌ handling = NULL/MISSING             │
    │  ❌ cancellation = NULL/MISSING         │
    └─────────────────────────────────────────┘
           │
           │ User views order history
           ↓
    ┌─────────────────────────────────────────┐
    │ order_history_screen.dart               │
    │                                         │
    │ Fetches from Supabase:                  │
    │  breakdown: null/empty {}               │
    │  handling: null/empty {}                │
    │                                         │
    │ Display shows:                          │
    │ ❌ EMPTY boxes (red)                    │
    │ ⚠️ "Breakdown is EMPTY/NULL"           │
    │ 💡 "Backend API may not support..."    │
    └─────────────────────────────────────────┘
```

## Solution: Update Backend API

```
SAME as above UNTIL:

    ┌─────────────────────────────────────────┐
    │ /api/pos/newOrder handler              │
    │ ✅ UPDATED CODE                         │
    │                                         │
    │ Checks if breakdown/handling present:   │
    │  YES → new schema:                      │
    │    INSERT INTO orders (                 │
    │      breakdown,  ← Save JSON directly   │
    │      handling,   ← Save JSON directly   │
    │      cancellation                       │
    │    )                                    │
    │                                         │
    │  NO → old schema (fallback)             │
    │    INSERT into separate tables          │
    └─────────────────────────────────────────┘
           │
           ↓ (Success)
    ┌─────────────────────────────────────────┐
    │ Supabase orders table                   │
    │                                         │
    │ INSERT into orders:                     │
    │  ✅ id                                  │
    │  ✅ customer_id                         │
    │  ✅ status                              │
    │  ✅ total_amount                        │
    │  ✅ breakdown = {...full JSON...}       │
    │  ✅ handling = {...full JSON...}        │
    │  ✅ cancellation = null                 │
    └─────────────────────────────────────────┘
           │
           │ User views order history
           ↓
    ┌─────────────────────────────────────────┐
    │ order_history_screen.dart               │
    │                                         │
    │ Fetches from Supabase:                  │
    │  breakdown: {...full JSON...}           │
    │  handling: {...full JSON...}            │
    │                                         │
    │ Display shows:                          │
    │ ✅ All JSON data in colored boxes       │
    │ ✅ Items array expanded                 │
    │ ✅ Baskets with services shown          │
    │ ✅ Payment info visible                 │
    │ ✅ Handling addresses displayed         │
    └─────────────────────────────────────────┘
```

---

## Current Status of Each Component

| Component                  | Status      | Notes                                        |
| -------------------------- | ----------- | -------------------------------------------- |
| **Mobile Data Generation** | ✅ Working  | booking_state_provider correctly builds JSON |
| **Mobile Error Handling**  | ✅ Updated  | Enhanced logging and user messages           |
| **Order Display**          | ✅ Updated  | Shows clear warnings when data missing       |
| **Backend API**            | ❌ Outdated | Still uses old relational schema             |
| **Database Schema**        | ✅ Correct  | JSONB columns exist and support new data     |
| **Supabase**               | ✅ Ready    | Just needs data to be sent correctly         |

---

## What You Need to Do

### Immediate (Testing)

1. Make sure web server is running:

   ```bash
   cd c:\Users\kizen\Projects\katflix_ilaba
   npm run dev
   ```

2. Run Flutter app and create a test order

3. Check logs for error messages - they'll tell you exactly what's wrong

4. Look in Supabase for the saved order:
   ```sql
   SELECT breakdown, handling FROM orders
   WHERE created_at > NOW() - INTERVAL '1 hour'
   LIMIT 5;
   ```

### Then (Fix the Backend)

Update `src/app/api/pos/newOrder/route.ts` to handle the new schema.

---

## Key Files Updated

### Mobile App ✅

- `lib/screens/order_history_screen.dart` - Enhanced with warnings
- `lib/services/pos_service_impl.dart` - Better error messages
- Console logging - Detailed troubleshooting info

### Documentation 📄

- `API_SCHEMA_MISMATCH.md` - Detailed technical guide
- This file - Visual explanation

### Backend ❌ (Needs update)

- `src/app/api/pos/newOrder/route.ts` - Doesn't handle new schema

---

## Troubleshooting Checklist

- [ ] Is web server running? (`npm run dev`)
- [ ] Is `.env` pointing to correct `API_BASE_URL`?
- [ ] Can you reach the API? (check network tab)
- [ ] Is Supabase order being created at all?
- [ ] Does breakdown column have NULL or actual JSON?
- [ ] Check browser console for network errors
- [ ] Check Next.js console for API errors
- [ ] Check Flutter debugPrint output (Ctrl+Alt+J)
