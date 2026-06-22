# AWS Cloud Security Posture Review Report

## Executive summary

This assessment reviews a small AWS Terraform lab for common cloud security posture issues: public exposure, excessive identity permissions, weak authentication guardrails, storage configuration, and database network placement.

The vulnerable baseline includes intentionally insecure resources for assessment practice. The remediated configuration shows the target state for the same control areas.

## Scope

In scope:

- Amazon S3 bucket access posture
- IAM user and policy permissions
- Security group ingress rules
- RDS public accessibility and encryption
- MFA guardrail policy design

Out of scope:

- Production incident response
- Real customer data
- Live penetration testing
- Organization-wide AWS Organizations service control policies

## Findings summary

| ID | Finding | Severity | Vulnerable evidence | Remediation |
|---|---|---:|---|---|
| CSPR-001 | S3 bucket allows public object reads | High | Bucket policy grants `s3:GetObject` to `Principal: *` | Block public access, remove public policy, enable encryption/versioning |
| CSPR-002 | IAM policy grants wildcard admin permissions | Critical | Policy allows `Action: *` on `Resource: *` | Replace with least-privilege read-only policy |
| CSPR-003 | Security group exposes admin/database ports to the internet | Critical | Ingress allows `22`, `80`, `5432` from `0.0.0.0/0` | Restrict admin access to approved CIDR and DB access to security group references |
| CSPR-004 | Sensitive actions not protected by MFA guardrail | Medium | No deny condition requiring MFA for high-risk actions | Add MFA-based deny condition for sensitive actions |
| CSPR-005 | RDS database is public and unencrypted | Critical | `publicly_accessible = true`, `storage_encrypted = false` | Private subnets, no public endpoint, encrypted storage |

## Detailed findings

### CSPR-001: Public S3 bucket

**Risk:** Public S3 object access can expose sensitive files, logs, reports, credentials, or customer data.

**Evidence:**

```hcl
Principal = "*"
Action    = "s3:GetObject"
Resource  = "${aws_s3_bucket.public_data.arn}/*"
```

**Remediation applied:**

- Enabled all S3 Block Public Access settings.
- Removed public bucket policy.
- Enabled server-side encryption.
- Enabled bucket versioning.

### CSPR-002: Overly permissive IAM policy

**Risk:** Wildcard administrative permissions violate least privilege and increase blast radius if credentials are compromised.

**Evidence:**

```json
{
  "Effect": "Allow",
  "Action": "*",
  "Resource": "*"
}
```

**Remediation applied:**

- Replaced wildcard policy with scoped read-only review actions.
- Added an explicit deny for selected sensitive actions when MFA is not present.

### CSPR-003: Internet-exposed security group

**Risk:** Exposing SSH and database ports to the internet increases likelihood of brute-force attempts, vulnerability scanning, and unauthorized access.

**Evidence:**

```hcl
cidr_blocks = ["0.0.0.0/0"]
from_port   = 5432
to_port     = 5432
```

**Remediation applied:**

- Restricted SSH to a single approved administrator CIDR.
- Restricted PostgreSQL to traffic from a trusted security group only.

### CSPR-004: No MFA guardrail

**Risk:** Without MFA enforcement, compromised passwords or access keys can be used to perform sensitive actions.

**Remediation applied:**

- Added a deny statement for sensitive IAM, EC2, RDS, and S3 changes unless MFA is present.

### CSPR-005: Public unencrypted RDS database

**Risk:** Public database exposure can permit direct internet attack paths. Lack of encryption increases impact if storage snapshots or underlying data are exposed.

**Remediation applied:**

- Moved RDS to private subnets.
- Set `publicly_accessible = false`.
- Enabled `storage_encrypted = true`.
- Limited ingress to a security group reference.

## Control mapping

| Control theme | Example mapping |
|---|---|
| Least privilege | CIS AWS Foundations IAM recommendations, AWS IAM best practices |
| Public access prevention | AWS S3 Block Public Access, data exposure prevention |
| Network segmentation | Security group least privilege, private subnet database placement |
| Strong authentication | MFA for privileged or sensitive operations |
| Data protection | Encryption at rest for S3 and RDS |

## Before/after risk summary

| Category | Before | After |
|---|---|---|
| Storage exposure | Public object access possible | Public access blocked |
| IAM blast radius | Account-wide wildcard permissions | Read-only scoped permissions |
| Network exposure | Admin and database ports open to world | Admin CIDR and SG-scoped DB access |
| Database posture | Public and unencrypted | Private and encrypted |
| MFA posture | No sensitive-action guardrail | Explicit deny without MFA |

## Conclusion

The remediated configuration reduces the lab environment's attack surface by removing public storage access, replacing wildcard IAM permissions, restricting network ingress, adding MFA-aware guardrails, and enabling database encryption at rest.
