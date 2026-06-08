# 173 - project-core-language-locale - plan

_Drafted from `spec.md` on 2026-06-08. Update this file if implementation reveals the plan is wrong; do NOT silently diverge._

## Approach

Reuse spec 131's project-core mirror instead of adding a second language-specific mechanism. Agent0 will author its own `.agent0/project-core.md` and carry the rendered `AGENT0:PROJECT` region in both entrypoints. Consumer values remain consumer-owned: Agent0 ships only `.agent0/project-core.md.example` as a placeholder/template and keeps the real `.agent0/project-core.md` outside the sync manifest.

Update the language fallback rule and harness-sync documentation so future agents know the authority order: project-core first, runtime/local overrides next where applicable, and the generic language rule only as a fallback. Add a focused harness-sync scenario proving the example file ships while the real consumer source stays untouched.

## Files to touch

**Create:**
- `.agent0/project-core.md` - Agent0's own always-on language, locale, voice, and scope guidance.
- `.agent0/project-core.md.example` - configurable consumer placeholder.
- `.agent0/tests/harness-sync/47-project-core-example.sh` - regression test for example shipping without real source overwrite.

**Modify:**
- `CLAUDE.md` - add the rendered `AGENT0:PROJECT` region for Claude Code.
- `AGENTS.md` - add the same rendered `AGENT0:PROJECT` region for Codex and AGENTS.md-standard tools.
- `.agent0/tools/sync-harness.sh` - add `.agent0/project-core.md.example` to the sync manifest, not `.agent0/project-core.md`.
- `.agent0/context/rules/harness-sync.md` - document the example/source split.
- `.agent0/context/rules/language.md` - point agents to project-core as the durable language/locale authority.
- `.agent0/context/rules/runtime-capabilities.md` - list project-core as a shared customization/sync surface.
- `.agent0/HANDOFF.md` - record current spec state and no-consumer-sync boundary.

**Delete:**
- None.

## Alternatives considered

### Add manual language sections directly to both entrypoints

Rejected because `CLAUDE.md` and `AGENTS.md` would become two editable sources that can drift. The existing project-core mirror already solves the cross-runtime entrypoint gap with one source.

### Put Agent0's `.agent0/project-core.md` into the sync manifest

Rejected because consumers need their own language/locale configuration. Agent0 can ship an example, but the real source must stay consumer-owned and outside the manifest.

### Wait for spec 171 context routing

Rejected because language/locale is always-needed static project framing, not event-scoped context. It should remain available even while prompt-time context injection is disabled.

## Risks and unknowns

- Adding `.agent0/project-core.md` to Agent0 means `check-instruction-drift.sh` will require both root entrypoints to carry a matching `AGENT0:PROJECT` region. This is intended, but the entrypoints must stay in sync.
- Future consumer syncs will receive the example file. Operators still need to decide whether to copy/customize it into `.agent0/project-core.md`; this spec deliberately does not auto-create that file for them.
- If a consumer already has `.agent0/project-core.md.example` customized, baseline reconciliation can refuse without `--force`, as with other harness-owned files.

## Research / citations

- `.agent0/context/rules/harness-sync.md` - current project-core source/mirror contract and AGENTS authority order.
- `.agent0/tools/sync-harness.sh` - `PROJECT_SOURCE_REL`, `sync_project_core`, and `COPY_CHECK_FILES`.
- `.agent0/tests/harness-sync/37-project-core-mirror.sh` - existing spec 131 mirror coverage.
- `.agent0/tools/check-instruction-drift.sh` - existing drift invariant when `.agent0/project-core.md` exists.
