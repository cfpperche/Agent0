# Session handoff

Read at the start of every Claude Code session and updated at the end. Captures work-in-progress context that wouldn't otherwise survive between sessions.

See `.claude/rules/session-handoff.md` for the protocol (4 KB size discipline + reader-side truncation defence).

---

## Current state

**Spec 031 brainstorm: SHIPPED.** Full SDD pipeline run end-to-end this session (`/sdd new` → spec → plan → tasks → impl → validation → status flip). 14/14 acceptance criteria checked, 5/5 Open Questions resolved, status `draft` → `shipped`.

New `/brainstorm` skill sits before `/sdd refine` in the ideation→spec pipeline. Free-form by default; 4 lenses available on demand (SCAMPER, Six Thinking Hats, Reverse, Crazy 8s). Output: self-contained HTML at `.claude/.brainstorm-state/<slug>-<ts>.html` with markmap mindmap + tag-kanban + open questions + lens tabs + mermaid timeline + Copy-as-markdown footer button.

**Validation this session**: synthetic state → Python renderer → Playwright (tab nav, lens panel, timeline SVG, clipboard write) → sync-harness `--check` (skill files in scope, `.brainstorm-state/` excluded). Behavioural scenarios (start / capture / checkpoint / lens / resume / list) defined in SKILL.md; full end-to-end run in a fresh CC session is the user's last step.

Files ready to commit:
- New: `.claude/skills/brainstorm/{SKILL.md,templates/render.html.tmpl,references/techniques.md}`, `docs/specs/031-brainstorm/{spec,plan,tasks}.md`
- Modified: `.gitignore` (+`.claude/.brainstorm-state/`), `.claude/SESSION.md`
- Wipe-able: `spec-031-brainstorm-exploration.png` (smoke screenshot), `.claude/.brainstorm-state/spec-031-smoke-*.{json,html}` (gitignored)

Untouched sibling work in tree (`site/src/components/Header.astro`, `site/src/i18n/strings.ts`, `site/src/pages/cheatsheet/`) — do NOT stage; parallel session owns those.

## Next steps

1. **Real `/brainstorm start` in a fresh CC session** — validate behavioural scenarios that this session could only check statically (start, capture, checkpoint cadence, lens application, maturation heuristic, resume, list). Drift goes into `plan.md` § Risks before purging the synthetic smoke artefacts.
2. **Commit the spec 031 ship** once approved (skill + spec/plan/tasks + .gitignore line).
3. **Spec 026 Phase B remaining tasks 19-22** (step 10/11/12/13) still pending from earlier work.
4. **REMINDERS.md** unchanged — fair OD re-match, OD `--bump/--apply` upstream test, spec 029 adoption check (due 2026-05-30).

## Decisions & gotchas

- **Brainstorm is divergent, `/sdd refine` is convergent — adjacent, NOT nested.** Brainstorm outputs HTML; spec promotion is manual via `/sdd new <slug>` + paste from Copy-as-markdown.
- **No hooks.** Divergence discipline encoded in SKILL.md prose, not enforced via `UserPromptSubmit` (rejected the [MadeByTokens hook approach](https://github.com/MadeByTokens/claude-brainstorm) — alt 1 in plan.md).
- **markmap > mermaid for mindmaps at 50+ nodes.** Both kept; markmap for mindmap, mermaid for timeline. Two CDN scripts, pinned: `markmap-autoloader@0.18`, `mermaid@11.4.0`.
- **Clipboard API needs localhost or https origin.** `file://` triggers textarea fallback. `done` output recommends `python3 -m http.server 8765 -d .claude/.brainstorm-state`.
- **Tab label gotcha caught + fixed mid-validation**: initial draft had inline lens badge in tab text → "SCAMPERSCAMPER". Resolved by moving the badge to the panel header; SKILL.md `{{LENS_TABS_HTML}}` / `{{LENS_PANELS_HTML}}` updated.

## Carryover (orthogonal lanes, not active)

- Pyshrnk CLAUDE.md reconciliation — long-standing parking lot.
- Shrnk-mono harness-sync commit pending.
- Praxis-prototype (separate repo): deployed at https://cfpperche.github.io/praxis-prototype/.
- Bench artifacts (wipe-able, ~1.5 MB): `/tmp/bench/026-dogfood-step{2,3-4,5,6,7,8}/` + `/tmp/bench/026-comparison-anthill/`.
- 10 `step7-*.png` + 1 `spec-031-brainstorm-exploration.png` screenshots at repo root — wipe-able, not source.
