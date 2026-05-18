---
name: od-vendor-port-plan
description: Open Design vendor bundle proved high-value in anthill. RESOLVED in two waves — spec 027 ported it into packages/mcp-product-pipeline/ (2026-05-14); spec 049 re-homed it into .claude/skills/product/ when MCP was discontinued (2026-05-18). This memo is the historical record of the port-plan deliberations.
metadata:
  type: project
---

# OD vendor port plan — RESOLVED (spec 049)

**Status:** RESOLVED 2026-05-18. The vendor now lives inside the `/product` skill at `.claude/skills/product/{design-systems,vendor/open-design,scripts/sync-open-design.ts,schemas/od-vendor-manifest.schema.json,runtime/od-sync}/` — self-contained, no MCP dependency. Sync engine empirically verified at the new location (`--check` ran cleanly 2026-05-18, drift report works; `--verify` confirms 7 paths match MANIFEST). See `docs/specs/049-od-vendor-port-to-skill/` for the resolution; the body below is the historical pre-resolution thinking.

---

# OD vendor port plan (deferred — historical)

## The fact

Anthill vendors the **Open Design** bundle (Apache-2.0, github.com/nexu-io/open-design) at `.anthill/vendor/open-design/` + `.anthill/design-systems/`. In dogfood (pivota benchmark, 2026-04-30), it materially elevated the quality of html-mockup output across all 3 directions of step 2 (prototype). User declared on 2026-05-13: this proved "de extremo valor" — needs to land in our MCP too.

**Why:** the OD bundle replaces "agent invents palette/typography from generic knowledge" with "agent grounds palette/typography in a real, vendored, named design system (Linear, Notion, Stripe, Wise, …)". Anthill's step 2 REPORTs cite which DS each direction composed — Direction A = Linear, B = Wise+Notion, C = Notion×Stripe. That citation chain is what made the 3 mood boards genuinely distinct rather than 3 takes on the same green.

**How to apply:** any future planning around `packages/mcp-product-pipeline/src/templates/02-prototype/` (or future stack-native prototype/v3 in step 13) must consider OD vendor as a real dependency, not a nice-to-have. Without it, our step 2 port can only describe the OD pipeline structurally — it can't ground directions in named DS the way anthill does.

## What OD bundle contains (from anthill `.anthill/vendor/open-design/MANIFEST.json`)

| Subtree | Anthill path | Size | Substance |
|---------|-------------|------|-----------|
| Design systems (73) | `.anthill/design-systems/` | 1.7 MB | One `DESIGN.md` per system. 73 systems: airbnb / airtable / apple / binance / bmw / cal / claude / clay / clickhouse / cohere / coinbase / composio / cursor / elevenlabs / expo / ferrari / figma / linear-app / notion / stripe / wise / + 53 others |
| Skill bundles (33) | `.anthill/vendor/open-design/skills/` | ~700 KB | Two key skills: `web-prototype` (multi-screen app mocks) + `saas-landing` (marketing surface). Each has SKILL.md + assets/template.html + references/{layouts.md, checklist.md} |
| Prompt sources | `.anthill/vendor/open-design/prompts/{system,discovery,directions}.ts` | ~50 KB | TypeScript exports of the 5 canonical visual schools (editorial-monocle / modern-minimal / warm-soft / tech-utility / brutalist-experimental) + discovery form schema |
| Frames | `.anthill/vendor/open-design/frames/{iphone-15-pro,macbook,browser-chrome}.html` | ~20 KB | Device-chrome HTML shells for embedding screen mocks |
| Templates | `.anthill/vendor/open-design/templates/deck-framework.html` | ~10 KB | Pitch-deck framework |
| Provenance | `MANIFEST.json` + `.LICENSE.provenance` + `LICENSE` + `NOTICE` | ~17 KB | `upstream_url` + `pinned_sha` + `last_check_at` + per-path `checksum` + `history` events ("bump" / "apply"). Lets anthill detect drift and re-sync |

Total: **~3.1 MB** vendored under Apache-2.0 (verbatim license + attribution shipped).

## Open architectural questions

These need to be resolved when the port is scheduled — do NOT decide now, just be aware.

1. **Where does the vendor live?** Two natural homes:
   - **(a) Inside the MCP package** — `packages/mcp-product-pipeline/vendor/open-design/`. Ships with `npm install @<scope>/mcp-product-pipeline`. Pro: zero consumer setup. Con: 3.1 MB shipped with every install of the MCP, even consumers who only run steps 1/3/8.
   - **(b) Consumer's project tree** — MCP exposes a `product_install_assets` MCP tool that copies the vendor on first `product_start`. Pro: explicit, mirrors anthill's `.anthill/` shape. Con: MCP servers running outside the project (Claude Desktop, remote) can't write into the consumer's repo.
   - **(c) Hybrid** — bundle in package, surface paths via a `product_get_asset(path)` tool. Pro: works in remote-MCP scenarios. Con: agent has to learn another tool.

2. **Sync mechanism.** Anthill has a manifest with `pinned_sha` + `history` and presumably a `sync-od-vendor.sh` tool. We need parity or simpler. Options: pin SHA in `package.json` and re-vendor on bump (manual), or write an MCP-side script. Lean toward manual until update cadence justifies tooling.

3. **License attribution surface.** Apache-2.0 requires LICENSE + NOTICE shipped. If we go path (a) or (c), they ship with the npm package automatically. If (b), we need to copy them into the consumer's repo.

4. **DESIGN.md selection UX.** Anthill's step 2 picks 1-4 design systems per direction. How does our agent see the list of 73? Options: dump a one-line manifest (`ds-index.json` with `{ name, palette_summary, mood }` per system) in the MCP context, or let the agent `ls` the vendor dir each time. The manifest approach is cheaper per turn.

5. **Step 2 port without OD vendor (interim).** While the OD port is deferred, our step 2 has to describe the 5 canonical schools inline in `references/pipeline.md` and rely on the agent's training-data knowledge of Linear / Notion / Stripe rather than a vendored DESIGN.md. This is the gap to track — once OD lands, step 2's `pipeline.md` simplifies (`read .vendor/open-design/skills/web-prototype/SKILL.md`) and DESIGN.md citation becomes mandatory.

## Related

- [[anthill-archived]] — anthill is frozen 2026-05-13, OD vendor in anthill is the canonical reference for what to port
- spec 026 ([[spec-026-pipeline-deep-port]] — not yet a memory) — current Phase B port work; step 2 is shipping WITHOUT OD vendor first (interim), this memo flags the follow-up
- Future spec: new `docs/specs/NNN-od-vendor-port/` to design the actual port. Decisions 1-5 above are the spec's open questions to resolve.
