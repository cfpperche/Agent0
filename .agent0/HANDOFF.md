# Session handoff

Canonical runtime-neutral handoff for Agent0 sessions. Claude Code injects/nags through hooks; Codex receives the same handoff through tracked `.codex/hooks.json` after project/hook trust.

See `.agent0/context/rules/session-handoff.md` for the protocol, 4 KB size discipline, fallback behavior, and reader-side truncation defense.

---

## Current State

**Session 2026-06-03 — specs 144 + 145 SHIPPED on `origin/main`.** 144 `sync-harness-gitignore-aware-walk` (`528c475`): git-aware walk, stops propagating gitignored runtime cache. 145 `od-vendor-skills-bundles-fate` (`dad39cf`): dropped the 729-file pipeline-unread `vendor/open-design/skills/` tree + its `vendored_paths[]` entry; `--verify` green (7→6 paths), 46/46 engine tests pass. **Now: propagating both to the 4 consumers (1-by-1).** Fixed the harness layer of the same bug-class as 141/142: `sync-harness.sh`'s `find`-based walk did not respect `.gitignore`, so it over-propagated the OD-engine's gitignored `runtime/od-sync/extracted-<sha>/` cache (measured: 6470 walked under `.claude/skills/product`, 5158 of them cache). Now the two `find` expansions (`COPY_CHECK_RECURSIVE`+`COPY_CHECK_GLOBS`) filter to `git ls-files` ("managed = tracked"); non-git sources fall back to a guarded `find` (static `*/runtime/od-sync/extracted-*` exclude + advisory, never blind); dirty-source advisory; cache-orphan deletions summarized. Full SDD ran incl. a Claude↔Codex `/sdd debate` (2 rounds, converged) that resolved A-vs-B → **Model A ownership-clarified**. **40/40 harness-sync tests pass** (added 39, 40); live `--check` against `tese`: 0 cache lines, 747 vendor still travel, 6470→1311. Files: `.agent0/tools/sync-harness.sh`, `.agent0/tests/harness-sync/{39,40}*`+`run-all.sh`, `.agent0/context/rules/harness-sync.md` § Manifest scope, `docs/specs/144-*`.

_Prior — **Session 2026-06-02 — OD-engine chain (141 → 143 → 142) SHIPPED + propagated to all 4 consumers.** `--verify` green (7/7) on Agent0 + every consumer; bundles 111 design-templates each._
- **141 `od-sync-apply-completeness`** — content-true idempotence (fast-path `pinnedContentAlreadyApplied` + post-stage slow-path; deleted the stale-manifest compare + recursive blind-skip), catalogue regen (`generateCatalogIndex` + `--gen-catalog`), stale-count advisory (`scanStaleCounts`). On `origin/main` (`1bc7223`).
- **143 `od-vendor-skills-remap`** — re-pointed the skill-bundle vendored-path `src: skills/ → design-templates/` (dst unchanged → zero pipeline edits) after the c128ffd5 upstream reorg moved the pipeline bundles. On `origin/main` (`c9ed1f8`).
- **142 `od-sync-orphan-prune`** — `--apply` now prunes upstream-removed orphans in recursive trees (4 pure cores, referenced-bundle hard-block, nested-root guard, runtime trash journal). On `origin/main` (`4b82998`).
- The chain was shaped by a Claude Code ↔ Codex CLI `/sdd debate` (`142/debate.md`) that uncovered the root cause: c128ffd5 silently reorganized upstream, the manifest mis-mapped, and the pipeline survived only on un-pruned orphans.

_Prior (committed): spec 140 `/meeting` `Next:` marker (`88343fd`); OD pin advance 73→150 (`5233ab3`); 137+139 status/doctor; 136/138._

## Active Work

**Spec 144 `sync-harness-gitignore-aware-walk` — SHIPPED + PUSHED** (`origin/main` @ `528c475`; ff-merge, branch deleted, 40/40 tests green post-merge). Status: shipped. `notes.md` records the build-time `set -e` errexit bug (`|| return` in `advise_dirty_once`) and the tese-baseline insight.

**Spec 145 `od-vendor-skills-bundles-fate` — SHIPPED (`dad39cf`).** Founder decided DROP. Removed 729-file `vendor/open-design/skills/` + manifest entry; `--verify` green (6 paths), 46/46 engine tests, harness 40/40. Retained `design-systems/` + `vendor/open-design/{prompts,frames,templates,.cache}` (all confirmed consumed by Step 02 / catalogue-gen) + Apache `LICENSE`/`NOTICE`. `SKILL.md` updated.

**✅ DONE — 144+145 propagated to all 4 consumers, validated, committed + pushed.** ag-antecipa `e0b2e6f`, mei-saas `3abd569`, cognixse `9d81320`, tese `c4a43ba`. Per consumer: `--apply` (self-rebootstrapped the fixed tool + brought tests 39/40, harness-sync.md), then fix-forward of the 145 drop — the harness is baseline-gated (each consumer's baseline recorded only ~91 of the 729 skills, the bulk vendored by the consumer's own OD engine), so a plain `--apply` couldn't fully remove them: surgically removed the `skills/` `vendored_paths[]` entry from each MANIFEST.json (preserving its own `history`), `git rm`'d the 729-file tree, mirrored the `SKILL.md` note. Each validated: OD `--verify` green (6 paths), harness suite 40/40. Apache attribution + the in-use vendor subdirs untouched. (Note: the baseline-gated limitation = the same bug-class spec 144's intent describes; dropping a whole vendored root still needs a manual `git rm` per consumer.)

**Spec 141 — DONE, MERGED, PUSHED** (`1bc7223` on `origin/main`; 3 consumers at 150 systems + fixed engine, pushed).

**Spec 143 `od-vendor-skills-remap` — DONE, MERGED, PUSHED** (`c9ed1f8` on `origin/main`). Re-pointed skill-bundle src `skills/` → `design-templates/` (dst unchanged); 31 pipeline bundles re-sourced at the current pin.

**Spec 142 `od-sync-orphan-prune` — DONE, MERGED, PUSHED** (`4b82998` on `origin/main`). `--apply` prunes upstream-removed orphan files in recursive trees: 4 pure cores (suite 36→46), automatic prune, referenced-bundle hard-block, nested-root guard, runtime trash journal rm'd-on-success (gitignored). Pruned 284 orphans in Agent0; `--verify` green on all 7 paths.

**OD-engine chain COMPLETE + PROPAGATED:** 141 (idempotence/regen/advisory) + 143 (remap) + 142 (prune), all on `origin/main`. **All 4 consumers re-synced + pushed, `--verify` green, 111 design-templates bundles each:** ag-antecipa `d6e7e26` (clean fresh sync), mei-saas `4bc542a` / tese `235bae6` / cognixse `4746bd0` (fix-forward: `--force` + consumer-side `bun --apply` self-prune, 283 pruned each). Agent0 + 4 consumers all consistent.

**Root cause (found via the Claude Code ↔ Codex CLI debate, `142/debate.md`):** c128ffd5 silently moved pipeline bundles `skills/` → `design-templates/`; manifest mis-mapped; pipeline survived only on un-pruned orphans.

**HARNESS GAP — REFRAMED + FIXED by spec 144.** The prior "reconcile_deletions doesn't mirror recursive roots" framing was the symptom; the real root cause was the walk not respecting `.gitignore` (over-propagating untracked cache, poisoning the baseline). 144's git-aware walk fixes it: `reconcile_deletions` stays baseline-gated (correct) and now operates over a clean, tracked-only manifest. No separate mirror-recursive-roots spec needed.

## Next Actions

**Spec 146 `product-craft-floor` — SHIPPED + PUSHED** (`origin/main` @ `a422a93`; ff-merge, branch deleted). **Propagated to 3 consumers** (cognixse `3e9f817`, mei-saas `7e0ff46`, tese `3498e62`) — all 7 product files were clean stale/copy (no customized), craft-floor 9/9 + OD `--verify` 6 paths green in each. (ag-antecipa not done this round per user.) Full SDD ran: OQs resolved via `codex-exec` convergence (rule triage 5 deterministic / 2 judge-only; judge-units 02+15b not 15a; brand-exception; JSON shape). Built `scripts/craft-floor-check.ts` (Agent0-authored P0 rules, brand-token-exempt) + `craft-floor-check.test.ts` (9/9; slop=5 active, purple-brand suppresses, noisy=0); `references/craft-floor.md`; wired `craft-floor` criterion into `quality-checklist.md` (02 + 15b only) + orchestration in `SKILL.md`/`quality-judge.md` (run check pre-judge, judge grades `fail` iff `active_p0>0`); pointer added to the 02 producer brief. 46/46 OD-engine tests still green. **Next: merge branch + push; mark in handoff.** (The 1 failing test under `runtime/od-sync/extracted-*` is OD upstream's own gitignored cache test, not ours.)


**▶ NEXT — drive spec 145 `od-vendor-skills-bundles-fate`** (investigation opened this session). Start with `/sdd refine 145` or research: confirm the `vendor/open-design/skills/` (729) "not-read-by-pipeline" verdict (incl. `templates/pipeline/**` + prose ad-hoc `Read`s), establish original intent from 027/049/143 + the anthill ADR, quantify carry cost (729 × N consumers), then surface KEEP-vs-DROP for the founder. DROP = remove the `skills/ ← design-templates/` `vendored_paths[]` entry (work out the `--verify` consequence). No removal without confirmation; Apache attribution + `design-systems/` untouched.

**Optional (not urgent) — propagate 144 to the 4 consumers.** 144 changes `sync-harness.sh` (in its own manifest → self-rebootstrap re-exec on next sync), so a re-sync picks up the fixed tool + stops over-propagating cache; consumers' own on-disk OD cache is gitignored/out-of-scope, untouched. All 5 repos currently correct, so this only matters before the next vendored-tree change.

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
