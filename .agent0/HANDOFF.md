# Session handoff

Canonical runtime-neutral handoff for Agent0 sessions.

See `.agent0/context/rules/session-handoff.md` for the protocol.

---

## Current State

- **Harness audit completed this session (Claude, Fable 5) — verdict: exceptionally healthy.** Doctor 24/24 green; instruction-drift checker green; zero orphaned hooks/tools/rules (13 wired + 2 sourced + 5 intentionally-unwired hooks; 30/30 tools and 39/39 rules reachable); spec corpus 164/173 shipped (94.8%); ~360 tests across 44 suites. Four findings were identified; the four mechanical ones were resolved this session via Sonnet delegation (audit items 1/3/4/5), verified, and committed:
  - `b999412` — **delegation.md cascade contradiction fixed.** Line 30 mandated the retired ×1.2/×1.8 artifact-size cascade; rewritten to current `artifact-budgets.md` semantics (200 KB catastrophe cap + `min_size` floors; trim-loop/re-emit still forbidden; `budget-exempt:` override retained — verified still defined in artifact-budgets.md:38). The unrelated "validator-cascade" passages untouched.
  - `7d571d9` — **governance doctrine grandfathering clause added.** New `## Grandfathering of pre-doctrine capacities` section: pre-2026-06-07 capacities grandfathered, doctrine applies prospectively, material expansion triggers the admission checklist, maintenance does not. Resolves the audit's "media/product capacities vs doctrine" tension (chronology verified: doctrine 2026-06-07 postdates media capacities of late May — no violation occurred).
  - `28186fb` — **spec 091 formally superseded** (meeting-bridge debate flow per specs 149/180 delivers what 091 proposed); `runtime-capabilities.md` debate row: Codex column `planned: 091-…` → `convention`, note rewritten spec-number-free. Drift checker green.
  - `573a07a` — **memory-frontmatter-validate test suite added** (`.agent0/tests/memory-frontmatter-validate/`, 6 scenarios, 6/6 pass, hermetic mktemp fixtures). Was the only load-bearing hook with zero coverage.
- **Validation:** new suite 6/6; adjacent suites green post-edit (`runtime-capabilities`, `delegation-gate`, `instruction-drift` run-alls all PASS); `check-instruction-drift.sh` exit 0; propagation scan confirmed the edits introduced no new internal pointers.
- Previous session's work (specs 180–184 + consumer sync to mei-saas/acmeyard/cognixse) remains fully pushed; see git log before `b999412`.
- **Pre-existing / unrelated dirty state remains untouched:** `.agent0/meetings/terceiro-runtime-modelos-chineses-2026-06-08T14-18-05Z/` (do not stage unless explicitly requested).

## Active Work

- None in flight as code after the audit-fix commits. This session: harness audit (4 parallel Explore agents + own verification) → 4 fixes delegated to Sonnet (4 parallel dispatches, disjoint files) → verified → committed.

## Next Actions

- **Audit item 2 (user decision, open):** decide spec 171 (`context-injection-reformulation`, 2/19 tasks, stalled) — resume, re-scope, or formally close it and declare the current design (managed block + startup brief, no prompt-time injection) final. Prompt-time context injection stays paused meanwhile.
- **Audit item 6 / spec 183 residual (optional):** live Codex `/hooks` matcher test to empirically confirm the doc-stated `Edit`/`Write`→`apply_patch` aliasing; needs an interactive Codex session + `.codex/hooks.json` change — hand the user a copy-paste recipe, don't headless-brute-force.
- **Consumer sync NOT run this session** (per project core: only on explicit request). Three shipped rules changed (`delegation.md`, `agent0-governance-doctrine.md`, `runtime-capabilities.md`) plus the new shipped test suite — next `sync-harness.sh --apply` run on mei-saas/acmeyard/cognixse will carry them.
- **Residual hygiene observed (cheap, opportunistic):** post-spec-070 spec-number citations have re-accumulated in shipped rules (e.g. delegation.md lines 6/32/56/89, runtime-capabilities.md several rows cite spec 106/111/121/137/152/153…). Pre-existing, out of audit scope; per propagation-hygiene memory, clean in passing when those files are next touched.
- If the user wants to change the spec 182 license holder from `cfpperche` to a legal name later, do that as a separate follow-up commit.

## Decisions & Gotchas

- **Grandfathering is now written doctrine:** pre-doctrine capacities (media gen, product lifecycle) are first-class and not retroactively re-litigated; the admission checklist binds new capacities and material expansions only.
- **Artifact-size cascade is dead everywhere:** delegation.md no longer mandates it; the only size mechanisms are the 200 KB catastrophe cap and per-step `min_size` floors. Do not reintroduce per-step KB budgets in briefs.
- Spec 091 is superseded — the debate-automation lane is the meeting bridge (`meeting.sh` + `codex-exec`/`claude-exec`), not a standalone runner. The registry debate row says `convention` for Codex.
- The secrets-preflight hook blocks compound `git add … && git commit …` — commit tracked files with `git commit <path> -m`, or stage and commit in separate Bash invocations.
- Agent0 remains positioned as a **portable governance/evidence harness for existing coding-agent runtimes**; keep branding independent/personal for now (no CognixSE product framing in public positioning).
- `codex-exec` has helper-owned timeout/progress bounds but no spend guard — operational control only, not cost control.
