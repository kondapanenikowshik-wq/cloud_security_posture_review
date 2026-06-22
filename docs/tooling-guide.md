# Tooling Guide

Example commands for reviewing the AWS lab posture. Run these only from an authorized sandbox account.

## AWS identity check

```bash
aws sts get-caller-identity
```

## Terraform review

```bash
cd configs/vulnerable
terraform init
terraform validate
terraform plan
```

```bash
cd configs/remediated
terraform init
terraform validate
terraform plan
```

## Prowler

Example checks:

```bash
prowler aws --checks s3_bucket_public_access iam_policy_no_administrative_privileges ec2_securitygroup_allow_ingress_from_internet_to_tcp_port_22 rds_instance_public_access
```

Suggested evidence files:

```text
scan-results/prowler-before-summary.md
scan-results/prowler-after-summary.md
```

## ScoutSuite

```bash
scout aws
```

Review the generated report for:

- S3 bucket public access
- IAM privilege risks
- Security group internet exposure
- RDS public exposure

## CloudSplaining

Use CloudSplaining to review IAM policy risk.

```bash
cloudsplaining download
cloudsplaining scan --input-file default.json --output scan-results/cloudsplaining-report
```

Look for:

- `PrivEscalation`
- `ResourceExposure`
- `DataExfiltration`
- `Wildcard actions`

## Steampipe

```bash
steampipe plugin install aws
steampipe mod install github.com/turbot/steampipe-mod-aws-compliance
steampipe check aws_compliance.benchmark.cis_v140
```

Example SQL-style checks:

```sql
select
  group_id,
  group_name,
  ip_protocol,
  from_port,
  to_port,
  cidr_ip
from
  aws_vpc_security_group_rule
where
  type = 'ingress'
  and cidr_ip = '0.0.0.0/0';
```

## AWS Config / Security Hub

Relevant managed rules and controls:

- `S3_BUCKET_PUBLIC_READ_PROHIBITED`
- `S3_BUCKET_PUBLIC_WRITE_PROHIBITED`
- `RDS_INSTANCE_PUBLIC_ACCESS_CHECK`
- `INCOMING_SSH_DISABLED`
- IAM policy checks for administrative access
