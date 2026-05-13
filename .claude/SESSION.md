# Session handoff

Read at the start of every Claude Code session and updated at the end. Captures work-in-progress context that wouldn't otherwise survive between sessions.

See `.claude/rules/session-handoff.md` for the protocol.

---

## Current state

Rule-infra modernization committed across 3 commits (prior session, 2026-05-13). Validation pending — this session's job.

- **`docs(memory)`** — skill-eval-pattern observation memo + index.
- **`feat(rules)`** — `paths:` frontmatter on 8 capacity-operational rules (`mcp-recipes`, `supply-chain`, `runtime-introspect`, `secrets-scan`, `lint-validator`, `harness-sync`, `typecheck-advisory`, `session-handoff`).
- **`feat(observability)`** — `rule-load-debug` capacity: hook on native `InstructionsLoaded` event, JSONL audit log gated by `CLAUDE_RULE_LOAD_DEBUG=1`, probe subcommand `rule-loads` with `--json` / `--session` / `--reason` flags.

Smoke-tested in-session at the unit level (synthetic payloads through hook+probe, all 5 `load_reason` types, all filter combinations). Real harness→hook plumbing NOT yet validated — requires session restart with env var pre-set in shell.

Parallel-session WIP (NOT this work's): `packages/mcp-product-pipeline/src/state.ts` modified, untracked template dirs under `packages/mcp-product-pipeline/src/templates/02-prototype/`, `03-spec/`, `04-ux-testing/`, `05-brand/`. Spec 025 lane.

## WIP — validation playbook

**Step 0: launch with env var in shell (NOT mid-session — hooks are harness siblings, not Bash children; see `.claude/rules/runtime-introspect.md` § Gotchas for the canonical statement):**

```bash
CLAUDE_RULE_LOAD_DEBUG=1 claude
```

**Step 1 — startup load shape (level 2):** within first minute,

```bash
bash .claude/tools/probe.sh rule-loads --reason session_start
```

Expected ~9 rows (CLAUDE.md + 8 unconditionals): `delegation.md`, `tdd.md`, `spec-driven.md`, `memory-placement.md`, `language.md`, `research-before-proposing.md`, `reminders.md`, `compaction-continuity.md`.

Should NOT appear in `session_start`: any of `mcp-recipes`, `supply-chain`, `runtime-introspect`, `secrets-scan`, `lint-validator`, `harness-sync`, `typecheck-advisory`, `session-handoff`, `rule-load-debug` (all 9 are path-scoped). If any DO appear → frontmatter is being parsed incorrectly or ignored entirely. **This is the primary regression signal.**

**Step 2 — path_glob_match triggers (level 2):** read files that match each rule's globs, then query `--reason path_glob_match`. Suggested triggers:

| Read | Should load |
| --- | --- |
| `.claude/hooks/secrets-scan.sh` | `secrets-scan` |
| `.claude/hooks/supply-chain-scan.sh` | `supply-chain` |
| `.claude/hooks/runtime-pre-mark.sh` | `runtime-introspect` |
| `.claude/validators/run.sh` | `lint-validator` AND `typecheck-advisory` (both globs match) |
| `.claude/hooks/session-stop.sh` | `session-handoff` |
| `.claude/tools/sync-harness.sh` | `harness-sync` |
| `.mcp.json.example` | `mcp-recipes` |
| `.claude/tools/probe.sh` | `rule-load-debug` AND `runtime-introspect` (probe.sh is in both globs) |

For each: confirm `file_path` matches, `globs` array matches frontmatter, `trigger_file` is what you just read.

If a rule does NOT load despite path match → glob is wrong, frontmatter parser issue, or CC version pre-dates `InstructionsLoaded` event (hook silently inert). Cross-check: `bash .claude/tools/probe.sh rule-loads --json` shows the raw stream — if NO rows have `load_reason: "path_glob_match"` for any trigger, the path-scoping mechanism is broken; if SOME do and SOME don't, individual globs need review.

**Step 3 — sanity check via system-reminder:** even with `CLAUDE_RULE_LOAD_DEBUG=0` unset, reading a path-scoped trigger file should produce a `<system-reminder>` block in the agent's context containing the rule body. The user observed this 2026-05-13 for `secrets-scan` (prior session). This is independent of the hook firing — it's the LOAD mechanism itself. If the system-reminder doesn't appear, the path-scoping ISN'T working regardless of what the hook says.

**Step 4 — fork dogfood (level 3):** after level 2 passes, sync into shrnk-mono:

```bash
bash .claude/tools/sync-harness.sh --check ~/shrnk-mono       # see drift
bash .claude/tools/sync-harness.sh --apply ~/shrnk-mono       # apply
cd ~/shrnk-mono && CLAUDE_RULE_LOAD_DEBUG=1 claude            # validate
```

Real-work probes to exercise capacity recovery:
- **Supply-chain:** attempt `bun add some-pkg` → expect block-by-default + corrective stderr template. Override with `# OVERRIDE: <reason>` two-line form → expect pass. Check whether agent recovers without the deep `supply-chain.md` rule loaded (it should NOT load because the trigger is a Bash invocation, not a file edit; CLAUDE.md `## Supply chain` summary must be sufficient).
- **Secrets-scan:** stage a fake test-fixture credential, attempt `git commit` → expect native pre-commit block. Check agent's recovery (uses correct override marker shape from CLAUDE.md summary alone? or fumbles?).
- **Runtime-introspect:** `bun test` (or stack-equivalent) → `bash .claude/tools/probe.sh last-run` → expect snapshot. Confirms spec 011 still works.
- **Path-scoped rule:** edit `package.json` → `supply-chain.md` should now load (Edit on a manifest IS a path-glob trigger, distinct from the Bash gate above). Confirm via `probe.sh rule-loads --reason path_glob_match`.

The level 3 question is **NOT** "does the hook fire" — that's level 2. Level 3 is "does agent BEHAVIOR degrade because deep rules aren't loaded by default". If CLAUDE.md `## Section` summaries are insufficient, the agent will recover slower/wrongly. Document any case where the agent had to read the deep rule to do something it used to do from default context.

## Next steps

1. **Run validation playbook above.** Report findings in updated SESSION.md and/or new memo under `.claude/memory/`.
2. If level 2 fails: revert `feat(rules)` commit and re-investigate; the `feat(observability)` commit can stay (still useful even if path-scoping itself is wrong).
3. If level 3 surfaces real behavioral degradation: identify which CLAUDE.md `## Section` summaries need beefing up; the rules themselves stay path-scoped, the orientation gets denser.
4. **Spec 025 continuation** — separate lane; `packages/mcp-product-pipeline/src/state.ts` modification + untracked template dirs need provenance check before any commit there.
5. **CC hooks underused reminder** (due 2026-05-13, already past-due) — partial progress: `InstructionsLoaded` adopted = 10 of 29 events now used (was 9). Original target (`UserPromptSubmit` for ambiguous-prompt detection) untouched. Consider dismissing/rewriting the reminder.
6. **Pyshrnk CLAUDE.md reconciliation** — long carryover.

## Decisions & gotchas

- **Smoke test in-session has a ceiling.** `settings.json` registration changes do NOT hot-reload mid-session (empirical: bypass-marker hook didn't fire when reading a path-scoped trigger file mid-session). The unit-level smoke test passed (synthetic payloads through hook+probe), but the integration is "trust the docs" until next session restart confirms. Same constraint applied to `runtime-introspect` adoption originally; standard CC behavior.
- **Hooks are harness siblings, not Bash children.** `CLAUDE_RULE_LOAD_DEBUG=1` MUST be exported in the shell before `claude` launches. Setting it via a Bash tool call mid-session is invisible to the hook. Documented identically in `.claude/rules/runtime-introspect.md` § Gotchas (`CLAUDE_RUNTIME_INTROSPECT_EXTRA_DETECT` case).
- **System-reminder injection ≠ hook firing.** The user observed `secrets-scan.md` re-injected as `<system-reminder>` after reading the matching hook file. That's the LOAD mechanism, not the InstructionsLoaded hook. Both should work; they're separate channels with the same trigger. If level 2 shows hook silence but system-reminder injection works, path-scoping is fine and the hook integration is the issue.
- **Probe text view drops `parent_file` on `include` loads.** Visible via `--json` only. Small gap; can extend probe if it becomes pain.
- **CLAUDE.md `## Section` summaries are LOAD-BEARING.** Each path-scoped rule's operational essentials (override marker, env vars, command templates) MUST remain in CLAUDE.md because the deep rule won't load when the capacity gate fires on a Bash invocation (not file edit). Audit done; flag any future migration of essentials OUT of CLAUDE.md.
- **`InstructionsLoaded` is non-blocking, no decision control.** Per CC docs: stdout/stderr ignored by harness, runs async. The audit log + probe is the ONLY signal path from this hook. Any future attempt to "talk back" via this hook will silently fail.
- **Docs migration:** `docs.claude.com/en/docs/claude-code/*` → 301 → `code.claude.com/docs/en/*`. Old URLs in older memos redirect but should be updated when touched.
- **Skill-eval framework NOT adopted (2026-05-13).** Industry pattern observed across 5 posts; deferred per `feedback_speculative_observability`. Reference: `.claude/memory/skill-eval-pattern.md`. Trigger to revisit: third silent regression in a skill dogfood missed.
