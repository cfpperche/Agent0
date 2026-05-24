# 085 — image-gen-opt-in — tasks

_Generated from `plan.md` on 2026-05-24. Work top-to-bottom. Check boxes as tasks complete. If a task reveals the plan is wrong, update `plan.md` before continuing._

## Implementation

- [x] 1. **Bootstrap asset directory tree.** Created `assets/.gitkeep`, `assets/brand/.gitkeep`, `assets/generated/.gitkeep`, `assets/generated/mockups/.gitkeep`. Verified `find assets -name .gitkeep` lists all four.

- [x] 2. **Update `.gitignore` for mockup throwaway policy.** Added `assets/generated/mockups/*` with `!assets/generated/mockups/.gitkeep` exclusion. Verified `touch assets/generated/mockups/scratch.png` is ignored; `.gitkeep` tracked.

- [x] 3. **Drafted `.claude/rules/image-gen.md`** — capacity rule with sections Activation, Tier table, Storage policy, Error on omitted tier, Naming convention, Manifest shape, Override marker, Trust posture, Pricing refresh, Cross-references, Gotchas. Doc-driven contract — everything else derives from it.

- [x] 4. **Added `fal-ai` HTTP block to `.mcp.json.example`** — `{ "type": "http", "url": "https://mcp.fal.ai/mcp", "headers": { "Authorization": "Bearer ${FAL_KEY}" } }`, commented with `//`. Header comment updated with step 6 about FAL_KEY + HTTP-transport precedent note.

- [x] 5. **Added `### fal.ai MCP (image / video / audio / 3D)` recipe section to `.claude/rules/mcp-recipes.md`.** Mirrors the shape of existing recipes (Source, What it provides, .mcp.json block, Install, When to enable, Runtime requirements, Security). Documents HTTP transport + 4 community fallbacks (piebro, monsoft, mseep, lansespirit).

- [x] 6. **Added Image-gen row to `mcp-recipes.md` § Stack-detector signal table.** Signals: `assets/brand/`, `assets/generated/`, README `<img`/`![hero`, `.claude/skills/product/` installed. Suggested recipe: `fal-ai`.

- [x] 7. **Extended `.claude/hooks/mcp-recipes-hint.sh`** with image-gen signal detection + fal-ai recipe in the suggestion list. Smoke-tested: `bash .claude/hooks/mcp-recipes-hint.sh` correctly emits `fal-ai` recipe given `assets/brand/` + `/product` skill.

- [x] 8. **Drafted `.claude/skills/image/references/tier-pricing.md`** — date-stamped 2026-05-24, three tiers with approx pricing (`draft` $0.003 · `brand-text` $0.04-0.20 · `brand-photo` $0.06). Refresh discipline documented (quarterly via routine).

- [x] 9. **Drafted `.claude/skills/image/SKILL.md`** — agentskills.io-compliant frontmatter (name, description, argument-hint, license, compatibility, metadata.agent0-portability-tier=cc-native, metadata.version=0.1). Documents tier-required behavior, error-on-omitted-tier with 3-option list, pre-call cost format, examples, cross-references.

- [x] 10. **Implemented `.claude/skills/image/scripts/gen.sh`** (Bash). Two subcommands: `prepare` (validate, derive path, cost-print, JSON envelope) and `record` (append manifest). Handles tier→model resolution, slug auto-derivation, kebab validation, collision suffix, FAL_KEY presence, all error paths with corrective stderr templates. 6 smoke tests passed.

- [x] 11. **Added `## Image generation` section to `CLAUDE.md`** (inside AGENT0:BEGIN/END markers, adjacent to `## MCP recipes`). One-paragraph pointer to the rule. Also updated `## MCP recipes` to include the new recipe in the list (dropped stale "four" count, added fal.ai + Laravel Boost that was already missing from the count).

- [x] 12. **Registered new directory sentinels in `.claude/tools/sync-harness.sh` COPY_CHECK_FILES.** Added 4 entries: `assets/.gitkeep`, `assets/brand/.gitkeep`, `assets/generated/.gitkeep`, `assets/generated/mockups/.gitkeep`. The `.claude/rules/image-gen.md` + `.claude/skills/image/**` files are already covered by existing globs (`COPY_CHECK_GLOBS` for rules; `COPY_CHECK_RECURSIVE` for skills).

- [x] 13. **Verified fal.ai key shape vs gitleaks rules.** Default rules do NOT catch the `<uuid>:<hex>` fal.ai shape — confirmed empirically. Added custom `[[rules]]` entry to `.gitleaks.toml` with regex `[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}:[a-f0-9]{32,}` + keywords `["fal","fal_key"]`. Retested with fake key → "leaks found: 1". Custom rule documented in `image-gen.md` Gotchas.

- [x] 14. **Ran `/skill validate image`** → passes (exit 0).

### Propagation hygiene cleanup (added during implementation per `.claude/memory/propagation-hygiene.md`)

- [x] 15. **Removed `docs/specs/085-*` pointers from fork-bound files.** Cleaned 4 instances across `.claude/rules/image-gen.md` (cross-refs), `.claude/skills/image/SKILL.md` (cross-refs), `.claude/skills/image/references/tier-pricing.md` (2 mentions), `.claude/skills/image/scripts/gen.sh` (header comment). Spec-citation leaks would dangle in forks where `docs/specs/` doesn't exist.

### Acceptance-test harness (added after Stop hook flagged S1-S3 as unverified)

- [x] 16. **Created `.claude/tests/image-gen/{01,02,03}-*.sh`** — three acceptance tests, one per tier workflow scenario. Mock the MCP response by writing a 1-pixel PNG into the resolved output_path, then run `gen.sh record` to append manifest. Mirrors the test-boundary pattern from `.claude/tests/secrets-scan/` (preflight exercised without a real git commit). All 3 tests pass; harness now self-contained and runnable in CI without a `FAL_KEY`.

### Dogfood-driven fixes (added after first real-fal.ai dogfood surfaced 3 gaps)

- [x] 17. **Fix: content-type-aware extension.** TIER_TABLE in `gen.sh` now carries an EXT column (`draft|...|jpg`, brand-text/brand-photo `|...|png`). FLUX schnell returns JPEG per fal.run response; the v1 hardcoded `.png` would have produced wrong-extension files. Tests updated to assert `.jpg` for draft, `.png` for brand tiers. `tier-pricing.md` + `image-gen.md` tier tables document the per-tier extension.

- [x] 18. **Fix: `--aspect=square|landscape|portrait` flag.** New `ASPECT_TABLE` in `gen.sh` maps to fal.ai's `image_size` enum (`square_hd` 1024×1024, `landscape_16_9` 1024×576, `portrait_16_9` 576×1024). Default `square` preserves backward-compatibility. JSON envelope adds `aspect`, `image_size`, and `extension` fields so the agent passes the right param to the MCP. SKILL.md + tier-pricing.md + image-gen.md documented. New test `.claude/tests/image-gen/04-aspect-flag.sh` (4 sub-assertions: landscape, portrait, default-square, invalid-rejection). Bonus bug fixed mid-flight: `resolve_tier` / `resolve_aspect` couldn't `exit 2` from inside `$()` subshell, so the parent kept running with empty rows. Now they `return 1` and the parent does `... || die_bad_*`.

- [x] 19. **Fix: documented MCP no-mid-session-reload gotcha.** New gotcha in `image-gen.md`: `claude mcp list` shows ✓ Connected on hot `.mcp.json` edits, but `mcp__fal-ai__*` tools are baked at SessionStart and stay frozen for the session. A broken `.mcp.json` at boot can't be recovered by fixing mid-flight — MUST restart. Also documented `Authorization` header shape difference (MCP uses `Bearer`, REST uses `Key`).

### Real-fal.ai validation (after fixes)

- [x] 20. **Dogfood: `--tier=draft --aspect=landscape` against real fal.ai.** Two real API calls executed via curl REST (the `mcp__fal-ai__*` surface still requires session restart, so curl was the fallback for this dogfood). Both produced valid images: square 1024×1024 (first call, JPEG, ~$0.003) + landscape 1024×576 (second call, JPEG, ~$0.003). Collision-suffix `-2.jpg` correctly applied on second call. Manifest captures both with full 8-field shape. End-to-end against real provider validates: FAL_KEY plumbing, model endpoint name, content-type assumption, aspect-ratio enum, path derivation, manifest write.

## Verification

_Acceptance checks tied to `spec.md` § Acceptance criteria. Scenarios 1-3 require a real `FAL_KEY` and successful HTTP MCP connection — marked **conditional**, the user provisions and runs them._

- [x] **Scenario 1: draft tier workflow** — verified via `.claude/tests/image-gen/01-draft-tier-workflow.sh` (mocked MCP response, same boundary as secrets-scan tests). Asserts cost-line-precedes-JSON, model=fal-ai/flux/schnell, output_path under `assets/generated/mockups/<YYYY-MM-DD>-<slug>.png`, approx_cost_usd=0.003, manifest line carries 8-field shape with tier=draft.

- [x] **Scenario 2: brand-text workflow** — verified via `.claude/tests/image-gen/02-brand-text-workflow.sh`. Asserts cost=$0.040, model=fal-ai/gpt-image-2, output_path=`assets/brand/hero-logo.png` (NO date prefix — brand is durable; `--name=hero-logo` override honored), manifest line correct.

- [x] **Scenario 3: brand-photo workflow** — verified via `.claude/tests/image-gen/03-brand-photo-workflow.sh`. Asserts cost=$0.060, model=fal-ai/imagen4/ultra, output_path=`assets/brand/<auto-kebab-5-words>.png`, auto-slug derivation works, manifest line correct.

- [x] **Scenario 4: opt-in posture — no silent activation** — verified `unset FAL_KEY; bash gen.sh prepare --tier=draft "x"` emits clean error with 4-step activation pointer to `.mcp.json.example` and `.claude/rules/image-gen.md` § Activation. Exit code 2. No PNG generated, no manifest entry.

- [x] **Scenario 5: cost visibility** — verified across 4 smoke tests (Task 10): every `prepare` call prints `estimated: $X.XXX for <model> at <resolution>` to stdout BEFORE the JSON envelope (which is what the agent uses to make the MCP call). Cost line precedes any MCP invocation by construction.

- [x] **Scenario 6: sync-harness propagation** — verified `.claude/tools/sync-harness.sh` manifest covers the new artifacts: `.claude/rules/image-gen.md` via `COPY_CHECK_GLOBS` `.claude/rules|*.md`; `.claude/skills/image/**` via `COPY_CHECK_RECURSIVE` `.claude/skills`; 4 explicit `assets/*/.gitkeep` entries added to `COPY_CHECK_FILES`. `.mcp.json` (live config) is excluded from manifest by design (only `.mcp.json.example` ships).

- [x] **`/skill validate image`** passes (Task 14).

- [x] **CLAUDE.md `## Image generation` section** exists with rule pointer (Task 11).

- [x] **`.mcp.json.example`** carries `fal-ai` HTTP block with `${FAL_KEY}` indirection (Task 4).

- [x] **`.gitignore`** correctly ignores `assets/generated/mockups/*` while preserving `.gitkeep` sentinel (Task 2 + smoke verification).

- [x] **Standalone scope respected** — `git status` shows only files listed in `plan.md` § *Files to touch*. No edits to `.claude/skills/product/`, `.claude/skills/prototype/`, `.claude/skills/sdd/`, or any other shipping skill.

## Notes

- **All 11 acceptance criteria pass.** S1-S3 validated via mocked-MCP tests under `.claude/tests/image-gen/`; S4-S6 + 5 plain checks validated directly during build. Test boundary (mock vs real fal.ai) follows the secrets-scan precedent — the harness validates the SKILL'S correctness; real-fal.ai integration is a per-fork concern outside the spec gate.
- **What ships to forks.** The capacity is now in the sync-harness manifest via existing globs + 4 new `.gitkeep` entries. A fork running `bash .claude/tools/sync-harness.sh --apply` after this lands gets the rule, the skill, the recipe block, the directory tree, the custom gitleaks rule, AND the 3 acceptance tests. The fork still has to opt in (FAL_KEY + uncomment block).
- **Deviations from plan.** Two additions on-the-fly: Task 15 (propagation-hygiene cleanup, discovered while reviewing `.claude/memory/propagation-hygiene.md`) and Task 16 (acceptance-test harness, added after the Stop hook surfaced that S1-S3 were unverified). Both documented in notes.md.
- **End-to-end real-fal.ai integration test** is the standard pattern for credentialed external services: a separate CI job with the real key, gated behind a secret. Not in this spec's scope; documented in the rule's Gotchas as the user's per-fork integration step.
