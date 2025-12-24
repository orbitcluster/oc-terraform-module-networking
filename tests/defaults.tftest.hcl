variables {

  cluster_name = "test-cluster"
  env          = "test"
  bu_id        = "test"
  app_id       = "app"
  vpc_cidr     = "10.0.0.0/16"
  azs          = ["us-east-1a", "us-east-1b"]
}

run "defaults" {
  command = plan

  assert {
    condition     = module.vpc.name == "test-vpc-app"
    error_message = "VPC name did not match expected value"
  }

  assert {
    condition     = module.vpc.vpc_cidr_block == "10.0.0.0/16"
    error_message = "VPC CIDR did not match expected value"
  }

  assert {
    condition     = length(module.vpc.private_subnets) == 2
    error_message = "Number of private subnets did not match expected value (2 AZs)"
  }

  assert {
    condition     = length(module.vpc.public_subnets) == 2
    error_message = "Number of public subnets did not match expected value (2 AZs)"
  }
}

run "cost_optimized" {
  command = plan

  variables {
    single_nat_gateway   = true
    enable_vpc_endpoints = false
    enable_flow_logs     = false
  }

  assert {
    condition     = length(module.vpc.natgw_ids) == 1
    error_message = "Single NAT gateway should create exactly 1 NAT gateway"
  }
}

run "features_enabled" {
  command = plan

  variables {
    enable_network_load_balancer = true
    enable_istio_support         = true
    enable_vpc_endpoints         = true
  }

  assert {
    condition     = length(aws_security_group.istio) == 1
    error_message = "Istio security group should be created when enabled"
  }
}
