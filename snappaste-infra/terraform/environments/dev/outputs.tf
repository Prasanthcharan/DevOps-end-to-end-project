# ──────────────────────────────────────────────
# VPC Outputs
# ──────────────────────────────────────────────
output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = module.vpc.private_subnet_ids
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = module.vpc.public_subnet_ids
}

# ──────────────────────────────────────────────
# EKS Outputs
# ──────────────────────────────────────────────
output "eks_cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = module.eks.cluster_endpoint
}

output "eks_cluster_version" {
  description = "EKS cluster Kubernetes version"
  value       = module.eks.cluster_version
}

output "eks_lb_controller_role_arn" {
  description = "IAM role ARN for AWS LB Controller"
  value       = module.eks.lb_controller_role_arn
}

# ──────────────────────────────────────────────
# ECR Outputs
# ──────────────────────────────────────────────
output "ecr_repository_urls" {
  description = "ECR repository URLs"
  value       = module.ecr.repository_urls
}

# ──────────────────────────────────────────────
# Jumpbox Outputs
# ──────────────────────────────────────────────
output "jumpbox_instance_id" {
  description = "Jumpbox instance ID — use with: aws ssm start-session --target <id>"
  value       = module.jumpbox.jumpbox_instance_id
}

# ──────────────────────────────────────────────
# GitHub Runner Outputs
# ──────────────────────────────────────────────
/*
output "runner_instance_id" {
  description = "GitHub Actions runner EC2 instance ID"
  value       = module.runner.runner_instance_id
}

output "ssm_to_runner" {
  description = "Command to SSM into the runner"
  value       = "aws ssm start-session --target ${module.runner.runner_instance_id}"
}

output "ssm_to_jumpbox" {
  description = "Command to SSM into the jumpbox"
  value       = "aws ssm start-session --target ${module.jumpbox.jumpbox_instance_id}"
}
*/
# ──────────────────────────────────────────────
# Monitoring Outputs
# ──────────────────────────────────────────────
output "mimir_bucket_name" {
  description = "S3 bucket for Mimir metrics — use in Helm values"
  value       = module.monitoring.mimir_bucket_name
}

output "loki_bucket_name" {
  description = "S3 bucket for Loki logs — use in Helm values"
  value       = module.monitoring.loki_bucket_name
}

output "mimir_role_arn" {
  description = "IAM role ARN for Mimir Pod Identity — use in Helm values"
  value       = module.monitoring.mimir_role_arn
}

output "loki_role_arn" {
  description = "IAM role ARN for Loki Pod Identity — use in Helm values"
  value       = module.monitoring.loki_role_arn
}

# ──────────────────────────────────────────────
# Kubeconfig command
# ──────────────────────────────────────────────
output "configure_kubectl" {
  description = "Command to configure kubectl"
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${module.eks.cluster_name}"
}
