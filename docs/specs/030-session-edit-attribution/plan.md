# 030 — session-edit-attribution — plan

_Drafted from `spec.md` on 2026-05-16. Update this file if implementation reveals the plan is wrong; do NOT silently diverge._

## Approach

Add a new `PostToolUse(Edit|Write|MultiEdit)` hook — `.claude/hooks/session-track-edits.sh` — that appends each edited `file_path` (normalized to repo-relative, deduped within a session) to `.claude/.session-state/<session_id>/edited-files.txt`. The hook reuses the same `session_id` sanitization and per-`session_id` subdir convention established by spec 017 and consumed by session-start/session-stop today.

Extend `.claude/hooks/session-stop.sh` with a **primary decision step** placed *before* the spec-023 porcelain-compare. **Pair with a one-line SessionStart change** that seeds an empty `edited-files.txt` so the file's PRESENCE means "this session ran with the tracker installed" (zero or more recorded edits), and ABSENCE means "tracker not installed in this session" (legacy):

1. If `edited-files.txt` exists and is empty → `exit 0` silently. SessionStart created the empty file; the tracker hook never appended; the session edited nothing the tracker could see. Bystander or Bash-only.
2. If `edited-files.txt` exists and is non-empty, but every listed path is clean in `git status --porcelain` (committed or reverted) → `exit 0` silently.
3. If `edited-files.txt` exists and at least one listed path is still dirty → fall through to the existing block-unless-SESSION-updated logic (Stop sets `OWN_DIRTY_WIP=1` and skips the spec-023 compare to avoid redundant decision).
4. If `edited-files.txt` does NOT exist (legacy sessions started before this spec landed) → fall through to spec 023 unchanged.

**Trade**: case 1 collapses two real-world classes — pure bystander AND Bash-only-edit sessions — into the same silent-pass branch. The Bash-edit case becomes a silent miss (user edits via `sed -i`, forgets SESSION.md, no nag). Accepted because (a) bystander quiet was the primary goal driving the spec; (b) the dominant agent edit path is Edit/Write/MultiEdit; (c) Bash-arg parsing for path attribution is fragile.

Spec 023's porcelain-compare stays in place as fallback. Spec 023 is not marked superseded — its mechanism still covers the cases the new tracker can't see (Bash-driven edits, IDE saves, external scripts, legacy sessions).

The hook matcher uses the existing project convention `Edit|Write|MultiEdit` (parity with `post-edit-validate.sh` / `secrets-advise.sh` / `supply-chain-advise.sh`). `NotebookEdit` is deliberately omitted v1 (no `.ipynb` files in the project today; adding the matcher is a one-line change a fork can make when it needs it).

Hook body must be cheap (target < 5 ms): single `jq` invocation to parse stdin, sanitize `session_id`, append with `flock` for safety against parallel sub-agent tool calls. Fails open on every error path — a broken tracker hook must never block a tool call. Path normalization: relative to `CLAUDE_PROJECT_DIR` (matches porcelain output shape); paths outside the project dir get logged as-is and are simply no-op at the Stop check (never match porcelain).

## Files to touch

**Create:**
- `.claude/hooks/session-track-edits.sh` — new PostToolUse hook. Reads stdin payload, extracts `session_id` + `tool_input.file_path`, sanitizes, normalizes path to project-relative, `flock`-atomic append (deduped) to `<state-dir>/edited-files.txt`. Fails open on every branch.
- `docs/specs/030-session-edit-attribution/spec.md` — already created in `/sdd new`.
- `docs/specs/030-session-edit-attribution/tasks.md` — created by `/sdd tasks` after this plan is reviewed.

**Modify:**
- `.claude/hooks/session-start.sh` — add a single `touch "$STATE_DIR/edited-files.txt"` line right after the `started-at` touch, BEFORE the `start-porcelain.txt` snapshot. This is the marker that says "this session is tracker-enabled"; the tracker hook appends to it on each Edit/Write/MultiEdit.
- `.claude/hooks/session-stop.sh` — insert the primary edit-attribution check between the "no uncommitted changes → exit 0" guard (current line 50) and the spec-023 porcelain-compare (current lines 58-63). New block reads `edited-files.txt`; on present-and-resolved → `exit 0`, on present-and-dirty → set a marker variable so the fall-through skips the spec-023 path (already-decided-to-block), on absent → fall through to spec-023 unchanged.
- `.claude/settings.json` — add a third hook command under the existing `PostToolUse` matcher `Edit|Write|MultiEdit` block: `bash "$CLAUDE_PROJECT_DIR"/.claude/hooks/session-track-edits.sh`. No new matcher block; piggyback on the existing one so hook ordering stays deterministic.
- `.claude/rules/session-handoff.md` — extend § *State files* with `edited-files.txt` (line-per-path, deduped, gitignored, swept by the existing 7-day cleanup). Rewrite § *Carryover discrimination* to name the new tracker as primary signal and demote spec 023's porcelain-compare to fallback. Add a short new § *Edit attribution* describing the contract (Edit/Write/MultiEdit → tracked; Bash/IDE → fallback) and pointing at spec 030.
- `.claude/tests/test_session_stop.sh` (if it exists; else added to whatever test runner the harness uses) — extend with 5 new scenarios mirroring the spec acceptance criteria (bystander, own-uncommitted, own-committed, own-reverted, legacy-session). Per `.claude/rules/tdd.md`, tests land in the same diff as the behavior they cover.

**Delete:**
- None.

## Alternatives considered

### Sibling-session exclusion via cross-reading sibling `start-porcelain.txt`

At Stop, scan `.claude/.session-state/*/start-porcelain.txt` for sibling baselines; any file appearing as dirty in another active session's baseline gets excluded from "my session's responsibility".

Rejected because: imprecise when 2+ sessions touch the same path (no way to choose ownership); still purely inferential; doesn't help legacy-session or Bash-edit cases (which fall back to today's logic anyway); adds cross-session file reads at Stop, growing the hook's I/O surface. Per-session edit tracking via `session_id` payload is the direct primitive — nothing structural to add on top.

### Per-file mtime compare ("did the file change after my started-at?")

Compare each dirty file's filesystem mtime against `started-at`; older → not this session, exclude.

Rejected because: mtime is unreliable for git purposes — staging, `git restore`, partial reverts, and IDE-driven content-preserving writes all play games with mtime that don't correlate with "did this session edit". Adds false-positive risk in the *other* direction (a file genuinely edited via Edit early in the session, then untouched, might appear as "older than started-at" if mtime got reset). The hook-payload-driven attribution avoids the filesystem-truth question entirely.

### PostToolUse(Bash) also tracked, parsing Bash args for file paths

Add a second matcher on `Bash`, parse the command line for arguments that look like file paths (e.g., the target of `sed -i`, `cat >`, `tee`).

Rejected because: Bash command-line parsing is fragility (`sed -i.bak path`, `find … -exec sed -i {}\+`, redirections via `eval`, etc.). 90%+ of agent-driven file mutations go through Edit/Write/MultiEdit; the remaining 10% (Bash-driven, IDE saves, external scripts) fall to spec 023's porcelain-compare safety net, which already handles them today. The cost-to-coverage ratio of correct Bash tracking does not justify the implementation complexity at v1.

### Behavioural-only: lean harder on `## Parallel WIP` in `SESSION.md`

Reinforce the existing convention in `session-handoff.md` (humans/agents write a bullet declaring active parallel work) and accept the false-positive as the cost of not building hook machinery.

Rejected because: the convention already exists and didn't prevent today's incident (research-only sessions don't write `## Parallel WIP` bullets because they're not the parallel-work claimant). The false positive is mechanical, so the fix should be mechanical — pushing it into the convention puts the burden on every future session author to remember a step that isn't theirs. The convention stays useful for *coordination* (claiming paths); spec 030 handles the *attribution* problem orthogonally.

## Risks and unknowns

- **Bash-driven and out-of-band edits remain attribution-blind.** Acknowledged in spec; fallback to spec 023 covers them with today's behavior. Risk-of-regression: zero. Risk that the false-positive class moves rather than disappears: real — if a user routinely edits via `sed -i` in `Bash` and expects the new tracker to catch it, they'll see legacy-session-shape nags. Documentation in § *Edit attribution* of the rule doc must call this out explicitly.
- **Hook latency on hot edit loops.** PostToolUse runs synchronously. A delegated sub-agent doing many small `Edit` calls would compound any per-hook cost. Measured 2026-05-16: ~30-50 ms per tracker invocation (bash startup + 2× jq + realpath + flock). The original ≤ 5 ms target was unrealistic for a bash+jq hook; bash startup alone is ~20 ms on Linux. The measured cost is acceptable next to existing PostToolUse(Edit) siblings — `post-edit-validate.sh` runs the project validator (seconds), `secrets-advise.sh` parses configs, etc. — so the tracker is a rounding error on the hot path. Future optimization (combine jq calls, skip realpath for relative paths) is deferred until empirical hot-path pressure emerges.
- **`flock` semantics on non-POSIX filesystems.** This repo assumes standard ext4/btrfs/zfs; `flock` works. A fork mounting `.claude/` from a network share (NFS, SMB) could see degraded locking. Out of scope to fix here; document as known-limitation in § *Gotchas* if it surfaces.
- **Path-normalization edge cases.** Symlinks, paths with embedded `..`, paths outside `CLAUDE_PROJECT_DIR`. Plan: use `realpath --relative-to=` if available; fall back to `printf '%s'` (literal). Outside-project paths get logged as-is and produce no Stop-time match against `git status --porcelain` (no false block, no false silence — correct behavior by default).
- **Sub-agent edits attribute to parent's `session_id`.** Per hook payload spec, sub-agent dispatches via `Agent` tool re-enter the same `session_id`; their Edit calls correctly attribute to the parent session. Verify by reading `.claude/delegation-audit.jsonl` shape and the existing `post-edit-validate.sh` actor-detection logic.
- **What if a session is killed mid-edit (Ctrl-C, crash)?** `edited-files.txt` keeps its rows; the next SessionStart with the same `session_id` is impossible (kills release the session_id). The 7-day cleanup sweeps the orphaned state-dir. Same posture as the existing `nagged` / `started-at` files; no new failure mode.
- **Spec 023 demotion language in the rule doc.** Spec 023 stays `shipped`, not `superseded` — its mechanism remains live and load-bearing. The rule doc rewrite must be careful not to imply 023 is dead.

## Research / citations

- `.claude/hooks/session-stop.sh` (current) — the file being extended; specifically the spec-023 porcelain-compare block at lines 58-63 is the insertion site.
- `.claude/hooks/session-start.sh` (current) — companion that already writes the per-session state dir and `start-porcelain.txt`; demonstrates the `jq`-parse-stdin-and-sanitize-session_id pattern reused verbatim.
- `.claude/rules/session-handoff.md` — protocol doc; canonical anchor for the new tracker's contract.
- `docs/specs/017-session-state-isolation/` — established the per-`session_id` subdir layout this spec extends.
- `docs/specs/023-session-stop-noop-aware/` — direct predecessor; its `## Gotchas` section already calls out the bystander false-positive class, naming it as future-work.
- Hermes-agent session 2026-05-16, transcript file `~/.claude/projects/-home-goat-Agent0/95b868a2-7367-425d-83ff-f11579d65fe6.jsonl` — forensic evidence behind this spec: `start-porcelain.txt` empty at 13:23, step-09 files modified out-of-band at 13:26 and 13:27, sibling session `c0f47da9` captured the dirty state in its own `start-porcelain.txt` at 13:27:33, hermes Stop fired at 13:27:48 with spec-023 compare flagging a difference whose true source was out of scope of the session.
- `.claude/settings.json` `PostToolUse` block — pattern of co-locating multiple `bash …` commands under one `matcher: "Edit|Write|MultiEdit"` block is the precedent we extend.
