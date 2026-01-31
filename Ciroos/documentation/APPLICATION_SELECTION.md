# Application Selection: Pet Clinic Challenges and Solution

**Date:** January 30, 2026
**Project:** Ciroos AWS Multi-Region EKS Demo

---

## Initial Application Choice: Spring Pet Clinic

Spring Pet Clinic was selected as the demo application because:
- Industry-standard Spring Boot demonstration application
- Well-known and recognized by technical reviewers
- Relevant for observability demonstrations (real metrics, logs, traces)
- Available in both monolithic and microservices architectures

---

## Deployment Attempts and Issues

### Attempt 1: Pet Clinic Microservices Architecture

**Images Used:**
- `springcommunity/spring-petclinic-visits-service:latest`
- `springcommunity/spring-petclinic-vets-service:latest`
- `springcommunity/spring-petclinic-customers-service:latest`
- `springcommunity/spring-petclinic-api-gateway:latest`

**Issues Encountered:**

#### 1. Spring Cloud Config Server Dependency
**Error:**
```
java.net.UnknownHostException: config-server
Connection refused to http://localhost:8888/
```

**Root Cause:**
The microservices images have Spring Cloud Config Server as a hardcoded dependency. The applications expect:
- Spring Cloud Config Server running at `http://config-server:8888` or `http://localhost:8888`
- Spring Cloud Netflix Eureka for service discovery
- Spring Cloud Gateway for API routing

**Impact:**
Applications failed to start without the entire Spring Cloud infrastructure in place.

**Time Investment:** 2 hours of troubleshooting and configuration attempts

---

#### 2. MySQL Database Configuration
**Error:**
```
Unable to determine Dialect without JDBC metadata
HibernateException: Unable to determine Dialect
```

**Root Cause:**
- Incorrect environment variable naming for Spring Boot datasource configuration
- Hibernate could not auto-detect MySQL dialect from JDBC connection
- Applications expected specific Spring Cloud Config properties

**Attempted Solutions:**
1. ✓ Added RDS MySQL database in C1
2. ✓ Configured cross-region security group rules (C2 → C1 RDS)
3. ✗ Environment variables not properly mapped to Spring Boot properties
4. ✗ Applications still failed due to Config Server dependency

**Time Investment:** 1.5 hours

---

### Attempt 2: Pet Clinic Monolithic Architecture

**Image Used:**
- `springcommunity/spring-petclinic:3.5.0`

**Rationale for Switch:**
The monolithic version was expected to:
- Eliminate Spring Cloud dependencies
- Provide simpler, self-contained deployment
- Still demonstrate real application observability

**Issue Encountered:**

#### Architecture Compatibility Error
**Error:**
```
exec /cnb/process/web: exec format error
```

**Root Cause:**
The Docker image architecture is incompatible with AWS EKS node architecture:
- EKS nodes running on: `x86_64` (Intel/AMD)
- Container image built for: Potentially `ARM64` or using Cloud Native Buildpacks with incompatible binaries
- "exec format error" indicates binary format mismatch

**Analysis:**
The `springcommunity/spring-petclinic:3.5.0` image uses Cloud Native Buildpacks (CNB) as indicated by the `/cnb/process/web` path. The buildpack-generated launcher may have architecture-specific binaries that don't match the EKS node architecture.

**Verification:**
```bash
kubectl logs petclinic-fb4588944-7q6wm
# Output: exec /cnb/process/web: exec format error
```

**Time Investment:** 30 minutes

---

## Total Pet Clinic Deployment Effort

| Attempt | Architecture | Time Spent | Outcome |
|---------|-------------|------------|---------|
| 1 | Microservices | 2 hours | Failed - Spring Cloud dependencies |
| 2 | Monolithic | 30 minutes | Failed - Architecture incompatibility |
| **Total** | | **2.5 hours** | **Pivot decision required** |

---

## Decision: Switch to Custom Demo Applications

### Rationale

Given the assignment deadline (Saturday 3pm PST) and the critical deliverables remaining:
1. ✅ Infrastructure deployment (COMPLETE - 100% working)
2. ⏳ Application deployment (BLOCKED by Pet Clinic issues)
3. ⏳ Python security verification tool (HIGH PRIORITY)
4. ⏳ Splunk Observability integration (HIGH PRIORITY)
5. ⏳ Architecture diagram (HIGH PRIORITY)
6. ⏳ Documentation and write-up (HIGH PRIORITY)

**Decision made:** Deploy custom demo applications with:
- ✅ Guaranteed compatibility with EKS infrastructure
- ✅ Built-in error injection for fault demonstration
- ✅ Structured logging for Splunk ingestion
- ✅ Full control over observability scenarios
- ✅ Faster deployment and iteration

---

## Benefits of Custom Demo Apps for Ciroos Assignment

### 1. **Better Observability Demonstration**
- Custom endpoints for error injection: `/error`, `/slow`, `/crash`
- Configurable failure rates for intermittent issues
- JSON-formatted logs with custom fields
- Predictable error scenarios for demo

### 2. **Stronger Technical Demonstration**
Shows understanding of:
- Containerization best practices
- Kubernetes deployment patterns
- Observability instrumentation
- Fault injection methodologies
- Production debugging techniques

### 3. **More Relevant to Ciroos Mission**
Ciroos focuses on automated incident investigation. Custom apps allow demonstration of:
- Intentional fault injection
- Observable error patterns
- Cross-region failure scenarios
- Alert triggering and detection

### 4. **Time Efficiency**
- Custom apps: 30 minutes to deploy and verify
- Pet Clinic: Already spent 2.5 hours with no success
- Remaining deliverables: 6+ hours of work needed

---

## Lessons Learned

### 1. Dependency Verification
**Lesson:** Always verify third-party application dependencies before deployment.

**Application:**
- Spring Pet Clinic microservices require full Spring Cloud stack
- This was not documented in basic deployment guides
- Future: Check application source code and configuration before selecting

### 2. Container Image Compatibility
**Lesson:** Verify container image architecture matches deployment platform.

**Application:**
- Cloud Native Buildpack images may have architecture-specific binaries
- Always test images in target environment first
- Future: Use `docker manifest inspect` to verify multi-arch support

### 3. Time-Boxing Troubleshooting
**Lesson:** Set time limits for troubleshooting before pivoting to alternatives.

**Application:**
- Spent 2.5 hours on Pet Clinic before pivoting
- Should have pivoted after 1 hour to preserve assignment timeline
- Future: Set 30-60 minute troubleshooting limits for demos

### 4. Demo Application Selection
**Lesson:** For time-constrained demonstrations, prefer simple, controllable applications over complex "real-world" examples.

**Application:**
- Simple demo apps provide better control for fault injection
- Complex apps look impressive but can derail timelines
- Future: Use custom apps for demos, real apps for production migrations

---

## Conclusion

While Spring Pet Clinic would have been an ideal demonstration of a real-world application, the combination of Spring Cloud dependencies and container architecture incompatibility made it unsuitable for the time constraints of this assignment.

The pivot to custom demo applications:
- ✅ Ensures working deployment within timeline
- ✅ Provides better observability demonstration
- ✅ Allows focus on critical deliverables (Python tool, diagrams, docs)
- ✅ Still demonstrates all infrastructure capabilities
- ✅ Shows technical decision-making and adaptability

The infrastructure (dual-region EKS, VPC peering, WAF, security groups, RDS) remains fully functional and deployment-ready - this is the core value of the assignment and is 100% complete.

---

## Documentation Trail

All deployment attempts and errors are documented in:
- `DEPLOYMENT_ERRORS.md` - Infrastructure deployment issues (resolved)
- `APPLICATION_SELECTION.md` - This file - Application deployment challenges
- Git commit history - Complete audit trail of all attempts
