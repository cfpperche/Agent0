# 051 — plan

## Approach

Two mechanical fixes to skill files + retro-fix on /tmp/dogfood-erp/ as validation. No sub-agents needed (parent-side edits + file splits). Total surface: 2 skill files modified, 3 dogfood pages restructured, 1 dogfood layout patched, dev server re-tested in browser.

## Files to touch

### Skill (committed)

| File | Change |
|---|---|
| `.claude/skills/product/SKILL.md` § Phase 4 step 3 | Insert substep 3.5 (or merge into step 3) describing the layout placeholder substitution — title resolution priority + lang detection heuristic |
| `.claude/skills/product/references/delegation-briefs.md` § Per-stack screen-writer § Next.js stack | Add CONSTRAINTS bullet about async + `'use client'` separation pattern |

### Dogfood (NOT committed — `/tmp/`)

| File | Change |
|---|---|
| `/tmp/dogfood-erp/app/layout.tsx` | `title: "PROTOTYPE_SLUG"` → `title: "ERP para salões de beleza"`; `lang="en"` → `lang="pt-BR"` |
| `/tmp/dogfood-erp/app/check-in/[appointmentId]/page.tsx` | Drop `'use client'` at top; extract interactive body to `_CheckInClient.tsx` (with `'use client'`); page.tsx stays Server async, awaits params, renders `<CheckInClient {...resolved} />` |
| `/tmp/dogfood-erp/app/prontuario/[clientId]/page.tsx` | Same pattern → `_ProntuarioClient.tsx` |
| `/tmp/dogfood-erp/app/booking/[salonSlug]/page.tsx` | Same pattern → `_BookingClient.tsx` |

## Alternatives considered

1. **Title substitution at Phase 0 (skeleton-copy time) instead of Phase 4 (stitch).** Rejected: Phase 0 doesn't yet have brand-book.md (Step 13 hasn't run); the title source would be limited to the raw `<idea>` string with no upgrade path. Phase 4 has access to everything — better resolution + same complexity.
2. **Add `--locale=<bcp47>` flag** instead of substring detection. Considered, deferred. The detection heuristic (`R$ | LGPD | NFS-e | Pix`) is robust enough for v1 and zero new surface area; explicit flag is a follow-on if the heuristic ever false-positives on a non-Brazilian product mentioning Pix in passing (low probability).
3. **Validator extension to grep for `'use client'` + `async function.*Page` in same file.** Rejected for spec 051 scope — useful but adds validator surface that needs its own design (advisory vs hard-block, false-positive rate vs Next.js version drift). Brief-side rule is the cheaper first fix; validator extension is a candidate follow-on if the brief rule alone doesn't stop the bug.
4. **Re-run full `/product` pipeline on a fresh dogfood** to validate skill changes. Rejected: cost (~90-120min) vs benefit (we already have a broken dogfood to retro-fix; if the fix patterns work there, the brief rule will be inherited by future runs). Re-run can be the first real founder invocation.
5. **Patch the skeleton's `layout.tsx` to use Next.js 16's metadata API generation function** (`generateMetadata`). Rejected: over-engineering for v1. Static metadata + Phase 4 sed-substitution is simpler, equally correct, and matches the rest of the skeleton's static posture.

## Risks

1. **Sed substitution with arbitrary `<idea>` strings.** Founder idea text could contain shell special chars (`&`, `|`, `/`, `'`, `"`). Mitigation: use python instead of sed, or use a unique sed delimiter (`|` since URLs/paths use `/`) AND shell-escape the idea before passing. Document in SKILL.md so future maintainers don't re-introduce the fragility.
2. **PT-BR detection false positive.** A US fintech post mentioning Pix integration could trigger `lang="pt-BR"`. Acceptable v1 risk; flag if it happens. Real fix: explicit `--locale` flag.
3. **Sub-agents ignore the brief rule.** Brief CONSTRAINTS are aspirational, not enforced. Even with the new bullet, a sub-agent might still slap `'use client'` at the top. Mitigation: phrase the rule as a hard NO + name the runtime error verbatim + show the canonical pattern. If recurrence happens, escalate to validator extension.
4. **Dev-server-only smoke-test gap.** The lesson from this whole spec is that tsc + biome don't catch runtime bugs. The right structural fix is to add `pnpm dev` + curl-check + console-error-count to Phase 4 build verification. That's deferred to spec 052 — but worth flagging: this spec patches the SYMPTOMS, not the verification gap.
5. **Spec 048 + 049 dogfood retro-fix divergence.** The dogfood at `/tmp/dogfood-erp/` was generated under spec 048's brief; retro-fix is hand-applied. Future fresh runs use spec 051's brief. Two paths to the same shape; documented so the next /product run is the real cross-check.
6. **Browser tab title cached.** When verifying, the browser might show the old title from cache. Hard-refresh (Ctrl+Shift+R) required.

## Execution order

1. Scaffold spec 051 (this file + spec.md + tasks.md) — done by the time this plan is read.
2. Edit SKILL.md Phase 4 stitch step — add substep 3.5 (layout placeholder substitution).
3. Edit delegation-briefs.md Per-stack screen-writer Next.js block — add async/client CONSTRAINTS bullet.
4. Apply title + lang substitution to `/tmp/dogfood-erp/app/layout.tsx`.
5. Apply Server/Client split to 3 broken pages in `/tmp/dogfood-erp/`.
6. Re-test dev server: navigate to /, /check-in/abc123, /prontuario/abc123, /booking/lumiere-haus; capture screenshots; confirm console clean + title correct.
7. Run skill validator (gate C).
8. Commit skill changes (NOT dogfood — /tmp/ is throwaway).

## Notes

- Per CLAUDE.md governance gate, no destructive operations needed (all edits + non-destructive file splits).
- Per `.claude/rules/delegation.md`, no sub-agent dispatches in spec 051 (parent-side mechanical work).
- Per `.claude/rules/tdd.md`, the dogfood retro-fix IS the test (visible end-state validation in browser); no separate test file needed since the skill change is documentation + brief text, not production code.
- The 4 audit findings split: (1)+(2) ship in this spec; (3)+(4)+(validator-dev-smoke-test) are spec 052 candidates.
