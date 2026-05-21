# 068 — harness-sync-baseline-reconciliation — notes

_Created 2026-05-20._

_In-flight design memory for this spec — decisions, deviations, tradeoffs, and open questions surfaced **while building** that weren't pre-empted by `spec.md` or `plan.md`. Append-only by convention. See `.claude/rules/spec-driven.md` § The four artifacts for purpose, and `.claude/rules/delegation.md` § The 5-field handoff for how sub-agents integrate._

**Entry shape:** `### YYYY-MM-DD — <author> — <one-line title>` followed by free-prose body. `<author>` is `parent` for the orchestrating agent, or the `subagent_type` (e.g. `general-purpose`, `Explore`) for delegated work.

**Routing rubric:** decision made under ambiguity → §1 Design decisions. Intentional departure from `plan.md` → §2 Deviations. Alternative weighed and chosen mid-flight → §3 Tradeoffs. Question surfaced during build, no answer yet → §4 Open questions. Sections may stay empty; the rubric is a guide, not a quota.

## Design decisions

_Choices made where the spec/plan was ambiguous. The decision itself + why this option over others considered in the moment._

### 2026-05-20 — parent — baseline lookup is awk exact-match, not grep/look

`plan.md` § Risks named `grep`/`look` as the candidate Bash-3.2-safe lookup against the sorted `relpath<TAB>sha` temp file, but explicitly deferred the exact choice to implementation. Chose `awk -F'\t' -v k="$rel" '$1 == k {print $2; exit}'`. Rejected `look`: it does a *prefix* match on sorted input, so `.claude/rules/foo.md` would also match a hypothetical `.claude/rules/foo.md.bak`. Rejected `grep -F`: a fixed-string scan can match the path as a substring of a longer line. `awk` comparing `$1` (the first tab-delimited field) for exact string equality is the only option with no false-match footgun, and one `awk` process per file is cheap (~1 ms startup) — no per-file `jq` fork.

### 2026-05-20 — parent — baseline files-map scope is the plain-file manifest only

The baseline's `files` map records exactly the `COPY_CHECK_*` manifest (what `walk_copy_check` iterates) — NOT the structured-merge files (`settings.json`, `CLAUDE.md`, `.gitignore`). Those three already have their own divergence-aware merge logic (jq structured merge, managed-block marker merge, additive entry merge) and are never deleted, so they need no baseline reference point. This keeps the spec's promise that "the structured-merge paths are unchanged" literally true — `merge_settings_json` / `merge_claude_md` / `merge_gitignore` were not touched, and the baseline is invisible to them.

## Deviations

_Places where implementation intentionally departed from `plan.md`. The departure + the reason it was necessary or better._

### 2026-05-21 — parent — Task 8 missed the .gitleaks.toml interaction (post-ship fix)

Task 8 ("`.gitignore` guard") verified that no `.gitignore` pattern catches `.claude/harness-sync-baseline.json` — but scoped the check too narrowly. The baseline file is git-tracked *and committed*, so the native `.githooks/pre-commit` gitleaks hook scans it on every commit; its `.files` map is hundreds of 64-hex sha256 strings, which gitleaks' generic-API-key rule flags as secrets. Surfaced immediately on the first real fork commit (mei-saas catch-up, 2026-05-21): the checkpoint commit blocked on 9 false-positive findings in `harness-sync-baseline.json`. Fix: added `'''harness-sync-baseline\.json'''` to `.gitleaks.toml` `[allowlist].paths` — `.gitleaks.toml` ships to forks via the sync manifest, so the exemption propagates. The lesson generalizes: "is this new git-tracked file safe to commit" must check BOTH `.gitignore` (should it be tracked) AND `.gitleaks.toml` (will the secrets gate accept it) — they are two separate gates.

### 2026-05-20 — parent — write_baseline is conditional, not "every --apply"

`plan.md` Q4/Task 6 says the baseline is "written on every `--apply`". Implemented it as a *conditional* write: `write_baseline` builds the candidate `files` map, and if it is byte-identical (key-sorted `jq -S -c` compare) to the existing baseline's `.files`, it skips the write entirely and leaves the file untouched. Reason: `spec.md`'s idempotency acceptance scenario requires that on a no-op re-apply "the baseline file is unchanged" — but the baseline carries a `synced_at` timestamp that an unconditional write would churn on every run, making the file differ byte-for-byte each time and failing that criterion. The conditional write satisfies idempotency while keeping `synced_at` meaningful (it records the last sync that actually changed the managed-file set). The plan's intent — "the baseline reflects the current sync" — is preserved; only the no-op case is short-circuited. Verified by test `30-baseline-idempotent-apply.sh` (asserts `harness-sync-baseline.json` is byte-identical across two consecutive `--apply` runs).

## Tradeoffs

_Alternatives weighed during implementation (not at plan time). The chosen path + what was given up + why the tradeoff was worth it._

### 2026-05-20 — parent — Agent0 files are sha'd twice per run

`walk_copy_check` records the manifest via `record_manifest`, which calls `sha_of` on each Agent0 source file; `process_file` then calls `sha_of` on the same source file again for its own compare. Considered threading a precomputed sha through, but `process_file` is also invoked by the structured-merge fallbacks (for missing-file copies) where no manifest entry exists, so a clean single-hash refactor would have meant a second code path. Accepted the double hash: ~500 extra `sha256sum` calls on small files is ~0.25 s on a developer-invoked, non-hot-path tool — not worth a branchier `process_file`.

## Open questions

_Questions surfaced during build that the implementer couldn't resolve alone. Owner (who decides) or path to resolution if known. Promote answered questions to `spec.md` § Open questions or as retroactive acceptance scenarios when the spec is updated._

_None — the four `spec.md` Open Questions (Q1-Q4) were all resolved in `plan.md` before implementation, and nothing new surfaced during the build that the implementer could not resolve._
