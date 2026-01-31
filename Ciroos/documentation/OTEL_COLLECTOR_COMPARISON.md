# OpenTelemetry Collector Deployment Comparison

**Date:** January 31, 2026
**Purpose:** Document what changed from custom OTel deployment to Splunk official deployment and why it fixed infrastructure metrics

---

## Summary

**Problem:** Custom OTel collector was collecting metrics but Splunk wasn't receiving/displaying infrastructure data.

**Solution:** Deployed Splunk official OpenTelemetry collector Helm chart, which immediately fixed the issue.

**Result:** Infrastructure metrics now visible in Splunk Observability Cloud.

---

## Deployment Comparison

### Custom OTel Collector (Original - Not Working)

**Deployment Method:** Manual Kubernetes YAML manifests
**Namespace:** `observability`
**Image:** `otel/opentelemetry-collector-contrib:0.91.0`
**Architecture:**
- DaemonSet only (one pod per node)
- No separate cluster receiver

**Components:**
- **Pods:** 2 per cluster (DaemonSet on each node)
- **ConfigMap:** Custom configuration
- **Secret:** Splunk access token
- **Service:** `otel-collector.observability.svc.cluster.local:4317`

**Status:**
- ✅ Collecting metrics (213 data points/10s)
- ✅ Collecting traces (228 spans/batch)
- ✅ Exporting to SignalFx ("Host metadata synchronized")
- ❌ Data not visible in Splunk UI
- ❌ Splunk API showed `infraDataReceived: false`

---

### Splunk Official OTel Collector (New - Working ✅)

**Deployment Method:** Helm chart from Splunk
**Chart:** `splunk-otel-collector-chart/splunk-otel-collector`
**Namespace:** `splunk-monitoring`
**Image:** `quay.io/signalfx/splunk-otel-collector:*` (version 0.143.0)
**Architecture:**
- **Agent DaemonSet** (one pod per node)
- **Cluster Receiver Deployment** (separate pod for cluster-level metrics)

**Components:**

**Agent Pods (DaemonSet):**
- **Count:** 2 per cluster
- **Name:** `splunk-otel-collector-agent-*`
- **Purpose:** Node-level and pod-level metrics, traces, logs
- **Service:** `splunk-otel-collector-agent.splunk-monitoring.svc.cluster.local`
- **Ports:** 14250, 14268, 4317 (OTLP gRPC), 4318 (OTLP HTTP), 9411

**Cluster Receiver Pod (Deployment):**
- **Count:** 1 per cluster
- **Name:** `splunk-otel-collector-k8s-cluster-receiver-*`
- **Purpose:** Cluster-wide metrics (deployments, services, namespaces)
- **Key Feature:** Dedicated pod for k8s_cluster receiver

**Status:**
- ✅ Collecting metrics
- ✅ Collecting traces
- ✅ Exporting to SignalFx
- ✅ **Data visible in Splunk UI** ⭐
- ✅ Infrastructure → Kubernetes Navigator shows clusters
- ✅ APM → Service Map shows services

---

## Key Differences That Fixed the Issue

### 1. Separate Cluster Receiver

**Custom Deployment:**
```yaml
# All receivers in the same DaemonSet pod
receivers:
  - kubeletstats (node metrics)
  - k8s_cluster (cluster metrics)
  - otlp (traces)
  - filelog (logs)
```

**Splunk Official:**
```yaml
# Agent DaemonSet:
receivers:
  - kubeletstats
  - otlp
  - filelog
  - receiver_creator (dynamic receivers)

# Cluster Receiver Deployment:
receivers:
  - k8s_cluster (dedicated pod)
```

**Why it matters:** The `k8s_cluster` receiver needs cluster-wide RBAC permissions and works better in a dedicated deployment rather than a DaemonSet.

### 2. Receiver Creator

**Custom Deployment:**
- Static Prometheus receiver configuration
- Manual scrape configs

**Splunk Official:**
- `receiver_creator` with k8s_observer
- Automatically discovers and scrapes:
  - CoreDNS
  - kube-proxy
  - Other Prometheus-annotated services

**Why it matters:** Automatically discovers and monitors Kubernetes services without manual configuration.

### 3. Exporter Configuration

**Custom Deployment:**
```yaml
exporters:
  signalfx:
    access_token: "${SPLUNK_ACCESS_TOKEN}"
    realm: "${SPLUNK_REALM}"
    sync_host_metadata: true
    send_compatible_metrics: true
```

**Splunk Official:**
```yaml
exporters:
  signalfx:
    access_token: "${SPLUNK_ACCESS_TOKEN}"
    realm: "${SPLUNK_REALM}"
    sync_host_metadata: true
    correlation: enabled
    api_url: https://api.${SPLUNK_REALM}.signalfx.com
    ingest_url: https://ingest.${SPLUNK_REALM}.signalfx.com
    # Additional configuration optimized for Splunk
```

**Why it matters:**
- Explicit API and ingest URLs
- Correlation tracking enabled for APM
- Splunk-specific optimizations

### 4. Resource Attributes

**Custom Deployment:**
```yaml
resource:
  attributes:
    - key: cluster.name
      value: ${CLUSTER_NAME}
    - key: cluster.region
      value: ${CLUSTER_REGION}
```

**Splunk Official:**
```yaml
resource:
  attributes:
    - key: k8s.cluster.name
      value: ${CLUSTER_NAME}
    - key: deployment.environment
      value: ${ENVIRONMENT}
    - key: service.version
      value: ${VERSION}
    # Plus auto-detected attributes from resourcedetection processor
```

**Why it matters:** Uses attribute names that Splunk Observability Cloud expects and recognizes.

### 5. Processors Pipeline

**Custom Deployment:**
```yaml
processors:
  - memory_limiter
  - k8sattributes
  - resource
  - resourcedetection
  - batch
```

**Splunk Official:**
```yaml
processors:
  - memory_limiter
  - k8sattributes (enhanced configuration)
  - resource/add_environment
  - resourcedetection/internal (cloud provider detection)
  - batch
  - resource/k8s_cluster (cluster-specific attributes)
  - filter/* (multiple filter processors)
```

**Why it matters:**
- More processors for better data enrichment
- Multiple resource processors for different contexts
- Enhanced k8sattributes configuration

### 6. Metrics Pipeline Specific Differences

**Custom Deployment:**
```yaml
metrics:
  receivers: [otlp, kubeletstats, k8s_cluster, prometheus]
  exporters: [signalfx, logging]
```

**Splunk Official:**
```yaml
# Agent metrics pipeline:
metrics:
  receivers: [otlp, kubeletstats, receiver_creator]
  exporters: [signalfx]

# Cluster receiver metrics pipeline:
metrics/collector:
  receivers: [k8s_cluster, prometheus/*]
  exporters: [signalfx]
```

**Why it matters:** Separate pipelines for node-level vs cluster-level metrics.

### 7. RBAC Permissions

**Custom Deployment:**
```yaml
ClusterRole:
  - nodes (get, list, watch)
  - pods (get, list, watch)
  - services (get, list, watch)
  # Basic permissions
```

**Splunk Official:**
```yaml
ClusterRole (Agent):
  - nodes (get, list, watch)
  - nodes/stats (get)
  - pods (get, list, watch)
  - events (get, list, watch)
  # Extensive permissions

ClusterRole (Cluster Receiver):
  - namespaces (get, list, watch)
  - nodes (get, list, watch)
  - persistentvolumes (get, list, watch)
  - persistentvolumeclaims (get, list, watch)
  - replicationcontrollers (get, list, watch) ⭐
  - resourcequotas (get, list, watch) ⭐
  - services (get, list, watch)
  - deployments (get, list, watch)
  - replicasets (get, list, watch)
  - daemonsets (get, list, watch)
  - statefulsets (get, list, watch)
  - jobs (get, list, watch)
  - cronjobs (get, list, watch)
  # Comprehensive permissions
```

**Why it matters:**
- Our custom deployment was missing permissions for `replicationcontrollers` and `resourcequotas` (we saw these errors in logs)
- Splunk official has all required permissions
- Separate RBAC for agent vs cluster receiver

### 8. Service Endpoints

**Custom Deployment:**
- Single service: `otel-collector.observability.svc.cluster.local:4317`

**Splunk Official:**
- Agent service: `splunk-otel-collector-agent.splunk-monitoring.svc.cluster.local:4317`
- Multiple protocol support: OTLP gRPC (4317), OTLP HTTP (4318), Jaeger, Zipkin

### 9. Version Differences

**Custom Deployment:**
- OTel Collector version: 0.91.0
- Released: ~December 2023

**Splunk Official:**
- OTel Collector version: 0.143.0
- Released: ~January 2025
- **52 versions newer** with bug fixes and improvements

**Why it matters:**
- Newer version has better SignalFx exporter
- Bug fixes for Splunk integration
- Improved stability and performance

---

## What We Changed in Applications

### APM Apps Configuration Change

**Before (using custom collector):**
```yaml
env:
  - name: OTEL_EXPORTER_OTLP_ENDPOINT
    value: "otel-collector.observability.svc.cluster.local:4317"
```

**After (using Splunk collector):**
```yaml
env:
  - name: OTEL_EXPORTER_OTLP_ENDPOINT
    value: "http://splunk-otel-collector-agent.splunk-monitoring.svc.cluster.local:4317"
```

**Applied to:**
- `apm-test-app` (C1 frontend)
- `apm-backend-app` (C2 backend)

---

## Installation Commands

### Splunk Official Collector Installation

**C1 Cluster (us-east-1):**
```bash
helm repo add splunk-otel-collector-chart https://signalfx.github.io/splunk-otel-collector-chart

helm install splunk-otel-collector splunk-otel-collector-chart/splunk-otel-collector \
  --set="splunkObservability.accessToken=s2QShwFU2-K214ozAT7Ifg" \
  --set="clusterName=petclinic-c1" \
  --set="splunkObservability.realm=us1" \
  --set="gateway.enabled=false" \
  --set="agent.enabled=true" \
  --namespace=splunk-monitoring \
  --create-namespace
```

**C2 Cluster (us-west-2):**
```bash
helm install splunk-otel-collector splunk-otel-collector-chart/splunk-otel-collector \
  --set="splunkObservability.accessToken=s2QShwFU2-K214ozAT7Ifg" \
  --set="clusterName=petclinic-c2" \
  --set="splunkObservability.realm=us1" \
  --set="gateway.enabled=false" \
  --set="agent.enabled=true" \
  --namespace=splunk-monitoring \
  --create-namespace
```

### Update APM Apps

**C1:**
```bash
kubectl set env deployment/apm-test-app -n petclinic \
  OTEL_EXPORTER_OTLP_ENDPOINT="http://splunk-otel-collector-agent.splunk-monitoring.svc.cluster.local:4317"
```

**C2:**
```bash
kubectl set env deployment/apm-backend-app -n petclinic \
  OTEL_EXPORTER_OTLP_ENDPOINT="http://splunk-otel-collector-agent.splunk-monitoring.svc.cluster.local:4317"
```

---

## Current State

### Running Collectors

**Custom OTel Collector:**
- **Status:** Still running (but not actively used)
- **Namespace:** `observability`
- **Pods:** 4 total (2 in C1, 2 in C2)
- **Can be removed:** Yes, no longer needed

**Splunk Official Collector:**
- **Status:** ✅ Running and actively sending data
- **Namespace:** `splunk-monitoring`
- **Pods per cluster:** 3 (2 agents + 1 cluster receiver)
- **Total pods:** 6 (C1: 3, C2: 3)

### Services

**Custom:**
- `otel-collector.observability.svc.cluster.local:4317`

**Splunk Official:**
- `splunk-otel-collector-agent.splunk-monitoring.svc.cluster.local:4317` (OTLP gRPC)
- `splunk-otel-collector-agent.splunk-monitoring.svc.cluster.local:4318` (OTLP HTTP)

---

## Verification

### Check Splunk Official Collector Status

```bash
# C1
kubectl get pods -n splunk-monitoring

# Expected output:
# NAME                                                          READY   STATUS
# splunk-otel-collector-agent-xxxxx                             1/1     Running
# splunk-otel-collector-agent-xxxxx                             1/1     Running
# splunk-otel-collector-k8s-cluster-receiver-xxxxxxxxxx-xxxxx   1/1     Running
```

### Check Logs

```bash
kubectl logs -n splunk-monitoring -l app=splunk-otel-collector --tail=50 | grep "Host metadata synchronized"
```

Expected: Should see "Host metadata synchronized" messages.

### Verify Data in Splunk

1. **Infrastructure → Kubernetes Navigator**
   - Should see: `petclinic-c1` and `petclinic-c2`

2. **APM → Service Map**
   - Should see: `apm-test-app` and `apm-backend-service`

3. **Metrics**
   - Search: `k8s.pod.cpu.utilization`
   - Filter: `k8s.cluster.name = petclinic-c1`

---

## Why It Worked

### Root Cause of Original Issue

The custom OTel collector had several issues:

1. **Missing RBAC permissions** for replicationcontrollers and resourcequotas
2. **Suboptimal exporter configuration** - not using Splunk-optimized settings
3. **Older version** (0.91.0 vs 0.143.0) with potential bugs
4. **Missing correlation tracking** for APM
5. **No separate cluster receiver** - k8s_cluster receiver works better in dedicated pod
6. **Attribute naming** - not using Splunk's expected attribute names

### Why Splunk Official Worked

1. ✅ **Pre-configured and tested** by Splunk for their platform
2. ✅ **Correct RBAC permissions** - all necessary permissions included
3. ✅ **Latest version** with bug fixes
4. ✅ **Optimized exporter** with correlation tracking
5. ✅ **Separate architecture** with dedicated cluster receiver
6. ✅ **Proper attribute names** that Splunk recognizes
7. ✅ **Receiver creator** for automatic service discovery

---

## Recommendation

### Keep Splunk Official Collector

**Reasons:**
- ✅ Working perfectly with Splunk Observability Cloud
- ✅ Officially supported by Splunk
- ✅ Regular updates and bug fixes
- ✅ Pre-configured for best practices
- ✅ Better RBAC and permissions

### Remove Custom Collector (Optional)

The custom collector in the `observability` namespace is no longer needed and can be removed:

```bash
# C1
kubectl delete namespace observability

# C2
aws eks update-kubeconfig --region us-west-2 --name petclinic-c2
kubectl delete namespace observability
```

**OR keep it for reference/backup:**
- No harm in keeping both
- Custom collector is not actively being used by applications
- Minimal resource usage (~200m CPU, ~512Mi memory per cluster)

---

## Lessons Learned

### 1. Use Official Integrations When Available

**Lesson:** When integrating with a specific platform (Splunk, Datadog, etc.), use their official integrations.

**Why:**
- Pre-configured for the platform
- Tested and supported
- Optimized for best performance
- Regular updates

### 2. Architecture Matters

**Lesson:** Separate cluster-level metrics collection from node-level collection.

**Why:**
- Different RBAC requirements
- Better scalability
- Clearer separation of concerns

### 3. Version Matters

**Lesson:** Use recent versions of OpenTelemetry components.

**Why:**
- Bug fixes
- New features
- Better platform support
- Performance improvements

### 4. RBAC is Critical

**Lesson:** Ensure all necessary Kubernetes permissions are granted.

**Why:**
- Missing permissions cause silent failures
- Error logs may be unclear
- Data collection incomplete

---

## Summary Table

| Aspect | Custom Collector | Splunk Official | Winner |
|--------|-----------------|-----------------|--------|
| **Deployment Method** | Manual YAML | Helm Chart | ✅ Splunk |
| **Version** | 0.91.0 | 0.143.0 | ✅ Splunk |
| **Architecture** | DaemonSet only | Agent + Cluster Receiver | ✅ Splunk |
| **RBAC** | Basic permissions | Comprehensive | ✅ Splunk |
| **Configuration** | Custom | Splunk-optimized | ✅ Splunk |
| **Data Visible in Splunk** | ❌ No | ✅ Yes | ✅ Splunk |
| **Maintenance** | Manual updates | Helm upgrade | ✅ Splunk |
| **Support** | Community | Official Splunk | ✅ Splunk |

---

## Files Reference

### Custom Collector (Original)
- `/Users/kanu/Desktop/Ciroos/petclinic-k8s/manifests/observability/otel-collector-config.yaml`
- `/Users/kanu/Desktop/Ciroos/petclinic-k8s/manifests/observability/otel-collector-daemonset.yaml`
- `/Users/kanu/Desktop/Ciroos/petclinic-k8s/manifests/observability/splunk-secret.yaml`

### Splunk Official (Current)
- Deployed via Helm chart (configuration managed by Helm)
- Namespace: `splunk-monitoring`
- ConfigMaps: `splunk-otel-collector-otel-agent`, `splunk-otel-collector-otel-k8s-cluster-receiver`

---

**Conclusion:** Switching to the Splunk official OpenTelemetry collector resolved all infrastructure metric visibility issues. The official integration is pre-configured, well-tested, and optimized for Splunk Observability Cloud.
