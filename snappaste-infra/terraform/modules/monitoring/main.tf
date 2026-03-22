data "aws_caller_identity" "current" {}

# ──────────────────────────────────────────────
# S3 Buckets — Mimir (metrics) and Loki (logs)
# ──────────────────────────────────────────────

resource "aws_s3_bucket" "mimir" {
  bucket        = "${var.project_name}-mimir-${var.environment}-${data.aws_caller_identity.current.account_id}"
  force_destroy = var.environment != "prod"

  tags = merge(var.common_tags, {
    Name    = "${var.project_name}-mimir-${var.environment}"
    Purpose = "Mimir metrics storage"
  })
}

resource "aws_s3_bucket_public_access_block" "mimir" {
  bucket                  = aws_s3_bucket.mimir.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "mimir" {
  bucket = aws_s3_bucket.mimir.id

  rule {
    id     = "expire-old-blocks"
    status = "Enabled"

    filter {}

    expiration {
      days = var.metrics_retention_days
    }
  }
}

resource "aws_s3_bucket" "loki" {
  bucket        = "${var.project_name}-loki-${var.environment}-${data.aws_caller_identity.current.account_id}"
  force_destroy = var.environment != "prod"

  tags = merge(var.common_tags, {
    Name    = "${var.project_name}-loki-${var.environment}"
    Purpose = "Loki log storage"
  })
}

resource "aws_s3_bucket_public_access_block" "loki" {
  bucket                  = aws_s3_bucket.loki.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "loki" {
  bucket = aws_s3_bucket.loki.id

  rule {
    id     = "expire-old-chunks"
    status = "Enabled"

    filter {}

    expiration {
      days = var.logs_retention_days
    }
  }
}

# ──────────────────────────────────────────────
# IAM Policy — Mimir S3 access
# ──────────────────────────────────────────────
resource "aws_iam_policy" "mimir_s3" {
  name        = "${var.project_name}-${var.environment}-mimir-s3"
  description = "Allow Mimir pods to read/write metrics to S3"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetBucketLocation"
        ]
        Resource = aws_s3_bucket.mimir.arn
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = "${aws_s3_bucket.mimir.arn}/*"
      }
    ]
  })

  tags = var.common_tags
}

# ──────────────────────────────────────────────
# IAM Policy — Loki S3 access
# ──────────────────────────────────────────────
resource "aws_iam_policy" "loki_s3" {
  name        = "${var.project_name}-${var.environment}-loki-s3"
  description = "Allow Loki pods to read/write logs to S3"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetBucketLocation"
        ]
        Resource = aws_s3_bucket.loki.arn
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = "${aws_s3_bucket.loki.arn}/*"
      }
    ]
  })

  tags = var.common_tags
}

# ──────────────────────────────────────────────
# Pod Identity — Mimir
# Same pattern as ebs-csi and lb-controller in modules/eks/main.tf
# ──────────────────────────────────────────────
module "mimir_pod_identity" {
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "2.7.0"

  name = "${var.project_name}-${var.environment}-mimir"

  additional_iam_policies = {
    mimir_s3 = aws_iam_policy.mimir_s3.arn
  }

  associations = {
    this = {
      cluster_name    = var.eks_cluster_name
      namespace       = "monitoring"
      service_account = "mimir"
    }
  }

  tags = var.common_tags
}

# ──────────────────────────────────────────────
# Pod Identity — Loki
# ──────────────────────────────────────────────
module "loki_pod_identity" {
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "2.7.0"

  name = "${var.project_name}-${var.environment}-loki"

  additional_iam_policies = {
    loki_s3 = aws_iam_policy.loki_s3.arn
  }

  associations = {
    this = {
      cluster_name    = var.eks_cluster_name
      namespace       = "monitoring"
      service_account = "loki"
    }
  }

  tags = var.common_tags
}
