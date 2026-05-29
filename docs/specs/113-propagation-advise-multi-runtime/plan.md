# 113 — propagation-advise-multi-runtime — plan

_Drafted from `spec.md` on 2026-05-29. Update this file if implementation reveals the plan is wrong; do NOT silently diverge._

**Open questions resolved (defaults adopted, 2026-05-29):**
1. Move the hook to `.agent0/hooks/propagation-advise.sh` (106–111 convention) — co-located with `_memory-hook-lib.sh` it now sources.
2. Maintainer-only Codex activation: brief pointer in the rule, full steps in `.agent0/memory/propagation-advisory-maintenance.md`. NO block in the shipped `.codex/config.toml.example`.

## Approach

Port `propagation-advise.sh` to runtime-neutral exactly like the 106–111 hooks, with one new wrinkle the memory ports never hit: **content scanning** (the memory hooks only extract *paths* from `apply_patch`; this hook must scan the *added content* for leak patterns).

The clean refactor is to funnel both runtimes through a common intermediate — a list of `(relpath, content-to-scan)` pairs — then run the existing 5-pattern scan over each pair whose relpath is in the shipped surface:

- **Claude** (`tool_name ∈ {Edit, Write, MultiEdit}`): one pair — `(file_path, new_string|content|concat(edits[].new_string))`. Same extraction as today.
- **Codex** (`tool_name = apply_patch`): parse the patch body (`memory_patch_body`) into per-file sections delimited by `*** (Add|Update|Delete|Move) File:` markers; for each section, the relpath is the marker target and the content is that section's **added lines** (`^+`, prefix stripped) — parity with Claude's "new content only" scan.

Everything downstream (shipped-surface path scoping, within-surface exclusions, override marker, the 5 `scan_pattern` calls, the `head -5` cap, exit 0) is shared and unchanged. `PROJECT_DIR` comes from `memory_project_dir` (handles `AGENT0_PROJECT_DIR`/`CLAUDE_PROJECT_DIR`/cwd) instead of the bare `CLAUDE_PROJECT_DIR`.

The maintainer-only exclusion is preserved by pointing `COPY_CHECK_EXCLUDE` at the new path; the `merge_settings_json` companion filter already matches on the `propagation-advise.sh` basename, so it keeps working regardless of dir. The Codex registration is NOT added to the shipped `.codex/config.toml.example` (that would dangle in consumers — the spec-112 bug class); it's documented for the maintainer's own gitignored `.codex/config.toml`.

## Files to touch

**Move:**
- `.claude/hooks/propagation-advise.sh` → `.agent0/hooks/propagation-advise.sh` (`git mv`), then rewrite for both runtimes.

**Modify — the hook itself** (`.agent0/hooks/propagation-advise.sh`):
- Source `_memory-hook-lib.sh`; use `memory_project_dir` / `memory_runtime` / `memory_patch_body` / `memory_relpath`.
- Add the Codex `apply_patch` per-file added-content extraction; funnel both runtimes through shared `(relpath, content)` scanning.
- Update the self-exclusion path to `.agent0/hooks/propagation-advise.sh`.
- Tag advisory lines unchanged (`propagation-advisory: <kind> in <relpath>:<line> — <text>`); keep override marker + `CLAUDE_SKIP_PROPAGATION_ADVISE=1`.

**Modify — registration + sync:**
- `.claude/settings.json` — update the `PostToolUse(Edit|Write|MultiEdit)` command path `.claude/hooks/` → `.agent0/hooks/`. (Claude keeps the `Edit|Write|MultiEdit` matcher; apply_patch is Codex-only and lives in the maintainer's config.)
- `.agent0/tools/sync-harness.sh` — `COPY_CHECK_EXCLUDE`: `.claude/hooks/propagation-advise.sh` → `.agent0/hooks/propagation-advise.sh`. (Verify the `merge_settings_json` basename filter still matches.)

**Modify — tests** (`.claude/tests/propagation-advisory/`):
- All 11 scenarios: `HOOK="$AGENT0_ROOT/.claude/hooks/..."` → `.agent0/hooks/...`.
- Add `12-codex-apply-patch-triggers.sh`: an `apply_patch` payload writing a leak into a shipped path fires the advisory; add `13-codex-non-shipped-silent.sh` (apply_patch to a non-shipped path stays silent). Wire both into `run-all.sh`.

**Modify — docs:**
- `.claude/rules/propagation-advisory.md` — note the new path + runtime-neutral firing + a one-line pointer to the maintainer Codex activation.
- `.agent0/memory/propagation-advisory-maintenance.md` — full maintainer-only Codex activation steps (own `.codex/config.toml`, `^apply_patch$` matcher; NOT the shipped example) + the dangling-ref rationale.
- `.claude/rules/runtime-capabilities.md` — flip the propagation-advise-relevant note / add row if present (Claude-only → runtime-neutral).
- `CLAUDE.md` / `AGENTS.md` § Propagation advisory — update the hook path reference if it names `.claude/hooks/`.

## Alternatives considered

### Keep the hook in `.claude/hooks/`, add only a Codex registration

Rejected: breaks 106–111 convention (all ported hooks live in `.agent0/hooks/` and source the shared lib from there). Co-location with `_memory-hook-lib.sh` is cleaner and the move cost is mechanical (one path each in settings + sync exclude + 11 tests).

### Scan the whole apply_patch body (not per-file added lines)

Rejected: over-broad — would match removed lines (`^-`) and context, and couldn't attribute a finding to the right file when a patch touches several. Per-file `+`-line extraction gives parity with Claude's new-content scan and correct `<relpath>` attribution.

### Add the Codex block to `.codex/config.toml.example`

Rejected hard: the example ships verbatim to consumers (no exclusion filter), so a block pointing at a maintainer-only (non-shipped) hook = dangling reference in every consumer — the exact spec-112 bug. Maintainer registers in their own gitignored `.codex/config.toml`.

## Risks and unknowns

- **apply_patch added-line prefix.** The Codex extraction assumes added lines start with `+` (unified-diff-style hunks under `*** Update File:` / `*** Add File:`). If a Codex format variant differs, the scan UNDER-fires (misses a leak) rather than over-fires — acceptable for a non-blocking advisory; documented as a gotcha. The memory hooks confirm the `*** … File:` header format is what Codex sends.
- **Line numbers in the advisory are within the extracted content block, not file lines** — already true for the Claude path (new_string line numbers ≠ file lines). Consistent imprecision, not a regression.
- **Settings change needs session restart** — the moved hook's new registration is live only next Claude session; this session's validation is via direct hook invocation in tests (same as how 112 was verified), not by triggering the live hook.
- **Codex live dogfood is human-brokered** — the both-runtime proof for the Codex firing path comes from the dogfood prompt at the end (real `apply_patch` in a Codex session), mirroring 106–111. Tests simulate the apply_patch payload shape; the live run confirms the real payload matches.

## Research / citations

- `.agent0/hooks/_memory-hook-lib.sh` — `memory_patch_body` (apply_patch body), `memory_extract_paths` (`*** … File:` header parsing), `memory_runtime`, `memory_project_dir`. Grounding for the Codex extraction.
- `.agent0/hooks/memory-events-journal.sh` — reference both-runtime hook structure (lib sourcing, project-dir, runtime detection).
- Spec 112 notes.md § Deviations — the `.codex/config.toml.example` dangling-ref bug class this spec avoids.
- 106–111 specs — the runtime-neutral port pattern + live-dogfood-before-shipped discipline.
