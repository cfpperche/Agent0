# Session handoff

Read at the start of every Claude Code session and updated at the end. Captures work-in-progress context that wouldn't otherwise survive between sessions.

See `.claude/rules/session-handoff.md` for the protocol.

---

## Current state

**Spec 011-runtime-introspect delivered and validated.** Twelve shipped capacities on `main`, all green. 10/10 scenario suite PASS; three consecutive 0-finding live-dogfood/validation passes (passes 2 + 3 on shrnk during impl, then a post-FP-fix re-validate). Six commits: `69099de` → `b0708a4`.

Spec 010-audit-forensics still draft, untracked (carryover — `spec.md` filled prior session, `plan.md` / `tasks.md` placeholders, awaiting user review). This is the only uncommitted state on disk.

## WIP

None on 011. The capacity ships as: `runtime-pre-mark.sh` + `runtime-capture.sh` (with leading-shape FP skip for `git commit` / `grep` / `rg` / `ag` / `egrep` / `fgrep`) + `probe.sh` + `runtime-introspect.md` rule doc + 10 test scenarios + CLAUDE.md § block + `.gitignore` entry + settings.json wiring. Agent reads its own latest verifier run via `bash .claude/tools/probe.sh last-run`.

## Next steps

1. **Follow-up spec: `.mcp.json.example`** — opt-in MCP recipes for forks that want browser introspection (Playwright MCP, Chrome DevTools MCP) or DB introspection (DBHub). Spec 011 § Non-goals explicitly defers these. Single doc + commented example file, no new hooks.
2. **010-audit-forensics** — still awaits user review of `spec.md`. Plan/tasks blocked until then.

Deferred (still queued):
- Second cargo dogfood pass (graduation by yield-decay rule)
- Go dogfood pass (low expected yield)

## Decisions & gotchas

- **Claude Code's `tool_response.exit_code` does not exist for Bash.** Live-dogfood surfaced this — payload carries `{stdout, stderr, interrupted, isImage, noOutputExpected}` and a top-level `duration_ms`. Runtime-introspect handles it via per-detector stdout-pattern inference (`inferred_status` + `inference_basis` fields). The `exit` field remains in schema for forward-compat; probe falls back to inferred status when null. All detectors must have an inference branch — there's no "exit code as ground truth" path under Claude Code today.
- **Probe inside the SAME Bash tool call sees the PRIOR snapshot, not the current.** PostToolUse fires after the underlying command returns, so `bun test && bash probe.sh last-run` reads the previous run. Agent must read in the NEXT Bash invocation. Documented in rule doc; surfaced during dogfood pass 1.
- **`bun run <script>` detector emits sub-keyed suffixes** (`bun-run-test`, `bun-run-typecheck`, etc.) so inference can route to the right pattern table. Originally just `bun-run` — failed inference on `bun run typecheck`. Fixed during dogfood.
- **Documented gotchas need DEFENDED counterparts.** I wrote the "commit-message FP" gotcha in the rule doc but did NOT add a tokeniser skip for it — the gotcha admitted the FP existed instead of preventing it. Validation pass surfaced it for real (a recent `git commit -m "$(cat <<EOF ... bun tsc ... EOF)"` captured a false bun-tsc snapshot). Fix landed in `b0708a4` — leading-shape skip for `git commit` / `git -C` / `grep` / `rg` / `ag` / `egrep` / `fgrep`. **Lesson:** when writing a Gotchas entry, decide if it's "accept the limitation" or "code the defense" — defaulting to documentation alone is how known-knowns become live regressions.
- **Wedge stays generic; framework-specific introspection (laravel-boost, next-devtools-mcp, rails-mcp) lives in fork-side `.mcp.json`.** Spec 011 deliberately does not duplicate them. Playwright / Chrome DevTools / DBHub get a future `.mcp.json.example` doc, not a capacity.
- **No audit log on the runtime side.** `last-run.json` is self-sufficient as "latest evidence". Supply-chain's per-Bash audit log volume (hundreds of `skip-not-install` rows per session) was the cautionary tale; revisit if forensic queries become a real need.
- **TDD discipline held end-to-end:** 8 RED tests written before any hook code → 8/8 GREEN first attempt after impl (one impl bug: bash `$(jq -r)` strips trailing newlines; fixed via `jq -j + printf-x` sentinel). Then dogfood pass 1 surfaced 4 production-only findings → test 09 + fixes → 9/9 GREEN. Then validation surfaced the commit-message FP → test 10 + leading-shape skip → 10/10 GREEN. Confirms the pattern: spec → RED tests → impl → live-dogfood → adjustments + new RED → green. Three rounds of finding-driven tests in one spec; each round added permanent regression coverage.
- **SESSION.md auto-injection has a ~2KB preview budget.** Replace stale content rather than appending — `git log` is the audit trail.
