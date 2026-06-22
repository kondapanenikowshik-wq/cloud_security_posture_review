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
  name_prefix = "cloud-posture-vulnerable"
  common_tags = {
    Project     = "Cloud Security Posture Review"
    Environment = "Vulnerable Lab"
    ManagedBy   = "Terraform"
    Warning     = "Intentional misconfiguration for isolated lab use only"
  }
}

# -----------------------------------------------------------------------------
# VULNERABILITY: Public S3 bucket
# -----------------------------------------------------------------------------
resource "aws_s3_bucket" "public_data" {
  bucket        = "${local.name_prefix}-${data.aws_caller_identity.current.account_id}"
  force_destroy = true

  tags = merge(local.common_tags, {
    Finding = "S3 bucket is publicly readable"
  })
}

resource "aws_s3_bucket_public_access_block" "public_data" {
  bucket = aws_s3_bucket.public_data.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "public_read" {
  bucket = aws_s3_bucket.public_data.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadForLab"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.public_data.arn}/*"
      }
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block.public_data]
}

# -----------------------------------------------------------------------------
# VULNERABILITY: Overly permissive IAM policy
# -----------------------------------------------------------------------------
resource "aws_iam_user" "overprivileged_user" {
  name = "${local.name_prefix}-admin-like-user"
  tags = local.common_tags
}

resource "aws_iam_policy" "overly_permissive" {
  name        = "${local.name_prefix}-wildcard-policy"
  description = "Intentionally excessive permissions for posture review lab"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "WildcardPermissions"
        Effect   = "Allow"
        Action   = "*"
        Resource = "*"
      }
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_user_policy_attachment" "overprivileged_user" {
  user       = aws_iam_user.overprivileged_user.name
  policy_arn = aws_iam_policy.overly_permissive.arn
}

# -----------------------------------------------------------------------------
# VULNERABILITY: Security group open to the internet
# -----------------------------------------------------------------------------
resource "aws_vpc" "lab" {
  cidr_block           = "10.10.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(local.common_tags, { Name = "${local.name_prefix}-vpc" })
}

resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.lab.id
  cidr_block              = "10.10.1.0/24"
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true

  tags = merge(local.common_tags, { Name = "${local.name_prefix}-public-a" })
}

resource "aws_subnet" "public_b" {
  vpc_id                  = aws_vpc.lab.id
  cidr_block              = "10.10.2.0/24"
  availability_zone       = "${var.aws_region}b"
  map_public_ip_on_launch = true

  tags = merge(local.common_tags, { Name = "${local.name_prefix}-public-b" })
}

resource "aws_security_group" "open_admin" {
  name        = "${local.name_prefix}-open-admin"
  description = "Intentionally exposes admin and database ports to the internet"
  vpc_id      = aws_vpc.lab.id

  ingress {
    description = "SSH open to world"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP open to world"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "PostgreSQL open to world"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
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
# VULNERABILITY: Public database
# -----------------------------------------------------------------------------
resource "aws_db_subnet_group" "public" {
  name       = "${local.name_prefix}-public-db-subnets"
  subnet_ids = [aws_subnet.public_a.id, aws_subnet.public_b.id]

  tags = local.common_tags
}

resource "aws_db_instance" "public_postgres" {
  identifier             = "${local.name_prefix}-postgres"
  engine                 = "postgres"
  engine_version         = "15"
  instance_class         = "db.t3.micro"
  allocated_storage      = 20
  db_name                = "labdb"
  username               = "labadmin"
  password               = var.database_password
  db_subnet_group_name   = aws_db_subnet_group.public.name
  vpc_security_group_ids = [aws_security_group.open_admin.id]
  publicly_accessible    = true
  storage_encrypted      = false
  skip_final_snapshot    = true

  tags = merge(local.common_tags, {
    Finding = "Publicly accessible unencrypted RDS instance"
  })
}
