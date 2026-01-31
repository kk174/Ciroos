#!/bin/bash
# inject-fault.sh - Simulate backend service failure for Ciroos demo
# Created: January 30, 2026

set -e

echo "=============================================="
echo "  Ciroos Demo - Fault Injection Script"
echo "=============================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Target:${NC} apm-backend-app in C2 (us-west-2)"
echo -e "${YELLOW}Action:${NC} Delete pod to simulate failure"
echo -e "${YELLOW}Expected Result:${NC} Service outage for 10-15 seconds, then auto-recovery"
echo ""

# Configure kubectl for C2 cluster
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
echo -e "${RED}⚠️  WARNING: About to delete pod: $POD_NAME${NC}"
echo ""
read -p "Press ENTER to inject fault (or Ctrl+C to cancel)..."

# Inject fault
echo ""
echo -e "${RED}💥 INJECTING FAULT: Deleting pod $POD_NAME${NC}"
kubectl delete pod -n petclinic $POD_NAME

echo ""
echo -e "${GREEN}✓ Fault injected!${NC}"
echo ""
echo "What happens now:"
echo "  1. Pod terminates (2-5 seconds)"
echo "  2. Kubernetes detects replica count mismatch"
echo "  3. New pod is scheduled and created (5-10 seconds)"
echo "  4. New pod starts and passes health checks (5-10 seconds)"
echo "  5. Service resumes normal operation"
echo ""
echo "Total expected downtime: 10-15 seconds"
echo ""

# Watch pod recovery
echo "Watching pod recovery (Ctrl+C to stop):"
echo ""
kubectl get pods -n petclinic -l app=apm-backend-app -w
