# ──────────────────────────────────────────────
# General
# ──────────────────────────────────────────────
aws_region   = "us-east-1"
project_name = "snappaste"

# ──────────────────────────────────────────────
# VPC
# ──────────────────────────────────────────────
vpc_cidr             = "10.2.0.0/16"
availability_zones   = ["us-east-1a", "us-east-1b", "us-east-1c"]
public_subnet_cidrs  = ["10.2.1.0/24", "10.2.2.0/24", "10.2.3.0/24"]
private_subnet_cidrs = ["10.2.10.0/24", "10.2.20.0/24", "10.2.30.0/24"]

# ──────────────────────────────────────────────
# EKS
# ──────────────────────────────────────────────
kubernetes_version  = "1.34"
node_instance_types = ["t3.large"]
node_min_size       = 2
node_max_size       = 6
node_desired_size   = 3

# ──────────────────────────────────────────────
# ECR
# ──────────────────────────────────────────────
ecr_repository_names = ["frontend", "backend"]
ecr_max_image_count  = 20

# ──────────────────────────────────────────────
# Jumpbox
# ──────────────────────────────────────────────
jumpbox_instance_type = "t3.micro"

# ──────────────────────────────────────────────
# GitHub Actions Runner
# ──────────────────────────────────────────────
runner_instance_type = "t3.large"
runner_volume_size   = 50
github_runner_url    = "https://github.com/siva9800/DevOps-end-to-end"

# github_runner_token — DO NOT add here — generate fresh at runtime:
# export TF_VAR_github_runner_token="$(gh api --method POST /repos/siva9800/DevOps-end-to-end/actions/runners/registration-token --jq '.token')"
