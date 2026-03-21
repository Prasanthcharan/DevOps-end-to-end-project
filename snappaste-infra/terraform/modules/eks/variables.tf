variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where EKS cluster will be created"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for EKS worker nodes"
  type        = list(string)
}

variable "kubernetes_version" {
  description = "Kubernetes version for the EKS cluster"
  type        = string
}

variable "node_instance_types" {
  description = "List of EC2 instance types for the node group"
  type        = list(string)
}

variable "node_min_size" {
  description = "Minimum number of nodes in the node group"
  type        = number
}

variable "node_max_size" {
  description = "Maximum number of nodes in the node group"
  type        = number
}

variable "node_desired_size" {
  description = "Desired number of nodes in the node group"
  type        = number
}

variable "jumpbox_security_group_id" {
  description = "Jumpbox security group ID — allows jumpbox to reach EKS API server"
  type        = string
}

variable "runner_security_group_id" {
  description = "GitHub Actions runner security group ID — allows runner to reach EKS API for kubectl deploys"
  type        = string
}

variable "jumpbox_role_arn" {
  description = "IAM role ARN of the jumpbox — granted EKS cluster-admin access"
  type        = string
}

variable "runner_role_arn" {
  description = "IAM role ARN of the GitHub Actions runner — granted EKS cluster-admin access"
  type        = string
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
}
