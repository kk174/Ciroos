# ============================================
# vpc-peering.tf - Cross-Region VPC Peering
# ============================================
# Enables private connectivity between C1 (us-east-1) and C2 (us-west-2)

# Create VPC peering connection from C1 to C2
resource "aws_vpc_peering_connection" "c1_to_c2" {
  provider = aws.us_east_1

  vpc_id      = module.vpc_c1.vpc_id
  peer_vpc_id = module.vpc_c2.vpc_id
  peer_region = "us-west-2"

  auto_accept = false

  tags = {
    Name = "petclinic-c1-to-c2-peering"
    Side = "Requester"
  }
}

# Accept the peering connection in C2
resource "aws_vpc_peering_connection_accepter" "c2_accept" {
  provider = aws.us_west_2

  vpc_peering_connection_id = aws_vpc_peering_connection.c1_to_c2.id
  auto_accept               = true

  tags = {
    Name = "petclinic-c1-to-c2-peering"
    Side = "Accepter"
  }
}

# Enable DNS resolution across peering connection (C1 side)
resource "aws_vpc_peering_connection_options" "c1" {
  provider = aws.us_east_1

  vpc_peering_connection_id = aws_vpc_peering_connection.c1_to_c2.id

  requester {
    allow_remote_vpc_dns_resolution = true
  }

  depends_on = [aws_vpc_peering_connection_accepter.c2_accept]
}

# Enable DNS resolution across peering connection (C2 side)
resource "aws_vpc_peering_connection_options" "c2" {
  provider = aws.us_west_2

  vpc_peering_connection_id = aws_vpc_peering_connection.c1_to_c2.id

  accepter {
    allow_remote_vpc_dns_resolution = true
  }

  depends_on = [aws_vpc_peering_connection_accepter.c2_accept]
}

# ============================================
# ROUTE TABLES - C1 to C2 Traffic
# ============================================

# Add routes in C1 private subnets to reach C2
resource "aws_route" "c1_to_c2_private" {
  provider = aws.us_east_1
  count    = length(module.vpc_c1.private_route_table_ids)

  route_table_id            = module.vpc_c1.private_route_table_ids[count.index]
  destination_cidr_block    = module.vpc_c2.vpc_cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.c1_to_c2.id

  depends_on = [aws_vpc_peering_connection_accepter.c2_accept]
}

# Add routes in C1 public subnets to reach C2 (for ALB health checks if needed)
resource "aws_route" "c1_to_c2_public" {
  provider = aws.us_east_1
  count    = length(module.vpc_c1.public_route_table_ids)

  route_table_id            = module.vpc_c1.public_route_table_ids[count.index]
  destination_cidr_block    = module.vpc_c2.vpc_cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.c1_to_c2.id

  depends_on = [aws_vpc_peering_connection_accepter.c2_accept]
}

# ============================================
# ROUTE TABLES - C2 to C1 Traffic
# ============================================

# Add routes in C2 private subnets to reach C1
resource "aws_route" "c2_to_c1_private" {
  provider = aws.us_west_2
  count    = length(module.vpc_c2.private_route_table_ids)

  route_table_id            = module.vpc_c2.private_route_table_ids[count.index]
  destination_cidr_block    = module.vpc_c1.vpc_cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.c1_to_c2.id

  depends_on = [aws_vpc_peering_connection_accepter.c2_accept]
}

# Add routes in C2 public subnets to reach C1
resource "aws_route" "c2_to_c1_public" {
  provider = aws.us_west_2
  count    = length(module.vpc_c2.public_route_table_ids)

  route_table_id            = module.vpc_c2.public_route_table_ids[count.index]
  destination_cidr_block    = module.vpc_c1.vpc_cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.c1_to_c2.id

  depends_on = [aws_vpc_peering_connection_accepter.c2_accept]
}

# ============================================
# SECURITY GROUPS - Cross-Region Communication
# ============================================

# Allow C1 EKS nodes to communicate with C2 services
resource "aws_security_group_rule" "c1_to_c2_api" {
  provider = aws.us_east_1

  type              = "egress"
  from_port         = 8080
  to_port           = 8082
  protocol          = "tcp"
  cidr_blocks       = [module.vpc_c2.vpc_cidr_block]
  security_group_id = module.eks_c1.node_security_group_id
  description       = "Allow C1 to call C2 services"
}

# Allow C2 EKS nodes to receive traffic from C1
resource "aws_security_group_rule" "c2_from_c1_api" {
  provider = aws.us_west_2

  type              = "ingress"
  from_port         = 8080
  to_port           = 8082
  protocol          = "tcp"
  cidr_blocks       = [module.vpc_c1.vpc_cidr_block]
  security_group_id = module.eks_c2.node_security_group_id
  description       = "Allow C2 to receive from C1"
}

# Allow C2 to respond back to C1 (return traffic)
resource "aws_security_group_rule" "c2_to_c1_response" {
  provider = aws.us_west_2

  type              = "egress"
  from_port         = 0
  to_port           = 65535
  protocol          = "tcp"
  cidr_blocks       = [module.vpc_c1.vpc_cidr_block]
  security_group_id = module.eks_c2.node_security_group_id
  description       = "Allow C2 to respond to C1"
}
