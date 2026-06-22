terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

data "aws_caller_identity" "current" {}

locals {
  name_prefix = "cloud-posture-remediated"
  common_tags = {
    Project     = "Cloud Security Posture Review"
    Environment = "Remediated Lab"
    ManagedBy   = "Terraform"
  }
}

# -----------------------------------------------------------------------------
# REMEDIATION: Private S3 bucket with public access blocked, encryption, versioning
# -----------------------------------------------------------------------------
resource "aws_s3_bucket" "private_data" {
  bucket        = "${local.name_prefix}-${data.aws_caller_identity.current.account_id}"
  force_destroy = true

  tags = merge(local.common_tags, {
    Control = "S3 public access blocked"
  })
}

resource "aws_s3_bucket_public_access_block" "private_data" {
  bucket = aws_s3_bucket.private_data.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "private_data" {
  bucket = aws_s3_bucket.private_data.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_versioning" "private_data" {
  bucket = aws_s3_bucket.private_data.id

  versioning_configuration {
    status = "Enabled"
  }
}

# -----------------------------------------------------------------------------
# REMEDIATION: Least-privilege IAM policy and MFA guardrail
# -----------------------------------------------------------------------------
resource "aws_iam_user" "readonly_user" {
  name = "${local.name_prefix}-readonly-user"
  tags = local.common_tags
}

resource "aws_iam_policy" "least_privilege_readonly" {
  name        = "${local.name_prefix}-least-privilege-readonly"
  description = "Read-only permissions scoped to inventory and review actions"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowReadOnlyReview"
        Effect = "Allow"
        Action = [
          "ec2:Describe*",
          "rds:Describe*",
          "s3:GetBucketLocation",
          "s3:GetBucketPolicyStatus",
          "s3:GetBucketPublicAccessBlock",
          "s3:ListAllMyBuckets",
          "iam:Get*",
          "iam:List*"
        ]
        Resource = "*"
      },
      {
        Sid    = "DenySensitiveActionsWithoutMFA"
        Effect = "Deny"
        Action = [
          "iam:CreateAccessKey",
          "iam:AttachUserPolicy",
          "iam:PutUserPolicy",
          "ec2:AuthorizeSecurityGroupIngress",
          "rds:ModifyDBInstance",
          "s3:PutBucketPolicy"
        ]
        Resource = "*"
        Condition = {
          BoolIfExists = {
            "aws:MultiFactorAuthPresent" = "false"
          }
        }
      }
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_user_policy_attachment" "readonly_user" {
  user       = aws_iam_user.readonly_user.name
  policy_arn = aws_iam_policy.least_privilege_readonly.arn
}

# -----------------------------------------------------------------------------
# REMEDIATION: Network segmentation and restricted ingress
# -----------------------------------------------------------------------------
resource "aws_vpc" "lab" {
  cidr_block           = "10.20.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(local.common_tags, { Name = "${local.name_prefix}-vpc" })
}

resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.lab.id
  cidr_block              = "10.20.1.0/24"
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = false

  tags = merge(local.common_tags, { Name = "${local.name_prefix}-public-a" })
}

resource "aws_subnet" "private_a" {
  vpc_id                  = aws_vpc.lab.id
  cidr_block              = "10.20.11.0/24"
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = false

  tags = merge(local.common_tags, { Name = "${local.name_prefix}-private-a" })
}

resource "aws_subnet" "private_b" {
  vpc_id                  = aws_vpc.lab.id
  cidr_block              = "10.20.12.0/24"
  availability_zone       = "${var.aws_region}b"
  map_public_ip_on_launch = false

  tags = merge(local.common_tags, { Name = "${local.name_prefix}-private-b" })
}

resource "aws_security_group" "admin_restricted" {
  name        = "${local.name_prefix}-admin-restricted"
  description = "Restricts administrative access to approved administrator CIDR"
  vpc_id      = aws_vpc.lab.id

  ingress {
    description = "SSH from approved admin CIDR only"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.admin_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.common_tags
}

resource "aws_security_group" "database_private" {
  name        = "${local.name_prefix}-database-private"
  description = "Allows database access only from approved application/admin security groups"
  vpc_id      = aws_vpc.lab.id

  ingress {
    description     = "PostgreSQL from restricted admin security group only"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.admin_restricted.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# REMEDIATION: Private encrypted database
# -----------------------------------------------------------------------------
resource "aws_db_subnet_group" "private" {
  name       = "${local.name_prefix}-private-db-subnets"
  subnet_ids = [aws_subnet.private_a.id, aws_subnet.private_b.id]

  tags = local.common_tags
}

resource "aws_db_instance" "private_postgres" {
  identifier             = "${local.name_prefix}-postgres"
  engine                 = "postgres"
  engine_version         = "15"
  instance_class         = "db.t3.micro"
  allocated_storage      = 20
  db_name                = "labdb"
  username               = "labadmin"
  password               = var.database_password
  db_subnet_group_name   = aws_db_subnet_group.private.name
  vpc_security_group_ids = [aws_security_group.database_private.id]
  publicly_accessible    = false
  storage_encrypted      = true
  skip_final_snapshot    = true

  tags = merge(local.common_tags, {
    Control = "Private encrypted RDS instance"
  })
}
