# 027 — Open Design vendor port into `mcp-product-pipeline`

**Status:** shipped

## Intent

Vendor the Open Design bundle (Apache-2.0, `nexu-io/open-design`) **inside** `packages/mcp-product-pipeline/` so the MCP server can ground its prototype-stage outputs (step 2, future step 7 prototype-v2) in 73 named design systems (Linear, Notion, Stripe, Wise, …) and 33 skill bundles — replacing the current "agent invents palette/typography from training data" path with "agent reads a vendored, pinned `DESIGN.md` and a vendored `SKILL.md`".

The anthill project pioneered this architecture (ADR `.anthill/memory/architecture/adr-vendor-open-design.md`, EPIC #568, 8-PR sequence). Anthill's pivota benchmark (2026-04-30) materially elevated step 2 output quality across all 3 directions — each one citing a different DS as its compositional source. That citation chain is the wedge: 3 mood boards are genuinely distinct because their grounding sources are distinct, not because the agent prompt-engineered variety from a single mental model. Spec 026 Phase B step 2 currently describes the OD pipeline structurally in `references/pipeline.md` without the vendored content — this spec closes that gap.

## Why now

- Spec 026 Phase B task 11 (step 2 prototype port) shipped 2026-05-13 with the OD pipeline described inline rather than backed by vendored assets. User flagged on the same day: this proved "de extremo valor" in anthill, needs to land in our MCP.
- Step 13 (future stack-native prototype-v2) and any future "branded prototype" capability will have the same dependency. Porting once now avoids re-confronting the architecture decision twice.
- The anthill repo is the canonical reference and is **archived as of 2026-05-13** — capture the design while the implementation is still fresh and grep-able.

## Acceptance criteria

### Vendor layout

- [ ] `packages/mcp-product-pipeline/vendor/open-design/MANIFEST.json` exists, schema-validated, with `pinned_sha` (40-hex), `pinned_at`, `last_check_sha`, `last_check_at`, `vendored_paths[]` (each with `{src, dst, kind, recursive?, checksum: sha256:...}`), `license_attribution[]`, `history[]` (append-only `bump`/`apply`/`check`).
- [ ] `packages/mcp-product-pipeline/vendor/open-design/LICENSE` is Apache-2.0 verbatim copy from upstream `nexu-io/open-design`.
- [ ] `packages/mcp-product-pipeline/vendor/open-design/NOTICE` carries per-subtree attribution (Apache-2.0 root + MIT guizang-ppt + MIT design-systems derivatives), copied verbatim from anthill's NOTICE.
- [ ] `packages/mcp-product-pipeline/vendor/open-design/.LICENSE.provenance` records the extraction SHA and date.
- [ ] `packages/mcp-product-pipeline/design-systems/` (sibling drawer — NOT under `vendor/`) contains the 73 `DESIGN.md` directories, populated by `--apply`. The sibling-vs-vendor split mirrors anthill (`.anthill/design-systems/` vs `.anthill/vendor/open-design/`).
- [ ] `packages/mcp-product-pipeline/vendor/open-design/skills/` contains the 33 skill bundles (each: `SKILL.md` + `assets/` + `references/`). `INDEX.json` from upstream is preserved.
- [ ] `packages/mcp-product-pipeline/vendor/open-design/prompts/{system,discovery,directions}.ts` contains the 5-school canonical visual-school exports + discovery schema.
- [ ] `packages/mcp-product-pipeline/vendor/open-design/frames/{iphone-15-pro,macbook,browser-chrome}.html` and `templates/deck-framework.html` are present.

### Sync engine

- [ ] **Scenario: --check is read-only** — **Given** `MANIFEST.json` is pinned at SHA `X`; **When** a maintainer runs `bun packages/mcp-product-pipeline/scripts/sync-open-design.ts --check`; **Then** the script fetches upstream HEAD via `git ls-remote` (no auth, no rate limit), writes a daily report to `packages/mcp-product-pipeline/runtime/od-sync/YYYY-MM-DD.md`, updates `last_check_sha`/`last_check_at` in the manifest, and the report flags drift if upstream HEAD differs from `X`. No vendored files mutated.
- [ ] **Scenario: --bump updates manifest only** — **Given** a new upstream SHA `Y`; **When** a maintainer runs `--bump Y --reason "<≥10-char message>"`; **Then** the manifest's `pinned_sha`/`pinned_at` updates to `Y`, a `history[]` event of `{event: "bump", sha: Y, at: <ISO>, reason: …}` is appended, and no vendored files are touched. `--bump` rejects when the SHA does not exist upstream.
- [ ] **Scenario: --apply extracts vendored content** — **Given** the manifest is pinned at SHA `X`; **When** a maintainer runs `--apply`; **Then** the script downloads the tarball at `X`, extracts each `vendored_paths[]` entry to its `dst`, computes per-tree sha256 checksums and writes them back to the manifest, validates each `DESIGN.md` has required H2 sections, writes provenance headers to text files (per anthill's `provenanceHeader` shape), appends a `history[]` event of kind `apply`, and exits 0.
- [ ] **Scenario: hand-edits to vendored files are detected** — **Given** `vendor/open-design/skills/web-prototype/SKILL.md` was edited after `--apply`; **When** the package's `prepublishOnly` check runs (or a maintainer invokes `--check`); **Then** the per-path checksum mismatch is reported on stderr and exit is non-zero, blocking publish until `--apply` is re-run from the pinned SHA.

### Distribution

- [ ] The vendor tree is published as part of the npm tarball for `agent0-mcp-product-pipeline`. Consumers receive the assets via `npm install` — no separate "install assets" tool, no consumer-side write step, no daemon fetch.
- [ ] `package.json` `files` field (or `.npmignore`) is configured so `vendor/` and `design-systems/` ship with the package; `runtime/` is excluded.
- [ ] The published package size is documented in spec 027's `plan.md` (anthill's tree is ~3.1 MB; expect the same order of magnitude).

### MCP integration

- [ ] **Scenario: agent can list available design systems** — **Given** the MCP server is running with the vendored tree present; **When** the agent calls a new MCP tool `product_design_systems_index` (or equivalent); **Then** the tool returns a one-line manifest of all 73 systems with `{name, mood_summary, palette_summary}`, sourced from a `vendor/open-design/design-systems/INDEX.json` or a generated `ds-index.json`. The tool does NOT walk the filesystem on every call.
- [ ] **Scenario: agent can read a specific DESIGN.md** — **Given** the agent picked `linear-app` for Direction A; **When** the agent calls an MCP tool returning the resolved vendor path; **Then** the agent can `Read` `<consumer-node_modules-path>/agent0-mcp-product-pipeline/design-systems/linear-app/DESIGN.md` directly. (Path resolution: the MCP tool returns the absolute path, the agent's Read tool reads it — no MCP-side file-content streaming.)
- [ ] **Scenario: step 2 template is updated to require DS citation** — **Given** the OD vendor is available; **When** an agent executes step 2 prototype; **Then** a ported `references/od-bridge.md` (modelled on anthill's consumer-doc) teaches the agent the pre-flight read sequence (DESIGN.md → SKILL.md → template.html → layouts.md → checklist.md), `references/pipeline.md` is simplified to point at it, and the agent composes each direction from 1-4 vendored design systems and cites them by name in the REPORT — replacing the current "inline 5-school description" approach.

### Provenance integrity (in-package, not Agent0 hook)

- [ ] A `prepublishOnly` script in `packages/mcp-product-pipeline/package.json` runs `bun scripts/sync-open-design.ts --verify` which checks per-path checksums match the manifest. Drift → non-zero exit → npm publish blocked.
- [ ] A `postinstall` script (in the package, not Agent0) is **NOT** added — postinstall is reserved for unavoidable native build steps; per the anthill pattern, content tampering is a build-time concern, not an install-time concern. Documented as explicit non-goal.

## Non-goals

- **No Agent0-level hook.** Per user constraint 2026-05-13: anthill's `.claude/hooks/vendor-edit-block.sh` does NOT port to `Agent0/.claude/hooks/`. The protection moves into the package via the `prepublishOnly` verifier (above) and developer-facing documentation in `packages/mcp-product-pipeline/vendor/open-design/README.md`. The MCP package's own `.claude/` surface (if it ever has one) MAY ship a fork-local hook, but Agent0's harness inventory does not absorb it.
- **No automated bump.** `--bump` is manual, same as anthill. Automated CI bumps require write access + a content-review step that no script can perform credibly.
- **No upstream-tracker daemon.** `--check` is invoked manually (or by the maintainer's cron locally). A scheduled GitHub Action is allowed in a follow-up spec but is not in scope here.
- **No daemon-fetch / runtime download.** Rejected for the same reasons anthill rejected it (offline-ability, determinism, audit). Vendored = shipped.
- **No selective subtree opt-in.** Consumers either get the whole vendor tree or none of it. A future spec can split the package into `agent0-mcp-product-pipeline-core` + `agent0-mcp-product-pipeline-assets` if the ~3 MB becomes a real adoption blocker.
- **No partial vendor.** All 73 design systems, all 33 skill bundles, all prompt sources are vendored — anthill's manifest takes `skills/` and `design-systems/` as recursive whole-tree, and we mirror exactly. Pruning to "just web-prototype + saas-landing" was considered and rejected: it regresses OD capability the moment a later visual step (5/6/7/13) needs a skill we pruned, and the ~3 MB cost is already accepted by the package-split escape hatch above. See § Findings, finding 1.
- **No fork of `nexu-io/open-design`.** We track upstream by SHA pin, same as anthill.

## Findings from anthill consumption analysis

Traced 2026-05-14 — *where* anthill actually consumes the vendor, not just *how* it stores it.

**Three consumers in anthill:**
- `.claude/skills/anthill-prototype/SKILL.md` — the `mode=html-mockup` path. The skill discriminates `stack-native` vs `html-mockup`; only the latter consumes OD.
- `.claude/skills/anthill-prototype/references/od-bridge.md` (187 LOC) — the consumer-facing doc that teaches the agent the read sequence and the pipeline (discovery form → direction picker → pre-flight reads → build → 5-dim critique gate).
- `scripts/inject.sh` (lines 304-305) — symlinks `.anthill/vendor/open-design/` into the consumer project when anthill is injected. This is anthill's distribution model.

**Consumption pattern:** the agent reads vendored files directly with its `Read` tool, using paths learned from `od-bridge.md`. The vendor is a **catalogue of files to Read**, not a content-streaming API. Per-build pre-flight read order: `DESIGN.md` → `SKILL.md` → `assets/template.html` → `references/layouts.md` → `references/checklist.md`; plus `prompts/discovery.extracted.md` (discovery form) and `prompts/directions.extracted.md` (5-school direction picker).

**Implications for this spec:**

1. **Vendor the full bundle — no partial vendor.** All 73 design systems, all 33 skill bundles, all prompt sources. Step 2 today consumes `web-prototype`; future visual steps (5 brand, 6 design-system, 7 prototype-v2, 13 prototype-v3) will consume more. A partial vendor regresses OD capability the moment a later step needs a pruned skill — not worth the ~couple-hundred-KB saving. The full ~3.1 MB is the accepted cost; the package-split escape hatch in Non-goals stays available if adoption ever demands it. (Codified in Non-goals § *No partial vendor*.)

2. **Port `od-bridge.md` as the consumer-doc pattern.** Anthill's `references/od-bridge.md` is the doc that turns "vendored files exist" into "agent knows the read sequence". The Agent0 equivalent lives at `packages/mcp-product-pipeline/src/templates/02-prototype/references/od-bridge.md` and replaces the current inline 5-school description in `pipeline.md`. Each future visual step that consumes OD either gets its own bridge doc or shares this one — a `plan.md` decision.

3. **MCP tools must return absolute resolved paths.** Anthill injects via symlink into the consumer's `.anthill/`, so relative paths work. Our MCP ships inside `node_modules/agent0-mcp-product-pipeline/` and the agent may be working in any consumer directory — relative paths break. `product_design_systems_index` and the DESIGN.md path resolver must return absolute paths into the installed package location, resolved from the MCP server's own `import.meta.url` / `__dirname`. (Reflected in the MCP integration scenarios above.)

## Open questions

1. **`design-systems/` placement inside the package.** Anthill has them at sibling level (`.anthill/design-systems/` next to `.anthill/vendor/`). For the package, two options: (a) `packages/mcp-product-pipeline/design-systems/` (sibling, mirrors anthill exactly) or (b) `packages/mcp-product-pipeline/vendor/open-design/design-systems/` (nested under vendor). Sibling mirrors anthill and keeps `vendor/` semantically "Apache-attributed upstream bundles"; nested is one fewer top-level dir at the package root. Recommend (a) for fidelity; revisit if the package root gets crowded.

2. **DS index file shape.** Anthill's `design-systems/INDEX.json` may already be sufficient as the listing the MCP tool returns. If not, generate `vendor/open-design/.cache/ds-index.json` during `--apply` with `{name, mood, palette_hex_summary}` per DS. The generated index is part of the manifest's checksum tree (so tampering is detected). Recommend: generate at `--apply` time; do not rely solely on upstream INDEX.

3. **`prompts/*.ts` transform — vendor as TypeScript or extract to markdown?** Anthill keeps both forms (`directions.ts` + `directions.extracted.md`) — the `.ts` is source-of-truth, the `.md` is a generated extract for agent reading. Our MCP is TypeScript-native, so we can import the `.ts` directly inside the server. Open: do we also generate the `.md` extracts for agent-facing `Read` calls, or expose the content via an MCP tool that returns the structured data?

4. **Sync script invocation surface in this repo.** Anthill puts the script at `scripts/sync-open-design.ts` (repo root) AND records runtime artifacts at `.anthill/runtime/od-sync/`. For us, both move into the package: `packages/mcp-product-pipeline/scripts/sync-open-design.ts` and `packages/mcp-product-pipeline/runtime/od-sync/`. Confirm: is `runtime/` gitignored or committed? Anthill commits the daily reports (`2026-04-30.md` etc.); we likely do the same for the audit trail.

5. **License attribution placement for the npm package surface.** Apache-2.0 § 4(c) requires that derivative works "retain, in the Source form of any Derivative Works that You distribute, all copyright … notices … and ... include a readable copy of the attribution notices". The vendor's own `LICENSE` + `NOTICE` + `.LICENSE.provenance` cover the in-tree requirement. Open: does the package's top-level `package.json` need a `license: "Apache-2.0 AND <our-license>"` declaration, or does shipping LICENSE files inside the vendor subtree satisfy npm-level attribution? The Apache-2.0 license is for the *vendored content*, not the package code — but the npm registry doesn't have a granular license-per-path concept.

6. **Fail-loud vs. graceful-degrade when the vendor is absent at runtime.** The vendor ships *inside* the npm package — a missing or partial `vendor/open-design/` tree at consumer runtime means a broken install, not a legitimate runtime condition (`prepublishOnly` already blocks tampered publishes; upstream changes don't reach a pinned consumer). Two postures: (a) **fail loud** — the MCP tool that resolves vendor paths detects the missing tree and returns a clear, actionable error (`OD vendor missing at <path> — reinstall agent0-mcp-product-pipeline`); no automatic fallback. (b) **graceful-degrade** — the MCP silently falls back to the pre-OD inline-5-schools path. Recommendation: **(a) fail loud.** Rationale: a silent fallback produces measurably worse output (no DESIGN.md grounding, no citation chain) without telling the operator *why* quality dropped — and the project's CLAUDE.md rule explicitly says not to build fallbacks for scenarios that can't legitimately happen. **However**, the inline 5-school description should be **retained in `pipeline.md` as documentation / a manual escape**, not wired as an automatic fallback — so an operator hitting the fail-loud error can consciously choose the pre-OD path. Degradation stays explicit and chosen, never silent. Decision needed in `plan.md`: confirm posture (a), and confirm the inline content stays as documented escape rather than being deleted when `pipeline.md` is simplified per the step-2 scenario above.

## References

- Anthill ADR: `~/anthill/.anthill/memory/architecture/adr-vendor-open-design.md` — full rationale + rejected alternatives (submodule, fork, daemon-fetch).
- Anthill sync script: `~/anthill/scripts/sync-open-design.ts` (659 LOC) — the canonical implementation to port. 3 subcommands (`--check`, `--bump`, `--apply`), tarball extraction, per-path checksum, provenance header injection, DESIGN.md H2 validation.
- Anthill manifest schema: `~/anthill/.anthill/schemas/od-vendor-manifest.schema.json` — JSON Schema for `MANIFEST.json` shape.
- Anthill vendor-edit hook: `~/anthill/.claude/hooks/vendor-edit-block.sh` — the protection mechanism this spec deliberately does NOT port verbatim (moves to `prepublishOnly` instead per user constraint).
- Anthill consumer skill: `~/anthill/.claude/skills/anthill-prototype/SKILL.md` + `references/od-bridge.md` — *where* anthill consumes the vendor; `od-bridge.md` is the consumer-doc pattern to port (see § Findings).
- Anthill injection: `~/anthill/scripts/inject.sh` lines 304-305 — symlink-based distribution; does NOT translate to our npm model (see § Findings, finding 3).
- Anthill memory: `~/anthill/.anthill/memory/architecture/session-2026-04-30-od-vendor-wave.md` — the implementation session log; useful for catching gotchas not in the ADR.
- Upstream: `https://github.com/nexu-io/open-design` (Apache-2.0).
- Agent0 spec 026 Phase B: `docs/specs/026-mcp-pipeline-deep-port/` — the consuming work; step 2 currently ships without OD vendor (interim) and step 2's `references/pipeline.md` simplifies once this spec lands.
- Project memory: `.claude/memory/od-vendor-port-plan.md` — informal port plan that this spec formalizes.
