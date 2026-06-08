# 174 - bootstrap-advisories - plan

_Drafted from `spec.md` on 2026-06-08. Update this file if implementation reveals the plan is wrong; do NOT silently diverge._

## Approach

Implement a narrow, hardcoded project-core advisory instead of a generic bootstrap framework. The predicate is simple and low-risk: `.agent0/project-core.md.example` exists and `.agent0/project-core.md` does not. That means Agent0 has shipped an opinionated bootstrap template but the consumer has not accepted/configured it yet.

Surface the same predicate in the three places agents already inspect harness health: `sync-harness` after check/apply, the shared startup/status composition layer, and `doctor`. All outputs are advisory-only and must become silent once the real source exists. No implementation path writes `.agent0/project-core.md`; human/project configuration remains explicit.

## Files to touch

**Create:**
- `.agent0/tests/bootstrap-advisory/run-all.sh` - focused fixture tests for pending/silent states across sync, startup/status, and doctor.

**Modify:**
- `.agent0/tools/sync-harness.sh` - emit `bootstrap-advisory:` when project-core bootstrap is pending.
- `.agent0/hooks/_brief-compose.sh` - add a shared `bootstrap_advisory` block for startup/status.
- `.agent0/hooks/startup-brief.sh` - include the bootstrap block in the bounded brief.
- `.agent0/tools/status.sh` - include the bootstrap block in the on-demand status.
- `.agent0/tools/doctor.sh` - add project-core bootstrap health check.
- `.agent0/context/rules/harness-sync.md` - document the advisory and cleanup behavior.
- `.agent0/context/rules/agent0-status.md` - document doctor/status bootstrap advisory behavior.
- `.agent0/HANDOFF.md` - record spec state and validation.

**Delete:**
- None.

## Alternatives considered

### Auto-create `.agent0/project-core.md` from the example

Rejected because that would convert an Agent0 opinion into a consumer configuration without human/project intent. The correct behavior is warning, not mutation.

### Build a generic `.agent0/bootstrap-required.json` registry now

Rejected for V1. Project-core is the first concrete case. A registry becomes justified when at least two more surfaces need the same bootstrap lifecycle.

### Warn forever after the user declines project-core

Rejected because persistent false-positive context trains agents to ignore warnings. If a consumer wants silence, it should create an explicit `.agent0/project-core.md` with the chosen guidance, even if that guidance says no extra project-specific conventions are needed.

## Risks and unknowns

- Startup brief has tight byte/line limits, so the bootstrap block must stay short.
- `doctor.sh` should not exit non-zero solely because project-core bootstrap is pending.
- `sync-harness --check` output is used for drift detection, so the advisory should not alter exit semantics.

## Research / citations

- `.agent0/context/rules/harness-sync.md` - source/example split and no-op mirror when source is absent.
- `.agent0/hooks/_brief-compose.sh` - existing advisory shape for githooks.
- `.agent0/tools/doctor.sh` - existing tri-state health check pattern.
- `.agent0/tests/githooks-activation/` - precedent for startup advisory fixtures that silence after activation.
