# Step 12 — Schema (required sections)

## Required sections

- escape-clause
- terms-posture
- privacy-posture
- data-handling
- licensing

## Recommended additional sections

- regulated-aspects — specific regulatory frames that apply (HIPAA / GDPR / COPPA / SOC2 / PCI / LGPD / etc) with v1 posture toward each
- ai-specific — for AI-using products: training data provenance, output liability, user disclosure, opt-out
- sub-processors — third-party services that touch user data (recap of system-design integrations with data-processing context)

## Section content guidance

- **escape-clause** — visible at top: "This is articulated posture, NOT legal advice. Counsel review required before launch." Non-negotiable.
- **terms-posture** — acceptance model + key clauses (acceptable use, payment, dispute resolution, governing law). Not the actual ToS.
- **privacy-posture** — PII collected, storage location (cite system-design), third-party shares, retention, deletion mechanism, applicable regulations (GDPR / CCPA / LGPD based on audience).
- **data-handling** — encryption at rest/in transit, backup retention, breach notification commitment.
- **licensing** — for shipped product: chosen license + rationale. For OSS components used: known compatibility issues.
