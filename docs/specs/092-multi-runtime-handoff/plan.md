# 092 — multi-runtime-handoff — plan

_Drafted from `spec.md` on 2026-05-26. Update this file if implementation reveals the plan is wrong; do NOT silently diverge._

## Approach

Migrate the live handoff from `.claude/SESSION.md` (Claude-namespaced, hook-coupled) to `.agent0/HANDOFF.md` (runtime-neutral, same shape) in one PR, with **Claude's hooks as the only enforcement surface** and **AGENTS.md guidance as Codex's convention surface** — asymmetric by design (spec non-goal #2: no Codex lifecycle hook parity in v1).

The migration is structured as five mechanical layers stacked bottom-up; each can be reviewed independently in the PR diff:

1. **New canonical file.** Create `.agent0/HANDOFF.md` populated from the *current* live `.claude/SESSION.md` content, reshaped into the 4 sections the spec mandates (`Current State` / `Active Work` / `Next Actions` / `Decisions & Gotchas`). The existing prior-session handoff content (session 2026-05-26, spec 092 synthesis applied) survives the migration verbatim under the new section labels — no information loss.
2. **Pointer-only legacy file.** Overwrite `.claude/SESSION.md` with a ~3-line pointer. Pick the **content-marker** detection mechanism (rejected alternatives below): the pointer file's first non-blank line is the literal `<!-- AGENT0_HANDOFF_POINTER -->`. Hooks (and the 3-layer fallback) grep for that marker to decide pointer-vs-legacy. Content-marker beats size-threshold (false-positive risk on a genuinely tiny session handoff) and beats frontmatter (adds parser dependency to bash hooks).
3. **Claude hooks rewired to `.agent0/HANDOFF.md`.** Both `session-start.sh` and `session-stop.sh` change their `SESSION_FILE` constant. SessionStart gets the 3-layer fallback (per spec acceptance criterion line 53): (a) HANDOFF.md present → inject; (b) SESSION.md present AND first non-blank line ≠ pointer marker → inject + emit `migration-advisory: .claude/SESSION.md is legacy; create .agent0/HANDOFF.md to migrate`; (c) neither → emit `.agent0/HANDOFF.md missing — create it to enable handoff` and proceed (no abort). Stop's freshness check (mtime > started-at) targets HANDOFF.md only; legacy SESSION.md is no longer a valid freshness substrate (a stale pointer file should never satisfy the check). Both hooks fire on `source=startup` AND `source=compact` (spec line 51) — the `if [[ "$SOURCE" == "compact" ]]; then … elif [[ -f "$SESSION_FILE" ]]; then …` branch collapses into a unified injection block that runs the HANDOFF.md path on both sources, with the compact-history snapshot appended additively (never replacing).
4. **Rules updated in lockstep.** `.claude/rules/session-handoff.md` is rewritten end-to-end: canonical path becomes `.agent0/HANDOFF.md`, the four-section template is documented, `## Parallel WIP coordination` is rewritten as `## Active Work coordination` with the three required fields (owner runtime + touched paths + release condition) per spec line 36, and a new `## Asymmetric enforcement` paragraph documents that Claude enforces via hooks while Codex follows AGENTS.md convention. `.claude/rules/compaction-continuity.md` adds one paragraph noting both `source=startup` and `source=compact` now inject HANDOFF.md (the compact-history snapshot is unchanged; HANDOFF.md is additive).
5. **Codex entrypoint updated.** `AGENTS.md`'s `<!-- AGENT0:BEGIN -->` managed block gains a new `## Session handoff` paragraph mirroring CLAUDE.md's existing section, naming `.agent0/HANDOFF.md` and pointing at `.claude/rules/session-handoff.md` for the discipline. `CLAUDE.md` gets the same new section in its corresponding managed block (parity — both runtime entrypoints point at the same handoff). Per spec non-goal #10, **`.agent0/**` is NOT added to `.claude/tools/sync-harness.sh`'s manifest** — per-project state, never fork-managed.

**Open Q2 disposition (plan-level decision):** defer the stale-claim advisory to a follow-up spec. v1 ships with the `Active Work` bullet's explicit `release condition` field as the only stale-claim mechanism; no separate `stale-claim-advisory:` line in `Stop` / `SessionStart`. Rationale: the rule-of-three demand test (per `.claude/memory/feedback_speculative_observability.md`) hasn't fired — no empirical evidence yet that release-condition prose is insufficient. Build the advisory when ≥3 sessions surface stale-claim drift the field couldn't catch. The plan documents this as the chosen default; user can override before tasks.

**Backwards compatibility for fork sync.** `.claude/SESSION.md` is a per-project file (gitignored from sync-harness's view, but git-tracked in the fork — same posture today). The pointer-only rewrite is a per-project change; forks that pull this upstream sync don't get their `.claude/SESSION.md` overwritten because sync-harness already excludes it. New `.agent0/HANDOFF.md` is also outside the manifest. Forks adopting the new convention rewrite their own `.claude/SESSION.md` and create their own `.agent0/HANDOFF.md` — the rule update tells them how. The hook changes DO ship via sync; a fork on the new hooks but the old `.claude/SESSION.md` lands in fallback layer (b) — migration advisory + still functional. Zero-downtime by construction.

## Files to touch

**Create:**

- `.agent0/HANDOFF.md` — canonical, runtime-neutral handoff. 4 sections, ≤ 4 KB. Migrated from current `.claude/SESSION.md` content.

**Modify:**

- `.claude/SESSION.md` — overwrite with ~3-line pointer-only content. First non-blank line is the literal marker `<!-- AGENT0_HANDOFF_POINTER -->`; body names `.agent0/HANDOFF.md` and references `.claude/rules/session-handoff.md`.
- `.claude/hooks/session-start.sh` — change `SESSION_FILE` constant to `.agent0/HANDOFF.md`. Collapse the `compact`/`startup` branch so HANDOFF.md injection runs on both sources. Add the 3-layer fallback (HANDOFF.md → legacy non-pointer SESSION.md + advisory → missing-file advisory).
- `.claude/hooks/session-stop.sh` — change `SESSION_FILE` constant to `.agent0/HANDOFF.md`. Freshness mtime check targets HANDOFF.md only; legacy SESSION.md is not a valid substitute. Edit-attribution logic (tracker + porcelain-compare) unchanged — spec line 26 explicitly preserves it.
- `.claude/rules/session-handoff.md` — full rewrite (see Approach step 4). Migrate `## Parallel WIP coordination` → `## Active Work coordination` with the three required fields; add `## Asymmetric enforcement` paragraph; update all `.claude/SESSION.md` references to `.agent0/HANDOFF.md`; keep the size discipline (4 KB), state-file machinery, edit-attribution, and reader-side truncation defence sections intact (those are hook-implementation details, not handoff-path details).
- `.claude/rules/compaction-continuity.md` — add one paragraph noting HANDOFF.md is now injected on both `source=startup` and `source=compact`; the per-event compact-history snapshot machinery is unchanged.
- `AGENTS.md` — inside `<!-- AGENT0:BEGIN ... AGENT0:END -->` managed block, add a `## Session handoff` paragraph naming `.agent0/HANDOFF.md` and `.claude/rules/session-handoff.md`. Codex reads/updates per the rule.
- `CLAUDE.md` — same `## Session handoff` paragraph in its corresponding managed block (parity).

**Delete:**

- Nothing structurally. `.claude/SESSION.md` is overwritten, not deleted (preserves `git log --follow` history; the pointer is the new content).

## Alternatives considered

### Write-through mirror for `.claude/SESSION.md` (legacy stays in sync with `.agent0/HANDOFF.md`)

Rejected because it reintroduces two mutable sources of truth — the exact failure mode this spec is trying to eliminate. Every edit to HANDOFF.md would need a hook to re-write SESSION.md, drift detection would compete with the size discipline, and a fork on old hooks would silently diverge. Non-goal #8 of the spec explicitly rejects this; the debate Round 1 critique #1 (Claude Code reviewing agent) drove the resolution to pointer-only. Documented here for the audit trail, not as a real option.

### Hot-swap the path without a fallback layer

Rejected because forks that pull the new hooks before migrating their own handoff content would lose injection entirely on the first post-sync session — no SESSION.md banner, no HANDOFF.md banner, agent boots context-blind. The 3-layer fallback (HANDOFF.md → legacy non-pointer SESSION.md + advisory → missing-file advisory) keeps every fork functional through the migration window at the cost of ~15 lines of bash in session-start.sh. The cost is paid once; the advisory nudges the fork operator to migrate at their own pace.

### Size-threshold pointer detection (`< 256 bytes` ⇒ pointer)

Rejected because a genuinely terse handoff from a quiet session (single-sentence "Current State: nothing in flight; next: deciding 092 path") would trip a false positive — the hook would treat the legitimate handoff as a pointer and skip injection. Content-marker (`<!-- AGENT0_HANDOFF_POINTER -->`) has zero false-positive surface, is grep-trivial for bash, and is self-documenting (a human opening `.claude/SESSION.md` sees the marker and understands).

### Frontmatter-based pointer detection

Rejected for the same reason CLAUDE.md and AGENTS.md don't use frontmatter for the managed block: it adds a YAML-parser dependency to plain-bash hooks. The content-marker mechanism is grep + one regex; frontmatter would require either `yq` (extra dep) or fragile sed parsing.

### Ship the stale-claim advisory in v1 alongside the release-condition field

Rejected as speculative observability. The rule-of-three demand test hasn't fired — no empirical evidence yet that the release-condition field alone is insufficient. The plan documents the choice; if dogfood surfaces ≥3 cases where a stale `Active Work` bullet caused a real collision the field's prose couldn't catch, a follow-up spec scopes the advisory.

## Risks and unknowns

- **Pointer-marker discoverability.** A human opening `.claude/SESSION.md` after the migration sees a 3-line pointer and could be confused if they don't recognize the marker. Mitigation: the pointer body is prose-readable — "This file has moved. Current handoff: [.agent0/HANDOFF.md](../.agent0/HANDOFF.md). See `.claude/rules/session-handoff.md`." — the marker is HTML-comment, invisible in rendered markdown.
- **Fork-migration tail.** Forks that haven't migrated still emit advisory layer (b) on every session start. If a fork operator ignores the advisory for weeks, the visible advisory line in every session boot becomes noise. Acceptable — the advisory is the discoverability mechanism; ignoring it is the fork operator's choice. No auto-migration tool ships in v1 (would be over-engineering for a one-time, mechanical migration).
- **Codex compliance is convention-only.** Codex has no `Stop` hook enforcement; if a Codex session edits files and forgets to update HANDOFF.md, the next Claude session won't see the Codex work. Documented as spec non-goal #2; the `Active Work` bullet convention is the human-coordinated mitigation. The asymmetric-enforcement paragraph in the rule names this gap explicitly.
- **The `Active Work` `release condition` field semantics could drift.** "Release condition" is prose; sessions could write vague conditions ("when done") that defeat the coordination value. The rule documents three concrete examples (passing test name, merged PR number, "feature flag off") to anchor the shape. If drift surfaces, the stale-claim advisory deferred from Open Q2 is the follow-up.
- **Unknown: how AGENTS.md's managed block interacts with the new `## Session handoff` paragraph in a Codex fork that has its own override.** Per spec 090, fork customization belongs in `AGENTS.override.md` or nested `AGENTS.md` — the managed block stays Agent0-owned. The new paragraph lands inside `<!-- AGENT0:BEGIN ... AGENT0:END -->`; forks that have edited the managed block in-place (vs override) will see sync flag it `!! customized`. Acceptable — same posture as every other managed-block change.

## Research / citations

- `.claude/rules/session-handoff.md` — current handoff rule, source of truth for hook contract + state machinery + Parallel WIP shape being migrated to Active Work.
- `.claude/hooks/session-start.sh` (lines 17, 67-85) — current `SESSION_FILE` constant and the compact/startup branching that this plan collapses.
- `.claude/hooks/session-stop.sh` (lines 17, 103-106) — current freshness check and the edit-attribution logic that is preserved verbatim.
- `.claude/rules/compaction-continuity.md` — sibling rule, gets one paragraph noting HANDOFF.md injection on both hook firings.
- `docs/specs/090-multi-runtime-entrypoints/` — established `AGENTS.md` as Codex entrypoint and the `<!-- AGENT0:BEGIN ... AGENT0:END -->` managed-block contract this plan extends.
- `docs/specs/092-multi-runtime-handoff/debate.md` — Rounds 1-2 cross-model review (Codex CLI initiating, Claude Code reviewing) that resolved pointer-only, 4-section template, `Active Work` framing, and the 3-layer fallback shape.
- `.claude/memory/feedback_speculative_observability.md` (user memory) — rule-of-three demand test that drives the Open Q2 deferral.
- `.claude/rules/harness-sync.md` § Fork-extension convention — informs the fork-migration-tail risk above and the non-sync of `.agent0/**`.
