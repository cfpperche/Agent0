# 076 — product-dogfood-fixes — tasks

_Generated from `plan.md` on 2026-05-22. Work top-to-bottom. Check boxes as tasks complete. If a task reveals the plan is wrong, update `plan.md` before continuing._

## Implementation

### #9 — Step 08 NN-prefix typo

- [ ] 1. In `.claude/skills/product/references/delegation-briefs.md` § Step 08, change the "Write 3 files DIRECTLY to {{out}}/docs/" CONSTRAINTS line: `08-system-design.md + 08-security.md + 08-data-flow.json` → `system-design.md + security.md + data-flow.json`. DELIVERABLE line is already correct — do NOT touch it.
- [ ] 2. Commit as `docs(076): fix Step 08 NN-prefix typo in delegation-briefs (#9)`.

### #3 — Mood-screen single-nav rule

- [ ] 3. In `delegation-briefs.md` § Mood-screen-writer → CONSTRAINTS, add one bullet immediately after the mobile-first / no-horizontal-overflow rules: *"Exactly one nav renders at any viewport width. The desktop nav/sidebar is `display:none` below the mobile breakpoint (a wrapped nav is a hard violation, not just an overflow concern — the SKILL.md overflow probe cannot catch a wrap)."*
- [ ] 4. Commit as `fix(076): mood-screen brief carries explicit single-nav rule (#3)`.

### #2-sections — Step 11 brief vs schema alignment

- [ ] 5. Re-read `.claude/skills/product/templates/pipeline/11-cost-estimate/schema.md` § "Required sections" + § "Conditional sections" to copy the canonical 8-required + 3-conditional list verbatim (Overview / Pricing Model / Assumptions / Build Cost / Run Cost / Sensitivity / Risks / Recommendations; conditional: Unit Economics / Projections / Scenarios).
- [ ] 6. In `delegation-briefs.md` § Step 11 → CONSTRAINTS:
  - Delete the line `SKIP unit economics + sensitivity + scenario analysis`.
  - Replace the existing `Required H2 sections: Assumptions / Build Cost / Run Cost / Legal & Audit Budget / Risks / Recommendations.` with two lines: `Required H2 sections (always): Overview / Pricing Model / Assumptions / Build Cost / Run Cost / Sensitivity / Risks / Recommendations.` AND `Required H2 sections (conditional — revenue products only): Unit Economics / Projections / Scenarios. Free / not-for-profit / internal products MUST declare the pricing model explicitly in running prose (per schema § Layer 1 any_of_contains).`
- [ ] 7. Commit as `fix(076): align Step 11 brief required sections with schema (#2-sections)`.

### #5 — False-parallelism in dispatch claims

- [ ] 8. In `.claude/skills/product/SKILL.md` § Phase 1 step 3 ("Steps 03 + 04 — parallel fan-out"), rewrite to two serial dispatches: *"Step 03 alone (functional-spec.md). After Step 03 returns, dispatch Step 04 alone — Step 04's brief reads `functional-spec.md`, so the dispatches MUST NOT share a single message."* Keep the rest of the step (quality judge + state update) unchanged.
- [ ] 9. In `SKILL.md` § Phase 4 step 1 ("Dispatch Step 15a + 15b + 15c in one message"), rewrite to: *"Dispatch Step 15a + Step 15c in one message (no shared inputs, distinct outputs). After Step 15c returns, dispatch Step 15b — Step 15b's Mood-screen-writer brief in hi-fi mode reads `fixture-spec.md`, so it CANNOT share a message with 15c."* Keep the per-step bullets (15a/15b/15c bodies) — only the dispatch grouping changes.
- [ ] 10. In `SKILL.md` § Worked example — parallel dispatch in a single message, update the prose:
  - Remove `Phase 1 Step 03+04` from the true-parallelism list.
  - Replace `Phase 4 Step 15a+15b+15c` with `Phase 4 Step 15a+15c (then 15b serially)`.
  - The 3-`Agent`-call code example: trim to the two truly-parallel calls (15a + 15c) and add one line below indicating "then a follow-up single dispatch for 15b once 15c returns".
- [ ] 11. In `delegation-briefs.md` § Phase 4 (line ~392), rewrite the paragraph that claims "three sub-agents — parallelizable in ONE message — all inputs are on disk from Phases 1-3, distinct output paths, no FS race": replace with the truthful split — 15a + 15c parallel; 15b serial because Mood-screen-writer hi-fi mode reads `fixture-spec.md`.
- [ ] 12. In `delegation-briefs.md` § Mood-screen-writer (no edit required) — verify line ~474 still explicitly names `fixture-spec.md` as a hi-fi-mode read (it does; cross-check left in place as the load-bearing source of truth for #5).
- [ ] 13. In `.claude/skills/product/references/state-machine.md` § Phase progression DAG (lines ~83-108):
  - `steps 01 (blocking, opus) → 02 alone → 03+04 parallel` → `steps 01 (blocking, opus) → 02 alone → 03 alone → 04 alone`
  - `step 15a atlas-writer + 15b hi-fi mood-writers (cap=5) + 15c fixture-spec writer — three sub-agents dispatched in parallel (one message)` → `step 15a atlas-writer + 15c fixture-spec writer dispatched in parallel (one message); after 15c returns, 15b hi-fi mood-writers (cap=5) dispatched serially (reads fixture-spec.md)`
- [ ] 14. Commit as `fix(076): serialize Step 04 after 03 and Step 15b after 15c (#5)`.

### #4 — Phase 4 visual check over HTTP

- [ ] 15. Create `.claude/skills/product/scripts/serve-hifi.sh`: best-effort HTTP server launcher. Picks a free port via `python3 -c 'import socket; s=socket.socket(); s.bind(("",0)); print(s.getsockname()[1])'`; backgrounds `python3 -m http.server <port> --bind 127.0.0.1 -d <serve-dir>`; writes `READY <port>` to stdout when bound (polls until the port responds, with a 5s timeout); on `python3` absent or port-bind failure, exits non-zero with `not-available: <reason>` on stderr. Make executable (`chmod +x`).
- [ ] 16. In `SKILL.md` § Phase 4 step 3 ("Best-effort visual check"), rewrite the loop:
  - Launch `.claude/skills/product/scripts/serve-hifi.sh <out>/docs/screens/hifi/` in the background; capture PID; read first line for `READY <port>` (or `not-available:` advisory).
  - On `not-available:` → emit `visual-gate-skipped: <reason>` and continue (existing advisory shape preserved).
  - On `READY <port>` → for each `<NN>-<name>.html`, navigate to `http://127.0.0.1:<port>/<NN>-<name>.html` (NOT `file://`); resize 375×812 then 1280×800; screenshot at each; run the overflow probe `document.documentElement.scrollWidth > document.documentElement.clientWidth`; record per-screen pass/fail for REPORT.md § Visual check.
  - On loop completion (success or any per-screen failure): `kill <pid>` to teardown the server. Wrap teardown in a trap or explicit final-cleanup branch so server doesn't leak if a navigation throws.
- [ ] 17. Smoke-test the helper script in isolation: `mkdir -p /tmp/serve-test && echo '<html>ok</html>' > /tmp/serve-test/index.html && bash .claude/skills/product/scripts/serve-hifi.sh /tmp/serve-test &` — confirm `READY <port>` appears, `curl http://127.0.0.1:<port>/index.html` returns `<html>ok</html>`, then `kill %1`. Verify no port leaks (`ss -ltn | grep <port>` empty after kill).
- [ ] 18. Commit as `fix(076): serve hi-fi screens over HTTP so the Playwright visual check actually runs (#4)`.

### #8 — SKILL-DIRECTED marker mechanism

- [x] 19. In `.claude/hooks/delegation-gate.sh` around lines 198-216 (the advisory branch):
  - Before the existing `if [ "$MODEL_SPECIFIED" = "false" ] && [ "$score" -ge 1 ]` block, extract the marker: `SKILL_DIRECTED="$(printf '%s' "$PROMPT" | grep -m1 -oE '^# SKILL-DIRECTED: [A-Za-z0-9_-]{10,}' | sed 's/^# SKILL-DIRECTED: //' || true)"`. Note the same anchoring as `# OVERRIDE:` extraction (line-start `^#`).
  - In the `elif [ "$score" -ge 2 ] && [ "$MODEL" != "opus" ]` branch (the `escalation` branch), prepend `[ -z "$SKILL_DIRECTED" ] && ` so the branch only fires when the marker is absent. `model-discipline` branch stays untouched.
  - **Done 2026-05-23.** Implementation extends slightly: anchor mirrors `# OVERRIDE:` exactly (`^[[:space:]]*# SKILL-DIRECTED: ` — optional leading whitespace, so prose that documents the marker mid-paragraph won't trip it), and slug validation moved to shell (not fused into the grep regex) so the rule paragraph stays load-bearing. Malformed slug values are silently ignored. Inline comment on the elif branch points readers to rules/delegation.md. **Slug length rule corrected 2026-05-23 post-task-25 live test**: ≥10-char minimum (mirrored from `# OVERRIDE:`) was wrong-shape for SKILL-DIRECTED — `# OVERRIDE:` carries human prose (≥10 rejects `skip`/`bypass`), SKILL-DIRECTED carries a machine slug where real skill names are short (`product` is 7 chars). Lowered to **≥3 chars** which still rejects typo-shaped `# SKILL-DIRECTED: x` while accepting every real skill slug. See notes.md § Deviations.
- [x] 20. In `delegation-gate.sh` around the audit-row jq builder (lines ~234-246):
  - Compute `skill_directed_field`: `if [ -n "$SKILL_DIRECTED" ]; then skill_directed_field="$(printf '%s' "$SKILL_DIRECTED" | jq -R -s -c 'rtrimstr("\n")')"; else skill_directed_field="null"; fi` (same shape as the existing `model_field`).
  - Add `--argjson skill_directed "$skill_directed_field" \` to the jq argument list.
  - Add `skill_directed:$skill_directed` to the JSON object literal after `advisory_kind:$advisory_kind` (keeps insertion order matching the documented field order).
  - **Done 2026-05-23.**
- [x] 21. Test the gate locally with two stdin payloads:
  - **(a) markerless multi-signal `sonnet` brief** — expect `additionalContext` carries the `escalation` advisory and the audit row carries `"advisory_kind":"escalation"` and `"skill_directed":null`.
  - **(b) same brief with `# SKILL-DIRECTED: product-dogfood` prepended** — expect `additionalContext` is empty (no advisory output) and the audit row carries `"advisory_kind":null` and `"skill_directed":"product-dogfood"`.
  - **(c) markerless brief WITHOUT a `model` field** — expect `model-discipline` still fires (marker does NOT excuse undeclared models).
  - **Done 2026-05-23.** All 3 scenarios passed verbatim (see notes.md § 2026-05-23 — task 21 3-payload gate test). Test artifacts under `/tmp/.claude/` cleaned up.
- [x] 22. In `.claude/rules/delegation.md` § Advisories, add one paragraph after the `escalation` description: *"**`# SKILL-DIRECTED: <slug>` marker** — a brief carrying this line (mirrors `# OVERRIDE:` grammar; slug ≥10 chars) is self-certifying that the model choice was deliberate (typically a slash-command skill that picked a non-opus model for mechanical pipeline work). The `escalation` advisory is suppressed; `model-discipline` is NOT — the marker doesn't excuse an undeclared model. The dispatch row's `skill_directed` field records the slug for greppable adoption tracking (`jq 'select(.skill_directed)'`). A brief may carry both `# OVERRIDE:` and `# SKILL-DIRECTED:` — they're independent."*
  - **Done 2026-05-23.** Paragraph reflects shipped behavior: mirrors `# OVERRIDE:` *anchoring* (not the ≥10-char rule — see task 19 update for why ≥3 is the right floor) and names `[A-Za-z0-9_-]+` slug shape explicitly with `product`/`sdd`/`run`/`verify` as worked examples.
- [x] 23. In `.claude/rules/delegation.md` § Audit log → Dispatch row:
  - Bump field count from "Thirteen fields" to "Fourteen fields".
  - Insert `skill_directed` into the field enumeration after `advisory_kind` (with the explanation that it's the slug from the marker, or null when absent — same shape as `override`).
  - **Done 2026-05-23.**
- [x] 24. In `.claude/skills/product/references/delegation-briefs.md`, add `# SKILL-DIRECTED: product` as the first line inside the brief body (immediately after the opening triple-backtick) for every brief Step 02 through Step 15c, plus § Mood-screen-writer and § Quality judge. Count: 14 producer briefs + Mood-screen-writer + Quality judge = ~16 insertions.
  - **Done 2026-05-23.** 17 markers inserted (Step 02-15c covers 15 briefs not 14 — 15a + 15c count separately, only Step 15b has no own brief block because it routes to Mood-screen-writer in hi-fi mode; plus Mood-screen-writer + Quality judge = 17). Idempotent awk transform skipped Step 01 (out of scope per task) and pre-flight verified no marker already existed; post-flight verified exactly 17 markers on `^# SKILL-DIRECTED: product$` pattern.
- [x] 25. Run one real-world end-to-end check by dispatching any `/product` Step's brief via the `Agent` tool (e.g., a no-op trial). Tail `.claude/delegation-audit.jsonl`; confirm the row carries `"skill_directed":"product"` and `"advisory_kind":null`.
  - **Done 2026-05-23.** Two-pass: first dispatch caught the ≥10-char slug bug (see notes.md § Deviations); after lowering the slug minimum to ≥3 the retest produced exactly the expected audit row — `model:"sonnet"`, `model_specified:true`, `advisory_kind:null`, `skill_directed:"product"`, `escalation_signals:["multi-integration","cross-domain","schema-data"]`. The 3 signals + non-opus model would normally trigger escalation; the marker suppressed it (verified end-to-end through the real CC harness, not just local stdin piping).
- [ ] 26. Commit as `feat(076): SKILL-DIRECTED marker suppresses escalation on skill-chosen models (#8)`.

## Verification

- [ ] 27. **Scenario #9** — `grep -E '08-(system-design|security|data-flow)' .claude/skills/product/references/delegation-briefs.md` returns ONLY the CONSTRAINTS-block reference (none in the "Write 3 files" line); semantic filenames are present in both the CONSTRAINTS and DELIVERABLE lines.
- [ ] 28. **Scenario #4** — manual: run the helper script against a directory of 2-3 sample HTML files; `curl http://127.0.0.1:<port>/<file>` returns the bytes; kill the server; `ss -ltn` shows no leaked port. `SKILL.md` no longer contains the string `file://` in the Phase 4 section (`grep -nF 'file://' .claude/skills/product/SKILL.md` returns nothing inside Phase 4; matches elsewhere are fine).
- [ ] 29. **Scenario #2-sections** — `grep -A1 'Required H2 sections' .claude/skills/product/references/delegation-briefs.md | grep -A0 'Step 11'` covers every required section the schema enforces at Layer 1; the substring `SKIP unit economics + sensitivity + scenario analysis` no longer appears in the Step 11 brief.
- [ ] 30. **Scenario #3** — `grep -i 'exactly one nav\|display:none.*mobile' .claude/skills/product/references/delegation-briefs.md` matches a CONSTRAINTS bullet inside § Mood-screen-writer.
- [ ] 31. **Scenario #5** — `grep -n '03+04\|15a + 15b + 15c\|all inputs.*on disk' .claude/skills/product/SKILL.md .claude/skills/product/references/delegation-briefs.md .claude/skills/product/references/state-machine.md` returns nothing (or only struck-through historical context if any). The same files' updated language correctly names the serial dependencies (`grep -n '03.*alone.*04 alone\|15a + 15c.*then 15b'` matches in each).
- [ ] 32. **Scenario #8** — re-run the three-payload test from task 21; results unchanged: markered dispatch → `escalation` suppressed + `skill_directed` populated; markerless multi-signal → `escalation` still fires; markerless no-model → `model-discipline` still fires.
- [ ] 33. Final sweep: bump `spec.md` `**Status:**` from `draft` to `shipped`; verify every `## Acceptance criteria` checkbox is `- [x]`; run `bash .claude/tools/probe.sh last-run` if any validator runs touched the delegation gate (sanity check it didn't regress).

## Notes

_Anything that came up during execution that doesn't belong in plan.md but is useful for the PR description or future readers._
