variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
}

variable "project_name" {
  description = "Project name"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
}

# ──────────────────────────────────────────────
# EKS
# ──────────────────────────────────────────────
variable "kubernetes_version" {
  description = "Kubernetes version for EKS"
  type        = string
}

variable "node_instance_types" {
  description = "EC2 instance types for EKS node group"
  type        = list(string)
}

variable "node_min_size" {
  description = "Minimum nodes in node group"
  type        = number
}

variable "node_max_size" {
  description = "Maximum nodes in node group"
  type        = number
}

variable "node_desired_size" {
  description = "Desired nodes in node group"
  type        = number
}

# ──────────────────────────────────────────────
# ECR
# ──────────────────────────────────────────────
variable "ecr_repository_names" {
  description = "ECR repository names to create"
  type        = list(string)
}

variable "ecr_max_image_count" {
  description = "Max images to retain per ECR repo"
  type        = number
}

# ──────────────────────────────────────────────
# Jumpbox
# ──────────────────────────────────────────────
variable "jumpbox_instance_type" {
  description = "EC2 instance type for the jumpbox"
  type        = string
}

# ──────────────────────────────────────────────
# GitHub Actions Runner
# ──────────────────────────────────────────────
variable "runner_instance_type" {
  description = "EC2 instance type for the GitHub Actions runner"
  type        = string
}

variable "runner_volume_size" {
  description = "Root volume size in GB for the runner"
  type        = number
}

variable "github_runner_url" {
  description = "GitHub org or repo URL for runner registration"
  type        = string
}

variable "github_runner_token" {
  description = "GitHub runner registration token — stored in SSM at boot, never hardcoded"
  type        = string
  sensitive   = true
}
