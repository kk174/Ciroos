#!/bin/bash
# pre-demo-check.sh - Verify all components before Ciroos demo
# Run this 30 minutes before the demo to catch any issues

set -e

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

PASS=0
FAIL=0

echo -e "${BLUE}=============================================="
echo "  Ciroos Demo - Pre-Demo Health Check"
echo "=============================================="
echo -e "${NC}"

# Function to check and report status
check_status() {
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ PASS${NC}: $1"
        ((PASS++))
    else
        echo -e "${RED}✗ FAIL${NC}: $1"
        ((FAIL++))
    fi
}

# 1. Check AWS Credentials
echo -e "${YELLOW}[1/10] Checking AWS credentials...${NC}"
aws sts get-caller-identity > /dev/null 2>&1
check_status "AWS credentials valid"

# 2. Check C1 Cluster Access
echo -e "${YELLOW}[2/10] Checking C1 cluster access...${NC}"
aws eks update-kubeconfig --region us-east-1 --name petclinic-c1 > /dev/null 2>&1
check_status "kubectl configured for C1"

kubectl get nodes > /dev/null 2>&1
check_status "C1 nodes accessible"

# 3. Check C1 Application Pods
echo -e "${YELLOW}[3/10] Checking C1 application pods...${NC}"
C1_RUNNING=$(kubectl get pods -n petclinic -l app=apm-test-app --no-headers 2>/dev/null | grep -c "Running" || echo "0")
if [ "$C1_RUNNING" -ge 1 ]; then
    echo -e "${GREEN}✓ PASS${NC}: C1 application pods running ($C1_RUNNING/2)"
    ((PASS++))
else
    echo -e "${RED}✗ FAIL${NC}: C1 application pods not running"
    ((FAIL++))
fi

# 4. Check C1 OTel Collector
echo -e "${YELLOW}[4/10] Checking C1 Splunk OTel collector...${NC}"
C1_OTEL=$(kubectl get pods -n splunk-monitoring --no-headers 2>/dev/null | grep -c "Running" || echo "0")
if [ "$C1_OTEL" -eq 3 ]; then
    echo -e "${GREEN}✓ PASS${NC}: C1 OTel collector running (3/3 pods)"
    ((PASS++))
else
    echo -e "${RED}✗ FAIL${NC}: C1 OTel collector incomplete ($C1_OTEL/3 pods)"
    ((FAIL++))
fi

# 5. Check C1 Application Endpoint
echo -e "${YELLOW}[5/10] Checking C1 application endpoint...${NC}"
C1_URL=$(kubectl get svc -n petclinic apm-test-app -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null)
if [ -n "$C1_URL" ]; then
    echo -e "${GREEN}✓ PASS${NC}: C1 load balancer provisioned"
    ((PASS++))
    echo "   URL: http://$C1_URL"

    # Test health endpoint
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "http://$C1_URL/health" --max-time 10 || echo "000")
    if [ "$HTTP_CODE" = "200" ]; then
        echo -e "${GREEN}✓ PASS${NC}: C1 /health endpoint responding"
        ((PASS++))
    else
        echo -e "${RED}✗ FAIL${NC}: C1 /health endpoint not responding (HTTP $HTTP_CODE)"
        ((FAIL++))
    fi
else
    echo -e "${RED}✗ FAIL${NC}: C1 load balancer not provisioned"
    ((FAIL+=2))
fi

# 6. Check C2 Cluster Access
echo -e "${YELLOW}[6/10] Checking C2 cluster access...${NC}"
aws eks update-kubeconfig --region us-west-2 --name petclinic-c2 > /dev/null 2>&1
check_status "kubectl configured for C2"

kubectl get nodes > /dev/null 2>&1
check_status "C2 nodes accessible"

# 7. Check C2 Application Pods
echo -e "${YELLOW}[7/10] Checking C2 application pods...${NC}"
C2_RUNNING=$(kubectl get pods -n petclinic -l app=apm-backend-app --no-headers 2>/dev/null | grep -c "Running" || echo "0")
if [ "$C2_RUNNING" -ge 1 ]; then
    echo -e "${GREEN}✓ PASS${NC}: C2 application pods running ($C2_RUNNING/2)"
    ((PASS++))
else
    echo -e "${RED}✗ FAIL${NC}: C2 application pods not running"
    ((FAIL++))
fi

# 8. Check C2 OTel Collector
echo -e "${YELLOW}[8/10] Checking C2 Splunk OTel collector...${NC}"
C2_OTEL=$(kubectl get pods -n splunk-monitoring --no-headers 2>/dev/null | grep -c "Running" || echo "0")
if [ "$C2_OTEL" -eq 3 ]; then
    echo -e "${GREEN}✓ PASS${NC}: C2 OTel collector running (3/3 pods)"
    ((PASS++))
else
    echo -e "${RED}✗ FAIL${NC}: C2 OTel collector incomplete ($C2_OTEL/3 pods)"
    ((FAIL++))
fi

# 9. Check C2 Internal Load Balancer
echo -e "${YELLOW}[9/10] Checking C2 backend endpoint...${NC}"
C2_URL=$(kubectl get svc -n petclinic apm-backend-app -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null)
if [ -n "$C2_URL" ]; then
    echo -e "${GREEN}✓ PASS${NC}: C2 internal load balancer provisioned"
    ((PASS++))
    echo "   URL: http://$C2_URL (internal only)"
else
    echo -e "${RED}✗ FAIL${NC}: C2 load balancer not provisioned"
    ((FAIL++))
fi

# 10. Test Cross-Region Communication
echo -e "${YELLOW}[10/10] Testing cross-region C1→C2 communication...${NC}"
if [ -n "$C1_URL" ]; then
    # Test /api/orders which calls C2
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "http://$C1_URL/api/orders" --max-time 15 || echo "000")
    if [ "$HTTP_CODE" = "200" ]; then
        echo -e "${GREEN}✓ PASS${NC}: Cross-region communication working"
        ((PASS++))

        # Verify response contains C2 data
        RESPONSE=$(curl -s "http://$C1_URL/api/orders" --max-time 15)
        if echo "$RESPONSE" | grep -q '"cluster": "C2"'; then
            echo -e "${GREEN}✓ PASS${NC}: Response contains C2 backend data"
            ((PASS++))
        else
            echo -e "${RED}✗ FAIL${NC}: Response missing C2 data (VPC peering issue?)"
            ((FAIL++))
        fi
    else
        echo -e "${RED}✗ FAIL${NC}: Cross-region communication failed (HTTP $HTTP_CODE)"
        ((FAIL+=2))
    fi
else
    echo -e "${RED}✗ FAIL${NC}: Cannot test cross-region (C1 URL unavailable)"
    ((FAIL+=2))
fi

# Summary
echo ""
echo -e "${BLUE}=============================================="
echo "  Health Check Summary"
echo "=============================================="
echo -e "${NC}"
echo -e "Total Checks: $((PASS + FAIL))"
echo -e "${GREEN}Passed: $PASS${NC}"
echo -e "${RED}Failed: $FAIL${NC}"
echo ""

if [ $FAIL -eq 0 ]; then
    echo -e "${GREEN}🎉 ALL SYSTEMS GO! Ready for demo!${NC}"
    echo ""
    echo "Next steps:"
    echo "  1. Open browser tabs (see DEMO_QUICK_REFERENCE.md)"
    echo "  2. Login to Splunk and verify data flowing"
    echo "  3. Review demo script one more time"
    echo "  4. Take a deep breath - you've got this!"
    exit 0
else
    echo -e "${RED}⚠️  SOME CHECKS FAILED - Review and fix before demo${NC}"
    echo ""
    echo "Common fixes:"
    echo "  - Pods not running: kubectl describe pod -n <namespace> <pod-name>"
    echo "  - Load balancer pending: Wait 2-3 minutes for AWS provisioning"
    echo "  - Endpoint not responding: Check pod logs with kubectl logs"
    echo "  - Cross-region failed: Verify VPC peering and security groups"
    exit 1
fi
