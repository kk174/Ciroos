# Ciroos Demo - Quick Reference Card

**Date:** Saturday, January 30, 2026 | **Duration:** 25 minutes

---

## URLs (Pre-load in Browser Tabs)

| Tab | Purpose | URL |
|-----|---------|-----|
| 1 | **Application Frontend** | http://ab565512bbcbf4cf5ac5ba54c67d8071-4607189aed878535.elb.us-east-1.amazonaws.com |
| 2 | **AWS WAF Console** | https://console.aws.amazon.com/wafv2/homev2/web-acls?region=us-east-1 |
| 3 | **AWS Load Balancers** | https://console.aws.amazon.com/ec2/v2/home?region=us-east-1#LoadBalancers: |
| 4 | **Splunk K8s Navigator** | https://app.us1.signalfx.com/ → Infrastructure → Kubernetes |
| 5 | **Splunk APM** | https://app.us1.signalfx.com/apm |
| 6 | **Terminal** | kubectl connected to C1 |

---

## Application Endpoints to Demo

| Endpoint | Purpose | Expected Behavior |
|----------|---------|-------------------|
| `/health` | Health check | Returns C1 status |
| `/api/users` | Local C1 query | Local database in C1 |
| `/api/orders` | **Cross-region call** | Calls C2 for inventory + shipping |
| `/api/checkout` | **Cross-region payment** | Calls C2, 20% failure rate |
| `/api/slow` | Performance test | Intentional 0.5-1.5s delay |
| `/api/error` | Error test | Always returns 500 |

---

## Key Commands

### Pre-Demo Setup
```bash
# C1 cluster
aws eks update-kubeconfig --region us-east-1 --name petclinic-c1
kubectl get pods -n petclinic
kubectl get pods -n splunk-monitoring

# C2 cluster
aws eks update-kubeconfig --region us-west-2 --name petclinic-c2
kubectl get pods -n petclinic
kubectl get pods -n splunk-monitoring
```

### Security Verification
```bash
cd /Users/kanu/Desktop/Ciroos/security-verification
python3 verify_security.py
```

### Fault Injection
```bash
cd /Users/kanu/Desktop/Ciroos
./inject-fault.sh
```

### Manual C1→C2 Connectivity Test
```bash
# From C1 pod to C2 backend
POD=$(kubectl get pods -n petclinic -l app=apm-test-app -o jsonpath='{.items[0].metadata.name}')
kubectl exec -n petclinic $POD -- curl -s http://ac3dc550dad9847ea805e20c963ee7ba-39ea100930485fc4.elb.us-west-2.amazonaws.com/health
```

---

## Demo Flow (28 minutes)

| Time | Section | Key Points |
|------|---------|------------|
| 0-5 | **Part 1: Working App** | Show frontend, cross-region calls, architecture diagram |
| 5-10 | **Part 2: WAF/ALB/Splunk** | Show AWS WAF rules, ALB health, Splunk K8s Navigator + APM |
| 10-15 | **Part 3: Security** | Run Python tool, show C2 unreachable from internet |
| 15-20 | **Part 4: Fault Injection** | Delete C2 pod, show user errors, recovery |
| 20-25 | **Part 5: Splunk Detection** | Show error spike, traces, service map, infrastructure |
| 25-28 | **Part 6: Ciroos Value** | Manual investigation vs. Ciroos AI automation |

---

## Splunk Navigation

### Infrastructure Monitoring
1. Infrastructure → Kubernetes Navigator
2. Filter: `k8s.cluster.name` = `petclinic-c1` or `petclinic-c2`
3. Drill into: Namespace → petclinic
4. Show: Pod status, CPU, memory, network

### APM Service Map
1. APM → Service Map
2. Time range: Last 15 minutes
3. Should see: `apm-test-app` → `apm-backend-service`
4. Click service: Request rate, error rate, latency

### Traces
1. APM → Traces
2. Filter by service: `apm-test-app`
3. Click trace: See distributed trace across C1→C2

---

## What to Highlight

### Security (Part 3)
✓ **C1 frontend:** Internet-accessible (intended)
✓ **C2 backend:** Internal only (no public IP)
✓ **VPC Peering:** Private cross-region connectivity
✓ **Security Groups:** C2 only allows C1 VPC CIDR

### Fault Detection (Part 5)
✓ **Error spike:** Goes from 20% → 100% during fault
✓ **Latency:** Timeout errors (5000ms)
✓ **Service Map:** Shows degraded service in red/yellow
✓ **Infrastructure:** Pod count drops, then recovers

### Ciroos Value (Part 6)
✓ **Manual:** 5+ minutes across multiple tools
✓ **With Ciroos:** 10 seconds to root cause
✓ **Correlation:** APM + K8s + VPC + CloudWatch
✓ **AI-driven:** Automated investigation and diagnosis

---

## Expected Questions & Answers

**Q: Why VPC peering vs Transit Gateway?**
A: For 2 regions, peering is simpler and lower latency. Would use TGW for 5+ regions.

**Q: Database consistency across regions?**
A: Demo has DB only in C1. Production would use Aurora Global DB or event-driven eventual consistency.

**Q: Cost of this setup?**
A: ~$400/month for demo (EKS $150, EC2 $140, NAT $90, data transfer $20).

**Q: How to scale 100x?**
A: HPA for pods, Cluster Autoscaler for nodes, RDS read replicas, ElastiCache, tail-based trace sampling.

**Q: Missing security controls?**
A: Secrets Manager, KMS encryption, IRSA, Pod Security Standards, custom WAF rules, VPN access.

---

## Troubleshooting

### If application not responding:
```bash
kubectl get pods -n petclinic
kubectl logs -n petclinic <pod-name>
kubectl describe pod -n petclinic <pod-name>
```

### If Splunk not showing data:
- Check OTel collector pods: `kubectl get pods -n splunk-monitoring`
- Check collector logs: `kubectl logs -n splunk-monitoring -l app=splunk-otel-collector`
- Verify token in Splunk UI: Settings → Access Tokens

### If C1→C2 communication fails:
- Check VPC peering: `aws ec2 describe-vpc-peering-connections`
- Check security groups: Allow port 80 from 10.0.0.0/16
- Check C2 service: `kubectl get svc -n petclinic apm-backend-app`

---

## Success Criteria Checklist

Before demo starts:
- [ ] All browser tabs loaded
- [ ] Splunk showing live data (both clusters)
- [ ] Application endpoints responding
- [ ] inject-fault.sh tested and ready
- [ ] Architecture diagram visible
- [ ] Terminal with kubectl ready

During demo:
- [ ] Showed working cross-region communication
- [ ] Showed WAF, ALB, Splunk state
- [ ] Proved security controls (Python tool)
- [ ] Injected fault successfully
- [ ] Splunk detected fault clearly
- [ ] Explained Ciroos value proposition

---

## Quick Stats to Reference

| Metric | Value |
|--------|-------|
| **Regions** | 2 (us-east-1, us-west-2) |
| **EKS Clusters** | 2 (petclinic-c1, petclinic-c2) |
| **VPCs** | 2 (10.0.0.0/16, 10.1.0.0/16) |
| **Services** | 2 (apm-test-app, apm-backend-service) |
| **OTel Collectors** | 6 pods total (3 per cluster) |
| **Kubernetes Version** | 1.30 |
| **OTel Collector Version** | 0.143.0 (Splunk official) |
| **Node Count** | 4 total (2 per cluster, t3.medium) |
| **Expected Fault Window** | 10-15 seconds |
| **Cross-region Latency** | ~40-60ms (us-east-1 ↔ us-west-2) |

---

## Architecture Summary (Elevator Pitch)

> "This is a production-ready multi-region AWS architecture with two EKS clusters across us-east-1 and us-west-2. The frontend in C1 is internet-accessible through an ALB protected by AWS WAF. The backend in C2 is completely private, only accessible from C1 via VPC peering. Both clusters are instrumented with Splunk's official OpenTelemetry collector, sending infrastructure metrics and APM traces to Splunk Observability Cloud. We're using W3C TraceContext for distributed tracing across regions, giving us end-to-end visibility from the user request all the way through cross-region service calls. I've built a Python security verification tool that validates our security controls, and I'll demonstrate fault injection and detection to show how Splunk would alert in a real incident."

---

## Backup Plan

If something breaks during demo:

**Plan A:** Use recorded screenshots/video of working system
**Plan B:** Walk through architecture diagram + documentation
**Plan C:** Focus on design decisions and production readiness discussion

Remember: **Explaining your thinking is more valuable than perfect execution!**

---

## Final Reminders

✓ Speak slowly and clearly
✓ Pause for questions between sections
✓ Assume audience is technical but unfamiliar with your setup
✓ Point out trade-offs and production improvements
✓ Connect everything back to Ciroos value proposition
✓ Have fun - you built something impressive! 🚀

---

**You've got this!** 💪
