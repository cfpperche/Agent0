# {{NNN}} — {{SLUG}} — notes

_Created {{DATE}}._

_In-flight design memory for this spec — decisions, deviations, tradeoffs, and open questions surfaced **while building** that weren't pre-empted by `spec.md` or `plan.md`. Append-only by convention. See `.agent0/context/rules/spec-driven.md` § The four artifacts for purpose, and `.agent0/context/rules/delegation.md` § The 5-field handoff for how sub-agents integrate._

**Entry shape:** `### YYYY-MM-DD — <author> — <one-line title>` followed by free-prose body. `<author>` is `parent` for the orchestrating agent, or the `subagent_type` (e.g. `general-purpose`, `Explore`) for delegated work.

**Routing rubric:** decision made under ambiguity → §1 Design decisions. Intentional departure from `plan.md` → §2 Deviations. Alternative weighed and chosen mid-flight → §3 Tradeoffs. Question surfaced during build, no answer yet → §4 Open questions. Sections may stay empty; the rubric is a guide, not a quota.

## Design decisions

_Choices made where the spec/plan was ambiguous. The decision itself + why this option over others considered in the moment._

### 2026-06-04 — parent — gate contract is `squad.json` (not `.yaml`) in v1

The debate said "squad.yaml or squad.json". Chose **JSON** for v1: `jq` is already a harness-wide dependency and parses it natively; YAML would add a `yq` dependency for marginal ergonomic gain. `squad-contract.md` documents this as a v1 decision; a `squad.yaml` form is a future nicety. The skill/rule/CLAUDE index all say `squad.json`.

### 2026-06-04 — parent — deterministic core fully tested; live pump is a separate dogfood

`squad.sh` (state machine: turn-lock, budget, gate, terminal states, guard, rollback) is shell-unit-tested 8/8 — every invariant, including the load-bearing "agreement ≠ done" (gate red + both proposed → status stays `running`). The **live autonomous pump** (a real 2-agent loop writing code via the exec bridges) is NOT unit-tested — it costs tokens, needs a target spec, and runs wall-clock. The test suite IS the dry-run of the state machine the pump drives; a real dogfood on a tiny low-risk pre-planned spec is the honest next validation, gated separately. This is scoped explicitly (spec § last acceptance bullet) — not a gap hidden behind a green suite.

### 2026-06-04 — parent — out-of-turn detection model (v1)

git can't attribute a working-tree change to a specific agent, so v1 "out-of-turn" = changes present in the working-tree fingerprint (`git status --porcelain`) when **no turn is open** (`turn_open=false`), compared against the boundary snapshot taken at the last `turn-end`. `guard` → `aborted_conflict`. Forbidden/human-gated path patterns are matched against the changed paths → `aborted_policy` / `human_checkpoint_required`. Run-dir lives under `.agent0/.runtime-state/squads/` (inherits the existing gitignore; zero new entry); the durable record is the spec + the git history of the turns.

## Live dogfood — 2026-06-04 (the real validation)

First live `/squad` runs on a tiny throwaway target (`slugify` — gate `node test.js`). Two passes:

- **Pass 1 (state-machine integration, `/tmp` repo, orchestrator drove both turns):** init → R0 partial (gate RED, repair 1/2) → R1 complete → gate GREEN + both proposed → `ready_for_human_prod`. The load-bearing **agreement≠done** invariant held LIVE: both agents `propose-done` while the gate was RED kept status `running` (repair), never closed. Proves the subcommands *compose* in sequence on a real repo (unit tests cover them in isolation).
- **Pass 2 (real exec-bridge handoff, inside Agent0, spec `199-squad-dogfood`):** Claude opened with a failing stub → **real Codex** via `codex-exec --sandbox workspace-write` (34s wall-clock, exit 0) implemented the fix touching only the sandbox file → gate GREEN → `ready_for_human_prod`. The external gate was the closer; the bridge handoff works end-to-end.

### Findings (→ a 150.1 hardening pass)

1. **🔴 Bridge anchors to the Agent0 root.** `codex-exec`/`claude-exec` set `ROOT="$SCRIPT_DIR/../../../.."` and hard-refuse `--cwd` outside it. So `/squad` can only drive the peer against a repo that **contains the harness** (Agent0 itself, or a consumer with it synced) — never an external/`/tmp` repo. **Action:** make this an explicit SKILL/rule precondition (currently unstated); it shaped the whole dogfood (Pass 1 had to fake Codex's turn).
2. **🔴 `forbidden_paths`/conflict only catch OUT-OF-TURN changes.** The documented pump order is `turn-end` → `guard`, but `turn-end` sets `boundary=cur` (folding in the turn's own changes), so `guard` sees empty `newlines` → an **in-turn** touch of a forbidden path escapes. (Test 07 only passes because it creates the forbidden file *after* `turn-end`.) **Action:** `guard` (or `turn-end`) should evaluate `forbidden_paths`/`human_gated_paths` against the turn's OWN diff (`changed_paths`), not only changes-since-boundary. Mitigated in the dogfood by an orchestrator-side `git status --porcelain` scope check before accepting Codex's turn.
3. **🟡 Fingerprint is path-level, not content-level.** Rewriting an already-listed (untracked) file keeps the same `?? path` porcelain line, so `guard`'s set-difference sees no change. A peer can fully rewrite an already-touched file invisibly. **Action:** for boundary/diff integrity, hash content (or stage to compare blobs), not just the porcelain path list.
4. **🟡 Target must gitignore `.agent0/.runtime-state/`** or the run-dir itself shows up in `changed_paths` (seen in Pass 1's `/tmp` repo, which had no `.gitignore`). Agent0 + consumers already ignore it, so this is a robustness precondition, not a field bug.

Net: the deterministic core + the live loop both hold; #1 and #2 are the load-bearing hardening for 150.1 before recommending `/squad` for real specs.

### 150.1 — resolution (2026-06-04)

Fast-follow (no new spec dir, per the 149.1 convention). Both 🔴 fixed; both 🟡 deferred with rationale.

- **#1 (bridge anchors to harness root) — FIXED (doc + guardrail).** Explicit precondition #5 in `SKILL.md` ("the target repo contains the Agent0 harness"), a matching bullet in `rules/squad.md`, and a **non-fatal `init` warning** when `.agent0/skills/codex-exec/scripts/codex-exec.sh` is absent under the target repo (assisted/single-runtime can still run; the autonomous pump cannot drive a peer there).
- **#2 (forbidden_paths only caught out-of-turn) — FIXED (semantics).** `turn-start` now snapshots a pre-turn fingerprint (`turn_start_fp`); `turn-end` computes `changed_paths` as **this turn's own delta** (vs `turn_start_fp`), while `boundary` stays the full fingerprint for out-of-turn conflict detection; `guard` policy-checks `forbidden_paths`/`human_gated_paths` against `changed_paths ∪ newlines`. New regression test `09-guard-policy-in-turn.sh` (TDD: red before, green after) covers the in-turn touch test 07 misses. Squad suite 9/9.
- **#3 (path-level, not content-level fingerprint) — DEFERRED (🟡).** Rewriting an already-`?? `-listed untracked file is still invisible to the porcelain set-diff. Out of 150.1 scope: needs content hashing / blob staging. Risk is bounded (a peer can only hide a rewrite of a path it already legitimately touched this turn). Tracked here for a future pass.
- **#4 (target must gitignore `.agent0/.runtime-state/`) — DEFERRED (🟡).** Agent0 + all consumers already gitignore it; only an issue for an ad-hoc repo without the harness's `.gitignore` — which precondition #5 now rules out anyway.

## Deviations

_Places where implementation intentionally departed from `plan.md`. The departure + the reason it was necessary or better._

### {{YYYY-MM-DD}} — {{author}} — {{one-line title}}

{{free-prose body — what the plan said, what was done instead, why}}

## Tradeoffs

_Alternatives weighed during implementation (not at plan time). The chosen path + what was given up + why the tradeoff was worth it._

### {{YYYY-MM-DD}} — {{author}} — {{one-line title}}

{{free-prose body — options considered in-flight, chosen path, accepted cost}}

## Open questions

_Questions surfaced during build that the implementer couldn't resolve alone. Owner (who decides) or path to resolution if known. Promote answered questions to `spec.md` § Open questions or as retroactive acceptance scenarios when the spec is updated._

### {{YYYY-MM-DD}} — {{author}} — {{one-line title}}

{{free-prose body — the question, why it surfaced, what's blocked on it, who can decide}}
