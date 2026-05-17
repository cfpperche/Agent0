# Delegation briefs — 5-field templates per subagent type

Every `Agent` tool call dispatched by `/prototype` MUST use the 5-field handoff per `.claude/rules/delegation.md` (TASK / CONTEXT / CONSTRAINTS / DELIVERABLE / DONE_WHEN). The delegation-gate hook returns exit 2 otherwise — undercount means the skill mid-aborts.

These templates are the canonical shape. Substitute `{{...}}` placeholders inline before dispatch.

## Phase 2 — Subagent A — Sitemap generator

```
TASK: Produce sitemap.yaml for the {{persona}} {{product_class}} product idea "{{idea}}".

CONTEXT: Read .claude/skills/prototype/references/sitemap-schema.md for the schema (required fields per route, validation rules, 5 required_categories). The prototype targets {{platform}} stack {{stack}}. Persona: {{persona_one_liner}}. Product class: {{product_class}} (drives minimum screen count).

CONSTRAINTS:
- Schema-conformant — required_categories MUST include marketing/auth/primary/admin/error; minimum {{min_screens}} routes for the product class.
- Per-route fields complete: path / category / states / covers_us / components.
- Components in PascalCase; component names should be reusable across routes where sensible.
- No proprietary brand references in path or copy hints.

DELIVERABLE: sitemap.yaml file at /tmp/prototype-{{slug}}/sitemap.yaml (full path).

DONE_WHEN: File exists at the deliverable path; parses as YAML; passes the validation rules in sitemap-schema.md (all 5 categories present, ≥ {{min_screens}} routes, per-route fields complete).
```

## Phase 2 — Subagent B — Brand + tokens

```
TASK: Produce tokens.css (CSS custom properties, semantic naming) and brand-voice.md (3 sample copy strings) for the {{persona}} {{product_class}} product idea "{{idea}}".

CONTEXT: Read packages/mcp-product-pipeline/src/templates/06-design-system/references/ for Open Design grounding catalog patterns. Persona: {{persona_one_liner}}. {{skip_brand_clause}}.

CONSTRAINTS:
- tokens.css uses semantic naming (--color-primary, --space-md, --radius-sm) NOT brand-naked (no --color-blue-500). Includes color (foreground/background/primary/accent), spacing (xs/sm/md/lg/xl), radius (sm/md/lg), font (family-sans/mono, size scale).
- brand-voice.md has exactly 3 sample copy strings: one ON-brand line + one OFF-brand counterexample + one persona-specific microcopy fragment. Each ≤ 30 words.
- No proprietary brand references; tone is appropriate to the persona.

DELIVERABLE: Two files at /tmp/prototype-{{slug}}/: tokens.css and brand-voice.md.

DONE_WHEN: Both files exist at deliverable paths; tokens.css is valid CSS (parses without errors); brand-voice.md has exactly 3 sample strings with the labels ON-brand / OFF-brand / persona-specific.
```

For `--skip-brand` invocations, substitute `{{skip_brand_clause}}` with: `Use bundled defaults from .claude/skills/prototype/templates/default-tokens.css verbatim; for brand-voice.md, use neutral professional tone (no persona-specific tuning needed since the founder opted out).`

## Phase 2 — Subagent C — Monorepo scaffolder

```
TASK: Scaffold a minimal {{stack}} monorepo at /tmp/prototype-{{slug}}/ from the bundled template.

CONTEXT: Read .claude/skills/prototype/references/stack-defaults.md for stack version + structure facts. Use .claude/skills/prototype/templates/monorepo-skeleton/{{stack}}/ as the byte-source — copy verbatim into /tmp/prototype-{{slug}}/, then run install.

CONSTRAINTS:
- Use cp -r (not symlinks) so the prototype is self-contained.
- Run the install step per stack (next: pnpm install; expo: bun install). Verify exit 0 and capture the duration.
- DO NOT modify the bundled template files — copy-only. If the template needs changes for this prototype, that's a template bug to surface in your handoff, not an inline fix.
- Total wall-clock budget: 3 minutes for install. If install takes longer, mark dep-install-status: "slow (Ns)" but don't fail.

DELIVERABLE: A working monorepo at /tmp/prototype-{{slug}}/ with node_modules/ populated.

DONE_WHEN: Directory exists with package.json + tsconfig.json + (next.config.* OR app.json) + node_modules/; pnpm dev / bunx expo start can launch (don't actually launch — verify the script is wired in package.json); return field dep-install-status: "ok|slow Ns|failed: <reason>" in your handoff response.
```

## Phase 2 — Subagent D — PRD-1pager

```
TASK: Produce prd-1pager.md for the product idea "{{idea}}".

CONTEXT: Read .claude/skills/prototype/templates/prd-1pager.md.tmpl for the Lenny hybrid shape. Persona: {{persona_one_liner}}. Product class: {{product_class}}. {{skip_prd_clause}}.

CONSTRAINTS:
- Strict 1-page discipline: ≤ 3 bullets per section.
- 7 sections (Problem · Why now · Release scope · NSM · Top 3-5 user-stories · Anti-goals · Upstream/downstream refs).
- User-stories are concrete ("user clicks X, sees Y"), not hand-wavy ("user has good experience").
- No marketing language ("revolutionary", "best-in-class") — straight prose.

DELIVERABLE: prd-1pager.md at /tmp/prototype-{{slug}}/prd-1pager.md.

DONE_WHEN: File exists; all 7 section headers present; each section has 1-3 bullets; total line count ≤ 60 (1-page test).
```

For `--skip-prd` invocations: this entire subagent is NOT dispatched (skill marks SKIPPED in REPORT.md).

## Phase 3 — Screen-writer (per-stack template)

Dispatched ONCE PER ROUTE, capped at 5 concurrent. Brief is templated per stack:

### Phase 3 brief — Next.js stack

```
TASK: Write the Next.js page file for route {{path}} in the {{slug}} prototype.

CONTEXT:
- Sitemap entry: {{route_yaml_excerpt}} (path / category / states / covers_us / components)
- Tokens: /tmp/prototype-{{slug}}/tokens.css (semantic CSS custom properties — use these, not hard-coded values)
- Voice: /tmp/prototype-{{slug}}/brand-voice.md (match the ON-brand sample tone for all copy)
- Stack defaults: .claude/skills/prototype/references/stack-defaults.md § Next.js 16 stack
- Target file location: /tmp/prototype-{{slug}}/app{{path_to_file_path}}/page.tsx (root `/` → app/page.tsx; `/login` → app/login/page.tsx; nested → mkdir as needed)

CONSTRAINTS:
- ≤ 3 component definitions per file (extract more into separate files if needed, but keep this route's file lean).
- No inline state machines — use useState + conditional rendering for the declared states (loading/empty/error/default).
- Token reads via CSS custom properties (var(--color-primary)) or Tailwind utility-classes that map to tokens (do not hard-code `#3B82F6` or `12px`).
- Implement ALL states declared in the sitemap entry; for primary-category routes, ALWAYS implement default + loading + empty + error.
- Use components from the sitemap entry's components list where applicable; if a component doesn't exist, create a placeholder inline at the top of the file.
- No external API calls — this is a prototype, use mock data inline or in a /tmp/prototype-{{slug}}/lib/mock-data.ts file.
- Soft token budget: 4000 tokens output (one file's worth; aggressive trimming over comprehensive coverage).

DELIVERABLE: The page.tsx file written at the target location; if a /lib/mock-data.ts file was added, that too.

DONE_WHEN: File exists at deliverable path; valid TypeScript (will be verified by Phase 4 typecheck); declared states are visibly implemented (a Phase 4 inspection will score this).
```

### Phase 3 brief — Expo stack

```
TASK: Write the Expo (expo-router) screen file for route {{path}} in the {{slug}} prototype.

CONTEXT:
- Sitemap entry: {{route_yaml_excerpt}}
- Tokens: /tmp/prototype-{{slug}}/tokens.css mapped via NativeWind tailwind.config.js → utility classes (use className for styling)
- Voice: /tmp/prototype-{{slug}}/brand-voice.md
- Stack defaults: .claude/skills/prototype/references/stack-defaults.md § Expo SDK 55 stack
- Target file location: /tmp/prototype-{{slug}}/app{{path_to_file_path}}.tsx (root `/` → app/index.tsx; `/login` → app/login.tsx; nested → mkdir as needed)

CONSTRAINTS:
- Same as Next.js brief, with React Native components (View, Text, Pressable, TextInput, FlatList) instead of HTML
- className via NativeWind for styling (not StyleSheet.create); use the token classes from tailwind.config.js
- No external API calls; mock data inline or in /tmp/prototype-{{slug}}/lib/mock-data.ts
- Soft token budget: 4000 tokens output

DELIVERABLE: The screen .tsx file written at the target location.

DONE_WHEN: File exists at deliverable path; valid TypeScript; declared states are implemented.
```

## Concurrency cap

Phase 3 dispatches MAX 5 concurrent `Agent` calls. If sitemap has > 5 routes, queue the rest and dispatch as earlier ones return. **Plan Risk #1 noted that 5 may be too high under context pressure — observe during dogfood and drop to 3 if OOM signals.**

## Failure handling

If any subagent dispatch returns failure (validator rejects DELIVERABLE, or the agent's handoff response indicates inability), the skill marks that route as `BLOCKED` in REPORT.md and continues with the rest. The whole prototype build does NOT fail on a single bad screen — partial success is recorded for human triage.
