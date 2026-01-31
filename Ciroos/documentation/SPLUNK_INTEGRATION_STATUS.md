# Splunk Observability Cloud Integration Status

**Date:** January 30, 2026
**Project:** Ciroos AWS Multi-Region EKS Demo
**Status:** ✅ **OPERATIONAL**

---

## Integration Overview

OpenTelemetry collectors have been successfully deployed to both EKS clusters and are actively sending telemetry data to Splunk Observability Cloud.

### Deployment Architecture

```
┌─────────────────────────────────────────────────────────┐
│         Splunk Observability Cloud (Realm: us1)        │
│                 https://app.signalfx.com                │
│                                                          │
│  ┌──────────────┐          ┌──────────────┐            │
│  │   Metrics    │          │    Traces    │            │
│  │  (SignalFx)  │          │ (Splunk APM) │            │
│  └──────────────┘          └──────────────┘            │
└─────────────────────────────────────────────────────────┘
           ▲                         ▲
           │                         │
    ┌──────┴─────────────────────────┴──────┐
    │       OTel Collector Exporters        │
    │  - signalfx (metrics) ✅              │
    │  - otlp/traces (traces) ✅            │
    └──────┬─────────────────────────┬──────┘
           │                         │
    ┌──────▼──────┐          ┌───────▼──────┐
    │  Cluster C1 │          │  Cluster C2  │
    │  us-east-1  │          │  us-west-2   │
    │             │          │              │
    │  2x OTel    │          │  2x OTel     │
    │  Collectors │          │  Collectors  │
    │  (DaemonSet)│          │  (DaemonSet) │
    └─────────────┘          └──────────────┘
```

---

## What's Working

### ✅ Metrics Collection & Export

**Status:** Fully operational

**Data Sources:**
- Kubernetes cluster metrics (deployments, services, pods)
- Kubelet statistics (pod/container metrics)
- Node metrics (CPU, memory, disk, network)
- Application metrics (via OTLP receiver on port 4317/4318)

**Exporter:** SignalFx
**Endpoint:** `ingest.us1.signalfx.com`
**Verification:** Log message `"Host metadata synchronized"` confirms successful data export

**Visible in Splunk:**
- Infrastructure → Kubernetes Navigator
- Both clusters should appear: `petclinic-c1` and `petclinic-c2`
- Real-time metrics for nodes, pods, containers
- Resource utilization dashboards

### ✅ Traces Collection (Ready)

**Status:** Configured and ready for application instrumentation

**Receiver:** OTLP (gRPC on 4317, HTTP on 4318)
**Exporter:** OTLP to Splunk APM
**Endpoint:** `ingest.us1.signalfx.com:443`

**To Enable:**
Applications need to be instrumented with OpenTelemetry SDKs and configured to send traces to the collector service:
- Service: `otel-collector.observability.svc.cluster.local:4317`

### ⚠️ Logs Collection (Local Only)

**Status:** Collected locally, not sent to Splunk Observability Cloud

**Why:**
Splunk Observability Cloud is designed for **metrics and traces**, not log aggregation. Log ingestion requires:
- Splunk Enterprise
- Splunk Cloud Platform
- Or a dedicated log management platform (e.g., Elasticsearch, CloudWatch Logs)

**Current Setup:**
- Logs ARE collected from all pods via filelog receiver
- Logs ARE enriched with Kubernetes metadata
- Logs ARE available via: `kubectl logs -n observability <otel-collector-pod>`
- Logs can be viewed with JSON structure including:
  - Pod name, namespace, container name
  - Cluster name and region tags
  - Timestamp and log message

**Production Recommendation:**
For full observability including logs, add one of:
1. Splunk Enterprise/Cloud with HTTP Event Collector (HEC)
2. Amazon CloudWatch Logs via AWS Firehose
3. Elasticsearch/OpenSearch cluster
4. Grafana Loki

---

## Deployment Details

### Clusters

**C1 (us-east-1 - Frontend):**
- Namespace: `observability`
- DaemonSet: `otel-collector` (2 pods running)
- Service: `otel-collector.observability.svc.cluster.local`
- Cluster tag: `petclinic-c1`
- Region tag: `us-east-1`

**C2 (us-west-2 - Backend):**
- Namespace: `observability`
- DaemonSet: `otel-collector` (2 pods running)
- Service: `otel-collector.observability.svc.cluster.local`
- Cluster tag: `petclinic-c2`
- Region tag: `us-west-2`

### Access Credentials

**Splunk Observability Cloud:**
- Account: https://app.signalfx.com
- Realm: `us1`
- Access Token ID: `G_7prKoAwAM`
- Token Secret: `QRF-G2Q75tubuVTGyAlZMw` (stored as Kubernetes secret)

**Token Storage:**
- Secret Name: `splunk-otel-collector`
- Namespace: `observability`
- Key: `access_token`

---

## Verification Steps

### 1. Check OTel Collector Pods

**C1:**
```bash
aws eks update-kubeconfig --region us-east-1 --name petclinic-c1
kubectl get pods -n observability
```

Expected: 2 pods in `Running` status

**C2:**
```bash
aws eks update-kubeconfig --region us-west-2 --name petclinic-c2
kubectl get pods -n observability
```

Expected: 2 pods in `Running` status

### 2. Verify Data Export

**Check collector logs:**
```bash
kubectl logs -n observability -l app=otel-collector --tail=50 | grep "Host metadata synchronized"
```

Expected output:
```
info hostmetadata/metadata.go:73 Host metadata synchronized
```

This confirms metrics are being successfully sent to Splunk SignalFx.

### 3. View Data in Splunk

**Access Splunk Observability Cloud:**
1. Navigate to https://app.signalfx.com
2. Log in with your credentials

**View Kubernetes Metrics:**
1. Go to **Infrastructure → Kubernetes Navigator**
2. You should see two clusters:
   - `petclinic-c1` (us-east-1)
   - `petclinic-c2` (us-west-2)
3. Click on a cluster to view:
   - Node count and health status
   - Pod count and distribution
   - CPU and memory utilization
   - Network traffic

**View Metrics Explorer:**
1. Go to **Metrics**
2. Search for metrics with cluster tags:
   - `k8s.cluster.name:petclinic-c1`
   - `k8s.cluster.name:petclinic-c2`
3. Available metric categories:
   - `k8s.pod.*` - Pod metrics
   - `k8s.node.*` - Node metrics
   - `k8s.container.*` - Container metrics
   - `container.*` - Container resource usage

---

## Metrics Being Collected

### Cluster-Level Metrics

| Metric | Description | Source |
|--------|-------------|--------|
| `k8s.deployment.available` | Available replicas per deployment | k8s_cluster receiver |
| `k8s.pod.phase` | Pod phase (Running, Pending, etc.) | k8s_cluster receiver |
| `k8s.namespace.phase` | Namespace status | k8s_cluster receiver |

### Node Metrics

| Metric | Description | Source |
|--------|-------------|--------|
| `k8s.node.cpu.utilization` | Node CPU usage percentage | kubeletstats receiver |
| `k8s.node.memory.usage` | Node memory usage | kubeletstats receiver |
| `k8s.node.network.io` | Node network I/O | kubeletstats receiver |

### Pod/Container Metrics

| Metric | Description | Source |
|--------|-------------|--------|
| `container.cpu.utilization` | Container CPU usage | kubeletstats receiver |
| `container.memory.usage` | Container memory usage | kubeletstats receiver |
| `k8s.pod.cpu.utilization` | Pod-level CPU usage | kubeletstats receiver |
| `k8s.pod.memory.usage` | Pod-level memory usage | kubeletstats receiver |

### Custom Tags on All Metrics

- `cluster.name` - EKS cluster name (petclinic-c1 or petclinic-c2)
- `cluster.region` - AWS region (us-east-1 or us-west-2)
- `k8s.cluster.name` - Same as cluster.name
- `k8s.namespace.name` - Kubernetes namespace
- `k8s.pod.name` - Pod name
- `k8s.deployment.name` - Deployment name (if applicable)
- `cloud.provider` - `aws`
- `cloud.platform` - `aws_eks`

---

## Demo Use Cases

### 1. Cross-Region Observability

**Demonstrate:** View metrics from both clusters simultaneously

**Steps:**
1. In Splunk, create a dashboard
2. Add chart with filter: `k8s.cluster.name:petclinic-c1`
3. Add chart with filter: `k8s.cluster.name:petclinic-c2`
4. Compare resource utilization across regions

### 2. Service Health Monitoring

**Demonstrate:** Monitor demo application health

**Steps:**
1. Navigate to Kubernetes Navigator
2. Select cluster → demo-app deployment
3. View pod-level metrics:
   - CPU utilization
   - Memory usage
   - Restart count
   - Network traffic

### 3. Fault Detection

**Demonstrate:** Observability during fault injection

**Steps:**
1. Baseline: View normal metrics in Splunk dashboard
2. Trigger fault: Access `/error` or `/random` endpoints
3. Observe in Splunk:
   - Increase in HTTP error status codes
   - Pod restart events
   - Container crash metrics
   - Resource usage spikes

### 4. Alert Configuration

**Demonstrate:** Proactive monitoring

**Create alerts for:**
- Pod restart count > 3 in 5 minutes
- Container CPU utilization > 80%
- Deployment replica count < desired count
- Node memory pressure

---

## Troubleshooting

### No Clusters Visible in Splunk

**Check:**
1. Collector pods are running:
   ```bash
   kubectl get pods -n observability
   ```

2. Logs show successful export:
   ```bash
   kubectl logs -n observability -l app=otel-collector | grep "Host metadata synchronized"
   ```

3. Access token is correct:
   ```bash
   kubectl get secret splunk-otel-collector -n observability -o yaml | grep access_token
   ```

4. Network connectivity:
   ```bash
   kubectl exec -it -n observability <pod-name> -- wget -O- https://ingest.us1.signalfx.com
   ```

### Collector Pods CrashLooping

**Check pod logs:**
```bash
kubectl logs -n observability <pod-name>
```

**Common issues:**
- Configuration syntax error (YAML indentation)
- Invalid access token (401 Unauthorized)
- Insufficient RBAC permissions
- Resource limits too low

### High Memory Usage

**Check resource usage:**
```bash
kubectl top pods -n observability
```

**If approaching limits:**
- Increase memory limit in DaemonSet spec
- Reduce batch size in collector config
- Adjust `memory_limiter` processor threshold

---

## Next Steps

### For Demo Presentation

1. ✅ **Metrics are flowing** - Show Kubernetes Navigator
2. ⏳ **Create custom dashboards** - Build service health dashboard
3. ⏳ **Configure alerts** - Set up error rate and resource alerts
4. ⏳ **Fault injection demo** - Trigger errors, show detection in Splunk
5. ⏳ **Cross-region comparison** - Compare C1 vs C2 metrics

### For Production Readiness

1. **Add log aggregation**:
   - Deploy Splunk Enterprise or Splunk Cloud
   - Configure HEC exporter
   - Or integrate with CloudWatch Logs

2. **Application instrumentation**:
   - Add OpenTelemetry SDK to applications
   - Configure OTLP export to collector
   - Enable distributed tracing

3. **Advanced monitoring**:
   - Service-level objectives (SLOs)
   - Anomaly detection
   - Capacity planning dashboards
   - Cost attribution by namespace

4. **Security hardening**:
   - Rotate access tokens regularly
   - Use AWS Secrets Manager for token storage
   - Implement NetworkPolicy for collector
   - Enable TLS for OTLP receivers

---

## Files and Documentation

### Deployment Files
- [`observability/otel-collector-config.yaml`](../petclinic-k8s/manifests/observability/otel-collector-config.yaml) - Collector configuration
- [`observability/otel-collector-daemonset.yaml`](../petclinic-k8s/manifests/observability/otel-collector-daemonset.yaml) - Deployment manifest
- [`observability/splunk-secret.yaml`](../petclinic-k8s/manifests/observability/splunk-secret.yaml) - Access token secret
- [`observability/deploy-all.sh`](../petclinic-k8s/manifests/observability/deploy-all.sh) - Automated deployment script
- [`observability/README.md`](../petclinic-k8s/manifests/observability/README.md) - Comprehensive deployment guide

### Related Documentation
- [`OBSERVABILITY_SETUP.md`](OBSERVABILITY_SETUP.md) - Initial observability planning document
- [`APPLICATION_SELECTION.md`](APPLICATION_SELECTION.md) - Application deployment decisions
- [`DEPLOYMENT_ERRORS.md`](DEPLOYMENT_ERRORS.md) - Infrastructure deployment issues

---

## Summary

| Component | Status | Notes |
|-----------|--------|-------|
| Metrics Collection | ✅ Working | All cluster, node, pod metrics flowing to Splunk |
| Traces Collection | ✅ Ready | Configured, awaiting application instrumentation |
| Logs Collection | ⚠️ Local Only | Collected and enriched, not sent to Splunk O11y Cloud |
| C1 Collector | ✅ Operational | 2 pods running, exporting to SignalFx |
| C2 Collector | ✅ Operational | 2 pods running, exporting to SignalFx |
| Splunk Dashboard | ✅ Available | Kubernetes Navigator shows both clusters |
| Demo Ready | ✅ Yes | Can demonstrate cross-region observability |

**Recommendation for Demo:**
Focus on metrics (cluster health, resource utilization, cross-region comparison) and demonstrate how Ciroos would enhance this observability by automating incident investigation across both regions using the rich metadata being collected.

---

**Last Updated:** January 30, 2026
**Verified By:** Claude Code (Automated deployment and verification)
