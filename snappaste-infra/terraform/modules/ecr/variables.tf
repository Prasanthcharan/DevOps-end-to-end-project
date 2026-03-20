variable "project_name" {
  description = "Name of the project (used as prefix for repo names)"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "repository_names" {
  description = "List of ECR repository names to create"
  type        = list(string)
}

variable "max_image_count" {
  description = "Maximum number of tagged images to retain per repository"
  type        = number
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
}
