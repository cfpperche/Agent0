# 139 — status-doctor-reconciliation — plan

_Drafted from `spec.md` on 2026-06-02. Update this file if implementation reveals the plan is wrong; do NOT silently diverge._

## Approach

Two independent edits to the spec-137 tools, each test-first, no new files beyond tests. **(A) `status.sh` gains a judgment layer:** a reconciliation banner emitted near the top (right after the `AGENT0_STATUS` header, before `=== handoff ===`) that fires *only* when the working tree is dirty AND the handoff claims clean/idle, plus a "probable active work" line derived from dirty `docs/specs/NNN-<slug>/` paths. **(B) `doctor.sh`'s `wired_check` is replaced** with jq contract validation: scope to `.hooks.SessionStart[].hooks[].command`, require a command that references `startup-brief.sh` AND a resolved `.agent0/hooks/startup-brief.sh` that exists + is executable; a config file that is *present but unwired* becomes `broken` (per-runtime), while an *absent* config stays `advisory` (runtime simply not configured here).

The three open questions resolve as follows:
- **Reconciliation trigger → string-contradiction, not mtime freshness.** Fire only when `git status --porcelain` is non-empty AND the handoff's Active Work (or Current State) matches a "clean/idle" signal (`none` / `working tree clean` / `nothing in flight`, case-insensitive). The mtime approach (handoff older than newest dirty file) is rejected: editing a file doesn't make the handoff stale, so mtime is noisy and would cause the false alarms acceptance criterion 2 forbids. The string contradiction is the exact high-signal case both runtimes flagged.
- **`doctor` runtime selector → auto-detect by file presence, no `--runtime` flag in v1.** Config absent → `advisory` (as today). Config present but no valid SessionStart→startup-brief binding → `broken`. "Both unwired" falls out naturally (both broken). A `--runtime` selector is deferred (rule-of-three; no caller needs per-runtime gating yet).
- **In-flight inference location → local to `status.sh`.** Keep it a `status.sh` function; do NOT extract to a shared helper or feed the bounded SessionStart brief (the brief is deliberately small). Extract later only if the brief wants it.

Order: B (doctor) is self-contained and lower-risk → do it first. A (status) touches the resume narrative and needs the more careful false-alarm testing → second. Both land with tests in `.agent0/tests/agent0-status/test.sh` (extend the existing suite; keep all 20 current assertions green).

## Files to touch

**Modify:**
- `.agent0/tools/doctor.sh` — replace `wired_check` with a jq-based `wired_check` that (1) reads `.hooks.SessionStart[].hooks[].command` from the given config, (2) matches `startup-brief.sh`, (3) confirms `$PROJECT_DIR/.agent0/hooks/startup-brief.sh` exists + is executable; emit `broken` when the file exists but no valid binding is found, `advisory` when the config file is absent, `ok` when bound + target valid. Guard for `jq` absent (fall back to the old substring behavior as `advisory`, never crash).
- `.agent0/tools/status.sh` — add `reconcile_block()` (emitted near top) + a "probable active work" derivation (in `reconcile_block` or `next_commands_block`). Banner only on the dirty-tree ∧ handoff-claims-clean contradiction; in-flight hint from `git status --porcelain` filtered to `docs/specs/NNN-*`.
- `.agent0/tests/agent0-status/test.sh` — add: reconciliation fires on contradiction (V10), no false alarm when clean or when handoff already mentions work (V11), in-flight hint derived from a fixture dirty spec path (V12), doctor jq-wiring reports `broken` on a present-but-unwired config fixture and `ok` on the real repo (V13). Keep V1–V9 green.

**Create:** none (tests extend the existing file).

**Delete:** none.

## Alternatives considered

### mtime-freshness reconciliation (handoff older than newest dirty file)
Rejected — noisy and false-alarm-prone. Touching any file updates its mtime without making the handoff stale; this would fire the warning constantly during normal editing, violating acceptance criterion 2 ("no false alarm when handoff and tree agree"). The string-contradiction check is narrower and higher-signal.

### `--runtime claude|codex|both` flag for doctor in v1
Rejected for v1 — no caller needs per-runtime gating today. Auto-detect by config-file presence covers the real cases (consumer with only one runtime → the absent one is advisory; a present-but-broken config → broken). Add the flag later if a CI consumer needs to scope the gate.

### Extract in-flight inference to a shared lib (so the brief can use it too)
Rejected now — the SessionStart brief is intentionally bounded (6000 bytes / 80 lines); adding inference there grows the boot surface for unclear benefit. Keep it local to `status.sh`; extract on demand (rule-of-three).

## Risks and unknowns

- **Reconciliation false positives** — the "clean/idle" signal match must be tight. Risk: a handoff Active Work that legitimately says "none — see spec X" could trip it while the tree is dirty with that spec's work. Mitigation: the banner is framed as "handoff *may be* stale" (advisory tone), and acceptance criterion 2's fixtures pin the no-false-alarm cases. Accept that a stale-handoff warning on genuinely-stale handoffs is the desired behavior.
- **jq command-string resolution** — the hook command embeds `$CLAUDE_PROJECT_DIR` / `$(git rev-parse …)`, so the literal path can't be eval'd safely. Mitigation: don't eval — match `startup-brief.sh` in the command string AND independently assert the canonical `$PROJECT_DIR/.agent0/hooks/startup-brief.sh` is present+exec. This is the contract without executing untrusted strings.
- **jq absent** — `doctor` must not crash. Mitigation: if `jq` missing, the wiring check degrades to the old substring behavior tagged `advisory` (and the binaries block already reports jq missing as `broken` separately).
- **Codex config shape drift** — `.codex/hooks.json` uses `.matcher` ("startup|resume|…") on the SessionStart entry; the jq must read `.hooks.SessionStart[].hooks[].command` which holds for both runtimes today. If Codex changes its schema, the check fails closed (advisory/broken), never silently green.

## Research / citations

- `.claude/settings.json` `.hooks.SessionStart[].hooks[].command` = `bash "$CLAUDE_PROJECT_DIR"/.agent0/hooks/startup-brief.sh` (read 2026-06-02).
- `.codex/hooks.json` `.hooks.SessionStart[]` carries `.matcher` + `.hooks[].command` = `bash "$(git rev-parse --show-toplevel)/.agent0/hooks/startup-brief.sh"` (read 2026-06-02).
- Dogfood findings motivating this spec: `.agent0/.runtime-state/{claude,codex}-exec/*df-*/last-message.md` (D1 status reconciliation, D2 doctor wiring).
- `docs/specs/137-agent0-status/` spec + notes — the capability being refined and its anti-drift scope (`.agent0/context/rules/agent0-status.md`).
