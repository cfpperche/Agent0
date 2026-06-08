# 176 - project-core-template-review - plan

_Drafted from `spec.md` on 2026-06-08. Update this file if implementation reveals the plan is wrong; do NOT silently diverge._

## Approach

Add a single HTML comment marker to both the template and reviewed consumer sources:

```markdown
<!-- AGENT0:PROJECT-CORE-TEMPLATE: 2026-06-08-1 -->
```

The marker is not a schema for project-core content; it is an acknowledgement token. If the example has a marker and the source does not match it, the consumer has not reviewed the current template. Advisory surfaces report that state. Silence is achieved by reviewing/updating `.agent0/project-core.md` and setting the marker to the current example id.

Implement the predicate in the shared startup/status composer, doctor, and sync-harness. Do not mutate `.agent0/project-core.md`; sync still only copies the example and renders entrypoint mirrors from the source.

## Files to touch

**Create:**
- `.agent0/tests/project-core-template-review/run-all.sh` - fixture coverage for sync/startup/status/doctor warnings and silence.
- `docs/specs/176-project-core-template-review/` - SDD artifacts.

**Modify:**
- `.agent0/project-core.md`
- `.agent0/project-core.md.example`
- `CLAUDE.md`
- `AGENTS.md`
- `.agent0/hooks/_brief-compose.sh`
- `.agent0/tools/doctor.sh`
- `.agent0/tools/sync-harness.sh`
- `.agent0/context/rules/{harness-sync,language,agent0-status}.md`
- `.agent0/tests/bootstrap-advisory/run-all.sh`
- `.agent0/tests/harness-sync/47-project-core-example.sh`
- `.agent0/HANDOFF.md`

**Delete:**
- None.

## Alternatives considered

### Compare source and example content directly

Rejected. Real consumer sources are supposed to differ from the template, so content equality would be a permanent false positive.

### Store acknowledgement in harness-sync baseline

Rejected. The acknowledgement is project configuration state, not upstream file sync state. It must survive outside a specific sync run and be visible to agents reading the source.

### Auto-update the marker after sync

Rejected. That would hide the very action required: reviewing whether the new template introduces language or project-core guidance that should be incorporated into the real config.

## Risks and unknowns

- Existing configured consumers will initially warn because their source has no marker. That is intended: they have not reviewed the new template contract.
- The marker is manual and can be updated without actually reviewing the source. That is a process risk, not a tooling risk; the same is true of any manual configuration acknowledgement.

## Research / citations

- `.agent0/project-core.md.example` - shipped template.
- `/home/goat/cognixse/.agent0/project-core.md` - configured consumer without the example/marker.
- `.agent0/context/rules/harness-sync.md` - source remains consumer-owned and examples are sync-owned.
