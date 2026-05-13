# Step 9 — Schema (required sections)

## Required sections

- stack
- services
- data-model
- apis
- integrations
- deployment
- non-functional

## Recommended additional sections

- alternatives-considered — per major choice, 1-2 rejected alternatives with reasoning
- diagrams — text/mermaid topology diagrams for the killer flow
- open-decisions — designs deferred to implementation time, with the deciding signal named

## Section content guidance

- **stack** — concrete choices: language (with version), framework, database, ORM if any, frontend framework. One sentence rationale each.
- **services** — service decomposition. Monolith / modular monolith / multi-service — state plainly. If multi-service, name each + responsibility + comms protocol.
- **data-model** — entities + relationships in typed pseudo-schema or text. Key indexes + multi-tenancy posture if relevant.
- **apis** — endpoint catalog (public + internal). One line per endpoint stating contract intent.
- **integrations** — third-party services per use case + vendor lock-in posture.
- **deployment** — host, CI/CD shape, secrets management, observability floor.
- **non-functional** — perf budgets, security floor, scale assumptions for v1.
