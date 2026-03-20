# ──────────────────────────────────────────────
# General
# ──────────────────────────────────────────────
aws_region   = "us-east-1"
project_name = "snappaste"

# ──────────────────────────────────────────────
# VPC
# ──────────────────────────────────────────────
vpc_cidr             = "10.0.0.0/16"
availability_zones   = ["us-east-1a", "us-east-1b"]
public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnet_cidrs = ["10.0.10.0/24", "10.0.20.0/24"]

# ──────────────────────────────────────────────
# EKS
# ──────────────────────────────────────────────
kubernetes_version  = "1.34"
node_instance_types = ["t3.medium"]
node_min_size       = 1
node_max_size       = 3
node_desired_size   = 2

# ──────────────────────────────────────────────
# ECR
# ──────────────────────────────────────────────
ecr_repository_names = ["frontend", "backend"]
ecr_max_image_count  = 10

# ──────────────────────────────────────────────
# Jumpbox
# ──────────────────────────────────────────────
jumpbox_instance_type = "t3.micro"

# ──────────────────────────────────────────────
# GitHub Actions Runner
# ──────────────────────────────────────────────
runner_instance_type = "t3.medium"
runner_volume_size   = 30
github_runner_url    = "https://github.com/siva9800/DevOps-end-to-end"

# export TF_VAR_github_runner_token="$(gh api --method POST /repos/siva9800/DevOps-end-to-end/actions/runners/registration-token --jq '.token')"
