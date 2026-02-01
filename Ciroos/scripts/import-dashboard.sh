#!/bin/bash
# import-dashboard.sh - Import Ciroos demo dashboard to Splunk

SPLUNK_TOKEN="s2QShwFU2-K214ozAT7Ifg"
SPLUNK_REALM="us1"
DASHBOARD_FILE="/Users/kanu/Desktop/projects/Ciroos/documentation/ciroos-demo-dashboard.json"

echo "=========================================="
echo "  Importing Dashboard to Splunk"
echo "=========================================="
echo ""

curl -X POST \
  "https://api.${SPLUNK_REALM}.signalfx.com/v2/dashboard" \
  -H "Content-Type: application/json" \
  -H "X-SF-TOKEN: ${SPLUNK_TOKEN}" \
  -d @"${DASHBOARD_FILE}" \
  | jq '.'

echo ""
echo "✓ Dashboard imported!"
echo ""
echo "View it at:"
echo "https://app.us1.signalfx.com/dashboard/..."
