# 106 — delegation-hooks-multi-runtime — plan

_Drafted from `spec.md` on 2026-05-28. Update this file if implementation reveals the plan is wrong; do NOT silently diverge._

## Approach

Implement the two-layer architecture the 3-round debate converged on, in an order that keeps the live Claude hooks working throughout (no intermediate state where the gate or stop hook is broken).

**Layer 1 — discipline (the 5-field contract).** Claude keeps its blocking gate (`delegation-gate.sh`, unchanged blocking semantics). Codex gets the *same discipline as convention*, not enforcement: a new "Codex: convention-only" section in `delegation.md` instructs the orchestrator to self-apply `TASK/CONTEXT/CONSTRAINTS/DELIVERABLE-or-DONE_WHEN` when composing a subagent dispatch, since no Codex hook can block a spawn (verified across `SubagentStart`/`PreToolUse`/`PermissionRequest`). The precedent is `user-prompt-framing.md` (un-hookable boundary → rule-only self-discipline).

**Layer 2 — observability (lifecycle audit).** All audit rows consolidate into a single canonical `.agent0/delegation-audit.jsonl` (hard cutover — `.claude/delegation-audit.jsonl` removed entirely). Three producers write it: `delegation-gate.sh` (Claude dispatch row), the new `delegation-start-audit.sh` (Codex `SubagentStart` start row, non-blocking, `brief_observable:false`/`formatted:null` always), and the shared multi-runner `delegation-stop.sh` (close row, branching Claude vs Codex). Every row gains `schema_version`, `runtime`, `event`. The Codex correlation path adds an `agent_id-direct` value.

`.claude/.delegation-state/` (loop-budget counter) stays in `.claude/` — its producer (the `post-edit-validate.sh` loop-budget half) is deferred for Codex, so per the co-location corollary the state follows the producer, not the topic.

Implementation order: (1) `delegation.md`; (2) repoint `delegation-gate.sh`; (3) move + extend `delegation-stop.sh`; (4) create `delegation-start-audit.sh`; (5) register hooks; (6) hard-cutover purge; (7) matrix; (8) tests + validate.

## Files to touch

**Create:**
- `.agent0/hooks/delegation-start-audit.sh` — Codex `SubagentStart` start-audit hook (non-blocking, observability only).
- `.agent0/hooks/delegation-stop.sh` — moved from `.claude/hooks/`, extended to a shared multi-runner.
- `.claude/tests/061-delegation-stop/10-codex-branch.sh` — Codex-payload close-row + start-audit coverage.

**Modify:**
- `.claude/hooks/delegation-gate.sh` — `AUDIT_LOG` → `.agent0/delegation-audit.jsonl`; dispatch row gains `schema_version`, `runtime:"claude-code"`, `event:"dispatch"`.
- `.claude/rules/delegation.md` — add § *Codex: convention-only*; update § *Audit log* (new path, new schema fields, start-row shape, `agent_id-direct` correlation); repoint the 4 jq queries.
- `.claude/settings.json` — `SubagentStop` → `.agent0/hooks/delegation-stop.sh`.
- `.codex/config.toml.example` — add commented `[[hooks.SubagentStart]]` → `delegation-start-audit.sh` and `[[hooks.SubagentStop]]` → `delegation-stop.sh`.
- `.claude/rules/runtime-capabilities.md` — `delegation/subagents` Codex cell `unsupported` → `native-opt-in`; owner files; trim re-audit note.
- `.claude/rules/image-gen.md` — repoint the `.claude/delegation-audit.jsonl` forensics example.
- `.claude/rules/memory-placement.md` — repoint the two `.claude/delegation-audit.jsonl` sibling references.
- `.claude/rules/harness-sync.md` — repoint the `.gitignore` entry mention.
- `.gitignore` — replace `.claude/delegation-audit.jsonl`(+`.lock`) with `.agent0/delegation-audit.jsonl`(+`.lock`); keep `.claude/.delegation-state/`.
- `.claude/tests/061-delegation-stop/0{1..7}-*.sh` — audit path `$TMP/.claude/` → `$TMP/.agent0/`.
- `.claude/tests/061-delegation-stop/08-shellcheck.sh` — STOP_HOOK path → `.agent0/`; add `delegation-start-audit.sh`.

**Delete:**
- `.claude/hooks/delegation-stop.sh` — moved to `.agent0/`.
- `.claude/delegation-audit.jsonl` + `.lock` — the gitignored live file (hard cutover; per-machine, regenerated at `.agent0/`).

## Alternatives considered

### Single shared `delegation-gate.sh` that branches (Claude blocks / Codex advises)

Rejected in Round 1 of the debate: a shared filename implies a shared guarantee, and the blocking guarantee is absent on Codex (verified — no hook surface can block a spawn). Two different contracts behind one name is a lie by filename. Per-runtime split with distinct names (`delegation-gate.sh` blocks; `delegation-start-audit.sh` observes) is honest.

### Freeze `.claude/delegation-audit.jsonl` as legacy read (implicit-v1 dual-read)

This was the debate synthesis's proposal. Rejected by the user in favor of a **hard cutover** (aligns with `.agent0/memory/forks-ephemeral-dogfood.md` — hard cutover is the default back-compat posture). Simpler: no implicit-version reading rule, no two-file union in queries; the 478 KB gitignored file is discarded.

### Two per-runtime audit logs unioned by a query tool

Rejected in Round 2: worse for cross-runtime queries + consumer propagation. One file keyed by `runtime`+`event` is cleaner than two files a tool must union.

## Risks and unknowns

- **Codex-side hooks cannot be live-tested in this session** (no Codex CLI runtime here). Mitigation: synthetic fixtures replaying the documented Codex `SubagentStart`/`SubagentStop` payload surface (verified 0.134.0 field set), exactly as the existing 061 tests replay Claude payloads.
- **The hard-cutover purge touches several rule files with prose references** — risk of a missed reference. Mitigation: a final `grep -rn '.claude/delegation-audit.jsonl'` over the repo as an acceptance gate; zero hits = clean.
- **Live hook breakage mid-implementation.** Mitigation: order the edits so each hook is internally consistent after its own edit; `bash -n` after each hook edit; the parent (me) never triggers `post-edit-validate.sh`.
- **`.delegation-state` staying in `.claude/` while `delegation-stop.sh` moves to `.agent0/`** — the moved stop hook reads an absolute `$PROJECT_DIR/.claude/.delegation-state/...` path on the Claude branch; that path is unchanged, so the read still works. Confirmed acceptable, not a true risk.

## References

- `docs/specs/106-delegation-hooks-multi-runtime/{spec,debate}.md` — intent + the 3-round cross-model decision.
- `.agent0/memory/codex-cli-hooks.md` § Subagent dispatch surface — the verified Codex payload/blocking facts.
- `.agent0/memory/harness-home.md` — `.agent0/` vs `.claude/` placement + co-location corollary.
- `.agent0/memory/forks-ephemeral-dogfood.md` — hard-cutover posture.
- `.agent0/hooks/_memory-hook-lib.sh` — the dual-runtime branch precedent (runtime/actor detection) the stop hook reuses.
