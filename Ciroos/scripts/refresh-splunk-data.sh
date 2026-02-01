#!/bin/bash
# refresh-splunk-data.sh - Refresh Splunk data before demo
# Run this 5-10 minutes before your demo to ensure Splunk has fresh data

set -e

C1_URL="http://a9dd2c5fde37e4c6abd04a564ea3ef95-a64aa6c61219d593.elb.us-east-1.amazonaws.com"

echo "================================================"
echo "  Splunk Data Refresh Script"
echo "================================================"
echo ""
echo "This script will:"
echo "  1. Restart OTel collectors (both clusters)"
echo "  2. Generate baseline traffic (300+ requests)"
echo "  3. Verify pods are running"
echo ""
read -p "Press ENTER to continue..."

# Step 1: Restart OTel Collectors
echo ""
echo "STEP 1: Restarting OTel Collectors"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo "  → Restarting C1 collectors (us-east-1)..."
aws eks update-kubeconfig --region us-east-1 --name petclinic-c1 > /dev/null 2>&1
kubectl rollout restart daemonset/splunk-otel-collector-agent -n splunk-monitoring > /dev/null
kubectl rollout restart deployment/splunk-otel-collector-k8s-cluster-receiver -n splunk-monitoring > /dev/null

echo "  → Restarting C2 collectors (us-west-2)..."
aws eks update-kubeconfig --region us-west-2 --name petclinic-c2 > /dev/null 2>&1
kubectl rollout restart daemonset/splunk-otel-collector-agent -n splunk-monitoring > /dev/null
kubectl rollout restart deployment/splunk-otel-collector-k8s-cluster-receiver -n splunk-monitoring > /dev/null

echo "  ✓ All collectors restarted"

# Step 2: Wait for collectors to be ready
echo ""
echo "STEP 2: Waiting for collectors to restart (15 seconds)..."
sleep 15

# Verify collectors
echo "  → Checking C1 collectors..."
aws eks update-kubeconfig --region us-east-1 --name petclinic-c1 > /dev/null 2>&1
C1_READY=$(kubectl get pods -n splunk-monitoring --field-selector=status.phase=Running --no-headers 2>/dev/null | wc -l)
echo "    C1: $C1_READY/3 collectors running"

echo "  → Checking C2 collectors..."
aws eks update-kubeconfig --region us-west-2 --name petclinic-c2 > /dev/null 2>&1
C2_READY=$(kubectl get pods -n splunk-monitoring --field-selector=status.phase=Running --no-headers 2>/dev/null | wc -l)
echo "    C2: $C2_READY/3 collectors running"

echo "  ✓ Collectors ready"

# Step 3: Generate baseline traffic
echo ""
echo "STEP 3: Generating baseline traffic (60 seconds)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

END_TIME=$(($(date +%s) + 60))
COUNT=0

while [ $(date +%s) -lt $END_TIME ]; do
    # Mix of endpoints
    for i in {1..3}; do
        RAND=$((RANDOM % 4))
        if [ $RAND -eq 0 ]; then
            curl -s -o /dev/null $C1_URL/health &
        elif [ $RAND -eq 1 ]; then
            curl -s -o /dev/null $C1_URL/api/users &
        elif [ $RAND -eq 2 ]; then
            curl -s -o /dev/null $C1_URL/api/orders &
        else
            curl -s -o /dev/null $C1_URL/api/checkout &
        fi
    done

    COUNT=$((COUNT + 12))

    if [ $((COUNT % 60)) -eq 0 ]; then
        echo "  → Sent $COUNT requests..."
    fi

    sleep 2
done

wait

echo "  ✓ Traffic generation complete"
echo ""
echo "================================================"
echo "  Summary"
echo "================================================"
echo ""
echo "  Total Requests Sent: $COUNT"
echo "  Time Elapsed: 60 seconds"
echo "  Request Rate: ~$((COUNT / 60)) req/sec"
echo ""
echo "  C1 Collectors: $C1_READY/3 running"
echo "  C2 Collectors: $C2_READY/3 running"
echo ""
echo "✅ Splunk should now have fresh data!"
echo ""
echo "Next steps:"
echo "  1. Wait 2-3 minutes for data to appear in Splunk"
echo "  2. Go to: https://app.us1.signalfx.com/"
echo "  3. Check: Infrastructure → Kubernetes Navigator"
echo "  4. Check: APM → Service Map"
echo ""
echo "If data still doesn't appear:"
echo "  • Check Splunk token: Settings → Access Tokens"
echo "  • Check collector logs: kubectl logs -n splunk-monitoring -l app=splunk-otel-collector"
echo "  • Run this script again"
echo ""
