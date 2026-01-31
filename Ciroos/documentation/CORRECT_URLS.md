# Correct Application URLs - Use These!

**Updated:** January 31, 2026

---

## ✅ C1 Frontend Application (Public)

**Correct Load Balancer URL:**
```
http://a9dd2c5fde37e4c6abd04a564ea3ef95-a64aa6c61219d593.elb.us-east-1.amazonaws.com
```

**Service Name:** `apm-test-app`
**App Type:** Python Flask with OpenTelemetry
**Access:** Public (internet-facing)

---

## 📍 All Available Endpoints

### 1. Health Check
```
GET http://a9dd2c5fde37e4c6abd04a564ea3ef95-a64aa6c61219d593.elb.us-east-1.amazonaws.com/health
```

**Response:**
```json
{
  "cluster": "C1",
  "service": "apm-test-app",
  "status": "healthy"
}
```

---

### 2. Users API (Local C1)
```
GET http://a9dd2c5fde37e4c6abd04a564ea3ef95-a64aa6c61219d593.elb.us-east-1.amazonaws.com/api/users
```

**Response:**
```json
{
  "users": [
    {"id": 1, "name": "Alice"},
    {"id": 2, "name": "Bob"},
    {"id": 3, "name": "Charlie"}
  ],
  "count": 3,
  "cluster": "C1"
}
```

---

### 3. Orders API (Cross-Region)
```
GET http://a9dd2c5fde37e4c6abd04a564ea3ef95-a64aa6c61219d593.elb.us-east-1.amazonaws.com/api/orders
```

**What it does:**
- Queries local database in C1
- Calls C2 backend for inventory (cross-region)
- Calls C2 backend for shipping (cross-region)

**Response:**
```json
{
  "orders": [
    {"id": 1, "total": 245},
    {"id": 2, "total": 123},
    ...
  ],
  "count": 5,
  "inventory": {
    "items": [...],
    "cluster": "C2"
  },
  "shipping": {
    "shipping_options": [...],
    "cluster": "C2"
  },
  "cluster": "C1"
}
```

---

### 4. Checkout API (Cross-Region Payment)
```
GET http://a9dd2c5fde37e4c6abd04a564ea3ef95-a64aa6c61219d593.elb.us-east-1.amazonaws.com/api/checkout
```

**What it does:**
- Calls C2 backend payment processing service
- **20% failure rate** (intentional for demo)

**Success Response:**
```json
{
  "status": "success",
  "order_id": "order_34567",
  "payment": {
    "status": "success",
    "transaction_id": "tx_45678",
    "cluster": "C2"
  },
  "cluster": "C1"
}
```

**Failure Response (20% of the time):**
```json
{
  "error": "Payment declined",
  "details": {...}
}
```
**HTTP Status:** 402

---

### 5. Slow Endpoint (Performance Testing)
```
GET http://a9dd2c5fde37e4c6abd04a564ea3ef95-a64aa6c61219d593.elb.us-east-1.amazonaws.com/api/slow
```

**What it does:**
- Intentionally delays 0.5-1.5 seconds
- For testing latency monitoring in Splunk

**Response:**
```json
{
  "status": "completed",
  "duration": "slow",
  "cluster": "C1"
}
```

---

### 6. Error Endpoint (Error Testing)
```
GET http://a9dd2c5fde37e4c6abd04a564ea3ef95-a64aa6c61219d593.elb.us-east-1.amazonaws.com/api/error
```

**What it does:**
- Always returns an error
- For testing error monitoring in Splunk

**Response:**
```json
{
  "error": "Internal Server Error",
  "message": "Simulated error",
  "cluster": "C1"
}
```
**HTTP Status:** 500

---

## 🔒 C2 Backend Application (Internal Only)

**Internal Load Balancer URL:**
```
http://ac3dc550dad9847ea805e20c963ee7ba-39ea100930485fc4.elb.us-west-2.amazonaws.com
```

**Service Name:** `apm-backend-app`
**App Type:** Python Flask with OpenTelemetry
**Access:** Internal only (not accessible from internet)

**Endpoints:**
- `/health`
- `/api/inventory`
- `/api/shipping`
- `/api/payment/process`

**⚠️ Security Note:** This URL will NOT work from your browser or external tools. It's only accessible from within the C1 VPC via VPC peering.

---

## ❌ Old/Wrong URLs (Don't Use These)

### Demo App (Old - Ignore)
```
http://ab565512bbcbf4cf5ac5ba54c67d8071-4607189aed878535.elb.us-east-1.amazonaws.com
```
**This is the old nginx demo app** - just shows a status page, not the proper API endpoints.

---

## 🧪 Quick Test Commands

### Test from your terminal:

```bash
# Health check
curl http://a9dd2c5fde37e4c6abd04a564ea3ef95-a64aa6c61219d593.elb.us-east-1.amazonaws.com/health

# Users (local C1)
curl http://a9dd2c5fde37e4c6abd04a564ea3ef95-a64aa6c61219d593.elb.us-east-1.amazonaws.com/api/users

# Orders (cross-region)
curl http://a9dd2c5fde37e4c6abd04a564ea3ef95-a64aa6c61219d593.elb.us-east-1.amazonaws.com/api/orders

# Checkout (might fail 20% of time)
curl http://a9dd2c5fde37e4c6abd04a564ea3ef95-a64aa6c61219d593.elb.us-east-1.amazonaws.com/api/checkout

# Slow endpoint
curl http://a9dd2c5fde37e4c6abd04a564ea3ef95-a64aa6c61219d593.elb.us-east-1.amazonaws.com/api/slow

# Error endpoint
curl http://a9dd2c5fde37e4c6abd04a564ea3ef95-a64aa6c61219d593.elb.us-east-1.amazonaws.com/api/error
```

---

## 📝 For Your Demo Script

Replace all URLs in your demo materials with:

**C1 Frontend:**
```
http://a9dd2c5fde37e4c6abd04a564ea3ef95-a64aa6c61219d593.elb.us-east-1.amazonaws.com
```

**C2 Backend:**
```
http://ac3dc550dad9847ea805e20c963ee7ba-39ea100930485fc4.elb.us-west-2.amazonaws.com
```
(Internal only - won't work from internet)

---

## ✅ Verification

All correct endpoints tested and working:
- ✅ Health check: Returns JSON
- ✅ Users API: Returns user data
- ✅ Orders API: Returns orders (inventory/shipping may be empty from external access)
- ✅ Checkout API: Returns payment result (20% failure rate)
- ✅ Slow endpoint: Returns after delay
- ✅ Error endpoint: Returns 500 error

**Use these URLs for your demo tomorrow!** 🚀
