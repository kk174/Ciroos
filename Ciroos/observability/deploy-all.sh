#!/bin/bash
# Deploy OpenTelemetry Collector to both C1 and C2 clusters

set -e

echo "========================================="
echo "Deploying OpenTelemetry Collector to All Clusters"
echo "========================================="
echo ""

# Check AWS credentials
echo "Verifying AWS credentials..."
aws sts get-caller-identity > /dev/null
if [ $? -ne 0 ]; then
    echo "Error: AWS credentials not configured"
    exit 1
fi

echo "✓ AWS credentials verified"
echo ""

# Deploy to C1
echo "========================================="
echo "Step 1/2: Deploying to C1 (us-east-1)"
echo "========================================="
bash deploy-c1.sh

echo ""
sleep 5

# Deploy to C2
echo "========================================="
echo "Step 2/2: Deploying to C2 (us-west-2)"
echo "========================================="
bash deploy-c2.sh

echo ""
echo "========================================="
echo "✓ All Deployments Complete"
echo "========================================="
echo ""
echo "Verification:"
echo ""
echo "C1 Cluster:"
echo "  aws eks update-kubeconfig --region us-east-1 --name petclinic-c1"
echo "  kubectl get pods -n observability"
echo "  kubectl logs -n observability -l app=otel-collector --tail=20"
echo ""
echo "C2 Cluster:"
echo "  aws eks update-kubeconfig --region us-west-2 --name petclinic-c2"
echo "  kubectl get pods -n observability"
echo "  kubectl logs -n observability -l app=otel-collector --tail=20"
echo ""
echo "Splunk Observability Cloud:"
echo "  Log in to https://app.signalfx.com (realm: us1)"
echo "  Navigate to: Infrastructure > Kubernetes Navigator"
echo "  You should see both petclinic-c1 and petclinic-c2 clusters"
echo ""
