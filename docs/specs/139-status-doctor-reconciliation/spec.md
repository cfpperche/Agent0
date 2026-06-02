# 139 — status-doctor-reconciliation

_Created 2026-06-02._

**Status:** shipped

## Intent

Close the two high-severity findings a cross-runtime dogfood of spec 137 surfaced: `status` and `doctor` do *inventory* well but *judgment* poorly. `status.sh` concatenates the hand-written handoff and live git state but never **reconciles** them — so it will print "Active Work: None / working tree clean" directly above a `git` block showing a dirty tree, lying about the one thing a resume surface must get right (the *now*). `doctor.sh`'s hook-wiring check is a bare `grep -q "startup-brief"` that passes on a comment, a disabled block, the wrong event, or malformed JSON, and is structurally **only ever `advisory`** — so the gate cannot fail on its headline claim ("the harness is wired"). Both findings were flagged independently by Claude Code and Codex CLI (high agreement → high confidence). This spec adds the missing judgment layer: a handoff↔git reconciliation banner + in-flight-spec inference in `status`, and jq-based hook-contract validation with a real `broken` tier in `doctor`. Scope stays inside the spec-137 anti-drift envelope — still text-first, stateless, no daemon/browser/new store.

## Acceptance criteria

- [x] **Scenario: `status` flags a handoff/git contradiction**
  - **Given** `.agent0/HANDOFF.md` whose Active Work says "None" / "working tree clean" (or is older than the newest tracked change) while `git status` is non-empty
  - **When** `bash .agent0/tools/status.sh` runs
  - **Then** it emits a prominent reconciliation banner near the top (e.g. `⚠ RESUME WARNING: handoff says clean/idle but the working tree has N uncommitted change(s) — handoff may be stale`), and still exits 0

- [x] **Scenario: no false alarm when handoff and tree agree**
  - **Given** a clean working tree, or a handoff whose Active Work already describes uncommitted work
  - **When** `status.sh` runs
  - **Then** no reconciliation warning is emitted (the banner is contradiction-only, not always-on)

- [x] **Scenario: `status` infers probable in-flight work from the tree**
  - **Given** untracked or modified paths under `docs/specs/NNN-<slug>/` (and/or matching tool/skill files)
  - **When** `status.sh` runs
  - **Then** it surfaces a one-line "probable active work: NNN-<slug>" hint derived from the dirty paths, so in-flight work has a narrative beyond raw `git status` porcelain

- [x] **Scenario: `doctor` validates the hook contract, not a substring**
  - **Given** `.claude/settings.json` / `.codex/hooks.json`
  - **When** `doctor.sh` runs its hook-wiring check
  - **Then** it parses the JSON (jq) and asserts a `SessionStart` (or runtime-equivalent) hook whose command path references an existing, executable `.agent0/hooks/startup-brief.sh` — a present-but-malformed/unbound config does NOT report `ok`

- [x] **Scenario: `doctor` can fail on an unwired harness**
  - **Given** a runtime config that exists but binds no startup hook (the headline "is it wired?" failure mode)
  - **When** `doctor.sh` runs
  - **Then** that is reported `broken` (exit non-zero) for the target runtime — not merely `advisory`. A `--runtime claude|codex|both` selector (or sensible auto-detect) governs which runtime's wiring is gate-failing vs informational

- [x] Reconciliation and validation stay text-first and stateless — no new persisted state, daemon, or browser surface (inherits spec 137 § Non-goals)
- [x] All new behavior covered by tests under `.agent0/tests/agent0-status/`; the spec-137 suite stays green

## Non-goals

- Re-opening any spec-137 Non-goal (browser/daemon/metrics/history store) — this is a judgment layer on the existing text tools, nothing more
- Auto-editing the handoff to "fix" the contradiction — `status` *flags*, the human reconciles (status stays read-only)
- `doctor` auto-remediation of unwired hooks — still reports + proposes, never fixes
- Proving the hook *actually fired at runtime* (static contract validation only; live/trust-state evidence is a possible later increment, explicitly deferred)
- A general handoff-staleness engine — the reconciliation is the narrow git-vs-handoff check, not a freshness framework

## Open questions

- [x] Reconciliation trigger → string-contradiction (not mtime).  pure "handoff claims clean/None + git dirty" string-match, or a freshness signal (handoff mtime vs newest dirty-file mtime), or both? Resolve at `/sdd plan`.
- [x] doctor runtime selector → auto-detect by file presence, no --runtime flag in v1.  explicit `--runtime` flag, auto-detect from which config files exist, or gate-fail only when BOTH runtimes are unwired (most conservative)? Plan-time decision.
- [x] In-flight inference → local to status.sh (not the bounded brief).  belong in `status.sh` or in a small shared helper (could the brief want it too)? Plan-time.

## Context / references

- `docs/specs/137-agent0-status/` — the shipped capability this refines; the dogfood that motivated 139.
- Dogfood run artifacts (2026-06-02, read-only claude-exec + codex-exec, 6 runs): under `.agent0/.runtime-state/{claude,codex}-exec/*df-*` — `last-message.md` per run. D1 (status, both runtimes) → handoff↔git contradiction + false next-actions line (the latter already fixed in 137). D2 (doctor, both runtimes) → substring wiring check can't reach `broken`; presence≠function. D3 (parity) → multi-runtime core confirmed sound.
- `.agent0/tools/status.sh` § `next_commands_block` / `git_dirty_block` — where reconciliation + inference attach.
- `.agent0/tools/doctor.sh` § `wired_check` — the substring check to replace with jq contract validation.
- `.agent0/context/rules/agent0-status.md` — anti-drift scope this spec must stay inside.
- Already-applied spec-137 dogfood follow-ups (bucket 1 + 3, this session): next-actions suppression when handoff is "nothing actionable"; `AGENT0_SKIP_GITHOOKS_HINT` alias; `doctor` `-d` rules check + non-empty exec check. 139 covers only the two high-severity judgment gaps left.
