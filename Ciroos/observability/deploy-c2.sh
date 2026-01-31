#!/bin/bash
# Deploy OpenTelemetry Collector to C2 (us-west-2) cluster

set -e

CLUSTER_NAME="petclinic-c2"
REGION="us-west-2"
CONTEXT="arn:aws:eks:us-west-2:$(aws sts get-caller-identity --query Account --output text):cluster/petclinic-c2"

echo "========================================="
echo "Deploying OpenTelemetry Collector to C2"
echo "Cluster: $CLUSTER_NAME"
echo "Region: $REGION"
echo "========================================="

# Configure kubectl context
echo "Configuring kubectl context..."
aws eks update-kubeconfig --region $REGION --name $CLUSTER_NAME

# Create namespace
echo "Creating observability namespace..."
kubectl apply -f namespace.yaml

# Create Splunk secret
echo "Creating Splunk access token secret..."
kubectl apply -f splunk-secret.yaml

# Create OTel collector config
echo "Creating OTel collector configuration..."
kubectl apply -f otel-collector-config.yaml

# Deploy OTel collector with cluster-specific values
echo "Deploying OTel collector DaemonSet..."
cat otel-collector-daemonset.yaml | \
  sed "s/REPLACE_WITH_CLUSTER_NAME/$CLUSTER_NAME/g" | \
  sed "s/REPLACE_WITH_REGION/$REGION/g" | \
  kubectl apply -f -

# Wait for DaemonSet to be ready
echo "Waiting for OTel collector pods to be ready..."
kubectl rollout status daemonset/otel-collector -n observability --timeout=120s

# Check pod status
echo ""
echo "OTel Collector Pods:"
kubectl get pods -n observability -l app=otel-collector

echo ""
echo "OTel Collector Service:"
kubectl get svc -n observability otel-collector

echo ""
echo "========================================="
echo "✓ OpenTelemetry Collector deployed to C2"
echo "========================================="
echo ""
echo "Verify logs are being sent to Splunk:"
echo "kubectl logs -n observability -l app=otel-collector --tail=50"
echo ""
echo "Check collector health:"
echo "kubectl port-forward -n observability svc/otel-collector 13133:13133"
echo "curl http://localhost:13133"
