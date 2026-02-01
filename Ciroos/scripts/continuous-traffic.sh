#!/bin/bash
# continuous-traffic.sh - Keep traffic flowing to Splunk

set -e

C1_URL="http://a9dd2c5fde37e4c6abd04a564ea3ef95-a64aa6c61219d593.elb.us-east-1.amazonaws.com"

echo "=========================================="
echo "  Continuous Traffic Generator"
echo "=========================================="
echo ""
echo "Sending requests every 5 seconds..."
echo "Press Ctrl+C to stop"
echo ""

COUNT=0

while true; do
    # Send 5 requests every iteration
    for i in {1..5}; do
        # Mix of endpoints
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

    wait
    COUNT=$((COUNT + 5))
    echo "$(date '+%H:%M:%S') - Sent $COUNT total requests"

    # Wait 5 seconds before next batch
    sleep 5
done
