# ============================================
# main-dual-region.tf - Dual-Region Infrastructure
# ============================================
# Creates infrastructure in us-east-1 (C1) and us-west-2 (C2)

# Get current AWS account info
data "aws_caller_identity" "current" {}

# Get available AZs in us-east-1
data "aws_availability_zones" "us_east_1" {
  provider = aws.us_east_1
  state    = "available"
}

# Get available AZs in us-west-2
data "aws_availability_zones" "us_west_2" {
  provider = aws.us_west_2
  state    = "available"
}

# ============================================
# CLUSTER C1 - US-EAST-1 (Frontend)
# ============================================

# VPC for Cluster C1
module "vpc_c1" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  providers = {
    aws = aws.us_east_1
  }

  name = "petclinic-c1-vpc"
  cidr = "10.0.0.0/16"

  azs = slice(data.aws_availability_zones.us_east_1.names, 0, 2)

  private_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets   = ["10.0.101.0/24", "10.0.102.0/24"]
  database_subnets = ["10.0.201.0/24", "10.0.202.0/24"]

  enable_nat_gateway   = true
  single_nat_gateway   = true  # Cost optimization
  enable_dns_hostnames = true
  enable_dns_support   = true

  create_database_subnet_group = true

  public_subnet_tags = {
    "kubernetes.io/role/elb"              = 1
    "kubernetes.io/cluster/petclinic-c1" = "owned"
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb"     = 1
    "kubernetes.io/cluster/petclinic-c1" = "owned"
  }

  tags = {
    Name    = "petclinic-c1-vpc"
    Cluster = "C1"
  }
}

# EKS Cluster C1
module "eks_c1" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.0"

  providers = {
    aws = aws.us_east_1
  }

  cluster_name    = "petclinic-c1"
  cluster_version = "1.30"

  vpc_id     = module.vpc_c1.vpc_id
  subnet_ids = module.vpc_c1.private_subnets

  cluster_endpoint_public_access = true
  enable_irsa                    = true

  eks_managed_node_groups = {
    default = {
      name           = "petclinic-c1-nodes"
      instance_types = ["t3.medium"]

      min_size     = 1
      max_size     = 4
      desired_size = 2

      disk_size = 50

      labels = {
        Environment = var.environment
        NodeGroup   = "c1-default"
        Cluster     = "C1"
      }
    }
  }

  manage_aws_auth_configmap = false  # Disabled to avoid Kubernetes provider connection issues during creation

  tags = {
    Name    = "petclinic-c1"
    Cluster = "C1"
  }
}

# RDS PostgreSQL for C1 (MySQL for Pet Clinic)
resource "aws_security_group" "rds_c1" {
  provider = aws.us_east_1

  name        = "petclinic-c1-rds-sg"
  description = "Security group for RDS in C1"
  vpc_id      = module.vpc_c1.vpc_id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [module.eks_c1.node_security_group_id]
    description     = "MySQL from EKS C1"
  }

  # Allow C2 EKS nodes to access RDS (cross-region via VPC peering)
  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["10.1.0.0/16"]  # C2 VPC CIDR
    description = "MySQL from EKS C2 via VPC peering"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "petclinic-c1-rds-sg"
  }
}

module "rds_c1" {
  source  = "terraform-aws-modules/rds/aws"
  version = "~> 6.0"

  providers = {
    aws = aws.us_east_1
  }

  identifier = "petclinic-c1-db"

  engine               = "mysql"
  engine_version       = "8.0"
  family               = "mysql8.0"
  major_engine_version = "8.0"
  instance_class       = "db.t3.micro"

  allocated_storage     = 20
  max_allocated_storage = 100

  db_name  = "petclinic"
  username = var.db_username
  password = var.db_password
  port     = 3306

  db_subnet_group_name   = module.vpc_c1.database_subnet_group_name
  vpc_security_group_ids = [aws_security_group.rds_c1.id]

  maintenance_window      = "Mon:00:00-Mon:03:00"
  backup_window           = "03:00-06:00"
  backup_retention_period = 7

  skip_final_snapshot = true
  deletion_protection = false

  performance_insights_enabled = false  # Not supported on db.t3.micro

  tags = {
    Name    = "petclinic-c1-db"
    Cluster = "C1"
  }
}

# ============================================
# CLUSTER C2 - US-WEST-2 (Backend)
# ============================================

# VPC for Cluster C2
module "vpc_c2" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  providers = {
    aws = aws.us_west_2
  }

  name = "petclinic-c2-vpc"
  cidr = "10.1.0.0/16"  # Different CIDR to avoid conflicts

  azs = slice(data.aws_availability_zones.us_west_2.names, 0, 2)

  private_subnets = ["10.1.1.0/24", "10.1.2.0/24"]
  public_subnets  = ["10.1.101.0/24", "10.1.102.0/24"]

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true
  enable_dns_support   = true

  public_subnet_tags = {
    "kubernetes.io/role/elb"              = 1
    "kubernetes.io/cluster/petclinic-c2" = "owned"
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb"     = 1
    "kubernetes.io/cluster/petclinic-c2" = "owned"
  }

  tags = {
    Name    = "petclinic-c2-vpc"
    Cluster = "C2"
  }
}

# EKS Cluster C2
module "eks_c2" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.0"

  providers = {
    aws = aws.us_west_2
  }

  cluster_name    = "petclinic-c2"
  cluster_version = "1.30"

  vpc_id     = module.vpc_c2.vpc_id
  subnet_ids = module.vpc_c2.private_subnets

  cluster_endpoint_public_access = true
  enable_irsa                    = true

  eks_managed_node_groups = {
    default = {
      name           = "petclinic-c2-nodes"
      instance_types = ["t3.medium"]

      min_size     = 1
      max_size     = 4
      desired_size = 2

      disk_size = 50

      labels = {
        Environment = var.environment
        NodeGroup   = "c2-default"
        Cluster     = "C2"
      }
    }
  }

  manage_aws_auth_configmap = false  # Disabled to avoid Kubernetes provider connection issues during creation

  tags = {
    Name    = "petclinic-c2"
    Cluster = "C2"
  }
}

# ============================================
# S3 BUCKET - SHARED LOG STORAGE
# ============================================

resource "aws_s3_bucket" "logs" {
  provider = aws.us_east_1
  bucket   = "petclinic-logs-${data.aws_caller_identity.current.account_id}"

  tags = {
    Name = "petclinic-logs"
  }
}

resource "aws_s3_bucket_versioning" "logs" {
  provider = aws.us_east_1
  bucket   = aws_s3_bucket.logs.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "logs" {
  provider = aws.us_east_1
  bucket   = aws_s3_bucket.logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "logs" {
  provider = aws.us_east_1
  bucket   = aws_s3_bucket.logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
