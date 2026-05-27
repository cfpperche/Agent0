---
paths:
  - ".claude/tools/sync-harness.sh"
---

# Harness sync

A one-way sync tool (`.claude/tools/sync-harness.sh <consumer-path>`) that brings a consumer project's harness state up to date with this Agent0 repo. Hooks, rules, tools, validators, skills, tests, `AGENTS.md`, `.mcp.json.example` plus structured merges of `.claude/settings.json` and `CLAUDE.md`. Conservative by design: `--check` is the default (read-only); the plain-file path AND the CLAUDE.md managed block do 3-way reconciliation against a recorded baseline so *stale* content (consumer untouched, Agent0 moved) auto-updates while genuinely *customized* content (consumer edited) is refused without `--force`; product code (`src/`, the consumer project's `tests/`, package manifests, `.mcp.json`) is never touched.

## Glossary

This rule and its sibling capacities use a precise vocabulary for the Agent0-consumer relationship. The relationship is **unidirectional** (Agent0 ships capacities; consumer projects install them via `sync-harness.sh`), not bidirectional like a git fork.

- **harness** — Agent0 itself, framed as a plugin/framework bundle of capacities (hooks, rules, tools, validators, skills, tests, the two entrypoints). What the consumer installs.
- **consumer project** — a project that has run `sync-harness.sh --apply` and now carries a copy of the harness. The thing on the receiving end of the unidirectional sync.
- **shipped surface** — the file set the sync manifest propagates from Agent0 to the consumer project. Equivalently: the files a consumer ends up with copies of. (Replaces the earlier term *fork-bound surface*.)
- **consumer customization** — a deliberate edit a consumer made to a shipped file; reconciliation refuses to overwrite without `--force`.
- **fork** (intentional carve-out) — reserved for the literal **git operation** ("fork the Agent0 repo on GitHub to contribute upstream"). Never used for the consumer relationship.

When in doubt, "consumer project" is the noun, "consumer" the adjective (`consumer-bound`, `consumer-specific`), `<consumer-path>` the CLI positional arg.

## What fires

Nothing automatically. The sync runs only when a developer invokes it explicitly. The Agent0 source path is **always required** — passed via `--agent0-path=PATH` or the `AGENT0_HARNESS_PATH` env var. The tool never infers it from the current directory or from the script's own location (see *Why no auto-detection* below) — the invocation is identical whether you run it standing in the Agent0 repo or anywhere else.

```bash
# Read-only drift survey (default)
bash .claude/tools/sync-harness.sh --agent0-path=~/Agent0 --check ~/some-consumer

# Apply changes
bash .claude/tools/sync-harness.sh --agent0-path=~/Agent0 --apply ~/some-consumer

# Dry-run (apply-shaped output, no writes)
bash .claude/tools/sync-harness.sh --agent0-path=~/Agent0 --apply --dry-run ~/some-consumer

# Force-overwrite consumer project customizations
bash .claude/tools/sync-harness.sh --agent0-path=~/Agent0 --apply --force ~/some-consumer

# Env-var form — convenient when scripting several consumer project syncs
AGENT0_HARNESS_PATH=~/Agent0 bash .claude/tools/sync-harness.sh --apply ~/some-consumer
```

If neither `--agent0-path` nor `AGENT0_HARNESS_PATH` is given, the tool refuses with exit code 2 and a usage hint naming both.

**Why no auto-detection.** `sync-harness.sh` is in its own propagation manifest (§ Self-rebootstrap) — an identical copy lives at `.claude/tools/sync-harness.sh` inside *every consumer project*. So neither the current directory nor `$BASH_SOURCE` can distinguish the Agent0 source from a consumer project: the script's location only reveals "which repo this copy lives in", never "is this repo Agent0". Inferring the source from either would silently sync a consumer project onto itself whenever a consumer project's own copy is run. The explicit-path requirement is the deliberate safe floor — a clean refusal beats a wrong-source sync.

## Modes

| Mode | Reads | Writes | Exit policy |
| --- | --- | --- | --- |
| `--check` (default) | Agent0 + consumer project | nothing | 0 = no drift, 1 = drift detected |
| `--apply` | Agent0 + consumer project | consumer project | 0 = clean apply, 1 = customizations refused |
| `--apply --dry-run` | Agent0 + consumer project | nothing | 0 always (decisions only) |
| `--apply --force` | Agent0 + consumer project | consumer project (incl. customized) | 0 = clean, customizations overwritten with warning |

## Customization detection — 3-way reconciliation

For plain files (the `COPY_CHECK_*` manifest — hooks, rules, tools, validators, skills, tests, agents, `.mcp.json.example`, `.gitleaks.toml`, `.githooks/pre-commit`, `.gitkeep` sentinels), the sync reconciles **three** reference points: the consumer project's copy, the recorded **baseline** (Agent0's version of the file as of the consumer project's last `--apply` — see § Sync baseline), and Agent0's current version. Three points let the tool tell a file the consumer project *deliberately edited* apart from one it simply *hasn't caught up on* — the gap the original 2-state `sha256` compare could not close.

For each plain file:

1. Consumer project's copy **missing** → copy (treated as a new file; no reconciliation).
2. Consumer project sha **==** Agent0 sha → `= up to date` (no-op).
3. Consumer project sha **!=** Agent0 sha → consult the baseline:

| `baseline` entry | relation to consumer project | verdict | behavior |
| --- | --- | --- | --- |
| present, `== consumer project sha` | consumer project untouched since last sync, Agent0 moved on | **stale** | `~ stale` → auto-update, **no `--force` needed**; counts as drift in `--check` |
| present, `!= consumer project sha` | consumer project edited the file | **customized** | `!! customized` → refuse (`--apply`) / drift (`--check`); `--force` overwrites |
| absent (no entry) | first sync, or file added to the manifest after the consumer project's last sync — the genuine pre-baseline ambiguity | **customized (no baseline)** | `!! customized <path> (no baseline)` → refuse; `--force` overwrites |

The `stale` verdict is the 3-way-reconciliation fix: a consumer project that fell behind several upstream releases no longer sees *every* upstream change as `!! customized`. Stale files auto-update on a plain `--apply` — the catch-up path that was missing. The summary line gains `N stale-updated, N removed` counters; exit codes are unchanged (`--check`: stale/removed count as drift → exit 1; `--apply`: only genuine refusals flip the exit code — stale updates and removals are successful actions).

Whitespace-only diffs are still customization. A consumer project that ran `shfmt`/`prettier` over a hook has `consumer project sha != baseline sha` → `customized`. 3-way does not normalize whitespace (that would mask real customizations). Fix: revert the formatter, or `--force` after reviewing the diff.

**Upstream deletions.** A file recorded in the baseline that is no longer in Agent0's manifest is an *orphan*. The deletion pass removes it when the consumer project copy still matches the baseline (`- removed <path>`, with now-empty parent dirs pruned bottom-up), and refuses it when the consumer project customized it (`!! customized <path> (upstream-removed)` — consumer project work is never silently destroyed; `--force` overrides into a delete). Canonical case: `templates/monorepo-skeleton/` after the `app-skeleton` rename. This mirrors, for the file tree, the symmetric ADD/REMOVE propagation the managed-block merge gave `CLAUDE.md`.

## Sync baseline

`<consumer-path>/.claude/harness-sync-baseline.json` records Agent0's managed-file sha-set as of the consumer project's last `--apply`. It is the third reference point that powers the 3-way reconciliation above. Shape:

```json
{
  "agent0_commit": "<git HEAD of the Agent0 source, or null>",
  "synced_at": "<ISO-8601 UTC>",
  "tool_version": 1,
  "files": { "<relpath>": "<Agent0 sha at last sync>", "...": "..." }
}
```

- **Per-file sha manifest, not a git ref.** Agent0's harness is verbatim-copied (no template variables), so a stored per-file sha answers "what did this file look like at last sync" *directly* — no `git show <ref>:<path>`, no dependency on Agent0's history being present or reachable (works from a tarball or shallow clone). This deliberately diverges from copier/cruft, whose git-ref model exists to re-render Jinja templates at the old ref. `agent0_commit` is recorded as a human-readable audit breadcrumb only; reconciliation never depends on it (`null` when the Agent0 source is not a git repo).
- **Git-tracked in the consumer project.** The non-dotted filename dodges the `.claude/.*` gitignore globs by design — a fresh `git clone` of the consumer project must know its baseline (same posture copier/cruft take toward `.copier-answers.yml` / `.cruft.json`). It appears in the consumer project's post-sync `git diff`; that diff *is* the "harness baseline bumped" record.
- **Written on every `--apply`** (not `--check`, not `--dry-run`), after all passes, atomically (`mktemp` + `mv`). Skipped when the resulting files-map is byte-identical to the existing baseline's — a no-op re-sync must leave the file untouched (idempotency), so `synced_at` is not churned.
- **Never shipped by Agent0.** It is a consumer project-side runtime artifact; not in any `COPY_CHECK_*` array, so the sync walk never visits it and it never appears as drift in another consumer project.

**First sync (bootstrap).** A consumer project that has never run an `--apply` under the baseline mechanism has no baseline. On that first run, files that *match* Agent0 trivially seed their baseline entry; files that *differ* are the genuine pre-baseline ambiguity (stale vs customized is unknowable with no recorded history) and are refused as `!! customized (no baseline)`. The operator does a **one-time** reconciliation — review the diffs, then `--apply --force` (adopt Agent0 wholesale) or `--apply --force --force-except='<globs of real customizations>'`. After that first run the baseline is fully seeded and every subsequent sync is clean 3-way. The friction is unavoidable (there is no history to consult) but is paid exactly once per consumer project.

## Consumer-extension convention (doc-only, no machinery)

For files the sync ships **without** a structured merge primitive (every shipped `SKILL.md`, every rule, every helper script), there is a **documentation convention** — not a mechanical merge — for where consumer-local extensions should live to keep the post-sync conflict region predictable.

**The convention.** For each shipped `SKILL.md`, the `## Notes` section is the designated extension surface. Consumer project-local additions go there. Sync will still flag the file as `!! customized` (sha-compare doesn't know about section semantics), but the conflict region is **always the same place** — making the manual merge mechanical: take the new Agent0 SKILL.md verbatim, then re-add the consumer project's `## Notes` bullets at the end.

**Why a convention, not machinery (yet).** Per-section marker-aware merge (analogous to `CLAUDE.md`'s managed-block) would require shipping `<!-- AGENT0-EXTENSION-START -->` / `<!-- AGENT0-EXTENSION-END -->` markers in every extensible file plus a per-marker merge handler in `sync-harness.sh`. That's ~200 LOC + 7 files of marker overhead. As of 2026-05-25, only **one consumer project** has surfaced this pain, with **two customizations**. Rule-of-three demand test (canonical in this project — see `.claude/rules/reminders.md`, `.claude/rules/spec-driven.md`, etc.) says: **don't pre-build the machinery**. The convention costs zero LOC and reduces manual-merge time to ~30s per file (because the conflict is always at the same heading).

**Promotion trigger.** Promote convention → machinery when **≥3 consumer projects have ≥1 `!! customized` entry on a SKILL.md or rule** OR **≥5 distinct customizations surfaced across ≥2 consumer projects**. Reminder `r-2026-05-25-re-evaluate-consumer-extension-con` (due 2026-08-25) re-evaluates against this threshold. The machinery's design template already exists: `CLAUDE.md`'s managed-block merge, `settings.json`'s structured-key merge, `.gitignore`'s additive merge — pick the closest analog and generalize.

**Other files (rules, helper scripts, etc.) don't carry the convention yet** — they're less extensible by nature (rules are policy; scripts are mechanism). If a consumer project legitimately needs to extend a rule, it customizes the file and accepts the `!! customized` flag; if consumer projects start hitting this regularly, that's the rule-of-three signal to add an extension convention to rules too.

## settings.json merge strategy

`.claude/settings.json` is structurally merged via `jq`, not hash-compared. Algorithm:

1. Read both files as JSON.
2. **Base: consumer project's settings** — preserves every top-level key the consumer project has (`permissions`, `env`, `model`, consumer-only keys, etc.). The harness owns only the keys explicitly named below; everything else is consumer project territory.
3. **Agent0-owned top-level keys overwrite when Agent0 has them** — currently `$schema` and `statusLine`. When Agent0's settings declare one of these, the consumer project's value is replaced; when Agent0 doesn't declare it, consumer project's value (if any) is preserved untouched.
4. **`hooks` merge per-event** — for each top-level `hooks.<event>` array (`PreToolUse`, `PostToolUse`, `SessionStart`, `Stop`, `PreCompact`, …):
   - Concatenate Agent0's entries and consumer project's entries.
   - `unique_by(.matcher + "|" + (.hooks[].command | join("##")))` — dedup tuple is `(matcher, ordered list of inner commands)`.
5. Write the merged JSON atomically (`mktemp + mv`).

Result: consumer-only hook entries (e.g. a consumer-specific custom hook) are preserved; Agent0 entries already in consumer project are not duplicated; new Agent0 entries are appended. Order within an event array is "consumer project's entries first, Agent0's appended" after dedup — non-binding since hooks run independently. `statusLine` propagates from Agent0 to consumer project on every sync, so the harness's canonical statusline-script registration always lands — paired with the file copy under `COPY_CHECK_GLOBS` for `.claude/presence|*.mjs`, the statusline works end-to-end after `--apply`. `permissions` is intentionally NOT in the override set (per-consumer allow/deny lists differ; permissions reconciliation is left to the consumer project developer post-sync).

**Upstream-side discipline (no permission-mode bypasses in tracked settings).** The consumer project-side preservation of `permissions` is only half the contract. The other half is the **upstream side**: Agent0's own `.claude/settings.json` MUST NOT carry permission-mode bypasses (`defaultMode: bypassPermissions`, `acceptEdits`, etc.) or pre-approved `permissions.allow` entries. These are user-ergonomic decisions — they belong in `~/.claude/settings.json` (user-global, per-developer) or `.claude/settings.local.json` (gitignored, per-machine), never in the tracked baseline that fresh clones / template-based consumer projects inherit verbatim. `permissions.deny` is the exception: blocking specific dangerous commands is genuine project policy, not user ergonomics, and may live in the tracked settings. The discipline is enforced by `.claude/tests/harness-sync/34-no-permission-bypass-in-upstream.sh`, which fails CI if `defaultMode` is set or `allow:` is non-empty in the upstream file.

**Limitations:**
- When Agent0 renames a hook (e.g. `supply-chain-scan.sh` → `supply-chain-block.sh`), the dedup key changes, so the old entry stays alongside the new one in the consumer project. The consumer project's `git diff` post-sync surfaces both; the developer prunes manually. Auto-prune deferred to v2 pending real evidence of this hurting.
- When Agent0 introduces a new harness-owned top-level key (say `analytics`), it does NOT auto-propagate to consumer projects — the override whitelist in `merge_settings_json` must be updated explicitly. This is by design (explicit > implicit); audit both files' top-level `keys` when adding a new harness-owned field, then add it to the conditional `has(…)` block.

## .gitignore merge strategy

`.gitignore` is **additively merged**, not hash-compared. Agent0's `.gitignore` carries harness-runtime entries (`.claude/.runtime-state/`, `.claude/secrets-audit.jsonl`, `.claude/delegation-audit.jsonl`, `.claude/.session-state/`, etc.) that MUST exist in every consumer project for the harness to run cleanly. Consumer projects typically ship stack-canonical `.gitignore` files (Laravel's `/vendor`, Next.js's `/node_modules`, Cargo's `/target`, etc.) that would be lost under naive overwrite. Algorithm:

1. If consumer project has no `.gitignore` → copy Agent0's verbatim via `process_file` (counted as `copied`, NOT `merged`).
2. Else extract non-comment, non-empty, trimmed lines from both files as the entry set; compute `comm -23` to find Agent0 entries the consumer project is missing.
3. If no entries missing → `= up to date` (regardless of comment/whitespace drift; entries are the semantic unit).
4. Else: append a marker line `# === Agent0 harness sync — additions ===` (only on first sync — idempotent on re-runs) followed by the missing entries, preserving Agent0's original ordering. Consumer project-specific entries are never touched.

Result: a Laravel consumer project's `.gitignore` keeps `/vendor`, `/node_modules`, `.env`, etc. verbatim, AND gets Agent0's `.claude/*.jsonl` / `.claude/.runtime-state/` / etc. appended below the marker. Idempotent: a second `--apply` reports `= up to date`; `comm -23` returns nothing because the additions from the first run are now in the entry set.

**Force-except scope** — `--force-except='.gitignore'` is honored by the merge handler too: the merge is skipped and `!! force-except .gitignore (merge skipped)` is logged, mirroring the canonical example documented under § Escape hatches. The skip is recorded in the `customized-refused` counter, and the exit code reflects refusal as it does for `process_file`-handled files. This preserves the contract that operators who explicitly say "do not touch .gitignore" get that behavior even after the merge primitive landed.

**Comments and orphans** — the marker block contains entries only, not their source-side comment groupings. Consumer project developers reviewing the post-sync `git diff` will see flat appended entries; if comment grouping matters for readability, they can reorganize after merge. Comment drift in consumer project's `.gitignore` (e.g., comments rewritten by the consumer project) is never overwritten — only the entry set is compared.

## CLAUDE.md managed-block merge strategy

Primary strategy. The consumer project's `CLAUDE.md` declares an explicit Agent0-owned region via paired HTML comment markers:

```markdown
# Consumer project title

## Overview
... consumer project-authored project narrative ...

## Gotchas
... consumer project-authored ...

<!-- AGENT0:BEGIN -->

## Spec-driven development
... Agent0 capacity body ...

## Compact Instructions
... Agent0 capacity body ...

<!-- AGENT0:END -->
```

Markers MUST be on their own lines and match exactly: `<!-- AGENT0:BEGIN -->` and `<!-- AGENT0:END -->`. The dispatcher (`merge_claude_md`) inspects the consumer project's `CLAUDE.md` and routes by 4-state detection:

| State | Trigger | Behavior |
| --- | --- | --- |
| `paired` | exactly one BEGIN, exactly one END, BEGIN before END | Run managed-block merge: 3-way reconcile the region against the recorded baseline — *stale* (consumer project region == baseline) → replace wholesale, no `--force`; *customized* (consumer project edited the block, or no baseline yet) → refuse without `--force`. |
| `absent` | no BEGIN, no END | Run legacy heading-set merge (fallback) AND write `.claude/CLAUDE.md.migration-candidate.md` proposing the wrapped layout for operator review. |
| `mismatched` | one of BEGIN/END present, not both | Refuse the file's merge with `!! claude-md: markers mismatched`; increments `customized-refused`. |
| `nested-invalid` | more than one BEGIN or END, or END before BEGIN | Refuse with `!! claude-md: nested or out-of-order markers`; increments `customized-refused`. |

**Region replacement semantics** — on `paired` state, the lines between markers are extracted from Agent0 source and substitute the consumer project's region wholesale. Project-narrative sections above BEGIN (and any trailing content after END) are preserved verbatim. The marker lines themselves are preserved exactly. This propagates Agent0 ADDs AND REMOVALs symmetrically — a section dropped upstream is gone on the next sync, fixing the legacy heading-set merge's append-only orphan bug (canonical case: `## Prototype skill` orphaning in consumer projects after it was renamed to `## Product skill`).

**3-way reconciliation of the block** — the managed block is treated as a single baseline-tracked unit, reusing the same 3-way machinery the plain-file path uses (§ Customization detection). The block's sha is recorded in `harness-sync-baseline.json` under the synthetic key `CLAUDE.md#managed-block` (`#` cannot appear in a real managed relpath, so no collision). On `paired` state with a differing region: *stale* (consumer project's region sha == the recorded baseline → consumer project never edited its block, Agent0 moved) → the block is replaced wholesale with no `--force`, counted `stale-updated`; *customized* (consumer project's region sha != baseline, or no baseline entry yet — a consumer project's first sync under this mechanism) → refused, `.claude/CLAUDE.md.diverged-region.md` written (per-section list + unified diff), `customized-refused` incremented, non-zero exit in apply mode. `--force` overwrites a customized block wholesale (`OVERWRITTEN` increments). The `AGENT0:BEGIN/END` contract makes the whole block Agent0-owned, so the reconciled unit is the entire block — there is no per-section ownership boundary. Heading-set diffs (Agent0 added or removed a section) are reconciled by the same wholesale replace, propagating ADDs and REMOVALs symmetrically.

**Migration candidate flow** — when the consumer project has no markers (state `absent`), the primary mechanism is to propose the wrapped layout via `.claude/CLAUDE.md.migration-candidate.md`. The candidate file has:

1. A leading HTML comment block explaining itself + Agent0 source SHA at generation time
2. Consumer project preamble (lines before first `## ` heading)
3. Consumer project's project-only sections (headings NOT in Agent0's region), preserving consumer project order
4. `<!-- AGENT0:BEGIN -->` marker
5. Agent0's region content, sourced verbatim from Agent0 source
6. `<!-- AGENT0:END -->` marker

The operator reviews the candidate; if it matches intent, they ratify with `mv .claude/CLAUDE.md.migration-candidate.md CLAUDE.md`. Subsequent syncs route via the `paired` state and apply managed-block semantics. There is no `--migrate-claude-md` flag — the operator's `mv` IS the ratification step (deliberate design decision).

**Per-section divergence blocks migration** — candidate generation runs `_check_section_divergence` against Agent0's region first; if the consumer project rewrote the body of any Agent0-region-titled section, the candidate is NOT written. Instead `.claude/CLAUDE.md.diverged-sections.md` is written listing the diverged titles. Legacy fallback merge still runs (zero disruption — consumer project keeps its custom body, gets new capacity sections appended). The operator either renames the heading (removing it from the Agent0-managed namespace) or accepts Agent0's body, then re-runs sync.

**Source must be wrapped for candidate generation** — `_generate_migration_candidate` no-ops when Agent0 source itself has no markers. Markers define the "Agent0-managed namespace"; without them, every `## ` in Agent0 source would be treated as Agent0-owned, falsely flagging consumer project's `## Overview` body customization as divergence. Agent0's own `CLAUDE.md` ships wrapped.

**Mode interaction** — `--check` and `--apply --dry-run` both detect drift but write no files; the dispatcher emits the same advisory shape on stderr ("would write candidate" / "would diverge"). Only `--apply` (no dry-run) writes the candidate or diverged-* reports.

**Idempotency** — once the consumer project is migrated (markers paired, region matches Agent0 source), `--apply` reports `= up to date` and produces zero mutations. `sha256sum` of `CLAUDE.md` is stable across consecutive applies.

This marker-aware merge primitive applies to `CLAUDE.md` only. `AGENTS.md` is intentionally synchronized as a plain baseline-tracked file because Codex has native override-chain primitives (`AGENTS.override.md` and nested `AGENTS.md`) for consumer-local instruction layering.

## CLAUDE.md heading-set merge strategy (legacy fallback)

The legacy fallback strategy. Active only when the consumer project's `CLAUDE.md` lacks paired markers (state `absent` in the dispatcher). Heading-set comparison, **not** full-file hash. Consumer project-authored sections (Overview, Stack, Conventions, Gotchas, etc.) intentionally diverge from Agent0; a full-hash compare would always flag CLAUDE.md as customized and break the workflow. Algorithm:

1. Extract `^## <Title>` lines from Agent0's and consumer project's CLAUDE.md.
2. Compute the set of headings in Agent0 missing from consumer project.
3. If none missing → `= up to date` (regardless of body drift).
4. Else: locate the line containing `## Compact Instructions` in consumer project's CLAUDE.md (the canonical "always last" anchor). Insert the missing sections (full body extracted from Agent0 via awk) immediately before that line.
5. If `## Compact Instructions` is absent in consumer project: emit `!! claude-md: missing "## Compact Instructions" anchor — appending at EOF` warning, append at EOF. Developer reorganizes manually if EOF placement is wrong.

Consumer project-authored sections are always preserved verbatim — the sync only writes Agent0-sourced sections that consumer project is missing. Append-only is the structural limitation that the managed-block merge supersedes: a section REMOVED from Agent0 stays as an orphan in consumer project CLAUDE.md until that consumer project migrates to the wrapped layout.

## Manifest scope

Encoded in three arrays at the top of `sync-harness.sh`:

- **`COPY_CHECK_RECURSIVE`** — `find -type f` under each base: `.claude/skills/`, `.claude/tests/`, `.claude/agents/`. Recursive walks; subdirs preserved.
- **`COPY_CHECK_GLOBS`** — `dir|pattern` pairs, single-level: `.claude/hooks/*.sh`, `.claude/rules/*.md`, `.claude/tools/*.sh`, `.claude/validators/*.sh`.
- **`COPY_CHECK_FILES`** — literal paths: `AGENTS.md`, `.mcp.json.example`, `.gitleaks.toml`, `.githooks/pre-commit`, `.claude/tools/lib/managed-block.sh`, `.claude/memory/.gitkeep`, `.claude/.browser-state/.gitkeep`.
- **Structured merge** (not in COPY_CHECK): `.claude/settings.json`, `CLAUDE.md`, `.gitignore`.

The walk only reads from Agent0 manifest paths. Out-of-scope consumer project content (`src/`, consumer project's `tests/` outside `.claude/tests/`, `docs/`, `package.json`, `Cargo.toml`, `pyproject.toml`, `.mcp.json`, `.env*`, `target/`, `node_modules/`, `.venv/`, `dist/`, `build/`) is **implicitly invisible** — no denylist guard fires because nothing in the manifest points at those paths. This means adding a new path to the manifest is the only way to extend scope; the safety floor is the manifest itself.

**Deletion propagation.** The walk also accumulates Agent0's *current* manifest into a sha-set; the deletion pass compares that set against the recorded baseline's file list. A path present in the baseline but absent from the current set is an upstream removal, propagated per § Customization detection § *Upstream deletions*. Out-of-scope consumer project content stays invisible to this pass too — it only ever considers paths that were *previously* in the manifest (and therefore recorded in the baseline), never arbitrary consumer project files. A consumer project with no baseline skips the deletion pass entirely.

## Self-rebootstrap

`sync-harness.sh` is itself in the propagation manifest (`COPY_CHECK_GLOBS` → `.claude/tools/*.sh`) — the tool syncs *itself*. That is a hazard: when a consumer project's copy is stale, an `--apply` invoked as `bash <consumer-path>/.claude/tools/sync-harness.sh …` overwrites the very file bash is executing. Bash reads scripts incrementally, tracking a byte offset into the file; an in-place whole-file overwrite mid-run leaves that offset pointing into misaligned bytes, and the run crashes (`unbound variable`, a syntax error) or — worse — silently executes the wrong code.

An `--apply` therefore runs a **self-rebootstrap pre-flight** immediately after `load_baseline` and before the first write (`walk_copy_check`). The pre-flight computes whether *this run will overwrite the consumer project's `.claude/tools/sync-harness.sh`* — true when that file is `stale` (auto-update) or `customized` under `--force`; false when it is up to date, or `customized` and refused without `--force`. If the run will overwrite it, the tool copies Agent0's current `sync-harness.sh` to a `mktemp` file and `exec`s that copy with the original arguments. The re-exec'd process executes from the stable temp file, so when it later overwrites the consumer project's `sync-harness.sh` it is writing a file it is not reading from — single run, no crash. One stderr line (`sync-harness: self-update detected — re-executing from a stable copy`) marks the re-exec; otherwise it is invisible.

The re-exec is guarded by the internal env var `AGENT0_SYNC_REBOOTSTRAPPED` (exported onto the re-exec'd process so it never loops), and the temp copy is removed by `_sync_cleanup` on exit (its path travels in `AGENT0_SYNC_REBOOTSTRAP_TMP`). `--check` and `--apply --dry-run` never write, so the pre-flight is a no-op for them.

## Escape hatches

- `--force` — overwrites customized files. Use after reviewing the diff (`diff <consumer-path>/file <agent0>/file`) and confirming the consumer project's edits are not load-bearing.
- `--force-except=GLOB[,GLOB...]` — comma-separated globs matched against the per-file relative path. Files matching any glob keep their customized-refused outcome even under `--force`. Canonical use: `--force --force-except='.gitignore'` to adopt drift-only Agent0 updates while preserving consumer project's stack-specific `.gitignore` patterns. Glob semantics are Bash `case` patterns (`*`, `?`, `[abc]`). Anchored against the full relative path from consumer project root.
- `AGENT0_HARNESS_PATH=<path>` — env-var alternative to `--agent0-path`. Convenient when scripting multiple consumer project syncs.
- `--dry-run` — combines with `--apply` to emit decision lines without writing. First-pass discovery on a new consumer project should always be `--check` or `--apply --dry-run`.

There is no `CLAUDE_SKIP_HARNESS_SYNC` env var — the tool is developer-invoked, not hook-triggered, so per-session disable doesn't apply.

## Audit

The recorded baseline (`<consumer-path>/.claude/harness-sync-baseline.json`) is the sync audit record. It is git-tracked in the consumer project, so `git log -- .claude/harness-sync-baseline.json` shows every sync the consumer project ever applied, each commit's diff shows which managed files changed sha, and `agent0_commit` names the Agent0 revision synced against (when the source was a git repo). Combined with the post-sync `git diff` of the rest of the tree, this is the full audit trail — no separate log, no auto-commit. The consumer project developer reviews the diff and commits manually. Same posture as every other harness primitive that mutates consumer project state.

The sync baseline file subsumes the need for a separate audit log — it is both the reconciliation input and the audit record, so a separate log is not built.

## Gotchas

- **`AGENTS.md` is plain baseline-tracked, not marker-merged.** This asymmetry is intentional. `CLAUDE.md` needs a marker-aware merge because Claude Code has no native override-file chain; Codex does have one (`AGENTS.override.md`, nested `AGENTS.md`), so root `AGENTS.md` remains Agent0-owned and consumer-local Codex guidance belongs in those Codex-native override surfaces. Do not promote `AGENTS.md` to structured merge without a follow-up spec and rule-of-three demand evidence.
- **`## Compact Instructions` anchor missing.** The CLAUDE.md merge looks for this line as the insertion point. A consumer project that has removed or renamed it will trigger the EOF-fallback warning; capacity sections land at EOF, which may not be the right place. Fix: restore the anchor in consumer project's CLAUDE.md, or reorganize after sync.
- **Whitespace-only customization false-positive.** A consumer project that ran `shfmt` / `prettier` over a hook script will have hash-mismatch despite semantic equivalence. The sync flags it as customized. Fix: revert the formatter, OR use `--force` consciously after reviewing the diff. The tool does NOT normalize whitespace (would mask real customizations).
- **`settings.json` array growth on hook renames.** When Agent0 renames a hook, both old and new entries land in the consumer project's settings.json (different dedup keys). The consumer project developer must prune manually post-sync. The `git diff` makes this visible; auto-prune deferred to v2.
- **Consumer project-only files survive the deletion pass.** The deletion pass only removes paths recorded in the baseline — files Agent0 once shipped and has since dropped. A consumer project-authored file that was never in Agent0's manifest (e.g. `.claude/tests/<capacity>/99-consumer project-extra.sh`) has no baseline entry, so the deletion pass never considers it. Consumer project-only additions survive every sync.
- **`core.hooksPath` activation is NOT automatic.** Sync writes `.githooks/pre-commit` but does NOT run `git config core.hooksPath .githooks` in the consumer project. Same Lazarus-vector reasoning as in `.claude/rules/secrets-scan.md` § Gotchas — the consumer project developer activates consciously, post-sync.
- **Concurrent `--apply` from two terminals.** No locking. Second writer overwrites first's output. Unlikely in practice; the operation is a deliberate developer action, not a hot loop.
- **Bash 3.2 / macOS portability.** The script uses `mapfile`-free patterns (`while IFS= read -r ... done < <(...)` instead of `mapfile`) and avoids `declare -A`. Same baseline every other hook in this repo follows.
- **First sync on a long-stale consumer project produces a large diff.** A consumer project that skipped several upstream releases will see ~30+ new files in one apply. Review the diff section-by-section, not as one giant blob: hooks first, rules second, tools third, then settings.json + CLAUDE.md. Commit in one go (`chore(harness-sync): adopt Agent0 specs NNN-MMM`) so the audit trail is clean.
- **One-time first-sync reconciliation for consumer projects with no baseline.** A consumer project with no `harness-sync-baseline.json` cannot tell stale from customized on its first `--apply` — every differing file is refused as `!! customized (no baseline)`. Resolve once with `--force` / `--force-except`; the baseline is then seeded and every subsequent sync is clean 3-way. See § Sync baseline § *First sync*.
- **A pre-rebootstrap consumer project still crashes once on the upgrade that installs the fix.** The self-rebootstrap guard (§ Self-rebootstrap) lives *inside* `sync-harness.sh`, so a consumer project whose copy predates it runs the old, unguarded script on the very `--apply` that updates `sync-harness.sh` — that one run self-overwrites and crashes (or stops short). It is harmless: the crashed run already wrote the new `sync-harness.sh`, so re-running `--apply` completes cleanly (the now-current script rebootstraps correctly, or no longer needs to). Same one-time-transitional shape as a no-baseline first sync; every `--apply` after it is single-run and crash-free.
- **Baseline lookup is Bash-3.2-safe.** No `declare -A` (repo-wide constraint). `load_baseline` dumps the baseline's `.files` map to a sorted `relpath<TAB>sha` temp file via one `jq` call; per-file lookup is an `awk` exact-match scan against that file — no per-file `jq` invocation (a 500-file consumer project would be slow). The deletion pass likewise reads the manifest/baseline as sorted temp files.
- **Hand-editing `harness-sync-baseline.json` is a footgun.** A wrong sha just mislabels one file stale-vs-customized — recoverable on the next sync, lower-severity than copier's `.copier-answers.yml` warning, but the file is still tool-owned: let `--apply` maintain it.
- **A malformed baseline fails open.** If the JSON is unreadable, the sync logs `!! harness-sync-baseline.json unreadable/malformed — treating as no baseline` and proceeds 2-state for that run, then rewrites a clean baseline on `--apply`. A broken baseline never blocks a sync.
- **No bidirectional sync.** Improvements made in a consumer project do NOT flow back to Agent0 via this tool. Consumer project developers PR-review their improvements upstream. The tool is deliberately one-way to keep the dependency graph clean (Agent0 is upstream-of-everything).
- **`settings.json` references files OUTSIDE the manifest cause silent breakage in consumer projects.** Two distinct sub-bugs surfaced through statusline dogfood, both shipped fixes:
  - **Sub-bug A (2026-05-12 dogfood):** `settings.json.statusLine.command` referenced `.claude/presence/statusline.mjs`, but `.claude/presence/` was missing from `COPY_CHECK_GLOBS`. Fix: `.claude/presence|*.mjs` added to `COPY_CHECK_GLOBS`.
  - **Sub-bug B (2026-05-19 dogfood):** even after sub-bug A's fix, consumer projects were still missing the `statusLine` block in their `settings.json`. Root cause: `merge_settings_json` jq expression emitted `{hooks: ...}` only, silently dropping every other top-level key (`$schema`, `statusLine`, `permissions`, `env`, `model`) from both sides. Fix: merge function rewritten to use consumer project's settings as the base + explicit whitelist of upstream-owned keys (`$schema`, `statusLine`) + the existing per-event hooks dedup. Regression test: `.claude/tests/harness-sync/23-settings-merge-toplevel-keys.sh`.
  - **Upstream maintainer rule:** when adding any new directory under `.claude/` that ships scripts referenced by hooks/settings, add a matching entry to `COPY_CHECK_RECURSIVE` or `COPY_CHECK_GLOBS`. The audit `git ls-files .claude/ | awk -F/ '{print $1"/"$2}' | sort -u` lists current subdirs; cross-check against the manifest arrays. When adding a new harness-owned top-level key to `settings.json` (beyond `hooks`/`$schema`/`statusLine`), also add it to the conditional `has(…)` block in `merge_settings_json` — otherwise the key won't propagate.
- **`.gitignore` template is stack-agnostic — consumer projects MUST uncomment per-stack patterns post-clone.** Agent0's `.gitignore` ships with `# node_modules/`, `# .venv/`, `# target/`, etc. all commented out (template is intentionally stack-agnostic; consumer projects customize per their actual stack). A consumer project that forgets to uncomment its stack's lines leaves `git ls-files --others --exclude-standard` dumping thousands of paths into validator's TDD warning loop, hanging the post-edit-validate hook for minutes. The validator gained a defensive grep filter (2026-05-12, validators/run.sh) that strips common noise dir prefixes before the per-file loop — but the consumer project's correct `.gitignore` remains the primary control. Audit any consumer project's first session: `git -C <consumer-path> ls-files --others --exclude-standard | awk -F/ '{print $1}' | sort | uniq -c | sort -rn | head` should show low counts for `node_modules`/`target`/`.venv`/etc.
