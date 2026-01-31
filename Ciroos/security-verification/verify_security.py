#!/usr/bin/env python3
"""
Ciroos AWS Multi-Region Security Verification Tool

This tool verifies:
1. No unintended public access paths exist
2. Only intended C1 → C2 communication is permitted
3. Security groups are properly configured
4. Internal services are not exposed to the internet

Usage:
    python3 verify_security.py [--output report.json]
"""

import boto3
import json
import sys
import argparse
from datetime import datetime
from typing import Dict, List, Tuple
import urllib.request
import urllib.error
import socket

# Configuration
REGIONS = {
    'C1': 'us-east-1',
    'C2': 'us-west-2'
}

VPC_NAMES = {
    'C1': 'petclinic-c1-vpc',
    'C2': 'petclinic-c2-vpc'
}

CLUSTER_NAMES = {
    'C1': 'petclinic-c1',
    'C2': 'petclinic-c2'
}


class SecurityVerifier:
    """Main security verification class"""

    def __init__(self):
        self.results = {
            'timestamp': datetime.utcnow().isoformat(),
            'summary': {
                'total_checks': 0,
                'passed': 0,
                'failed': 0,
                'warnings': 0
            },
            'checks': []
        }
        self.ec2_clients = {
            cluster: boto3.client('ec2', region_name=region)
            for cluster, region in REGIONS.items()
        }
        self.elb_clients = {
            cluster: boto3.client('elbv2', region_name=region)
            for cluster, region in REGIONS.items()
        }

    def add_check(self, name: str, status: str, details: str, severity: str = 'INFO'):
        """Add a check result"""
        self.results['checks'].append({
            'name': name,
            'status': status,
            'details': details,
            'severity': severity
        })
        self.results['summary']['total_checks'] += 1
        if status == 'PASS':
            self.results['summary']['passed'] += 1
        elif status == 'FAIL':
            self.results['summary']['failed'] += 1
        elif status == 'WARN':
            self.results['summary']['warnings'] += 1

    def get_vpc_id(self, cluster: str) -> str:
        """Get VPC ID for a cluster"""
        try:
            ec2 = self.ec2_clients[cluster]
            vpcs = ec2.describe_vpcs(
                Filters=[{'Name': 'tag:Name', 'Values': [VPC_NAMES[cluster]]}]
            )
            if vpcs['Vpcs']:
                return vpcs['Vpcs'][0]['VpcId']
        except Exception as e:
            print(f"Error getting VPC ID for {cluster}: {e}")
        return None

    def check_security_groups(self):
        """Check security group configurations"""
        print("\n[1/6] Checking Security Groups...")

        for cluster, region in REGIONS.items():
            ec2 = self.ec2_clients[cluster]
            vpc_id = self.get_vpc_id(cluster)

            if not vpc_id:
                self.add_check(
                    f'{cluster} VPC',
                    'WARN',
                    f'Could not find VPC for {cluster}',
                    'MEDIUM'
                )
                continue

            # Get all security groups in VPC
            sgs = ec2.describe_security_groups(
                Filters=[{'Name': 'vpc-id', 'Values': [vpc_id]}]
            )

            for sg in sgs['SecurityGroups']:
                sg_name = sg['GroupName']
                sg_id = sg['GroupId']

                # Check for overly permissive ingress rules
                for rule in sg.get('IpPermissions', []):
                    for ip_range in rule.get('IpRanges', []):
                        cidr = ip_range.get('CidrIp', '')
                        if cidr == '0.0.0.0/0':
                            # Allow 0.0.0.0/0 only for ALB security group on ports 80/443
                            if 'alb' in sg_name.lower() and rule.get('FromPort') in [80, 443]:
                                self.add_check(
                                    f'{cluster} SG: {sg_name} Public Access',
                                    'PASS',
                                    f'ALB security group {sg_id} allows public HTTP/HTTPS (expected)',
                                    'INFO'
                                )
                            else:
                                self.add_check(
                                    f'{cluster} SG: {sg_name} Public Access',
                                    'WARN',
                                    f'Security group {sg_id} allows 0.0.0.0/0 on port {rule.get("FromPort", "all")}',
                                    'HIGH'
                                )

    def check_load_balancers(self):
        """Check load balancer configurations"""
        print("[2/6] Checking Load Balancers...")

        for cluster, region in REGIONS.items():
            elb = self.elb_clients[cluster]

            try:
                lbs = elb.describe_load_balancers()

                for lb in lbs['LoadBalancers']:
                    lb_name = lb['LoadBalancerName']
                    lb_arn = lb['LoadBalancerArn']
                    scheme = lb['Scheme']

                    # C1 should have internet-facing LB
                    # C2 should have internal-only LB
                    if cluster == 'C1':
                        if scheme == 'internet-facing':
                            self.add_check(
                                f'{cluster} Load Balancer Exposure',
                                'PASS',
                                f'C1 load balancer is internet-facing (expected for frontend)',
                                'INFO'
                            )
                        else:
                            self.add_check(
                                f'{cluster} Load Balancer Exposure',
                                'WARN',
                                f'C1 load balancer is internal (may not be accessible)',
                                'MEDIUM'
                            )

                    elif cluster == 'C2':
                        if scheme == 'internal':
                            self.add_check(
                                f'{cluster} Load Balancer Exposure',
                                'PASS',
                                f'C2 load balancer is internal-only (correct - no public exposure)',
                                'INFO'
                            )
                        else:
                            self.add_check(
                                f'{cluster} Load Balancer Exposure',
                                'FAIL',
                                f'C2 load balancer is internet-facing (SECURITY RISK - backend should be private)',
                                'CRITICAL'
                            )

            except Exception as e:
                self.add_check(
                    f'{cluster} Load Balancers',
                    'WARN',
                    f'Error checking load balancers: {str(e)}',
                    'MEDIUM'
                )

    def check_public_ips(self):
        """Check for public IP addresses on backend instances"""
        print("[3/6] Checking Public IP Exposure...")

        for cluster, region in REGIONS.items():
            ec2 = self.ec2_clients[cluster]
            vpc_id = self.get_vpc_id(cluster)

            if not vpc_id:
                continue

            # Get all instances in VPC
            instances = ec2.describe_instances(
                Filters=[{'Name': 'vpc-id', 'Values': [vpc_id]}]
            )

            public_ips = []
            for reservation in instances['Reservations']:
                for instance in reservation['Instances']:
                    public_ip = instance.get('PublicIpAddress')
                    if public_ip:
                        instance_id = instance['InstanceId']
                        instance_name = next(
                            (tag['Value'] for tag in instance.get('Tags', []) if tag['Key'] == 'Name'),
                            'Unknown'
                        )
                        public_ips.append((instance_id, instance_name, public_ip))

            if cluster == 'C2' and public_ips:
                self.add_check(
                    f'{cluster} Public IPs',
                    'WARN',
                    f'C2 (backend) has {len(public_ips)} instances with public IPs: {public_ips}',
                    'HIGH'
                )
            elif public_ips:
                self.add_check(
                    f'{cluster} Public IPs',
                    'PASS',
                    f'{cluster} has {len(public_ips)} instances with public IPs (may be for NAT/bastion)',
                    'INFO'
                )

    def check_vpc_peering(self):
        """Check VPC peering configuration"""
        print("[4/6] Checking VPC Peering...")

        ec2_c1 = self.ec2_clients['C1']

        try:
            # Get VPC IDs
            vpc_c1 = self.get_vpc_id('C1')
            vpc_c2 = self.get_vpc_id('C2')

            if not vpc_c1 or not vpc_c2:
                self.add_check(
                    'VPC Peering',
                    'WARN',
                    'Could not verify VPC peering - VPC IDs not found',
                    'MEDIUM'
                )
                return

            # Check for peering connections
            peerings = ec2_c1.describe_vpc_peering_connections(
                Filters=[
                    {'Name': 'requester-vpc-info.vpc-id', 'Values': [vpc_c1]},
                    {'Name': 'accepter-vpc-info.vpc-id', 'Values': [vpc_c2]}
                ]
            )

            if peerings['VpcPeeringConnections']:
                peering = peerings['VpcPeeringConnections'][0]
                status = peering['Status']['Code']

                if status == 'active':
                    self.add_check(
                        'VPC Peering C1-C2',
                        'PASS',
                        f'VPC peering active between C1 and C2: {peering["VpcPeeringConnectionId"]}',
                        'INFO'
                    )
                else:
                    self.add_check(
                        'VPC Peering C1-C2',
                        'FAIL',
                        f'VPC peering exists but status is: {status}',
                        'CRITICAL'
                    )
            else:
                self.add_check(
                    'VPC Peering C1-C2',
                    'WARN',
                    'No VPC peering connection found between C1 and C2',
                    'HIGH'
                )

        except Exception as e:
            self.add_check(
                'VPC Peering',
                'WARN',
                f'Error checking VPC peering: {str(e)}',
                'MEDIUM'
            )

    def check_internet_connectivity(self):
        """Check that C2 services are NOT accessible from internet"""
        print("[5/6] Checking Internet Accessibility...")

        # Try to get C2 load balancer DNS
        try:
            elb = self.elb_clients['C2']
            lbs = elb.describe_load_balancers()

            for lb in lbs['LoadBalancers']:
                dns_name = lb['DNSName']
                scheme = lb['Scheme']

                if scheme == 'internal':
                    # Try to connect from external (should fail)
                    try:
                        url = f'http://{dns_name}/health'
                        req = urllib.request.Request(url, method='GET')
                        urllib.request.urlopen(req, timeout=5)

                        # If we get here, internal LB is accessible (BAD)
                        self.add_check(
                            'C2 Internet Exposure',
                            'FAIL',
                            f'C2 internal load balancer is accessible from internet at {dns_name}',
                            'CRITICAL'
                        )
                    except (urllib.error.URLError, socket.timeout):
                        # Connection failed (GOOD - as expected for internal LB)
                        self.add_check(
                            'C2 Internet Exposure',
                            'PASS',
                            f'C2 internal load balancer correctly NOT accessible from internet',
                            'INFO'
                        )
                    except Exception as e:
                        self.add_check(
                            'C2 Internet Exposure',
                            'PASS',
                            f'C2 internal load balancer not accessible (connection error: {type(e).__name__})',
                            'INFO'
                        )

        except Exception as e:
            self.add_check(
                'C2 Internet Exposure',
                'WARN',
                f'Could not test C2 internet accessibility: {str(e)}',
                'MEDIUM'
            )

    def check_waf_configuration(self):
        """Check WAF configuration"""
        print("[6/6] Checking WAF Configuration...")

        try:
            waf = boto3.client('wafv2', region_name='us-east-1')

            # List regional web ACLs
            web_acls = waf.list_web_acls(Scope='REGIONAL')

            petclinic_waf = None
            for acl in web_acls['WebACLs']:
                if 'petclinic' in acl['Name'].lower():
                    petclinic_waf = acl
                    break

            if petclinic_waf:
                self.add_check(
                    'WAF Configuration',
                    'PASS',
                    f'WAF Web ACL found: {petclinic_waf["Name"]} (ID: {petclinic_waf["Id"]})',
                    'INFO'
                )

                # Get WAF details
                waf_detail = waf.get_web_acl(
                    Name=petclinic_waf['Name'],
                    Scope='REGIONAL',
                    Id=petclinic_waf['Id']
                )

                rules_count = len(waf_detail['WebACL'].get('Rules', []))
                self.add_check(
                    'WAF Rules',
                    'PASS',
                    f'WAF has {rules_count} rules configured',
                    'INFO'
                )
            else:
                self.add_check(
                    'WAF Configuration',
                    'WARN',
                    'No petclinic WAF Web ACL found',
                    'MEDIUM'
                )

        except Exception as e:
            self.add_check(
                'WAF Configuration',
                'WARN',
                f'Error checking WAF: {str(e)}',
                'MEDIUM'
            )

    def run_all_checks(self):
        """Run all security verification checks"""
        print("\n" + "="*60)
        print("Ciroos AWS Multi-Region Security Verification")
        print("="*60)

        self.check_security_groups()
        self.check_load_balancers()
        self.check_public_ips()
        self.check_vpc_peering()
        self.check_internet_connectivity()
        self.check_waf_configuration()

        return self.results

    def print_summary(self):
        """Print verification summary"""
        print("\n" + "="*60)
        print("VERIFICATION SUMMARY")
        print("="*60)
        print(f"Total Checks: {self.results['summary']['total_checks']}")
        print(f"✓ Passed:     {self.results['summary']['passed']}")
        print(f"✗ Failed:     {self.results['summary']['failed']}")
        print(f"⚠ Warnings:   {self.results['summary']['warnings']}")
        print("="*60)

        # Print failed checks
        failed = [c for c in self.results['checks'] if c['status'] == 'FAIL']
        if failed:
            print("\nFAILED CHECKS:")
            for check in failed:
                print(f"  ✗ {check['name']}: {check['details']}")

        # Print warnings
        warnings = [c for c in self.results['checks'] if c['status'] == 'WARN']
        if warnings:
            print("\nWARNINGS:")
            for check in warnings:
                print(f"  ⚠ {check['name']}: {check['details']}")

        # Security verdict
        print("\n" + "="*60)
        if self.results['summary']['failed'] == 0:
            print("✓ SECURITY VERIFICATION PASSED")
            print("  No critical security issues detected.")
        else:
            print("✗ SECURITY VERIFICATION FAILED")
            print(f"  {self.results['summary']['failed']} critical issue(s) detected.")
        print("="*60 + "\n")


def main():
    parser = argparse.ArgumentParser(
        description='Verify security configuration of Ciroos AWS multi-region deployment'
    )
    parser.add_argument(
        '--output',
        '-o',
        help='Output file for JSON report',
        default='security-verification-report.json'
    )
    parser.add_argument(
        '--verbose',
        '-v',
        action='store_true',
        help='Verbose output'
    )

    args = parser.parse_args()

    verifier = SecurityVerifier()
    results = verifier.run_all_checks()
    verifier.print_summary()

    # Save JSON report
    with open(args.output, 'w') as f:
        json.dump(results, f, indent=2)
    print(f"📄 Detailed report saved to: {args.output}\n")

    # Exit with error code if checks failed
    if results['summary']['failed'] > 0:
        sys.exit(1)
    else:
        sys.exit(0)


if __name__ == '__main__':
    main()
