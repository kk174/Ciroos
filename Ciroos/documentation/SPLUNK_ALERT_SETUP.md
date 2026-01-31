# Splunk Alert Setup Guide

**Purpose:** Configure "High Error Rate" alert for demo fault detection
**Time Required:** 5 minutes
**Date:** January 31, 2026

---

## 🎯 Alert Overview

**Alert Name:** Backend Service - High Error Rate

**What it detects:**
- When the error rate of apm-test-app exceeds 40%
- Typically fires when C2 backend becomes unavailable
- Perfect for demonstrating automated fault detection

**When it fires:**
- During pod deletion (C2 backend down)
- When C2 backend is unreachable
- During network connectivity issues

---

## 📋 Step-by-Step Configuration

### **1. Login to Splunk**

URL: https://app.us1.signalfx.com/
Realm: us1
Token: (your access token)

---

### **2. Navigate to Detectors**

1. Click: **"Alerts & Detectors"** (left sidebar, bell icon)
2. Click: **"New Detector"** (blue button, top right)

---

### **3. Choose Detector Type**

**Option A: APM Detector (Recommended)**
- Click: **"APM Detector"**
- This uses built-in APM metrics

**Option B: Custom Detector**
- Click: **"Custom Detector"**
- More flexible, uses any metric

For this guide, we'll use **APM Detector** (simpler).

---

### **4. Configure APM Detector**

#### **A. Select Service**
```
Service: apm-test-app
Environment: demo (if available, otherwise "All")
```

#### **B. Select Metric**
```
Metric Type: Error Rate
Calculation: Percentage of requests with errors
Time Window: 1 minute
```

#### **C. Set Alert Condition**
```
Alert when: Error Rate > 40%
For at least: 1 minute
Severity: Critical
```

---

### **5. Alternative: Custom Detector Configuration**

If you chose Custom Detector, use this configuration:

#### **Signal Configuration:**

**Signal A - Error Count:**
```yaml
Plot Name: Errors
Metric: spans.count
Filters:
  - service.name = apm-test-app
  - error = true
Aggregation: Sum
Rollup: Sum by service.name
```

**Signal B - Total Requests:**
```yaml
Plot Name: Total Requests
Metric: spans.count
Filters:
  - service.name = apm-test-app
Aggregation: Sum
Rollup: Sum by service.name
```

**Formula - Error Rate:**
```yaml
Name: error_rate
Formula: (A / B) * 100
```

#### **Alert Rule:**
```yaml
Trigger Condition: Static Threshold
Rule: error_rate > 40
Duration: At least 1 minute
Severity: Critical
```

---

### **6. Configure Alert Message**

**Alert Title:**
```
🚨 High Error Rate Detected - {{service.name}}
```

**Alert Body:**
```
Service: {{service.name}}
Error Rate: {{value}}%
Threshold: 40%
Duration: {{duration}}

Cluster: C1 (us-east-1)
Target Service: apm-backend-service (C2)

Potential Causes:
- Backend service unavailable
- Network connectivity issues
- VPC peering failure
- Pod failure in C2 cluster

Action Required: Investigate backend connectivity
```

**Runbook URL (Optional):**
```
https://github.com/kk174/Ciroos/blob/main/documentation/LIVE_DEMO_SCRIPT.md
```

---

### **7. Configure Notifications**

#### **Email Notification:**
```
Recipient: your-email@example.com
Subject: [CRITICAL] High Error Rate - {{service.name}}
Send when: Alert triggered
```

#### **Auto-Clear Settings:**
```
Clear alert when: error_rate < 40% for 1 minute
Send clear notification: Yes
```

---

### **8. Save and Activate**

1. **Detector Name:** "Backend Service - High Error Rate"
2. Click: **"Activate"**
3. Status should show: **Active** (green)

---

## ✅ Verify Alert is Active

### **Check Detector Status**

1. Go to: Alerts & Detectors
2. Find: "Backend Service - High Error Rate"
3. Status: Should show **Active** with green checkmark
4. Muted: Should be **No**

### **View Detector Details**

Click on the detector name to see:
- Alert rule configuration
- Current metric values
- Alert history (should be empty initially)

---

## 🧪 Test the Alert

### **Method 1: Generate Errors (Safe)**

Run the test script:
```bash
cd /Users/kanu/Desktop/projects/Ciroos/scripts
./test-alert.sh
```

This will:
1. Send 50 requests to `/api/error` endpoint (100% error rate)
2. Wait for Splunk to process
3. Alert should fire within 1-2 minutes

### **Method 2: Delete Pod (Demo Scenario)**

```bash
# Get pod name
kubectl get pods -n petclinic -l app=apm-backend-app

# Delete one pod
kubectl delete pod <pod-name> -n petclinic

# Alert should fire within 1-2 minutes
```

### **Method 3: Check Manually**

Visit the error endpoint in browser:
```
http://a9dd2c5fde37e4c6abd04a564ea3ef95-a64aa6c61219d593.elb.us-east-1.amazonaws.com/api/error
```

Refresh 20-30 times to generate enough errors.

---

## 🔍 Verify Alert Fired

### **Check Alert Status**

1. Go to: https://app.us1.signalfx.com/
2. Navigate to: Alerts & Detectors
3. Look for: "Backend Service - High Error Rate"
4. Status should show: **ALERT** (red) or **Firing**

### **Check Alert History**

1. Click on the detector
2. Go to: **"Alert History"** tab
3. Should see recent alert events with timestamps

### **Check Email**

If you configured email notifications:
- Check inbox for alert email
- Subject: [CRITICAL] High Error Rate - apm-test-app

---

## 📊 Expected Behavior During Demo

### **Baseline (Normal Operation)**
```
Error Rate: ~20% (due to intentional payment failures)
Alert Status: OK (green)
```

### **During Fault (Pod Deleted)**
```
Time: 0s - Delete pod
Time: 5s - Error rate climbs to 100%
Time: 60s - Alert fires! 🚨
Alert Status: CRITICAL (red)
Alert Message: "High Error Rate Detected!"
```

### **After Recovery (Pod Restarted)**
```
Time: 75s - New pod becomes healthy
Time: 80s - Error rate drops to 20%
Time: 140s - Alert clears (below threshold for 1 min)
Alert Status: OK (green)
```

---

## 🎬 Using Alert in Your Demo

### **Demo Script Integration**

**Part 1: Show Healthy State**
```
"Right now, everything is healthy.
Let me show you the alert configuration..."
[Show Splunk detector, status: OK]
```

**Part 2: Inject Fault**
```
"Now I'm going to simulate a real production incident
by deleting a backend pod in C2..."
[Run: kubectl delete pod ...]
```

**Part 3: Show Alert Firing**
```
"Within 60 seconds, the alert fired automatically.
This is what an engineer would see - they get paged at 2am.
Now they have to manually investigate..."
[Show Splunk alert status: CRITICAL]
```

**Part 4: Manual Investigation**
```
"Let me show you what the engineer would do:
1. Check APM for error traces
2. Check infrastructure for pod status
3. Correlate the data
4. Identify root cause
This takes 5-10 minutes typically..."
[Navigate through Splunk APM and Infrastructure]
```

**Part 5: Ciroos Value Proposition**
```
"With Ciroos, this entire investigation happens automatically:
- Alert fires
- Ciroos AI starts investigating immediately
- Checks APM, Infrastructure, Kubernetes API, CloudWatch
- Correlates all the data
- Delivers root cause in 10 seconds:
  'Pod terminated, Kubernetes recreated it, service restored.'"
```

---

## 🔧 Troubleshooting

### **Alert Not Firing**

**Check 1: Metric Data**
- Go to: APM → Services → apm-test-app
- Verify error rate is showing data
- Check if error rate actually exceeds 40%

**Check 2: Detector Active**
- Go to: Alerts & Detectors
- Verify detector status is **Active** (not muted)

**Check 3: Time Window**
- Alert requires error rate > 40% for **1 full minute**
- If pod recovers in < 60 seconds, alert may not fire
- Solution: Make condition stricter (30 seconds instead of 1 minute)

**Check 4: Service Name**
- Verify filter: `service.name = apm-test-app`
- Check actual service name in APM (might have different capitalization)

### **Alert Fires Too Often**

**Solution 1: Increase Threshold**
```
Change: error_rate > 40%
To: error_rate > 60%
```

**Solution 2: Increase Duration**
```
Change: For at least 1 minute
To: For at least 2 minutes
```

### **Alert Doesn't Clear**

**Check Auto-Clear Settings:**
- Ensure auto-clear is enabled
- Condition: error_rate < 40% for 1 minute
- Verify error rate actually dropped below threshold

---

## 📝 Alert Configuration Summary

**Quick Reference:**

| Setting | Value |
|---------|-------|
| **Alert Name** | Backend Service - High Error Rate |
| **Metric** | APM Error Rate or spans.count |
| **Service** | apm-test-app |
| **Threshold** | > 40% |
| **Duration** | 1 minute |
| **Severity** | Critical |
| **Auto-Clear** | < 40% for 1 minute |
| **Notification** | Email (optional) |

---

## 🎯 Success Criteria

After configuration, you should have:

- ✅ Detector created and active
- ✅ Alert fires when error rate > 40%
- ✅ Alert tested with error endpoint or pod deletion
- ✅ Alert visible in Splunk UI with red status
- ✅ Alert clears when error rate normalizes
- ✅ Integrated into demo script

---

## 📚 Additional Resources

**Splunk Documentation:**
- Detector Documentation: https://docs.splunk.com/observability
- APM Detectors: https://docs.splunk.com/observability/apm/alerts-detectors
- Alert Conditions: https://docs.splunk.com/observability/alerts-detectors

**Related Demo Files:**
- Demo Script: `/documentation/LIVE_DEMO_SCRIPT.md`
- Alert Test Script: `/scripts/test-alert.sh`
- Fault Injection Script: `/scripts/inject-fault.sh`

---

**Good luck with your alert configuration!** 🚀

If the alert doesn't fire during testing, don't worry - you can still demonstrate the concept in your demo by saying "in production, this alert would have fired."
