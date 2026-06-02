# 135 — od-design-md-validator-drift — plan

_Drafted from `spec.md` on 2026-06-01. Update this file if implementation reveals the plan is wrong; do NOT silently diverge._

## Approach

The preflight (consumer audit) already landed the design decision: nothing in the pipeline depends on the literal H2 heading text, so the `validateDesignMd` gate over `REQUIRED_H2_SUBSTRINGS` enforces a contract no consumer reads and produces false rejections (`wechat`, the abbreviated-heading systems). We replace that exact-phrase gate with a **substance gate** grounded in what is actually consumed: a usable palette (≥ `MIN_PALETTE_HEX` `#RRGGBB` hex codes — the one hard `generateDsIndex` dependency) plus a corruption tripwire (≥ `MIN_H2_SECTIONS` H2 headings of any name). The required surface IS the consumed surface, with the two constants commented to trace back to `generateDsIndex` + step 02-prototype — that comment is the Q3 "named source of truth", not a hand-maintained heading list.

Order: (1) red — rewrite the `validateDesignMd` tests to express the new contract (accept abbreviated `## 2. Color`, accept wechat-style vocabulary, reject a degenerate/truncated stub); (2) green — reimplement `validateDesignMd` as the substance check; (3) keep the call sites in `cmdApply` Phase A unchanged (signature stays `(content) → string[] of problems`); (4) validate via the full suite + a real `--apply` dogfood showing Phase A now passes the previously-failing files and reaches Phase B. The two-phase atomic mechanism is untouched (confirmed correct in the prior dogfood).

## Files to touch

**Modify:**
- `.claude/skills/product/scripts/sync-open-design.ts` — replace `REQUIRED_H2_SUBSTRINGS` + `validateDesignMd` body with the substance gate (`MIN_PALETTE_HEX`, `MIN_H2_SECTIONS` consts + a comment tracing them to the consumers). Keep the exported signature `validateDesignMd(content: string): string[]` so `cmdApply` Phase A and its `report.schemaFailures` wiring are unchanged. Update the now-stale doc-comment that claims the list tracks an older upstream snapshot.
- `.claude/skills/product/scripts/sync-open-design.test.ts` — replace the `describe("validateDesignMd")` block: assert accept on abbreviated headings, accept on wechat-style vocabulary (no literal "layout"/"visual theme"), reject on a degenerate stub (too few sections / no palette). Add a Phase-A-shaped fixture asserting the atomic invariant on a validation failure (live untouched, manifest unchanged, staging preserved) — reuse the existing tmp-tree harness style.

**Create:** none.

**Delete:** none (the `REQUIRED_H2_SUBSTRINGS` array is replaced in place, not removed as a separate file).

## Alternatives considered

### Naive resolution (a): `'color palette' → 'color'`

Rejected — fixes only the one substring that happened to fail in the dogfood; `typography`/`component`/`layout`/`visual theme` would each drift next upstream rename. Doesn't address the root cause (hand-maintained heading list silently drifting). This was Codex's point 3.

### Resolution (b): keep strict, treat upstream as regressed

Rejected — the audit shows the strict heading contract guards nothing any consumer reads; `wechat` is demonstrably valid and consumable. "Regressed" is the wrong diagnosis. Keeping it permanently wedges the OD sync (the pin can never advance).

### Resolution (c): per-system allowlist

Rejected — re-introduces a hand-maintained exception list, the same drift-prone shape in new clothing. The substance gate needs zero per-system entries.

## Risks and unknowns

- **Threshold calibration.** `MIN_PALETTE_HEX = 3` / `MIN_H2_SECTIONS = 3` are floors below every observed real system (claude 9 / flat 9 / wechat 8 sections; wechat 15 hex). Risk: a legitimate but minimalist future system dips under. Mitigation: floors are deliberately low; a too-low file is genuinely suspect. The constants are named + commented for easy adjustment.
- **Substance ≠ quality.** The gate proves "not corrupt/degenerate", not "good design system" — same honest limitation the old heading gate had (a `## Typography` with an empty body always passed). Not a regression; documented.
- **Real `--apply` is network + large.** Advancing the pin ingests ~72 systems of upstream content (409 MB tarball). The validator fix is verified independently; the actual content commit is a separate founder-gated step (Non-goals). The validation step demonstrates Phase A passes without necessarily committing the content churn.
- **`generateDsIndex` mood fallback.** `wechat`'s first blockquote is `> Category: …` which `generateDsIndex` skips (regex `^>\s*category:`) → mood falls back to title. Confirmed working; no change needed, but noted so the validator doesn't accidentally start requiring a mood blockquote.

## Research / citations

- Consumer audit recorded in `notes.md` § Design decisions (2026-06-01): `generateDsIndex` internals, step 02-prototype `prompt.md:81`, `wechat/DESIGN.md` @ `bfcac4e0` fetched via `gh api`.
- `debate.md` — cross-model review (Claude Code initiating, Codex CLI reviewing) that shaped the spec's preflight + source-of-truth requirements.
- Prior dogfood (HANDOFF 2026-06-01): two-phase atomic apply confirmed correct under Phase-A failure.
