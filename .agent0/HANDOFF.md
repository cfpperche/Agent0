# Session handoff

Canonical runtime-neutral handoff for Agent0 sessions. Claude Code injects/nags through hooks; Codex receives the same handoff through tracked `.codex/hooks.json` after project/hook trust.

See `.agent0/context/rules/session-handoff.md` for the protocol, 4 KB size discipline, fallback behavior, and reader-side truncation defense.

---

## Current State

**Session 2026-06-03 — spec 144 `sync-harness-gitignore-aware-walk` COMMITTED on branch `144-sync-harness-gitignore-aware-walk` (`2f90538`); not yet pushed/merged.** Fixed the harness layer of the same bug-class as 141/142: `sync-harness.sh`'s `find`-based walk did not respect `.gitignore`, so it over-propagated the OD-engine's gitignored `runtime/od-sync/extracted-<sha>/` cache (measured: 6470 walked under `.claude/skills/product`, 5158 of them cache). Now the two `find` expansions (`COPY_CHECK_RECURSIVE`+`COPY_CHECK_GLOBS`) filter to `git ls-files` ("managed = tracked"); non-git sources fall back to a guarded `find` (static `*/runtime/od-sync/extracted-*` exclude + advisory, never blind); dirty-source advisory; cache-orphan deletions summarized. Full SDD ran incl. a Claude↔Codex `/sdd debate` (2 rounds, converged) that resolved A-vs-B → **Model A ownership-clarified**. **40/40 harness-sync tests pass** (added 39, 40); live `--check` against `tese`: 0 cache lines, 747 vendor still travel, 6470→1311. Files: `.agent0/tools/sync-harness.sh`, `.agent0/tests/harness-sync/{39,40}*`+`run-all.sh`, `.agent0/context/rules/harness-sync.md` § Manifest scope, `docs/specs/144-*`.

_Prior — **Session 2026-06-02 — OD-engine chain (141 → 143 → 142) SHIPPED + propagated to all 4 consumers.** `--verify` green (7/7) on Agent0 + every consumer; bundles 111 design-templates each._
- **141 `od-sync-apply-completeness`** — content-true idempotence (fast-path `pinnedContentAlreadyApplied` + post-stage slow-path; deleted the stale-manifest compare + recursive blind-skip), catalogue regen (`generateCatalogIndex` + `--gen-catalog`), stale-count advisory (`scanStaleCounts`). On `origin/main` (`1bc7223`).
- **143 `od-vendor-skills-remap`** — re-pointed the skill-bundle vendored-path `src: skills/ → design-templates/` (dst unchanged → zero pipeline edits) after the c128ffd5 upstream reorg moved the pipeline bundles. On `origin/main` (`c9ed1f8`).
- **142 `od-sync-orphan-prune`** — `--apply` now prunes upstream-removed orphans in recursive trees (4 pure cores, referenced-bundle hard-block, nested-root guard, runtime trash journal). On `origin/main` (`4b82998`).
- The chain was shaped by a Claude Code ↔ Codex CLI `/sdd debate` (`142/debate.md`) that uncovered the root cause: c128ffd5 silently reorganized upstream, the manifest mis-mapped, and the pipeline survived only on un-pruned orphans.

_Prior (committed): spec 140 `/meeting` `Next:` marker (`88343fd`); OD pin advance 73→150 (`5233ab3`); 137+139 status/doctor; 136/138._

## Active Work

**Spec 144 `sync-harness-gitignore-aware-walk` — COMMITTED on branch (`2f90538`), NOT pushed/merged.** All 16 tasks + 14 acceptance scenarios done; `notes.md` records the build-time `set -e` errexit bug (an `|| return` in `advise_dirty_once` aborted the walk in the non-git path — masked because the git path dodged it) and the tese-baseline insight (consumers' on-disk OD cache is the OD-engine's, never harness-recorded, so out of scope). **Status: in-progress** (→ shipped once on `origin/main`). Next: push + merge to `main`, then optionally re-sync the 4 consumers (self-rebootstrap picks up the fixed tool).

**Spec 141 — DONE, MERGED, PUSHED** (`1bc7223` on `origin/main`; 3 consumers at 150 systems + fixed engine, pushed).

**Spec 143 `od-vendor-skills-remap` — DONE, MERGED, PUSHED** (`c9ed1f8` on `origin/main`). Re-pointed skill-bundle src `skills/` → `design-templates/` (dst unchanged); 31 pipeline bundles re-sourced at the current pin.

**Spec 142 `od-sync-orphan-prune` — DONE, MERGED, PUSHED** (`4b82998` on `origin/main`). `--apply` prunes upstream-removed orphan files in recursive trees: 4 pure cores (suite 36→46), automatic prune, referenced-bundle hard-block, nested-root guard, runtime trash journal rm'd-on-success (gitignored). Pruned 284 orphans in Agent0; `--verify` green on all 7 paths.

**OD-engine chain COMPLETE + PROPAGATED:** 141 (idempotence/regen/advisory) + 143 (remap) + 142 (prune), all on `origin/main`. **All 4 consumers re-synced + pushed, `--verify` green, 111 design-templates bundles each:** ag-antecipa `d6e7e26` (clean fresh sync), mei-saas `4bc542a` / tese `235bae6` / cognixse `4746bd0` (fix-forward: `--force` + consumer-side `bun --apply` self-prune, 283 pruned each). Agent0 + 4 consumers all consistent.

**Root cause (found via the Claude Code ↔ Codex CLI debate, `142/debate.md`):** c128ffd5 silently moved pipeline bundles `skills/` → `design-templates/`; manifest mis-mapped; pipeline survived only on un-pruned orphans.

**HARNESS GAP — REFRAMED + FIXED by spec 144.** The prior "reconcile_deletions doesn't mirror recursive roots" framing was the symptom; the real root cause was the walk not respecting `.gitignore` (over-propagating untracked cache, poisoning the baseline). 144's git-aware walk fixes it: `reconcile_deletions` stays baseline-gated (correct) and now operates over a clean, tracked-only manifest. No separate mirror-recursive-roots spec needed.

## Next Actions

**▶ NEXT — push branch `144-sync-harness-gitignore-aware-walk` + merge to `main` (user-gated), then optional propagation.**
- Feature committed at `2f90538`; handoff committed separately. Push + open PR or fast-forward `main` per the user's call.
- Propagation: 144 changes `sync-harness.sh` itself (in its own manifest → self-rebootstrap re-exec on next consumer sync). A re-sync of the 4 consumers picks up the fixed tool + stops over-propagating cache; their *own* on-disk OD cache is gitignored/out-of-scope and untouched. Not urgent — all 5 repos currently correct.
- Mark spec 144 `**Status:** shipped` once on `origin/main`.

- **OD-vendor extraction** (`r-2026-06-01`, snoozed → 07-01) — distinct from the 141/142/143 chain.

**Spec 138 (shelved):** autopilot reopens only on demand test — 3 meetings with `friction` ≥4 consecutive model turns + explicit "continue unattended". Measurement only until then.

**Dormant reminder:**
- `r-2026-05-17` re-snapshot agentskills.io — quarterly, due 08-17. _(r-2026-05-31 umbrella-driver: dismissed + committed `1db1bc5`.)_

## Decisions & Gotchas

- **Skill/capacity homes:** edit canonical `.agent0/skills/<slug>/` only (`.claude/skills`+`.agents/skills` are symlinks). status/doctor share `.agent0/hooks/_brief-compose.sh` (emit-neutral) — re-verify the brief byte-identical after any lib edit.
- **Meeting portability:** skill is `agentskills-portable` — core loop free of Claude-only primitives (human gate degrades `AskUserQuestion`→prose). Transcripts git-tracked but project-local under `.agent0/meetings/` (out of sync manifest; only `.gitkeep` ships).
- **Meeting speaker selection (spec 140):** context-driven via `Next: <id>` exact-shape marker (last non-empty line; never NLP). `meeting.sh check` is roster-membership-only now; `resolve-speaker` owns the precedence; `advance --next <id>` sets `next_speaker` (no more `csv_successor`). 140↔138 boundary: deterministic transcript directive = in scope; semantic speaker inference / auto-chain = still gated behind 138's demand test.
- **OD pin advance (spec 141 — FIXED this session, uncommitted):** both bugs fixed (content-true idempotence; `--apply` now regenerates `od-catalog-index.json` via `generateCatalogIndex` + standalone `--gen-catalog`). A future advance is clean `--bump` then `--apply`, no perturbation. CAVEAT: `--verify` still fails on `skills/` (pre-existing orphan-file drift, out of 141 scope → candidate spec 142); does not block an advance (reconcile is byte-correct).
- **Harness sync:** all 3 consumers reconciled clean 3-way (`~ stale` auto-update, zero `!! customized`). Baseline bump = the audit record. NOTE: consumers now behind on `/product` (OD 150 systems) — resync after 141.
- **Env:** gitleaks pre-commit active; governance blocks `rm -rf`/`git clean -fd`/blanket `git add`; secrets-preflight wants separate `git add` then `git commit -F <file>` (not `-F -`); commits user-gated.
