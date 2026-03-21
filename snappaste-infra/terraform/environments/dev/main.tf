terraform {
  required_version = ">= 1.11.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.28"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = local.common_tags
  }
}

locals {
  project_name = var.project_name
  environment  = "dev"

  common_tags = {
    Project     = local.project_name
    Environment = local.environment
    ManagedBy   = "terraform"
  }
}

# ──────────────────────────────────────────────
# VPC
# ──────────────────────────────────────────────
module "vpc" {
  source = "../../modules/vpc"

  project_name         = local.project_name
  environment          = local.environment
  vpc_cidr             = var.vpc_cidr
  availability_zones   = var.availability_zones
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  common_tags          = local.common_tags
}

# ──────────────────────────────────────────────
# EKS
# ──────────────────────────────────────────────
module "eks" {
  source = "../../modules/eks"

  project_name        = local.project_name
  environment         = local.environment
  vpc_id              = module.vpc.vpc_id
  private_subnet_ids  = module.vpc.private_subnet_ids
  kubernetes_version  = var.kubernetes_version
  node_instance_types = var.node_instance_types
  node_min_size       = var.node_min_size
  node_max_size       = var.node_max_size
  node_desired_size   = var.node_desired_size
  common_tags         = local.common_tags 
  jumpbox_security_group_id = module.jumpbox.jumpbox_security_group_id
  runner_security_group_id  = module.runner.runner_security_group_id
  jumpbox_role_arn          = module.jumpbox.jumpbox_role_arn
  runner_role_arn           = module.runner.runner_iam_role_arn
}

# ──────────────────────────────────────────────
# ECR (shared across environments, deploy once)
# ──────────────────────────────────────────────
module "ecr" {
  source = "../../modules/ecr"

  project_name     = local.project_name
  environment      = local.environment
  repository_names = var.ecr_repository_names
  max_image_count  = var.ecr_max_image_count
  common_tags      = local.common_tags
}

# ──────────────────────────────────────────────
# Jumpbox (private subnet — SSM access only)
# ──────────────────────────────────────────────
module "jumpbox" {
  source = "../../modules/jumpbox"

  project_name      = local.project_name
  environment       = local.environment
  vpc_id            = module.vpc.vpc_id
  private_subnet_id = module.vpc.private_subnet_ids[0]
  instance_type     = var.jumpbox_instance_type
  common_tags       = local.common_tags
  aws_region        = var.aws_region
}

# ──────────────────────────────────────────────
# GitHub Actions Self-Hosted Runner (private subnet)
# ──────────────────────────────────────────────
module "runner" {
  source = "../../modules/github-runner"

  project_name         = local.project_name
  environment          = local.environment
  vpc_id               = module.vpc.vpc_id
  subnet_id            = module.vpc.private_subnet_ids[0]
  aws_region           = var.aws_region
  instance_type        = var.runner_instance_type
  root_volume_size     = var.runner_volume_size
  github_runner_url    = var.github_runner_url
  github_runner_token  = var.github_runner_token
  ecr_repository_names = var.ecr_repository_names
  eks_cluster_arn      = module.eks.cluster_arn
  common_tags          = local.common_tags
}

# ──────────────────────────────────────────────
# RDS (optional — uncomment to use RDS instead of K8s PostgreSQL)
# ──────────────────────────────────────────────
# module "rds" {
#   source = "../../modules/rds"
#
#   project_name          = local.project_name
#   environment           = local.environment
#   vpc_id                = module.vpc.vpc_id
#   private_subnet_ids    = module.vpc.private_subnet_ids
#   eks_security_group_id = module.eks.cluster_security_group_id
#   instance_class        = "db.t3.micro"
#   allocated_storage     = 20
#   common_tags           = local.common_tags
# }
