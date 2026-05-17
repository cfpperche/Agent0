# Session handoff

Read at the start of every Claude Code session and updated at the end. Captures work-in-progress context that wouldn't otherwise survive between sessions.

See `.claude/rules/session-handoff.md` for the protocol (4 KB size discipline + reader-side truncation defence).

---

## Current state

**Claude Code learning content extracted to its own repo.** All four learning surfaces (cheatsheet, Master Class EN/PT/ES, /goal Class, Hook Cookbook) — plus the shared `ResourcesMenu` component and the index landing — now live at `/home/goat/claude-core/` and are published as a standalone repo.

**claude-core (new, published):**
- Repo: https://github.com/cfpperche/claude-core (public, MIT)
- Live: https://cfpperche.github.io/claude-core/
- Local: `/home/goat/claude-core/` (sibling to Agent0)
- Initial commit `8a0b07f` — 19 files, 9843 insertions
- GitHub Pages workflow deployed in 29s, ✓ success
- Rebrand pass complete: "AGENT0 CONTROL ROOM"/"ACADEMY" → "CLAUDE-CORE · CHEATSHEET"/"ACADEMY", `← back to Agent0` → `← claude-core`, REPO_URL points to new repo, footers re-attributed.

**Agent0 (cleaned, uncommitted):**
- Removed 5 tracked Claude-Code page files + 2 untracked (`goal-command.astro`, `ResourcesMenu.astro`)
- Header.astro: stripped the `Claude Code ↗` pill nav item
- strings.ts: removed 5 nav fields from en/pt/es (`cheatsheet`, `masterclass`, `goalClass`, `cookbook`, `claudeCodeHub`)
- Build verified: 3 pages, 609ms, clean — Agent0 is back to landing-only shape
- Working tree: 4 modified + 5 deleted from this session, plus 3 unrelated items left untouched

## Next steps

1. **Commit Agent0 cleanup.** Suggested message: `chore(site): extract Claude Code content to claude-core repo`. Working tree has 4 M + 5 D from this session — staging is selective, leave the 3 unrelated items.
2. **Translations for /goal class** (now lives in claude-core) — pt-BR and es versions, mirroring the main Master Class i18n pattern. Open work item in claude-core.
3. **Distribution announcement** — Akshay-style thread on X promoting the now-standalone claude-core site. Marginal ROI of another page is now lower than promoting the existing four.
4. **Spec 026 Phase C / Phase D** — still pending in Agent0.
5. **Memorialize port→judge→calibrate as 8th phase of `.claude/memory/anthill-port-workflow.md`** — still pending 4+ sessions.

## Decisions & gotchas

- **Separation rationale.** Agent0 is a harness story, claude-core is a Claude Code story. Audiences and identity differ. Hub card + Resources dropdown handle nav within claude-core; no cross-link back to Agent0 in content.
- **URL stability.** Page URLs kept their shape (`/cheatsheet/claude-core/`, `/masterclass/claude-code/` …); only base path changed from `/Agent0/` to `/claude-core/`.
- **i18n config dropped in claude-core.** Astro `i18n` block was needed for Agent0's landing locales. claude-core's pt/es variants are just nested routes, no Astro-level i18n. Side benefit: eliminates the dev-server 404 quirk for non-prefixed URLs.
- **Deploy workflow shape.** Agent0's uses `path: ./site`; claude-core's uses repo root. Single-project repo needs no nested-site indirection.

## Carryover (orthogonal lanes, not active)

- Spec 026 Phase B follow-ons + bench artifacts in `/tmp/bench/026-dogfood-step{11,12,13}/`.
- 3 unrelated working-tree items NOT this session: `.claude/skills/brainstorm/templates/render.html.tmpl` mod, `banner-4-atos.png`, `next-steps-tab.png`, `docs/specs/032-pipeline-industry-alignment/`.
