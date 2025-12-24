terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.15.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# Cost-optimized networking for development
module "networking" {
  source = "../.."


  cluster_name = "dev-cluster"
  env          = "dev"
  bu_id        = "cost"
  app_id       = "optim"

  # Single NAT gateway to reduce costs
  enable_nat_gateway = true
  single_nat_gateway = true

  # Disable VPC endpoints to reduce costs
  enable_vpc_endpoints = false

  # Disable flow logs
  enable_flow_logs = false

  # No NLB
  enable_network_load_balancer = false

  tags = {
    Project     = "CostOptimizedExample"
    Environment = "development"
  }
}

# Example EKS module integration
module "eks" {
  # checkov:skip=CKV_TF_1:Example usage
  # checkov:skip=CKV_TF_2:Example usage
  source = "github.com/orbitcluster/oc-terraform-module-eks"

  cluster_name        = "dev-cluster"
  env                 = "dev"
  vpc_id              = module.networking.vpc_id
  routable_subnet_ids = module.networking.private_subnet_ids

  extra_nodegroups = {
    "default" = "t3.small"
  }
}

# Outputs
output "vpc_id" {
  value = module.networking.vpc_id
}

output "private_subnet_ids" {
  value = module.networking.private_subnet_ids
}

output "estimated_monthly_cost" {
  value = "~$32/month (single NAT gateway)"
}
