# Session handoff

Read at the start of every Claude Code session and updated at the end. Captures work-in-progress context that wouldn't otherwise survive between sessions.

See `.claude/rules/session-handoff.md` for the protocol.

---

## Current state

**Eleven capacities on `main`, all green — spec 009 (`supply-chain-block`) delivered.** This session split into three phases:

1. **Live-dogfood of spec 008 against `/home/goat/pyshrnk` (uv branch)** surfaced two findings, both landed:
   - `b730b63` fix(008): tokenizer stops at shell separators + skips value-taking flag args
   - `6b0ea3e` docs(008): tokenizer + stderr-observability gotchas

2. **Live-dogfood of spec 008 against `/home/goat/shrnk` (bun branch)** yielded 0 new findings — tokenizer fix generalized across managers (scoped packages, multi-package, value-taking flags). Yield-decay signal that prompted the pivot to spec 009.

3. **Spec 009 (`supply-chain-block`) delivered in 4 commits:**
   - `2e52a8b` docs: spec 009 scaffold (intent + plan + tasks)
   - `4b42d8e` tests(009): RED phase — block-mode scenarios + advisory-mode regression guards (T1-T7)
   - `d9fac8e` feat(009): block mode in supply-chain Bash preflight (T8-T9)
   - `5f4942e` docs(009): rule doc + CLAUDE.md + README updates (T10-T13)

Suite: 11/11 PASS via `bash .claude/tests/supply-chain/run-all.sh`. Spec acceptance criteria all ticked. Three design questions resolved via AskUserQuestion: scope = Bash only, default = block-on, trigger = any dep-mutation.

The Bash preflight now blocks dep-mutating commands by default with an exit-2 corrective stderr template. `CLAUDE_SUPPLY_CHAIN_BLOCK=0` falls back to spec-008 advisory mode; `CLAUDE_SKIP_SUPPLY_CHAIN_SCAN=1` still disables both layers. Edit/Write side unchanged (always advisory — basename match FP rate too high to block on).

---

**Prior session state (still `main`):** Ten capacities on `main`, all green — spec 008 (`supply-chain-scan`) landed in the previous session. The earlier two-thirds of that session ran three dogfood-and-tune passes against sibling projects (NOT inside this repo): `/home/goat/shrnk` (TS+Bun), `/home/goat/pyshrnk` (Python 3.14 + WSGI stdlib + uv), and `/home/goat/rshrnk` (Rust 1.94 + edition 2024, library-only scope). The dogfood arc surfaced 8 harness improvements; supply-chain-scan was then chosen over a 4th dogfood pass when yield-per-pass appeared to be decaying. All prior work landed upstream:

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

- **Live-dogfood pass of spec 009 against a fresh fork** — first-fork friction is the load-bearing risk per `docs/specs/009-supply-chain-block/plan.md` § *Risks*. The block-template is well-documented (CLAUDE.md + README + stderr template all name the env-var opt-out), but real-session signal would confirm whether documentation density is sufficient or whether a more accommodating default is warranted. Best target: an existing dogfood sibling that wasn't already used in this session (e.g. `/home/goat/rshrnk` cargo branch).
- **Go dogfood pass** — last unverified validator branch. Expected friction yield: low (1 or fewer findings). Defer until something specifically Go-shaped becomes interesting.
- **Extend tokenizer allowlist if noise surfaces** — known unhandled cases: `--registry-mirror` and other manager-specific value-taking flags. Current allowlist is the small intersection of "common across managers AND value is not the supply-chain signal". Add narrowly if a fork's real session produces noisy `packages` arrays.
- **Audit-log forensics tooling** — `jq` one-liners for common queries (block rate per session, top blocked packages, override-reason patterns) might be worth packaging as a small script under `.claude/tools/` if forensic analysis becomes a recurring task. Premature now; revisit if a session demands it.

## Decisions & gotchas

Newly observed this session (spec 009 + two live-dogfood passes 2026-05-11):

- **Yield-decay confirmed as the right pivot signal.** pyshrnk live-dogfood surfaced 2 findings; shrnk live-dogfood surfaced 0. After two passes in different ecosystems (uv and bun), the tokenizer fix generalized and further passes weren't producing new bugs. That's the moment to switch from "find more bugs" mode to "promote the capacity" mode — spec 009 was the natural successor. **Rule of thumb**: dogfood until two consecutive passes yield 0 findings, then graduate.

- **Decision-value-as-mode-encoding worked better than a separate `mode` field.** Spec 009 considered adding `mode: "block"` / `mode: "advisory"` to each audit row but rejected it — the decision values (`block` / `block-override` ⇒ block mode, `advisory` / `advisory-override` ⇒ advisory mode) already encode the mode without redundancy. Avoided the trap of letting two fields disagree. `jq` discriminators stay clean: `select(.decision | startswith("block"))` filters all block-mode rows.

- **`override_reason` is multi-modal under spec 009 — null vs populated discriminates "no marker" vs "rejected too-short".** A `block` row with `override_reason: null` means no marker at all; `override_reason: "skip"` means a marker was present but rejected by the ≥10-char floor. Forensic queries must use `(.override_reason | length // 0)` to discriminate. Documented in the rule doc + the hook docstring. Future audit consumers should NOT collapse the two cases — they represent different agent behaviours.

- **TDD with all-RED-tests-first paid off mechanically.** Wrote 4 failing tests (08-11) before touching the hook, confirmed RED via `run-all.sh`, then patched the hook in a single edit pass. Result: 11/11 PASS on the first GREEN attempt with zero iteration. The discipline cost (~20 min to write 4 tests upfront) bought back the time it would have cost to debug a patch that broke an edge case. Generalises: for hook changes that have a clean spec, write the tests before the code.

- **`# OVERRIDE: ...` heredoc inside the hook stderr template needs careful quoting.** When emitting the corrective stderr template via `cat <<EOF`, `$first_cmd_line` and `$override_reason` interpolate normally but a literal `$` inside the template body (none present here, but watch out in future templates) would need escaping. Current templates only interpolate the captured command + reason, so safe; documented as a maintenance note. The two-line corrected-form pattern (`<cmd>\n# OVERRIDE: <placeholder>`) at the END of the template is what the agent's pattern-match latches onto — that's the issue-#24327 contract.

- **README per-fork checklist insertions need item-number bumps.** Added a new item 5 about `CLAUDE_SUPPLY_CHAIN_BLOCK=0` between the gitleaks item (4) and the native-hook activation (was 5, now 6); had to renumber items 6, 7, 8 manually. A future spec inserting checklist items will hit the same friction — there's no auto-renumbering. Acceptable cost for the simplicity of plain-markdown checklist.

Newly observed earlier this session (live-dogfood pass on pyshrnk + shrnk):

- **The dogfood pattern WORKS for supply-chain too — 2 real findings from one live pass.** The pyshrnk live-dogfood ran ~5 Bash hits + 1 sub-agent edit and surfaced (a) tokenizer leak past pipes/redirects/flag-values (`packages` field captured `/home/goat/pyshrnk`, `2>&1`, `|`, `tail` after `uv add requests --directory /home/goat/pyshrnk 2>&1 | tail -20`), (b) the stderr-observability gap (PreToolUse hook stderr surfaces to the agent's next-turn context, not as inline Bash output — confirmed by audit log showing the advisory row while no `supply-chain-advisory:` line appeared in the Bash tool's return). The smoke tests committed in the prior session would NEVER have caught either — they ran with clean fixture commands and trusted the audit log without comparing it against expected vs. inline-stderr behaviour. **Implication**: every advisory-capacity should have a live-dogfood pass before being considered "done", not just smoke tests.

- **Tokenizer fix kept allowlist deliberately small.** The value-taking flag allowlist (`--directory`, `--dir`, `--target`, `--target-dir`, `--prefix`, `--manifest-path`, `--project`, `--cwd`, `--workspace`, `--config`, `-c`, `--filter`, `--registry`, `--index`, `--index-url`) is the intersection of "common across managers" AND "value is NOT a supply-chain signal". Deliberate exclusions:
  - `-r` / `--requirements` (pip): the file path IS the signal; skipping it would silently lose the advisory for `pip install -r requirements.txt`. The existing gotcha (file captured as "package") is the lesser evil.
  - `--package` / `-p` (cargo): the value IS the package being acted on; e.g., `cargo update --package tokio` MUST keep `tokio` as the captured package.
  
  Both exclusions have regression-guard sub-cases in `07-tokenizer-shape.sh`. Future allowlist additions should follow the same rationale (signal-preserving) — adding a flag whose value carries supply-chain meaning would create a silent-skip vulnerability.

- **Shell separator coverage has a known gap: fused redirects (`2>>file`, `>file`, etc.) without whitespace.** Bash word-split on the unquoted `$COMMAND` doesn't split inside a token, so `2>>err.log` is one token starting with `2`, falls through to the `*` arm, and gets captured as a package. Acceptable noise — the advisory still fires correctly on the manager+verb match, and forensics can disambiguate. Document'd in the new "Package-collection terminators" gotcha. Not worth fixing until a real fork report makes the gap material.

- **Claude Code per-Bash `cwd` reset behaviour cooperates with `uv --directory <path>`.** `cd /home/goat/pyshrnk && uv add foo` would (a) reset CWD on the next Bash call anyway, and (b) trip the secrets-scan compound-and reject if combined with a commit. The clean shape is `uv add foo --directory /home/goat/pyshrnk` (single-command, no chain). Generalises to other managers: `cargo --manifest-path /path/Cargo.toml`, `npm --prefix /path`. The harness and the cross-manager flag idiom conspire to make path-targeting the natural shape.

Newly observed in the prior session (still load-bearing):

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
