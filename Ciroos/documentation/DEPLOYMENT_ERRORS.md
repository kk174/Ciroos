# Deployment Errors and Resolutions

**Date:** January 30, 2026
**Project:** Ciroos AWS Multi-Region EKS Demo
**Deployment Attempts:** #1 and #2

## Errors Encountered

### 1. WAF Logging Configuration Error

**Error Message:**
```
Error: putting WAFv2 WebACL Logging Configuration: WAFInvalidParameterException:
The ARN isn't valid. A valid ARN begins with arn: and includes other information
separated by colons or slashes.
Field: LOG_DESTINATION
Parameter: arn:aws:s3:::petclinic-logs-084784854430
```

**Root Cause:**
AWS WAFv2 cannot log directly to S3 buckets. WAF logging requires:
- CloudWatch Logs Log Group, OR
- Kinesis Data Firehose delivery stream

**Resolution:**
Remove WAF logging configuration or create CloudWatch Log Group first.

**File:** `alb-waf.tf`
**Line:** 127

---

### 2 & 3. EKS Node Group AMI Version Error (Both Clusters)

**Error Message:**
```
Error: creating EKS Node Group: InvalidParameterException:
Requested AMI for this version 1.28 is not supported
```

**Root Cause:**
Kubernetes version 1.28 has been deprecated/removed from AWS EKS.
Available versions: 1.29, 1.30, 1.31

**Resolution:**
Upgrade Kubernetes version to 1.30 (latest stable).

**File:** `main.tf`
**Lines:** 76 (C1), 233 (C2)

---

### 4. RDS Performance Insights Not Supported

**Error Message:**
```
Error: creating RDS DB Instance: InvalidParameterCombination:
Performance Insights not supported for this configuration.
```

**Root Cause:**
Performance Insights is NOT supported on db.t3.micro instance class.
Minimum requirement: db.t3.small or db.t4g.micro

**Resolution:**
Either disable Performance Insights or upgrade to db.t3.small.

**File:** `main.tf`
**Line:** 173

---

### 5. Kubernetes Provider Connection Refused (Deployment Attempt #2)

**Error Message:**
```
Error: Have got the following error while validating the existence of the ConfigMap "aws-auth":
Get "http://localhost/api/v1/namespaces/kube-system/configmaps/aws-auth":
dial tcp [::1]:80: connect: connection refused
```

**Root Cause:**
The EKS Terraform module's Kubernetes provider tries to manage the aws-auth ConfigMap during cluster creation. However, during `terraform apply`, the Kubernetes provider attempts to connect to localhost instead of the actual EKS cluster endpoint. This happens because:
1. The cluster endpoint isn't fully available during initial creation
2. The Kubernetes provider configuration depends on resources that don't exist yet
3. Creates a circular dependency issue

**Resolution:**
Disable `manage_aws_auth_configmap` in both EKS modules. Configure aws-auth manually after cluster creation using kubectl.

**File:** `main.tf`
**Lines:** 103 (C1), 260 (C2)
**Changed:** `manage_aws_auth_configmap = true` → `manage_aws_auth_configmap = false`

---

## Impact Assessment

| Error | Severity | Impact | Resolution Time |
|-------|----------|--------|-----------------|
| WAF Logging | Low | WAF still works, just no logging | 2 min |
| EKS AMI Version | **Critical** | Node groups can't be created | 5 min |
| RDS Perf Insights | Low | RDS still works, no enhanced monitoring | 1 min |
| K8s Provider Connection | **Critical** | Deployment fails, clusters partially created | 3 min |

**Total Fix Time:** ~11 minutes across both deployment attempts

---

## Lessons Learned

1. **Check AWS service version support** before deployment
2. **Validate AMI availability** for EKS versions
3. **Review instance class capabilities** (Performance Insights)
4. **WAF logging requires intermediary services** (CloudWatch/Kinesis)
5. **Disable EKS aws-auth ConfigMap management** in Terraform to avoid provider connection issues
6. **Configure kubectl access manually** after cluster creation for better reliability

---

## Next Steps (After All Fixes)

1. ✓ Update Kubernetes version: 1.28 → 1.30
2. ✓ Disable Performance Insights on db.t3.micro
3. ✓ Remove WAF logging or add CloudWatch Log Group
4. ✓ Disable manage_aws_auth_configmap in EKS modules
5. Re-run `terraform apply` (attempt #3)
6. Configure kubectl access manually after successful deployment
7. Manually update aws-auth ConfigMap if needed
