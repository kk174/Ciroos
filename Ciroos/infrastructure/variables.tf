# ============================================
# variables.tf - Input Variables
# ============================================
# Variables make your code REUSABLE
# Instead of hardcoding "us-east-1", we use var.aws_region
# This way, same code can deploy to any region!
#
# ANALOGY: Like function parameters in programming
#          function deploy(region, environment) { ... }

# ------------------------------
# General Settings
# ------------------------------

variable "aws_region" {
  description = "AWS region to deploy to"
  type        = string
  default     = "us-east-1"

  # You could add validation rules:
  # validation {
  #   condition     = contains(["us-east-1", "us-west-2"], var.aws_region)
  #   error_message = "Only us-east-1 and us-west-2 are supported."
  # }
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Project name - used in resource naming"
  type        = string
  default     = "globalretail"
}

# ------------------------------
# VPC / Network Settings
# ------------------------------

variable "vpc_cidr" {
  description = "CIDR block for VPC (the IP address range)"
  type        = string
  default     = "10.0.0.0/16"  # Gives us 65,536 IP addresses

  # WHAT IS CIDR?
  # 10.0.0.0/16 means:
  # - Network starts at 10.0.0.0
  # - /16 means first 16 bits are fixed (10.0.x.x)
  # - We can use 10.0.0.1 through 10.0.255.254
}

variable "availability_zones" {
  description = "List of AZs to use (for high availability)"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]

  # WHY 2 AZs?
  # If one data center (AZ) fails, the other keeps running
  # This is the "Multi-AZ" high availability we discussed
}

# ------------------------------
# EKS / Kubernetes Settings
# ------------------------------

variable "cluster_name" {
  description = "Name for the EKS cluster"
  type        = string
  default     = "globalretail-demo"
}

variable "cluster_version" {
  description = "Kubernetes version for EKS"
  type        = string
  default     = "1.28"
}

variable "node_instance_type" {
  description = "EC2 instance type for EKS worker nodes"
  type        = string
  default     = "t3.medium"  # 2 vCPU, 4GB RAM - good for demos

  # INSTANCE TYPE CHEAT SHEET:
  # t3.micro  = 2 vCPU, 1GB RAM  (~$0.01/hr) - too small for K8s
  # t3.small  = 2 vCPU, 2GB RAM  (~$0.02/hr) - minimal
  # t3.medium = 2 vCPU, 4GB RAM  (~$0.04/hr) - good for demos ✓
  # t3.large  = 2 vCPU, 8GB RAM  (~$0.08/hr) - production-ish
}

variable "node_desired_count" {
  description = "Desired number of worker nodes"
  type        = number
  default     = 2  # One per AZ for high availability
}

variable "node_min_count" {
  description = "Minimum number of worker nodes"
  type        = number
  default     = 1
}

variable "node_max_count" {
  description = "Maximum number of worker nodes (for auto-scaling)"
  type        = number
  default     = 4
}

# ------------------------------
# RDS / Database Settings
# ------------------------------

variable "db_instance_class" {
  description = "RDS instance type"
  type        = string
  default     = "db.t3.micro"  # Smallest, ~$0.02/hr
}

variable "db_name" {
  description = "Name of the database to create"
  type        = string
  default     = "ecommerce"
}

variable "db_username" {
  description = "Master username for RDS"
  type        = string
  default     = "dbadmin"
}

variable "db_password" {
  description = "Master password for RDS (use terraform.tfvars!)"
  type        = string
  sensitive   = true  # Won't show in logs/output

  # SECURITY NOTE:
  # Never commit passwords to Git!
  # Put them in terraform.tfvars (which is in .gitignore)
  # Or better: use AWS Secrets Manager
}

variable "db_allocated_storage" {
  description = "Storage in GB for RDS"
  type        = number
  default     = 20
}

# ------------------------------
# ElastiCache / Redis Settings
# ------------------------------

variable "redis_node_type" {
  description = "ElastiCache node type"
  type        = string
  default     = "cache.t3.micro"  # Smallest, ~$0.02/hr
}

# ============================================
# WHAT YOU LEARNED:
# ============================================
# - Variables have: description, type, default value
# - type can be: string, number, bool, list, map
# - sensitive = true hides values in output (for passwords)
# - Variables are used as: var.variable_name
# - Override defaults in terraform.tfvars file
