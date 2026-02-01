# Ciroos Multi-Region AWS Infrastructure Demo
## Production-Grade Cloud Architecture with AI-Powered Observability

**Presenter:** Kanu
**Date:** February 1, 2026
**Duration:** 25 minutes
**Status:** ✅ Production Ready

---

## Quick Access Links

### Live Application & Monitoring
- **Frontend Application:** http://a9dd2c5fde37e4c6abd04a564ea3ef95-a64aa6c61219d593.elb.us-east-1.amazonaws.com
- **Splunk Observability:** https://app.us1.signalfx.com/
- **Splunk APM:** https://app.us1.signalfx.com/apm
- **Splunk Alerts:** https://app.us1.signalfx.com/ → Alerts & Detectors
- **Webhook Monitor:** https://webhook.site/d1ebc87a-cc67-4f20-aad2-920443514976

### AWS Console
- **WAF Console:** https://console.aws.amazon.com/wafv2/homev2/web-acls?region=us-east-1
- **Load Balancers:** https://console.aws.amazon.com/ec2/v2/home?region=us-east-1#LoadBalancers

### GitHub Repository
- **Project Code:** https://github.com/kk174/Ciroos

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                         INTERNET                                 │
│                            │                                      │
│                            ▼                                      │
│                    ┌──────────────┐                              │
│                    │   AWS WAF    │                              │
│                    │  (Regional)  │                              │
│                    └──────┬───────┘                              │
│                           │                                       │
│                           ▼                                       │
└──────────────────────────────────────────────────────────────────┘
           ┌───────────────────────────────────────────┐
           │   Region: us-east-1 (Virginia)            │
           │   ┌─────────────────────────────────────┐ │
           │   │  VPC C1: 10.0.0.0/16                │ │
           │   │  ┌─────────────────┐                │ │
           │   │  │ Application LB  │ (Public)       │ │
           │   │  │ (Internet-facing)│               │ │
           │   │  └────────┬────────┘                │ │
           │   │           │                          │ │
           │   │           ▼                          │ │
           │   │  ┌─────────────────┐                │ │
           │   │  │ apm-test-app    │                │ │
           │   │  │ Python Flask    │                │ │
           │   │  │ Frontend Service│                │ │
           │   │  └────────┬────────┘                │ │
           │   │           │                          │ │
           │   │           │ OTel Traces              │ │
           │   │           ▼                          │ │
           │   │  ┌─────────────────┐                │ │
           │   │  │ Splunk OTel     │                │ │
           │   │  │ Collector       │                │ │
           │   │  └─────────────────┘                │ │
           │   └─────────────────────────────────────┘ │
           └──────────────┬────────────────────────────┘
                          │
                          │ VPC Peering
                          │ (Private AWS Network)
                          │ 50-60ms latency
                          │
           ┌──────────────▼────────────────────────────┐
           │   Region: us-west-2 (Oregon)              │
           │   ┌─────────────────────────────────────┐ │
           │   │  VPC C2: 10.1.0.0/16                │ │
           │   │  ┌─────────────────┐                │ │
           │   │  │ Network LB      │ (Internal)     │ │
           │   │  │ (C1 VPC Only)   │                │ │
           │   │  └────────┬────────┘                │ │
           │   │           │                          │ │
           │   │           ▼                          │ │
           │   │  ┌─────────────────┐                │ │
           │   │  │ apm-backend-app │                │ │
           │   │  │ Python Flask    │                │ │
           │   │  │ Backend Service │                │ │
           │   │  └────────┬────────┘                │ │
           │   │           │                          │ │
           │   │           │ OTel Traces              │ │
           │   │           ▼                          │ │
           │   │  ┌─────────────────┐                │ │
           │   │  │ Splunk OTel     │                │ │
           │   │  │ Collector       │                │ │
           │   │  └─────────────────┘                │ │
           │   └─────────────────────────────────────┘ │
           └──────────────┬────────────────────────────┘
                          │
                          │ SignalFx + OTLP
                          ▼
              ┌────────────────────────┐
              │  Splunk Observability  │
              │  Cloud (us1)           │
              │                        │
              │  • Infrastructure      │
              │  • APM Traces         │
              │  • Service Map        │
              │  • Alerts             │
              └───────────┬────────────┘
                          │
                          │ Alert Webhooks
                          ▼
              ┌────────────────────────┐
              │  Ciroos AI             │
              │  Investigation Platform│
              │                        │
              │  • Root Cause Analysis │
              │  • Cross-domain        │
              │    Correlation         │
              │  • Automated Response  │
              └────────────────────────┘
```

---

## Executive Summary

### What We Built

This demonstration showcases a **production-grade, multi-region AWS infrastructure** that mirrors real-world enterprise deployments. The environment combines:

- **Geographic redundancy** across two AWS regions (Virginia & Oregon)
- **Private cross-region connectivity** using AWS VPC peering
- **Multi-layer security** with WAF, security groups, and network isolation
- **Complete observability** with Splunk Observability Cloud
- **Automated incident detection** with webhook integration to Ciroos AI

### Why It Matters

Modern cloud applications are complex, distributed systems. When incidents occur, engineers spend hours manually investigating across multiple tools, regions, and data sources. **This is exactly the problem Ciroos solves.**

Our infrastructure demonstrates:
- ✅ The complexity of multi-region architectures
- ✅ The challenge of manual incident investigation
- ✅ The value of automated, AI-powered root cause analysis
- ✅ Real-world incident scenarios and recovery patterns

### Key Metrics

| Metric | Value |
|--------|-------|
| **AWS Regions** | 2 (us-east-1, us-west-2) |
| **EKS Clusters** | 2 Kubernetes clusters |
| **Cross-Region Latency** | 50-60ms (private network) |
| **Auto-Recovery Time** | 30-40 seconds |
| **Observability Platform** | Splunk Observability Cloud |
| **Security Layers** | WAF + Security Groups + VPC Isolation |
| **Monitoring Pods** | 6 OpenTelemetry collectors |

---

## Technical Architecture

### Region 1: us-east-1 (Virginia) - Frontend Cluster

**VPC Configuration:**
- CIDR Block: 10.0.0.0/16
- EKS Cluster: `petclinic-c1`
- Kubernetes Version: 1.30
- Node Count: 2 (t3.medium)

**Application: apm-test-app**
- Technology: Python Flask with OpenTelemetry
- Exposure: Public (internet-facing via ALB)
- Security: Protected by AWS WAF

**Key Endpoints:**
- `/health` - Health check
- `/api/users` - Local database query
- `/api/orders` - **Cross-region call to C2**
- `/api/checkout` - **Cross-region payment processing**
- `/api/error` - Error injection for testing

**Observability:**
- 3 Splunk OpenTelemetry Collector pods
- Real-time metrics and distributed tracing
- Infrastructure monitoring (CPU, memory, network)

---

### Region 2: us-west-2 (Oregon) - Backend Cluster

**VPC Configuration:**
- CIDR Block: 10.1.0.0/16
- EKS Cluster: `petclinic-c2`
- Kubernetes Version: 1.30
- Node Count: 2 (t3.medium)

**Application: apm-backend-app**
- Technology: Python Flask with OpenTelemetry
- Exposure: **Internal only** (no public access)
- Security: Only accepts traffic from C1 VPC (10.0.0.0/16)

**Backend Services:**
- `/api/inventory` - Inventory management
- `/api/shipping` - Shipping calculations
- `/api/payment/process` - Payment processing (20% intentional failure rate for demo)

**Observability:**
- 3 Splunk OpenTelemetry Collector pods
- Same real-time monitoring as C1
- Full distributed tracing visibility

---

### Cross-Region Connectivity

**VPC Peering:**
- Private AWS network connection
- No public internet traversal
- Latency: 50-60ms consistently
- Bandwidth: High throughput

**Security Configuration:**
- C1 → C2 traffic flows over private peering connection
- Security groups restrict C2 to only accept traffic from 10.0.0.0/16
- All traffic encrypted in transit
- Route tables configured for seamless routing

**W3C TraceContext:**
- Distributed tracing propagation across regions
- End-to-end visibility from frontend request to backend response
- Service dependency mapping in Splunk

---

## Security Architecture

### Multi-Layer Security Model

| Layer | Technology | Purpose | Status |
|-------|-----------|---------|--------|
| **1. WAF** | AWS WAF (Regional) | SQL injection, XSS protection | ✅ Active |
| **2. Load Balancer** | ALB (C1) Public, NLB (C2) Internal | Traffic distribution | ✅ Configured |
| **3. Security Groups** | AWS Security Groups | Network access control | ✅ Enforced |
| **4. VPC Isolation** | VPC Peering | Private connectivity | ✅ Verified |
| **5. Network ACLs** | Subnet-level filtering | Defense in depth | ✅ Applied |

### Security Verification

**Automated Security Checks:**
```bash
python3 security-verification/verify_security.py
```

**Results: 12/12 Checks Passed**
1. ✅ C1 security groups allow public HTTP/HTTPS (intended)
2. ✅ C2 security groups restrict to C1 VPC only
3. ✅ C1 load balancer is internet-facing (intended)
4. ✅ C2 load balancer is internal-only
5. ✅ No public IPs on C2 nodes
6. ✅ VPC peering active and routing correctly
7. ✅ C1 → C2 connectivity works
8. ✅ Internet → C2 connectivity blocked
9. ✅ WAF rules applied to C1 ALB
10. ✅ No overly permissive security group rules
11. ✅ Route tables configured correctly
12. ✅ Network isolation verified

---

## Observability & Monitoring

### Splunk Observability Cloud Integration

**What We Monitor:**

**Infrastructure Metrics:**
- CPU utilization (per pod, per node)
- Memory usage and trends
- Network I/O (bytes sent/received)
- Pod counts and health status
- Kubernetes events and state changes

**Application Performance (APM):**
- Request rate (requests per second)
- Error rate (4xx, 5xx errors)
- Latency percentiles (P50, P95, P99)
- Service dependency map
- Individual trace inspection

**Distributed Tracing:**
- End-to-end request flows (C1 → VPC Peering → C2)
- Span timing breakdown
- Error propagation visualization
- Cross-region latency analysis

### Alert Configuration

**Alert 1: High Error Rate (APM)**
```yaml
Name: Backend Service - High Error Rate
Condition: error_rate > 40% for 1 minute
Baseline: 20% (intentional demo failures)
During Fault: 100% (service completely unavailable)
Action: Send webhook to Ciroos AI platform
Status: ✅ Configured and tested
```

**Alert 2: Low Pod Count (Infrastructure)**
```yaml
Name: Low Pod Count - Backend Service
Condition: pod_count < 2 for 30 seconds
Normal State: 2 pods running
During Fault: 1 pod (after deletion)
Action: Send webhook to Ciroos AI platform
Status: ✅ Configured and tested
```

**Webhook Integration:**
- URL: https://webhook.site/d1ebc87a-cc67-4f20-aad2-920443514976
- Format: JSON payload with full incident details
- Purpose: Trigger Ciroos AI automated investigation
- Response Time: < 1 second

---

## Fault Injection & Auto-Recovery Demonstration

### Scenario: Backend Pod Failure

**What We Simulate:**
Deletion of a backend service pod in the Oregon cluster (C2), simulating real-world scenarios such as:
- Out of Memory (OOM) kills
- Node failures
- Application crashes
- Deployment issues

**Execution:**
```bash
cd scripts
./inject-fault-with-traffic.sh
```

This script:
1. Deletes one backend pod in C2
2. Generates high traffic to stress remaining pod
3. Triggers **both** Infrastructure and APM alerts
4. Sends webhooks to Ciroos AI platform

### Timeline of Events

| Time | Event | Impact | Observability |
|------|-------|--------|---------------|
| **T+0s** | Pod deletion command | ⚠️ Fault injected | Infrastructure alert triggered |
| **T+5s** | Error rate spikes | ❌ User-facing errors (100%) | APM shows error spike |
| **T+30s** | Infrastructure alert fires | 🔔 Webhook sent to Ciroos | Ciroos begins investigation |
| **T+30s** | New pod created | 🔄 Kubernetes self-healing starts | Pod state: ContainerCreating |
| **T+40s** | New pod healthy | ✅ Service fully restored | Error rate returns to 20% |
| **T+60s** | APM alert fires | 🔔 Second webhook to Ciroos | Ciroos correlates both alerts |

**Recovery Time: 30-40 seconds** (Fully automated by Kubernetes)

### Kubernetes Self-Healing Process

1. **Detection** - ReplicaSet controller detects mismatch (desired: 2, actual: 1)
2. **Scheduling** - Kubernetes scheduler assigns new pod to available node
3. **Container Creation** - Docker pulls image and starts container
4. **Health Checks** - Readiness probe validates application health
5. **Traffic Routing** - Service load balancer includes new pod
6. **Full Recovery** - Error rate returns to baseline (20%)

### Splunk Visibility During Incident

**Infrastructure View:**
- Pod count: 2 → 1 → 2 (visible in real-time chart)
- Pod lifecycle: Running → Terminating → (new pod) Pending → Running
- Restart count incremented
- Timeline showing exact deletion timestamp

**APM View:**
- Error rate: 20% → 100% → 20% (spike clearly visible)
- Request latency: Normal → Timeout (5000ms) → Normal
- Service map: C2 backend shows red/degraded status
- Individual traces show connection failures

**Distributed Tracing:**
- Failed traces show "Connection refused" errors
- Missing spans from backend service (pod was down)
- Timeout errors (5 second configured timeout)
- Recovery visible when spans return

---

## The Ciroos Value Proposition

### The Manual Investigation Challenge

**Scenario:** Backend pod fails in production

**Without Ciroos (Manual Process):**

1. **Engineer receives alert** (PagerDuty/email) - 1 minute
2. **Logs into Splunk** to check APM dashboard - 2 minutes
3. **Notices error spike**, investigates traces - 5 minutes
4. **Checks Kubernetes Navigator** for infrastructure - 3 minutes
5. **Sees pod count drop**, checks pod logs - 4 minutes
6. **Reviews Kubernetes events** for pod termination - 2 minutes
7. **Checks VPC peering status** (is network down?) - 3 minutes
8. **Reviews recent deployments** (was this a bad deploy?) - 5 minutes
9. **Correlates all data** and identifies root cause - 5 minutes
10. **Verifies recovery** and updates incident ticket - 2 minutes

**Total Time: 30+ minutes**

---

### With Ciroos AI (Automated Process)

**Scenario:** Same backend pod failure

**With Ciroos (Automated Investigation):**

1. **T+30s** - Infrastructure alert fires → Webhook to Ciroos
2. **T+30s** - Ciroos AI begins investigation:
   - Queries Splunk for recent pod events
   - Checks Kubernetes API for pod status
   - Examines recent deployments
   - Reviews VPC peering health
   - Analyzes error traces
3. **T+45s** - Ciroos correlates all data sources
4. **T+60s** - APM alert fires → Second webhook to Ciroos
5. **T+60s** - Ciroos connects both alerts to same incident
6. **T+70s** - Root cause identified and delivered:

```
Root Cause Analysis:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Pod: apm-backend-app-c4648cf69-dr56g
Cluster: petclinic-c2 (us-west-2)
Termination Reason: Manual deletion at 03:45:23 UTC
Impact: 100% error rate for 35 seconds
Recovery: New pod apm-backend-app-c4648cf69-xyz created
Status: RESOLVED - Service fully restored at 03:46:00 UTC

Timeline:
  03:45:23 - Pod deleted
  03:45:28 - Error rate spike detected
  03:45:53 - Infrastructure alert fired
  03:45:58 - New pod healthy and serving traffic
  03:46:23 - APM alert fired (sustained high error rate)

Network: VPC peering healthy ✓
Deployments: No recent changes ✓
Related incidents: None
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**Total Time: 70 seconds** (from first alert to root cause)

**Time Saved: 96%** (30 minutes → 70 seconds)

---

### Business Impact & ROI

**Assumptions:**
- Average incident investigation time: 30 minutes
- Incidents per month: 20
- Average engineer cost: $100/hour
- Team size: 5 engineers

**Manual Process Cost:**
```
20 incidents × 30 minutes × $100/hour = $1,000/month
Annual cost: $12,000
```

**With Ciroos AI:**
```
20 incidents × 1 minute × $100/hour = $33/month
Annual cost: $400
```

**Savings:**
- **Monthly:** $967
- **Annual:** $11,600
- **ROI:** 2,900% (29x return)

**Additional Benefits:**
- Reduced Mean Time To Resolution (MTTR): 96% improvement
- Reduced engineer toil and burnout
- Faster incident response = better customer experience
- Scalable investigation (AI scales, humans don't)
- 24/7 automated monitoring (no sleep required)

---

### Why Our Setup Amplifies Ciroos Value

**Multi-Region Complexity:**
- Our architecture spans 2 regions with private connectivity
- Manual investigation requires checking both regions
- Ciroos correlates data from both regions automatically

**Multiple Data Sources:**
- Splunk APM (application traces)
- Splunk Infrastructure (pod/node metrics)
- Kubernetes API (events, logs)
- AWS CloudWatch (VPC, load balancer)
- Our custom alerts and webhooks

**The More Data, The Better:**
- Deep observability = more context for AI
- Comprehensive instrumentation = better root cause analysis
- Our setup provides ideal data richness for Ciroos

---

## Live Demonstration Flow

### Part 1: Healthy System (5 minutes)

**Show:**
1. **Working Application**
   - Navigate to frontend: http://[ALB-URL]
   - Test `/health` endpoint → Returns healthy status
   - Test `/api/users` → Local query works
   - Test `/api/checkout` → Cross-region call succeeds (80% success rate)

2. **Architecture Review**
   - Show architecture diagram
   - Explain VPC peering connection
   - Explain traffic flow: User → WAF → ALB → C1 App → VPC Peering → C2 Backend

3. **Splunk Observability**
   - Show Kubernetes Navigator with both clusters
   - Show APM Service Map (apm-test-app → apm-backend-service)
   - Show real-time metrics flowing

---

### Part 2: Security Demonstration (5 minutes)

**Show:**
1. **AWS WAF Configuration**
   - AWS Console → WAF → Web ACLs
   - Show AWS Managed Rules (Core Rule Set)
   - Protection against OWASP Top 10

2. **Security Verification Tool**
   ```bash
   cd security-verification
   python3 verify_security.py
   ```
   - Show 12/12 checks passing
   - Highlight: C2 not accessible from internet
   - Highlight: C1→C2 connectivity works privately

3. **Manual Security Test**
   ```bash
   # This FAILS (proves C2 is internal-only)
   curl http://[C2-INTERNAL-LB]/health

   # This SUCCEEDS (proves C1 can reach C2)
   kubectl exec -it [C1-POD] -- curl http://[C2-INTERNAL-LB]/health
   ```

---

### Part 3: Fault Injection (8 minutes)

**Execute:**
```bash
cd scripts
./inject-fault-with-traffic.sh
```

**Demonstrate:**
1. **Script runs** - Shows "Deleting pod..." message
2. **Switch to browser** - Try `/api/checkout` → Shows 503 errors
3. **Switch to Splunk APM** - Show error rate spike (20% → 100%)
4. **Switch to Splunk Infrastructure** - Show pod count drop (2 → 1)
5. **Switch to Webhook Monitor** - Show two webhooks received:
   - Infrastructure Alert: "Pod count below 2"
   - APM Alert: "Error rate above 40%"
6. **Watch recovery** - Pod count returns to 2, errors disappear
7. **Show distributed traces** - Failed traces show "Connection refused"

**Timeline Narration:**
- "At T+0, we deleted the backend pod"
- "At T+30s, Infrastructure alert fired and sent webhook to Ciroos"
- "At T+35s, Kubernetes created a new pod"
- "At T+40s, new pod became healthy and traffic restored"
- "At T+60s, APM alert fired due to sustained error rate"
- "Ciroos received both alerts and correlated them to single incident"

---

### Part 4: Ciroos Value Proposition (5 minutes)

**Explain:**

"What you just saw was our manual investigation:
- We checked the application
- We looked at Splunk APM
- We checked Kubernetes Navigator
- We correlated the pod deletion with the error spike
- We verified recovery

**That took us 5 minutes with preparation and a known scenario.**

In production:
- Engineers don't know what failed beforehand
- They have to check multiple tools, regions, logs
- Average investigation time: 30+ minutes
- Investigations happen at 2 AM during on-call

**With Ciroos:**
- Alert fires → Webhook sent
- Ciroos queries all data sources automatically
- AI correlates infrastructure events with application errors
- Root cause delivered in 60 seconds
- Engineer wakes up to solution, not just an alert

**The demo you saw is simple. Real production is 10x more complex:**
- 50+ microservices instead of 2
- 5+ regions instead of 2
- Multiple cloud providers (AWS + GCP + Azure)
- Hundreds of dependencies
- Thousands of metrics

**Ciroos scales with complexity. Humans don't.**"

---

### Part 5: Q&A Preparation (2 minutes)

**Expected Questions:**

**Q: Why VPC peering instead of Transit Gateway?**
A: For two regions, VPC peering is simpler and has lower latency. Transit Gateway makes sense for 5+ regions or complex routing needs. Our architecture prioritizes simplicity.

**Q: How do you handle database consistency across regions?**
A: Currently, database is only in C1 for demo simplicity. In production, we'd use Aurora Global Database for active-active, or RDS read replicas for active-passive, depending on RTO/RPO requirements.

**Q: What about disaster recovery?**
A: Our architecture is already DR-ready. C2 could be promoted to primary in minutes. Add Route53 health checks and automated failover, and you have full DR capability.

**Q: Security concerns with cross-region traffic?**
A: All traffic flows over private AWS network (VPC peering), never touching public internet. Traffic is encrypted in transit. Security groups enforce strict access control.

**Q: How does this scale?**
A: Kubernetes Horizontal Pod Autoscaler (HPA) scales pods based on CPU/memory. EKS Cluster Autoscaler adds nodes when needed. We can scale from 2 pods to 100+ pods seamlessly.

**Q: Cost of this setup?**
A: Demo environment: ~$400/month (2 small EKS clusters, minimal traffic). Production would be $2-5K/month depending on scale. Savings from faster incident resolution far exceed infrastructure cost.

---

## Technical Specifications

### Infrastructure Components

**EKS Clusters:**
- Version: Kubernetes 1.30
- Node Type: t3.medium
- Nodes per Cluster: 2
- Total Nodes: 4
- CNI: AWS VPC CNI
- Storage: EBS gp3 volumes

**Networking:**
- VPC C1: 10.0.0.0/16 (256 subnets available)
- VPC C2: 10.1.0.0/16 (256 subnets available)
- Subnets: 2 private, 2 public per VPC
- NAT Gateways: 1 per region
- Internet Gateways: 1 per region

**Load Balancers:**
- C1: Application Load Balancer (Layer 7)
- C2: Network Load Balancer (Layer 4)
- Health Checks: HTTP /health every 30 seconds
- Target Type: IP mode (for EKS pods)

**Security:**
- AWS WAF: Regional, attached to C1 ALB
- Security Groups: 4 total (per LB, per node group)
- RBAC: Kubernetes role-based access control
- Secrets: Kubernetes secrets for sensitive data

**Observability:**
- Splunk Realm: us1
- OTel Collector Version: 0.143.0 (Splunk official)
- Exporters: SignalFx (metrics), OTLP (traces)
- Collection Interval: 10 seconds
- Retention: 8 days (Splunk trial)

---

### Application Specifications

**Frontend (apm-test-app):**
```yaml
Language: Python 3.11
Framework: Flask 3.0
Instrumentation: OpenTelemetry Auto-Instrumentation
Deployment:
  Replicas: 2
  CPU Request: 100m
  Memory Request: 128Mi
  CPU Limit: 500m
  Memory Limit: 512Mi
Environment:
  OTEL_SERVICE_NAME: apm-test-app
  OTEL_EXPORTER_OTLP_ENDPOINT: http://splunk-otel-collector:4317
  BACKEND_URL: http://[C2-NLB]:80
```

**Backend (apm-backend-app):**
```yaml
Language: Python 3.11
Framework: Flask 3.0
Instrumentation: OpenTelemetry Auto-Instrumentation
Deployment:
  Replicas: 2
  CPU Request: 100m
  Memory Request: 128Mi
  CPU Limit: 500m
  Memory Limit: 512Mi
Environment:
  OTEL_SERVICE_NAME: apm-backend-service
  OTEL_EXPORTER_OTLP_ENDPOINT: http://splunk-otel-collector:4317
  FAILURE_RATE: "0.20"  # 20% intentional failures
```

---

## Automation & Scripts

### Pre-Demo Health Check
```bash
./scripts/pre-demo-check.sh
```
**Validates:**
- AWS credentials configured
- kubectl access to both clusters
- All pods running in both clusters
- OTel collectors operational
- Frontend and backend endpoints responding
- Cross-region communication working

### Background Traffic Generator
```bash
./scripts/continuous-traffic.sh &
```
**Purpose:** Keeps Splunk populated with baseline metrics
**Behavior:** Sends 5 requests every 5 seconds
**Endpoints:** Randomized across /health, /api/users, /api/orders, /api/checkout

### Fault Injection (Full Demo)
```bash
./scripts/inject-fault-with-traffic.sh
```
**Actions:**
- Deletes one backend pod in C2
- Generates high traffic for 60 seconds
- Triggers both Infrastructure and APM alerts
- Demonstrates webhook integration

**Timeline:**
- T+0s: Pod deleted
- T+30s: Infrastructure alert fires
- T+60s: APM alert fires
- T+40s: Pod recovers automatically

### Security Verification
```bash
cd security-verification
python3 verify_security.py
```
**Checks (12 total):**
- Security group rules (no overly permissive access)
- Load balancer exposure (C1 public, C2 internal)
- Public IP verification (C2 nodes have none)
- VPC peering status (active and routing)
- Connectivity tests (C1→C2 works, Internet→C2 blocked)

---

## Key Learnings & Best Practices

### 1. Observability is Critical
**Lesson:** Without comprehensive metrics and traces, incident investigation is guesswork.
**Implementation:** We instrumented every service with OpenTelemetry, collected infrastructure and application metrics, and enabled distributed tracing.
**Impact:** Full visibility into system behavior enabled fast root cause analysis.

### 2. Automation Saves Time
**Lesson:** Manual health checks and deployments are error-prone and slow.
**Implementation:** Created scripts for common tasks, automated testing, and continuous monitoring.
**Impact:** Pre-demo validation reduced surprises, fault injection became repeatable.

### 3. Test Your Demo Environment
**Lesson:** "It works on my machine" doesn't work for live demos.
**Implementation:** End-to-end testing the night before revealed URL bugs, missing alerts, and empty dashboards.
**Impact:** Confident, smooth demo execution.

### 4. Security by Design
**Lesson:** Security can't be bolted on after deployment.
**Implementation:** Designed network isolation, security groups, and WAF from day one. Created automated verification.
**Impact:** Provable security posture, no last-minute scrambling.

### 5. Simplicity Over Complexity
**Lesson:** Complex architectures are harder to debug and demonstrate.
**Implementation:** Custom Python apps instead of complex microservices (Pet Clinic). VPC peering instead of Transit Gateway.
**Impact:** Faster development, clearer demonstration, easier troubleshooting.

---

## Production Readiness Assessment

### What's Production-Ready ✅

| Component | Status | Notes |
|-----------|--------|-------|
| Infrastructure as Code | ✅ | 100% Terraform, reproducible |
| Multi-Region Architecture | ✅ | VPC peering, tested latency |
| Security Controls | ✅ | WAF, security groups, verified |
| Observability | ✅ | Comprehensive metrics, traces |
| Auto-Healing | ✅ | Kubernetes self-healing tested |
| Documentation | ✅ | Complete guides, procedures |

### What Would Change for Production 🔧

| Component | Current State | Production Recommendation |
|-----------|--------------|--------------------------|
| **Database** | None (demo only) | Aurora Global Database or RDS Multi-AZ |
| **Load Balancers** | Single LB per region | Multi-AZ with health checks |
| **Node Groups** | 2 nodes per cluster | Auto Scaling Groups, 3+ nodes |
| **Secrets** | Kubernetes secrets | AWS Secrets Manager + IRSA |
| **Monitoring** | Splunk trial | Production Splunk license |
| **Backups** | None | Automated snapshots, cross-region replication |
| **CI/CD** | Manual deployment | GitOps with ArgoCD or Flux |
| **Alerting** | 2 alerts | Comprehensive alert rules, escalation |
| **Logging** | OTel only | CloudWatch Logs + centralized logging |
| **Cost** | ~$400/month | $2-5K/month with optimization |

---

## Appendix: Technical Details

### Endpoint Reference

**Frontend (C1) - Public Endpoints:**
```
http://[ALB-URL]/health
http://[ALB-URL]/api/users
http://[ALB-URL]/api/orders
http://[ALB-URL]/api/checkout
http://[ALB-URL]/api/error
```

**Backend (C2) - Internal Only:**
```
http://[NLB-INTERNAL]/api/inventory
http://[NLB-INTERNAL]/api/shipping
http://[NLB-INTERNAL]/api/payment/process
```

### Kubernetes Commands

**Check Cluster Status:**
```bash
# C1 Cluster
aws eks update-kubeconfig --region us-east-1 --name petclinic-c1
kubectl get nodes
kubectl get pods -n petclinic
kubectl get pods -n splunk-monitoring

# C2 Cluster
aws eks update-kubeconfig --region us-west-2 --name petclinic-c2
kubectl get nodes
kubectl get pods -n petclinic
kubectl get pods -n splunk-monitoring
```

**View Logs:**
```bash
kubectl logs -n petclinic [POD-NAME]
kubectl logs -n splunk-monitoring -l app=splunk-otel-collector
```

**Exec into Pod:**
```bash
kubectl exec -it -n petclinic [POD-NAME] -- /bin/bash
```

### Troubleshooting Guide

**Issue: Pods Not Running**
```bash
kubectl get pods -n petclinic
kubectl describe pod -n petclinic [POD-NAME]
kubectl logs -n petclinic [POD-NAME]
```

**Issue: No Splunk Data**
```bash
# Check collector status
kubectl get pods -n splunk-monitoring
kubectl logs -n splunk-monitoring -l app=splunk-otel-collector

# Verify token in Splunk UI
Settings → Access Tokens
```

**Issue: Cross-Region Communication Failed**
```bash
# Check VPC peering
aws ec2 describe-vpc-peering-connections

# Check security groups
aws ec2 describe-security-groups --filters "Name=group-name,Values=*c2*"

# Test from C1 pod
kubectl exec -it -n petclinic [C1-POD] -- curl http://[C2-LB]/health
```

---

## Conclusion

This demonstration proves that **modern cloud infrastructure is complex**, and that complexity creates a real need for **intelligent, automated incident investigation**.

### What We've Shown

✅ **Production-grade multi-region architecture** - Not a toy example, but real-world complexity
✅ **Complete observability** - Infrastructure + Application + Distributed Tracing
✅ **Real incident scenarios** - Pod failures, error spikes, cross-region issues
✅ **Automated detection** - Alerts fire and send webhooks automatically
✅ **Self-healing systems** - Kubernetes recovers, but investigation still needed

### The Ciroos Opportunity

**The Problem:** Engineers spend 30+ minutes manually investigating incidents across multiple tools and data sources.

**The Solution:** Ciroos AI automates investigation, correlates all data sources, and delivers root cause analysis in under 60 seconds.

**The Value:** 96% reduction in MTTR, happier engineers, better customer experience, and measurable ROI.

**This infrastructure is the perfect showcase for Ciroos** - it has all the complexity, all the data sources, and all the real-world challenges that Ciroos is designed to solve.

---

**Thank you for your time!**

**Questions?**

---

**Document Version:** 3.0 (Presentation Edition)
**Last Updated:** February 1, 2026 - 12:30 AM
**Status:** ✅ Demo Ready
**Repository:** https://github.com/kk174/Ciroos
