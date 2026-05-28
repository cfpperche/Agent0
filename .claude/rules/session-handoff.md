---
paths:
  - ".agent0/HANDOFF.md"
  - ".agent0/hooks/session-start.sh"
  - ".agent0/hooks/session-stop.sh"
  - ".agent0/hooks/session-track-edits.sh"
  - ".codex/config.toml.example"
  - ".agent0/.session-state/**"
---

# Session handoff

`.agent0/HANDOFF.md` is the canonical work-state handoff for Agent0 sessions. It is runtime-neutral: Claude Code receives it automatically through hooks, and Codex receives it through opt-in hooks plus the `AGENTS.md` convention.

Codex receives the same hook-backed handoff behavior after the user copies `.codex/config.toml.example` to `.codex/config.toml`, enables hooks, and uncomments the session-handoff blocks.

## Runtime enforcement

- **Claude Code**: `SessionStart` (`.agent0/hooks/session-start.sh`) injects `.agent0/HANDOFF.md`; `Stop` (`.agent0/hooks/session-stop.sh`) nags once per session when Claude leaves dirty own work without updating `.agent0/HANDOFF.md`; `PostToolUse(Edit|Write|MultiEdit)` (`.agent0/hooks/session-track-edits.sh`) records edited paths for bystander discrimination.
- **Codex CLI**: after opt-in via `.codex/config.toml.example`, `SessionStart` injects `.agent0/HANDOFF.md`; `Stop` uses Codex's continue-with-corrective-prompt contract (`{"decision":"block","reason":...}`) for nag-once parity; `PostToolUse(^apply_patch$)` records edited paths parsed from patch headers.

Codex `Stop` does not reject termination byte-for-byte like a Claude stop block. `decision: "block"` tells Codex to continue and creates a new continuation prompt from `reason`. The shared hook exits silently when Codex sends `stop_hook_active=true` or when the per-session `nagged` marker is already set.

## What to write in HANDOFF.md

Update before ending a session that touched the repo. Use exactly these four short sections:

- **Current State** — what is working, what is broken, what is in flight.
- **Active Work** — live parallel-work claims. One bullet per active thread, using the grammar below.
- **Next Actions** — concrete tasks for the next session.
- **Decisions & Gotchas** — non-obvious choices made, traps discovered, and context future sessions need.

## Active Work coordination

`Active Work` replaces the old `Parallel WIP` convention. Bullet grammar:

```markdown
- <owner runtime> — <intent> — paths: <path list> — release: <condition>
```

Examples:

```markdown
- Claude Code — implementing auth spec — paths: `src/auth/*`, `tests/auth/*` — release: when PR #42 is merged.
- Codex CLI — auditing handoff hooks — paths: `.agent0/hooks/session-*.sh` — release: when validation commands in spec 101 pass.
```

Rules:

- **Owner runtime is required.** Use a clear runtime label such as `Claude Code`, `Codex CLI`, or `human`.
- **Touched paths are required.** Name files, directories, or globs another session should avoid.
- **Release condition is required.** Prefer observable conditions: a commit lands, a PR merges, a named test passes, or the owner removes the bullet.
- **The owner removes the bullet.** A bullet is a live claim, not a journal.
- **No empty scaffolding.** If no parallel work is active, write a short empty-state line instead of keeping stale claims.

## SessionStart fallback

`session-start.sh` uses a two-layer handoff source decision:

1. If `.agent0/HANDOFF.md` exists, inject it under `=== HANDOFF.md (canonical handoff) ===`.
2. Else emit a one-line `handoff-advisory` that `.agent0/HANDOFF.md` is missing and proceed without aborting the session.

`SessionStart` applies the same handoff decision for `source=startup`, `source=resume`, `source=clear`, and `source=compact`. On `source=compact`, it also injects the latest `.claude/.compact-history/*.md` snapshot additively; compact-history never replaces the canonical handoff.

## Size discipline

**Target: `.agent0/HANDOFF.md` ≤ 4 KB.** The SessionStart hook serves the file verbatim via `cat`; the Claude Code harness truncates injected hook outputs past roughly 2-3 KB into a preview + a sidecar persisted-output file. When HANDOFF.md grows past the cap, the next session's agent may receive a partial preview and miss the immediate next step.

The cap is enforced behaviorally at session end, not by tooling. **Prune before write** when closing a session:

1. **Migrate durable entries out.** Anything that survives this session as "future-me will want to know this" belongs in a memory file, not HANDOFF.md. Project-factual knowledge goes to `.agent0/memory/<topic>.md`. Behavioral guidance goes to `~/.claude/projects/<path>/memory/feedback_<topic>.md`. The handoff entry then becomes a short pointer at most.
2. **Drop entries already in commit messages or specs.** `git log --oneline` + `docs/specs/NNN-*/` are the audit trail.
3. **Replace, don't append.** Previous "Next Actions" are replaced by this session's. Previous "Current State" is overwritten, not extended.
4. **Keep Active Work live.** Resolved bullets disappear; they do not earn "done" badges.

If the file is past 4 KB at session end, prune again. The Stop hook does not enforce the size cap today.

## Reader-side defense — read the source when injected output is truncated

When Claude Code truncates a large hook output, it preserves the full output to a sidecar file and shows only a preview. **Scan for truncation markers and read the source file before answering anything that depends on the injected block.**

Markers that mean the block is partial:

- `Output too large (N KB).`
- `Full output saved to: <path>`
- `<persisted-output>`
- `Preview (first N KB):`
- A block that ends with `...` and no closing delimiter.
- A `=== <SOURCE> ===` block that opens but never closes with `=== end <SOURCE> ===`.

Before responding to anything that depends on a truncated block:

1. Identify the source file, usually `.agent0/HANDOFF.md`, `.claude/.compact-history/<snapshot>.md`, or another hook-injected file.
2. Read it directly, full file.
3. Then answer from the source, not the partial preview.

## Escape hatch

Set `CLAUDE_SKIP_SESSION_HOOKS=1` to disable Stop-hook enforcement for quick Q&A sessions where no commit is intended. SessionStart injection still runs.

## State files

`.agent0/.session-state/<session_id>/` holds four ephemeral artifacts per runtime session: `started-at` (touched by `SessionStart`), `nagged` (touched by `Stop` when it nags), `start-porcelain.txt` (a snapshot of `git status --porcelain` captured by `SessionStart`), and `edited-files.txt` (per-session list of Claude Edit/Write/MultiEdit paths and Codex `apply_patch` paths, append-only with dedup, populated by `session-track-edits.sh`; seeded empty by `SessionStart` so presence means "tracker-enabled"). Gitignored — do not commit.

`session_id` comes from the stdin payload each runtime passes to hooks (`$.session_id`). When absent, or when it contains characters outside `^[a-zA-Z0-9_-]+$`, hooks fall to the literal subdir `unknown`.

`SessionStart` runs a best-effort cleanup of `.agent0/.session-state/*` subdirs older than 7 days. Cleanup failures never block the hook.

### Edit attribution

The primary signal is `edited-files.txt`:

- **File present, empty** → session edited nothing the tracker could see → `exit 0` silently. This protects read-only Claude sessions from being nagged for Codex or sibling-session edits.
- **File present, non-empty, every listed path clean in `git status --porcelain`** → `exit 0` silently.
- **File present, non-empty, at least one listed path still dirty** → fall through to the block-unless-HANDOFF-updated path.
- **File absent** → legacy session or tracker disabled → fall through to porcelain-compare fallback.

Tradeoff: file-present-and-empty treats pure bystander and Bash-only-edit sessions the same. Sessions that edit exclusively through shell commands may not be nagged. Accepted because the dominant agent edit paths are Claude Edit/Write/MultiEdit and Codex `apply_patch`; Bash path attribution is fragile.

### Carryover discrimination

For legacy or tracker-absent sessions, `SessionStart` writes `start-porcelain.txt` and `Stop` compares it to current `git status --porcelain`. Byte-identical means no new WIP from this session and exits silently. Different means Stop checks whether `.agent0/HANDOFF.md` was updated after `started-at`; if not, it blocks once.

Missing snapshot is the conservative fallback: Stop skips comparison and uses the mtime check.

`/compact` and `/resume` both fire `SessionStart` with the same `session_id`, so the snapshot is overwritten at compaction/resume time and becomes the new baseline. Correct: pre-compact work should already be committed or reflected in `.agent0/HANDOFF.md`.

## Cross-capacity dependency

`.agent0/tools/probe.sh` reads `started-at` as the "session boundary" signal to detect stale snapshots. It scans `.agent0/.session-state/*/started-at` and takes the maximum mtime as the conservative boundary. Parallel sessions can produce conservative false positives; safe direction is to re-run the verifier.
