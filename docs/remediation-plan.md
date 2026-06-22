# Remediation Plan

This plan prioritizes the corrective actions used in the remediated Terraform configuration.

## Priority order

1. **Critical: Remove public database exposure**
   - Set RDS `publicly_accessible = false`.
   - Place RDS in private subnets.
   - Restrict PostgreSQL ingress to trusted security groups.

2. **Critical: Remove wildcard IAM permissions**
   - Replace `Action: *` and `Resource: *` with specific read-only permissions.
   - Use role-based access instead of long-lived IAM users where possible.

3. **High: Block public S3 access**
   - Enable S3 Block Public Access.
   - Remove public bucket policies and ACLs.
   - Enable encryption and versioning.

4. **High: Close internet-exposed admin ports**
   - Remove `0.0.0.0/0` access for SSH and database ports.
   - Use VPN, AWS Systems Manager Session Manager, or approved administrator CIDRs.

5. **Medium: Add MFA guardrails**
   - Add explicit deny statements for sensitive operations when MFA is absent.
   - Prefer AWS IAM Identity Center and conditional access policies for workforce identities.

## Validation checklist

- [ ] Prowler no longer reports public S3 bucket access.
- [ ] CloudSplaining no longer flags wildcard administrative permissions.
- [ ] Security group review shows no SSH or PostgreSQL ingress from `0.0.0.0/0`.
- [ ] RDS reports `PubliclyAccessible: false`.
- [ ] RDS storage encryption is enabled.
- [ ] Sensitive actions are denied without MFA context.

## Evidence to retain

- Terraform plan output before and after remediation.
- Prowler or ScoutSuite findings before and after remediation.
- AWS console screenshots for S3 Block Public Access, RDS public accessibility, and security group ingress.
- IAM policy JSON before and after remediation.
