# Quality checklist — `/prototype` skill

Materializes the spec 034 § Quality bar into a checklist the skill enforces in Phase 4 (stitch + verify + REPORT.md). Each item maps to a REPORT.md section.

## 1. Sitemap completeness (binary)

- All 5 `required_categories` present in `sitemap.yaml` → ✓ otherwise gap-audit entry per missing category
- Per-route fields complete per `sitemap-schema.md` Rules 4-6 → ✓ otherwise REPORT.md flags malformed routes
- Minimum screen count by product class met (Micro ≥6 / Mobile ≥12 / Dev Tool ≥12 / SMB SaaS ≥12 / Venture ≥20) → ✓ otherwise REPORT.md notes "under-target by N screens"

## 2. Design fidelity (4-dim scoring per screen)

Each generated screen file gets a score 1-5 on each of 4 dimensions. **Specificity from the original 5-dim rubric (spec 026 task 22) is dropped — it correlated too tightly with the other 4 to add signal.**

| Dimension | What 5 looks like | What 1 looks like |
|---|---|---|
| **Token** | Every color / spacing / radius / font in the screen reads from `tokens.css` (or NativeWind tailwind config that consumes the tokens); zero hard-coded `#3B82F6` or `12px` | Hard-coded values throughout; tokens.css ignored |
| **Voice** | All copy strings (headings, microcopy, CTA labels, empty-state text) match the persona + on-brand sample in `brand-voice.md` | Generic "Welcome to our app" copy that any product could use |
| **Component** | Each screen uses components named in `sitemap.yaml`'s `components` list for that route; component composition is internally coherent (e.g., FormField, Button, Card matched to the screen's intent) | Random component choices not in the sitemap entry; or one giant inline JSX block |
| **Brief-fit** | Screen renders ALL `states` declared for the route (loading + empty + error per primary screens); `covers_us` user-stories are visibly addressed | Only happy-path renders; states ignored; user-story intent not addressed |

**Threshold:** Primary screens (`category: primary` and `category: auth`) MUST score ≥3/5 on each of the 4 dims. Marketing / admin / error screens are advisory-only — flagged in REPORT.md but don't fail the build.

**Computation:** Skill (Phase 4, inline) reads each screen file + matched sitemap entry + tokens.css + brand-voice.md; scores by inspection per dim; records the 4-dim score in REPORT.md per-screen table.

## 3. States coverage matrix

For each route in `sitemap.yaml`, build a matrix:

```
                  default  loading  empty  error
/                   ✓         ·        ·       ·
/login              ✓         ✓        ·       ✓
/dashboard          ✓         ✓        ✓       ✓
/settings           ✓         ·        ·       ✓
...
```

**Rule:** every state declared in the route's `states` field must be implemented. Primary-category routes MUST have at least `default + loading + empty + error` regardless of what the sitemap declared (skill auto-augments the sitemap entry if missing; gap-audit logs the auto-augmentation).

## 4. Monorepo runs (binary)

- `pnpm install` (or `bun install` for Expo) exits 0 — Phase 2 Subagent C verified; Phase 4 re-verifies after Phase 3 screen-writes land
- Dev server starts via `pnpm dev` (Next.js) / `bunx expo start --web` (Expo for web preview) without errors in first 10 seconds
- `pnpm typecheck` exits 0 — REQUIRED ship gate
- `pnpm lint` exits 0 — REQUIRED ship gate

If any of the above fails, REPORT.md marks the prototype `BUILD_BROKEN` and the skill exits with a stderr block describing the failure + which Phase produced the bad output.

## 5. Skill-self compliance (gate)

`bash .claude/skills/skill/scripts/validate.sh .claude/skills/prototype` exits 0 — this is the spec 033 gate, non-skippable, NOT optional.

## REPORT.md section mapping

Each checklist item lands in REPORT.md:

| Checklist | REPORT.md section |
|---|---|
| 1 — Sitemap completeness | `## Coverage scorecard` (X/Y routes wired, per-category counts, gap-audit) |
| 2 — Design fidelity 4-dim | `## Fidelity scorecard` (per-screen table: route × Token / Voice / Component / Brief-fit) |
| 3 — States coverage matrix | `## States matrix` (the ASCII table above, per-route) |
| 4 — Monorepo runs | `## Build health` (install / dev-server / typecheck / lint stamps with timestamps) |
| 5 — Skill compliance | (not in REPORT.md — verified via `/skill validate prototype` separately, but skill prints the result in Phase 5 handoff) |
