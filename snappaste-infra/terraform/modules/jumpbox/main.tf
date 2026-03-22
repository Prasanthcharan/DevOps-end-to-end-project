# ──────────────────────────────────────────────
# Security Group — Jumpbox (SSM only, no SSH)
# ──────────────────────────────────────────────
resource "aws_security_group" "jumpbox" {
  name_prefix = "${var.project_name}-${var.environment}-jumpbox-"
  description = "Security group for jumpbox - SSM only, no SSH"
  vpc_id      = var.vpc_id

  # No ingress — SSM agent phones home outbound, nothing needed inbound

  egress {
    description = "Allow outbound HTTPS for SSM"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-jumpbox-sg"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# ──────────────────────────────────────────────
# IAM Role — SSM Session Manager access
# ──────────────────────────────────────────────
resource "aws_iam_role" "jumpbox" {
  name = "${var.project_name}-${var.environment}-jumpbox-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })

  tags = var.common_tags
}

resource "aws_iam_role_policy_attachment" "jumpbox_ssm" {
  role       = aws_iam_role.jumpbox.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

resource "aws_iam_role_policy" "jumpbox_eks" {
  name = "${var.project_name}-${var.environment}-jumpbox-eks"
  role = aws_iam_role.jumpbox.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = ["eks:DescribeCluster"]
        # Scoped to this environment's cluster — no circular dep, ARN is predictable
        Resource = "arn:aws:eks:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:cluster/${var.project_name}-${var.environment}-eks"
      },
      {
        Effect   = "Allow"
        Action   = ["eks:ListClusters"]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_instance_profile" "jumpbox" {
  name = "${var.project_name}-${var.environment}-jumpbox-profile"
  role = aws_iam_role.jumpbox.name
}

# ──────────────────────────────────────────────
# EC2 Instance — Jumpbox (private subnet, SSM only)
# ──────────────────────────────────────────────
resource "aws_instance" "jumpbox" {
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = var.instance_type
  subnet_id                   = var.private_subnet_id
  vpc_security_group_ids      = [aws_security_group.jumpbox.id]
  iam_instance_profile        = aws_iam_instance_profile.jumpbox.name

  # No key_name — SSM only, no SSH keys needed
  associate_public_ip_address = false

  user_data_base64 = base64encode(templatefile("${path.module}/user-data.sh", {
    aws_region   = var.aws_region
    project_name = var.project_name
    environment  = var.environment
  }))

  root_block_device {
    volume_size           = 10
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }

  metadata_options {
    http_tokens   = "required"  # IMDSv2 enforced
    http_endpoint = "enabled"
  }

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-jumpbox"
    Role = "jumpbox"
  })
}

# ──────────────────────────────────────────────
# AMI — Latest Amazon Linux 2023
# ──────────────────────────────────────────────
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}
