locals {
  # Auto-detect AZs if not provided
  azs = length(var.azs) > 0 ? var.azs : slice(data.aws_availability_zones.available.names, 0, min(3, length(data.aws_availability_zones.available.names)))

  # Auto-calculate subnet CIDRs if not provided
  # Private subnets: 10.0.0.0/19, 10.0.32.0/19, 10.0.64.0/19
  # Public subnets: 10.0.96.0/24, 10.0.97.0/24, 10.0.98.0/24
  private_subnets = length(var.private_subnets) > 0 ? var.private_subnets : [
    for idx, az in local.azs : cidrsubnet(var.vpc_cidr, 3, idx)
  ]

  public_subnets = length(var.public_subnets) > 0 ? var.public_subnets : [
    for idx, az in local.azs : cidrsubnet(var.vpc_cidr, 8, 96 + idx)
  ]

  # Common tags for all resources
  common_tags = merge(
    var.tags,
    {
      Environment = var.env
      ManagedBy   = "Terraform"
      Module      = "oc-terraform-module-networking"
    }
  )

  # EKS-specific tags for subnets
  eks_tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }

  # Public subnet tags for ELB
  public_subnet_tags = merge(
    local.eks_tags,
    {
      "kubernetes.io/role/elb" = "1"
    }
  )

  # Private subnet tags for internal ELB
  private_subnet_tags = merge(
    local.eks_tags,
    {
      "kubernetes.io/role/internal-elb" = "1"
    }
  )
}
