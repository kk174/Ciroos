# ============================================
# versions.tf - Terraform & Provider Versions
# ============================================
# This file tells Terraform:
# 1. What version of Terraform is required
# 2. What providers (plugins) we need and their versions
#
# ANALOGY: Think of this like package.json in Node.js
#          or requirements.txt in Python

terraform {
  # Minimum Terraform version required
  required_version = ">= 1.0"

  # Providers are plugins that let Terraform talk to cloud APIs
  required_providers {
    # AWS Provider - lets us create AWS resources
    aws = {
      source  = "hashicorp/aws"  # Where to download from
      version = "~> 5.0"         # Version 5.x (any 5.something)
    }

    # Kubernetes Provider - lets us deploy to K8s
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }

    # Helm Provider - lets us install Helm charts (pre-packaged K8s apps)
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.11"
    }
  }
}

# ============================================
# WHAT YOU LEARNED:
# ============================================
# - Terraform uses "providers" to talk to different clouds
# - Version constraints (~> 5.0) mean "5.x but not 6.x"
# - This ensures everyone on your team uses compatible versions
