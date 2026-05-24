# 086 — memory-cap-query-decay — plan

_Drafted from `spec.md` on 2026-05-24. Update this file if implementation reveals the plan is wrong; do NOT silently diverge._

## Approach

Five-layer change, each independently verifiable:

1. **Backfill helper + run** — one-shot `bash .claude/tools/memory-backfill-metadata.sh` populates the 3 optional frontmatter fields (`created_at`, `last_accessed`, `confirmed_count`) on the 13 existing entries. `created_at` derives from `git log --follow --format=%aI -- <file> | tail -1` per entry (true introduction time, matches 084 T2 pattern). `last_accessed` defaults to today's ISO date (no honest signal exists for pre-spec reads). `confirmed_count: 0`. Run once, committed in this ship; idempotent (skips entries already carrying the fields). The script is NOT auto-run by sync-harness — forks adopting the schema populate organically as entries get touched.

2. **`.claude/memory.config.json`** — starter template at repo root with documented defaults: `decay.threshold_days: 60`, `decay.confirm_boost_days: 14`, `cap.max_line_chars: 250`. Shipped per umbrella OQ-4 tentative; forks override values directly. Comments in the JSON via `_comment` keys (no real JSON comments, but readers see them). Out-of-spec keys ignored with `memory-config-advisory:` line — same posture as `.claude/rules/delegation.md` § *Advisories*.

3. **Cap enforcement in `memory-project.sh`** — read `cap.max_line_chars` from `memory.config.json` (default 250 if absent/malformed). After projecting each entry to `- [<name>](<file>) — <description>`, check the line length. If > cap, emit `memory-cap-advisory: <file> projects to <N> chars (cap <M>) — shorten description` to stderr. Always emit the bullet (no truncation per OQ-3 resolution: stderr only, no log). Exit 0.

4. **`memory-query.sh`** — single script with 4 subcommands per OQ-4 resolution:
   - `search <pattern>` — `grep -ilE <pattern>` across `.claude/memory/*.md` (case-insensitive); for each hit, emit the file path + first matching body line as context.
   - `list [--type=<T>] [--stale=<Nd|Nw|Nm>]` — read frontmatter via Python helper (PyYAML, same path as `reminders-helper.py`), filter, emit `<name>: <description>` one-per-line. Staleness threshold parsed via the same duration shape as `/remind snooze`.
   - `confirm <name1> [<name2> ...]` — variadic per OQ-5. For each name, mutate the entry's frontmatter to set `last_accessed: <today>` and bump `confirmed_count` by 1. The mutation is a regular `Edit` of the file, so the existing memory-events-journal hook from 083 captures it as an `update` event. No new event type.
   - `decay [--readout]` — compute staleness score for each entry per the OQ-1 formula (`stale_days − confirmed × 14`), filter to `score > threshold_days` (default 60 from config), emit one line per stale entry. The `--readout` flag emits the framed `=== MEMORY DECAY ===` block for SessionStart; bare invocation emits a CLI-shaped list.

   The query script delegates heavy YAML work to a Python helper `memory-query-helper.py` (mirrors the `reminders-helper.py` pattern from 084), keeping the shell script as a thin dispatcher. ~200 LOC Python + ~80 LOC bash.

5. **Readout hook + rule update** — `memory-decay-readout.sh` registers at SessionStart, invokes `memory-query.sh decay --readout`, surfaces the framed block. Always-fire per OQ-2 (the `(no stale entries)` empty case keeps the capacity discoverable). `.claude/rules/memory-placement.md` grows a new § *Cap / query / decay* subsection documenting the surfaces, config keys, and override grammar.

The five layers ship as a single commit (`feat(086): memory cap + query + decay`). Partial state is incoherent — a cap check that reads a config file that doesn't exist, or a decay hook that reads frontmatter fields that aren't populated, surfaces noise instead of value.

## Files to touch

**Create:**

- `.claude/tools/memory-backfill-metadata.sh` — one-shot bash wrapper that calls `memory-query-helper.py backfill-metadata` for each `.claude/memory/*.md` entry. Idempotent. Run once during ship; not part of the running capacity.
- `.claude/tools/memory-query.sh` — thin bash dispatcher for `search` / `list` / `confirm` / `decay`. ~80 LOC.
- `.claude/tools/memory-query-helper.py` — Python helper for YAML mutation + staleness math + filtered listing. ~200 LOC. Mirrors `reminders-helper.py` pattern from 084.
- `.claude/hooks/memory-decay-readout.sh` — SessionStart hook, ~25 LOC. Calls `memory-query.sh decay --readout`, exits 0.
- `.claude/memory.config.json` — starter template with default values + `_comment` keys.

**Modify:**

- `.claude/tools/memory-project.sh` — read `cap.max_line_chars` from `memory.config.json`, emit `memory-cap-advisory:` per overflow. Backward-compatible: behavior unchanged when config file absent (defaults to 250).
- `.claude/rules/memory-placement.md` — new § *Cap / query / decay* subsection. Documents the 3 surfaces + config keys + override grammar. Add 4th file under § Files: `.claude/memory.config.json`.
- `.claude/settings.json` — register `memory-decay-readout.sh` under `hooks.SessionStart` alongside the existing readout hooks.
- All 13 `.claude/memory/*.md` entries (except `MEMORY.md`) — frontmatter populated with `created_at`, `last_accessed`, `confirmed_count` via the backfill helper. Mechanical mutation, no body changes.
- `docs/specs/080-memory-system-scale-ready/spec.md` — flip MS-5 + MS-7 rows to ✓ shipped, tick `Scenario: 086 closure`.

**Delete:**

- (none)

## Alternatives considered

### Truncate overflow lines in `memory-project.sh` with a `…` suffix

Rejected. Truncation hides exactly the half a reader of the index would have needed (the meaningful continuation of the description). The advisory-only approach keeps the full line visible until the founder rewrites — a small ongoing nudge to keep descriptions tight, not a silent lossy edit. Anthill's projection also doesn't truncate; the cap is a *writing* discipline enforced at *index-time*.

### Ship `memory-decay.sh` as a separate script from `memory-query.sh`

Rejected (OQ-4 resolution). Two scripts double the discoverability surface and the shell-glue duplication. Subcommands are idiomatic — `git`, `kubectl`, `npm`, etc. ship one entrypoint with many verbs. The bash dispatcher stays under 100 LOC even with 4 subcommands.

### Auto-archive stale entries to `.claude/memory/.archive/`

Rejected (NG-1). Anthill ships `auto_archive: true` as a fork-toggle and the user explicitly rejected this in umbrella NG-4 ("auto_archive: false"). Stale ≠ wrong; "stale" means "founder hasn't re-validated lately", and many useful entries (e.g. `cc-platform-hooks.md`) need re-validation maybe twice a year. Auto-archiving them would silently break the agent's knowledge access.

### Use file mtime instead of `last_accessed` frontmatter

Rejected. mtime tracks edits, not reads — the same signal the event journal from 083 already captures. The whole reason the schema (082) declared `last_accessed` as a distinct field is that *re-validation* (founder/agent confirms "this is still right") is a different signal from *modification* ("I rewrote part of this"). Conflating them would make `confirm` a no-op (mtime already moves on edit) and lose the orthogonal axis decay needs.

### Read-detection hook for automatic `last_accessed` bumps

Rejected (NG-2). Anthill's research notes reported this as fragile (every `grep`, `cat`, search hit bumped the field, drowning the honest signal). Manual `confirm` is more work for the founder but produces a usable decay signal.

### Skip `memory.config.json`, hard-code constants in `memory-query.sh`

Rejected. Forks at different scales need different thresholds (a fork with 200 entries probably wants 90d, not 60d; a fork with 30 needs 30d). Hard-coding violates umbrella NG-4 ("forks pick different thresholds; Agent0 doesn't pretend to know"). Shipping the config as a starter (umbrella OQ-4 tentative) reduces friction without committing Agent0 to specific numbers.

## Risks and unknowns

- **YAML mutation in-place is order-sensitive.** Frontmatter currently has `name` / `description` / `metadata.type` in a specific visual order. PyYAML's `safe_dump(sort_keys=False)` preserves insertion order but the `memory-query-helper.py confirm` mutation reads → mutates → dumps. If the helper doesn't preserve every existing key's position, git diffs will show spurious reorderings. Mitigation: same approach as `reminders-helper.py` (load → mutate specific keys → dump with `sort_keys=False`); the 084 verification confirmed this works.
- **Staleness signal is unreliable for the first ~30 days after backfill.** All 13 entries get `last_accessed: 2026-05-24` from the backfill. None will be stale until 2026-07-23 (60d default threshold). The decay readout will be empty for ~2 months — discoverable but uninformative. Acceptable: the founder confirms entries naturally over the window, populating real `last_accessed` values. Mitigation: the empty `(no stale entries)` readout still proves the capacity exists.
- **Cap enforcement could surface immediately on 2 existing entries.** `consumer-contract-discipline` (353 chars) and `anthill-port-workflow` (345 chars) will trigger advisories on the first projection. This is actually the desired outcome — the cap is there to surface bloat. The founder rewrites or leaves them with the advisory noise.
- **`.claude/memory.config.json` collides with fork customization.** Forks that already manually populated the file (none today, but possible) would have their config overwritten by the starter ship. Mitigation: ship the starter only if absent (cp-with-noclobber semantics). The backfill helper checks `[ -f .claude/memory.config.json ] || cp .claude/memory.config.json.example .claude/memory.config.json`. Alternative: ship as `.claude/memory.config.json.example` only and let forks `cp` it manually. Going with the simpler ship-if-absent path; revisit if a fork complains.
- **Hook count creep on SessionStart.** Adding `memory-decay-readout.sh` brings the SessionStart hook count up. Each hook adds ~10-50ms to session boot. Mitigation: the decay readout is cheap (~30ms — read 13 frontmatter blobs, compute deltas). Real risk only materializes when forks have 500+ entries; revisit then.
- **The `confirm` subcommand mutates entries, which triggers the 083 journal hook, which auto-regenerates MEMORY.md.** Side effect: every `confirm` call rewrites MEMORY.md too. This is correct (the projection might shift if descriptions vary) but worth documenting in the rule so users don't see it as unexpected churn.

## Research / citations

- `/tmp/research/anthill.md` lines 258, 346, 377 — Anthill's `memory-decay.sh` + `memory-confirm.sh` + read-detection hook; informs NG-2 (read-detection rejected) and the variadic-confirm pattern
- `docs/specs/080-memory-system-scale-ready/spec.md` — umbrella MS-5 + MS-7 rows + non-goals
- `docs/specs/082-memory-frontmatter-schema/spec.md` — optional metadata fields this spec activates
- `docs/specs/083-memory-events-journal/spec.md` — projection helper this spec extends; event journal that catches `confirm` mutations as `update` events
- `docs/specs/084-reminders-yaml-refactor/spec.md` — pattern reference for "bash dispatcher + Python helper" (`/remind` skill + `reminders-helper.py`)
- `.claude/memory/anthill-archived.md` + `.claude/memory/feedback_speculative_observability.md` — advisory-not-action posture grounding
- `.claude/rules/memory-placement.md` — 3-bucket model; this spec adds a new subsection
- `.claude/rules/delegation.md` § *Advisories* — `memory-cap-advisory:` / `memory-config-advisory:` / `memory-decay-advisory:` follow the project's advisory grammar pattern (mirrors `tdd-advisory:` / `lint-advisory:` / `typecheck-advisory:` / `memory-frontmatter-advisory:`)
