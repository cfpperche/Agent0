# Session handoff

Read at the start of every Claude Code session and updated at the end. Captures work-in-progress context that wouldn't otherwise survive between sessions.

See `.claude/rules/session-handoff.md` for the protocol (4 KB size discipline + reader-side truncation defence).

---

## Current state

**Session 2026-05-24 — spec 085 image-gen-opt-in shipped + 3 dogfood-driven fixes.** Spec 085 went through implementation → mocked-test validation → first real-fal.ai dogfood → 3 fixes from dogfood findings → re-validation. Final tally: 31 checkboxes ✓, 0 ⏸ in `docs/specs/085-image-gen-opt-in/tasks.md`. Status `shipped`.

Implementation surface:
- New artifacts: `.claude/rules/image-gen.md`, `.claude/skills/image/{SKILL.md, scripts/gen.sh, references/tier-pricing.md}`, `.claude/tests/image-gen/{01,02,03,04}-*.sh`, `assets/{,brand,generated,generated/mockups}/.gitkeep`, `docs/specs/085-image-gen-opt-in/`.
- Modified: `.mcp.json.example`, `.claude/rules/mcp-recipes.md`, `.claude/hooks/mcp-recipes-hint.sh`, `.gitignore`, `.gitleaks.toml`, `CLAUDE.md`, `.claude/tools/sync-harness.sh`.
- Per-machine (gitignored): `.mcp.json` + `.claude/settings.local.json` carry fal-ai HTTP block + FAL_KEY. `claude mcp list` reports `fal-ai: ✓ Connected`.

Dogfood produced 2 real images at `assets/generated/mockups/2026-05-24-a-friendly-extraterrestrial-astronaut-mascot{,-2}.jpg` (square + landscape, $0.003 each).

## WIP — resume point

**No active WIP.** One residual validation:

- **mcp__fal-ai__* tool surface** — `claude mcp list` says ✓ Connected but the agent surface still doesn't have the tools. Needs ONE more session restart to load. Dogfood was done via curl REST as fallback (which validated FAL_KEY plumbing + model endpoint + content-type assumption + aspect-ratio enum). MCP path is bonus validation, not a spec gate.

## Next steps

1. **Push** — `git push origin main` to publish prior 084 + 086 + this session's spec 085 + handoff commits.
2. **Optional after restart:** invoke `/image --tier=draft "..."` via the actual `mcp__fal-ai__*` tool to close the residual MCP-path validation.
3. **Carryover (prior session):** umbrella 080 NG-doc polish in `memory-placement.md`; 3 cap-overflow memory entries (`anthill-port-workflow`, `consumer-contract-discipline`, `product-pipeline-empirical-baseline`).
4. **Dated reminders due:** 029 (05-30) · 035 (06-07) · 046 (07-01) · 060 (07-19).

## Decisions & gotchas

- **`.mcp.json` HTTP-transport JSON key is `type`, NOT `transport`.** CLI flag spells `--transport http`, but `claude mcp add` writes `"type": "http"` to JSON. Use `claude mcp add` for HTTP blocks; hand-authoring with `transport` silently breaks.
- **MCP tool surface does NOT hot-reload.** `claude mcp list` re-handshakes on `.mcp.json` change (reports ✓ Connected) but the `mcp__*` tools available to the agent are baked at SessionStart. Mid-session edits require restart.
- **fal.ai content-types differ per model.** FLUX schnell → JPEG (verified). gpt-image-2 / Imagen 4 → PNG (documented assumption). `TIER_TABLE` in `gen.sh` carries per-tier extension.
- **MCP vs REST auth header word differs.** MCP: `Bearer ${FAL_KEY}`. REST (`fal.run/...`): `Key $FAL_KEY`.
- **Subshell `exit` doesn't propagate to parent.** Functions called via `$(...)` must `return 1` and parent does `... || die_*`. Documented in `gen.sh` resolver comments.
- **Mocked tests validate contract; real-provider dogfood validates assumptions.** Spec 085's 3 mocked tests passed before dogfood, but dogfood surfaced 3 real gaps (content-type, aspect ratio, MCP-reload). Future credentialed-service specs should include explicit "ran against real provider" acceptance item.
- **Default gitleaks misses fal.ai `<uuid>:<hex>` key shape.** Custom `[[rules]]` in `.gitleaks.toml` covers it.

## Carryover (orthogonal — not touched this session)

- `docs/specs/074-subagent-personas/` — untracked draft; leave for originating session.
