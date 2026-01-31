# Observability and Log Capture Configuration

**Date:** January 30, 2026
**Project:** Ciroos AWS Multi-Region EKS Demo

---

## Log Capture Points

### 1. **Application Logs (Container stdout/stderr)**

**Location:** Container standard output
**Format:** JSON structured logs
**Captured by:** Kubernetes logging system → FluentBit/Fluentd → Splunk

**Log Format Example:**
```json
{
  "time_local": "30/Jan/2026:21:15:42 +0000",
  "remote_addr": "10.0.1.52",
  "request": "GET /error HTTP/1.1",
  "status": "500",
  "body_bytes_sent": "89",
  "request_time": "0.001",
  "http_referrer": "-",
  "http_user_agent": "curl/7.64.1",
  "cluster": "C1",
  "region": "us-east-1",
  "app": "demo-frontend"
}
```

**How to View:**
```bash
# View logs from specific pod
kubectl logs -n petclinic <pod-name>

# View logs from all pods of deployment
kubectl logs -n petclinic -l app=demo-app --tail=100

# Stream logs in real-time
kubectl logs -n petclinic -l app=demo-app -f
```

---

### 2. **Kubernetes Events**

**Location:** Kubernetes API Server
**Format:** Kubernetes Event objects
**Captured by:** Kubernetes API → Event Exporter → Splunk

**Event Types:**
- Pod scheduling events
- Container crashes/restarts
- Resource quota violations
- Health check failures
- Volume mount issues

**How to View:**
```bash
# View events in namespace
kubectl get events -n petclinic --sort-by='.lastTimestamp'

# Watch events in real-time
kubectl get events -n petclinic --watch
```

---

### 3. **Application Metrics**

**Location:** Prometheus/Kubernetes Metrics API
**Format:** Prometheus metrics format
**Captured by:** OpenTelemetry Collector → Splunk Observability

**Metrics Collected:**
- **HTTP metrics:**
  - Request rate (requests/second)
  - Error rate (5xx responses)
  - Latency (p50, p95, p99)
  - Status code distribution

- **Container metrics:**
  - CPU usage
  - Memory usage
  - Network I/O
  - Disk I/O

- **Kubernetes metrics:**
  - Pod restarts
  - Pod ready status
  - Deployment rollout status

**How to View:**
```bash
# View pod metrics
kubectl top pods -n petclinic

# View node metrics
kubectl top nodes
```

---

### 4. **Nginx Access Logs**

**Location:** `/var/log/nginx/access.log` (inside container)
**Format:** JSON (custom format defined in nginx.conf)
**Captured by:** stdout redirection → Container logs → Splunk

**Configuration:**
```nginx
log_format json_combined escape=json
'{'
  '"time_local":"$time_local",'
  '"remote_addr":"$remote_addr",'
  '"request":"$request",'
  '"status": "$status",'
  '"cluster":"C1",'
  '"region":"us-east-1"'
'}';
```

**Key Fields for Splunk:**
- `time_local`: Timestamp
- `status`: HTTP status code (200, 500, 503, etc.)
- `request_time`: Response time in seconds
- `cluster`: Which cluster served the request (C1 or C2)
- `region`: AWS region

---

### 5. **Nginx Error Logs**

**Location:** `/var/log/nginx/error.log` (inside container)
**Format:** Plain text with severity levels
**Captured by:** stderr redirection → Container logs → Splunk

**Severity Levels:**
- `error`: Application errors
- `warn`: Warnings
- `info`: Informational messages

---

## Splunk Observability Integration

### Architecture

```
┌─────────────────────┐
│   Demo App Pods     │
│   (C1 & C2)         │
│                     │
│  ┌──────────────┐   │
│  │ Nginx        │   │
│  │ - Access log │──────┐
│  │ - Error log  │──────┤
│  └──────────────┘   │  │
└─────────────────────┘  │
                         │
                         ├──> stdout/stderr
                         │
                         ▼
              ┌──────────────────┐
              │ Kubernetes       │
              │ Logging System   │
              └──────────────────┘
                         │
                         ▼
              ┌──────────────────┐
              │ OpenTelemetry    │
              │ Collector        │
              │  - Logs          │
              │  - Metrics       │
              │  - Traces        │
              └──────────────────┘
                         │
                         │ OTLP Protocol
                         ▼
              ┌──────────────────┐
              │ Splunk O11y      │
              │ Cloud            │
              │                  │
              │ - Log Observer   │
              │ - APM            │
              │ - Infrastructure │
              │ - Dashboards     │
              │ - Alerts         │
              └──────────────────┘
```

---

## OpenTelemetry Collector Configuration

### Deployment Location
- **C1 Cluster:** DaemonSet on all nodes
- **C2 Cluster:** DaemonSet on all nodes

### Configuration
```yaml
receivers:
  # Collect Kubernetes logs
  filelog:
    include:
      - /var/log/pods/*/*/*.log
    include_file_path: true
    include_file_name: false
    operators:
      - type: json_parser
        parse_from: body

  # Collect Kubernetes metrics
  kubeletstats:
    collection_interval: 30s
    auth_type: serviceAccount
    endpoint: "https://${K8S_NODE_NAME}:10250"

processors:
  # Add cluster and region attributes
  resource:
    attributes:
      - key: cluster
        value: C1  # or C2
        action: upsert
      - key: region
        value: us-east-1  # or us-west-2
        action: upsert

  # Batch logs for efficiency
  batch:
    timeout: 10s
    send_batch_size: 1024

exporters:
  # Send to Splunk Observability Cloud
  splunk_hec:
    endpoint: "https://ingest.us1.signalfx.com/v1/log"
    token: "${SPLUNK_INGEST_TOKEN}"

  signalfx:
    access_token: "${SPLUNK_ACCESS_TOKEN}"
    realm: "us1"
```

---

## Fault Injection and Error Detection

### Available Error Endpoints

#### 1. `/error` - Guaranteed Error
**HTTP 500 - Internal Server Error**
```bash
curl http://<LOAD_BALANCER>/error
```
**Splunk Detection:**
- Status code: 500
- Error count spike
- Alert: "HTTP 5xx error rate > 5%"

---

#### 2. `/random` - Random Failures (30%)
**HTTP 503 - Service Unavailable (30% of requests)**
```bash
for i in {1..10}; do curl http://<LOAD_BALANCER>/random; done
```
**Splunk Detection:**
- Intermittent 503 errors
- Error rate ~30%
- Alert: "Service degradation detected"

---

#### 3. Pod Deletion - Container Crash
```bash
kubectl delete pod -n petclinic -l app=demo-app --force
```
**Splunk Detection:**
- Pod restart event
- Container exit code
- Temporary service unavailability
- Alert: "Pod crash detected - C1 demo-app"

---

#### 4. `/slow` - Latency Injection
**3-second delay before response**
```bash
curl http://<LOAD_BALANCER>/slow
```
**Splunk Detection:**
- Request time: 3000ms
- Latency spike in metrics
- Alert: "p95 latency > 1s"

---

#### 5. `/db-error` - Database Simulation (C2 only)
**HTTP 503 - Database Connection Failed**
```bash
curl http://<C2_LOAD_BALANCER>/db-error
```
**Splunk Detection:**
- Service unavailable errors
- Database-specific error message
- Alert: "Backend service errors detected"

---

## Splunk Dashboard Queries

### 1. Error Rate by Cluster
```spl
source="kubernetes" status>=500
| timechart span=1m count by cluster
```

### 2. Request Latency (p95)
```spl
source="kubernetes" request_time=*
| timechart span=1m perc95(request_time) by cluster
```

### 3. Pod Restart Events
```spl
source="kubernetes:events" reason="BackOff" OR reason="CrashLoopBackOff"
| stats count by namespace, pod, reason
```

### 4. Status Code Distribution
```spl
source="kubernetes" status=*
| stats count by status, cluster
| sort -count
```

### 5. Cross-Region Traffic Analysis
```spl
source="kubernetes"
| stats count, avg(request_time) by cluster, region
```

---

## Alert Configuration

### Critical Alerts

**1. High Error Rate**
- Condition: `HTTP 5xx errors > 5% over 5 minutes`
- Severity: Critical
- Action: PagerDuty notification

**2. Pod Crash Loop**
- Condition: `Pod restart count > 3 in 10 minutes`
- Severity: Critical
- Action: Slack alert + email

**3. Service Unavailable**
- Condition: `No successful requests for 2 minutes`
- Severity: Critical
- Action: Immediate escalation

### Warning Alerts

**4. Elevated Latency**
- Condition: `p95 latency > 1 second for 5 minutes`
- Severity: Warning
- Action: Slack notification

**5. Increased Restart Rate**
- Condition: `Pod restarts > 1 in 30 minutes`
- Severity: Warning
- Action: Email notification

---

## How to Generate Test Data for Splunk

### Script: Generate Traffic and Errors
```bash
#!/bin/bash
# generate-traffic.sh

C1_LB="<C1_LOAD_BALANCER_URL>"
C2_LB="<C2_LOAD_BALANCER_URL>"

echo "Generating normal traffic..."
for i in {1..100}; do
    curl -s $C1_LB/ > /dev/null &
    curl -s $C2_LB/ > /dev/null &
done

echo "Generating errors..."
for i in {1..20}; do
    curl -s $C1_LB/error > /dev/null &
    curl -s $C2_LB/error > /dev/null &
done

echo "Generating random failures..."
for i in {1..50}; do
    curl -s $C1_LB/random > /dev/null &
    curl -s $C2_LB/random > /dev/null &
done

echo "Traffic generation complete. Check Splunk in 30 seconds."
wait
```

---

## Verification Commands

### Check Logs are Being Generated
```bash
# C1 cluster
kubectl logs -n petclinic -l app=demo-app --tail=20

# C2 cluster
kubectl config use-context <C2_CONTEXT>
kubectl logs -n petclinic -l app=demo-app --tail=20
```

### Verify JSON Log Format
```bash
kubectl logs -n petclinic -l app=demo-app --tail=1 | jq .
```

### Test All Error Endpoints
```bash
LB_URL="<LOAD_BALANCER_URL>"

echo "Testing /health (should return 200)"
curl -v $LB_URL/health

echo "Testing /error (should return 500)"
curl -v $LB_URL/error

echo "Testing /random (30% should fail)"
curl -v $LB_URL/random

echo "Testing /info (cluster metadata)"
curl $LB_URL/info | jq .
```

---

## Summary

**Log Capture Points:**
1. ✅ Container logs (stdout/stderr) → JSON formatted
2. ✅ Nginx access logs → JSON with custom fields
3. ✅ Nginx error logs → stderr
4. ✅ Kubernetes events → API server
5. ✅ Application metrics → Prometheus format

**Splunk Integration:**
- OpenTelemetry Collector as DaemonSet
- Real-time log ingestion
- Metrics collection
- Custom dashboards
- Alert configuration

**Error Injection:**
- `/error` - Guaranteed failures
- `/random` - Intermittent issues
- Pod deletion - Container crashes
- `/slow` - Latency spikes
- `/db-error` - Backend failures

All logs are structured in JSON format with cluster and region labels for easy filtering and analysis in Splunk Observability Cloud.
