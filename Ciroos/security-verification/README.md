# AWS Multi-Region Security Verification Tool

Python-based security verification tool for the Ciroos dual-region EKS deployment. This tool validates that security controls are properly configured across both clusters (C1 in us-east-1 and C2 in us-west-2).

## Purpose

This tool confirms:
1. **No unintended public access paths** - C2 backend services are not publicly accessible
2. **Proper C1 → C2 communication** - Only intended cross-region connectivity is permitted
3. **Security group configurations** - No overly permissive rules
4. **WAF protection** - Web Application Firewall is properly configured
5. **VPC peering** - Cross-region connectivity is established and active

## Prerequisites

### AWS Credentials
Ensure AWS credentials are configured with sufficient permissions:
```bash
aws configure
# Or use environment variables:
export AWS_ACCESS_KEY_ID=your_access_key
export AWS_SECRET_ACCESS_KEY=your_secret_key
export AWS_DEFAULT_REGION=us-east-1
```

Required AWS permissions:
- `ec2:DescribeSecurityGroups`
- `ec2:DescribeVpcPeeringConnections`
- `ec2:DescribeInstances`
- `elasticloadbalancing:DescribeLoadBalancers`
- `wafv2:ListWebACLs`
- `wafv2:GetWebACL`

### Python Dependencies
Python 3.8 or higher is required.

Install dependencies:
```bash
cd /Users/kanu/Desktop/Ciroos/security-verification
pip install -r requirements.txt
```

## Installation

1. Clone or navigate to the security-verification directory:
```bash
cd /Users/kanu/Desktop/Ciroos/security-verification
```

2. Install dependencies:
```bash
pip install -r requirements.txt
```

3. Verify AWS credentials:
```bash
aws sts get-caller-identity
```

## Usage

### Basic Usage

Run all security checks:
```bash
python verify_security.py
```

### Command-Line Options

```bash
python verify_security.py [OPTIONS]
```

**Options:**
- `--regions REGION1,REGION2` - AWS regions to check (default: us-east-1,us-west-2)
- `--c1-vpc VPC_ID` - C1 VPC ID (auto-detected if not specified)
- `--c2-vpc VPC_ID` - C2 VPC ID (auto-detected if not specified)
- `--output FILE` - Save JSON report to file (default: security-report.json)
- `--verbose` - Enable verbose output
- `--help` - Show help message

### Examples

**Run with default settings:**
```bash
python verify_security.py
```

**Specify VPC IDs explicitly:**
```bash
python verify_security.py --c1-vpc vpc-0123456789abcdef0 --c2-vpc vpc-0fedcba9876543210
```

**Save report to custom file:**
```bash
python verify_security.py --output my-security-audit.json
```

**Enable verbose logging:**
```bash
python verify_security.py --verbose
```

## Security Checks Performed

### 1. Security Group Configuration
**Purpose**: Verify no overly permissive security group rules

**Checks:**
- Identifies security groups with 0.0.0.0/0 ingress rules
- Flags non-ALB security groups allowing unrestricted access
- Validates that only ALB/WAF security groups have public ingress

**Expected Result**: Only ALB security groups should have 0.0.0.0/0 ingress on ports 80/443

### 2. Load Balancer Configuration
**Purpose**: Confirm proper public/private load balancer setup

**Checks:**
- C1 load balancers should be **internet-facing**
- C2 load balancers should be **internal-only**
- Verifies load balancer schemes match intended architecture

**Expected Result**:
- C1: `internet-facing` scheme
- C2: `internal` scheme

### 3. Public IP Assignment
**Purpose**: Ensure C2 backend instances have no public IPs

**Checks:**
- Queries all EC2 instances in C2 VPC
- Verifies no public IP addresses are assigned
- Checks EKS node groups in C2

**Expected Result**: Zero public IPs found in C2 backend cluster

### 4. VPC Peering Configuration
**Purpose**: Validate cross-region connectivity is established

**Checks:**
- Confirms VPC peering connection exists between C1 and C2
- Verifies peering status is **active**
- Validates route tables include peering routes

**Expected Result**: Active VPC peering connection with bidirectional routes

### 5. Internet Connectivity Test
**Purpose**: Confirm C2 services are NOT accessible from internet

**Checks:**
- Attempts to connect to C2 load balancer from external network
- Verifies connection fails (timeout or refused)
- Confirms only C1 is publicly reachable

**Expected Result**: Connection to C2 should **fail** (unreachable)

### 6. WAF Configuration
**Purpose**: Verify Web Application Firewall is deployed

**Checks:**
- Confirms WAF Web ACL exists in us-east-1
- Validates WAF has active rules
- Checks for AWS Managed Rule Sets

**Expected Result**: WAF Web ACL with at least one rule enabled

## Output Format

### Console Output

The tool displays color-coded results in the terminal:

```
========================================
AWS Multi-Region Security Verification
========================================

Region 1 (C1): us-east-1
Region 2 (C2): us-west-2

[1/6] Checking Security Groups...
✓ PASS - No overly permissive security groups found

[2/6] Checking Load Balancer Configuration...
✓ PASS - C1 is internet-facing, C2 is internal

[3/6] Checking Public IP Assignments...
✓ PASS - No public IPs found in C2 backend

[4/6] Checking VPC Peering...
✓ PASS - VPC peering active between C1 and C2

[5/6] Testing Internet Connectivity to C2...
✓ PASS - C2 services are not accessible from internet

[6/6] Checking WAF Configuration...
✓ PASS - WAF Web ACL found with 3 rules

========================================
Security Verification Summary
========================================
Total Checks: 6
Passed: 6
Failed: 0

Status: ✓ ALL CHECKS PASSED
```

### JSON Report

The tool generates a detailed JSON report saved to `security-report.json` (or custom filename):

```json
{
  "timestamp": "2026-01-30T14:32:15Z",
  "regions": {
    "c1": "us-east-1",
    "c2": "us-west-2"
  },
  "checks": [
    {
      "name": "security_groups",
      "status": "PASS",
      "message": "No overly permissive security groups found",
      "details": {
        "total_security_groups": 12,
        "permissive_rules_found": 1,
        "allowed_permissive": ["sg-alb-public"]
      }
    },
    {
      "name": "load_balancers",
      "status": "PASS",
      "message": "C1 is internet-facing, C2 is internal",
      "details": {
        "c1_scheme": "internet-facing",
        "c2_scheme": "internal"
      }
    }
  ],
  "summary": {
    "total_checks": 6,
    "passed": 6,
    "failed": 0,
    "status": "PASS"
  }
}
```

## Interpreting Results

### PASS Status
All security controls are properly configured. The deployment meets security requirements.

### FAIL Status
One or more security issues detected. Review the details section for specific findings:

**Common Issues:**
1. **Security Group Fail**: C2 has security groups allowing 0.0.0.0/0 ingress
   - **Fix**: Remove public ingress rules from C2 security groups

2. **Load Balancer Fail**: C2 load balancer is internet-facing
   - **Fix**: Recreate C2 load balancer with `internal` scheme

3. **Public IP Fail**: C2 instances have public IPs assigned
   - **Fix**: Remove public IP associations from C2 instances

4. **VPC Peering Fail**: Peering connection not active
   - **Fix**: Check VPC peering status and route tables

5. **Internet Connectivity Fail**: C2 services are publicly accessible
   - **Fix**: Review security groups and network ACLs

6. **WAF Fail**: No WAF Web ACL found
   - **Fix**: Deploy WAF Web ACL in us-east-1

## Troubleshooting

### Error: "Unable to locate credentials"
**Cause**: AWS credentials not configured

**Solution**:
```bash
aws configure
# Or set environment variables:
export AWS_ACCESS_KEY_ID=your_key
export AWS_SECRET_ACCESS_KEY=your_secret
```

### Error: "An error occurred (UnauthorizedOperation)"
**Cause**: Insufficient AWS IAM permissions

**Solution**: Ensure your IAM user/role has the required permissions listed in Prerequisites

### Error: "Could not connect to the endpoint URL"
**Cause**: Invalid region or network connectivity issue

**Solution**:
- Verify region names are correct (us-east-1, us-west-2)
- Check internet connectivity
- Verify AWS service endpoints are accessible

### VPC IDs Not Auto-Detected
**Cause**: VPCs don't have the expected naming tags

**Solution**: Specify VPC IDs explicitly:
```bash
python verify_security.py --c1-vpc vpc-xxx --c2-vpc vpc-yyy
```

### False Positive: "C2 is accessible from internet"
**Cause**: Internal DNS resolution or VPN connection

**Solution**: Run the tool from a truly external network (not connected to AWS VPN)

## Architecture Context

This tool validates the following architecture:

```
Internet
   |
   ↓
[AWS WAF] → [ALB (C1)] → [EKS Cluster C1] ←──┐
                         (Frontend)           │
                         us-east-1            │
                                              │
                                    VPC Peering (Private)
                                              │
                         [EKS Cluster C2] ←──┘
                         (Backend)
                         us-west-2
                         (Internal Only - No Public Access)
```

**Key Security Requirements:**
- ✓ C1 frontend is publicly accessible via ALB + WAF
- ✓ C2 backend is private (no public IPs, internal load balancer)
- ✓ C1 → C2 communication over VPC peering only
- ✓ No direct internet access to C2 services
- ✓ Security groups enforce least-privilege access

## Integration with CI/CD

This tool can be integrated into deployment pipelines:

```yaml
# Example GitHub Actions workflow
- name: Security Verification
  run: |
    pip install -r security-verification/requirements.txt
    python security-verification/verify_security.py --output security-report.json

- name: Check Security Status
  run: |
    STATUS=$(jq -r '.summary.status' security-report.json)
    if [ "$STATUS" != "PASS" ]; then
      echo "Security verification failed!"
      exit 1
    fi
```

## Assignment Context

This tool fulfills the Ciroos hands-on assignment requirement:

> **4. Verification**
> Develop a Python-based verification tool that:
> 1. Confirms there are no unintended public access paths.
> 2. Validates that only the intended C1 → C2 communication is permitted.

The tool provides automated validation of the security controls implemented in the dual-region AWS EKS deployment.

## Support

For issues or questions:
1. Review the Troubleshooting section above
2. Check AWS CloudTrail logs for API call failures
3. Verify AWS credentials and permissions
4. Examine the generated JSON report for detailed error messages

## License

This tool is provided as-is for the Ciroos hands-on assignment demonstration.
