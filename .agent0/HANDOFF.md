# Session handoff

Canonical runtime-neutral handoff for Agent0 sessions.

See `.agent0/context/rules/session-handoff.md` for the protocol.

---

## Current State

- **Spec 179 (sdd-close-advisory) SHIPPED + committed (`1b8830b`, local, not pushed).** Read-only auditor `.agent0/tools/sdd-close.sh` checks a shipped spec's artifacts vs its declared status (unchecked tasks/acceptance, surviving `{{placeholders}}` backtick-stripped, missing `**Closure:**`); `[<spec-dir>] [--json]`, exit 0/1/64, writes nothing. Validator emits non-blocking `sdd-close-advisory:` **opt-in via the `**Closure:**` line** (mirrors spec-verify's `**Verify:**` opt-in) — silent (0 lines) on the live corpus; `missing-closure` is the opt-out, never a nag; opt-out env `CLAUDE_VALIDATOR_SKIP_SDD_CLOSE=1`. Rule `.agent0/context/rules/sdd-close.md`; index in CLAUDE.md/AGENTS.md; suite `.agent0/tests/sdd-close/` 8/8. **Design pivot (notes.md):** a recency-window advisory was built first and rejected — Agent0's ~4-spec/day cadence floods even a 14-day window, and git mtime is the consolidation-repo migration date (all specs share `2026-05-25`), not authoring. Dogfoods 177 (`**Verify:**` pass 1/1) + the closure convention; doctor 24 ok/0 broken. **Not synced to consumers** (own call).
- **SDD-flow improvements wave SHIPPED + synced (this session).** Originated from a Claude×Codex adversarial debate on the SDD flow (Codex via `codex-exec.sh`; transcripts at `.agent0/.runtime-state/codex-exec/sdd-debate-out.md` + `sdd-threshold-out.md`). Two Agent0 commits on `main`, NOT pushed to origin yet:
  - **`d6da13c` — closure cluster.** `spec-driven.md`: `**Status:**` is now a bare enum (`draft|in-progress|shipped|shipped-partial|superseded|abandoned|deferred`); dates/commits/test-counts forbidden on it; closure evidence on an optional `**Closure:**` line; spec is a historical decision record unless it declares `**Verify:**`. `spec.md.tmpl` documents the enum + commented `**Closure:**`. `notes.md.tmpl` dropped the 4 `{{...}}` example blocks (kept headers). 177 dogfood: checked its 8+3 boxes (were `[ ]` despite shipped) + first real `**Closure:**`.
  - **`650b5b5` — spec 178 (sdd-admission-decision-gate), shipped.** Replaced the "Touches 3+ files" admission trigger with a **5-question decision gate** (high-cost surfaces embedded in questions 2/4, no rotting catalog); breadth is evidence only when it crosses independent boundaries. `§ When to skip` makes wide-but-trivial cases explicit + "skipping never waives proof" (PR/report.json/handoff recipients). `visual-contract.md` framing decoupled — UI proof owed with or without a spec (mechanism untouched; detector was already spec-independent). Dogfoods 177 (`**Verify:** doctor`, pass 1/1) + closure convention. doctor 24 ok/0 broken; read-through green on 4 acceptance scenarios.
  - **Synced to the 3 active consumers** (harness-only, explicit paths, their own product specs untouched): cognixse `ba2be1b`, acmeyard `da1070f`, mei-saas `1e5875f` — each got the 2 rules + 2 templates + baseline.json. All `--check`-clean (no customization refusals).
- **Spec 177 (spec-verify-advisory) shipped + pushed.** Per-spec rerunnable proof, ported from the studied `repository-harness` project into Agent0's markdown+shell+advisory idiom (no SQLite/CLI). `.agent0/tools/spec-verify.sh` runs a spec's `**Verify:** \`<cmd>\`` lines, records `## Verification log` to notes.md; `.agent0/validators/run.sh` emits non-blocking `spec-verify-advisory:` for a SHIPPED spec declaring a verify command with no passing latest record (opt-in). Built in `/squad` mode with Codex (3 real defects fixed in its peer turn); closed `ready_for_human_prod`. Suite `.agent0/tests/spec-verify/` 8/8 green. Agent0 commit `e31ca6f` on `main`.
- **Consumers synced + pushed for the 177 wave:** `cognixse` (`4c061c1`), `acmeyard` (`7e1849b`), `mei-saas` (`938dac4`) — harness-only commits via `sync-harness`; spec-verify suite verified 8/8 in each. `mei-saas` also caught up on prior pending syncs in the same commit.
- **Prompt-time context injection remains paused.** `UserPromptSubmit` hook registration is still absent from `.codex/hooks.json` and `.claude/settings.json`; `SessionStart` still points at `startup-brief.sh`.
- **Specs 173/174/175 shipped locally:** project-core source/example, bootstrap advisories, and local renderer are implemented. `.agent0/tools/project-core-sync.sh` renders `AGENT0:PROJECT`; edit hooks and `sync-harness.sh` delegate to it.
- **Spec 176 shipped locally:** `.agent0/project-core.md.example` carries marker `2026-06-08-1`; configured consumers preserve `.agent0/project-core.md` and see template-review advisory until their source marker matches.
- **Bootstrap cleanup contract:** source missing warns; source present silences bootstrap. Template-review is separate and clears only when source/example markers match.
- **`mei-saas` synced/configured:** project-core is pt-BR for product artifacts under `docs/`; entrypoints are hydrated from its source.
- **Browser verifier promotion shipped locally:** CognixSE had generic `agent-browser.sh verify-contract` hardening; it was ported to Agent0 and validated with visual-contract + agent-browser suites.
- **Consumers synced this section:** `cognixse` is synced with template-review advisory pending by design; `acmeyard` is synced and bootstrapped with marker `2026-06-08-1`; `mei-saas` was synced/configured earlier.
- **Validation passed:** project-core, bootstrap/template-review, status/doctor, harness-sync, instruction-drift, visual-contract, agent-browser, and `git diff --check`.

## Active Work

- **SDD-flow backlog from the debate — status after this session:**
  - ✅ Closure cluster — done (`d6da13c`).
  - ✅ Admission decision-gate — done (`650b5b5`, spec 178). The "admission threshold / volume" lever was **investigated and dropped as a flow change**: consumer evidence (Agent0 166 specs vs ~48 across 7 consumers) proved the volume is an Agent0 artifact, not a flow property — tightening the shipped gate would harm consumers. What survived is the file-count→decision-gate fix (different problem). Any Agent0-local "apply SDD less to meta-governance" discipline remains optional and unaddressed (would live in CLAUDE.md/project-core, not the shared rule).
  - ✅ **`sdd close` advisory — done** (`1b8830b`, spec 179). Built full SDD pipeline; opt-in-via-Closure design (silent on corpus). Not yet pushed/synced.
  - ⏳ **Debate tiers / "always decision-grade" contradiction** — wording lives in BOTH `spec-driven.md` and `.claude/skills/sdd/SKILL.md`; needs a spec spanning both to avoid rule↔skill drift. Lower urgency (18% debate adoption).
  - ❌ Rejected (rule-of-three unmet): typed inter-spec relations (`Depends-on/Blocks/...`) — watch cognixse (34 specs) as the likely first place this earns its keep.
- None in flight as code.
- Pre-existing/unrelated dirty state is still present and left untouched: `.agent0/meetings/terceiro-runtime-modelos-chineses-2026-06-08T14-18-05Z/`. Specs 173/174/175/176 remain locally shipped but not yet committed on Agent0 (separate from the 177 commit, which staged explicit paths only).

## Next Actions

- **Push Agent0 `main`** — `d6da13c` + `650b5b5` + `2cf05bb` (pushed earlier) and now `1b8830b` (spec 179) + the handoff commit are local; push when ready (179 not yet on origin).
- **Sync the remaining consumers when desired** (deferred this session by choice; the active 3 are done): ag-antecipa / tmux-sentinel / tese are `--check`-clean (visual-contract.md is a new additive file for them). **codexeng needs a separate, deliberate migration** — it is on the old `.claude/` rule layout; a sync would copy `.agent0/context/rules/*` AND delete old `.claude/rules/*` (structural, broader than this wave). Do not bundle it.
- **Best remaining SDD-flow work:** draft the `sdd close` advisory spec (`/sdd new`).
- If/when ready, commit the still-uncommitted 173–176 project-core/bootstrap work on Agent0 (it was deliberately excluded from the 177 commit) and sync that wave to consumers.
- Optionally adopt the `**Verify:**` convention in future specs (it is opt-in; declare a command in `tasks.md` to get re-verification + the advisory).
- For other consumers (`codexeng`, `tmux-sentinel`, `ag-antecipa`, `tese`), sync one by one when desired.

## Decisions & Gotchas

- **The SDD-flow debate's core insight: the bottleneck is the front door, not the internal machinery.** Volume (~4 specs/day) is the root cause behind status-as-changelog, notes ceremony, and weak inter-spec links. The closure cluster treats symptoms cheaply; the admission threshold treats the cause but is a doctrine change. Codex's full critique is preserved at `.agent0/.runtime-state/codex-exec/sdd-debate-out.md` (debate prompt at `/tmp/sdd-debate-prompt.md`). Where Claude diverged from Codex: rejected his 4 typed inter-spec fields as itself mild overengineering (rule-of-three unmet); reframed `**Verify:**` as a watch-item not a defect (shipped same day → zero adoption is expected).
- **`**Closure:**` is additive and optional — existing 166 specs need NO migration.** New specs adopt it; the enum expansion just documents terminal states (`abandoned/deferred/shipped-partial`) the corpus already used informally inside the `**Status:**` line.
- **spec-verify adopted the `repository-harness` *pattern*, not its substrate.** The studied project stores `last_verified_result` in a gitignored SQLite `harness.db` driven by a Rust CLI; Agent0 deliberately rejected that (markdown+hooks center of gravity) and persists the proof as a `## Verification log` block in `notes.md`. Same rejection applies to its intake-lane / trace-ledger / backlog ideas — out of scope for 177. Both Claude and Codex independently ranked verify-command as the #1 fit and flagged the SQLite substrate as a mistake to import.
- **The 177 commit staged explicit paths only** (not `-A`) so the pending 173–176 work and the meeting dir stayed out. Do the same when committing the rest.
- Project-core language/locale is static always-on framing in `.agent0/project-core.md`; do not re-enable `UserPromptSubmit` for this.
- `sync-harness.sh` strips Agent0's own `AGENT0:PROJECT` region from entrypoint copies so Agent0 language settings do not leak into consumers without source.
- `project-core-sync.sh` is local derived-output maintenance; no `--agent0-path` just to refresh mirrors after a consumer source edit.
- Project-core bootstrap and template-review advisories are temporary cleanup signals, not permanent nags.
- CognixSE keeps a template-review advisory until its project-core source is reviewed and marker `2026-06-08-1` is copied. Acmeyard has already copied the marker and should have no project-core advisory.
- `AGENTS.override.md` and nested `AGENTS.md` still win for Codex-local customization after the mirrored root project core.
- Real consumer `.agent0/project-core.md` is never written by sync. Only `.agent0/project-core.md.example` ships as the placeholder.
