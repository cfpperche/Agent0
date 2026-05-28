# 107 — governance-gate-refinement — plan

_Drafted from `spec.md` on 2026-05-28. Update this file if implementation reveals the plan is wrong; do NOT silently diverge._

## Approach

Refine `governance-gate.sh` in place first (regex families + fast-path + header), validate, THEN move it to `.agent0/` and register both runtimes. Doing the logic edits before the move keeps each step independently checkable, and the move is a pure relocation (no logic change) so it can't mask a regex regression.

The load-bearing ordering constraint: the new families (`git clean`, whole-tree `checkout/restore`) only fire if their keywords are ALSO in the pre-jq fast-path probe — a probe-miss `exit 0`s before the family regex is ever reached. So the probe extension and the family regexes must land together, and the drift-guard test encodes the invariant.

Order: (1) refine families; (2) extend probe + fix comment; (3) header doc; (4) build test suite + validate in place; (5) move to `.agent0/` + register; (6) re-run suite against moved hook + live dogfood.

## Files to touch

**Create:**
- `.claude/tests/governance-gate/` — new suite (rm shapes, git clean, checkout/restore, drift-guard, override, registration, shellcheck) + `run-all.sh`.

**Modify:**
- `.claude/hooks/governance-gate.sh` → moved to `.agent0/hooks/governance-gate.sh` — three regex changes (rm widen, git clean family, whole-tree checkout/restore family), probe extension, comment correction, header expansion.
- `.claude/settings.json` — repoint `PreToolUse(Bash)` governance entry to `.agent0/hooks/governance-gate.sh`.
- `.codex/config.toml.example` — add commented `[[hooks.PreToolUse]]` matcher `"^Bash$"` → `delegation`… no: → `governance-gate.sh`.

**Delete:**
- `.claude/hooks/governance-gate.sh` — relocated (git shows delete+add).

## Alternatives considered

### Keep the port separate (the debate's lean)

The Round-1/2 debate leaned "refine in `.claude/`, port later in a batch with secrets-scan + supply-chain-scan." User overrode (2026-05-28): bundle the port now. Rationale accepted — we touch the file anyway, it's the most mechanical port possible (Bash-surface, no asymmetry), so one spec delivers refined+multi-runtime rather than churning the file twice. The secrets-scan/supply-chain-scan ports stay a later batch.

### Chase the RESISTED shell-primitive families (dd, chmod -R, find -delete, truncate)

Rejected in debate (both agents): unbounded shapes, false-confidence, no principled family. Recorded as deliberate non-coverage in the header + § Non-goals.

### Add an override-audit jsonl

Rejected: override reasons can carry secrets → redaction/retention/sync infra unjustified for a rare escape hatch.

## Risks and unknowns

- **Probe/family drift is the live trap.** If a new family keyword is missing from the probe, the command silently skips the gate. Mitigation: the drift-guard test asserts probe ⊇ families; add it BEFORE trusting the new families.
- **`git checkout`/`restore` false-positives.** The dangerous shape is whole-tree only. Mitigation: match only `.` / `:/` / index-wide `--staged .`; the suite explicitly tests that `git checkout -- <file>` and branch switches stay allowed.
- **`git clean` short-flag combos.** `-fdx`, `-fd`, `-xf`, `-f -d` etc. Mitigation: match force (`-f`/`--force` — incl. inside a combined short cluster) AND a broad signal (`-d`/`-x`/no pathspec); explicitly allow `-n`/`--dry-run`.
- **Parent-vs-sub-agent / PROJECT_DIR.** The gate reads only `tool_input.command` — no `PROJECT_DIR`, no state — so the `.agent0/` move needs no `_memory-hook-lib` and no runtime branch. Confirmed low-risk.
- **Live hook breakage mid-edit.** `bash -n` after each edit; the gate is on `PreToolUse(Bash)` so a syntax error would block ALL bash — validate carefully before relying on it.

## References

- `docs/specs/107-governance-gate-refinement/{spec,debate}.md` — intent + the converged 2-round decision.
- `.claude/hooks/governance-gate.sh` — current implementation (3 families, fast-path, override).
- `docs/specs/106-delegation-hooks-multi-runtime/` — the port-registration pattern (settings.json + .codex example) to mirror.
- `.agent0/memory/hook-chain-latency.md` — the fast-path budget the probe extension must respect.
