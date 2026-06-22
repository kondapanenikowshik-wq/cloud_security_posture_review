# Sample After Findings

These are representative validation results expected from the remediated configuration.

| Tool | Check | Expected result | Evidence |
|---|---|---|---|
| Prowler | S3 public access | Pass | Block Public Access enabled |
| Prowler | Internet-exposed SSH | Pass or accepted exception | SSH limited to approved `/32` admin CIDR |
| Prowler | RDS public access | Pass | `publicly_accessible = false` |
| CloudSplaining | Administrative wildcard policy | Pass | No `Action: *` admin policy |
| Manual review | MFA guardrail | Pass | Sensitive actions denied without MFA |

## Example evidence snippets

```text
PASS: S3 bucket blocks public ACLs and policies.
PASS: No PostgreSQL ingress from 0.0.0.0/0.
PASS: RDS DB instance PubliclyAccessible is false.
PASS: RDS storage encryption is enabled.
PASS: IAM policy scopes review permissions and denies sensitive actions without MFA.
```
