# Session handoff

Canonical runtime-neutral handoff for Agent0 sessions. Claude Code injects/nags through hooks; Codex receives the same handoff through tracked `.codex/hooks.json` after project/hook trust.

See `.agent0/context/rules/session-handoff.md` for the protocol, 4 KB size discipline, fallback behavior, and reader-side truncation defense.

---

## Current State

**OD `--bump`/`--apply` dogfood run (2026-06-01) — UNCOMMITTED, founder to review/commit.** Exercised the OD vendor-sync
write-paths end-to-end against upstream HEAD `bfcac4e0` (was pinned `d25a7aaf`). Two real bugs found + fixed:
- **Bug A (FIXED):** `--check` false "no changes" — `cmdCheck` trusted the `gh api compare` list, hard-capped at 300 by
  GitHub (no real pagination). Fix: pure `resolveChangedVendoredScope()` detects truncation (≥ `COMPARE_FILE_CAP=300`) /
  gh-unavailable and over-reports all vendored paths instead of concluding "in sync". TDD, +5 tests.
- **Bug B (FIXED + VALIDATED, spec 135):** real `--apply` was hard-blocked by `validateDesignMd`'s exact-phrase
  `REQUIRED_H2_SUBSTRINGS` gate. Consumer audit (notes.md) proved **nothing reads the H2 text** — `generateDsIndex` reads
  mood+hex, step 02-prototype reads prose. Replaced with a **substance gate** (`MIN_PALETTE_HEX=2` unique `#RRGGBB` +
  `MIN_H2_SECTIONS=3`, source-of-truth constants commented to the consumers). Cross-model debate w/ Codex (debate.md,
  converged) sharpened the spec. Validated: real `--apply` of HEAD passed all 731 files, reached Phase B; content reverted
  (founder-gated), pin stays `d25a7aaf`. **20 tests pass.** Spec 135 = `/sdd` full cycle (refine→debate→plan→tasks→impl→validate).
- **Positive:** `--bump` write-path verified; `--apply` two-phase atomicity held under Phase-A failure (confirmed twice).

_Prior (committed): sync-harness leak fix `dc3a93c`; specs 131/099/035/060 shipped, 036 superseded; `/product` by 079._

## Active Work

**Uncommitted, founder-gated** (one session, 2026-06-01):
- `sync-open-design.ts` + `.test.ts` — **Bug A** (compare-truncation false-negative) + **Bug B** (substance-gate validator). 20 tests.
- `docs/specs/135-od-design-md-validator-drift/` — full spec tree incl. `debate.md` (Claude↔Codex, converged) + `notes.md` (consumer audit, calibration).
- `reminders.yaml` — r-2026-05-18 closed; **r-2026-06-01** added (extract OD vendor out of /product — discuss w/ Codex). `HANDOFF.md`.
- Suggested commits: `fix(od-sync)` (Bug A + Bug B together, same file) + `docs(specs)` (135 tree).

## Next Actions

**Near-term queue:**
1. **Commit this session** — review `git diff`, then `fix(od-sync)` + `docs(specs)`. Set spec 135 Status draft→shipped on commit.
2. **(founder, optional) Pin advance** — whether to actually ingest+commit upstream HEAD's wholesale content (648 new systems / 83 updated). Validator no longer blocks it; this is a deliberate `/product` visual-output change, out of spec 135's scope.
3. **Extract OD vendor out of /product** (reminder `r-2026-06-01`) — debate w/ Codex the target home + consumer-contract boundary so OD is usable outside /product. Specs 027/049/135 context.
4. **Fair OD re-match for spec 027** (`r-2026-05-14`) — blind-judge 3.87-vs-4.73 confounded; iterate OD to 4 passes OR re-judge vs first-pass baseline.
5. **Re-evaluate fork-extension → smart-merge** (`r-2026-05-25`).

**Deferred / gated:** umbrella-execution driver in `/sdd` (`r-2026-05-31`, NOT a code generator); agentskills.io
re-snapshot (`r-2026-05-17`, due 08-17); agent0-atlas (≥10 forks); paid `/video`+`/image` validations need `FAL_KEY`.

## Decisions & Gotchas

- **Skill homes:** edit canonical `.agent0/skills/<slug>/` only (`.claude/skills`+`.agents/skills` are symlinks).
- **GitHub compare 300-file cap:** `gh api .../compare/A...B` truncates `.files[]` at 300 with no working pagination
  (`--paginate` only expands the commit list). Any drift detector reading that endpoint must over-report on a capped
  list, never conclude "no changes" (the Bug A false-negative). Codified in `resolveChangedVendoredScope`.
- **OD `--apply` reaches Phase-A only on real drift:** idempotence guard short-circuits to `no-op` (no tarball fetch)
  when live checksums match the manifest. To dogfood the full write-path, perturb one vendored non-recursive file so
  idempotence fails — apply re-fetches and overwrites it (reversible). Real apply ingests ~409M / 731 files (upstream
  catalogue grew 73→150 systems); revert via `git checkout <vendored dirs>` + `git clean -fd` (governance-gated, needs OVERRIDE).
- **OD `DESIGN.md` validator = substance gate (spec 135):** validates consumable substance (≥2 unique `#RRGGBB` hex +
  ≥3 H2 sections), NOT heading names — no consumer reads H2 text (`generateDsIndex`=mood+hex, step 02=prose). Don't
  re-introduce a heading-substring list. Hex-only detection deliberately mirrors `generateDsIndex.palette_summary`.
- **Env gotchas:** gitleaks pre-commit active; governance blocks `rm -rf`, `git clean -fd`, blanket `git add`;
  secrets-preflight blocks compound `git add && git commit` (separate calls); commits user-gated.
