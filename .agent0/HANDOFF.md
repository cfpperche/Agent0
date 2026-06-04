# Session handoff

Canonical runtime-neutral handoff for Agent0 sessions. Claude Code injects/nags through hooks; Codex receives the same handoff through tracked `.codex/hooks.json` after project/hook trust.

See `.agent0/context/rules/session-handoff.md` for the protocol, 4 KB size discipline, fallback behavior, and reader-side truncation defense.

---

## Current State

**Session 2026-06-04 (squad) — spec 150.2 `/squad` content-aware fingerprint SHIPPED-LOCAL (pending push + consumer propagation).** Fast-follow fixing dogfood finding #3 (🟡): `_fingerprint` was path-level (`git status --porcelain`), so an in-place REWRITE of an already-listed path — or any file under a collapsed `?? dir/` — was invisible to the set-diff (the dogfood's Pass-2 manifestation; an in-turn forbidden rewrite could escape). Now content-aware: `-uall` (files listed individually) + a `\t<git hash-object>` per line; `.agent0/.runtime-state/` excluded so the squad's own `state.json` churn isn't a false `aborted_conflict` (also a defensive backstop for #4). New TDD regression `10-fingerprint-content-aware.sh` (red→green). **Squad suite 10/10**, shellcheck clean, no regression. All 4 dogfood findings now resolved (#1/#2 in 150.1, #3 in 150.2, #4 mooted by precondition #5 + the run-state exclusion).

_Prior this session — 149/149.1/150/150.1 propagated + committed/pushed to all 5 consumers; sync-harness baseline bug fixed; see below._

**Session 2026-06-04 (squad) — 149/149.1/150/150.1 PROPAGATED to all 5 consumers + a sync-harness bug fixed.** Ran `sync-harness.sh --apply` to ag-antecipa, cognixse, mei-saas, tese, **tmux-sentinel** (the 5 harness-bearing consumers): squad skill + 9 squad tests + 12 deliberation-bias tests + meeting.sh/SKILL/turn-prompt/templates + debate template + rules (squad/meeting/spec-driven) + CLAUDE.md managed block all landed; **baselines recorded; squad suite 9/9 green inside tese (propagated copy)**. The only `customized-refused` are OD-vendor `/product` caches (cognixse 4, mei-saas 3, tese 3) — unrelated to this propagation, correctly left alone. **Surfaced + fixed a real harness bug:** `write_baseline` passed the whole files-map to `jq` via a single `--argjson` command-line arg, which exceeds Linux `MAX_ARG_STRLEN` (~128 KB/arg) for any ~1000+ -file consumer → `execve` E2BIG → silent "failed to write baseline (jq error)" + stale baseline. (All 5 real consumers hit it; synthetic test SRCs were too small to.) Fix: `--slurpfile` from a temp file (no argv limit). New TDD regression `harness-sync/41-baseline-write-large-consumer.sh` (1600-file SRC; red→green). **harness-sync suite now 41/41.** Consumer working trees now hold the propagated harness files UNCOMMITTED (not committed per the consumer-local-work rule — see Next Actions). Agent0-side fix committed; pending push.

_Prior this session — 150.1 hardening shipped (`bcea0a1`); see below._

**Session 2026-06-04 (squad) — spec 150.1 `/squad` hardening SHIPPED-LOCAL (pending push).** Fast-follow from the live dogfood (149.1 convention: no new spec dir; recorded in `docs/specs/150-squad/notes.md` § 150.1 resolution). Both 🔴 findings fixed: **(2)** `forbidden_paths`/`human_gated_paths` now policy-checked against the turn's OWN delta — `turn-start` snapshots a pre-turn fingerprint, `turn-end` derives `changed_paths` = delta vs it (`boundary` stays the full fingerprint for out-of-turn conflict), `guard` checks `changed_paths ∪ newlines`; in-turn forbidden touch now caught (was escaping). New TDD regression `09-guard-policy-in-turn.sh` (red→green); **squad suite 9/9**. **(1)** `/squad` target-must-contain-the-harness is now an explicit SKILL precondition #5 + rule bullet + a non-fatal `init` warning when the exec bridge is absent. 🟡 #3 (path-level fingerprint) + #4 (runtime-state gitignore) deferred with rationale in notes. No regression: multi-runtime-skills, harness-sync 40/40, `/skill validate squad` clean.

_Prior this session — live `/squad` dogfood done (committed `92e1d1a`); see below._

**Session 2026-06-04 (squad) — LIVE `/squad` dogfood DONE (the real validation).** Two passes on a tiny throwaway target (`slugify`, gate `node test.js`): **Pass 1** (state-machine integration on a `/tmp` repo, orchestrator drove both turns) converged RED→repair→GREEN→`ready_for_human_prod` and the **agreement≠done invariant held LIVE** (both `propose-done` with a RED gate stayed `running`). **Pass 2** (real exec-bridge handoff, inside Agent0, throwaway spec `199-squad-dogfood` since removed): Claude opened a failing stub → **real Codex via `codex-exec --sandbox workspace-write` (34s, exit 0)** completed it touching only the sandbox file → gate GREEN → `ready_for_human_prod`. The deterministic core + the live loop both hold. **4 findings recorded in `docs/specs/150-squad/notes.md` § Live dogfood** → a **150.1 hardening pass** (2 are 🔴 load-bearing; see Next Actions + Decisions). Only uncommitted change this session: `docs/specs/150-squad/notes.md` (the dogfood evidence) — not yet committed.

_Prior this session — spec 149 shipped; see below._

**Session 2026-06-04 (squad) — spec 149 `deliberation-confirmation-bias` IMPLEMENTED + VALIDATED + SHIPPED.** `origin/main` @ `3db5138`. Etapa 1 of the `/squad` roadmap done. The de-biased deliberation protocol is now live in `meeting.sh` (shared by `/sdd debate` + decision-grade `/meeting`): **commit/reveal** blind opening (seals each independent opening under gitignored `.agent0/.runtime-state/deliberation/`, `reveal` refuses until all model speakers commit + verifies hashes), **ab-map** (randomized Proposal A/B critique view; transcript stays attributed), **ledger-add/ledger-check** convergence GATE (`assertion-only` ⇒ unresolved regardless of agreement), **check-anchors** (deterministic path/test verify; test-rerun is v2), **init --tier light|decision-grade**. Prose wired: `turn-prompt.md` (counterfactual coverage + confidence-as-routing, structural not persona), both templates (blind/ledger/minority-report), `meeting/SKILL.md` § De-biased decision-grade flow, `sdd/SKILL.md` blind Round 1, rules `meeting.md` + `spec-driven.md`. **Tests: deliberation-bias 9/9; meeting 15/15; multi-runtime-skills pass; harness-sync 40/40 — no regression.** Design notes: orchestrator-sealed (not agent-resupply); blindness is procedural+tamper-evident, not cryptographic vs an adversarial peer. **Not yet propagated to consumers.**

_Prior this session — spec 149 designed (debate) + planned; see below._

**Session 2026-06-04 (squad) — spec 149 design/plan (superseded by the implementation above).** `origin/main` @ `4bfaa1e`. This is **Etapa 1 of a 2-etapa roadmap toward `/squad`** (autonomous multi-agent build loop): before building a squad whose done-condition leans on agent agreement, harden the deliberation primitives so "the agents converged" is trustworthy. Resolved (via a web-backed Claude↔Codex `/sdd debate` that dogfooded its own subject — Codex gave an independent source-first ranking *before* seeing my list and materially diverged): a 4-stage de-biased protocol — **(1) commit/reveal blind opening (`sha256+nonce`, not separate files); (2) randomized Proposal-A/B critique (judgment-surface anonymization; audit stays attributed); (3) claim/evidence convergence GATE (4 tags; `assertion-only` ≠ resolved; deterministic anchor check where feasible); (4) rubric-over-ledger synthesis + preserved minority report** + counterfactual-candidate-coverage & confidence-as-routing turn schema; heterogeneous models required; `/meeting` light-tier vs decision-grade tier. **Architectural call (founder-ratified): unify the mechanics as shared `meeting.sh` subcommands; `/sdd debate` calls the same script (one tested impl, not two).** 11 ordered tasks in `tasks.md`. **Etapa 2 = `/squad`** (renamed from `/pair`), gated on Etapa 1 landing.

_Prior 2026-06-04 — spec 148 `publish-boundary-closeout-check` closed._

**Session 2026-06-04 — spec 148 `publish-boundary-closeout-check` closed.** The handoff-discipline meeting converged on a hook-backed fix for the recurring "section done but HANDOFF stale" failure. `SessionStart` now records `start-head`; `SessionStop` now has a clean publish-boundary branch: when session commits are pushed and the latest session commit does not touch `.agent0/HANDOFF.md`, it nags once to force a final handoff re-read/update.

Validation passed: `bash .agent0/tests/session-handoff/run-all.sh` (11/11), `bash .agent0/tests/session-handoff-multi-runtime/run-all.sh` (6/6), `bash .agent0/tests/harness-sync/run-all.sh` (40/40), `bash -n .agent0/hooks/session-start.sh .agent0/hooks/session-stop.sh .agent0/tests/session-handoff/11-publish-boundary-closeout.sh`, and `git diff --check`.

**Session 2026-06-04 — Codex `/video` skill-loader warning fixed locally.** Meeting investigation traced the startup warning to `.agent0/skills/video/SKILL.md` frontmatter: unquoted `argument-hint` contained `code: scaffold`, which strict YAML parses as invalid at column 46. The value is now quoted, and `/skill` validation rejects invalid YAML frontmatter before field extraction.

Validation passed: `bash -n .agent0/skills/skill/scripts/validate.sh`; `/skill` fixtures 9/9 including `invalid-yaml-colon-space`; `validate.sh` over every `.agent0/skills/*` skill (only existing body-size warning for `/skill`); PyYAML parse over every skill frontmatter; multi-runtime-skills 9/9; video tests 4 pass / 1 integration skip; `git diff --check` clean.

## Active Work

- **Spec 150 `/squad` (Etapa 2) — IMPLEMENTED + VALIDATED + SHIPPED** (`origin/main` @ `36b8537`). Deterministic state machine `.agent0/skills/squad/scripts/squad.sh` (init/turn-start/turn-end/propose-done/gate/guard/rollback/status/abort) + `/squad` SKILL (pump loop, symmetric, `--mode assisted`) + `squad.json` gate contract + rule `squad.md` + CLAUDE.md index. **Tests squad 8/8** incl. the load-bearing **agreement≠done** invariant (gate red + both proposed → stays `running`); no regression (meeting 15/15, deliberation-bias 11/11, harness-sync 40/40). Spec 138's autonomous-loop concern marked superseded. **Live dogfood DONE this session** (see Current State; findings in `docs/specs/150-squad/notes.md`) → **150.1 hardening** is the fast-follow. Consumer propagation still pending.
- **Spec 149.1 — SHIPPED** (`94ebf47`): debate.md gained meeting.sh-compatible front-matter (the 149 mechanics now run on `/sdd debate`, not only `/meeting`); ledger sanitizes `|`. Tests deliberation-bias 11/11.
- **Spec 149 (Etapa 1) — shipped** (`3db5138`).

- **(superseded entry below) Spec 150 design/plan — now implemented above.** The v1 cut was resolved in a decision-grade `/meeting` that **dogfooded spec 149's blind/ledger flow** (first real use): Claude & Codex committed openings BLIND (hashes verified) and **converged independently** on the spine; ledger 8 claims / 0 assertion-only → green. Resolved v1: full autonomous pump on one pre-planned spec; new `squad.sh` + run-dir; pump-enforced terminal states (agreement only "proposes done"); turn-locked single-writer + per-turn diff snapshot/rollback (worktree=v2); done-gate = `docs/specs/NNN/squad.yaml` executable contract; supersedes 138's autonomous-loop concern; hard round/token/spend ceilings. Transcript: `.agent0/meetings/squad-v1-design-2026-06-04T17-48-21Z/`.
- **Spec 149 (Etapa 1) — implemented + validated + shipped** (`3db5138`).
- **Spec 149.1 fast-follows (from the 150 dogfood, not blockers):** (a) `/sdd debate`'s `debate.md` has no YAML front-matter, so `meeting.sh commit/reveal/ledger` can't run on it literally — needs a front-matter shim or sidecar transcript for `/sdd debate` to invoke the 149 mechanics (the dogfood used a `/meeting` transcript, which is meeting.sh-native); (b) a ledger claim containing a literal `|` corrupts `check-anchors`' markdown-table parse (gate still passed).

## Next Actions

**Optional — propagate spec 149 to the 4 consumers** (cognixse, mei-saas, tese, ag-antecipa). Changed files are all tracked under `.agent0/` (meeting.sh, templates, turn-prompt, SKILLs, rules) + the new test suite → a `sync-harness.sh --apply` carries them cleanly (the `/sdd debate` + `/meeting` skills are harness-managed). Not urgent; can ride the next routine consumer sync.

**✓ DONE — Agent0 commits pushed** (150.1 `bcea0a1` + sync-harness baseline fix `bd707e7`).

**✓ DONE — propagated harness committed + pushed in all 5 consumers** (allowlist-staged harness paths only; anti-leak assert kept product/spec work out): ag-antecipa `bdc2cfd`, cognixse `7add64d`, mei-saas `037ded0`, tese `da5f56e`, tmux-sentinel `611b159` — each pushed to its `origin/main`. Consumer-own uncommitted work left untouched (ag-antecipa/mei-saas brand PNGs, tese `uv.lock`). OD-vendor `customized-refused` caches intentionally not synced.

**Optional next — a real-spec `/squad` dogfood** — now that the 2 🔴 are fixed, run `/squad` on a small REAL already-`/sdd plan`-ned spec (inside Agent0 or a synced consumer, per precondition #5) to test convergence/cost/drift on non-toy work. The toy dogfood proved mechanics; this would be the first real-work run.

**Optional — 🟡 deferred 150.x:** #3 content-level fingerprint (hash blobs, not just porcelain paths) so a rewrite of an already-listed file isn't invisible to `guard`. Low urgency (bounded risk).

**Optional — propagate 149 + 149.1 + 150 + 150.1 to the 4 consumers** — all tracked `.agent0/` files → a `sync-harness.sh --apply` carries them; rides the next routine sync.

_Live `/squad` dogfood + 150.1 hardening (the prior Next Actions) are DONE — see Current State._

**Optional — propagate 149 + 149.1 + 150 to the 4 consumers** — all tracked `.agent0/` files (meeting.sh, squad skill, rules, tests) → a `sync-harness.sh --apply` carries them; rides the next routine sync.

## Decisions & Gotchas

- **`/squad` dogfood findings (2026-06-04):** (1) 🔴 `codex-exec`/`claude-exec` anchor `ROOT` to the Agent0 root (`$SCRIPT_DIR/../../../..`) and refuse `--cwd` outside it → `/squad` can only target a harness-containing repo; (2) 🔴 `forbidden_paths`/conflict only catch OUT-OF-TURN changes (turn-end folds the turn's diff into boundary before guard) — in-turn forbidden touch escapes; (3) 🟡 fingerprint is path-level not content-level (rewriting an already-`?? `-listed file is invisible to guard); (4) 🟡 target must gitignore `.agent0/.runtime-state/` (Agent0/consumers already do). Full writeup: `docs/specs/150-squad/notes.md` § Live dogfood.
- `assets/generated/.manifest.jsonl` is now local audit state, not durable project history.
- Do not add the manifest to `sync-harness.sh` copy lists; that would risk copying Agent0 prompt/cost history into consumers.
- `/video` policy is unchanged: `.video-manifest.jsonl` remains governed by `.agent0/context/rules/video-gen.md`.
- `argument-hint:` is still a top-level skill frontmatter field; values containing `: ` must be quoted or block-styled.
- Spec 148 intentionally does not parse handoff prose; the mechanical proof is that the latest pushed session commit touches `.agent0/HANDOFF.md`.
- Root `AGENTS.md` and `CLAUDE.md` are Agent0-managed entrypoints; consumer-local Codex guidance still belongs in `AGENTS.override.md` or nested `AGENTS.md`.
