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

# Simple networking setup with defaults
module "networking" {
  source = "../.."

  vpc_name     = "simple-eks-vpc"
  cluster_name = "simple-cluster"
  env          = "dev"

  tags = {
    Project = "SimpleExample"
  }
}

# Example EKS module integration
# checkov:skip=CKV_TF_1:Example usage
# checkov:skip=CKV_TF_2:Example usage
module "eks" {
  source = "github.com/orbitcluster/oc-terraform-module-eks"

  cluster_name        = "simple-cluster"
  env                 = "dev"
  vpc_id              = module.networking.vpc_id
  routable_subnet_ids = module.networking.private_subnet_ids

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
