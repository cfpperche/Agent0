# Session handoff

Canonical runtime-neutral handoff for Agent0 sessions.

See `.agent0/context/rules/session-handoff.md` for the protocol.

---

## Current State

- **Rule-corpus cleanup executed + synced to all 3 consumers (Claude, Fable 5, 2026-06-10).** Agent0 pass: (1) register-split of the 4 largest rules — operative text stays, design memory moved verbatim to `.agent0/memory/{harness-sync,delegation,memory-placement,secrets-scan}-maintenance.md` (one-directional linkage, no memory pointers in rules); (2) citation sweep across ALL shipped rules: ~70 spec-number/docs-path/memory-pointer leaks removed, facts kept. Corpus 417→384 KB; global leak grep returns zero; 44/44 suites + drift + doctor 25 ok + harness-tests CI green. **Consumer sync DONE + PUSHED, one at a time, each user-approved, each audited:** mei-saas `4e81afd` (doctor 24 ok / 1 advisory = pre-existing project-core review), acmeyard `d903c91` (25 ok / 0), cognixse `19c8447` (25 ok / 0). Each: 52 files (15 copied, 34 updated, 2 removed), **0 customized-refused / 0 overwritten**, the 2 relocated governance rules auto-deleted, zero citation leaks downstream, P8 `shipped integrity` debuted in the field (53 executables verified vs baseline per consumer).
- **CORRECTION to record — managed-block sync is NOT append-only.** Prior handoff/memory claimed the CLAUDE.md managed-block merge "adds sections, never removes" → manual deletion of the stale `## Agent0 governance doctrine` section would be needed per consumer. **False:** the region between `AGENT0:BEGIN`/`AGENT0:END` is replaced *wholesale* each sync (consumer's own CLAUDE.md documents this), so the section auto-removed cleanly in all 3, markers intact. **No manual cleanup was needed anywhere.** The relocated rule files are whole-file synced → also auto-deleted (not manual). Update `propagation-hygiene` memory's "append-only / known limitation" paragraph if it still claims otherwise.
- **Spec 185 (`harness-evolution-program`) shipped + closed (Claude, Fable 5, 2026-06-09→10).** The 8-point external harness review ran one detailing round per point; all dispositioned: **executed** P4 (rule-corpus discipline adopted: audience test "consumer-facing → rule, else memory or gate"; 3 rules relocated to memory, corpus 39→36, one sync special-case deleted), P7 (CI: `.agent0/tests/run-all-suites.sh` + `.github/workflows/harness-tests.yml`, green in ~3min — first runs caught 4 real defects: stale test, rg dependency, missing skip-guard, SC2034), P8 (doctor `shipped integrity` section verifying executable shipped surface vs sync baseline, advisory-only, suite 5/5); **decided** P2 (Agent0 = personal lab + public showcase; no adoption machinery; reopen on first external interest); **killed** P5 (hook chains measured 7ms/46ms — non-problem), P6 (bash kernel rewrite buys nothing for the operator); **deferred** P1 (evidence bundle — no users yet; ephemerality finding + reopen triggers recorded), P3 (multi-runtime parity stands; Codex re-tier analysis preserved). Full record: docs/specs/185-harness-evolution-program/{tasks,notes}.md.
- **⚡ Tachyon GRADUATED to its own public repo (2026-06-10) and was removed from Agent0.** Incubated here as `packages/tachyon/` across specs 186–204 (v1 + F1/F2/F3/F4/F12/F13/F14/F15/F16/F17/F18/F19/F20/F21/F9; F22 split-panels shipped then hidden behind a feature flag). Split out with **full git history** (`packages/tachyon/` → repo root + `docs/specs/186–204`) via `git filter-repo` into **[github.com/cfpperche/tachyon](https://github.com/cfpperche/tachyon)** (public, MIT, CI green = typecheck+build+188 unit, GitHub Pages live at cfpperche.github.io/tachyon, last shipped 0.4.6). The package, its 19 specs, and the `.vscode/launch.json|tasks.json` dev configs were then deleted from Agent0 (tracked files git-rm'd; Agent0's git LOG still retains all the work). Dogfood lives outside both repos at `~/tachyon-demo*`. **Agent0 no longer hosts any product code — it is purely the governance/harness template again.**
  - Known follow-up for the Tachyon repo (not Agent0's concern): one-shot command exit-code capture is tmux-version-sensitive (3.4 leaves `pane_dead_status` empty for instant-exit panes; 3.6 populates it) — bump documented min tmux to 3.6 or harden CommandRunner. The xvfb integration suite is a local gate there, not in CI.

## Active Work

- None in flight.

## Next Actions

- **CI is live:** every push touching harness paths runs all 44 suites (`harness-tests` workflow). If it goes red, fix before continuing — that's the operator-quality bar the maintainer set.
- **Consumer sync — DONE (mei-saas `4e81afd`, acmeyard `d903c91`, cognixse `19c8447`, all on origin/main).** No follow-up; no manual cleanup was required.
- ~~Audit item 2~~ **DECIDED 2026-06-10:** spec 171 closed as abandoned — the index + on-demand-read context model (no prompt-time injection) is the declared-final design; pause language removed from runtime-capabilities/harness-sync/startup-brief; reopen trigger = a second silent-substitution incident.

## Decisions & Gotchas

- The secrets-preflight hook blocks compound `git add … && git commit …` — stage and commit in separate Bash invocations.
- **Agent0 is a portable governance/evidence harness, not a product host.** Tachyon's graduation (2026-06-10) restored that: `packages/` is gone; if a future product is incubated here it follows the same arc — built in `packages/<name>/`, never touching `.agent0/`/`.claude/`, then split out with `git filter-repo` when it earns its own repo.
