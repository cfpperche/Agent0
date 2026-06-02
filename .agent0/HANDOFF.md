# Session handoff

Canonical runtime-neutral handoff for Agent0 sessions. Claude Code injects/nags through hooks; Codex receives the same handoff through tracked `.codex/hooks.json` after project/hook trust.

See `.agent0/context/rules/session-handoff.md` for the protocol, 4 KB size discipline, fallback behavior, and reader-side truncation defense.

---

## Current State

**Session 2026-06-01/02 — all SHIPPED, committed + pushed (`609b2b8..444b963`).** OD vendor-sync hardened + reminder
queue triaged.
- **Spec 135 (shipped, `884724c`/`2fc0415`):** OD `--check`/`--apply` dogfood found + fixed two bugs. **Bug A** — `--check`
  false "no changes": `cmdCheck` trusted the `gh api compare` list, hard-capped at 300 by GitHub (no real pagination).
  Fixed via pure `resolveChangedVendoredScope()` (truncation/gh-unavailable → over-report). **Bug B** — real `--apply`
  hard-blocked by `validateDesignMd`'s exact-phrase `REQUIRED_H2_SUBSTRINGS`; a consumer audit proved nothing reads H2
  text (`generateDsIndex`=mood+hex, step 02=prose), so it became a **substance gate** (`MIN_PALETTE_HEX=2` + `MIN_H2_SECTIONS=3`).
  Full `/sdd` cycle incl. Codex debate (converged). Validated: real `--apply` of HEAD passed 731 files, reached Phase B;
  content reverted (pin stays `d25a7aaf`). 20 tests.
- **Canvas-contrast rule (`2bbb53a`):** step-2 prototype now requires ≥2 distinct canvas tones across the 3 directions
  (durable residual of the 2026-05-14 OD dogfood, finding #2).
- **Reminder queue triaged 5→2:** closed `r-2026-05-14` (fair OD re-match — apparatus gone, overtaken-by-events),
  cancelled `r-2026-05-17` agent0-atlas + `r-2026-05-25` fork-extension (both forks-presupposing → over-engineering per
  `[[forks-ephemeral-dogfood]]`); snoozed `r-2026-06-01` OD-extraction → 07-01.

_Prior (committed): sync-harness leak fix `dc3a93c`; specs 131/099/035/060 shipped, 036 superseded; `/product` by 079._

## Active Work

None. Working tree clean (the untracked `docs/specs/136-meeting/` is from a **separate session** — not this one's, leave it).
All session work committed + pushed.

## Next Actions

**Nothing actionable in the queue** — the 2 remaining reminders are correctly dormant (real triggers, not cancel-worthy):
1. `r-2026-05-17` **re-snapshot agentskills.io** — quarterly maintenance, due 08-17 (snapshot frozen 05-17). Date-gated.
2. `r-2026-05-31` **umbrella-execution driver for `/sdd`** — deferred by rule-of-three (n=1, only mei-saas hit it); reopen
   as a `/sdd` spec when a 2nd founder stalls. NOT a code generator.

**Founder-gated, not queued:**
- **OD pin advance** — whether to ingest+commit upstream HEAD's wholesale content (648 new systems / 83 updated). Validator
  no longer blocks it; deliberate `/product` visual-output change, out of spec 135 scope.
- **OD-vendor extraction** (`r-2026-06-01`, snoozed → 07-01) — debate w/ Codex moving OD out of `/product` so it's usable
  outside it. Specs 027/049/135 context.

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
