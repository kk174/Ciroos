# ============================================
# providers.tf - Provider Configuration
# ============================================
# This file configures HOW we connect to AWS
# 
# ANALOGY: This is like setting up your AWS CLI credentials
#          but in code form

# AWS Provider Configuration - Region 1 (us-east-1) - Cluster C1
provider "aws" {
  region = "us-east-1"
  alias  = "us_east_1"

  # Tags applied to ALL resources we create
  # Super helpful for cost tracking and organization
  default_tags {
    tags = {
      Project     = "ciroos-demo"
      Environment = var.environment
      ManagedBy   = "terraform"
      Owner       = "kanav"
      Region      = "us-east-1"
      Cluster     = "C1"
    }
  }
}

# AWS Provider Configuration - Region 2 (us-west-2) - Cluster C2
provider "aws" {
  region = "us-west-2"
  alias  = "us_west_2"

  default_tags {
    tags = {
      Project     = "ciroos-demo"
      Environment = var.environment
      ManagedBy   = "terraform"
      Owner       = "kanav"
      Region      = "us-west-2"
      Cluster     = "C2"
    }
  }
}

# Kubernetes Provider - Cluster C1 (us-east-1)
provider "kubernetes" {
  alias                  = "c1"
  host                   = module.eks_c1.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks_c1.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", module.eks_c1.cluster_name, "--region", "us-east-1"]
  }
}

# Kubernetes Provider - Cluster C2 (us-west-2)
provider "kubernetes" {
  alias                  = "c2"
  host                   = module.eks_c2.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks_c2.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", module.eks_c2.cluster_name, "--region", "us-west-2"]
  }
}

# Helm Provider - Cluster C1
provider "helm" {
  alias = "c1"
  kubernetes {
    host                   = module.eks_c1.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks_c1.cluster_certificate_authority_data)

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", module.eks_c1.cluster_name, "--region", "us-east-1"]
    }
  }
}

# Helm Provider - Cluster C2
provider "helm" {
  alias = "c2"
  kubernetes {
    host                   = module.eks_c2.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks_c2.cluster_certificate_authority_data)

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", module.eks_c2.cluster_name, "--region", "us-west-2"]
    }
  }
}

# ============================================
# WHAT YOU LEARNED:
# ============================================
# - provider "aws" tells Terraform to use AWS
# - region determines WHERE resources are created
# - default_tags automatically tag everything (great for billing!)
# - kubernetes and helm providers connect to EKS after it's created
