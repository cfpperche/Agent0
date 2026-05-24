# Memory placement

When saving a learning, fact, or rule, route it by **what kind of knowledge** it is and **who/what should see it**. Three buckets, each with distinct propagation properties:

## The 3 buckets

### 1. CC per-user memory — `~/.claude/projects/<path>/memory/`

**For:** preferences, style, personal context that wouldn't help anyone else. Per-user, per-machine, **not git-tracked**. Lost when you switch machines — by design.

**Use when:** the knowledge is genuinely about THIS user (language, response terseness, "I prefer X over Y"). Anything that reads like a profile attribute or interaction style.

**Do NOT use for:** anything substantive about the project itself. If another Agent0 contributor would benefit from knowing this fact, it does not belong here. The "memoria do projeto" naming in CC's UI is misleading: it's memory of the user *about* the project, not of the project itself.

**Concrete example currently in this bucket:** `user_language.md` — "native Portuguese, fluent English; chat in Portuguese by default but repo artifacts stay English". Genuine per-user preference; another developer cloning Agent0 has their own language preference.

### 2. Project memory — `.claude/memory/<topic>.md`

**For:** factual cross-cutting knowledge about THE PROJECT — platform constraints, prior decisions and their reasoning, architectural gotchas discovered through dogfooding, references to canonical external sources. Git-tracked, **propagates between contributors of THE SAME project via PR/clone** but **NOT shipped between projects** via sync-harness manifest. The empty scaffold (`.claude/memory/.gitkeep`) IS shipped so every fork gets its own bucket — but memory content is project-local, never cross-pollinated.

**For forks of Agent0:** this same rule applies. Each fork has its own `.claude/memory/` that accumulates its own factual knowledge (e.g. pyshrnk might memorize "Starlette form parsing without python-multipart uses urllib.parse.parse_qs"). Agent0's memory entries (about CC platform internals, sync-harness design rationale, etc.) do NOT travel to forks — and reciprocally, fork-specific memories do NOT propagate back upstream. The sync tool is one-way for capacities; memory content is one-source.

**Use when:** the knowledge is project-specific factual reference, not behavioral mandate. "Claude Code has 29 hook events", "we chose hash-compare because alternatives X/Y had problems Z". The agent reads these on demand when starting relevant work — discovery is via the `## Memory` block in CLAUDE.md (lazy-read of `.claude/memory/MEMORY.md` index).

**Do NOT use for:** behavioral mandates ("the agent must do X") — those are rules. Capacity operational documentation ("how the supply-chain hook works") — those are rules. Work-specific design context — that lives in the corresponding `docs/specs/NNN-*/` dir.

**One narrow exception** to "no behavioral mandates here": a mandate that binds the Agent0 *maintainer* rather than the agent working in any fork. Rules ship to forks, so a maintainer-only discipline placed in a rule would be inert cruft in every fork that consumes the harness but never extends it. Such disciplines route to project memory despite being mandate-shaped — `propagation-hygiene.md` (how fork-bound files must be written so they carry no Agent0-internal pointers) is the canonical case; `agent0-purpose.md` is a softer precedent.

**Concrete examples currently in this bucket:** `agent0-purpose.md` (Agent0 is a template-forever project; do not list empty placeholders as gaps), `visibility-intent.md` (next visibility wedge is agent-self-debug, not human dashboards), `cc-platform-hooks.md` (the canonical 29 events of the CC platform).

### 3. Project rules — `.claude/rules/<topic>.md`

**For:** behavioral mandates the agent SHOULD comply with, plus operational documentation of the project's capacities (hooks, validators, tools). Git-tracked AND **shipped to forks** via sync-harness manifest — the rules ride with the capacities they govern.

**Use when:** the knowledge is "the agent must follow X when working in this project" or "here's how capacity Y works in any fork that adopts it". Path-scoped variants of these rules use a `paths:` frontmatter to restrict where they apply.

**Do NOT use for:** factual reference data that's Agent0-design-internal (CC platform knowledge, why-we-chose-X decisions). Those are project memory, not rules — they'd noisily ship to every fork that doesn't extend the harness.

**Concrete examples currently in this bucket:** `delegation.md` (5-field handoff mandate), `secrets-scan.md` (gitleaks behavior + override grammar), `runtime-introspect.md` (probe.sh capacity operational docs).

## Routing decision tree

```
Is the knowledge a user-specific preference (language, style)?
  Yes → CC per-user memory (~/.claude/projects/<path>/memory/)
  No  → continue

Is the knowledge a behavioral mandate or capacity operational doc?
  Yes → .claude/rules/<topic>.md (will ship to forks)
  No  → continue

Is the knowledge factual project reference (platform constraint, prior decision, gotcha)?
  Yes → .claude/memory/<topic>.md (git-tracked, NOT shipped to forks)
  No  → reconsider; the knowledge probably belongs elsewhere (CLAUDE.md for orientation, SESSION.md for WIP, docs/specs/ for work-unit design memory)
```

When in doubt, route to project memory (`.claude/memory/`). Demoting from rule → memory later is easy; promoting from per-user → project requires migration.

## Quick reference table

| Bucket | Path | Git-tracked? | Ships to forks? | Auto-loaded? | Best for |
| --- | --- | --- | --- | --- | --- |
| CC per-user memory | `~/.claude/projects/<path>/memory/` | No | No | Yes (MEMORY.md, capped) | Preferences only |
| Project memory | `.claude/memory/<topic>.md` | **Yes** | **Empty scaffold only** (`.gitkeep`); content stays project-local | No (lazy-read via CLAUDE.md `## Memory`) | Factual project knowledge — each project accumulates its own |
| Project rules | `.claude/rules/<topic>.md` | **Yes** | **Yes** | On demand (CLAUDE.md mentions) | Behavioral mandates + capacity docs |

<!-- DO NOT RENAME — referenced verbatim by .claude/hooks/memory-frontmatter-validate.sh advisory messages -->
## Frontmatter schema

Project-memory entries (bucket #2 — `.claude/memory/<topic>.md`, NOT `MEMORY.md` itself, which is the index) carry a YAML frontmatter block fenced by `---`. Three fields are **required**; three are **optional** and populated by the decay engine + event-sourced journal documented below.

The `.claude/hooks/memory-frontmatter-validate.sh` hook fires on `PostToolUse(Edit|Write|MultiEdit)` for any file under `.claude/memory/*.md` (except `MEMORY.md`) and emits a non-blocking `memory-frontmatter-advisory:` line to stderr when the entry violates the schema. Always exit 0 — never blocks the edit. Pattern matches `tdd-advisory:` / `lint-advisory:` / `typecheck-advisory:` (see `.claude/rules/delegation.md` § *Advisories*).

### Required fields

| Field | Shape | Purpose |
|---|---|---|
| `name` | string | Stable identifier — slug or human-readable label. Both shapes pass (existing entries use both). |
| `description` | string | One-line summary used in the MEMORY.md index. Soft cap on projected index-line length (advisory only) — see § *Cap / query / decay* below. |
| `metadata.type` | string | Classification, nested under `metadata:`. Value-open by design (forks pick the taxonomy that fits their project). Examples in current use: `project`, `reference`. |

### Optional fields (under `metadata.*`)

| Field | Shape | Purpose |
|---|---|---|
| `metadata.created_at` | ISO-8601 timestamp | Entry creation time. Decay engine input (see § *Cap / query / decay*). |
| `metadata.last_accessed` | ISO-8601 timestamp | Last-read time. Decay engine input. |
| `metadata.confirmed_count` | integer | Strength signal — how many times the entry has been re-validated since creation. |

### Worked example

```markdown
---
name: cc-platform-hooks
description: Canonical surface of 32 Claude Code hook events; consult before designing any hook-based capacity.
metadata:
  type: reference
  created_at: 2026-05-19T17:41:00Z
  last_accessed: 2026-05-23T09:15:00Z
  confirmed_count: 4
---
# CC platform hooks
…body…
```

### Failure modes the validator advises on

- **Missing required field** — `name`, `description`, or `metadata.type` absent.
- **Unknown field** (typo guard) — any top-level key outside `{name, description, metadata}`, or any `metadata.*` key outside the 4 allowed values above.
- **No frontmatter block** — file does not start with `---` at line 1.
- **Frontmatter unparseable** — first `---` present but no closing `---` found.

Conforming entries pass silently. `MEMORY.md` (the index) is skipped — it carries no frontmatter by design.

## Event journal

`.claude/memory/MEMORY.md` is a **derived view**, regenerated from the entries' `name` + `description` frontmatter. Two cooperating hooks make the system self-consistent:

- **`PostToolUse(Edit|Write|MultiEdit)`** → `.claude/hooks/memory-events-journal.sh` fires on any write to `.claude/memory/*.md` (excluding `MEMORY.md`). Appends one JSONL event to `.claude/.memory-events.jsonl` AND invokes `bash .claude/tools/memory-project.sh` to regenerate `MEMORY.md` from the current entries. Always exit 0 — failure modes (unwritable journal, missing `jq`, projection error) emit a `memory-journal-advisory:` line and continue. The PreToolUse gate is the only blocking part of this capacity.

- **`PreToolUse(Edit|Write|MultiEdit)`** → `.claude/hooks/memory-index-gate.sh` blocks raw edits to `.claude/memory/MEMORY.md` (exit 2 with corrective template) unless the tool input carries `# OVERRIDE: memory-index-edit: <reason ≥10 chars>` (or the equivalent `<!-- OVERRIDE: memory-index-edit: <reason> -->` HTML-comment form). Override-bypassed edits are recorded as `manual-edit` events in the journal with the reason as a field.

### Event shape

One JSONL line per memory write. Five `event_type` values:

| `event_type` | When | Fields |
| --- | --- | --- |
| `add` | First write of an `entry_id` (no prior `add` in journal) | `ts`, `entry_id`, `actor`, `session_id`, `tool_use_id`, `tool` |
| `update` | Subsequent write of an `entry_id` that already has an `add` | same as `add` |
| `delete` | Reserved — not auto-emitted in v1 (no file-removal hook event) | `ts`, `entry_id`, `actor` |
| `rename` | Manual append when renaming an entry (no auto-detect in v1) | `ts`, `entry_id`, `prev_entry_id`, `actor` |
| `manual-edit` | PreToolUse gate override accepted | adds `reason` field |

`entry_id = basename(filename, '.md')` — naturally stable, machine-derivable, no schema field needed. `actor = agent_type` when present in the hook payload (sub-agent edits), else `"parent"`. `ts` in ISO-8601 UTC; the backfill uses git-introduction timestamps which may carry a timezone offset (acceptable — JSONL consumers parse both).

### Per-machine journal (gitignored)

`.claude/.memory-events.jsonl` is **gitignored** — per-machine cache, sibling to `.claude/delegation-audit.jsonl` and `.claude/.runtime-state/`. A git-tracked journal would produce merge conflicts on every concurrent commit across a multi-contributor fork; entry files themselves are git-tracked and carry the durable record via `git log --follow`. On a new leader machine, run `bash .claude/tools/memory-backfill.sh` once to seed the journal with one `add` event per existing entry (`ts` derived from git-introduction time). Idempotent — re-running on a populated journal is a no-op.

The first invocation of the journal hook on an empty journal emits a one-time `memory-journal-advisory: journal empty; run bash .claude/tools/memory-backfill.sh` to mitigate the otherwise-silent add-vs-update misclassification.

### Direct `git commit` opt-out

A human running `vim .claude/memory/MEMORY.md && git commit` bypasses the tool-surface gate. This is explicitly opt-out — the operator is responsible for re-running `bash .claude/tools/memory-project.sh` afterward to re-converge. The next agent-driven edit to any entry restores consistency anyway.

### Cross-references

- `.claude/hooks/memory-events-journal.sh` / `.claude/hooks/memory-index-gate.sh` — implementations
- `.claude/tools/memory-project.sh` / `.claude/tools/memory-backfill.sh` — operator commands
- `.claude/memory/cc-platform-hooks.md` — hook event semantics + `agent_id` / `agent_type` payload conventions
- `.claude/rules/delegation.md` § *Advisories* / *Audit log* — `memory-journal-advisory:` follows the project advisory grammar; the JSONL shape mirrors `.claude/delegation-audit.jsonl`

## Cap / query / decay

Three scale-handling surfaces let the bucket operate at 100-500 entries without the index becoming unreadable or stale entries crowding the active set.

### 1. Index-line cap

`memory-project.sh` checks each projected `MEMORY.md` line against `cap.max_line_chars` (default 250) read from `.claude/memory.config.json`. Overflow emits a `memory-cap-advisory: <file> projects to <N> chars (cap <M>) — shorten description` line to stderr; the bullet is still written (no auto-truncation — the cap is a writing discipline, not a silent edit). The advisory surfaces every projection until the founder shortens the entry's `description:` frontmatter.

### 2. `memory-query.sh`

Search + filter helper for entry bodies and frontmatter. Four subcommands, all routed through `.claude/tools/memory-query-helper.py` (Python + PyYAML; mirrors the `.claude/skills/remind/scripts/reminders-helper.py` pattern — bash dispatcher delegates to a Python helper for YAML mutation):

- **`search <pattern>`** — case-insensitive grep across all `.claude/memory/*.md` (body + frontmatter). One line per hit: `<path>: <first matching line>`.
- **`list [--type=T] [--stale=Nd|Nw|Nm]`** — filter the index. `--type` matches `metadata.type` exactly; `--stale` accepts the same duration grammar as `/remind snooze` and lists entries whose `last_accessed` is older than `today − duration`.
- **`confirm <name1> [<name2> ...]`** — bumps `metadata.last_accessed` to today + increments `metadata.confirmed_count`. Variadic; reports the resolved file path per name. Refuses with exit 2 on unknown names. Note: the helper writes via Python syscalls, which bypasses the `PostToolUse` memory-events-journal hook — the audit trail for confirms lives in `git log` of the entry file, not in `.claude/.memory-events.jsonl`.
- **`decay [--readout]`** — computes staleness for each entry and lists ones above the threshold. The `--readout` flag wraps output in a `=== MEMORY DECAY ===` framed block for SessionStart injection.

### 3. Decay engine

Formula (default, transparent + overridable):

```
score = (today − last_accessed_or_created_at).days − confirmed_count × confirm_boost_days
```

Entries with `score > threshold_days` are listed as stale. Defaults: `threshold_days = 60`, `confirm_boost_days = 14` (each confirm discounts ~2 weeks from the staleness clock). The `.claude/hooks/memory-decay-readout.sh` SessionStart hook fires `memory-query.sh decay --readout` every session — always-fire with `(no stale entries)` empty-case keeps the capacity discoverable.

The engine never auto-archives, auto-deletes, or otherwise mutates entry files. Decay is observation, not removal — the founder (or agent) decides whether to `confirm`, manually edit, or move the entry. Auto-archive is rejected by design: staleness is a re-validation cadence question (some useful entries need re-confirming twice a year), not a wrongness signal.

### Config — `.claude/memory.config.json`

```json
{
  "cap": { "max_line_chars": 250 },
  "decay": { "threshold_days": 60, "confirm_boost_days": 14 }
}
```

Shipped as a starter template. Forks override values directly. Missing keys fall back to documented defaults. Malformed JSON emits a one-line `memory-config-advisory:` and the defaults run; never blocks. Out-of-spec keys are ignored silently.

### Gotchas

- **`confirm` writes via Python, NOT via the Edit/Write tool surface.** The `PostToolUse` memory-events-journal hook (which captures `Edit`/`Write`/`MultiEdit` invocations) does NOT fire on confirms. The audit trail for confirms lives in `git log <entry-file>`. If you need journal events on confirms in your fork, extend the Python helper to append a JSONL line directly.
- **`last_accessed` is honest only after the founder uses `confirm`.** Backfilled values for pre-spec-086 entries default to "today at backfill time" (no honest read signal exists pre-spec). Decay won't surface anyone for ~60 days after the backfill ship unless the founder confirms (and thus moves the timestamp) some entries first.
- **Cap counts the projected bullet length, not the raw description.** The check is on `- [<name>](<slug>.md) — <description>` after assembly. Tightening `name` (rare) is one lever; the usual fix is shortening `description`.
- **Folded YAML strings in the entries can confuse non-Python tooling.** PyYAML's `safe_dump` folds long values across lines for readability. The Python helper handles this; the degraded awk projection path in `memory-project.sh` (used when python3+yaml absent) emits a `memory-project-advisory:` warning and may truncate folded descriptions at the first line. Forks without PyYAML get a degraded but still-functional projection.

### Files

- `.claude/memory.config.json` — config (cap + decay numerics)
- `.claude/tools/memory-query.sh` — bash dispatcher (4 subcommands)
- `.claude/tools/memory-query-helper.py` — Python helper (YAML mutation + filtering + projection)
- `.claude/tools/memory-backfill-metadata.sh` — one-shot helper to populate `created_at` / `last_accessed` / `confirmed_count` for pre-spec-086 entries
- `.claude/tools/memory-project.sh` — extended with cap-advisory check
- `.claude/hooks/memory-decay-readout.sh` — SessionStart hook

## Cross-cutting artifacts (not buckets, but related)

- **`CLAUDE.md`** — first-contact orientation, capacity inventory, always loaded. Points at memory/rules/specs as needed.
- **`SESSION.md`** — short-term WIP handoff, ~2KB budget, replaced rather than appended. Always loaded.
- **`docs/specs/NNN-*/`** — design memory for specific work units. Not auto-loaded; referenced when relevant.

## Why three buckets, not two

The previous version of this rule had only two buckets: project-shared (rules) and per-user (preferences). That model conflates two distinct kinds of project-shared knowledge: behavioral mandates that should ride with capacities into forks, and factual reference that's Agent0-internal design context. The empirical trigger for the split was discovering that Claude Code has 29 hook events (not the ~9 originally assumed). That knowledge:
- Is project-shared (other Agent0 contributors benefit)
- Is NOT a behavioral mandate (it's reference data)
- Should NOT ship to forks (forks consume capacities, they don't extend the harness)

No existing bucket fit. The new `.claude/memory/` bucket covers this gap.
