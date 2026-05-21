# 072 — sync-harness-self-overwrite — plan

_Drafted from `spec.md` on 2026-05-21. Update this file if implementation reveals the plan is wrong; do NOT silently diverge._

## Approach

The fix interposes a **startup self-rebootstrap** between argument parsing and the orchestration block. `sync-harness.sh` runs top-to-bottom with no `main()` — arg parse (lines 50-83), source/fork resolution + sanity (84-112), then function definitions, then the orchestration tail (`load_baseline` → `walk_copy_check` → … → `write_baseline`). `walk_copy_check` is what overwrites `$FORK_ROOT/.claude/tools/sync-harness.sh`; since the operator invokes the *fork's* copy, that whole-file overwrite corrupts the running process — bash tracks a byte offset into the script file and an entire-file replacement leaves the offset pointing into misaligned bytes ([Baeldung]; the "overwritten entirely" failure mode it names is exactly `walk_copy_check`'s full-file copy). The fix: before the orchestration writes anything, a new `_self_rebootstrap` pre-flight detects whether *this run will overwrite the fork's `sync-harness.sh`*, and if so copies Agent0's current version to a `mktemp` file and `exec`s it with the original arguments. The re-exec'd process executes from the stable temp file — a file nobody overwrites — so when it later writes the fork's `sync-harness.sh` it is writing a file it is not reading from. Single run, no crash, invisible to the operator.

The pre-flight matters only in apply mode without `--dry-run` (check and dry-run never write). It is guarded by an internal env var (`AGENT0_SYNC_REBOOTSTRAPPED`) so the re-exec'd process does not loop. Detection reuses the existing `sha_of` + `load_baseline` 3-way logic for the single path `.claude/tools/sync-harness.sh`: rebootstrap iff the verdict is a *write* verdict — `copy` (fork copy missing), `stale` (auto-update), or `customized`-under-`--force` not matched by `--force-except`. A customized-and-refused self is not a write → no rebootstrap; the fork's own copy runs the (refusing) sync and never overwrites itself, so there is no crash. Build order: (1) capture `ORIGINAL_ARGS` at the very top before the parse loop consumes `$@`; (2) add the `_self_rebootstrap` function and call it in the orchestration tail immediately after `load_baseline` and before `walk_copy_check` — after the baseline is loaded (stale-vs-customized needs it) but before the first write; (3) add the regression test; (4) document in `harness-sync.md`.

## Files to touch

**Create:**
- `.claude/tests/harness-sync/33-self-overwrite-single-run.sh` — stages a fixture fork whose `.claude/tools/sync-harness.sh` is a *length-altered* stale variant (clearly different byte length, with a `harness-sync-baseline.json` entry matching the fork copy so it classifies `stale`), runs `--apply` once, and asserts: exit 0, stderr carries no `unbound variable` / syntax error, the fork's `sync-harness.sh` ends byte-identical to Agent0's.

**Modify:**
- `.claude/tools/sync-harness.sh` —
  - capture `ORIGINAL_ARGS=("$@")` as the first executable line, before the `while [ $# -gt 0 ]` parse loop consumes the positionals;
  - early (after the sanity block), if `AGENT0_SYNC_REBOOTSTRAP_TMP` is set — i.e. this process *is* the re-exec'd one — register `trap 'rm -f "$AGENT0_SYNC_REBOOTSTRAP_TMP"' EXIT` so the temp copy is removed after execution finishes;
  - add a `_self_rebootstrap()` function: compute the write-verdict for the single relpath `.claude/tools/sync-harness.sh` (reusing `sha_of` + `load_baseline`); on a write-verdict and `AGENT0_SYNC_REBOOTSTRAPPED` unset and apply-non-dry-run mode, `mktemp` a temp file, `cp` Agent0's `sync-harness.sh` into it, `export AGENT0_SYNC_REBOOTSTRAPPED=1 AGENT0_SYNC_REBOOTSTRAP_TMP=<tmp>`, then `exec bash "$tmp" "${ORIGINAL_ARGS[@]}"`;
  - call `_self_rebootstrap` in the orchestration tail immediately after `load_baseline` and before `walk_copy_check` — the baseline must be loaded for the stale-vs-customized verdict, and `walk_copy_check` is the first writer.
- `.claude/tests/harness-sync/run-all.sh` — add `33` to the explicit `for n in 01 02 … 32` scenario-number list.
- `.claude/rules/harness-sync.md` — new `## Self-rebootstrap` subsection describing the pre-flight; a gotcha entry for the one-time transitional crash a pre-072 fork still hits on the upgrade that installs the fix, with the "re-run `--apply`, it is clean" remedy.

**Delete:** none.

## Alternatives considered

### Approach B — process `sync-harness.sh` last, then exit with a "re-run to complete" message

Order the manifest so the self-file is the final write; on a stale self, write the new version and exit non-zero with `sync-harness.sh updated — re-run --apply`. Rejected: it imposes a **permanent two-run operator cost** on every sync that changes the tool, forever, to dodge a one-time bit of re-exec plumbing. The "write last, nothing executes after" variant is worse — fragile: any future line added after the self-write (a new pass, a summary printf) silently reintroduces the corruption. Approach A pays the complexity once and stays correct as the script grows.

### Approach B2 — write the self-file in place, then `exec` the fork's now-updated copy

`exec` of a freshly-written file is itself safe (fresh process, reads from offset 0). Rejected: the re-exec'd process would redo the entire sync unless gated by a "skip, already applied" flag — which is Approach A with worse ergonomics (exec at the end against the fork file, instead of at the start against a stable temp). A is the clean form of the same idea.

### Exclude `sync-harness.sh` from the propagation manifest

Stop self-syncing; the operator updates the tool by hand. Rejected: the entire value of the tool is *one-command* harness updates. Making the updater the one file that must be manually maintained means forks silently drift on the very tool whose job is to kill drift.

## Risks and unknowns

- **Transitional pre-072 → 072 crash (declared non-goal).** A fork already deployed runs its *old* (pre-fix) `sync-harness.sh` on the upgrade that installs 072 — no rebootstrap guard yet → it self-overwrites once. Unavoidable; mitigated by the `harness-sync.md` gotcha ("re-run, it is clean"). Same shape as 071's one-time `--force`.
- **`exec` argument forwarding.** The two-token flag forms (`--agent0-path PATH`, `--force-except GLOB`) must survive the re-exec. Capturing `ORIGINAL_ARGS=("$@")` *before* the parse loop preserves them verbatim; the only risk is capturing at the wrong point — mitigated by making it the first executable line.
- **Unlinking the temp file bash executes from.** The `trap … EXIT` fires *after* the script finishes executing, so bash has already read the whole file; `rm` is safe then on Linux/macOS (unlink-after-open inode semantics make it safe even mid-run). If it proves fragile, the fallback is to leave the temp for the OS `/tmp` reaper — noted, not expected.
- **`AGENT0_SYNC_REBOOTSTRAPPED` pre-set in the operator's environment** would suppress the rebootstrap and reintroduce the crash. It is an internal variable, unlikely to be pre-set, but is documented as reserved.
- **Reliable crash reproduction in the regression test.** The fixture's stale `sync-harness.sh` must differ enough in length that a self-overwrite *would* corrupt without the fix — otherwise the test passes whether or not the fix is present. Resolved by making the fixture variant a clearly length-altered copy; exact mechanics land in `tasks.md` / `notes.md`.
- **Bash 3.2 / macOS portability** (repo-wide constraint, per `harness-sync.md` § Gotchas). `exec`, arrays, `trap`, and `mktemp` (invoked with an explicit `XXXXXX` template, no `-t`) are all 3.2-safe. No `declare -A`, no `mapfile`.

## Research / citations

- Codebase exploration — `sync-harness.sh` is procedural (no `main()`): arg parse L50-83, source/fork resolution + sanity L84-112, function defs, then the orchestration tail `load_baseline → walk_copy_check → … → write_baseline`. Helpers `sha_of` and `load_baseline` already exist. `run-all.sh` uses an explicit scenario-number list, not glob auto-discovery. Empirical crash: 2026-05-21 mei-saas validation, `line 1234: src: unbound variable` after `walk_copy_check` overwrote the running script.
- Bash reads scripts incrementally and tracks a byte offset; overwriting the file *entirely* mid-run misaligns the instruction pointer → command-not-found / syntax errors, and rarely a valid-but-destructive command — [Baeldung: What's the Effect of Editing a Shell Script While It's Running?](https://www.baeldung.com/linux/modify-running-script), [textplain.org: don't edit running bash scripts](https://textplain.org/shellsplosion), [Hacker News discussion](https://news.ycombinator.com/item?id=23087308).
- `mktemp` + `trap 'rm -f …' EXIT` is the canonical safe temp-file lifecycle in shell — [Putorius: Working with Temporary Files in Shell Scripts](https://www.putorius.net/mktemp-working-with-temporary-files.html).
