# 118 — move-validators-tests-to-agent0 — notes

_Created 2026-05-29._

_In-flight design memory for this spec — decisions, deviations, tradeoffs, and open questions surfaced **while building** that weren't pre-empted by `spec.md` or `plan.md`. Append-only by convention._

## Design decisions

### 2026-05-29 — parent — Scoped global sed over per-file edits

213 test files carry header self-refs + validator invocations. A single scoped sed of the two unambiguous, prefix-isolated strings (`.claude/tests`, `.claude/validators`) is uniform and complete where hand-editing would be slow and miss files. The sibling `.claude/rules`/`hooks`/`skills`/`agents`/`worktrees` paths don't share the prefix, so they're untouchable by the substitution. The 4 correctness-bearing spots were hand-verified after the sed.

## Deviations

_None from the planned approach; the plan itself was amended mid-flight to harden the sed filter (see Open questions → the incident)._

## Tradeoffs

_None beyond the design decision above._

## Open questions

### 2026-05-29 — parent — The sed-filter mis-anchor incident (resolved)

The first sed pass built its file-list with `grep -rlE '...' . | grep -vE '/\.git/|/docs/specs/'`. `grep -r .` emits paths **without** a leading `./`, so a spec path is `docs/specs/117-.../spec.md` — and the exclusion pattern `/docs/specs/` (leading slash) never matched it. Result: the sed rewrote `.claude/tests`→`.agent0/tests` inside **158 frozen committed-spec files** (and collapsed spec 118's own source-path descriptions).

Recovery was clean and total: every corrupted file was committed at HEAD, so `git checkout HEAD -- docs/specs/` restored all 158; spec 118's three files were re-authored from the in-context originals; the untracked 091 dir was verified unaffected (it carries no such refs). No data lost.

Hardening applied: `plan.md` § Approach now mandates anchoring the exclusion as `(^|/)docs/specs/` (or pruning the find), and § Risks records this as the realized risk. **Lesson for future relocations:** when filtering `grep -r` output, never assume a leading `./` — anchor with `(^|/)` or pass an explicit file list from `git ls-files`. This is the single most reusable takeaway from the spec.
