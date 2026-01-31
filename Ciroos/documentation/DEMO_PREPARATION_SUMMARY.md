# Demo Preparation - Complete Guide

**Created:** January 31, 2026
**Demo Date:** Saturday, January 30, 2026
**Status:** ✅ All materials ready

---

## What You Need to Demonstrate

Based on the Ciroos assignment requirements, you need to show:

1. ✅ **Working application** accessible by end users
2. ✅ **WAF, ALB, and Splunk** operational state
3. ✅ **Security verification** - C1→C2 allowed, no unintended internet exposure
4. ✅ **Fault injection** in the environment
5. ✅ **Fault detection** using Splunk Observability Cloud

---

## Demo Materials Created

### 1. Comprehensive Demo Script

**File:** [LIVE_DEMO_SCRIPT.md](LIVE_DEMO_SCRIPT.md) (20 pages)

**What it contains:**
- Complete 28-minute demo script with timing
- Step-by-step instructions for each requirement
- Browser tabs to pre-load
- Commands to run
- Expected outputs
- Talking points for each section
- Q&A preparation with answers
- Troubleshooting guide

**When to use:**
- Read through this 1 hour before demo
- Keep open during demo for reference
- Use as your primary guide

---

### 2. Quick Reference Card

**File:** [DEMO_QUICK_REFERENCE.md](DEMO_QUICK_REFERENCE.md) (4 pages)

**What it contains:**
- All URLs in one place
- Key commands cheat sheet
- Demo flow timeline
- Success criteria checklist
- Architecture elevator pitch
- Backup plan

**When to use:**
- Print this out or keep on second screen during demo
- Quick lookup for commands and URLs
- Don't need to scroll through 20-page script

---

### 3. Pre-Demo Health Check Script

**File:** `/Users/kanu/Desktop/Ciroos/pre-demo-check.sh`

**What it does:**
```bash
# Run this 30 minutes before demo
./pre-demo-check.sh
```

**Checks:**
- [x] AWS credentials valid
- [x] Both EKS clusters accessible
- [x] All application pods running (4 total: 2 in C1, 2 in C2)
- [x] All OTel collector pods running (6 total: 3 per cluster)
- [x] Load balancers provisioned and healthy
- [x] Application endpoints responding (HTTP 200)
- [x] Cross-region C1→C2 communication working
- [x] Response contains data from both clusters

**Output:**
- Green ✓ for passing checks
- Red ✗ for failing checks
- Final summary: "ALL SYSTEMS GO!" or "SOME CHECKS FAILED"

**When to use:**
- **MUST RUN** 30 minutes before demo
- If any failures, gives you time to fix
- Verifies everything is working before you start

---

### 4. Fault Injection Script

**File:** `/Users/kanu/Desktop/Ciroos/inject-fault.sh`

**What it does:**
```bash
# Run during demo Part 4
./inject-fault.sh
```

**Actions:**
- Deletes apm-backend-app pod in C2 cluster
- Simulates real-world service failure
- Kubernetes auto-recovers in 10-15 seconds
- Gives you live fault to demonstrate in Splunk

**When to use:**
- Demo Part 4: Fault Injection (minute 15-20)
- Follow the script exactly
- Wait for prompt before executing

---

### 5. Architecture Diagrams (3 Formats)

**Files:**
- `architecture-diagram.drawio` - Import into Lucid Chart
- `architecture-diagram.md` - Text specification for manual creation
- `architecture-diagram.mermaid` - Renderable diagram code

**When to use:**
- Show at beginning of demo (Part 1)
- Reference throughout when explaining architecture
- Use to explain cross-region communication

---

### 6. Complete Documentation Suite

**Files in `/Users/kanu/Desktop/Ciroos/deliverables/`:**

1. **APM_COMPLETE_SETUP_DOCUMENTATION.md**
   - Complete APM setup
   - All endpoints documented
   - Cross-region architecture
   - Distributed tracing explanation

2. **OTEL_COLLECTOR_COMPARISON.md**
   - Why custom OTel collector didn't work
   - Why Splunk official collector worked
   - Technical deep dive

3. **APPLICATION_SELECTION.md**
   - Pet Clinic deployment attempts
   - Why we pivoted to custom apps
   - Technical trade-offs

4. **ENDPOINT_TESTING_GUIDE.md**
   - All endpoint URLs
   - Testing procedures
   - Expected responses

5. **LIVE_DEMO_SCRIPT.md** (NEW)
   - Your main demo script

6. **DEMO_QUICK_REFERENCE.md** (NEW)
   - Quick reference card

7. **DEMO_PREPARATION_SUMMARY.md** (THIS FILE)
   - Overview of all materials

---

## 30-Minute Pre-Demo Checklist

### Step 1: Run Health Check (5 minutes)

```bash
cd /Users/kanu/Desktop/Ciroos
./pre-demo-check.sh
```

**Expected result:** "ALL SYSTEMS GO!"

**If failures:**
- Check pod status: `kubectl get pods -n petclinic`
- Check logs: `kubectl logs -n petclinic <pod-name>`
- Restart deployment if needed: `kubectl rollout restart deployment -n petclinic <deployment-name>`

---

### Step 2: Verify Splunk Data (5 minutes)

1. **Login to Splunk:**
   - URL: https://app.us1.signalfx.com/
   - Username: <your-email>
   - Password: <your-password>

2. **Check Kubernetes Navigator:**
   - Infrastructure → Kubernetes Navigator
   - Should see clusters: `petclinic-c1` and `petclinic-c2`
   - All pods green/healthy

3. **Check APM Service Map:**
   - APM → Service Map
   - Should see: `apm-test-app` → `apm-backend-service`
   - Connection between them with metrics

4. **Check recent traces:**
   - APM → Traces
   - Filter: Last 15 minutes
   - Should see traces from both services

**If no data:**
- Check OTel collector pods: `kubectl get pods -n splunk-monitoring`
- Check collector logs: `kubectl logs -n splunk-monitoring <pod-name>`
- Verify access token hasn't expired

---

### Step 3: Test All Endpoints (5 minutes)

**C1 Frontend URL:**
```
http://a9dd2c5fde37e4c6abd04a564ea3ef95-a64aa6c61219d593.elb.us-east-1.amazonaws.com
```

**Test each endpoint:**
```bash
# Health check
curl http://<C1-URL>/health

# Users (local C1)
curl http://<C1-URL>/api/users

# Orders (cross-region to C2)
curl http://<C1-URL>/api/orders

# Checkout (cross-region to C2 payment)
curl http://<C1-URL>/api/checkout

# Slow endpoint
curl http://<C1-URL>/api/slow

# Error endpoint
curl http://<C1-URL>/api/error
```

**All should return valid JSON** (except /api/slow which is slow, and /api/checkout which may fail 20% of the time)

---

### Step 4: Open Browser Tabs (5 minutes)

Open these in separate tabs and arrange them:

1. **Application Frontend**
   ```
   http://a9dd2c5fde37e4c6abd04a564ea3ef95-a64aa6c61219d593.elb.us-east-1.amazonaws.com/health
   ```

2. **AWS WAF Console**
   ```
   https://console.aws.amazon.com/wafv2/homev2/web-acls?region=us-east-1
   ```
   - Login to AWS Console
   - Navigate to WAF & Shield → Web ACLs
   - Select Region: US East (N. Virginia)

3. **AWS Load Balancers**
   ```
   https://console.aws.amazon.com/ec2/v2/home?region=us-east-1#LoadBalancers:
   ```
   - Should show your ALB

4. **Splunk Kubernetes Navigator**
   ```
   https://app.us1.signalfx.com/
   ```
   - Navigate to: Infrastructure → Kubernetes Navigator
   - Filter: `k8s.cluster.name` = `petclinic-c1`

5. **Splunk APM Service Map**
   ```
   https://app.us1.signalfx.com/apm
   ```
   - Should show service map with both services

6. **Terminal Window**
   - Configure kubectl for C1:
     ```bash
     aws eks update-kubeconfig --region us-east-1 --name petclinic-c1
     ```

---

### Step 5: Prepare Terminal (5 minutes)

**Open 2 terminal windows:**

**Terminal 1:** Demo commands
```bash
# Set to C1 cluster
aws eks update-kubeconfig --region us-east-1 --name petclinic-c1

# Verify
kubectl get pods -n petclinic
kubectl get pods -n splunk-monitoring

# Have security verification ready
cd /Users/kanu/Desktop/Ciroos/security-verification
```

**Terminal 2:** Fault injection
```bash
cd /Users/kanu/Desktop/Ciroos

# Test the script (don't run yet, just verify it's ready)
ls -la inject-fault.sh
# Should show: -rwxr-xr-x (executable)
```

---

### Step 6: Review Demo Script (5 minutes)

**Read through:**
- [LIVE_DEMO_SCRIPT.md](LIVE_DEMO_SCRIPT.md) - Sections 1-6
- Focus on talking points
- Practice the Ciroos value proposition (Part 6)

**Print or open on second screen:**
- [DEMO_QUICK_REFERENCE.md](DEMO_QUICK_REFERENCE.md)

---

## During Demo - Step by Step

### Part 1: Working Application (5 min)

**Show:**
1. Architecture diagram
2. Frontend /health endpoint (Browser Tab 1)
3. /api/orders endpoint (shows cross-region data)

**Key point:** "Frontend in C1 successfully calling backend in C2 over VPC peering"

---

### Part 2: WAF, ALB, Splunk (5 min)

**Show:**
1. AWS WAF rules (Browser Tab 2)
2. ALB health and monitoring (Browser Tab 3)
3. Splunk Kubernetes Navigator (Browser Tab 4)
4. Splunk APM Service Map (Browser Tab 5)

**Key point:** "All security controls and monitoring in place and operational"

---

### Part 3: Security Verification (5 min)

**Run:**
```bash
cd /Users/kanu/Desktop/Ciroos/security-verification
python3 verify_security.py
```

**Show:**
- All 6 checks passing
- C2 not accessible from internet
- C1→C2 communication working

**Key point:** "Automated verification proves security controls are effective"

---

### Part 4: Fault Injection (5 min)

**Run:**
```bash
cd /Users/kanu/Desktop/Ciroos
./inject-fault.sh
```

**Show:**
- Pod deletion
- Application errors in browser (HTTP 503)
- Pod auto-recovery
- Service restoration

**Key point:** "Simulated real-world service failure with Kubernetes auto-healing"

---

### Part 5: Fault Detection in Splunk (5 min)

**Show in Splunk:**
1. Error rate spike in APM (Browser Tab 5)
2. Individual error traces
3. Service map showing degraded state
4. Infrastructure showing pod termination (Browser Tab 4)

**Key point:** "Splunk immediately detected the fault across APM and infrastructure"

---

### Part 6: Ciroos Value (3 min)

**Talking points:**
- Manual investigation: 5+ minutes across tools
- With Ciroos: 10 seconds to root cause
- AI-driven correlation across APM, K8s, VPC, CloudWatch
- Your observability setup makes Ciroos even more powerful

**Key point:** "Ciroos automates exactly what we just did manually"

---

## Emergency Backup Plans

### If Application is Down

**Use:**
- Screenshots from testing
- Walk through expected behavior
- Focus on architecture and design decisions

### If Splunk Not Showing Data

**Use:**
- Show OTel collector logs proving data export
- Explain what SHOULD be visible
- Focus on architecture and instrumentation

### If Demo Environment Completely Broken

**Use:**
- Architecture diagram as primary visual
- Documentation to show what was built
- Code walkthrough of Terraform and K8s manifests
- Emphasize learning and problem-solving approach

**Remember:** Explaining your technical decisions and trade-offs is more valuable than perfect execution!

---

## After Demo - Cleanup (Optional)

If you want to tear down the environment:

```bash
# Delete applications
kubectl delete namespace petclinic --context=C1
kubectl delete namespace petclinic --context=C2

# Uninstall OTel collectors
helm uninstall splunk-otel-collector -n splunk-monitoring --context=C1
helm uninstall splunk-otel-collector -n splunk-monitoring --context=C2

# Destroy infrastructure
cd /Users/kanu/Desktop/Ciroos/ciroos-demo-infra
terraform destroy -auto-approve
```

**Cost:** ~$400/month if you leave it running

---

## Files Summary

### In `/Users/kanu/Desktop/Ciroos/deliverables/`

| File | Size | Purpose |
|------|------|---------|
| LIVE_DEMO_SCRIPT.md | 20 pages | Main demo script |
| DEMO_QUICK_REFERENCE.md | 4 pages | Quick reference card |
| DEMO_PREPARATION_SUMMARY.md | This file | Overview |
| APM_COMPLETE_SETUP_DOCUMENTATION.md | 18 pages | APM setup docs |
| OTEL_COLLECTOR_COMPARISON.md | 15 pages | OTel comparison |
| APPLICATION_SELECTION.md | 8 pages | App selection rationale |
| ENDPOINT_TESTING_GUIDE.md | 6 pages | Testing guide |
| architecture-diagram.drawio | - | Lucid Chart import |
| architecture-diagram.md | 12 pages | Diagram specification |
| architecture-diagram.mermaid | - | Mermaid diagram |

### In `/Users/kanu/Desktop/Ciroos/`

| File | Purpose |
|------|---------|
| pre-demo-check.sh | Health check script (run before demo) |
| inject-fault.sh | Fault injection script (run during demo) |

### In `/Users/kanu/Desktop/Ciroos/security-verification/`

| File | Purpose |
|------|---------|
| verify_security.py | Security verification tool (run during demo) |

---

## Success Criteria

At the end of the demo, you will have demonstrated:

- ✅ Working multi-region application with cross-region communication
- ✅ WAF, ALB, and Splunk all operational and visible
- ✅ Security verification proving C1→C2 allowed, C2 not internet-exposed
- ✅ Live fault injection with user-visible impact
- ✅ Splunk detecting and visualizing the fault
- ✅ Clear articulation of Ciroos value proposition

---

## Final Checklist - 5 Minutes Before Demo

- [ ] Pre-demo health check passed (all green)
- [ ] All browser tabs open and loaded
- [ ] Splunk showing live data from both clusters
- [ ] Application endpoints responding (tested in last 5 min)
- [ ] Terminal ready with kubectl configured
- [ ] inject-fault.sh ready to execute
- [ ] Architecture diagram visible
- [ ] Quick reference card open/printed
- [ ] Water nearby
- [ ] Phone on silent
- [ ] Screen sharing ready (if remote)
- [ ] Deep breath taken 😊

---

## You're Ready! 🚀

You've built an impressive multi-region architecture with:
- Private cross-region connectivity
- Comprehensive security controls
- Full observability stack
- Automated verification tools
- Professional documentation

**Trust your preparation. Speak confidently. You've got this!** 💪

---

## Questions?

If you need to clarify anything about the demo:

1. **Check LIVE_DEMO_SCRIPT.md** - Most detailed walkthrough
2. **Check DEMO_QUICK_REFERENCE.md** - Quick answers
3. **Check APM_COMPLETE_SETUP_DOCUMENTATION.md** - Technical deep dive

All the information you need is in these documents!

Good luck! 🍀
