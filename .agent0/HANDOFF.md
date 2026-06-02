# Session handoff

Canonical runtime-neutral handoff for Agent0 sessions. Claude Code injects/nags through hooks; Codex receives the same handoff through tracked `.codex/hooks.json` after project/hook trust.

See `.agent0/context/rules/session-handoff.md` for the protocol, 4 KB size discipline, fallback behavior, and reader-side truncation defense.

---

## Current State

**Session 2026-06-02 (/meeting fluidity) — spec 140 `meeting-context-driven-speaker-selection` IMPLEMENTED + VALIDATED, NOT committed.**
- Replaced `/meeting`'s mandatory round-robin with a context-driven **`Next: <id>` addressing marker** (exact-shape last line, never NLP). `next_speaker` → derived/reported default; `check` → roster-membership-only; new `resolve-speaker` (precedence `--speaker` > `Next:` > `next_speaker` > first `rotation` model > convener, all roster-validated). `rotation` kept as *fallback order*. Turn shape loosened. Both invariants kept: single-writer + one-turn-per-invocation; autonomy stays gated spec-138 v2 (untouched, per user).
- Full SDD cycle: `debate.md` converged in 2 rounds (Codex's `Next:` idea dissolved the parse-vs-derive false choice). Suite **8/8 files, 76 assertions, 0 fail** (TDD; `02`/`03` rewritten, `08` added). Backward-compat verified on legacy transcript; e2e dogfood passes.

**Concurrent OD thread (this session, COMMITTED):** `/product` OD vendor pin advanced `d25a7aaf`→`c128ffd5` (`5233ab3`) — 73→**150** design systems, validated, `od-catalog-index.json` regenerated so the pipeline sees them. Two OD-sync engine bugs found → **spec 141 drafted** (`51e92ae`).

_Prior session (committed, leave it): specs 137+139 status/doctor SHIPPED + synced to 3 consumers; spec 136 `/meeting` shipped; spec 138 shelved._

## Active Work

**Spec 140 done, UNCOMMITTED** (tree dirty — see git below). Open offer: commit (on a branch).
- **AG-Antecipa transcript:** removed deliberately by a **parallel session at the user's request** (NOT codex-exec — my earlier causal guess was wrong). This session wrongly "restored" it, then re-removed it on user confirmation. Now absent, as intended. `.agent0/meetings/` holds only `v2-meeting-llm-orchestrator-mode-*`.

## Next Actions

**Spec 140 — commit when user asks.** New: `08-addressing-marker.sh`, `docs/specs/140-*/`, restored `.agent0/meetings/investigacao-empresa-agantecipa-*/`. Modified: `meeting.sh`, `SKILL.md`, `turn-prompt.md`, `meeting.md.tmpl`, rule `meeting.md`, tests `02/03/04/run-all`. Deferred: cosmetic `rotation`→`fallback_order` rename (own change).

**Spec 138 (shelved):** autopilot reopens only on demand test — 3 meetings with `friction` ≥4 consecutive model turns + explicit "continue unattended". Measurement only until then.

**OD thread — user-sequenced plan (DO IN ORDER):**
1. **Implement spec 141** (`od-sync-apply-completeness`, draft) — fix the 2 engine bugs: idempotence no-ops a `--bump` (compares on-disk vs stale manifest, skips recursive trees → can't trigger reconcile); `--apply` regenerates only `.cache/ds-index.json`, NOT the pipeline-facing `references/od-catalog-index.json`. `/sdd plan` from the spec; `/tmp/gen-catalog.py` is the regen reference impl.
2. **THEN re-sync the 3 consumers** (mei-saas/cognixse/tese) — they're behind on `/product` after the OD advance (+~115k lines / 150 systems each). Order matters: fixed engine ships with the content.
- **OD-vendor extraction** (`r-2026-06-01`, snoozed → 07-01) — Codex debate on moving OD out of `/product`. Distinct from 141.

**Dormant reminder:**
- `r-2026-05-17` re-snapshot agentskills.io — quarterly, due 08-17. _(r-2026-05-31 umbrella-driver: dismissed + committed `1db1bc5`.)_

## Decisions & Gotchas

- **Skill/capacity homes:** edit canonical `.agent0/skills/<slug>/` only (`.claude/skills`+`.agents/skills` are symlinks). status/doctor composition lives once in `.agent0/hooks/_brief-compose.sh` (emit-neutral) — brief truncates+emits, `status.sh` prints full; any edit there → re-verify the brief is byte-identical. Both tools honor `AGENT0_PROJECT_DIR`, locate the lib relative to their own path.
- **Meeting portability:** skill is `agentskills-portable` — core loop free of Claude-only primitives (human gate degrades `AskUserQuestion`→prose). Transcripts git-tracked but project-local under `.agent0/meetings/` (out of sync manifest; only `.gitkeep` ships).
- **Meeting speaker selection (spec 140):** context-driven via `Next: <id>` exact-shape marker (last non-empty line; never NLP). `meeting.sh check` is roster-membership-only now; `resolve-speaker` owns the precedence; `advance --next <id>` sets `next_speaker` (no more `csv_successor`). 140↔138 boundary: deterministic transcript directive = in scope; semantic speaker inference / auto-chain = still gated behind 138's demand test.
- **`codex-exec` sandbox:** `--sandbox workspace-write` grants repo-wide write — still worth scoping tightly, but NOTE: the AG-Antecipa transcript loss this session was NOT caused by codex-exec (a parallel session removed it at the user's request). Don't carry that as a codex-exec lesson.
- **OD pin advance (specs 135/141):** the engine has 2 bugs (spec 141) — `--bump`+`--apply` no-ops (perturb a non-recursive vendored file to force the reconcile), and `--apply` regenerates only the engine cache, not the pipeline catalogue (`od-catalog-index.json`; regen via `/tmp/gen-catalog.py` logic: preserve curated entries, mechanical for new). Fix 141 before the next advance.
- **Harness sync:** all 3 consumers reconciled clean 3-way (`~ stale` auto-update, zero `!! customized`). Baseline bump = the audit record. NOTE: consumers now behind on `/product` (OD 150 systems) — resync after 141.
- **Env:** gitleaks pre-commit active; governance blocks `rm -rf`/`git clean -fd`/blanket `git add`; secrets-preflight wants separate `git add` then `git commit -F <file>` (not `-F -`); commits user-gated.
