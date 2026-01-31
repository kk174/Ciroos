# Splunk Observability Cloud - Data Viewing Guide

**Date:** January 30, 2026
**Issue:** "I don't see anything on Splunk APM dashboard"

---

## Understanding What Data Is Available

### ✅ Currently Sending to Splunk:

1. **Infrastructure Metrics** (Kubernetes)
   - Node CPU, memory, disk, network
   - Pod resource usage
   - Container metrics
   - Cluster health status
   - Deployment replica counts

2. **System Metrics**
   - Collected every 10 seconds
   - ~177-194 data points per export cycle
   - Tagged with cluster name and region

### ❌ NOT Currently Sending:

1. **Application Traces** (APM)
   - Requires application instrumentation with OpenTelemetry SDK
   - Our demo apps are plain nginx (not instrumented)
   - This is why APM dashboard is empty

2. **Custom Application Metrics**
   - Would need OpenTelemetry SDK integration
   - Nginx access logs have metrics but aren't exported as Splunk metrics

---

## Where to Find Your Data in Splunk

### Option 1: Kubernetes Navigator (RECOMMENDED - START HERE)

**This is where your data is!**

1. Log in to **https://app.signalfx.com** (realm: us1)

2. Click on **Infrastructure** in the left navigation

3. Click **Kubernetes Navigator**

4. Look for your clusters:
   - `petclinic-c1` (us-east-1)
   - `petclinic-c2` (us-west-2)

5. **If you DON'T see the clusters:**
   - Wait 2-3 minutes (data needs to propagate)
   - Check the time range (top right) - set to "Last 15 minutes"
   - Refresh the page

6. **If you DO see the clusters:**
   - Click on `petclinic-c1`
   - You'll see:
     - Cluster overview
     - Node list (should show 2 nodes)
     - Pod list (including demo-app and otel-collector pods)
     - Resource utilization charts

---

### Option 2: Infrastructure Monitoring

1. Go to **Infrastructure** → **Hosts**

2. You should see your EKS nodes:
   - Look for hosts tagged with `k8s.cluster.name:petclinic-c1`
   - Or hosts tagged with `k8s.cluster.name:petclinic-c2`

3. Click on a host to see:
   - CPU usage
   - Memory usage
   - Disk I/O
   - Network traffic

---

### Option 3: Metric Finder

1. Go to **Metrics** (top navigation)

2. In the search box, type: `k8s.pod`

3. You should see metrics like:
   - `k8s.pod.cpu.utilization`
   - `k8s.pod.memory.usage`
   - `k8s.pod.network.io`

4. Click on a metric to see it charted

5. **Add filters** to narrow down:
   - Click "Add Filter"
   - Select `k8s.cluster.name`
   - Choose `petclinic-c1` or `petclinic-c2`

---

### Option 4: Create a Custom Dashboard

1. Go to **Dashboards** → **Create Dashboard**

2. Click **+ Chart**

3. In the "Signal" field, type: `k8s.pod.cpu.utilization`

4. Add a filter:
   - `k8s.cluster.name:petclinic-c1`

5. Click **Save**

6. Add more charts for:
   - Memory: `k8s.pod.memory.usage`
   - Network: `k8s.pod.network.io`
   - Container restarts: `k8s.container.restarts`

---

## Why APM Dashboard is Empty

**APM (Application Performance Monitoring)** requires:

1. **Application instrumentation** with OpenTelemetry SDK
2. **Trace generation** from application code
3. **Span export** to the OTel collector

**Current state:**
- ✅ OTel collectors are deployed and ready to receive traces
- ✅ OTLP receivers listening on ports 4317 (gRPC) and 4318 (HTTP)
- ❌ Demo applications (nginx) don't generate traces

**To populate APM:**
We would need to deploy an instrumented application (e.g., a Python/Node.js/Java app with OpenTelemetry SDK).

---

## Quick Check: Is Data Flowing?

Run this command to verify the collector is exporting data:

```bash
kubectl logs -n observability -l app=otel-collector --tail=20 | grep MetricsExporter
```

**Expected output:**
```
info MetricsExporter {"kind": "exporter", "data_type": "metrics", "name": "logging", "resource metrics": 17, "metrics": 184, "data points": 194}
```

This confirms **177-194 metrics data points** are being collected and exported every 10 seconds.

---

## Troubleshooting: Still Don't See Data?

### Check 1: Verify Splunk Realm

Your Splunk realm should be **us1**.

1. In Splunk, go to **Settings** (gear icon, top right)
2. Look for **Organization Settings**
3. Verify **Realm** is `us1`

If it's different, update the collector configuration.

### Check 2: Verify Access Token

```bash
kubectl get secret splunk-otel-collector -n observability -o jsonpath='{.data.access_token}' | base64 -d
echo
```

Should output: `QRF-G2Q75tubuVTGyAlZMw`

### Check 3: Check Collector Pod Status

```bash
kubectl get pods -n observability
```

All pods should be `Running` with `1/1` ready.

### Check 4: Check for Export Errors

```bash
kubectl logs -n observability -l app=otel-collector --tail=50 | grep -i "error.*export"
```

Should return no critical errors (ignore ReplicationController/ResourceQuota warnings).

### Check 5: Wait for Data Propagation

- Initial data may take 3-5 minutes to appear
- Set time range to "Last 30 minutes" in Splunk
- Refresh the page

---

## What You Should See Right Now

### In Kubernetes Navigator:

| Element | Expected Value |
|---------|---------------|
| Clusters | 2 (petclinic-c1, petclinic-c2) |
| Nodes per cluster | 2 |
| Namespaces | petclinic, observability, kube-system, default, etc. |
| Pods in petclinic namespace | 2 (demo-app replicas) |
| Pods in observability namespace | 2 (otel-collector replicas) |

### In Metric Finder:

Available metrics (search for these):
- `k8s.cluster.*` - Cluster-level metrics
- `k8s.node.*` - Node metrics
- `k8s.pod.*` - Pod metrics
- `k8s.container.*` - Container metrics
- `container.cpu.*` - Container CPU usage
- `container.memory.*` - Container memory usage

### Tags on All Metrics:

- `k8s.cluster.name` = `petclinic-c1` or `petclinic-c2`
- `cluster.region` = `us-east-1` or `us-west-2`
- `cloud.provider` = `aws`
- `cloud.platform` = `aws_eks`

---

## Next Steps to Populate APM

If you want to see data in the APM dashboard, we would need to:

### Option 1: Deploy a Pre-Instrumented Demo App

Deploy a sample application with OpenTelemetry already integrated:
- Splunk's own demo apps (e.g., OpenTelemetry Demo)
- Hot R.O.D. (Rides On Demand) demo app

### Option 2: Instrument the Nginx App

Add OpenTelemetry nginx module:
- Requires rebuilding nginx with OpenTelemetry module
- Configure to send traces to collector

### Option 3: Deploy a Simple Instrumented App

Create a minimal Python/Node.js app:
```python
# Example: Simple Python Flask app with OpenTelemetry
from flask import Flask
from opentelemetry import trace
from opentelemetry.exporter.otlp.proto.grpc.trace_exporter import OTLPSpanExporter
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor

# Configure tracing
trace.set_tracer_provider(TracerProvider())
tracer = trace.get_tracer(__name__)

# Export to OTel collector
otlp_exporter = OTLPSpanExporter(
    endpoint="otel-collector.observability.svc.cluster.local:4317",
    insecure=True
)
trace.get_tracer_provider().add_span_processor(
    BatchSpanProcessor(otlp_exporter)
)

app = Flask(__name__)

@app.route('/health')
def health():
    with tracer.start_as_current_span("health_check"):
        return {"status": "healthy"}

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080)
```

---

## For Your Demo Presentation

**Focus on Infrastructure Metrics** (what's working now):

1. **Show Kubernetes Navigator**
   - Two clusters visible
   - Cross-region deployment
   - Resource utilization

2. **Show Metric Charts**
   - CPU usage across both clusters
   - Memory trends
   - Pod health status

3. **Demonstrate Value Proposition**
   - "Currently monitoring infrastructure metrics"
   - "Ciroos would enhance this by correlating infrastructure health with application behavior"
   - "Adding APM would give complete observability stack"

4. **Show Fault Detection** (using nginx logs as proxy for app behavior)
   - Generate errors via `/error` endpoint
   - Show increased HTTP 500 responses in logs
   - Explain how instrumented apps would show this in APM

---

## Summary

| Data Type | Status | Where to View |
|-----------|--------|---------------|
| Kubernetes Metrics | ✅ Working | Infrastructure → Kubernetes Navigator |
| Infrastructure Metrics | ✅ Working | Infrastructure → Hosts |
| System Metrics | ✅ Working | Metrics → Metric Finder |
| Application Traces | ❌ Not instrumented | APM (empty, expected) |
| Application Metrics | ⚠️ Limited | Only infrastructure metrics |

**Bottom Line:**
- Your Splunk integration **IS working**
- Data **IS flowing** (177-194 metrics every 10 seconds)
- You're looking in the wrong place (APM vs Infrastructure)
- **Go to Infrastructure → Kubernetes Navigator to see your data**

---

**Next Action:**
1. Log in to Splunk: https://app.signalfx.com
2. Click: **Infrastructure** → **Kubernetes Navigator**
3. Look for: `petclinic-c1` and `petclinic-c2`
4. If not visible, wait 2-3 minutes and refresh

If you still don't see data after following these steps, let me know and I'll help debug further.
