# Ciroos Assignment Deliverables

**Candidate:** Kanu
**Date:** January 31, 2026
**Assignment:** Multi-Region EKS with Cross-Region Communication and Observability

---

## 📁 Directory Structure

```
deliverables/
├── README.md (this file)
│
├── 📊 Architecture Diagrams
│   ├── architecture-diagram.drawio        # Import into Lucid Chart
│   ├── architecture-diagram.md            # Diagram specification
│   └── architecture-diagram.mermaid       # Mermaid diagram code
│
├── 🎬 Demo Materials
│   ├── DEMO_PREPARATION_SUMMARY.md        # START HERE - Demo overview
│   ├── LIVE_DEMO_SCRIPT.md                # Complete demo script (20 pages)
│   └── DEMO_QUICK_REFERENCE.md            # Quick reference card
│
├── 📖 Technical Documentation
│   ├── APM_COMPLETE_SETUP_DOCUMENTATION.md      # APM architecture & setup
│   ├── OTEL_COLLECTOR_COMPARISON.md             # Why Splunk official worked
│   ├── APPLICATION_SELECTION.md                 # App deployment journey
│   └── ENDPOINT_TESTING_GUIDE.md                # All endpoints & testing
│
└── 📝 Project Documentation
    ├── INITIAL_RESEARCH.md                      # Research notes
    └── TERRAFORM_PLAN_OUTPUT.md                 # Infrastructure plan
```

---

## 🚀 Quick Start - Preparing for Demo

### 30 Minutes Before Demo

**1. Run Health Check**
```bash
cd /Users/kanu/Desktop/Ciroos
./pre-demo-check.sh
```

**2. Read Demo Materials**
- [DEMO_PREPARATION_SUMMARY.md](DEMO_PREPARATION_SUMMARY.md) - Overview
- [LIVE_DEMO_SCRIPT.md](LIVE_DEMO_SCRIPT.md) - Full script
- [DEMO_QUICK_REFERENCE.md](DEMO_QUICK_REFERENCE.md) - Quick reference

**3. Verify Splunk**
- Login: https://app.us1.signalfx.com/
- Check: Infrastructure → Kubernetes Navigator
- Verify: Both clusters showing data

**4. Open Browser Tabs**
- Application: http://a9dd2c5fde37e4c6abd04a564ea3ef95-a64aa6c61219d593.elb.us-east-1.amazonaws.com
- AWS WAF Console
- AWS Load Balancers Console
- Splunk Observability Cloud

---

## 📊 Architecture Summary

**Two-Region Setup:**
- **Region 1 (us-east-1):** Frontend cluster (C1) - Internet-facing
- **Region 2 (us-west-2):** Backend cluster (C2) - Internal only

**Key Components:**
- 2 EKS clusters (Kubernetes 1.30)
- 2 VPCs with VPC peering (10.0.0.0/16 ↔ 10.1.0.0/16)
- AWS WAF protecting public ALB
- OpenTelemetry collectors (Splunk official, version 0.143.0)
- Distributed tracing with W3C TraceContext propagation
- Splunk Observability Cloud (realm: us1)

**Applications:**
- `apm-test-app` (Python Flask) in C1
- `apm-backend-service` (Python Flask) in C2

---

## 📖 Documentation Guide

### For Demo Preparation
1. **[DEMO_PREPARATION_SUMMARY.md](DEMO_PREPARATION_SUMMARY.md)** ⭐ START HERE
   - Complete demo overview
   - 30-minute preparation checklist
   - All materials explained

2. **[LIVE_DEMO_SCRIPT.md](LIVE_DEMO_SCRIPT.md)**
   - 28-minute demo script with timing
   - Step-by-step instructions
   - Talking points for each section
   - Q&A preparation

3. **[DEMO_QUICK_REFERENCE.md](DEMO_QUICK_REFERENCE.md)**
   - URLs and commands cheat sheet
   - Quick lookup during demo

### For Architecture Understanding
4. **[APM_COMPLETE_SETUP_DOCUMENTATION.md](APM_COMPLETE_SETUP_DOCUMENTATION.md)**
   - Complete APM architecture
   - Distributed tracing explanation
   - All endpoints documented
   - Cross-region communication flow

5. **[architecture-diagram.drawio](architecture-diagram.drawio)**
   - Visual architecture diagram
   - Import into Lucid Chart

### For Technical Deep Dive
6. **[OTEL_COLLECTOR_COMPARISON.md](OTEL_COLLECTOR_COMPARISON.md)**
   - Why custom OTel didn't work
   - Why Splunk official worked
   - 9 key differences explained
   - Lessons learned

7. **[APPLICATION_SELECTION.md](APPLICATION_SELECTION.md)**
   - Pet Clinic deployment attempts
   - Why we pivoted to custom apps
   - Technical challenges documented

8. **[ENDPOINT_TESTING_GUIDE.md](ENDPOINT_TESTING_GUIDE.md)**
   - All endpoint URLs
   - Testing procedures
   - Expected responses
   - curl commands

---

## 🛠️ Supporting Tools

### Pre-Demo Health Check
```bash
/Users/kanu/Desktop/Ciroos/pre-demo-check.sh
```
Verifies:
- AWS credentials
- EKS cluster access
- Application pods running
- OTel collectors running
- Load balancers healthy
- Cross-region communication

### Fault Injection Script
```bash
/Users/kanu/Desktop/Ciroos/inject-fault.sh
```
Simulates:
- Pod failure in C2 backend
- 10-15 second outage
- Kubernetes auto-recovery

### Security Verification Tool
```bash
/Users/kanu/Desktop/Ciroos/security-verification/verify_security.py
```
Checks:
- Security group rules
- Load balancer exposure
- VPC peering status
- Internet accessibility

---

## 🎯 Demo Requirements Met

| Requirement | Status | Evidence |
|-------------|--------|----------|
| Working application accessible by end user | ✅ | Frontend: http://...-us-east-1.amazonaws.com |
| Show WAF, ALB, Splunk state | ✅ | AWS Console + Splunk UI |
| Confirm C1→C2 allowed, no unintended exposure | ✅ | Python security tool + manual verification |
| Fault injection in environment | ✅ | inject-fault.sh script |
| Show fault detection in Splunk | ✅ | APM error spike + traces |

---

## 📈 Key Metrics

| Metric | Value |
|--------|-------|
| **Regions** | 2 (us-east-1, us-west-2) |
| **EKS Clusters** | 2 (petclinic-c1, petclinic-c2) |
| **VPCs** | 2 (10.0.0.0/16, 10.1.0.0/16) |
| **Applications** | 2 (apm-test-app, apm-backend-service) |
| **OTel Collectors** | 6 pods total (3 per cluster) |
| **Kubernetes Version** | 1.30 |
| **OTel Version** | 0.143.0 (Splunk official) |
| **Cross-Region Latency** | ~40-60ms |
| **Estimated Cost** | ~$400/month |

---

## 🏗️ Infrastructure Code

**Location:** `/Users/kanu/Desktop/Ciroos/ciroos-demo-infra/`

**Key Files:**
- `main.tf` - Core infrastructure
- `providers.tf` - AWS provider configuration
- `vpc-peering.tf` - Cross-region VPC peering
- `alb-waf.tf` - ALB and WAF configuration
- `variables.tf` - Input variables
- `outputs.tf` - Output values

**Deployment:**
```bash
cd /Users/kanu/Desktop/Ciroos/ciroos-demo-infra
terraform init
terraform plan
terraform apply
```

---

## 🐳 Application Manifests

**Location:** `/Users/kanu/Desktop/Ciroos/petclinic-k8s/manifests/`

**Directories:**
- `c1-frontend/` - Frontend application for C1
- `c2-backend/` - Backend application for C2
- `observability/` - Custom OTel collector (deprecated)

**Deployment:**
```bash
# C1 Frontend
aws eks update-kubeconfig --region us-east-1 --name petclinic-c1
kubectl apply -f c1-frontend/apm-test-app-v2.yaml

# C2 Backend
aws eks update-kubeconfig --region us-west-2 --name petclinic-c2
kubectl apply -f c2-backend/apm-backend-app.yaml
```

---

## 🔍 Observability Setup

**Splunk OTel Collector:**
- **Installation:** Helm chart from Splunk
- **Version:** 0.143.0
- **Architecture:** Agent DaemonSet + Cluster Receiver Deployment
- **Namespace:** splunk-monitoring
- **Exporters:** SignalFx (metrics) + OTLP (traces)

**Instrumentation:**
- **Language:** Python
- **Library:** opentelemetry-instrumentation-flask
- **Propagation:** W3C TraceContext
- **Exporter:** OTLP gRPC to collector

**Splunk Observability Cloud:**
- **Realm:** us1
- **Features Used:**
  - Kubernetes Navigator (infrastructure metrics)
  - APM (distributed tracing)
  - Service Map (cross-region dependencies)

---

## 🔒 Security Controls

**Network Security:**
- VPC peering (private connectivity)
- Security groups (least-privilege access)
- C2 internal-only load balancer
- No public IPs on EKS nodes

**Application Security:**
- AWS WAF (AWS Managed Rules)
- ALB security groups
- RBAC for Kubernetes
- Splunk access token for telemetry export

**Verification:**
- Automated Python security tool
- Manual connectivity testing
- Security group audit

---

## 📊 Splunk Dashboards

**Infrastructure:**
- Kubernetes Navigator → Filter by cluster
- View: Nodes, pods, CPU, memory, network

**APM:**
- Service Map → apm-test-app → apm-backend-service
- Traces → Filter by service or endpoint
- Metrics → Request rate, error rate, latency

**Key Searches:**
```
# Infrastructure metrics
k8s.pod.cpu.utilization AND k8s.cluster.name:petclinic-c1

# APM traces
service.name:apm-test-app AND error:true

# Cross-region calls
service.name:apm-backend-service AND http.route:/api/inventory
```

---

## 🎬 Demo Timeline

| Time | Section | File to Reference |
|------|---------|-------------------|
| 0-5 min | Working Application | LIVE_DEMO_SCRIPT.md (Part 1) |
| 5-10 min | WAF, ALB, Splunk | LIVE_DEMO_SCRIPT.md (Part 2) |
| 10-15 min | Security Verification | LIVE_DEMO_SCRIPT.md (Part 3) |
| 15-20 min | Fault Injection | LIVE_DEMO_SCRIPT.md (Part 4) |
| 20-25 min | Fault Detection | LIVE_DEMO_SCRIPT.md (Part 5) |
| 25-28 min | Ciroos Value Proposition | LIVE_DEMO_SCRIPT.md (Part 6) |

---

## 📞 Support & Troubleshooting

**If pods not running:**
```bash
kubectl get pods -n petclinic
kubectl describe pod -n petclinic <pod-name>
kubectl logs -n petclinic <pod-name>
```

**If Splunk not showing data:**
```bash
kubectl get pods -n splunk-monitoring
kubectl logs -n splunk-monitoring -l app=splunk-otel-collector
```

**If cross-region communication fails:**
```bash
# Check VPC peering
aws ec2 describe-vpc-peering-connections

# Check C2 service
kubectl get svc -n petclinic apm-backend-app
```

---

## 🎓 Lessons Learned

1. **Use official integrations when available**
   - Splunk official OTel collector vs custom configuration
   - Pre-configured, tested, and supported

2. **Architecture matters**
   - Separate cluster receiver from node agents
   - Better RBAC and scalability

3. **Version matters**
   - 0.91.0 vs 0.143.0 (52 versions difference)
   - Bug fixes and platform improvements

4. **RBAC is critical**
   - Missing permissions cause silent failures
   - Comprehensive RBAC in official charts

All documented in [OTEL_COLLECTOR_COMPARISON.md](OTEL_COLLECTOR_COMPARISON.md)

---

## 🚀 Production Readiness Roadmap

**Missing for Production:**
- [ ] Secrets Manager for credentials
- [ ] KMS encryption for data at rest
- [ ] IRSA (IAM Roles for Service Accounts)
- [ ] Pod Security Standards
- [ ] Custom WAF rules (rate limiting, geo-blocking)
- [ ] Multi-AZ RDS with read replicas
- [ ] GitOps pipeline (ArgoCD)
- [ ] Canary deployments
- [ ] Automated backup/restore
- [ ] Cost optimization (auto-scaling, spot instances)

Documented in demo script and write-up.

---

## ✅ Checklist - Demo Ready?

- [ ] Read [DEMO_PREPARATION_SUMMARY.md](DEMO_PREPARATION_SUMMARY.md)
- [ ] Run `pre-demo-check.sh` (all green)
- [ ] Verify Splunk showing data
- [ ] Test all application endpoints
- [ ] Open all browser tabs
- [ ] Review [LIVE_DEMO_SCRIPT.md](LIVE_DEMO_SCRIPT.md)
- [ ] Print [DEMO_QUICK_REFERENCE.md](DEMO_QUICK_REFERENCE.md)
- [ ] Practice Ciroos value proposition
- [ ] Deep breath - you've got this! 😊

---

## 📧 Contact

If you have questions about any documentation:
1. Check the specific document (most comprehensive)
2. Check DEMO_PREPARATION_SUMMARY.md (overview)
3. Check this README (quick reference)

All the information you need is documented! 📚

---

**Good luck with your demo!** 🍀🚀
