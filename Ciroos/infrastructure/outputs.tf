# ============================================
# outputs-dual-region.tf - Infrastructure Outputs
# ============================================
# Values you'll need after deployment

# ============================================
# CLUSTER C1 (us-east-1) OUTPUTS
# ============================================

output "c1_cluster_name" {
  description = "EKS Cluster C1 name"
  value       = module.eks_c1.cluster_name
}

output "c1_cluster_endpoint" {
  description = "EKS Cluster C1 endpoint"
  value       = module.eks_c1.cluster_endpoint
}

output "c1_configure_kubectl" {
  description = "Command to configure kubectl for C1"
  value       = "aws eks update-kubeconfig --region us-east-1 --name ${module.eks_c1.cluster_name}"
}

output "c1_vpc_id" {
  description = "VPC ID for C1"
  value       = module.vpc_c1.vpc_id
}

output "c1_vpc_cidr" {
  description = "VPC CIDR for C1"
  value       = module.vpc_c1.vpc_cidr_block
}

output "c1_private_subnets" {
  description = "Private subnet IDs in C1"
  value       = module.vpc_c1.private_subnets
}

output "c1_public_subnets" {
  description = "Public subnet IDs in C1"
  value       = module.vpc_c1.public_subnets
}

output "c1_rds_endpoint" {
  description = "RDS endpoint for C1"
  value       = module.rds_c1.db_instance_endpoint
}

output "c1_rds_connection_string" {
  description = "MySQL connection string for C1"
  value       = "mysql://${var.db_username}:${var.db_password}@${module.rds_c1.db_instance_endpoint}/petclinic"
  sensitive   = true
}

# ============================================
# CLUSTER C2 (us-west-2) OUTPUTS
# ============================================

output "c2_cluster_name" {
  description = "EKS Cluster C2 name"
  value       = module.eks_c2.cluster_name
}

output "c2_cluster_endpoint" {
  description = "EKS Cluster C2 endpoint"
  value       = module.eks_c2.cluster_endpoint
}

output "c2_configure_kubectl" {
  description = "Command to configure kubectl for C2"
  value       = "aws eks update-kubeconfig --region us-west-2 --name ${module.eks_c2.cluster_name}"
}

output "c2_vpc_id" {
  description = "VPC ID for C2"
  value       = module.vpc_c2.vpc_id
}

output "c2_vpc_cidr" {
  description = "VPC CIDR for C2"
  value       = module.vpc_c2.vpc_cidr_block
}

output "c2_private_subnets" {
  description = "Private subnet IDs in C2"
  value       = module.vpc_c2.private_subnets
}

output "c2_public_subnets" {
  description = "Public subnet IDs in C2"
  value       = module.vpc_c2.public_subnets
}

# ============================================
# VPC PEERING OUTPUTS
# ============================================

output "vpc_peering_connection_id" {
  description = "VPC Peering connection ID"
  value       = aws_vpc_peering_connection.c1_to_c2.id
}

output "vpc_peering_status" {
  description = "VPC Peering connection status"
  value       = aws_vpc_peering_connection.c1_to_c2.accept_status
}

# ============================================
# WAF OUTPUTS
# ============================================

output "waf_web_acl_id" {
  description = "WAF Web ACL ID"
  value       = aws_wafv2_web_acl.petclinic.id
}

output "waf_web_acl_arn" {
  description = "WAF Web ACL ARN (use in ALB Ingress annotation)"
  value       = aws_wafv2_web_acl.petclinic.arn
}

# ============================================
# SHARED RESOURCES OUTPUTS
# ============================================

output "logs_bucket_name" {
  description = "S3 bucket for logs"
  value       = aws_s3_bucket.logs.id
}

output "logs_bucket_arn" {
  description = "S3 bucket ARN"
  value       = aws_s3_bucket.logs.arn
}

output "aws_account_id" {
  description = "AWS Account ID"
  value       = data.aws_caller_identity.current.account_id
}

# ============================================
# DEPLOYMENT SUMMARY
# ============================================

output "deployment_summary" {
  description = "Deployment summary with next steps"
  value       = <<-EOT
    ╔══════════════════════════════════════════════════════════════════╗
    ║     CIROOS DEMO - DUAL-REGION INFRASTRUCTURE DEPLOYED!           ║
    ╠══════════════════════════════════════════════════════════════════╣
    ║                                                                  ║
    ║  🌍 CLUSTER C1 (us-east-1) - Frontend                            ║
    ║     EKS Cluster: ${module.eks_c1.cluster_name}
    ║     VPC CIDR: ${module.vpc_c1.vpc_cidr_block}
    ║     Configure: aws eks update-kubeconfig --region us-east-1 --name ${module.eks_c1.cluster_name}
    ║                                                                  ║
    ║  🌎 CLUSTER C2 (us-west-2) - Backend                             ║
    ║     EKS Cluster: ${module.eks_c2.cluster_name}
    ║     VPC CIDR: ${module.vpc_c2.vpc_cidr_block}
    ║     Configure: aws eks update-kubeconfig --region us-west-2 --name ${module.eks_c2.cluster_name}
    ║                                                                  ║
    ║  🔗 CONNECTIVITY                                                 ║
    ║     VPC Peering: ${aws_vpc_peering_connection.c1_to_c2.id}
    ║     Status: ${aws_vpc_peering_connection.c1_to_c2.accept_status}
    ║                                                                  ║
    ║  🛡️  SECURITY                                                     ║
    ║     WAF Web ACL: ${aws_wafv2_web_acl.petclinic.name}
    ║     WAF ARN: ${aws_wafv2_web_acl.petclinic.arn}
    ║                                                                  ║
    ║  📊 NEXT STEPS:                                                  ║
    ║  1. Deploy Pet Clinic microservices to both clusters            ║
    ║  2. Configure Ingress with ALB + WAF                             ║
    ║  3. Set up Splunk Observability                                  ║
    ║  4. Test cross-region connectivity                               ║
    ║  5. Run security verification tool                               ║
    ║                                                                  ║
    ╚══════════════════════════════════════════════════════════════════╝
  EOT
}
