# Assessment Methodology

## Objective

Assess a small AWS environment for common configuration weaknesses and document remediation steps using infrastructure-as-code.

## Approach

1. Review Terraform resources for risky configuration patterns.
2. Map each issue to impact, evidence, and affected control area.
3. Prioritize findings by exposure and potential blast radius.
4. Implement corrected Terraform in a separate remediated configuration.
5. Record expected tool findings before and after remediation.

## Severity model

| Severity | Criteria |
|---|---|
| Critical | Public exposure or permissions that could lead to direct compromise or broad account impact |
| High | Misconfiguration likely to expose data or increase attack surface |
| Medium | Missing guardrail or hardening control that increases risk under certain conditions |
| Low | Documentation, monitoring, or defense-in-depth improvement |

## Evidence standards

Evidence should include the affected resource, configuration snippet, expected tool finding, and remediation reference. Actual scan output should be stored outside version control if it includes account IDs, ARNs, IP addresses, or other environment-specific data.
