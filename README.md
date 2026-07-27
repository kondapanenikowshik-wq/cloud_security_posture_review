# AWS Cloud Security Posture Review

Small AWS security assessment lab built with Terraform. The project documents common cloud misconfigurations, maps them to risk, and provides remediated infrastructure-as-code for comparison.

## Scope

The review focuses on five AWS control areas:

- S3 public access
- IAM privilege scope
- Security group exposure
- MFA-based guardrails
- RDS public accessibility and encryption

## Repository layout

```text
configs/
├── vulnerable/      # Terraform with intentional misconfigurations
└── remediated/      # Terraform with corrected security controls
diagrams/            # Mermaid architecture and workflow diagrams
docs/                # Assessment report, remediation plan, tooling notes
scan-results/        # Sample before/after findings
```

## Assessment scenarios

| Control area | Vulnerable configuration | Remediated configuration |
|---|---|---|
| Object storage | S3 bucket policy grants public read access | S3 Block Public Access, encryption, versioning |
| Identity and access | IAM policy allows `Action: *` on `Resource: *` | Scoped read-only review permissions |
| Network access | SSH, HTTP, and PostgreSQL open to `0.0.0.0/0` | Admin CIDR restriction and security-group-scoped DB access |
| Authentication guardrails | No MFA condition for sensitive operations | Explicit deny for selected sensitive actions without MFA |
| Database | Public, unencrypted RDS PostgreSQL instance | Private, encrypted RDS PostgreSQL instance |

## Safety note

`configs/vulnerable` is intentionally insecure. Use it only in an isolated AWS sandbox account with no production data, no shared networking, and a defined cleanup process.

## Usage

Terraform is not required to review the project. If deploying in a lab account, create local variable files first:

```bash
cp configs/vulnerable/terraform.tfvars.example configs/vulnerable/terraform.tfvars
cp configs/remediated/terraform.tfvars.example configs/remediated/terraform.tfvars
```

Update the database password and administrator CIDR values before running Terraform.

Review the vulnerable configuration:

```bash
cd configs/vulnerable
terraform init
terraform validate
terraform plan
```

Review the remediated configuration:

```bash
cd configs/remediated
terraform init
terraform validate
terraform plan
```

## Documentation

- [Security posture review report](docs/security-posture-review-report.md)
- [Remediation plan](docs/remediation-plan.md)
- [Assessment methodology](docs/assessment-methodology.md)
- [Tooling guide](docs/tooling-guide.md)
- [Architecture diagram](diagrams/aws-lab-architecture.md)
- [Review workflow](diagrams/review-workflow.md)

## Tools referenced

- Prowler
- ScoutSuite
- Steampipe AWS Compliance
- CloudSplaining
- AWS Config
- AWS Security Hub

## Security scan results

The Terraform configurations were validated and scanned locally using Checkov.

| Configuration | Passed | Failed | Skipped |
|---|---:|---:|---:|
| Vulnerable | 16 | 42 | 0 |
| Remediated | 47 | 22 | 0 |

The remediated configuration produced:

- 31 additional passing checks
- 20 fewer failed checks
- Approximately 47.6% fewer failed findings

Detailed evidence is available in:

- `scan-results/SCAN-SUMMARY.md`
- `scan-results/vulnerable-checkov-report.txt`
- `scan-results/remediated-checkov-report.txt`

Remaining findings represent additional production-hardening controls such as centralized logging, cross-region replication, IAM Identity Center, stricter outbound network controls, and enhanced database monitoring.

## Validation commands

```bash
terraform -chdir=configs/vulnerable validate
terraform -chdir=configs/remediated validate

checkov -d configs/vulnerable --framework terraform
checkov -d configs/remediated --framework terraform
```

## Safety and limitations

- The intentionally vulnerable infrastructure was not deployed.
- Terraform state, plan files, local variable files, and credentials are excluded from version control.
- The Terraform does not create access keys or store AWS credentials.
- This repository demonstrates static Infrastructure-as-Code security assessment and remediation.
