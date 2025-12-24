# oc-terraform-module-networking

A comprehensive Terraform module for setting up AWS networking infrastructure required for EKS clusters. This module provides a one-stop solution for VPC, subnets, NAT gateways, security groups, VPC endpoints, and optional Network Load Balancer configuration.

## Features

- 🌐 **Complete VPC Setup** - VPC with configurable CIDR blocks and DNS settings
- 🏢 **Multi-AZ Architecture** - High availability across multiple availability zones
- 🔒 **Private & Public Subnets** - Auto-calculated subnet CIDRs with proper EKS tagging
- 🚀 **NAT Gateway** - HA or single NAT gateway options for cost optimization
- 🔐 **Security Groups** - Pre-configured for EKS nodes, control plane, and VPC endpoints
- 🔌 **VPC Endpoints** - Interface and gateway endpoints for AWS services (SSM, KMS, ECR, S3, etc.)
- ⚖️ **Network Load Balancer** - Optional NLB for external access
- 🕸️ **Service Mesh Ready** - Optional Istio security group configuration
- 📊 **VPC Flow Logs** - Optional CloudWatch logging for network traffic analysis
- 🏷️ **EKS Auto-Discovery** - Proper subnet tagging for automatic EKS integration

## Architecture

This module implements the following AWS networking architecture:

- **VPC** with configurable CIDR (default: `10.0.0.0/16`)
- **Public Subnets** across multiple AZs for NAT gateways and load balancers
- **Private Subnets** across multiple AZs for EKS nodes and pods
- **Internet Gateway** for public subnet internet access
- **NAT Gateways** for private subnet outbound internet access
- **VPC Endpoints** to reduce NAT costs and improve security
- **Security Groups** for nodes, control plane, and VPC endpoints
- **Optional Network Load Balancer** for TCP 443 traffic

## Usage

### Comprehensive Example with All Parameters

```hcl
module "networking" {
  source = "github.com/orbitcluster/oc-terraform-module-networking"

  # ===================================
  # Required Parameters
  # ===================================

  # Business Unit ID
  bu_id = "marketing"

  # Application ID
  app_id = "ecommerce"

  # EKS cluster name - used for subnet tagging and auto-discovery
  cluster_name = "production-cluster"

  # Environment: dev, staging, or prod
  env = "prod"

  # ===================================
  # VPC Configuration (Optional)
  # ===================================

  # VPC CIDR block (default: "10.0.0.0/16")
  vpc_cidr = "10.0.0.0/16"

  # Availability zones (default: auto-detect 2-3 AZs in region)
  azs = ["us-east-1a", "us-east-1b", "us-east-1c"]

  # Private subnet CIDRs (default: auto-calculated from vpc_cidr)
  # These subnets will host EKS worker nodes and pods
  private_subnets = ["10.0.0.0/19", "10.0.32.0/19", "10.0.64.0/19"]

  # Public subnet CIDRs (default: auto-calculated from vpc_cidr)
  # These subnets will host NAT gateways and load balancers
  public_subnets = ["10.0.96.0/24", "10.0.97.0/24", "10.0.98.0/24"]

  # Enable DNS hostnames in VPC (default: true)
  enable_dns_hostnames = true

  # Enable DNS support in VPC (default: true)
  enable_dns_support = true

  # Enable VPN Gateway (default: false)
  enable_vpn_gateway = false

  # ===================================
  # NAT Gateway Configuration (Optional)
  # ===================================

  # Enable NAT Gateway for private subnet internet access (default: true)
  enable_nat_gateway = true

  # Use single NAT Gateway instead of one per AZ (default: false)
  # Set to true for cost savings in dev/test (~$32/mo vs ~$96/mo for 3 AZs)
  # Set to false for production HA
  single_nat_gateway = false

  # ===================================
  # VPC Endpoints Configuration (Optional)
  # ===================================

  # Enable VPC endpoints for AWS services (default: true)
  # Reduces NAT Gateway costs and improves security
  enable_vpc_endpoints = true

  # Individual VPC endpoint controls
  vpc_endpoints = {
    ssm         = true  # Systems Manager
    ssmmessages = true  # SSM Session Manager
    ec2messages = true  # SSM agent communication
    kms         = true  # Key Management Service
    ecr_api     = true  # ECR API (for pulling container images)
    ecr_dkr     = true  # ECR Docker registry
    ec2         = true  # EC2 API
    sts         = true  # Security Token Service
    logs        = true  # CloudWatch Logs
    s3          = true  # S3 Gateway endpoint
    dynamodb    = false # DynamoDB Gateway endpoint
  }

  # ===================================
  # Network Load Balancer (Optional)
  # ===================================

  # Create Network Load Balancer in public subnets (default: false)
  enable_network_load_balancer = true

  # Subnet IDs for NLB (default: uses public_subnets)
  # nlb_subnet_ids = ["subnet-xxx", "subnet-yyy"]

  # Enable deletion protection for NLB (default: false)
  nlb_deletion_protection = true

  # ===================================
  # Service Mesh Support (Optional)
  # ===================================

  # Configure security groups for Istio service mesh (default: false)
  # Adds ingress rules for Istio ports (15010-15012, 8080, 8443)
  enable_istio_support = true

  # ===================================
  # VPC Flow Logs (Optional)
  # ===================================

  # Enable VPC Flow Logs to CloudWatch (default: false)
  enable_flow_logs = true

  # CloudWatch log retention in days (default: 7)
  # Valid values: 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, etc.
  flow_logs_retention_days = 30

  # ===================================
  # Resource Tagging (Optional)
  # ===================================

  # Additional tags for all resources (default: {})
  tags = {
    Project     = "MyProject"
    ManagedBy   = "Terraform"
    CostCenter  = "Engineering"
    Owner       = "platform-team"
  }
}

# ===================================
# Integration with EKS Module
# ===================================

module "eks" {
  source = "github.com/orbitcluster/oc-terraform-module-eks"

  cluster_name        = "production-cluster"
  env                 = "prod"
  vpc_id              = module.networking.vpc_id
  routable_subnet_ids = module.networking.private_subnet_ids

  # Optional: Attach EKS nodes to NLB target group
  target_group_arns = module.networking.nlb_target_group_arn != null ? [
    module.networking.nlb_target_group_arn
  ] : []

  extra_nodegroups = {
    "default" = "t3.medium"
  }
}

# ===================================
# Useful Outputs
# ===================================

output "vpc_id" {
  description = "VPC ID"
  value       = module.networking.vpc_id
}

output "private_subnet_ids" {
  description = "Private subnet IDs for EKS nodes"
  value       = module.networking.private_subnet_ids
}

output "nlb_dns_name" {
  description = "Network Load Balancer DNS name"
  value       = module.networking.nlb_dns_name
}

output "vpc_endpoints" {
  description = "Map of VPC endpoint IDs"
  value       = module.networking.vpc_endpoints
}

output "nat_gateway_ips" {
  description = "NAT Gateway public IPs for allowlist"
  value       = module.networking.nat_gateway_public_ips
}
```

## Integration with EKS Module

This module is designed to work seamlessly with the `oc-terraform-module-eks` module:

```hcl
# Step 1: Create networking infrastructure
module "networking" {
  source = "github.com/orbitcluster/oc-terraform-module-networking"

  bu_id        = "finance"
  app_id       = "payments"
  cluster_name = "my-cluster"
  env          = "prod"
}

# Step 2: Create EKS cluster using networking outputs
module "eks" {
  source = "github.com/orbitcluster/oc-terraform-module-eks"

  cluster_name        = "my-cluster"
  env                 = "prod"
  vpc_id              = module.networking.vpc_id
  routable_subnet_ids = module.networking.private_subnet_ids

  # Optional: Use NLB target group
  target_group_arns = module.networking.nlb_target_group_arn != null ? [
    module.networking.nlb_target_group_arn
  ] : []

  extra_nodegroups = {
    "default" = "t3.medium"
  }
}
```

## Cost Considerations

### High Availability (Recommended for Production)

```hcl
single_nat_gateway = false  # NAT gateway in each AZ (~$32/month per NAT)
enable_vpc_endpoints = true # Reduces NAT data transfer costs
```

### Cost-Optimized (Dev/Testing)

```hcl
single_nat_gateway = true   # Single NAT gateway (~$32/month total)
enable_vpc_endpoints = false # No endpoint costs, higher NAT costs
```

**Note:** VPC endpoints have hourly charges (~$7/month per endpoint) but can significantly reduce NAT gateway data transfer costs in production environments.

## Development

### Pre-commit Hooks

This repository uses [pre-commit](https://pre-commit.com/) to ensure code quality and security.

1. **Install pre-commit**:
   ```bash
   pip install pre-commit
   ```
2. **Install hooks**:
   ```bash
   pre-commit install
   ```
3. **Run checks**:
   ```bash
   pre-commit run --all-files
   ```

## CI/CD

This repository uses GitHub Actions for automated testing and release management.

### Workflows

- **CI**: Triggered on push to any branch and pull requests.
  - Runs `terraform fmt -check`
  - Runs `terraform validate`
  - Runs security scanning with Checkov
  - Validates terraform-docs

- **Release**: Triggered on push to `main`.
  - Uses [Semantic Release](https://github.com/semantic-release/semantic-release) to analyze commit messages
  - Automatically creates a new version tag and GitHub release

## Subnet CIDR Calculation

If you don't specify subnet CIDRs, they will be auto-calculated from the VPC CIDR:

**For VPC CIDR `10.0.0.0/16`:**
- Private Subnets (each /19, 8,192 IPs):
  - AZ 1: `10.0.0.0/19`
  - AZ 2: `10.0.32.0/19`
  - AZ 3: `10.0.64.0/19`
- Public Subnets (each /24, 256 IPs):
  - AZ 1: `10.0.96.0/24`
  - AZ 2: `10.0.97.0/24`
  - AZ 3: `10.0.98.0/24`

## Security Best Practices

1. **Use VPC Endpoints** - Reduce exposure to internet and lower NAT costs
2. **Enable Flow Logs** - Monitor network traffic for security analysis
3. **Private Subnets** - Run EKS nodes in private subnets only
4. **Security Groups** - Use provided security groups instead of wide-open rules
5. **Multi-AZ** - Deploy across multiple AZs for high availability

<!-- BEGIN_TF_DOCS -->
<!-- END_TF_DOCS -->

## License

This module is part of OrbitCluster and follows the project's licensing terms.
