# 209 — unused-code-python-go — plan

_Drafted from `spec.md` on 2026-06-18. Update this file if implementation reveals the plan is wrong; do NOT silently diverge._

## Approach

Extend the existing `.agent0/tools/unused-code.sh` in place — same status machine, same `--json` shape, same report-never-delete posture — adding a Python branch (vulture) and a Go branch (deadcode) alongside the JS/knip branch. The engine already factors cleanly: stack-detect → resolve a no-fetch engine invocation → run → map output to the shared status + `findings[]`. The new work is (1) a stack dispatch so the right branch runs, (2) two new branch implementations (resolve/run/parse), (3) three cross-cutting additions the codex review forced: a `--stack` override + polyglot "other stacks detected" note, an optional `confidence` field on findings, and generalizing `unconfigured` to "engine lacks the boundary/entry model it needs" (Go with no main/test root). Then extend `verify.sh` with Python + Go fixtures, update the rule + CLAUDE.md/AGENTS.md index, and re-verify.

Order: refactor the JS path into a dispatched branch first (no behavior change, re-run verify.sh to prove parity), then add Python, then Go, then the cross-cutting flags, proving each with a fixture before the next. knip stays the JS engine untouched.

## Files to touch

**Modify:**
- `.agent0/tools/unused-code.sh` — add `--stack <js|python|go>` arg; detect ALL supported stacks (not just first-match) to drive the polyglot note; dispatch to a per-stack branch. Python branch: resolve vulture (project venv via uv/poetry/pdm/`.venv`, else PATH; no install), run `vulture <paths>`, parse its `path:line: msg (NN% confidence)` text into findings with `confidence`. Go branch: resolve `deadcode` (PATH only; no `go install`), run `deadcode -test ./...` (or `-json`), map unreachable funcs to kind `unreachable code`; no analyzable main/test root → `unconfigured`. Add optional `confidence` to the finding object + human output. Add the "other detected stacks not audited: … (use --stack)" note.
- `.agent0/context/rules/unused-code-audit.md` — document Python/Go engines, the `unconfigured` generalization, `--stack` + polyglot note, Rust/PHP deferral (deps≠code), confidence surfacing.
- `CLAUDE.md` + `AGENTS.md` — update the index entry: "knip, JS/TS-only v1" → "knip/vulture/deadcode; JS/TS, Python, Go"; note Rust/PHP deferred.
- `docs/specs/209-unused-code-python-go/verify.sh` — Python (findings/unavailable) + Go (findings/unconfigured-no-root/unavailable) fixtures + the JS parity re-run + `--stack` override + confidence-present assertions. Reuse the v1 fixture-cache pattern; SKIP gracefully when a toolchain/engine is absent.
- `docs/specs/209-.../{notes,tasks}.md` — in-flight memory + checklist.

**Create:** none beyond the spec dir.

**Delete:** none.

**Propagation:** unchanged — `unused-code.sh` + the rule are already under existing sync globs; CLAUDE.md/AGENTS.md via managed-block merge.

## Alternatives considered

### Ship all four stacks (Python+Go+Rust+PHP) as the maintainer first asked

Rejected (codex BLOCK, maintainer-confirmed). Rust/PHP tools detect unused *dependencies*, not dead *code*; reporting `status=clean` from a deps-only scan under `/unused-code` is a contract lie no prose caveat fixes. Rust dead code is already the rustc `dead_code` lint. Deferred to a possible sibling `/unused-deps` capability.

### `{runs:[...]}` multi-stack JSON auditing every detected stack in one pass

Rejected for v1. A real rewrite of the single-engine contract; the polyglot honesty problem is solved more cheaply by `--stack` + an explicit unaudited-stacks note. Revisit behind demand.

### Impose vulture `--min-confidence` floor

Rejected. Agent0 shouldn't pick the threshold — that's taste. Report all findings with confidence surfaced; the human (or a consumer-passed engine flag) decides the floor.

## Risks and unknowns

- **vulture text-output parsing.** vulture's default output is `path:line: unused <what> 'name' (NN% confidence)`; it has no stable JSON reporter (verify the installed version's exact format at build time, like knip in v1). Parse defensively → `failed` on unparseable, never crash.
- **vulture environment resolution.** vulture must run where the project's imports resolve, or it over-reports. Mirror the validator's `py_prefix` (uv/poetry/pdm/venv) detection; document that a misconfigured env inflates findings.
- **Go `deadcode` reachability roots.** Library-only modules / build tags / generated code have no `main` root → must be `unconfigured`, not `clean`. Confirm deadcode's exact behavior + exit codes for the no-root case at build time. `-test` default reduces FPs but verify it doesn't itself error on no-test packages.
- **deadcode output format.** Has a `-json` mode — prefer it over text parsing if stable. Verify shape against the installed version.
- **Polyglot detection vs first-match.** Changing from first-match to detect-all could alter the JS-only behavior subtly; the refactor-first step + verify.sh parity re-run guards this.
- **Host lacks engines.** This host has go + python3 + cargo + composer but NOT vulture/deadcode/staticcheck installed — build will install vulture/deadcode locally into throwaway fixtures to capture real output shapes (as v1 did for knip), never into the repo.

## Research / citations

- Codex CLI adversarial review, 2026-06-18 — `.agent0/.runtime-state/codex-exec/20260619T010015Z-design-position-to-pressure-test-extend-unused-c/last-message.md`. Drove the Python+Go-only scope, confidence preservation, Go entrypoint/`unconfigured`, no-fetch-per-engine, and polyglot `--stack` decisions.
- Spec 208 engine as the structural base: `.agent0/tools/unused-code.sh`, `.agent0/context/rules/unused-code-audit.md`, `docs/specs/208-unused-code-audit/verify.sh`.
- vulture: https://github.com/jendrikseipp/vulture · Go deadcode: https://pkg.go.dev/golang.org/x/tools/cmd/deadcode
