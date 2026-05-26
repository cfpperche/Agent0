# 092 — multi-runtime-handoff — tasks

_Generated from `plan.md` on 2026-05-26. Work top-to-bottom. Check boxes as tasks complete. If a task reveals the plan is wrong, update `plan.md` before continuing._

## Implementation

### Layer 1 — Canonical file

- [x] 1. Create `.agent0/` directory and `.agent0/HANDOFF.md` populated from current `.claude/SESSION.md` content reshaped into the 4 required sections (`Current State` / `Active Work` / `Next Actions` / `Decisions & Gotchas`). The 2026-05-26 spec-092-plan context already in `.claude/SESSION.md` migrates verbatim — only the section labels change. Keep the file ≤ 4 KB.

### Layer 2 — Rule rewrites (prerequisite for hooks)

- [x] 2. Rewrite `.claude/rules/session-handoff.md`: canonical path → `.agent0/HANDOFF.md`; document the 4-section template (with concrete examples for `Active Work` bullet shape: owner runtime + touched paths + release condition); rename `## Parallel WIP coordination` → `## Active Work coordination` and migrate the bullet grammar; add new `## Asymmetric enforcement` paragraph explaining Claude-enforces-via-hooks vs Codex-follows-AGENTS.md-convention; document the 3-layer SessionStart fallback and pointer-detection content-marker (`<!-- AGENT0_HANDOFF_POINTER -->`); preserve § Size discipline, § State files, § Edit attribution, § Reader-side defence verbatim (those are hook-internal, not handoff-path).

- [x] 3. Update `.claude/rules/compaction-continuity.md`: add one paragraph noting `.agent0/HANDOFF.md` is injected on both `source=startup` AND `source=compact`; the per-event compact-history snapshot machinery is unchanged and stacks additively with the HANDOFF.md injection.

### Layer 3 — Hook rewiring

- [x] 4. Update `.claude/hooks/session-start.sh`: change `SESSION_FILE` constant to `$PROJECT_DIR/.agent0/HANDOFF.md`; add a `LEGACY_SESSION_FILE="$PROJECT_DIR/.claude/SESSION.md"` constant for the layer-(b) fallback. Replace the `if [[ "$SOURCE" == "compact" ]]; then ... elif [[ -f "$SESSION_FILE" ]]; then ...` branch with a unified block that (a) when HANDOFF.md exists → inject it as `=== HANDOFF.md (canonical handoff) ===` regardless of source; (b) else-if SESSION.md exists AND first non-blank line is NOT `<!-- AGENT0_HANDOFF_POINTER -->` → inject the legacy file under its old `=== SESSION.md (handoff from prior session) ===` header AND append a `migration-advisory: .claude/SESSION.md is legacy; create .agent0/HANDOFF.md to migrate` line; (c) else → append a `=== handoff-advisory ===\n'.agent0/HANDOFF.md' missing — create it to enable handoff\n=== end handoff-advisory ===` block. The compact-history snapshot injection (when `SOURCE=compact`) keeps running as a separate additive block — never replaces HANDOFF.md injection.

- [x] 5. Update `.claude/hooks/session-stop.sh`: change `SESSION_FILE` constant to `$PROJECT_DIR/.agent0/HANDOFF.md`. The freshness mtime check (`SESSION_FILE -nt STARTED_AT`) targets HANDOFF.md only — legacy `.claude/SESSION.md` no longer satisfies freshness, period (pointer-only file should never be "updated"). The edit-attribution logic (tracker file + porcelain-compare fallback) is untouched — only the freshness target changes. Update the block message JSON to name `.agent0/HANDOFF.md` (not SESSION.md) and the 4 new section labels.

### Layer 4 — Cutover

- [x] 6. Overwrite `.claude/SESSION.md` with the pointer-only content. Required shape: first non-blank line is the literal HTML-comment marker `<!-- AGENT0_HANDOFF_POINTER -->`; body is ≤ 3 lines of human-readable prose naming `.agent0/HANDOFF.md` and referencing `.claude/rules/session-handoff.md`. Total file size ≤ 256 B target (informational; hook detection is marker-based, not size-based).

### Layer 5 — Entrypoint parity

- [x] 7. Update `CLAUDE.md`: add `## Session handoff` section (in document order, near the existing `## Runtime entrypoints` block) — one paragraph naming `.agent0/HANDOFF.md` as the canonical handoff, the 4-section template, asymmetric enforcement (Claude=hooks, Codex=convention), and pointing at `.claude/rules/session-handoff.md`.

- [x] 8. Update `AGENTS.md`: mirror the same `## Session handoff` paragraph inside the `<!-- AGENT0:BEGIN ... AGENT0:END -->` managed block. If a sync mechanism between CLAUDE.md and AGENTS.md managed block exists (per spec 090), use it; otherwise hand-mirror the section.

### Layer 6 — Tests

- [x] 9. Extend `.claude/tests/session-handoff/`: add scenario tests covering (a) HANDOFF.md present → injected at SessionStart on both startup and compact source; (b) HANDOFF.md absent + SESSION.md non-pointer → legacy injection + `migration-advisory:` line emitted; (c) HANDOFF.md absent + SESSION.md is pointer-only (carries marker) → no legacy injection, missing-handoff advisory emitted; (d) HANDOFF.md absent + SESSION.md absent → missing-handoff advisory only; (e) Stop hook freshness — HANDOFF.md unchanged + own dirty WIP → blocks; HANDOFF.md updated during session → exits silently. Follow the bash-scenario shape of existing tests (`01-noop-with-carryover.sh`, `02-edits-without-session-update.sh`, etc.).

- [x] 10. Extend `.claude/tests/compaction-continuity/`: add a scenario covering `source=compact` SessionStart with HANDOFF.md present → both the HANDOFF.md banner AND the compact-history snapshot banner appear in injection output (additive, neither replaces the other).

## Verification

- [x] 11. Run `bash .claude/tests/session-handoff/run-all.sh` — all scenarios (existing + new) pass.
- [x] 12. Run `bash .claude/tests/compaction-continuity/run-all.sh` — all scenarios (existing + new) pass.
- [x] 13. **Dogfood verification** — end this implementation session normally; the Stop hook should evaluate freshness against `.agent0/HANDOFF.md` (the new canonical) and accept this session's update without blocking. Next session start re-injects `.agent0/HANDOFF.md` (layer-a path), not the legacy SESSION.md. Compaction during a long session re-injects `.agent0/HANDOFF.md` AND the compact-history snapshot.
- [x] 14. **Spec 092 acceptance scenarios** — walk the 7 scenario bullets and 6 static-fact bullets in `spec.md § Acceptance criteria`. Each must be satisfied by the diff this implementation produced.

## Notes

_Anything that came up during execution that doesn't belong in plan.md but is useful for the PR description or future readers._
