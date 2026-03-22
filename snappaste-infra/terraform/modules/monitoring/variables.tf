variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
}

variable "eks_cluster_name" {
  description = "EKS cluster name — needed for Pod Identity association"
  type        = string
}

variable "metrics_retention_days" {
  description = "How many days to keep metrics in Mimir S3 bucket"
  type        = number
  default     = 90
}

variable "logs_retention_days" {
  description = "How many days to keep logs in Loki S3 bucket"
  type        = number
  default     = 30
}

variable "common_tags" {
  description = "Tags applied to all resources"
  type        = map(string)
  default     = {}
}
