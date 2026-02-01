#!/bin/bash
# inject-fault-with-traffic.sh - Inject fault AND generate traffic to trigger both alerts
# Created: January 31, 2026

set -e

C1_URL="http://a9dd2c5fde37e4c6abd04a564ea3ef95-a64aa6c61219d593.elb.us-east-1.amazonaws.com"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "=============================================="
echo "  Ciroos Demo - Full Fault Injection"
echo "=============================================="
echo ""
echo -e "${YELLOW}This script will:${NC}"
echo "  1. Delete backend pod in C2 (Infrastructure alert)"
echo "  2. Generate high traffic (APM error rate alert)"
echo "  3. Both alerts should fire!"
echo ""

# Configure kubectl for C2
echo "Configuring kubectl for C2 cluster..."
aws eks update-kubeconfig --region us-west-2 --name petclinic-c2 > /dev/null 2>&1

# Get current pod status
echo ""
echo "Current backend pods in C2:"
kubectl get pods -n petclinic -l app=apm-backend-app

# Get pod name
POD_NAME=$(kubectl get pods -n petclinic -l app=apm-backend-app -o jsonpath='{.items[0].metadata.name}')

if [ -z "$POD_NAME" ]; then
    echo -e "${RED}ERROR: No apm-backend-app pods found!${NC}"
    exit 1
fi

echo ""
echo -e "${RED}⚠️  Ready to inject fault and generate traffic${NC}"
echo ""
read -p "Press ENTER to continue (or Ctrl+C to cancel)..."

# Step 1: Delete pod
echo ""
echo -e "${RED}💥 STEP 1: Deleting pod $POD_NAME${NC}"
kubectl delete pod -n petclinic $POD_NAME

echo ""
echo -e "${GREEN}✓ Pod deleted!${NC}"
echo ""

# Step 2: Generate high traffic to overwhelm remaining pod
echo -e "${YELLOW}⚡ STEP 2: Generating high traffic (60 seconds)${NC}"
echo "   This will stress the single remaining pod and trigger error rate alert"
echo ""

END_TIME=$(($(date +%s) + 60))
COUNT=0

while [ $(date +%s) -lt $END_TIME ]; do
    # Send requests to cross-region endpoints (which hit the backend)
    for i in {1..5}; do
        curl -s -o /dev/null $C1_URL/api/orders &
        curl -s -o /dev/null $C1_URL/api/checkout &
    done
    COUNT=$((COUNT + 10))

    if [ $((COUNT % 50)) -eq 0 ]; then
        echo "   Sent $COUNT requests..."
    fi

    sleep 0.5
done

wait

echo ""
echo -e "${GREEN}✓ Traffic generation complete!${NC}"
echo ""
echo "=========================================="
echo "  Expected Results:"
echo "=========================================="
echo ""
echo "⏰ T+30 seconds:"
echo "   Infrastructure Alert should fire"
echo "   (Pod count below 2)"
echo ""
echo "⏰ T+60 seconds:"
echo "   APM Error Rate Alert should fire"
echo "   (Error rate > 40%)"
echo ""
echo "Check Splunk:"
echo "  1. Go to: Alerts & Detectors"
echo "  2. Look for both alerts firing (red status)"
echo "  3. Click to see details"
echo ""
echo "Pod Recovery:"
kubectl get pods -n petclinic -l app=apm-backend-app
echo ""
echo "Demo complete! 🎉"
