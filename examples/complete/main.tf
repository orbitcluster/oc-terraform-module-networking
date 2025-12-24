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

# Networking module with full features
module "networking" {
  source = "../.."

  vpc_cidr     = "10.0.0.0/16"
  cluster_name = "example-complete-cluster"
  env          = "prod"
  bu_id        = "comp"
  app_id       = "lete"

  # Customize AZs and subnets
  azs             = ["us-east-1a", "us-east-1b", "us-east-1c"]
  private_subnets = ["10.0.0.0/19", "10.0.32.0/19", "10.0.64.0/19"]
  public_subnets  = ["10.0.96.0/24", "10.0.97.0/24", "10.0.98.0/24"]

  # Enable all features
  enable_nat_gateway = true
  single_nat_gateway = false # HA NAT gateways

  enable_vpc_endpoints = true
  vpc_endpoints = {
    ssm         = true
    ssmmessages = true
    ec2messages = true
    kms         = true
    ecr_api     = true
    ecr_dkr     = true
    ec2         = true
    sts         = true
    logs        = true
    s3          = true
    dynamodb    = false
  }

  enable_flow_logs         = true
  flow_logs_retention_days = 30

  enable_network_load_balancer = true
  nlb_deletion_protection      = true

  enable_alb                  = true
  alb_deletion_protection     = false
  alb_ingress_cidr_blocks     = ["0.0.0.0/0"]

  enable_istio_support = true

  tags = {
    Project     = "ExampleComplete"
    ManagedBy   = "Terraform"
    Environment = "production"
  }
}

# Example EKS module integration
module "eks" {
  # checkov:skip=CKV_TF_1:Example usage
  # checkov:skip=CKV_TF_2:Example usage
  source = "github.com/orbitcluster/oc-terraform-module-eks"

  cluster_name        = "example-complete-cluster"
  env                 = "prod"
  vpc_id              = module.networking.vpc_id
  routable_subnet_ids = module.networking.private_subnet_ids

  # Use NLB target group
  target_group_arns = module.networking.nlb_target_group_arn != null ? [
    module.networking.nlb_target_group_arn
  ] : []

  extra_nodegroups = {
    "default" = "t3.medium"
  }
}

# Outputs
output "vpc_id" {
  value = module.networking.vpc_id
}

output "private_subnet_ids" {
  value = module.networking.private_subnet_ids
}

output "nlb_dns_name" {
  value = module.networking.nlb_dns_name
}

output "vpc_endpoints" {
  value = module.networking.vpc_endpoints
}

output "alb_dns_name" {
  value = module.networking.alb_dns_name
}
