# Splunk → Ciroos Webhook Integration

**Purpose:** Feed Splunk alerts directly into Ciroos AI for automated investigation

---

## Option 1: Local Webhook Receiver (Demo)

### Start the Receiver

```bash
cd /Users/kanu/Desktop/projects/Ciroos/scripts
node webhook-receiver.js
```

**Output:**
```
🎯 Ciroos Webhook Receiver Started
   Listening on: http://localhost:3000/api/alerts
   Waiting for alerts from Splunk...
```

### Expose with ngrok (for Splunk to reach it)

```bash
# Install ngrok if needed
brew install ngrok

# Expose local server
ngrok http 3000
```

**Copy the public URL:** `https://abc123.ngrok.io`

### Configure in Splunk

1. **Settings** → **Integrations** → **New Integration**
2. **Webhook**
3. **Configuration:**
   ```
   Name: Ciroos Local Demo
   URL: https://abc123.ngrok.io/api/alerts
   Method: POST
   ```

4. **Add to your detectors** (APM + Infrastructure alerts)

---

## Option 2: Webhook Testing Service (Quickest)

### Use Webhook.site

1. Go to: https://webhook.site
2. Copy your unique URL
3. Use in Splunk webhook configuration
4. View incoming alerts in real-time

**Perfect for demo - shows exact payload Ciroos would receive!**

---

## Option 3: Production Ciroos Integration

```
URL: https://api.ciroos.com/v1/alerts/ingest
Method: POST
Headers:
  Content-Type: application/json
  Authorization: Bearer <ciroos-api-token>
  X-Source: splunk-observability
```

---

## Webhook Payload Format

Splunk sends this JSON when alerts fire:

```json
{
  "incidentId": "HAB9AJYA4AQ",
  "detectorId": "Ekl8wABAAAA",
  "detectorName": "APM - Sudden change in service error rate",
  "severity": "Critical",
  "status": "triggered",
  "triggeredAt": "2026-02-01T12:58:50Z",
  "triggeredWhile": "Below",
  "triggeredOn": 1.0,
  "rule": {
    "detectLabel": "APM Service Error rate",
    "severity": "Critical",
    "disabled": false
  },
  "dimensions": {
    "sf_service": "apm-test-app",
    "sf_environment": "demo",
    "kubernetes_cluster": "petclinic-c1",
    "kubernetes_namespace": "petclinic"
  },
  "inputs": {
    "error_rate": 5.19,
    "preceding_error_rate": 0.0,
    "threshold": 0.0
  },
  "eventAnnotations": {
    "description": "Error rate in a service has suddenly grown",
    "runbookUrl": "https://github.com/kk174/Ciroos"
  },
  "detectorUrl": "https://app.us1.signalfx.com/detector/..."
}
```

---

## Demo Flow

### 1. Start Webhook Receiver

```bash
cd /Users/kanu/Desktop/projects/Ciroos/scripts
node webhook-receiver.js
```

(Keep this terminal open)

### 2. Expose with ngrok

```bash
ngrok http 3000
```

Copy the public URL: `https://abc123.ngrok.io`

### 3. Configure Splunk Webhooks

**For APM Alert:**
- Edit detector
- Alert Recipients → Add → Webhook
- URL: `https://abc123.ngrok.io/api/alerts`

**For Infrastructure Alert:**
- Same process

### 4. Trigger Fault

```bash
./inject-fault.sh
```

### 5. Watch Webhook Receiver

The terminal will show:
```
========================================
🚨 ALERT RECEIVED FROM SPLUNK
========================================
Timestamp: 2026-02-01T13:02:15.000Z

Alert Details:
  Incident ID: HAB9AJYA4AQ
  Detector: Backend Service - High Error Rate
  Severity: Critical
  Status: triggered
  Service: apm-test-app

Full Payload:
{...}

========================================
✅ CIROOS AI INVESTIGATION TRIGGERED
========================================
```

### 6. Demo Talking Points

**Show the audience:**

1. **"Here's Splunk detecting the issue"** [Show alert in Splunk UI]

2. **"Immediately, Splunk sends this alert to Ciroos"** [Show webhook receiver terminal]

3. **"Ciroos AI receives the alert and starts investigating"** [Show payload details]

4. **"Within 30 seconds, Ciroos identifies root cause:"**
   - Checks Splunk APM: Error rate spike ✓
   - Checks Kubernetes API: Pod terminated ✓
   - Correlates timeline: Pod deletion → errors ✓
   - Root cause: "Pod apm-backend-app-XXX terminated, Kubernetes auto-recovery in progress"

5. **"Without Ciroos, an engineer would manually check each tool - taking 10-15 minutes"**

---

## Ciroos AI Investigation Workflow

**When webhook received:**

```
1. Parse alert payload
   ↓
2. Identify affected service (apm-test-app)
   ↓
3. Query data sources:
   - Splunk APM: Get error traces
   - Splunk Infrastructure: Get pod events
   - Kubernetes API: Get pod status
   - AWS CloudWatch: Get node metrics
   ↓
4. Correlate events on timeline
   ↓
5. Identify root cause
   ↓
6. Generate incident report
   ↓
7. Suggest remediation (if applicable)
```

**Time: 30-60 seconds**

---

## Testing the Webhook

### Manual Test

```bash
curl -X POST http://localhost:3000/api/alerts \
  -H "Content-Type: application/json" \
  -d '{
    "incidentId": "TEST123",
    "detectorName": "Test Alert",
    "severity": "Critical",
    "status": "triggered",
    "dimensions": {
      "sf_service": "apm-test-app"
    }
  }'
```

**Expected output in webhook receiver terminal:**
```
🚨 ALERT RECEIVED FROM SPLUNK
Alert Details:
  Incident ID: TEST123
  Detector: Test Alert
  ...
```

---

## Production Considerations

**For real Ciroos integration:**

1. **Authentication:** Add API key validation
2. **Rate Limiting:** Handle alert storms
3. **Deduplication:** Same alert firing multiple times
4. **Retry Logic:** Handle temporary failures
5. **Alert Correlation:** Group related alerts
6. **Escalation:** Critical vs. warning severity handling

---

## Troubleshooting

**Webhook not receiving alerts:**
- Check ngrok is running
- Verify Splunk webhook URL is correct
- Check webhook receiver logs
- Test with curl command above

**Splunk can't reach webhook:**
- Ensure ngrok URL is public
- Check firewall settings
- Verify webhook receiver is running

---

## Summary

**Webhook integration enables:**
- ✅ Real-time alert delivery to Ciroos
- ✅ Automated investigation triggering
- ✅ Complete alert context (service, metrics, dimensions)
- ✅ Seamless Splunk → Ciroos workflow

**Demo ready!** 🚀
