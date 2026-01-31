#!/bin/bash
# test-alert.sh - Test Splunk alert by generating errors

set -e

echo "=============================================="
echo "  Splunk Alert Test - Generate Errors"
echo "=============================================="
echo ""

C1_URL="http://a9dd2c5fde37e4c6abd04a564ea3ef95-a64aa6c61219d593.elb.us-east-1.amazonaws.com"

echo "This script will:"
echo "1. Generate 50 requests to /api/error endpoint (100% error rate)"
echo "2. Wait 1-2 minutes for Splunk to process"
echo "3. Check if alert fires in Splunk"
echo ""
echo "Expected: Alert should fire when error rate > 40%"
echo ""

read -p "Press ENTER to start generating errors..."

echo ""
echo "Generating 50 error requests..."
for i in {1..50}; do
    curl -s -o /dev/null -w "Request $i: HTTP %{http_code}\n" $C1_URL/api/error &

    # Throttle to avoid overwhelming the service
    if [ $((i % 10)) -eq 0 ]; then
        wait
        sleep 1
    fi
done

wait

echo ""
echo "✓ Completed 50 requests to error endpoint"
echo ""
echo "Now check Splunk Observability Cloud:"
echo "1. Go to: https://app.us1.signalfx.com/"
echo "2. Navigate to: Alerts & Detectors"
echo "3. Look for: 'Backend Service - High Error Rate'"
echo "4. Status should show: ALERT (red)"
echo ""
echo "It may take 1-2 minutes for the alert to fire."
echo ""
echo "To check APM metrics:"
echo "- Go to: APM → Services → apm-test-app"
echo "- Check error rate in the last 5 minutes"
echo "- Should show spike to 100%"
echo ""
