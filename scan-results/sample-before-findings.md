# Sample Before Findings

These are representative findings expected from the intentionally vulnerable configuration.

| Tool | Finding | Severity | Resource |
|---|---|---:|---|
| Prowler | S3 bucket allows public access | High | `cloud-posture-vulnerable-*` |
| Prowler | Security group allows SSH from internet | High | `cloud-posture-vulnerable-open-admin` |
| Prowler | RDS instance is publicly accessible | Critical | `cloud-posture-vulnerable-postgres` |
| CloudSplaining | IAM policy allows administrative wildcard access | Critical | `cloud-posture-vulnerable-wildcard-policy` |
| Manual review | No MFA condition for sensitive actions | Medium | IAM policy set |

## Example evidence snippets

```text
FAIL: S3 bucket policy grants public read access.
FAIL: Security group ingress allows 0.0.0.0/0 on TCP/22.
FAIL: Security group ingress allows 0.0.0.0/0 on TCP/5432.
FAIL: RDS DB instance PubliclyAccessible is true.
FAIL: IAM policy contains Action=* and Resource=*.
```
