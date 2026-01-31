# OpenTelemetry Collector for Splunk Observability Cloud

This directory contains the Kubernetes manifests and deployment scripts for integrating both EKS clusters (C1 and C2) with Splunk Observability Cloud using OpenTelemetry collectors.

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                   Splunk Observability Cloud                │
│              https://ingest.us1.signalfx.com                │
│                                                              │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │   Metrics    │  │     Logs     │  │    Traces    │     │
│  └──────────────┘  └──────────────┘  └──────────────┘     │
└─────────────────────────────────────────────────────────────┘
           ▲                  ▲                  ▲
           │                  │                  │
    ┌──────┴──────┐    ┌──────┴──────┐    ┌──────┴──────┐
    │   SignalFx  │    │  Splunk HEC │    │    OTLP     │
    │   Exporter  │    │   Exporter  │    │   Exporter  │
    └──────┬──────┘    └──────┬──────┘    └──────┬──────┘
           │                  │                  │
           └──────────────────┴──────────────────┘
                              │
                    ┌─────────▼─────────┐
                    │  OTel Collector   │
                    │   (DaemonSet)     │
                    └─────────┬─────────┘
                              │
           ┌──────────────────┼──────────────────┐
           │                  │                  │
    ┌──────▼──────┐    ┌──────▼──────┐   ┌──────▼──────┐
    │ Container   │    │  Kubelet    │   │ Application │
    │    Logs     │    │   Metrics   │   │   Metrics   │
    └─────────────┘    └─────────────┘   └─────────────┘

         EKS Cluster (C1 in us-east-1, C2 in us-west-2)
```

## Components

### 1. OpenTelemetry Collector
- **Deployment Type**: DaemonSet (one pod per node)
- **Image**: `otel/opentelemetry-collector-contrib:0.91.0`
- **Namespace**: `observability`

### 2. Data Collection
The collector gathers:
- **Container Logs**: From `/var/log/pods/*/*/*.log`
- **Kubernetes Metrics**: Pod, container, node metrics via kubeletstats
- **Cluster Metrics**: Cluster-level metrics via k8s_cluster receiver
- **Application Metrics**: Via OTLP and Prometheus receivers
- **Traces**: Via OTLP receiver (for future APM integration)

### 3. Data Export
Data is sent to Splunk Observability Cloud:
- **Logs** → Splunk HEC (HTTP Event Collector)
- **Metrics** → SignalFx
- **Traces** → Splunk APM (OTLP)

## Files

- `namespace.yaml` - Creates the `observability` namespace
- `splunk-secret.yaml` - Stores Splunk access token (sensitive)
- `otel-collector-config.yaml` - OpenTelemetry collector configuration
- `otel-collector-daemonset.yaml` - Collector DaemonSet, ServiceAccount, RBAC
- `deploy-c1.sh` - Deploy to C1 cluster (us-east-1)
- `deploy-c2.sh` - Deploy to C2 cluster (us-west-2)
- `deploy-all.sh` - Deploy to both clusters

## Prerequisites

1. **AWS CLI configured** with access to both regions:
   ```bash
   aws sts get-caller-identity
   ```

2. **kubectl installed** and configured:
   ```bash
   kubectl version --client
   ```

3. **Splunk Observability Cloud account** with:
   - Access Token: `QRF-G2Q75tubuVTGyAlZMw`
   - Realm: `us1`

4. **EKS clusters deployed**:
   - C1: `petclinic-c1` in `us-east-1`
   - C2: `petclinic-c2` in `us-west-2`

## Quick Start

### Deploy to Both Clusters

```bash
cd /Users/kanu/Desktop/Ciroos/petclinic-k8s/manifests/observability
./deploy-all.sh
```

This will:
1. Deploy OTel collector to C1 (us-east-1)
2. Deploy OTel collector to C2 (us-west-2)
3. Verify deployments are successful

### Deploy to Individual Clusters

**C1 only:**
```bash
./deploy-c1.sh
```

**C2 only:**
```bash
./deploy-c2.sh
```

## Manual Deployment Steps

If you prefer manual deployment:

### For C1 (us-east-1)

```bash
# Configure kubectl
aws eks update-kubeconfig --region us-east-1 --name petclinic-c1

# Create namespace
kubectl apply -f namespace.yaml

# Create secret
kubectl apply -f splunk-secret.yaml

# Deploy collector config
kubectl apply -f otel-collector-config.yaml

# Deploy collector (replace cluster name/region)
cat otel-collector-daemonset.yaml | \
  sed 's/REPLACE_WITH_CLUSTER_NAME/petclinic-c1/g' | \
  sed 's/REPLACE_WITH_REGION/us-east-1/g' | \
  kubectl apply -f -

# Wait for rollout
kubectl rollout status daemonset/otel-collector -n observability
```

### For C2 (us-west-2)

```bash
# Configure kubectl
aws eks update-kubeconfig --region us-west-2 --name petclinic-c2

# Create namespace
kubectl apply -f namespace.yaml

# Create secret
kubectl apply -f splunk-secret.yaml

# Deploy collector config
kubectl apply -f otel-collector-config.yaml

# Deploy collector (replace cluster name/region)
cat otel-collector-daemonset.yaml | \
  sed 's/REPLACE_WITH_CLUSTER_NAME/petclinic-c2/g' | \
  sed 's/REPLACE_WITH_REGION/us-west-2/g' | \
  kubectl apply -f -

# Wait for rollout
kubectl rollout status daemonset/otel-collector -n observability
```

## Verification

### Check Pod Status

**C1:**
```bash
aws eks update-kubeconfig --region us-east-1 --name petclinic-c1
kubectl get pods -n observability
```

Expected output:
```
NAME                   READY   STATUS    RESTARTS   AGE
otel-collector-xxxxx   1/1     Running   0          2m
otel-collector-yyyyy   1/1     Running   0          2m
```

**C2:**
```bash
aws eks update-kubeconfig --region us-west-2 --name petclinic-c2
kubectl get pods -n observability
```

### Check Collector Logs

```bash
# C1
kubectl logs -n observability -l app=otel-collector --tail=50

# C2
aws eks update-kubeconfig --region us-west-2 --name petclinic-c2
kubectl logs -n observability -l app=otel-collector --tail=50
```

Look for:
- `Everything is ready. Begin running and processing data.`
- No error messages about authentication or connectivity

### Check Collector Health

```bash
# Port forward to collector
kubectl port-forward -n observability svc/otel-collector 13133:13133

# In another terminal
curl http://localhost:13133
```

Expected: HTTP 200 response with `{"status":"Server available"}`

## Verify Data in Splunk

1. **Log in to Splunk Observability Cloud**:
   - URL: https://app.signalfx.com
   - Realm: us1

2. **Check Kubernetes Navigator**:
   - Navigate to: **Infrastructure → Kubernetes Navigator**
   - You should see both clusters:
     - `petclinic-c1` (us-east-1)
     - `petclinic-c2` (us-west-2)

3. **View Cluster Metrics**:
   - Click on a cluster to see:
     - Node count and health
     - Pod count and status
     - CPU and memory utilization
     - Network traffic

4. **Search Logs**:
   - Navigate to: **Log Observer**
   - Search for:
     - `k8s.cluster.name:petclinic-c1`
     - `k8s.cluster.name:petclinic-c2`
   - You should see container logs from both clusters

5. **Check Service Map**:
   - Navigate to: **APM → Service Map**
   - You should see services from both clusters
   - C1 → C2 communication should be visible

## Configuration Details

### Receivers Enabled

1. **filelog** - Container log collection from `/var/log/pods`
2. **kubeletstats** - Pod, container, node metrics
3. **k8s_cluster** - Cluster-level metrics (deployments, services, etc.)
4. **otlp** - For application instrumentation (OTLP protocol)
5. **prometheus** - Scrapes Prometheus-annotated pods

### Processors Applied

1. **memory_limiter** - Prevents OOM (512MB limit)
2. **batch** - Batches data for efficiency
3. **k8sattributes** - Enriches with Kubernetes metadata
4. **resource** - Adds cluster name and region
5. **resourcedetection** - Auto-detects AWS/EKS metadata
6. **filter** - Excludes system namespace logs (kube-system, etc.)

### Exporters Configured

1. **splunk_hec** - Sends logs to Splunk
2. **signalfx** - Sends metrics to Splunk
3. **otlp** - Sends traces to Splunk APM

## Troubleshooting

### Pods Not Starting

**Check pod events:**
```bash
kubectl describe pod -n observability -l app=otel-collector
```

**Common issues:**
- ImagePullBackOff → Check internet connectivity
- CrashLoopBackOff → Check logs for config errors
- Pending → Check node resources

### Authentication Errors in Logs

**Error:** `401 Unauthorized` or `403 Forbidden`

**Solution:**
- Verify Splunk access token in secret:
  ```bash
  kubectl get secret splunk-otel-collector -n observability -o yaml
  ```
- Check token is correct: `QRF-G2Q75tubuVTGyAlZMw`
- Verify realm is correct: `us1`

### No Data in Splunk

**Check collector is sending data:**
```bash
kubectl logs -n observability -l app=otel-collector | grep -i export
```

Look for export success messages.

**Check Splunk token status:**
- Log in to Splunk Observability
- Settings → Access Tokens
- Verify token `G_7prKoAwAM` is active

**Check network connectivity:**
```bash
kubectl exec -it -n observability deployment/otel-collector -- sh
wget -O- https://ingest.us1.signalfx.com
```

### High Memory Usage

The collector has a memory limit of 512MB per pod.

**Check memory usage:**
```bash
kubectl top pods -n observability
```

**If approaching limit:**
- Increase memory limit in `otel-collector-daemonset.yaml`
- Reduce batch size in config
- Increase `memory_limiter` threshold

### Logs Not Appearing

**Check log file paths:**
```bash
kubectl exec -it -n observability <pod-name> -- ls -la /var/log/pods/
```

**Verify filelog receiver:**
```bash
kubectl logs -n observability <pod-name> | grep filelog
```

## Advanced Configuration

### Change Splunk Realm

If your Splunk realm is not `us1`:

1. Edit `splunk-secret.yaml`:
   ```yaml
   realm: "eu0"  # or us0, us2, jp0, etc.
   ```

2. Edit `otel-collector-daemonset.yaml`:
   ```yaml
   - name: SPLUNK_REALM
     value: "eu0"
   ```

3. Redeploy

### Add Custom Metrics

To scrape custom Prometheus metrics from your applications:

1. Annotate your pods:
   ```yaml
   annotations:
     prometheus.io/scrape: "true"
     prometheus.io/port: "8080"
     prometheus.io/path: "/metrics"
   ```

2. The collector will automatically scrape these endpoints

### Enable Debug Logging

Edit `otel-collector-config.yaml`:

```yaml
exporters:
  logging:
    loglevel: debug  # Change from info to debug
```

Redeploy the collector.

## Resource Requirements

### Per Node (DaemonSet)

- **CPU Request**: 100m (0.1 CPU)
- **CPU Limit**: 500m (0.5 CPU)
- **Memory Request**: 256Mi
- **Memory Limit**: 512Mi

### Total for 2-node cluster

- **CPU**: 200m - 1000m
- **Memory**: 512Mi - 1Gi

## Security Considerations

### Secret Management

The Splunk access token is stored as a Kubernetes secret. For production:

1. **Use AWS Secrets Manager**:
   - Store token in AWS Secrets Manager
   - Use ExternalSecrets operator to sync to K8s

2. **Rotate tokens regularly**:
   - Generate new token in Splunk
   - Update secret
   - Restart collector pods

### RBAC Permissions

The collector requires ClusterRole permissions to:
- Read nodes, pods, services (for metadata enrichment)
- Read node stats (for kubeletstats receiver)

Review `otel-collector-daemonset.yaml` ClusterRole for full permissions.

### Network Policies

Consider adding NetworkPolicy to restrict:
- Egress: Only to Splunk endpoints
- Ingress: Only from application pods (OTLP receiver)

## Maintenance

### Update Collector Version

1. Edit `otel-collector-daemonset.yaml`:
   ```yaml
   image: otel/opentelemetry-collector-contrib:0.92.0  # New version
   ```

2. Redeploy:
   ```bash
   ./deploy-all.sh
   ```

### Monitor Collector Health

Set up alerts in Splunk for:
- Collector pod crashes
- High memory usage (>80%)
- Export failures
- No data received for >5 minutes

## Uninstall

### Remove from C1

```bash
aws eks update-kubeconfig --region us-east-1 --name petclinic-c1
kubectl delete daemonset otel-collector -n observability
kubectl delete configmap otel-collector-config -n observability
kubectl delete secret splunk-otel-collector -n observability
kubectl delete namespace observability
```

### Remove from C2

```bash
aws eks update-kubeconfig --region us-west-2 --name petclinic-c2
kubectl delete daemonset otel-collector -n observability
kubectl delete configmap otel-collector-config -n observability
kubectl delete secret splunk-otel-collector -n observability
kubectl delete namespace observability
```

## Support

For issues:
- Check collector logs: `kubectl logs -n observability -l app=otel-collector`
- Review Splunk status: https://status.splunk.com
- OpenTelemetry docs: https://opentelemetry.io/docs/collector/
- Splunk O11y docs: https://docs.splunk.com/Observability

## Next Steps

After deploying the collector:

1. **Generate Traffic**: Access the demo applications to generate logs and metrics
2. **Create Dashboards**: Build custom dashboards in Splunk
3. **Set Up Alerts**: Configure alerts for error rates and latency
4. **Fault Injection**: Test observability by injecting faults (see `/error` endpoint)
5. **APM Integration**: Instrument applications with OpenTelemetry SDKs
