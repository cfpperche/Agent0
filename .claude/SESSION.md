# Session handoff

Read at the start of every Claude Code session and updated at the end. Captures work-in-progress context that wouldn't otherwise survive between sessions.

See `.claude/rules/session-handoff.md` for the protocol.

---

## Current state

**Ten capacities on `main`, all green** — spec 008 (`supply-chain-scan`) landed this session. The earlier two-thirds of the session ran three dogfood-and-tune passes against sibling projects (NOT inside this repo): `/home/goat/shrnk` (TS+Bun), `/home/goat/pyshrnk` (Python 3.14 + WSGI stdlib + uv), and `/home/goat/rshrnk` (Rust 1.94 + edition 2024, library-only scope). The dogfood arc surfaced 8 harness improvements; supply-chain-scan was then chosen over a 4th dogfood pass when yield-per-pass appeared to be decaying. All work landed upstream:

**Dogfood-driven fixes (8 commits):**
- `d9929a5` chore: SESSION + reminder from shrnk dogfood
- `d7adf69` fix: validator detects `bun.lock` (text) alongside `bun.lockb`
- `eb41c5a` docs: trim `secrets-scan.md` (~1k tokens off the always-on context budget)
- `11c1e6d` docs: per-fork checklist step 7 (optional drop of self-verification suite)
- `5608580` docs: spec 001 — Gotcha for byte-level regex false-positives in commit messages
- `7ffacfe` refactor: relocate `tests/secrets-scan/` → `.claude/tests/secrets-scan/` (harness-internal; supersedes the step-7 band-aid)
- `f67b560` fix: validator python branch — pytest blocks (was being swallowed by `|| true`), mypy non-blocking, venv-aware (`uv run` / `poetry run` / `pdm run` auto-detected)
- `a4ed20d` fix: validator `now_ms()` emits milliseconds, not nanoseconds (`%3N` precision specifier silently ignored on some GNU coreutils)
- `290c957` fix: `.gitignore` stack-pattern section — descriptions on separate lines (inline trailing comments are invalid in gitignore, broke when forks uncommented)

**Spec 008 — supply-chain-scan (3 commits):**
- `1123243` docs: spec 008 scaffold — design memory (intent + plan + tasks)
- `f979283` feat(008): supply-chain-scan hooks + registration (phase 1) — Bash preflight + Edit/Write advisory + settings.json + .gitignore
- `aaa96e0` feat(008): supply-chain docs + test suite (phase 2) — rule doc + CLAUDE.md + README + 6 scenario scripts + run-all.sh, all PASS

Plus the housekeeping chore commits for SESSION refreshes.

## WIP

None.

## Next steps

No spec in flight. Candidates for a future session:

- **Live-dogfood spec 008 against `/home/goat/shrnk` or `/home/goat/pyshrnk`** — exercise the supply-chain hooks against a real `npm add foo` or `uv add foo` invocation and watch the audit log + stderr fire. Smoke tests passed in isolation; observation in a real session might surface fork-side friction.
- **`supply-chain-block` follow-up spec** (009) — once the advisory has been used in real sessions for a while, decide whether to add a blocking gate. The override marker grammar is already wired up; the new layer would just need a shape-rejection branch that exits 2 with a corrective template (same shape as the secrets-scan preflight).
- **Go dogfood pass** — last unverified validator branch. Expected friction yield: low (1 or fewer findings). Defer until something specifically Go-shaped becomes interesting.

## Decisions & gotchas

Newly observed and load-bearing:

- **The harness has two distinct "weight" dimensions, and the disk one is misleading.** Disk LOC (~3,388 of harness mechanism in a fresh fork, plus 780 in `tests/secrets-scan/`) is 78% of a commit-zero diff but constant — product LOC grows past it within ~5 specs of real work. The **context-budget** weight is the more honest measure: ~15,000 tokens always-on at session start (CLAUDE.md harness sections + 10 rules + skill triggers + SESSION.md + REMINDERS.md) = 1.5% of an Opus 1M window, 7.5% of a 200K window. Most of `.claude/` (hooks, validators, skill bodies, spec docs, smoke tests) is NEVER in context — only runs on fire or load-on-demand. Document this when explaining the harness to skeptics.

- **`secrets-scan.md` trimmed from 4,885 → 3,882 tokens (-20%) in commit `eb41c5a`.** Compression was purely narrative: per-layer paragraphs in § *What fires* no longer enumerate decision values inline (the audit-log table already does), framing sentences in § *Override grammar* / *Env-var bridge* / *Escape hatch* tightened, gotcha lead-ins compressed. **Zero contract changes**: all 10 decision values, 5 `cmd_shape` names, 3 env vars, 12 gotcha bullets, both override example blocks, the verbatim stderr templates, `4b47a42` + V4 test refs, Lazarus context, issue #24327 reference, and the `flock` / `PIPE_BUF` / sticky-exec notes are all preserved. Verified by grep before commit.

- **Validator now detects `bun.lock` alongside `bun.lockb` (commit `d7adf69`).** Bun 1.3+ emits text-based `bun.lock` by default; the old guard only checked `bun.lockb` (binary, Bun ≤1.2), forcing forks to commit a `bunfig.toml` purely as a detection marker. The fix is one-line in `.claude/validators/run.sh` (added `|| [ -f "bun.lock" ]` to the bun-stack OR-chain) plus a sentence in README step 2 listing all three accepted markers. Smoke tested in three fixture configurations (`bun.lock` alone → detect, `bun.lockb`+tsconfig → preserved with `bun tsc --noEmit`, empty dir → `no-stack-detected`). Reminder added by the dogfood and dismissed in the fix commit's diff.

- **Validator python branch was effectively inert; now corrected (commit `f67b560`).** The pyshrnk dogfood revealed two bugs at once: (1) `python -m pytest -q && python -m mypy . || true` parses as `(pytest && mypy) || true` — the `|| true` covered the whole chain so any pytest failure (test fail, `ModuleNotFoundError`, etc.) collapsed to exit 0 and the validator returned `ok=true`. (2) The command always ran bare `python -m ...`, missing deps installed inside `uv`/`poetry`/`pdm`-managed `.venv/`. Both fixed in one commit: (a) wrap only the mypy step in a brace group so `|| true` is localised — `pytest && { mypy || true; }` — pytest is now a real gate, mypy stays non-blocking as originally intended; (b) detect `uv.lock` / `poetry.lock` / `pdm.lock` (with the matching tool on PATH) or just `.venv/` (uv) and prepend `uv run` / `poetry run` / `pdm run` accordingly. Smoke tested three fixture configs + the real pyshrnk project. README step 2 documents the new behavior. `.gitignore` also gained a commented stack-patterns block as a third tweak (`node_modules` / `.venv` / `__pycache__` / `target` / etc.) so forks don't have to rediscover them.

- **The dogfood-fork pattern is firmly the harness-improvement engine.** Three passes in one session, eight concrete fixes that wouldn't have been visible from rule-reading alone. Cumulative ~3,300 LOC of throwaway dogfood code (`/home/goat/{shrnk,pyshrnk,rshrnk}`) yielded 8 real bugs/improvements — roughly one finding per ~410 LOC, with friction yield dropping later as obvious bugs got fixed (shrnk surfaced 3, pyshrnk 3, rshrnk 2). Worth normalising as a periodic cadence, with the expectation that yield per pass decays.

- **Rust pass surfaced two self-bugs from the previous fix attempts.** (1) The `.gitignore` commented stack-pattern section from `f67b560` used `# pattern    # description` inline-comment shape — invalid in gitignore, which has no inline comments. When the rshrnk fork uncommented `# target/`, the result was a literal pattern with spaces and `#` that never matched anything; cargo build artefacts leaked into the working tree. Fixed in `290c957`: descriptions moved to comment lines above each pattern. (2) The validator's `now_ms()` function used `date +%s%3N` with a regex check `[0-9]+$` — on systems where `%3N` is silently ignored, the output is full nanoseconds (19 digits) but the regex still matches. Result: `duration_ms` in audit logs was 10^6 too large. Fixed in `a4ed20d`: switched to `%s` + `%N` separately, computed `ms = nanos / 1_000_000` in shell arithmetic with `10#` base-10 forcing on the nanos value. Lesson: regex-only validation of `date` format output isn't enough — also gate on length or compute from primitives.

- **The dogfood pattern is a real signal source.** `/home/goat/shrnk` produced six observable harness fires in one session (governance gate × 2 with overrides, preflight passthrough, native gitleaks allow, TDD red→green visible, BDD-scenario → test-name mapping) and surfaced two concrete improvements (validator drift, secrets-scan weight) that wouldn't have appeared from rule-reading alone. Keep the dogfood-fork sibling pattern as a deliberate "find harness friction" tool, not just a demo.

- **Claude Code's per-Bash cwd reset cooperates with the preflight discipline.** Each `Bash` tool invocation resets to `$CLAUDE_PROJECT_DIR`, so to work in a sibling repo you reach for `git -C /path commit` instead of `cd /path && git commit`. That naturally dodges the preflight's `compound-and` reject — the harness and the harness-host conspire to make the right shape the easy shape, not the override-eligible one.

- **`@types/bun` `Server` type is now generic (`Server<WebSocketData>`).** Hit while typechecking shrnk. Clean fix: `ReturnType<typeof createServer>` instead of importing `Server` directly. Worth noting if a future Bun reference example lands in the template.

Carried forward from prior sessions (still load-bearing — full list in `.claude/rules/*` and `docs/specs/*/`):

- `gitleaks protect --staged` was deprecated in 2025 in favor of `gitleaks git --pre-commit --staged`. Both layers use the current shape; minimum gitleaks version 8.20.
- AKIA test-vector reminder: spec 006 § *Notes* documents the canonical non-stopworded shape; the AWS-published `EXAMPLE`-suffix vector is stopworded by gitleaks 8.21.2 and silently does not trip.
- The user's global Claude Code hook at `$HOME/.claude/hooks/pre-commit-secrets-scan.sh` scans staged content via plain regex without honoring `gitleaks:allow`; bypass var is `DOTCLAUDE_HOOK_SECRETS_SCAN=0` (process env, not bash prefix).
- `core.hooksPath` is active on Agent0 (`.githooks`); the native hook fires on every commit. Per-fork install is manual by design (Lazarus 2025 vector).
- Path discipline: `.claude/` is harness, `docs/specs/` is project artifacts, `.githooks/` is versioned native git hooks.
- `agent_id` IS in the PostToolUse payload (undocumented but reliable); native git hooks do NOT have access.
- Two bash traps: (1) `jq '.field // empty'` collapses `false` and missing — use `has` shape when distinguishing matters; (2) `exec N>file 2>/dev/null` is sticky — probe writability in a subshell first.
- Validator is inert in this base repo (no stack lockfile present); activates per-fork.
