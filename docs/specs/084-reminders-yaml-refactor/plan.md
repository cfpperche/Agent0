# 084 — reminders-yaml-refactor — plan

_Drafted from `spec.md` on 2026-05-24. Update this file if implementation reveals the plan is wrong; do NOT silently diverge._

## Approach

Five-layer change, each layer independently verifiable:

1. **Storage migration** — author `.claude/reminders.yaml` with top-level `reminders:` list, manually translating the 12 existing bullets from `.claude/REMINDERS.md` (per umbrella's "no migration tooling" decision). Each translated entry gets a stable `id` of form `r-YYYY-MM-DD-<short-slug>` derived from the bullet's earliest known timestamp (use `git log --follow --format=%aI -- .claude/REMINDERS.md | tail -1` heuristic per-line, or today's date when ambiguity bites — manual judgment is fine, this is a one-shot).
2. **Skill body refactor** — rewrite `.claude/skills/remind/SKILL.md` to drive YAML mutation. Six subcommands: `add` (create entry), `list` (filtered surface), `done` (soft-delete), `dismiss` (alias for `done` — back-compat, no warning), `snooze` (status: snoozed + snoozed_until), `check` (run an entry's `check_command`, surface output verbatim, never mutate state). The skill body uses `yq` for YAML mutation when present, falls back to a vendored Python helper script for portability (see § Files to touch).
3. **Readout hook refactor** — rewrite `.claude/hooks/reminders-readout.sh` to parse YAML and filter to surfaceable entries (`status: pending` OR `status: snoozed` with `snoozed_until ≤ today`). Tool tier: `yq` first, `python3 -c "import yaml"` fallback, raw-YAML degraded readout last. Inline the `check_command` text under each surfaced entry so the agent can copy-paste-run on demand (OQ-5 resolution: inline > hint).
4. **Rule rewrite** — `.claude/rules/reminders.md` documents the new shape, schema, subcommands, override grammar (carries `# OVERRIDE:` for in-tool YAML edits if needed — same pattern as `.claude/rules/memory-placement.md` § Memory and other forms of persistence), discipline (soft-delete default; positions resolve to IDs at command time; no autonomous check execution).
5. **Old artifact removal** — delete `.claude/REMINDERS.md` from the working tree once the YAML migration is verified. Git history preserves the original.

The five layers ship as a single commit (`feat(084): reminders.yaml refactor + check_command + snooze`) since they're interlocked — partial-state would leave the readout hook reading a file that doesn't exist or the skill mutating a file the hook can't read. No incremental rollout.

Tool dependency posture: hook and skill both tolerate `yq`-absent, Python-`yaml`-absent, and (worst case) both-absent — degraded but functional output, visible advisory. Forks adopting Agent0 inherit the capacity without a hard install gate.

## Files to touch

**Create:**

- `.claude/reminders.yaml` — new YAML state file; top-level `reminders:` list; 12 manually-translated entries from current `.claude/REMINDERS.md`. Per OQ-6: not shipped to forks (skill creates on first `add` like current REMINDERS.md scaffold).
- `.claude/skills/remind/scripts/reminders-helper.py` — Python helper invoked by skill body for YAML mutations when `yq` is absent. ~80 LOC: load YAML, mutate by id-or-position, dump YAML. Stdin-piped, stdout-emitted (mirrors `yq` shape so skill body's call sites are symmetric). Falls under `.claude/skills/remind/scripts/` per spec 026's portable-script pattern.

**Modify:**

- `.claude/skills/remind/SKILL.md` — full rewrite. New argument-hint (`add "<text>" [--due <DATE>] [--check '<cmd>'] [--links <a,b,c>] | list | dismiss <N|id> | done <N|id> | snooze <N|id> <duration> | check <N|id>`), new subcommand semantics, YAML mutation contract, ID format `r-YYYY-MM-DD-<short-slug>` (OQ-4 resolution: Anthill format), dismiss-as-alias-for-done (OQ-2 resolution: silent alias).
- `.claude/hooks/reminders-readout.sh` — full rewrite. YAML parse → filter → emit framed block. yq-then-Python-fallback tier (OQ-3 resolution).
- `.claude/rules/reminders.md` — full rewrite for new shape. Cross-references to umbrella 080 + this spec. Keep the 3-bucket comparison table (SESSION.md / MEMORY.md / REMINDERS), update format examples.

**Delete:**

- `.claude/REMINDERS.md` — removed from working tree once `.claude/reminders.yaml` carries the translated entries. Git history preserves original via `git log --follow`.

**Touch (no functional change, but cross-references):**

- `docs/specs/080-memory-system-scale-ready/spec.md` — flip MS-4 row status to ✓ shipped, tick the "Scenario: 084 closure" acceptance bullet. Single-line edit per row.

## Alternatives considered

### Keep `.claude/REMINDERS.md` and add YAML frontmatter per bullet

Rejected. Bullets-with-frontmatter is hybrid: markdown-readable but YAML-extracted via per-bullet parsing. The parser becomes either fragile (regex-extract `--- ... ---` mid-bullet) or duplicative of YAML proper. Anthill's exemplar uses top-level YAML for the same reasons. The cost of the format change is one-time; the cost of hybrid parsing recurs per readout.

### Ship a JSON Schema validator alongside `reminders.yaml`

Rejected (NG-1 of this spec, derives from umbrella NG-3). Anthill ships `reminders.schema.json` validated via python3+jsonschema. Agent0's pattern is "schema lives in the skill body" — spec 082's frontmatter validator is the most recent example, and spec 083's journal events follow the same pattern (validation embedded in the writer, not a separate schema file). Adding a JSON Schema runtime would be policy-leak from Anthill (umbrella explicitly rejects this in NG-3).

### Auto-run all `check_command`s at SessionStart

Rejected (NG-2). A reminder whose check spawns `gh issue view 42737` costs ~500ms-2s. A fork with 20 reminders × 1s mean check = 20s SessionStart latency on every session boot. Worse, autonomous execution breaks the contract-not-promise discipline (see `.claude/rules/delegation.md` § *Why DONE_WHEN exists*) — the agent reading "still applicable" is informational, but the agent reading "check passed" implies a binary verdict that the check shape doesn't carry. Lazy `/remind check <id>` keeps human-in-loop and zero readout latency.

### Migrate via a one-shot `bash .claude/tools/migrate-reminders.sh` script

Rejected (NG-4). Umbrella decision: 12 entries × manual translation is < 30 min of attention; investing 200 LOC in a script that runs once and is then deleted (or kept as inert cruft) is over-engineering. The manual translation also surfaces ID-format judgment calls (which YYYY-MM-DD to pick when a bullet has no explicit timestamp) that a script would homogenize wrongly.

## Risks and unknowns

- **YAML parser inconsistencies between `yq` (Go) and `yq` (Python).** Go-yq emits compact output by default; Python-yq via `yq` PyPI package emits longer style. If a fork has Python-yq installed, mutations could change formatting on every write, polluting git diffs. Mitigation: skill body invokes the helper script (Python) over `yq` when output stability matters (i.e. always for `add`/`done`/`snooze`); `yq` is read-only-fast-path for the readout hook. Trade-off: forks with `yq` get a fast readout, forks without get the Python fallback (~50ms slower per boot — acceptable).
- **`yq` flavors silently diverge on field ordering.** Anthill's exemplar shows `id` first, `created` second, etc. — readable in that order. Both `yq` flavors and PyYAML's `safe_dump` will re-order alphabetically without `sort_keys=False`. Mitigation: helper script uses `yaml.safe_dump(..., sort_keys=False, default_flow_style=False)` to preserve insertion order; the readout hook doesn't mutate, so its parse-and-print is order-preserving naturally.
- **Bullet → entry translation ambiguity.** Of the 12 current bullets, only those with `· due: <date>` carry explicit timestamps. The rest need a heuristic `created` date — either today (loses authenticity) or the bullet's first git-log appearance (more honest but tedious). Tentative: use `git log --follow -p .claude/REMINDERS.md` to find each bullet's introduction commit, set `created` from that commit's `%aI`. ~30 min manual scan.
- **Snooze date-math without `date -d`.** macOS `date` does NOT support `-d "+7 days"` (GNU only). Skill body must compute `snoozed_until` portably. Mitigation: use Python helper for date math too (`datetime.date.today() + datetime.timedelta(days=N)`); never invoke `date -d` directly. Falls under the Python-helper-always-available baseline.
- **Stable IDs in the readout vs position-based dismissal.** Current UX: "list shows 1..N, dismiss <N>". New UX: "list shows 1..N with IDs visible, dismiss/done/snooze accepts either N or ID". Risk: agents reading the readout and choosing position over ID could mis-target after a concurrent add. Mitigation: position resolution happens at command time inside the skill — the resolved ID is logged in the skill's report message so the user can confirm.
- **`.claude/rules/reminders.md` rewrite collides with cross-references in other rules.** Currently referenced from `.claude/rules/memory-placement.md`, `.claude/rules/routines.md`, `.claude/rules/session-handoff.md`. Rewrite must preserve anchor-targeted phrases or update the referrers. Mitigation: grep `.claude/rules/*.md` for "REMINDERS.md" and "reminders.md" + check section anchors before final commit; update referrers in the same commit.

## Research / citations

- `/tmp/research/anthill.md` lines 110, 319, 346 — Anthill `reminders.yaml` schema reference; informs every field choice except the omitted `close_note` (NG-5)
- `/home/goat/anthill/.anthill/memory/reminders.yaml` — exemplar showing real-world entries with `check_command`, `links`, `snoozed_until`, `completed_ts`
- `docs/specs/080-memory-system-scale-ready/spec.md` — umbrella MS-4 row + non-goals (NG-3 drawer-taxonomy)
- `docs/specs/082-memory-frontmatter-schema/spec.md` — sibling precedent for "schema in skill body, not a separate JSON schema file"
- `docs/specs/083-memory-events-journal/spec.md` — sibling precedent for "advisory readout when tooling absent, never block SessionStart"
- `.claude/rules/delegation.md` § *Why DONE_WHEN exists* — contract-not-promise discipline informing NG-2 (no autonomous check execution)
- `.claude/rules/memory-placement.md` § *Memory and other forms of persistence* — 3-bucket model; reminders.yaml is project-shared via clone, NOT shipped via sync-harness
