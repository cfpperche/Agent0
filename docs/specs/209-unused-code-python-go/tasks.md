# 209 — unused-code-python-go — tasks

_Generated from `plan.md` on 2026-06-18. Work top-to-bottom. Check boxes as tasks complete. If a task reveals the plan is wrong, update `plan.md` before continuing._

**Verify:** `bash docs/specs/209-unused-code-python-go/verify.sh`

## Implementation

### Refactor base (no behavior change)

- [x] 1. Refactor `unused-code.sh` JS path into a dispatched per-stack branch (detect → dispatch → branch fn), changing NO JS behavior. Re-run spec-208 `verify.sh` to prove parity (22/22 unchanged).
- [x] 2. Add `--stack <js|python|go>` arg + detect-ALL-supported-stacks; emit the "other detected stacks not audited: … (use --stack)" note when >1 detected; first-match still picks the default audited stack.

### Python (vulture)

- [x] 3. Confirm vulture's real output format + exit codes against a locally-installed vulture (throwaway fixture, not repo); record the parse contract in `notes.md`.
- [x] 4. Implement the Python branch: resolve vulture no-fetch (project env via uv/poetry/pdm/`.venv` mirroring the validator `py_prefix`, else PATH; `unavailable` + `pip install vulture` hint otherwise); run vulture; parse `path:line: msg 'name' (NN% confidence)` → findings with `kind` + `confidence`; defensive parse → `failed`.
- [x] 5. Add optional `confidence` to the finding object (`--json`) + human output ("candidate unused, NN% — heuristic"); absent for engines without confidence.

### Go (deadcode)

- [x] 6. Confirm deadcode output (`-json` if stable) + exit codes + the no-main/no-test-root behavior against a locally-installed deadcode (throwaway fixture); record in `notes.md`.
- [x] 7. Implement the Go branch: resolve `deadcode` no-fetch (PATH only; `unavailable` + `go install …@latest` hint); run `deadcode -test ./...`; map unreachable funcs → kind `unreachable code`; **no analyzable root → `unconfigured`** (hint: needs executable/test entry), NOT `clean`.

### Cross-cutting + proof

- [x] 8. Generalize the `unconfigured` status semantics in code comments + behavior (engine lacks the boundary/entry model it needs — knip: no entry config; Go: no reachability root).
- [x] 9. Extend `verify.sh`: Python (findings-with-confidence / unavailable), Go (findings-as-unreachable / unconfigured-no-root / unavailable), JS parity re-run, `--stack` override, polyglot-note presence. Reuse v1 fixture-cache pattern; SKIP gracefully when a toolchain/engine is absent.
- [x] 10. `bash -n` + full `verify.sh` green.

### Codex review gate

- [x] 11. Send the updated `unused-code.sh` (+ diff) to codex for read-only review (high effort); fold findings; report verdict to maintainer. **(Pause before docs/index.)**

### Docs + index

- [x] 12. Update `.agent0/context/rules/unused-code-audit.md` (Python/Go engines, `unconfigured` generalization, `--stack`/polyglot note, confidence, Rust/PHP deferral).
- [x] 13. Update the `CLAUDE.md` + `AGENTS.md` index entry (engines + stacks; Rust/PHP deferred).

## Verification

_Acceptance checks tied to `spec.md` acceptance criteria._

- [x] 14. `verify.sh` green across JS parity + Python + Go scenarios incl. Go-no-root=`unconfigured` (not clean), vulture confidence present, `--stack` override, polyglot note (maps spec scenarios 1–5 + static criteria).
- [x] 15. `bash .agent0/tools/doctor.sh` clean; spec-208 `verify.sh` still 22/22 (no regression).
- [x] 16. Codex reviews the full final diff; fold; report verdict. Fill `**Closure:**`, check all spec/tasks boxes, record spec-verify pass. **(Pause for maintainer OK before commit.)**

## Notes

_Anything that came up during execution that doesn't belong in plan.md but is useful for the PR description or future readers._
