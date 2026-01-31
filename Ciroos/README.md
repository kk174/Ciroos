# Ciroos Multi-Region EKS Assignment

**Candidate:** Kanu
**Date:** January 31, 2026
**Assignment:** AWS Multi-Region EKS with Cross-Region Communication, Security Controls, and Splunk Observability

---

## 📋 Project Overview

This project demonstrates a production-ready multi-region AWS architecture featuring:
- **Two EKS clusters** across us-east-1 (C1) and us-west-2 (C2)
- **Private cross-region connectivity** via VPC peering
- **Security controls** including AWS WAF, security groups, and network isolation
- **Comprehensive observability** using Splunk Observability Cloud
- **Distributed tracing** with OpenTelemetry across regions
- **Automated security verification** tooling

---

## 🏗️ Repository Structure

```
Ciroos/
├── infrastructure/              # Terraform infrastructure as code
│   ├── main.tf                 # Core infrastructure (VPCs, EKS clusters)
│   ├── providers.tf            # AWS provider configuration
│   ├── vpc-peering.tf          # Cross-region VPC peering
│   ├── alb-waf.tf             # Application Load Balancer and WAF
│   ├── variables.tf           # Input variables
│   └── outputs.tf             # Output values
│
├── applications/               # Kubernetes application manifests
│   ├── c1-frontend/           # Frontend app (us-east-1)
│   │   ├── apm-test-app-v2.yaml
│   │   └── ...
│   └── c2-backend/            # Backend app (us-west-2)
│       ├── apm-backend-app.yaml
│       └── ...
│
├── observability/             # OpenTelemetry collector configs
│   ├── otel-collector-config.yaml
│   ├── otel-collector-daemonset.yaml
│   ├── deploy-c1.sh
│   └── deploy-c2.sh
│
├── security-verification/     # Python security validation tool
│   ├── verify_security.py
│   └── README.md
│
├── scripts/                   # Helper scripts
│   ├── pre-demo-check.sh      # Pre-demo health check
│   └── inject-fault.sh        # Fault injection for demo
│
├── documentation/             # Complete project documentation
│   ├── README.md              # Documentation index
│   ├── LIVE_DEMO_SCRIPT.md    # 28-minute demo script
│   ├── DEMO_QUICK_REFERENCE.md
│   ├── APM_COMPLETE_SETUP_DOCUMENTATION.md
│   ├── OTEL_COLLECTOR_COMPARISON.md
│   └── ...
│
└── README.md                  # This file
```

---

## 🚀 Quick Start

### Prerequisites

- AWS CLI configured with AdministratorAccess
- Terraform >= 1.0
- kubectl
- Helm 3
- Python 3.9+
- Splunk Observability Cloud account

### 1. Deploy Infrastructure

```bash
cd infrastructure
terraform init
terraform plan
terraform apply
```

**Creates:**
- 2 VPCs (10.0.0.0/16, 10.1.0.0/16)
- 2 EKS clusters (Kubernetes 1.30)
- VPC peering connection
- Security groups
- ALB with WAF in us-east-1
- RDS MySQL database

### 2. Configure kubectl

```bash
# C1 cluster (us-east-1)
aws eks update-kubeconfig --region us-east-1 --name petclinic-c1

# C2 cluster (us-west-2)
aws eks update-kubeconfig --region us-west-2 --name petclinic-c2
```

### 3. Deploy Splunk OpenTelemetry Collectors

```bash
# C1 cluster
helm repo add splunk-otel-collector-chart https://signalfx.github.io/splunk-otel-collector-chart

helm install splunk-otel-collector splunk-otel-collector-chart/splunk-otel-collector \
  --set="splunkObservability.accessToken=<YOUR_TOKEN>" \
  --set="clusterName=petclinic-c1" \
  --set="splunkObservability.realm=us1" \
  --set="gateway.enabled=false" \
  --namespace=splunk-monitoring \
  --create-namespace

# C2 cluster (switch context first)
helm install splunk-otel-collector splunk-otel-collector-chart/splunk-otel-collector \
  --set="splunkObservability.accessToken=<YOUR_TOKEN>" \
  --set="clusterName=petclinic-c2" \
  --set="splunkObservability.realm=us1" \
  --set="gateway.enabled=false" \
  --namespace=splunk-monitoring \
  --create-namespace
```

### 4. Deploy Applications

```bash
# C1 frontend
aws eks update-kubeconfig --region us-east-1 --name petclinic-c1
kubectl apply -f applications/c1-frontend/apm-test-app-v2.yaml

# C2 backend
aws eks update-kubeconfig --region us-west-2 --name petclinic-c2
kubectl apply -f applications/c2-backend/apm-backend-app.yaml
```

### 5. Verify Deployment

```bash
cd scripts
./pre-demo-check.sh
```

**Expected output:** "ALL SYSTEMS GO! Ready for demo!"

---

## 🏛️ Architecture

### High-Level Design

```
┌─────────────────────────────────────────────────────────────┐
│                        Internet                              │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
              ┌────────────────┐
              │   AWS WAF      │
              │   (Regional)   │
              └────────┬───────┘
                       │
                       ▼
┌──────────────────────────────────────────────────────────────┐
│  Region: us-east-1 (C1 - Frontend)                           │
│  ┌────────────────────────────────────────────────────────┐  │
│  │  VPC: 10.0.0.0/16                                      │  │
│  │  ┌──────────────────────────────────────────────────┐ │  │
│  │  │  EKS Cluster: petclinic-c1                       │ │  │
│  │  │  ┌────────────────────────────────────────────┐  │ │  │
│  │  │  │  apm-test-app (Frontend Service)          │  │ │  │
│  │  │  │  • Python Flask                            │  │ │  │
│  │  │  │  • OpenTelemetry instrumented              │  │ │  │
│  │  │  │  • Makes cross-region API calls to C2      │  │ │  │
│  │  │  └────────────────────────────────────────────┘  │ │  │
│  │  │  ┌────────────────────────────────────────────┐  │ │  │
│  │  │  │  Splunk OTel Collector                     │  │ │  │
│  │  │  │  • Agent DaemonSet (2 pods)                │  │ │  │
│  │  │  │  • Cluster Receiver (1 pod)                │  │ │  │
│  │  │  └────────────────────────────────────────────┘  │ │  │
│  │  └──────────────────────────────────────────────────┘ │  │
│  └────────────────────────────────────────────────────────┘  │
└──────────────────────┬───────────────────────────────────────┘
                       │
                       │ VPC Peering
                       │ (Private)
                       ▼
┌──────────────────────────────────────────────────────────────┐
│  Region: us-west-2 (C2 - Backend)                            │
│  ┌────────────────────────────────────────────────────────┐  │
│  │  VPC: 10.1.0.0/16                                      │  │
│  │  ┌──────────────────────────────────────────────────┐ │  │
│  │  │  EKS Cluster: petclinic-c2                       │ │  │
│  │  │  ┌────────────────────────────────────────────┐  │ │  │
│  │  │  │  apm-backend-service (Backend Service)     │  │ │  │
│  │  │  │  • Python Flask                            │  │ │  │
│  │  │  │  • OpenTelemetry instrumented              │  │ │  │
│  │  │  │  • Inventory API                           │  │ │  │
│  │  │  │  • Shipping API                            │  │ │  │
│  │  │  │  • Payment processing                      │  │ │  │
│  │  │  └────────────────────────────────────────────┘  │ │  │
│  │  │  ┌────────────────────────────────────────────┐  │ │  │
│  │  │  │  Splunk OTel Collector                     │  │ │  │
│  │  │  │  • Agent DaemonSet (2 pods)                │  │ │  │
│  │  │  │  • Cluster Receiver (1 pod)                │  │ │  │
│  │  │  └────────────────────────────────────────────┘  │ │  │
│  │  └──────────────────────────────────────────────────┘ │  │
│  └────────────────────────────────────────────────────────┘  │
└──────────────────────┬───────────────────────────────────────┘
                       │
                       │ SignalFx + OTLP
                       ▼
              ┌────────────────────┐
              │  Splunk            │
              │  Observability     │
              │  Cloud (us1)       │
              └────────────────────┘
```

### Key Components

**Region 1 (us-east-1) - Frontend:**
- Internet-facing Application Load Balancer
- AWS WAF with managed rule sets
- EKS cluster with frontend application
- RDS MySQL database
- Security groups allowing public HTTP/HTTPS

**Region 2 (us-west-2) - Backend:**
- Internal-only Network Load Balancer
- EKS cluster with backend services
- Security groups allowing only C1 VPC traffic (10.0.0.0/16)
- No public IP addresses

**Cross-Region Connectivity:**
- VPC peering (10.0.0.0/16 ↔ 10.1.0.0/16)
- Private API calls over AWS backbone
- W3C TraceContext propagation for distributed tracing

**Observability:**
- Splunk official OpenTelemetry collector (v0.143.0)
- SignalFx for infrastructure metrics
- OTLP for APM traces
- Unified service map across regions

---

## 🔐 Security Controls

### Network Security
- ✅ VPC peering for private cross-region connectivity
- ✅ Security groups with least-privilege access
- ✅ C2 backend accessible only from C1 VPC (10.0.0.0/16)
- ✅ No public IPs on EKS worker nodes
- ✅ NAT gateways for outbound internet access

### Application Security
- ✅ AWS WAF protecting public ALB
  - AWS Managed Rules - Core Rule Set (CRS)
  - Protection against OWASP Top 10
- ✅ Security groups on load balancers
- ✅ Kubernetes RBAC
- ✅ Separate namespaces for applications and monitoring

### Verification
```bash
cd security-verification
python3 verify_security.py
```

**Checks:**
1. Security group rules (no overly permissive 0.0.0.0/0)
2. Load balancer exposure (C1 public, C2 internal)
3. Public IP addresses (none on backend)
4. VPC peering status
5. C1→C2 connectivity (working)
6. Internet→C2 connectivity (blocked)

---

## 📊 Observability

### Splunk Observability Cloud

**Infrastructure Monitoring:**
- Kubernetes Navigator showing both clusters
- Node, pod, and container metrics
- CPU, memory, network utilization
- Real-time health status

**APM (Application Performance Monitoring):**
- Service map showing apm-test-app → apm-backend-service
- Distributed tracing across regions
- Request rate, error rate, latency percentiles
- Individual trace inspection

**Key Metrics:**
- `k8s.pod.cpu.utilization`
- `k8s.pod.memory.utilization`
- `k8s.pod.network.io`
- Custom application metrics

**Access:**
- URL: https://app.us1.signalfx.com/
- Navigate to: Infrastructure → Kubernetes Navigator
- APM: APM → Service Map

### OpenTelemetry Setup

**Collector Architecture:**
- Agent DaemonSet (one pod per node)
- Cluster Receiver Deployment (one pod per cluster)
- Version: 0.143.0 (Splunk official)

**Exporters:**
- SignalFx (infrastructure metrics)
- OTLP (APM traces)

**Instrumentation:**
- Language: Python
- Library: opentelemetry-instrumentation-flask
- Propagation: W3C TraceContext

---

## 🎬 Demo Guide

### Pre-Demo Health Check

```bash
cd scripts
./pre-demo-check.sh
```

**Checks 10 critical items:**
1. AWS credentials
2. C1 cluster access
3. C1 application pods
4. C1 OTel collector
5. C1 endpoint health
6. C2 cluster access
7. C2 application pods
8. C2 OTel collector
9. C2 load balancer
10. Cross-region communication

### Live Demo Script

See [documentation/LIVE_DEMO_SCRIPT.md](documentation/LIVE_DEMO_SCRIPT.md) for complete 28-minute demo covering:

1. **Working Application** (5 min)
   - Show frontend accessible by end users
   - Demonstrate cross-region API calls

2. **WAF, ALB, Splunk State** (5 min)
   - AWS WAF configuration
   - Load balancer health
   - Splunk dashboards and metrics

3. **Security Verification** (5 min)
   - Run Python security tool
   - Verify C1→C2 allowed, C2 not internet-exposed

4. **Fault Injection** (5 min)
   - Delete C2 backend pod
   - Show user-facing errors
   - Demonstrate auto-recovery

5. **Fault Detection in Splunk** (5 min)
   - Error spike in APM
   - Individual error traces
   - Service map degradation
   - Infrastructure pod lifecycle

6. **Ciroos Value Proposition** (3 min)
   - Manual investigation vs. Ciroos AI automation

### Fault Injection

```bash
cd scripts
./inject-fault.sh
```

**Simulates:**
- Pod failure in C2 backend cluster
- 10-15 second service outage
- Kubernetes auto-healing
- Real user-facing impact

---

## 📈 Key Metrics

| Metric | Value |
|--------|-------|
| **AWS Regions** | 2 (us-east-1, us-west-2) |
| **EKS Clusters** | 2 |
| **Kubernetes Version** | 1.30 |
| **VPCs** | 2 (10.0.0.0/16, 10.1.0.0/16) |
| **Application Services** | 2 (frontend, backend) |
| **OTel Collector Pods** | 6 total (3 per cluster) |
| **Node Count** | 4 (2 per cluster, t3.medium) |
| **OTel Version** | 0.143.0 (Splunk official) |
| **Cross-Region Latency** | ~40-60ms |
| **Estimated Monthly Cost** | ~$400 (demo scale) |

---

## 📚 Documentation

Complete documentation available in [documentation/](documentation/) folder:

### Getting Started
- [README.md](documentation/README.md) - Documentation index
- [DEMO_PREPARATION_SUMMARY.md](documentation/DEMO_PREPARATION_SUMMARY.md) - Demo overview

### Demo Materials
- [LIVE_DEMO_SCRIPT.md](documentation/LIVE_DEMO_SCRIPT.md) - Complete 28-minute demo script
- [DEMO_QUICK_REFERENCE.md](documentation/DEMO_QUICK_REFERENCE.md) - Quick reference card

### Technical Deep Dives
- [APM_COMPLETE_SETUP_DOCUMENTATION.md](documentation/APM_COMPLETE_SETUP_DOCUMENTATION.md) - APM architecture
- [OTEL_COLLECTOR_COMPARISON.md](documentation/OTEL_COLLECTOR_COMPARISON.md) - Why Splunk official worked
- [APPLICATION_SELECTION.md](documentation/APPLICATION_SELECTION.md) - App deployment journey
- [ENDPOINT_TESTING_GUIDE.md](documentation/ENDPOINT_TESTING_GUIDE.md) - All endpoints and testing

### Architecture
- [architecture-diagram.md](documentation/architecture-diagram.md) - Detailed diagram specification
- architecture-diagram.drawio - Lucid Chart import
- architecture-diagram.mermaid - Mermaid diagram

---

## 🛠️ Troubleshooting

### Pods Not Running

```bash
kubectl get pods -n petclinic
kubectl describe pod -n petclinic <pod-name>
kubectl logs -n petclinic <pod-name>
```

### Splunk Not Showing Data

```bash
kubectl get pods -n splunk-monitoring
kubectl logs -n splunk-monitoring -l app=splunk-otel-collector
```

### Cross-Region Communication Failing

```bash
# Check VPC peering
aws ec2 describe-vpc-peering-connections

# Check security groups
aws ec2 describe-security-groups --region us-west-2

# Check C2 service
kubectl get svc -n petclinic apm-backend-app
```

### Application Not Accessible

```bash
# Check load balancer
kubectl get svc -n petclinic

# Check ingress
kubectl get ingress -n petclinic

# Check pods
kubectl get pods -n petclinic -o wide
```

---

## 🧪 Testing

### Application Endpoints

**C1 Frontend (Public):**
```bash
C1_URL="http://ab565512bbcbf4cf5ac5ba54c67d8071-4607189aed878535.elb.us-east-1.amazonaws.com"

# Health check
curl $C1_URL/health

# Users API (local C1)
curl $C1_URL/api/users

# Orders API (cross-region to C2)
curl $C1_URL/api/orders

# Checkout API (cross-region payment)
curl $C1_URL/api/checkout

# Slow endpoint (performance testing)
curl $C1_URL/api/slow

# Error endpoint (error testing)
curl $C1_URL/api/error
```

**C2 Backend (Internal Only):**
```bash
# From within C1 cluster
kubectl exec -it -n petclinic <c1-pod> -- curl http://<C2-INTERNAL-LB>/health
```

### Security Verification

```bash
cd security-verification
python3 verify_security.py
```

### Infrastructure Tests

```bash
# Verify VPC peering
aws ec2 describe-vpc-peering-connections \
  --filters "Name=status-code,Values=active"

# Check EKS clusters
aws eks list-clusters --region us-east-1
aws eks list-clusters --region us-west-2

# Verify WAF
aws wafv2 list-web-acls --scope REGIONAL --region us-east-1
```

---

## 🔄 Deployment Workflow

1. **Infrastructure Setup** (Terraform)
   ```bash
   cd infrastructure
   terraform init
   terraform apply
   ```

2. **OTel Collector Deployment** (Helm)
   ```bash
   helm install splunk-otel-collector ...
   ```

3. **Application Deployment** (kubectl)
   ```bash
   kubectl apply -f applications/
   ```

4. **Verification**
   ```bash
   ./scripts/pre-demo-check.sh
   ```

5. **Testing**
   ```bash
   curl <endpoints>
   python3 security-verification/verify_security.py
   ```

---

## 🧹 Cleanup

To tear down the entire environment:

```bash
# Delete applications
kubectl delete namespace petclinic --context=<C1-context>
kubectl delete namespace petclinic --context=<C2-context>

# Uninstall OTel collectors
helm uninstall splunk-otel-collector -n splunk-monitoring --context=<C1-context>
helm uninstall splunk-otel-collector -n splunk-monitoring --context=<C2-context>

# Destroy infrastructure
cd infrastructure
terraform destroy
```

**Warning:** This will delete all resources. Estimated time: 15-20 minutes.

---

## 📝 Lessons Learned

### 1. Use Official Integrations When Available
- Splunk official OTel collector vs custom configuration
- Pre-configured, tested, and supported
- Better RBAC and permissions out of the box

### 2. Architecture Matters
- Separate cluster receiver from node agents
- Better scalability and clearer separation of concerns
- Different RBAC requirements for cluster-level vs node-level metrics

### 3. Version Matters
- OTel 0.91.0 vs 0.143.0 (52 versions difference)
- Bug fixes and platform improvements
- Better Splunk integration in newer versions

### 4. RBAC is Critical
- Missing permissions cause silent failures
- Comprehensive RBAC in official Helm charts
- Always verify required permissions

Detailed analysis in [documentation/OTEL_COLLECTOR_COMPARISON.md](documentation/OTEL_COLLECTOR_COMPARISON.md)

---

## 🚀 Production Readiness Roadmap

**Current State:** Demo/POC
**Target State:** Production-ready

**Missing Components:**

1. **Secrets Management**
   - [ ] AWS Secrets Manager integration
   - [ ] External Secrets Operator
   - [ ] KMS encryption

2. **High Availability**
   - [ ] Multi-AZ RDS deployment
   - [ ] Multiple NAT gateways per region
   - [ ] Auto-scaling groups for nodes

3. **CI/CD Pipeline**
   - [ ] GitOps with ArgoCD
   - [ ] Automated testing
   - [ ] Blue/green deployments
   - [ ] Canary releases

4. **Advanced Security**
   - [ ] Pod Security Standards
   - [ ] Network policies
   - [ ] Runtime security (Falco)
   - [ ] Custom WAF rules

5. **Disaster Recovery**
   - [ ] Automated backups
   - [ ] Cross-region RDS replication
   - [ ] Documented runbooks
   - [ ] Tested failover procedures

6. **Cost Optimization**
   - [ ] Cluster autoscaler
   - [ ] Spot instances
   - [ ] Resource right-sizing
   - [ ] Budget alerts

7. **Compliance**
   - [ ] CIS benchmarks
   - [ ] SOC2 controls
   - [ ] Audit logging
   - [ ] Compliance scanning

---

## 🤝 Contributing

This is a demonstration project for the Ciroos assignment. For questions or issues:

1. Check [documentation/](documentation/) for comprehensive docs
2. Review [troubleshooting](#-troubleshooting) section
3. Examine logs: `kubectl logs -n <namespace> <pod>`

---

## 📄 License

This is a demonstration project created for a technical assignment.

---

## 👤 Author

**Kanu**
Assignment: Ciroos Multi-Region EKS Demo
Date: January 31, 2026

---

## 🙏 Acknowledgments

- **Splunk** for official OpenTelemetry collector Helm chart
- **AWS** for EKS, VPC peering, and security services
- **OpenTelemetry** community for instrumentation libraries
- **Ciroos** team for the challenging and educational assignment

---

**Status:** ✅ Complete and ready for demo

**Next Steps:** Review [documentation/DEMO_PREPARATION_SUMMARY.md](documentation/DEMO_PREPARATION_SUMMARY.md) to prepare for live demonstration.
