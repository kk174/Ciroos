# Demo Application Endpoint Testing Guide

**Date:** January 30, 2026
**Project:** Ciroos AWS Multi-Region EKS Demo

---

## Load Balancer URLs

### C1 (us-east-1) - Frontend Cluster
**Type:** Internet-Facing (Public)
**URL:** `http://ab565512bbcbf4cf5ac5ba54c67d8071-4607189aed878535.elb.us-east-1.amazonaws.com`
**Status:** ✅ **ACCESSIBLE FROM INTERNET**

### C2 (us-west-2) - Backend Cluster
**Type:** Internal Only (Private)
**URL:** `http://a11e332ddf414470781dcffadfcbff6e-02e4279cfc7d48f9.elb.us-west-2.amazonaws.com`
**Status:** ✅ **NOT ACCESSIBLE FROM INTERNET** (Security requirement met)

---

## C1 (Frontend) - Available Endpoints

### 1. Health Check Endpoint
**Purpose:** Load balancer health monitoring
**URL:** `http://ab565512bbcbf4cf5ac5ba54c67d8071-4607189aed878535.elb.us-east-1.amazonaws.com/health`

**Request:**
```bash
curl http://ab565512bbcbf4cf5ac5ba54c67d8071-4607189aed878535.elb.us-east-1.amazonaws.com/health
```

**Response:**
```json
{
  "status": "healthy",
  "cluster": "C1",
  "region": "us-east-1"
}
```
**HTTP Status:** 200 OK

---

### 2. Application Info Endpoint
**Purpose:** Display cluster and application metadata
**URL:** `http://ab565512bbcbf4cf5ac5ba54c67d8071-4607189aed878535.elb.us-east-1.amazonaws.com/info`

**Request:**
```bash
curl http://ab565512bbcbf4cf5ac5ba54c67d8071-4607189aed878535.elb.us-east-1.amazonaws.com/info
```

**Response:**
```json
{
  "cluster": "C1",
  "region": "us-east-1",
  "tier": "frontend",
  "app": "demo-app",
  "version": "1.0"
}
```
**HTTP Status:** 200 OK

---

### 3. Status Endpoint
**Purpose:** Service status check
**URL:** `http://ab565512bbcbf4cf5ac5ba54c67d8071-4607189aed878535.elb.us-east-1.amazonaws.com/status`

**Request:**
```bash
curl http://ab565512bbcbf4cf5ac5ba54c67d8071-4607189aed878535.elb.us-east-1.amazonaws.com/status
```

**Response:**
```json
{
  "status": "ok",
  "cluster": "C1",
  "uptime": "healthy",
  "message": "Service is running"
}
```
**HTTP Status:** 200 OK

---

### 4. Error Injection Endpoint
**Purpose:** Simulate server errors for observability testing
**URL:** `http://ab565512bbcbf4cf5ac5ba54c67d8071-4607189aed878535.elb.us-east-1.amazonaws.com/error`

**Request:**
```bash
curl http://ab565512bbcbf4cf5ac5ba54c67d8071-4607189aed878535.elb.us-east-1.amazonaws.com/error
```

**Response:**
```json
{
  "error": "Internal Server Error",
  "cluster": "C1",
  "message": "Intentional error for testing"
}
```
**HTTP Status:** 500 Internal Server Error

**Use Case:**
- Demonstrate Splunk error detection
- Test alerting systems
- Validate error rate monitoring

---

### 5. Random Failure Endpoint
**Purpose:** Simulate intermittent failures (30% error rate)
**URL:** `http://ab565512bbcbf4cf5ac5ba54c67d8071-4607189aed878535.elb.us-east-1.amazonaws.com/random`

**Request:**
```bash
curl http://ab565512bbcbf4cf5ac5ba54c67d8071-4607189aed878535.elb.us-east-1.amazonaws.com/random
```

**Success Response (70% probability):**
```json
{
  "status": "ok",
  "cluster": "C1",
  "message": "Random endpoint - success"
}
```
**HTTP Status:** 200 OK

**Failure Response (30% probability):**
```json
{
  "error": "Service Unavailable",
  "cluster": "C1",
  "message": "Random failure simulation"
}
```
**HTTP Status:** 503 Service Unavailable

**Use Case:**
- Simulate real-world intermittent failures
- Test observability detection of flaky services
- Demonstrate error rate trending in Splunk

---

### 6. Root/Home Endpoint
**Purpose:** Main application page
**URL:** `http://ab565512bbcbf4cf5ac5ba54c67d8071-4607189aed878535.elb.us-east-1.amazonaws.com/`

**Request:**
```bash
curl http://ab565512bbcbf4cf5ac5ba54c67d8071-4607189aed878535.elb.us-east-1.amazonaws.com/
```

**Response:**
```html
<html><body><h1>Ciroos Demo - Cluster C1</h1><p>Region: us-east-1 (Frontend)</p><p>Status: Running</p><p>Timestamp: 2026-01-31T00:42:15+00:00</p></body></html>
```
**HTTP Status:** 200 OK
**Content-Type:** text/html

---

## C2 (Backend) - Available Endpoints

**IMPORTANT:** C2 endpoints are only accessible from within the AWS VPC or via VPC peering from C1.

### 1. Health Check Endpoint
**URL (Internal):** `http://a11e332ddf414470781dcffadfcbff6e-02e4279cfc7d48f9.elb.us-west-2.amazonaws.com/health`

**Response:**
```json
{
  "status": "healthy",
  "cluster": "C2",
  "region": "us-west-2"
}
```

---

### 2. Application Info Endpoint
**URL (Internal):** `http://a11e332ddf414470781dcffadfcbff6e-02e4279cfc7d48f9.elb.us-west-2.amazonaws.com/info`

**Response:**
```json
{
  "cluster": "C2",
  "region": "us-west-2",
  "tier": "backend",
  "app": "demo-app",
  "version": "1.0"
}
```

---

### 3. Error Injection Endpoint
**URL (Internal):** `http://a11e332ddf414470781dcffadfcbff6e-02e4279cfc7d48f9.elb.us-west-2.amazonaws.com/error`

**Response:**
```json
{
  "error": "Internal Server Error",
  "cluster": "C2",
  "message": "Intentional error for testing"
}
```
**HTTP Status:** 500

---

### 4. Database Error Simulation
**URL (Internal):** `http://a11e332ddf414470781dcffadfcbff6e-02e4279cfc7d48f9.elb.us-west-2.amazonaws.com/db-error`

**Response:**
```json
{
  "error": "Database Connection Failed",
  "cluster": "C2",
  "message": "Simulated database outage"
}
```
**HTTP Status:** 503 Service Unavailable

**Use Case:**
- Simulate backend database failures
- Test cross-region error propagation
- Demonstrate C1 → C2 dependency monitoring

---

### 5. Random Failure Endpoint
**URL (Internal):** `http://a11e332ddf414470781dcffadfcbff6e-02e4279cfc7d48f9.elb.us-west-2.amazonaws.com/random`

**Response:** Same as C1 random endpoint but with "cluster": "C2"

---

## Testing C2 from C1 (Cross-Region)

To test C2 endpoints, you must be inside the VPC (e.g., from a pod in C1):

```bash
# Connect to C1 cluster
aws eks update-kubeconfig --region us-east-1 --name petclinic-c1

# Create a test pod
kubectl run test-pod --image=curlimages/curl:latest --rm -it --restart=Never -- sh

# Inside the pod, test C2 endpoint
curl http://a11e332ddf414470781dcffadfcbff6e-02e4279cfc7d48f9.elb.us-west-2.amazonaws.com/health
```

**Expected:** Successful response (proving VPC peering works)

---

## Automated Testing Script

### Test All C1 Endpoints

```bash
#!/bin/bash
C1_URL="http://ab565512bbcbf4cf5ac5ba54c67d8071-4607189aed878535.elb.us-east-1.amazonaws.com"

echo "Testing C1 (Frontend) Endpoints"
echo "================================"

echo -e "\n1. Health:"
curl -s $C1_URL/health | jq .

echo -e "\n2. Info:"
curl -s $C1_URL/info | jq .

echo -e "\n3. Status:"
curl -s $C1_URL/status | jq .

echo -e "\n4. Error (should be 500):"
curl -s -w "\nHTTP: %{http_code}\n" $C1_URL/error | head -3

echo -e "\n5. Random (may succeed or fail):"
curl -s $C1_URL/random | jq .

echo -e "\n6. Home:"
curl -s $C1_URL/ | head -5
```

### Load Testing for Fault Injection Demo

```bash
#!/bin/bash
# Generate load on error endpoint for Splunk demo

C1_URL="http://ab565512bbcbf4cf5ac5ba54c67d8071-4607189aed878535.elb.us-east-1.amazonaws.com"

echo "Generating error traffic for Splunk observability demo..."

for i in {1..100}; do
  curl -s $C1_URL/error > /dev/null &
  curl -s $C1_URL/random > /dev/null &
  curl -s $C1_URL/status > /dev/null &

  if [ $((i % 10)) -eq 0 ]; then
    echo "Sent $i requests..."
  fi

  sleep 0.1
done

wait
echo "Load test complete. Check Splunk for error spike."
```

---

## Logging and Observability

### Log Format

All requests are logged in JSON format for Splunk ingestion:

```json
{
  "time_local": "31/Jan/2026:00:42:15 +0000",
  "remote_addr": "203.0.113.42",
  "request": "GET /error HTTP/1.1",
  "status": "500",
  "body_bytes_sent": "94",
  "request_time": "0.001",
  "http_referrer": "-",
  "http_user_agent": "curl/7.68.0",
  "cluster": "C1",
  "region": "us-east-1",
  "app": "demo-frontend"
}
```

### Viewing Logs

**From Kubernetes:**
```bash
# C1 logs
kubectl logs -n petclinic -l app=demo-app --tail=50

# C2 logs
kubectl logs -n petclinic -l app=demo-app --tail=50
```

**From OTel Collector (enriched with K8s metadata):**
```bash
kubectl logs -n observability -l app=otel-collector --tail=100 | grep demo-app
```

---

## Security Verification

### C1 - Public Access (Expected)

```bash
# Should succeed
curl -I http://ab565512bbcbf4cf5ac5ba54c67d8071-4607189aed878535.elb.us-east-1.amazonaws.com/health

# Expected: HTTP/1.1 200 OK
```

### C2 - No Public Access (Security Requirement)

```bash
# Should fail or timeout
curl -I http://a11e332ddf414470781dcffadfcbff6e-02e4279cfc7d48f9.elb.us-west-2.amazonaws.com/health

# Expected: Connection timeout or DNS resolution failure
```

**Verification via Python Tool:**
```bash
cd /Users/kanu/Desktop/Ciroos/security-verification
python verify_security.py
```

The tool will confirm:
- ✅ C1 is internet-facing
- ✅ C2 is internal-only
- ✅ No unintended public access paths

---

## Demo Scenarios

### Scenario 1: Normal Operation
**Goal:** Show healthy application baseline

```bash
# Hit healthy endpoints multiple times
for i in {1..20}; do
  curl -s http://ab565512bbcbf4cf5ac5ba54c67d8071-4607189aed878535.elb.us-east-1.amazonaws.com/health
  sleep 1
done
```

**In Splunk:** Show stable HTTP 200 responses, normal latency

---

### Scenario 2: Error Spike
**Goal:** Demonstrate fault detection

```bash
# Generate error traffic
for i in {1..50}; do
  curl -s http://ab565512bbcbf4cf5ac5ba54c67d8071-4607189aed878535.elb.us-east-1.amazonaws.com/error > /dev/null
done
```

**In Splunk:**
- Show HTTP 500 error rate spike
- Alert firing (if configured)
- Service health degradation

---

### Scenario 3: Intermittent Failures
**Goal:** Simulate flaky service behavior

```bash
# Hit random endpoint repeatedly
for i in {1..100}; do
  STATUS=$(curl -s -w "%{http_code}" -o /dev/null http://ab565512bbcbf4cf5ac5ba54c67d8071-4607189aed878535.elb.us-east-1.amazonaws.com/random)
  echo "Request $i: HTTP $STATUS"
  sleep 0.5
done
```

**In Splunk:**
- Show ~30% error rate (503 responses)
- Demonstrate error rate trending
- Show how Ciroos would identify the pattern

---

### Scenario 4: Cross-Region Dependency
**Goal:** Show C1 → C2 communication

```bash
# From C1 pod, call C2 service
kubectl run -it --rm test-c1-to-c2 --image=curlimages/curl --restart=Never -- \
  curl -v http://a11e332ddf414470781dcffadfcbff6e-02e4279cfc7d48f9.elb.us-west-2.amazonaws.com/health
```

**In Splunk:**
- Show cross-region latency metrics
- Service dependency map (C1 → C2)
- Demonstrate private connectivity via VPC peering

---

## Metrics Available in Splunk

For each endpoint hit, Splunk Observability collects:

- **Request Count:** Total requests per endpoint
- **Error Rate:** 4xx/5xx errors percentage
- **Latency:** Request duration (p50, p95, p99)
- **Throughput:** Requests per second
- **Status Codes:** Distribution of HTTP status codes

**Filtered by:**
- Cluster (C1 vs C2)
- Region (us-east-1 vs us-west-2)
- Tier (frontend vs backend)
- Endpoint path (/health, /error, /random, etc.)

---

## Troubleshooting

### C1 Endpoint Not Responding

**Check load balancer status:**
```bash
aws elbv2 describe-load-balancers --region us-east-1 | jq '.LoadBalancers[] | select(.DNSName | contains("ab565512bbcbf"))'
```

**Check target health:**
```bash
aws elbv2 describe-target-health --target-group-arn <TARGET_GROUP_ARN> --region us-east-1
```

**Check pods:**
```bash
kubectl get pods -n petclinic -l app=demo-app
```

### C2 Accessible from Internet (Security Issue!)

**This should NOT happen.** If it does:

1. Check service annotation:
   ```bash
   kubectl get svc -n petclinic demo-app -o yaml | grep internal
   ```
   Should show: `service.beta.kubernetes.io/aws-load-balancer-internal: "true"`

2. Check load balancer scheme:
   ```bash
   aws elbv2 describe-load-balancers --region us-west-2 | jq '.LoadBalancers[] | select(.DNSName | contains("a11e332ddf414"))'
   ```
   Should show: `"Scheme": "internal"`

---

## Quick Reference

| Endpoint | C1 URL | Purpose | Expected Status |
|----------|--------|---------|-----------------|
| /health | [Link](http://ab565512bbcbf4cf5ac5ba54c67d8071-4607189aed878535.elb.us-east-1.amazonaws.com/health) | Health check | 200 |
| /info | [Link](http://ab565512bbcbf4cf5ac5ba54c67d8071-4607189aed878535.elb.us-east-1.amazonaws.com/info) | App metadata | 200 |
| /status | [Link](http://ab565512bbcbf4cf5ac5ba54c67d8071-4607189aed878535.elb.us-east-1.amazonaws.com/status) | Service status | 200 |
| /error | [Link](http://ab565512bbcbf4cf5ac5ba54c67d8071-4607189aed878535.elb.us-east-1.amazonaws.com/error) | Error injection | 500 |
| /random | [Link](http://ab565512bbcbf4cf5ac5ba54c67d8071-4607189aed878535.elb.us-east-1.amazonaws.com/random) | Random failures | 200 or 503 |
| / | [Link](http://ab565512bbcbf4cf5ac5ba54c67d8071-4607189aed878535.elb.us-east-1.amazonaws.com/) | Home page | 200 |

**Note:** Click links to test directly in browser (C1 only - C2 is not publicly accessible)

---

**Last Updated:** January 30, 2026
**Status:** All endpoints tested and operational
