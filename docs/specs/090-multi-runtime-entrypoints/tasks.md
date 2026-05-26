# 090 — multi-runtime-entrypoints — tasks

_Generated from `plan.md` on 2026-05-26. Work top-to-bottom. Check boxes as tasks complete. If a task reveals the plan is wrong, update `plan.md` before continuing._

## Implementation

- [x] 1. **Extract marker-region helpers to a shared lib.** Create `.claude/tools/lib/managed-block.sh` containing `detect_marker_state`, `_extract_region`, `_region_sha` (verbatim from `sync-harness.sh` lines ~767-818). Add a leading comment block explaining the lib is sourced by both `sync-harness.sh` and `check-instruction-drift.sh`. Make executable bit consistent with sibling tools (`chmod +x` not needed for a sourced lib, but `chmod 644` explicit).

- [x] 2. **Refactor `sync-harness.sh` to source the lib.** Replace the inline `detect_marker_state` / `_extract_region` / `_region_sha` definitions with `source "$(dirname "$0")/lib/managed-block.sh"` (or the equivalent fork-relative resolution that matches how the script locates other resources today). Preserve every other line of the file unchanged.

- [x] 3. **Run existing harness-sync tests to confirm zero regression.** Execute `bash .claude/tests/harness-sync/*.sh` in order; every test must continue to pass. The helper extraction is mechanical — any failure here indicates the source path or function signatures changed accidentally.

- [x] 4. **Edit `CLAUDE.md` managed block.** Inside the existing `<!-- AGENT0:BEGIN -->` / `<!-- AGENT0:END -->` markers, add a new section `## Runtime entrypoints` (index-shaped, one paragraph) documenting: `CLAUDE.md` is the Claude Code entrypoint and uses structured marker-aware merge in `sync-harness.sh` because Claude Code has no override-file chain; `AGENTS.md` is the Codex entrypoint and is plain baseline-tracked because Codex provides native override primitives (`AGENTS.override.md` at any scope; nested directory `AGENTS.md` files). The asymmetry is intentional — see `docs/specs/090-multi-runtime-entrypoints/`.

- [x] 5. **Create `AGENTS.md` at repo root.** Three regions:
  - **Top (outside markers, runtime-specific preamble):** project purpose (one paragraph), spec-first workflow pointer, the 3-tier capability classification table (`native-now` / `manual/read-only-now` / `Claude-only-until-follow-up`), and per-tier examples grounded in actual Agent0 capacities (file/shell, SDD artifacts, hooks/slash-skills).
  - **Middle (inside `<!-- AGENT0:BEGIN -->` / `<!-- AGENT0:END -->`):** byte-identical copy of `CLAUDE.md`'s managed-block region. Use the extracted lib's `_extract_region CLAUDE.md` and write the output between markers in `AGENTS.md`.
  - **Bottom (outside markers, customization-surface pointer):** short section naming `AGENTS.override.md` (any scope) and nested `AGENTS.md` files as the sanctioned fork-customization paths per Codex's instruction chain.

- [x] 6. **Verify cross-file managed-block byte-equality.** Run `diff <(.claude/tools/lib/managed-block.sh _extract_region CLAUDE.md) <(.claude/tools/lib/managed-block.sh _extract_region AGENTS.md)` (or equivalent inline awk for the same extraction). Expect empty diff. If non-empty, fix `AGENTS.md` to match.

- [x] 7. **Register `AGENTS.md` in `sync-harness.sh` `COPY_CHECK_FILES`.** Append the literal path `AGENTS.md` to the array. No other arrays touched; no new dispatcher needed — the existing plain-baseline-tracked path handles it.

- [x] 8. **Update `.claude/rules/harness-sync.md`.** Three edits: (a) § Manifest scope `COPY_CHECK_FILES` bullet list gains `AGENTS.md`; (b) § Gotchas append a new bullet: "AGENTS.md uses plain baseline-tracked sync, NOT the marker-aware merge that CLAUDE.md uses. The asymmetry is intentional — Codex provides native override-chain primitives (AGENTS.override.md, nested AGENTS.md) that make structured merge redundant. Do not promote AGENTS.md to managed-block merge without a follow-up spec and rule-of-three demand evidence — see spec 090."; (c) § CLAUDE.md managed-block merge strategy append one sentence at end: "This primitive does NOT apply to `AGENTS.md` by design; see § Gotchas + spec 090."

- [x] 9. **Create `.claude/tools/check-instruction-drift.sh`.** Sources `lib/managed-block.sh`. Implements the 5 checks: (i) `[ -f CLAUDE.md ] && [ -f AGENTS.md ]`; (ii) `detect_marker_state CLAUDE.md = paired` AND same for `AGENTS.md`; (iii) `_region_sha "$(_extract_region CLAUDE.md)" = _region_sha "$(_extract_region AGENTS.md)"`; (iv) grep `AGENTS.md` for Claude-only command patterns (`/sdd`, `PreToolUse`, `PostToolUse`, `SessionStart`, `Stop`, `.claude/settings.json`) and ensure each match is within a configurable line-window of a tier qualifier (`native-now`, `manual/read-only-now`, `Claude-only-until-follow-up`); (v) `bash .claude/tools/sync-harness.sh --check --agent0-path=. .` for the `AGENTS.md` row — exit non-zero on drift. Exit code 0 = all clean, 1 = drift. Plain text output, one line per check.

- [x] 10. **`chmod +x .claude/tools/check-instruction-drift.sh`.**

- [x] 11. **Create `.claude/tests/instruction-drift/` with 5 test fixtures.** One shell script per check, mirroring the existing `.claude/tests/harness-sync/` test convention (`set -e`, assertion shape, exit 0 on pass). Filenames: `01-both-entrypoints-exist.sh`, `02-markers-paired-and-ordered.sh`, `03-managed-blocks-byte-equal.sh`, `04-no-claude-only-claims-without-tier-caveat.sh`, `05-sync-harness-detects-agents-md-drift.sh`. Each test stages a known-bad scenario in `mktemp -d`, runs the drift script against it, asserts the expected failure mode.

- [x] 12. **Update `README.md` quick start.** Add one short line near the top of the project description: "Open this repo with **Claude Code** or **Codex**." (or the matching tone of the existing quick-start prose). No other README changes in this spec.

- [x] 13. **Run `.claude/tools/check-instruction-drift.sh` against the current repo.** Expect exit 0 with all 5 checks reporting OK. This is the live dogfood of the drift script — if it fails on a clean repo, the script is wrong, not the repo.

- [x] 14. **Run `.claude/tests/instruction-drift/*.sh`.** All 5 must pass. They exercise the failure modes against synthetic fixtures, not the live repo.

## Verification

_Acceptance checks tied to `spec.md` acceptance criteria. Each one maps to a scenario or static-fact bullet there._

- [x] **V1. Scenario "Codex first-contact entrypoint"** — `cat AGENTS.md` shows the 3-tier preamble at the top, project purpose, spec-first workflow pointer, and tier-qualified references to shared rules. `wc -c AGENTS.md` < 32768 (Codex `project_doc_max_bytes` default). Manually inspect: every `/sdd` / `PreToolUse` / `.claude/settings.json` mention carries the tier qualifier nearby (per task 9's check (iv)).

- [x] **V2. Scenario "Claude Code entrypoint remains correct"** — `grep -A6 'Runtime entrypoints' CLAUDE.md` shows the new section explaining the asymmetric structure: CLAUDE.md = structured marker merge / AGENTS.md = baseline-tracked + Codex override chain.

- [x] **V3. Scenario "Shared Agent0 guidance does not silently drift" (5 static checks)** — `bash .claude/tools/check-instruction-drift.sh` returns exit 0 with all 5 checks logged OK.

- [x] **V4. Scenario "Fork-facing instruction hygiene"** — `awk '/AGENT0:BEGIN/{f=1;next}/AGENT0:END/{f=0}f' CLAUDE.md AGENTS.md | grep -E '\.claude/memory/(cc-platform-hooks|propagation-hygiene|[a-z][a-z0-9-]+)\.md' | grep -vE '<topic>|<slug>|<name>'` returns zero hits (no concrete topic refs inside managed blocks; generic placeholders allowed and excluded by the second grep).

- [x] **V5. Static-fact "AGENTS.md exists + 3-tier preamble"** — `[ -f AGENTS.md ] && grep -E 'native-now|manual/read-only-now|Claude-only-until-follow-up' AGENTS.md` matches all three.

- [x] **V6. Static-fact "Ownership model = byte-identical managed block + comparison check"** — task 6 already confirmed; re-run `diff` for the verification record.

- [x] **V7. Static-fact "Asymmetric marker layout per file"** — `detect_marker_state CLAUDE.md` = `paired`, `detect_marker_state AGENTS.md` = `paired`, AND `awk '/AGENT0:END/{exit} f; /AGENT0:BEGIN/{f=1}' AGENTS.md | wc -l` AND post-AGENT0:END `AGENTS.md` has no fork-narrative section (only the customization-surface pointer).

- [x] **V8. Static-fact "AGENTS.md in sync-harness COPY_CHECK_FILES"** — `grep -A20 'COPY_CHECK_FILES=' .claude/tools/sync-harness.sh | grep -E 'AGENTS\.md'` matches one line.

- [x] **V9. Static-fact "Managed-block byte size within envelope"** — `wc -c < <(_extract_region CLAUDE.md)` ≤ 6.4 KiB × 1.10 (10% headroom over the 2026-05-26 baseline of 6381 bytes). Bigger growth triggers a re-look at index-shape discipline.

- [x] **V10. Static-fact "3-tier capability classification documented in spec.md"** — `grep -E 'native-now|manual/read-only-now|Claude-only-until-follow-up' docs/specs/090-multi-runtime-entrypoints/spec.md` matches all three tier names.

- [x] **V11. Static-fact "README.md quick start mentions both runtimes"** — `head -40 README.md | grep -E '(Claude Code|Codex)'` shows at least one line with each runtime name.

- [x] **V12. Regression — harness-sync tests unaffected by helper extraction** — `bash .claude/tests/harness-sync/*.sh` all pass (already done at task 3, re-run after all other edits land to confirm).

- [x] **V13. Status flip** — after V1–V12 are green, edit `docs/specs/090-multi-runtime-entrypoints/spec.md` `**Status:**` from `draft` to `shipped`. Check off all acceptance bullets in spec.md.

## Notes

- The implementation is contract-coupled — all 14 tasks land in a single commit (`feat(multi-runtime): ship spec 090 — AGENTS.md + asymmetric sync contract`) because the spec acceptance criteria reference each other (drift script tests both files; sync-harness registers a file that doesn't exist until task 5; etc.). Partial commits would leave the repo in a broken state where `check-instruction-drift.sh` fails.
- After ship, watch for the rule-of-three trigger: if ≥3 forks customize `AGENTS.md` outside Codex's native override chain (i.e. directly edit root `AGENTS.md`), scope a follow-up spec to promote it to structured marker-aware merge. Reminder in the project's normal `/remind` rhythm.
- The helper extraction (tasks 1-3) is a small refactor unrelated to spec 090's contract but enabling for it. If task 3 reveals the extraction breaks anything subtle, abort the extraction and instead duplicate the helpers in `check-instruction-drift.sh` — the duplication risk is ≤30 LOC and the spec 090 contract still ships.
- Codex's `project_doc_max_bytes` is configurable; downstream Agent0 forks whose users set it below 32 KiB will lose AGENTS.md silently. This is a Codex-side concern, not Agent0's — but the `AGENTS.md` body should mention the default config dependency near the customization-surface pointer.
- The Round 2 + Round 3 debate notes are the authoritative interpretation of the asymmetric contract. When implementing, prefer re-reading `debate.md` over re-deriving from spec.md prose — the debate has the reasoning.
