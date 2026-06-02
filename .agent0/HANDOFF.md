# Session handoff

Canonical runtime-neutral handoff for Agent0 sessions. Claude Code injects/nags through hooks; Codex receives the same handoff through tracked `.codex/hooks.json` after project/hook trust.

See `.agent0/context/rules/session-handoff.md` for the protocol, 4 KB size discipline, fallback behavior, and reader-side truncation defense.

---

## Current State

**Session 2026-06-02 (spec 141) — `141 od-sync-apply-completeness` IMPLEMENTED + VALIDATED, UNCOMMITTED.**
- Full SDD cycle: plan → tasks → TDD implement → validate. All 5 acceptance criteria met; suite **36 pass / 0 fail** (was 20; +16 assertions across 3 new pure exported fns). 3 fixes, all in `.claude/skills/product/scripts/sync-open-design.ts`:
  - **Fix 1 — content-true idempotence:** deleted the stale-manifest compare + `if (vp.recursive) continue` blind-skip. New two-tier gate: `pinnedContentAlreadyApplied()` fast-path (network-free: `verifyManifest` passes AND last `apply` history sha == `pinned_sha`) + post-stage slow-path (staged-vs-on-disk, tree-aware) no-op. A `--bump`+`--apply` now reconciles without the spec-135 perturbation workaround.
  - **Fix 2 — catalogue regen:** `buildCatalogVendors()` (pure, ports `/tmp/gen-catalog.py`: preserve curated verbatim / add new mechanical) + `generateCatalogIndex()` wired after `generateDsIndex` in `cmdApply` + standalone `--gen-catalog` flag (dual-exposure mirrors `--gen-ds-index`). Dogfood: regen reproduced the committed `od-catalog-index.json` byte-for-byte.
  - **Fix 3 — stale-count advisory:** `scanStaleCounts()` (3 context-specific patterns, precision-tuned after a real false-positive) + `## Stale count advisory` section in the apply report. Caught + fixed the live stale `02-prototype/prompt.md:104` ("73 `DESIGN.md` directories").
- **3 OQs resolved at plan-time** (see `docs/specs/141-*/plan.md`): OQ1 both-not-either, OQ2 keep-two-indices, OQ3 two-tier no-op.
- **Discovered, OUT OF SCOPE:** a 3rd engine gap — `--apply` never prunes orphan dst files, so `vendor/open-design/skills/` permanently fails `--verify` (residue of the original advance's manual workaround). Masks the live fast-path on this repo (verify-gated) → `--apply` here always slow-path-reconciles, CORRECTLY (byte-identical output). Candidate spec 142 / founder call (notes.md § Open questions).

_Prior (committed): spec 140 `/meeting` `Next:` marker (`88343fd`); OD pin advance 73→150 (`5233ab3`); spec 141 drafted (`51e92ae`); 137+139 status/doctor; 136/138._

## Active Work

**Spec 141 — COMMITTED + CONSUMERS SYNCED.** Committed `1bc7223` on branch `spec-141-od-sync-apply-completeness` (not merged to main, not pushed). All 3 consumers re-synced via `sync-harness.sh --apply`: each **5837 copied + 103 stale-updated, 0 customized-refused, 0 overwritten, exit 0**; verified at 150 systems + fixed engine; post-sync `--check` clean (0 drift). **Consumers now carry ~6000 uncommitted changed files each** (harness surface + /product 150-system advance + fixed engine) — committing inside each consumer repo is a separate, user-gated follow-up.

## Next Actions

1. **Decide spec-141 branch fate** — merge `spec-141-od-sync-apply-completeness` → main (+ push?), or keep as branch. (Commits/pushes user-gated.)
2. **Commit the synced changes inside each consumer** (mei-saas/cognixse/tese) if desired — each has ~6000 staged-able files from the re-sync.
3. **DISCUSS / decide spec 142 (orphan-cleanup)** — the discovered 3rd engine gap (`--apply` never prunes orphan dst files → `vendor/open-design/skills/` permanently fails `--verify`). Founder call: separate spec vs 141 amendment. _(in discussion this session)_
- **OD-vendor extraction** (`r-2026-06-01`, snoozed → 07-01) — distinct from 141.

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
