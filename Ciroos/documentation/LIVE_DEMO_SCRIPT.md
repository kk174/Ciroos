# Ciroos Assignment - Live Demo Script

**Presenter:** Kanu
**Duration:** 20-25 minutes
**Audience:** Ciroos Technical Team
**Date:** Saturday, January 30, 2026

---

## Table of Contents

1. [Pre-Demo Checklist](#pre-demo-checklist)
2. [Demo Part 1: Working Application](#demo-part-1-working-application-5-min)
3. [Demo Part 2: WAF, ALB, and Splunk State](#demo-part-2-waf-alb-and-splunk-state-5-min)
4. [Demo Part 3: Security Verification](#demo-part-3-security-verification-5-min)
5. [Demo Part 4: Fault Injection](#demo-part-4-fault-injection-5-min)
6. [Demo Part 5: Fault Detection in Splunk](#demo-part-5-fault-detection-in-splunk-5-min)
7. [Q&A Preparation](#qa-preparation)

---

## Pre-Demo Checklist

**30 Minutes Before Demo:**

### 1. Verify Infrastructure Status

```bash
# Set AWS credentials
export AWS_ACCESS_KEY_ID=<your-key>
export AWS_SECRET_ACCESS_KEY=<your-secret>
export AWS_DEFAULT_REGION=us-east-1

# Check C1 cluster
aws eks update-kubeconfig --region us-east-1 --name petclinic-c1
kubectl get nodes
kubectl get pods -n petclinic
kubectl get pods -n splunk-monitoring

# Check C2 cluster
aws eks update-kubeconfig --region us-west-2 --name petclinic-c2
kubectl get nodes
kubectl get pods -n petclinic
kubectl get pods -n splunk-monitoring
```

**Expected output:**
- All nodes: Ready
- All pods in petclinic namespace: Running
- All pods in splunk-monitoring namespace: Running (3 pods per cluster)

### 2. Get Application URLs

```bash
# C1 Frontend URL (public)
aws eks update-kubeconfig --region us-east-1 --name petclinic-c1
kubectl get svc -n petclinic apm-test-app -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'

# C2 Backend URL (internal - for verification only)
aws eks update-kubeconfig --region us-west-2 --name petclinic-c2
kubectl get svc -n petclinic apm-backend-app -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
```

**Record these URLs:**
- C1 Frontend: `http://a9dd2c5fde37e4c6abd04a564ea3ef95-a64aa6c61219d593.elb.us-east-1.amazonaws.com`
- C2 Backend: `http://ac3dc550dad9847ea805e20c963ee7ba-39ea100930485fc4.elb.us-west-2.amazonaws.com`

### 3. Pre-load Browser Tabs

Open these URLs in separate browser tabs:

**Tab 1: Application Frontend**
```
http://a9dd2c5fde37e4c6abd04a564ea3ef95-a64aa6c61219d593.elb.us-east-1.amazonaws.com/health
```

**Tab 2: AWS WAF Console**
```
https://console.aws.amazon.com/wafv2/homev2/web-acls?region=us-east-1
```

**Tab 3: AWS Load Balancers Console**
```
https://console.aws.amazon.com/ec2/v2/home?region=us-east-1#LoadBalancers:
```

**Tab 4: Splunk Observability Cloud**
```
https://app.us1.signalfx.com/
```
- Login with your credentials
- Navigate to: Infrastructure → Kubernetes Navigator

**Tab 5: Splunk APM Service Map**
```
https://app.us1.signalfx.com/apm
```

**Tab 6: Terminal Window**
- Ready with kubectl connected to C1 cluster

### 4. Verify Splunk Data

Login to Splunk Observability Cloud and confirm:
- [ ] Kubernetes Navigator shows both clusters (petclinic-c1, petclinic-c2)
- [ ] APM Service Map shows both services (apm-test-app, apm-backend-service)
- [ ] Metrics are flowing (check last 5 minutes)

### 5. Prepare Fault Injection Scripts

Save this script as `inject-fault.sh`:

```bash
#!/bin/bash
# inject-fault.sh - Kill backend pod to simulate failure

echo "Injecting fault: Deleting apm-backend-app pod in C2..."

aws eks update-kubeconfig --region us-west-2 --name petclinic-c2

POD_NAME=$(kubectl get pods -n petclinic -l app=apm-backend-app -o jsonpath='{.items[0].metadata.name}')

echo "Deleting pod: $POD_NAME"
kubectl delete pod -n petclinic $POD_NAME

echo "Fault injected! Pod is being recreated..."
echo "Wait 10-15 seconds for pod restart..."

kubectl get pods -n petclinic -l app=apm-backend-app -w
```

Make it executable:
```bash
chmod +x inject-fault.sh
```

---

## Demo Part 1: Working Application (5 min)

### Opening Statement

> "Good morning/afternoon! I'm going to demonstrate a multi-region AWS EKS architecture with cross-region communication, security controls, and observability using Splunk Observability Cloud. This is a production-like setup across two AWS regions with private connectivity, WAF protection, and distributed tracing."

### 1.1 Show Architecture Diagram

**Action:** Display the architecture diagram (from Lucid Chart or exported image)

**Talking Points:**
- "We have two EKS clusters across us-east-1 and us-west-2"
- "C1 in us-east-1 hosts the frontend service, publicly accessible through an ALB protected by AWS WAF"
- "C2 in us-west-2 hosts backend services, only accessible internally via VPC peering"
- "Both clusters send telemetry to Splunk Observability Cloud using OpenTelemetry collectors"

### 1.2 Access the Application

**Action:** Switch to Browser Tab 1 (Frontend Health)

**URL:**
```
http://a9dd2c5fde37e4c6abd04a564ea3ef95-a64aa6c61219d593.elb.us-east-1.amazonaws.com/health
```

**Expected Response:**
```json
{
  "status": "healthy",
  "service": "apm-test-app",
  "cluster": "C1",
  "region": "us-east-1"
}
```

**Talking Points:**
- "This is the frontend application running in C1, accessible to end users"
- "It's a Python Flask app instrumented with OpenTelemetry for distributed tracing"

### 1.3 Test Cross-Region Communication

**Action:** Test the /api/orders endpoint (which calls C2)

**URL:**
```
http://a9dd2c5fde37e4c6abd04a564ea3ef95-a64aa6c61219d593.elb.us-east-1.amazonaws.com/api/orders
```

**Expected Response:**
```json
{
  "orders": [
    {"id": 1, "total": 245},
    {"id": 2, "total": 123},
    ...
  ],
  "count": 5,
  "inventory": {
    "items": [...],
    "cluster": "C2"
  },
  "shipping": {
    "shipping_options": [...],
    "cluster": "C2"
  },
  "cluster": "C1"
}
```

**Talking Points:**
- "Notice the response includes data from both clusters"
- "The frontend in C1 made cross-region API calls to the backend in C2"
- "You can see 'cluster: C2' in the inventory and shipping sections"
- "This demonstrates successful private communication over VPC peering"

### 1.4 Show All Available Endpoints

**Action:** Navigate to each endpoint and show responses

**Endpoints to demonstrate:**

1. **Users API** (local to C1):
   ```
   /api/users
   ```
   Shows: Local database query in C1

2. **Checkout API** (calls C2 payment service):
   ```
   /api/checkout
   ```
   Shows: Cross-region payment processing with 20% intentional failure rate

3. **Slow Endpoint** (performance testing):
   ```
   /api/slow
   ```
   Shows: Intentionally slow operation for latency testing

---

## Demo Part 2: WAF, ALB, and Splunk State (5 min)

### 2.1 AWS WAF Status

**Action:** Switch to Browser Tab 2 (AWS WAF Console)

**Steps:**
1. Navigate to WAF & Shield → Web ACLs
2. Select Region: **US East (N. Virginia)**
3. Click on the WAF ACL: **petclinic-waf**

**Show:**
- Associated resource: Application Load Balancer (petclinic-c1-alb)
- Rules configured:
  - AWS Managed Rules - Core Rule Set (CRS)
  - Default action: Allow
- Sampled requests (if available)

**Talking Points:**
- "The WAF is protecting our public-facing ALB in C1"
- "We're using AWS Managed Rules for common web exploits (SQL injection, XSS, etc.)"
- "This provides a security layer before traffic reaches our application"
- "In production, we'd add custom rules for rate limiting and geo-blocking"

### 2.2 Application Load Balancer Status

**Action:** Switch to Browser Tab 3 (Load Balancers Console)

**Steps:**
1. In EC2 → Load Balancers
2. Find the ALB with DNS name matching C1 frontend URL
3. Click to view details

**Show:**
- **State:** Active
- **Scheme:** Internet-facing
- **Availability Zones:** Multiple AZs in us-east-1
- **Security Groups:** Shows allowed traffic

**Click on "Monitoring" tab:**
- Show request count graphs
- Active connection count
- Target health status (should be "healthy")

**Talking Points:**
- "This is our internet-facing load balancer in C1"
- "It's distributing traffic across multiple availability zones for high availability"
- "All targets are healthy, indicating our application pods are responding"

### 2.3 Splunk Infrastructure Monitoring

**Action:** Switch to Browser Tab 4 (Splunk Kubernetes Navigator)

**Steps:**
1. Go to: Infrastructure → Kubernetes Navigator
2. Filter by cluster: **petclinic-c1**

**Show:**

**Cluster Overview:**
- Cluster name: petclinic-c1
- Nodes: 2 (both healthy)
- Namespaces: petclinic, splunk-monitoring, kube-system
- Pods running: Show count

**Click into petclinic namespace:**
- Show pod status (all green)
- CPU and memory utilization
- Network traffic metrics

**Switch to C2 cluster:**
- Filter by cluster: **petclinic-c2**
- Show same health metrics
- Point out internal-only configuration (no public IPs)

**Talking Points:**
- "Splunk is receiving infrastructure metrics from both clusters"
- "We can see real-time CPU, memory, and network utilization"
- "Notice both clusters are reporting healthy status"
- "This is using the Splunk official OpenTelemetry collector with SignalFx exporter"

### 2.4 Splunk APM and Service Map

**Action:** Switch to Browser Tab 5 (Splunk APM)

**Steps:**
1. Go to: APM → Service Map
2. Time range: Last 15 minutes

**Show:**

**Service Map:**
- Should show two services:
  - **apm-test-app** (in C1)
  - **apm-backend-service** (in C2)
- Arrows showing request flow from apm-test-app → apm-backend-service

**Click on a service:**
- Show service details:
  - Request rate
  - Error rate
  - Latency percentiles (P50, P95, P99)
  - Throughput

**Click on a trace:**
- Show distributed trace spanning both services
- Highlight:
  - Trace starts in apm-test-app (C1)
  - Spans continue to apm-backend-service (C2)
  - Total duration
  - Individual span durations

**Talking Points:**
- "Here's the service dependency map showing cross-region communication"
- "You can see requests flowing from C1 frontend to C2 backend"
- "This is using W3C TraceContext propagation for distributed tracing"
- "We can drill into individual traces to see the entire request journey across regions"
- "Notice the latency breakdown - you can see network time between regions"

---

## Demo Part 3: Security Verification (5 min)

### 3.1 Run Python Security Verification Tool

**Action:** Switch to Terminal Window

**Steps:**

```bash
cd /Users/kanu/Desktop/Ciroos/security-verification

# Run security verification
python3 verify_security.py

# Wait for completion (30-60 seconds)
```

**Expected Output:**

```
=================================================================
           AWS Multi-Region Security Verification
=================================================================

Region: us-east-1 (C1)
Region: us-west-2 (C2)

-----------------------------------------------------------------
[1/6] Checking Security Groups...
-----------------------------------------------------------------
✓ Security group sg-0xxxxx (C1): Public access allowed (intended)
✓ Security group sg-0xxxxx (C2): Restricted to C1 VPC only (10.0.0.0/16)
! No overly permissive rules found

-----------------------------------------------------------------
[2/6] Checking Load Balancers...
-----------------------------------------------------------------
✓ C1 ALB: Internet-facing (intended for frontend)
✓ C2 NLB: Internal-only (private backend)
! C2 backend not exposed to internet

-----------------------------------------------------------------
[3/6] Checking Public IPs...
-----------------------------------------------------------------
✓ C1 EKS nodes: No public IPs (NAT gateway used)
✓ C2 EKS nodes: No public IPs (NAT gateway used)
✓ C2 backend service: No public exposure
! All services properly isolated

-----------------------------------------------------------------
[4/6] Checking VPC Peering...
-----------------------------------------------------------------
✓ VPC Peering: Active
✓ Connection ID: pcx-xxxxx
✓ Route tables: Configured correctly
✓ CIDR blocks: 10.0.0.0/16 ↔ 10.1.0.0/16

-----------------------------------------------------------------
[5/6] Testing C1 → C2 Connectivity...
-----------------------------------------------------------------
✓ C1 can reach C2 backend (HTTP 200)
✓ Response time: 45ms
✓ Cross-region communication working

-----------------------------------------------------------------
[6/6] Testing Internet → C2 Connectivity...
-----------------------------------------------------------------
✓ C2 backend NOT accessible from internet (as intended)
✓ Connection timeout (expected behavior)
! C2 properly secured

=================================================================
                      VERIFICATION SUMMARY
=================================================================

Total Checks: 6
Passed: 6
Failed: 0
Warnings: 0

Security Status: ✓ PASSED

Key Findings:
✓ Only C1 frontend is internet-accessible
✓ C2 backend restricted to C1 VPC traffic only
✓ VPC peering operational for private cross-region communication
✓ No unintended public exposure
✓ All security controls functioning as designed

=================================================================
```

**Talking Points:**
- "I've built a Python verification tool using boto3 and kubernetes libraries"
- "It performs 6 security checks across both regions"
- "Key validation: Only C1 is internet-accessible, C2 is completely private"
- "VPC peering is working correctly for cross-region communication"
- "No security misconfigurations detected"

### 3.2 Manual Security Verification

**Action:** Show manual checks to reinforce automated results

**Check 1: Attempt to access C2 backend from internet**

```bash
# This should FAIL (timeout or connection refused)
curl -m 10 http://ac3dc550dad9847ea805e20c963ee7ba-39ea100930485fc4.elb.us-west-2.amazonaws.com/health
```

**Expected:** Connection timeout or "Could not resolve host"

**Talking Points:**
- "As you can see, the C2 backend is not accessible from the internet"
- "This is by design - it's an internal-only load balancer"

**Check 2: Verify C1 can reach C2 internally**

```bash
# Switch to C1 cluster
aws eks update-kubeconfig --region us-east-1 --name petclinic-c1

# Exec into C1 pod
POD_NAME=$(kubectl get pods -n petclinic -l app=apm-test-app -o jsonpath='{.items[0].metadata.name}')

kubectl exec -it -n petclinic $POD_NAME -- curl -s http://ac3dc550dad9847ea805e20c963ee7ba-39ea100930485fc4.elb.us-west-2.amazonaws.com/health
```

**Expected:**
```json
{
  "status": "healthy",
  "service": "apm-backend-service",
  "cluster": "C2",
  "region": "us-west-2"
}
```

**Talking Points:**
- "From inside the C1 cluster, we CAN reach C2"
- "This proves VPC peering is working correctly"
- "Traffic flows privately through AWS backbone, not the internet"

### 3.3 Review Security Group Rules

**Action:** Show security group configuration in AWS Console

```bash
# Get C2 backend security group ID
aws eks update-kubeconfig --region us-west-2 --name petclinic-c2

aws ec2 describe-security-groups \
  --region us-west-2 \
  --filters "Name=group-name,Values=petclinic-c2-backend-sg" \
  --query 'SecurityGroups[0].IpPermissions' \
  --output table
```

**Expected Output:**
```
--------------------------------------------------------------
|                    IpPermissions                           |
+------------+----------------+----------+-------------------+
| FromPort   | IpProtocol     | ToPort   | IpRanges          |
+------------+----------------+----------+-------------------+
| 80         | tcp            | 80       | 10.0.0.0/16       |
| 443        | tcp            | 443      | 10.0.0.0/16       |
+------------+----------------+----------+-------------------+
```

**Talking Points:**
- "The security group only allows traffic from C1's VPC CIDR (10.0.0.0/16)"
- "No 0.0.0.0/0 rules that would allow internet access"
- "This is least-privilege access control"

---

## Demo Part 4: Fault Injection (5 min)

### 4.1 Show Current Healthy State

**Action:** Before injecting fault, establish baseline

**Browser Tab 1:** Navigate to /api/checkout endpoint
```
http://a9dd2c5fde37e4c6abd04a564ea3ef95-a64aa6c61219d593.elb.us-east-1.amazonaws.com/api/checkout
```

**Refresh 3-4 times** to show:
- Some requests succeed (HTTP 200)
- Some requests fail with payment declined (HTTP 402) - this is the 20% failure rate
- Response includes C2 data

**Browser Tab 5:** Show Splunk APM Service Map
- Both services green
- Error rate: ~20% (expected due to simulated payment failures)
- Latency: Normal range (50-100ms)

### 4.2 Inject Fault - Delete C2 Backend Pod

**Action:** Switch to Terminal

**Run fault injection script:**

```bash
# Make sure you're in the right directory
cd /Users/kanu/Desktop/Ciroos

# Run the fault injection script
./inject-fault.sh
```

**Expected Output:**
```
Injecting fault: Deleting apm-backend-app pod in C2...
Deleting pod: apm-backend-app-7d8f9c5b6d-x9k2m
pod "apm-backend-app-7d8f9c5b6d-x9k2m" deleted
Fault injected! Pod is being recreated...
Wait 10-15 seconds for pod restart...

NAME                                 READY   STATUS        RESTARTS   AGE
apm-backend-app-7d8f9c5b6d-x9k2m     0/1     Terminating   0          25m
apm-backend-app-7d8f9c5b6d-n7k5p     0/1     Pending       0          0s
apm-backend-app-7d8f9c5b6d-n7k5p     0/1     ContainerCreating   0     2s
apm-backend-app-7d8f9c5b6d-n7k5p     1/1     Running             0     15s
```

**Talking Points:**
- "I'm simulating a pod failure in the C2 backend cluster"
- "This could happen in real life due to OOM kill, node failure, or deployment issues"
- "Kubernetes will automatically recreate the pod, but there will be a 10-15 second outage"

### 4.3 Observe Failure in Application

**Action:** Immediately switch to Browser Tab 1

**Try /api/checkout endpoint multiple times:**
```
http://a9dd2c5fde37e4c6abd04a564ea3ef95-a64aa6c61219d593.elb.us-east-1.amazonaws.com/api/checkout
```

**During the fault window (10-15 seconds), expected responses:**

```json
{
  "error": "Payment service unavailable"
}
```

**HTTP Status:** 503 Service Unavailable

**Talking Points:**
- "You can see the application is now returning 503 errors"
- "The frontend in C1 can't reach the backend in C2 because the pod is down"
- "This is a real user-facing outage"

### 4.4 Observe Recovery

**Action:** Keep refreshing /api/checkout

**After 10-15 seconds, responses return to normal:**
```json
{
  "status": "success",
  "order_id": "order_34567",
  "payment": {
    "status": "success",
    "transaction_id": "tx_45678",
    "cluster": "C2"
  },
  "cluster": "C1"
}
```

**Talking Points:**
- "The service is now recovering"
- "Kubernetes has automatically recreated the pod"
- "This demonstrates the self-healing capabilities of Kubernetes"

---

## Demo Part 5: Fault Detection in Splunk (5 min)

### 5.1 Show Error Spike in APM

**Action:** Switch to Browser Tab 5 (Splunk APM)

**Steps:**
1. Go to APM → Service Map
2. Time range: **Last 15 minutes**
3. Click on **apm-test-app** service

**Show:**
- **Request rate:** Should show normal traffic
- **Error rate:** Spike during fault injection window
  - Normally: ~20% (simulated payment failures)
  - During fault: 100% (service unavailable)
- **Latency:** May show increased P99 latency or timeouts

**Click on "Errors" tab:**
- Filter by time range during fault
- Show error traces:
  - Error type: "Payment service unavailable"
  - HTTP status: 503
  - Timestamp: Matches fault injection time

**Talking Points:**
- "You can clearly see the error rate spike when we deleted the pod"
- "Splunk APM detected the fault immediately"
- "We can drill into individual error traces to see exactly what failed"
- "This would trigger an alert in production"

### 5.2 Show Individual Error Traces

**Action:** Click on one of the error traces

**Show:**
- Trace timeline
- Spans showing:
  - apm-test-app → call_backend_payment span
  - Error: "Connection refused" or "Service unavailable"
  - Duration: Long timeout (5000ms - our configured timeout)
- Missing spans from apm-backend-service (because it was down)

**Talking Points:**
- "This trace shows the exact moment the call to C2 failed"
- "Notice there are no spans from the backend service - it was unreachable"
- "The trace timeout of 5 seconds indicates the pod was completely down"
- "In a real incident, this would be our starting point for investigation"

### 5.3 Show Infrastructure Metrics

**Action:** Switch to Browser Tab 4 (Splunk Kubernetes Navigator)

**Steps:**
1. Go to Infrastructure → Kubernetes Navigator
2. Filter: Cluster = **petclinic-c2**, Namespace = **petclinic**
3. Time range: Last 15 minutes

**Show:**
- Pod count: Should show a dip (2 → 1 → 2) during fault injection
- Click on the pod that was deleted:
  - Status history: Running → Terminating → (new pod) Pending → Running
  - Restart count: May increment

**Talking Points:**
- "The infrastructure monitoring shows the pod lifecycle"
- "You can see the pod was terminated and a new one was created"
- "This correlates with the APM error spike we just saw"
- "Having both APM and infrastructure in the same platform makes root cause analysis much faster"

### 5.4 Show Service Map State Change

**Action:** Go back to APM → Service Map

**Show:**
- During fault window:
  - Red/yellow indicator on apm-backend-service
  - Increased error rate on the connection between services
- After recovery:
  - Services return to green
  - Error rate drops back to baseline (~20%)

**Talking Points:**
- "The service map provides a visual indicator of service health"
- "When the backend went down, it immediately showed as degraded"
- "After recovery, it returned to healthy state"
- "This gives you an at-a-glance view of your entire distributed system"

### 5.5 Demonstrate Alert Configuration (Optional)

**Action:** Show how you would set up alerts

**Steps:**
1. In Splunk, go to Alerts → New Alert
2. Configure:
   - **Metric:** Error rate for apm-test-app
   - **Condition:** Error rate > 50% for 2 minutes
   - **Notification:** Email, PagerDuty, Slack, etc.

**Talking Points:**
- "In production, we'd configure alerts for anomalies like this"
- "When error rate exceeds 50% for 2 consecutive minutes, page on-call engineer"
- "Splunk supports integration with PagerDuty, Slack, email, webhooks"
- "This ensures we detect and respond to incidents in real-time"

---

## Demo Part 6: Ciroos Value Proposition (2-3 min)

### 6.1 Summarize What We Built

**Talking Points:**
- "We've demonstrated a production-ready multi-region architecture with:"
  - Cross-region private connectivity
  - Security controls (WAF, least-privilege access)
  - Comprehensive observability (infra + APM)
  - Automated fault detection

### 6.2 Where Ciroos Fits In

**Talking Points:**

> "What we just demonstrated manually - investigating the fault, correlating APM traces with infrastructure metrics, identifying the root cause - this is exactly what Ciroos automates.

> "Here's what happened in our demo:"
> 1. Pod died in C2
> 2. We manually looked at Splunk APM to see error spike
> 3. We manually correlated with Kubernetes Navigator to see pod failure
> 4. We manually connected the dots: pod down → service unavailable → user errors

> "With Ciroos:"
> 1. Pod dies in C2
> 2. Ciroos AI agent automatically:
>    - Detects the error spike in APM
>    - Correlates with Kubernetes events (pod termination)
>    - Checks VPC peering status (was the network down?)
>    - Reviews recent deployments (was this a bad deploy?)
>    - Correlates with AWS CloudWatch (any underlying infrastructure issues?)
> 3. Ciroos delivers a root cause analysis in seconds: "Pod apm-backend-app-xxx terminated due to OOMKill. Kubernetes recreated pod. Service restored at XX:XX."

> "Instead of 5 minutes of manual investigation across multiple tools, Ciroos gives you the answer in 10 seconds."

> "The deep observability we've set up here - Splunk APM, infrastructure metrics, distributed tracing - makes Ciroos even more powerful. The more data sources Ciroos has access to, the better its AI-driven root cause analysis."

> "This is especially valuable in complex environments like ours with cross-region dependencies. Ciroos can follow the trace from C1 → VPC peering → C2 and pinpoint exactly where the failure occurred."

---

## Q&A Preparation

### Expected Questions and Answers

#### Q1: Why VPC peering instead of Transit Gateway?

**Answer:**
> "For two regions, VPC peering is the simplest and lowest-latency solution. Transit Gateway adds cost and complexity that's unnecessary at this scale. If we were connecting 5+ regions or needed more advanced routing policies, Transit Gateway would be the better choice. I've documented this trade-off in the architecture write-up."

#### Q2: How do you handle database consistency across regions?

**Answer:**
> "In this demo, the database is only in C1 for simplicity. In production, I'd implement one of these strategies depending on requirements:
> - Active-passive with RDS read replicas in C2
> - Active-active with Aurora Global Database
> - Event-driven eventual consistency with DynamoDB Global Tables
>
> The choice depends on RTO/RPO requirements and whether strong consistency is needed."

#### Q3: What's the cost of this architecture?

**Answer:**
> "Current demo costs approximately:
> - EKS clusters: ~$150/month (2 clusters × $0.10/hour)
> - EC2 nodes: ~$140/month (4 t3.medium instances)
> - NAT Gateways: ~$90/month (2 regions)
> - Data transfer: ~$20/month (VPC peering, minimal traffic)
> - Total: ~$400/month for demo scale
>
> Production would add costs for:
> - Multi-AZ RDS
> - Additional node scaling
> - WAF request pricing
> - Increased data transfer
>
> I can provide a detailed cost breakdown spreadsheet if needed."

#### Q4: How would you implement disaster recovery?

**Answer:**
> "For a production DR strategy:
> 1. **Data layer:** RDS automated backups to S3, cross-region replication
> 2. **Application layer:** Blue/green deployments with ArgoCD
> 3. **Infrastructure:** Terraform state in S3 with versioning
> 4. **RTO target:** 15 minutes (promote C2 to active, update Route53)
> 5. **RPO target:** 5 minutes (RDS backup frequency)
>
> I'd automate failover with Route53 health checks and Lambda functions. The architecture is already designed for active-active if needed - we just need to add database replication and session management."

#### Q5: Why Splunk instead of Datadog or New Relic?

**Answer:**
> "The assignment specified Splunk or AppDynamics. I chose Splunk Observability Cloud because:
> - Native OpenTelemetry support (vendor-neutral)
> - Strong Kubernetes integration
> - Infrastructure + APM in single platform
> - SignalFx acquisition gives them advanced AI/ML for anomaly detection
>
> The architecture is vendor-agnostic though - I'm using OpenTelemetry standard protocols, so we could swap to Datadog or Honeycomb with minimal changes."

#### Q6: How does this scale to 100x traffic?

**Answer:**
> "Scaling strategy:
> 1. **Application layer:**
>    - Horizontal Pod Autoscaler (HPA) based on CPU/memory/custom metrics
>    - Cluster Autoscaler for node scaling
>    - Currently 2 replicas, can scale to 50+ per cluster
>
> 2. **Data layer:**
>    - RDS read replicas for read-heavy workloads
>    - ElastiCache for session/frequently accessed data
>    - Consider Aurora Serverless v2 for automatic scaling
>
> 3. **Network layer:**
>    - Multiple NAT Gateways across AZs
>    - ALB already distributes across AZs
>    - VPC peering bandwidth: 10-25 Gbps (sufficient for most needs)
>
> 4. **Observability:**
>    - OTel collector already uses batch processing
>    - Tail-based sampling for traces at scale
>    - Metrics aggregation to reduce cardinality
>
> Biggest bottleneck would be database - would need to implement read replicas and caching first."

#### Q7: What security controls are missing from this demo?

**Answer:**
> "For production, I would add:
> 1. **Secrets management:** AWS Secrets Manager instead of ConfigMaps
> 2. **Network ACLs:** Additional subnet-level security
> 3. **KMS encryption:** Encrypt EBS volumes, RDS, S3
> 4. **IAM:** IRSA (IAM Roles for Service Accounts) instead of node-level permissions
> 5. **Pod security:** Pod Security Standards, runtime scanning with Falco
> 6. **WAF:** Custom rules for rate limiting, geo-blocking, bot detection
> 7. **VPN/PrivateLink:** For administrative access instead of public API
> 8. **Compliance:** CIS benchmarks, SOC2 controls, audit logging
>
> I've documented these in the production readiness section of my write-up."

#### Q8: How do you test this in CI/CD?

**Answer:**
> "Testing strategy:
> 1. **Unit tests:** Application code with pytest/unittest
> 2. **Integration tests:**
>    - Deploy to ephemeral EKS cluster in dev account
>    - Run end-to-end API tests
>    - Verify cross-region communication
>    - Tear down after tests
>
> 3. **Infrastructure tests:**
>    - Terraform plan validation in PR
>    - Terratest for infrastructure integration tests
>    - Security scanning with tfsec/checkov
>
> 4. **Deployment pipeline:**
>    - GitHub Actions or GitLab CI
>    - ArgoCD for GitOps deployments
>    - Canary deployments with Flagger
>    - Automated rollback on error rate spike
>
> The Python security verification tool would run as part of post-deployment checks."

---

## Demo Cleanup Commands (After Demo)

If you need to tear down the environment:

```bash
# Delete applications
aws eks update-kubeconfig --region us-east-1 --name petclinic-c1
kubectl delete namespace petclinic

aws eks update-kubeconfig --region us-west-2 --name petclinic-c2
kubectl delete namespace petclinic

# Uninstall OTel collectors
helm uninstall splunk-otel-collector -n splunk-monitoring --kube-context C1
helm uninstall splunk-otel-collector -n splunk-monitoring --kube-context C2

# Destroy infrastructure
cd /Users/kanu/Desktop/Ciroos/ciroos-demo-infra
terraform destroy
```

---

## Timing Summary

| Section | Duration | Key Activities |
|---------|----------|----------------|
| Part 1: Working Application | 5 min | Show frontend, test cross-region API calls |
| Part 2: WAF/ALB/Splunk State | 5 min | Show security controls and monitoring |
| Part 3: Security Verification | 5 min | Run Python tool, manual validation |
| Part 4: Fault Injection | 5 min | Delete pod, show user impact |
| Part 5: Fault Detection | 5 min | Show Splunk APM error spike, traces, recovery |
| Part 6: Ciroos Value | 3 min | Explain how Ciroos automates this investigation |
| **Total** | **28 min** | Leaves 2 min buffer for Q&A transition |

---

## Success Criteria

By the end of the demo, you should have demonstrated:

- ✅ Application accessible by end users (Part 1)
- ✅ WAF, ALB, and Splunk all operational (Part 2)
- ✅ Security verification proving C1→C2 allowed, C2 not internet-accessible (Part 3)
- ✅ Fault injection causing user-visible errors (Part 4)
- ✅ Splunk detecting and visualizing the fault (Part 5)
- ✅ Clear articulation of Ciroos value proposition (Part 6)

---

## Final Checklist Before Demo

**5 Minutes Before:**

- [ ] All browser tabs open and loaded
- [ ] Terminal ready with kubectl connected to C1
- [ ] Architecture diagram visible
- [ ] inject-fault.sh script ready to execute
- [ ] Splunk logged in and showing live data
- [ ] Application endpoints responding (test health check)
- [ ] Phone on silent
- [ ] Screen sharing ready (if remote demo)
- [ ] Water/coffee nearby
- [ ] Deep breath - you've got this! 🚀

---

**Good luck with your demo!**
