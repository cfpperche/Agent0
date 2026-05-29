# 113 — propagation-advise-multi-runtime

_Created 2026-05-29._

**Status:** shipped

## Intent

Migrate `propagation-advise.sh` from `.claude/hooks/` (Claude-only) to a
runtime-neutral home so it ALSO fires on Codex `apply_patch` edits — completing
the 106–111 hook-migration arc for the last edit-surface advisory still left
behind. (Spec 112 removed the other two edit-surface advisories — supply-chain
+ secrets-advise — instead of porting them; propagation-advise is the one that
survived and therefore the one to port.)

The motivation is real, not bookkeeping: `propagation-advise.sh` guards against
upstream-internal pointers (spec-NNN refs, `/home/<user>/` paths, `anthill`
lineage, `.agent0/memory/<file>.md` pointers) leaking into **shipped** files.
The upstream maintainer dogfoods Codex. A leak written via a Codex `apply_patch`
edit to a rule/hook today is **invisible** — Codex doesn't run `.claude/hooks/*`.
Runtime-neutrality closes that gap.

**The wrinkle that makes this NOT a mechanical 106–111 port** (the whole reason
it needs its own spec): propagation-advise is **maintainer-only**. It's doubly
excluded from consumer shipping — `sync-harness.sh` `COPY_CHECK_EXCLUDE` drops
the file, and a `merge_settings_json` companion filter drops its Claude
registration from the consumer `settings.json` merge. The 106–111 runtime-neutral
pattern registers the Codex side in `.codex/config.toml.example`, which ships to
consumers as a **plain verbatim file** (`COPY_CHECK_FILES`) with NO exclusion
filter. A naive port would therefore ship a Codex registration block pointing at
a hook that is excluded from shipping → a dangling reference in every consumer —
**the exact bug class spec 112 just cleaned up** (the supply-chain block in
`.codex/config.toml.example`). This spec exists to port it WITHOUT recreating
that bug.

## Acceptance criteria

- [x] **Scenario: propagation-advise fires on a Codex apply_patch edit**
  - **Given** the maintainer has activated the migrated hook on Codex (per the documented activation)
  - **When** a Codex `apply_patch` writes a leak pattern (e.g. `spec 080`) into a shipped file (`.claude/rules/*.md`)
  - **Then** a `propagation-advisory:` line is surfaced to the Codex-visible context
- [x] **Scenario: migrated hook still fires on Claude edits (regression)**
  - **Given** the hook now lives at its runtime-neutral path
  - **When** a Claude `Edit` writes a leak pattern into a shipped file
  - **Then** the `propagation-advisory:` line is emitted exactly as before the migration
- [x] **Scenario: no dangling Codex registration ships to consumers**
  - **Given** the migration is applied
  - **When** `.codex/config.toml.example` is inspected (the file that ships verbatim to consumers)
  - **Then** it carries NO active or commented block referencing `propagation-advise.sh` — the maintainer-only Codex registration lives only in the maintainer's own gitignored `.codex/config.toml`, never in the shipped template
- [x] The hook resolves leak patterns from the Codex `apply_patch` payload (file path + new content) via the shared `_memory-hook-lib.sh` extraction, mirroring the 106–111 ports.
- [x] `sync-harness.sh` still excludes the hook from consumer shipping at its new path — `COPY_CHECK_EXCLUDE` is updated to the new path AND the `merge_settings_json` companion filter still drops the Claude registration.
- [x] The override marker (`# OVERRIDE: propagation-exempt:`) and the `CLAUDE_SKIP_PROPAGATION_ADVISE=1` escape hatch behave identically on both runtimes.
- [x] Existing `.claude/tests/propagation-advisory/` suite stays green; a Codex-path scenario is added.
- [x] `.claude/rules/propagation-advisory.md` + `.agent0/memory/propagation-advisory-maintenance.md` updated to document the new path + the maintainer-only Codex activation (own `.codex/config.toml`, not the shipped example).

## Non-goals

- **Porting the runtime-introspect pair** (`runtime-capture.sh` / `runtime-pre-mark.sh`). They are the other 106–111 leftover but are a distinct concern (different surface, not maintainer-only) — separate spec. This spec is scoped to the single hook the founder named.
- **Shipping propagation-advise to consumers.** It stays maintainer-only on BOTH runtimes; this spec only changes WHERE it lives + adds the Codex firing path, not WHO gets it.
- **Building a generic Codex-example exclusion mechanism.** The recommended approach sidesteps it (maintainer registers in their own gitignored config). If a future maintainer-only Codex hook makes a shipped-example exclusion genuinely necessary, that's its own spec.

## Open questions

- [x] Does the hook physically move to `.agent0/hooks/propagation-advise.sh` (matching 106–111 convention), or stay at `.claude/hooks/` and just gain a Codex registration in the maintainer's `.codex/config.toml`? The 106–111 precedent moves the file to `.agent0/hooks/`; confirm that's right here even though it's maintainer-only (the move means updating `COPY_CHECK_EXCLUDE` + the merge filter to the new path). Proposed default: move to `.agent0/hooks/` for consistency with the arc.
- [x] Is the maintainer-only Codex activation documented in the rule, the maintenance memory, or both? Proposed: brief pointer in the rule, full activation steps in `propagation-advisory-maintenance.md` (maintainer-binding surface).
- [x] Does Codex surface PostToolUse command output to the transcript/context? Yes, but only via JSON stdout using `hookSpecificOutput.additionalContext`. Plain stdout and exit-0 stderr are ignored on Codex `PostToolUse`. Live-proven 2026-05-29 with `_dogfood-113d.md`.

## Context / references

- Spec 112 (`docs/specs/112-prune-supply-chain-and-secrets-advise/`) — removed the sibling edit-surface advisories; its notes.md § Deviations documents the `.codex/config.toml.example` dangling-ref bug class this spec must avoid.
- 106–111 hook-migration arc — the runtime-neutral pattern (`_memory-hook-lib.sh` sourcing, runtime-tagged output, Codex `apply_patch` path extraction, live both-runtime dogfood before flipping shipped).
- `.agent0/tools/sync-harness.sh` lines 216-218 (`COPY_CHECK_EXCLUDE`) + ~690/701 (`merge_settings_json` companion filter) — the dual maintainer-only exclusion to preserve at the new path.
- `.claude/rules/propagation-advisory.md` + `.agent0/memory/propagation-advisory-maintenance.md` — the capacity's consumer-facing rule + maintainer-binding companion.
- `.claude/rules/runtime-capabilities.md` — the matrix; propagation-advise's runtime row updates from Claude-only to runtime-neutral when this ships.
