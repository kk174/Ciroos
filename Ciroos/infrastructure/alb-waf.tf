# ============================================
# alb-waf.tf - Application Load Balancer + WAF
# ============================================
# Deployed in us-east-1 (C1) to protect Pet Clinic frontend

# ============================================
# WAF Web ACL
# ============================================

resource "aws_wafv2_web_acl" "petclinic" {
  provider = aws.us_east_1

  name  = "petclinic-waf"
  scope = "REGIONAL"  # For ALB (use CLOUDFRONT for CloudFront)

  default_action {
    allow {}
  }

  # AWS Managed Rule - Common Rule Set (OWASP Top 10)
  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 1

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSManagedRulesCommonRuleSetMetric"
      sampled_requests_enabled   = true
    }
  }

  # AWS Managed Rule - Known Bad Inputs
  rule {
    name     = "AWSManagedRulesKnownBadInputsRuleSet"
    priority = 2

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSManagedRulesKnownBadInputsMetric"
      sampled_requests_enabled   = true
    }
  }

  # AWS Managed Rule - SQL Injection
  rule {
    name     = "AWSManagedRulesSQLiRuleSet"
    priority = 3

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesSQLiRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSManagedRulesSQLiMetric"
      sampled_requests_enabled   = true
    }
  }

  # Rate limiting rule - prevent DDoS
  rule {
    name     = "RateLimitRule"
    priority = 4

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = 2000  # requests per 5 minutes from single IP
        aggregate_key_type = "IP"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "RateLimitMetric"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "petclinic-waf"
    sampled_requests_enabled   = true
  }

  tags = {
    Name = "petclinic-waf"
  }
}

# ============================================
# WAF Logging to S3
# ============================================
# Note: Disabled - WAF requires CloudWatch Logs or Kinesis Firehose for logging
# S3 direct logging is not supported. Can be enabled later with proper setup.

# resource "aws_wafv2_web_acl_logging_configuration" "petclinic" {
#   provider = aws.us_east_1
#
#   resource_arn            = aws_wafv2_web_acl.petclinic.arn
#   log_destination_configs = [aws_s3_bucket.logs.arn]
#
#   depends_on = [aws_s3_bucket_public_access_block.logs]
# }

# ============================================
# SECURITY GROUP FOR ALB
# ============================================

resource "aws_security_group" "alb" {
  provider = aws.us_east_1

  name        = "petclinic-alb-sg"
  description = "Security group for Pet Clinic ALB"
  vpc_id      = module.vpc_c1.vpc_id

  # Allow HTTP from internet
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP from internet"
  }

  # Allow HTTPS from internet
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS from internet"
  }

  # Allow outbound to EKS nodes on app port
  egress {
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [module.eks_c1.node_security_group_id]
    description     = "To EKS nodes"
  }

  # Allow all outbound (for health checks, etc.)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "All outbound"
  }

  tags = {
    Name = "petclinic-alb-sg"
  }
}

# Allow ALB to reach EKS nodes
resource "aws_security_group_rule" "eks_from_alb" {
  provider = aws.us_east_1

  type                     = "ingress"
  from_port                = 8080
  to_port                  = 8080
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb.id
  security_group_id        = module.eks_c1.node_security_group_id
  description              = "Allow ALB to reach EKS pods"
}
