# Session handoff

Read at the start of every Claude Code session and updated at the end. Captures work-in-progress context that wouldn't otherwise survive between sessions.

See `.claude/rules/session-handoff.md` for the protocol.

---

## Current state

Nine capacities on `main`, all green from spec 007 close-out. This session was a **dogfood pass**: bifurcated the full harness into `/home/goat/shrnk` (a TS+Bun URL-shortener MVP, sibling directory — NOT inside this repo), exercised the per-fork checklist end-to-end, and measured harness weight against real product code. Working tree on Agent0 is dirty in exactly one path: `.claude/REMINDERS.md` (new bullet from the dogfood, see WIP).

## WIP

- `.claude/REMINDERS.md` carries one uncommitted bullet: **the validator (`run.sh`) only detects `bun.lockb` (binary lockfile), but Bun 1.3+ emits text-based `bun.lock` by default** — forks have to ship a `bunfig.toml` purely as a detection marker, which is friction. One-line fix: add `bun.lock` to the bun-stack guard alongside `bun.lockb`. Not urgent but worth landing before another fork hits the same gotcha.

## Next steps

Two reasonable continuations:

1. **Land the validator `bun.lock` fix.** Trivial one-line change in `.claude/validators/run.sh`, plus a sentence in `README.md` § *Per-fork checklist* step 2 noting both lockfile shapes are detected. Either a tiny commit on its own or bundled with the reminder dismissal in the same diff.
2. **Walk through `/home/goat/shrnk` and harvest harness-improvement signals.** The session exposed three concrete frictions (cwd-reset forces `git -C` over `cd && git`, validator drift above, `tests/secrets-scan/` 780 LOC noise in a non-spec-007 fork). Each could become its own spec; none are urgent.

No spec in flight on Agent0 itself.

## Decisions & gotchas

Newly observed this session — load-bearing for understanding the dogfood result:

- **The harness is heavy on commit zero and light forever after.** Initial commit on shrnk (`dee9e68`): 4,215 LOC across 57 files. Of that, 78% is harness mechanism + smoke tests + state; 22% is project code, tests, specs, config, meta. The ratio inverts fast — harness LOC is constant, product LOC grows linearly. By ~3–5k LOC of product code, harness fraction drops below 30%. Don't be alarmed by the initial dominance.

- **Where the harness fired in real work** (from the shrnk session): governance gate caught `rm -rf` during prune and `git add -A` for initial commit (both overridden with audit reasons); preflight identified `git -C <path> commit` as a clean real-commit and passed through; native `gitleaks pre-commit` ran clean over the full 4.2k-LOC initial diff; TDD red→green was visible in each module (test failed with `Cannot find module`, then green after implementation); BDD scenarios in `spec.md` mapped 1:1 to `test('...')` names in `src/*.test.ts`. Six concrete moments in one session — the harness is hot, not theoretical.

- **The `cd ... && git commit` reflex is naturally suppressed by Claude Code's per-Bash-call cwd reset.** Each `Bash` tool invocation starts in `$CLAUDE_PROJECT_DIR`, so to commit in a sibling repo you reach for `git -C /path commit` instead of `cd /path && git commit`. That happens to dodge the preflight's `compound-and` reject — which would otherwise have been the canonical friction case. Worth knowing: the harness and the harness-host conspire to make the right shape the easy shape, not the override-eligible one.

- **Validator drift on Bun 1.3+ (`bun.lockb` → `bun.lock`).** Already captured in the active reminder. Workaround in shrnk was to commit a `bunfig.toml`, which the validator also accepts as a stack marker. Fix is one-line in `.claude/validators/run.sh`.

- **TypeScript `Server` type in `@types/bun` is now generic (`Server<WebSocketData>`).** Hit while typechecking shrnk; the clean fix is `ReturnType<typeof createServer>` instead of importing `Server` directly. Worth noting if a future template adds a Bun reference example or any Bun-stack project hits it again.

- **`tests/secrets-scan/` arguably shouldn't ship to every fork.** Those are V1-V7 scenario tests for the harness's own spec 007 — they verify *the harness* works, not the fork's project. 8 files, 780 LOC. A fork that never touches secrets-scan internals inherits them as noise. Options: (a) move them under `docs/specs/007-secrets-scan-timing/tests/` so they live with the spec that defines them, or (b) add a delete-this-if-you-don't-need-it line to the per-fork checklist. Not a spec — a refactor judgment call for the next session.

Carried forward from prior sessions (still load-bearing — full list in `.claude/rules/*` and `docs/specs/*/`):

- `gitleaks protect --staged` was deprecated in 2025 in favor of `gitleaks git --pre-commit --staged`. Both layers use the current shape; minimum gitleaks version 8.20.
- AKIA test-vector reminder: spec 006 § *Notes* documents the canonical non-stopworded shape; the AWS-published `EXAMPLE`-suffix vector is stopworded by gitleaks 8.21.2 and silently does not trip.
- The user's global Claude Code hook at `$HOME/.claude/hooks/pre-commit-secrets-scan.sh` scans staged content via plain regex without honoring `gitleaks:allow`; bypass var is `DOTCLAUDE_HOOK_SECRETS_SCAN=0` (process env, not bash prefix).
- `core.hooksPath` is active on Agent0 (`.githooks`); the native hook fires on every commit. Per-fork install is manual by design (Lazarus 2025 vector).
- Path discipline: `.claude/` is harness, `docs/specs/` is project artifacts, `.githooks/` is versioned native git hooks.
- `agent_id` IS in the PostToolUse payload (undocumented but reliable); native git hooks do NOT have access.
- Two bash traps: (1) `jq '.field // empty'` collapses `false` and missing — use `has` shape when distinguishing matters; (2) `exec N>file 2>/dev/null` is sticky — probe writability in a subshell first.
- Validator is inert in this base repo (no stack lockfile present); activates per-fork.
