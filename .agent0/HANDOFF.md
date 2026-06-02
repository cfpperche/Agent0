# Session handoff

Canonical runtime-neutral handoff for Agent0 sessions. Claude Code injects/nags through hooks; Codex receives the same handoff through tracked `.codex/hooks.json` after project/hook trust.

See `.agent0/context/rules/session-handoff.md` for the protocol, 4 KB size discipline, fallback behavior, and reader-side truncation defense.

---

## Current State

**Session 2026-06-02 (status/doctor) — specs 137 + 139 SHIPPED, dogfooded cross-runtime, synced to 3 consumers; all committed + pushed.**
- **Spec 137 `agent0-status` (`8bad634`):** on-demand text-first cockpit — `status.sh` (work state, reuses the startup-brief composition via extracted `_brief-compose.sh`) + `doctor.sh` (harness health, tri-state) + portable `/status` skill. The transferable kernel of `opus-domini/sentinel`, NOT a dashboard (anti-drift; see `.agent0/context/rules/agent0-status.md`).
- **Spec 139 `status-doctor-reconciliation` (`37e67ad`):** the judgment layer a 137 dogfood asked for — `status` flags handoff↔git contradictions (RESUME WARNING) + infers in-flight spec from dirty paths; `doctor` jq-validates the SessionStart→startup-brief contract (present-but-unwired → `broken`). 34/34 tests; brief byte-identical.
- **Consumer harness sync:** mei-saas (`8060afc`), cognixse (`a5bca6c`), tese (`f83a97e`) — clean 3-way (all `~ stale`, zero customizations touched), pushed.

_Concurrent /meeting session (committed, leave it): spec 136 `/meeting` shipped; spec 138 autopilot shelved (rule-of-three) — only the `friction` measurement shipped. Prior: spec 135 OD `--check`/`--apply` fixes._

## Active Work

None. Working tree clean; everything committed + pushed to `origin/main`.

## Next Actions

**status/doctor (specs 137/139) — nothing pending.** Shipped + validated + dogfooded. The 5 LOW dogfood residuals (substring-in-SessionStart, slug truncation, SIGPIPE, JSON-misattribution, first-bullet idle) are recorded as accepted known-limitations in `docs/specs/139-*/notes.md` — deferred by rule-of-three, do NOT build without demand.

**Meeting (spec 138 — shelved):**
- **Spec 138 reopens on evidence, not now.** The autopilot build is shelved behind a demand test: 3 meetings where `meeting.sh friction` shows **≥4 consecutive model turns** + an explicit human "continue unattended" note. Until then only the measurement exists. Don't build it speculatively.

**Founder-gated (prior session, still pending):**
- **OD pin advance** — whether to ingest+commit upstream HEAD content (648 new / 83 updated systems). Validator no longer blocks; deliberate `/product` visual change, out of spec 135 scope.
- **OD-vendor extraction** (`r-2026-06-01`, snoozed → 07-01) — debate w/ Codex on moving OD out of `/product`.

**Dormant reminders (real triggers, not cancel-worthy):**
- `r-2026-05-17` re-snapshot agentskills.io — quarterly, due 08-17.
- `r-2026-05-31` umbrella-execution driver for `/sdd` — deferred by rule-of-three (n=1); reopen as a spec when a 2nd founder stalls.

## Decisions & Gotchas

- **Skill/capacity homes:** edit canonical `.agent0/skills/<slug>/` only (`.claude/skills`+`.agents/skills` are symlinks). status/doctor composition lives once in `.agent0/hooks/_brief-compose.sh` (emit-neutral) — brief truncates+emits, `status.sh` prints full; any edit there → re-verify the brief is byte-identical. Both tools honor `AGENT0_PROJECT_DIR`, locate the lib relative to their own path.
- **Meeting portability:** skill is `agentskills-portable` — core loop free of Claude-only primitives (human gate degrades `AskUserQuestion`→prose). Transcripts git-tracked but project-local under `.agent0/meetings/` (out of sync manifest; only `.gitkeep` ships).
- **Harness sync:** all 3 consumers reconciled clean 3-way (`~ stale` auto-update, zero `!! customized`). Baseline bump = the audit record.
- **Env:** gitleaks pre-commit active; governance blocks `rm -rf`/`git clean -fd`/blanket `git add`; secrets-preflight wants separate `git add` then `git commit -F <file>` (not `-F -`); commits user-gated.
