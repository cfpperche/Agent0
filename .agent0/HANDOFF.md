# Session handoff

Canonical runtime-neutral handoff for Agent0 sessions. Claude Code injects/nags through hooks; Codex receives the same handoff through tracked `.codex/hooks.json` after project/hook trust.

See `.agent0/context/rules/session-handoff.md` for the protocol, 4 KB size discipline, fallback behavior, and reader-side truncation defense.

---

## Current State

**Session 2026-06-02 — `/meeting` skill SHIPPED + dogfooded, all committed + pushed (HEAD `0d9c2ee`).** New multi-party, multi-model deliberation skill.
- **Spec 136 (`22dde79`):** `/meeting` — human + Claude + Codex take turns on a free topic; state/content split (`meeting.sh` owns a machine-readable header; the active runtime is single-writer); peer turns via `codex-exec`/`claude-exec`. 59 tests.
- **Runtime-neutral fix (`b416f4b`):** the synthesis human gate degraded `AskUserQuestion`→plain prose; retiered cc-native → **agentskills-portable** (any runtime can orchestrate).
- **Dogfood + graduation (`47e5cbb`):** first real `/meeting` (Claude⇄Codex) on "should v2 add an LLM-orchestrator mode" → graduated to **spec 138 (meeting-bounded-autopilot)**; its `/sdd debate` (Codex) **shelved** the build behind a rule-of-three demand test.
- **Near-term measurement (`6ccfddf`):** `meeting.sh friction` + `state` lines record max consecutive model-turns-without-human; the only piece of 138 that shipped.
- **Housekeeping (`0d9c2ee`):** gitignore `.claude/*.lock` (CC `/schedule` per-process lock).

_Prior session (OD vendor-sync, shipped+pushed): spec 135 OD `--check`/`--apply` bug fixes (GitHub 300-file compare cap → over-report; `DESIGN.md` validator became a substance gate); canvas-contrast rule; reminder triage 5→2. Specs 137 `agent0-status` / 139 are a separate concurrent session's — shipped, leave them._

## Active Work

None. Working tree clean; everything committed + pushed to `origin/main`.

## Next Actions

**Meeting (this session):**
- **Spec 138 reopens on evidence, not now.** The autopilot build is shelved behind a demand test: 3 meetings where `meeting.sh friction` shows **≥4 consecutive model turns** + an explicit human "continue unattended" note. Until then only the measurement exists. Don't build it speculatively.

**Founder-gated (prior session, still pending):**
- **OD pin advance** — whether to ingest+commit upstream HEAD content (648 new / 83 updated systems). Validator no longer blocks; deliberate `/product` visual change, out of spec 135 scope.
- **OD-vendor extraction** (`r-2026-06-01`, snoozed → 07-01) — debate w/ Codex on moving OD out of `/product`.

**Dormant reminders (real triggers, not cancel-worthy):**
- `r-2026-05-17` re-snapshot agentskills.io — quarterly, due 08-17.
- `r-2026-05-31` umbrella-execution driver for `/sdd` — deferred by rule-of-three (n=1); reopen as a spec when a 2nd founder stalls.

## Decisions & Gotchas

- **Meeting homes/portability:** skill is `agentskills-portable` — keep the core loop free of Claude-only primitives (the human gate degrades `AskUserQuestion`→prose). Transcripts are git-tracked but **project-local** under `.agent0/meetings/` (excluded from the sync-harness manifest like `memory`/`routines`; only `.gitkeep` ships).
- **Skill homes:** edit canonical `.agent0/skills/<slug>/` only (`.claude/skills`+`.agents/skills` are symlinks).
- **OD gotchas (spec 135, if you touch OD):** GitHub `gh api .../compare` truncates `.files[]` at 300 (no real pagination) → drift detectors must over-report, never conclude "no changes". `DESIGN.md` validator is a substance gate (≥2 hex + ≥3 H2), NOT heading names. Full write-path dogfood needs perturbing a vendored file (idempotence guard short-circuits otherwise).
- **Env:** gitleaks pre-commit active; governance blocks `rm -rf`/`git clean -fd`/blanket `git add`; secrets-preflight blocks compound `git add && git commit` (separate calls); commits user-gated.
