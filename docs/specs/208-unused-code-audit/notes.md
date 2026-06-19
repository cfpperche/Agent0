# {{NNN}} — {{SLUG}} — notes

_Created {{DATE}}._

_In-flight design memory for this spec — decisions, deviations, tradeoffs, and open questions surfaced **while building** that weren't pre-empted by `spec.md` or `plan.md`. Append-only by convention. See `.agent0/context/rules/spec-driven.md` § The four artifacts for purpose, and `.agent0/context/rules/delegation.md` § The 5-field handoff for how sub-agents integrate._

**Entry shape:** `### YYYY-MM-DD — <author> — <one-line title>` followed by free-prose body. `<author>` is `parent` for the orchestrating agent, or the `subagent_type` (e.g. `general-purpose`, `Explore`) for delegated work.

**Routing rubric:** decision made under ambiguity → §1 Design decisions. Intentional departure from `plan.md` → §2 Deviations. Alternative weighed and chosen mid-flight → §3 Tradeoffs. Question surfaced during build, no answer yet → §4 Open questions. Sections may stay empty; the rubric is a guide, not a quota.

## Design decisions

_Choices made where the spec/plan was ambiguous. The decision itself + why this option over others considered in the moment._

### 2026-06-18 — parent — knip 6.17.1 `--reporter json` schema contract (defensive-parse anchor)

Verified live against knip 6.17.1. Top-level: `{ "issues": [ ... ] }` (single key `issues`, an array). Each element is keyed by `file` (string) plus a fixed set of issue-type arrays: `files`, `dependencies`, `devDependencies`, `exports`, `types`, `enumMembers`, `namespaceMembers`, `duplicates`, `unlisted`, `unresolved`, `binaries`, `catalog`, `optionalPeerDependencies`. Element shapes: `files`/`dependencies`/`devDependencies` → `{name}`; `exports`/`types` → `{name,line,col,pos}`. Exit code: `0` when `issues` empty, `1` when ≥1 issue (so exit code alone is NOT the status — parse the JSON). Empty clean run prints exactly `{"issues":[]}`.

**Taxonomy mapping (engine):** `files`→*unused file*; `exports`+`types`→*unused export*; `dependencies`+`devDependencies`→*unused dependency*; `enumMembers`+`namespaceMembers`→*unreferenced member*; `unlisted`+`unresolved`+`duplicates`→*other* (distinct risk classes — surfaced, grouped, not conflated with deletable-unused). **Defensive parse:** depend only on top-level `.issues[]` + per-file array keys; missing/extra keys tolerated (`// []`); non-JSON or jq-parse failure → status `failed` with reason, never crash. **Config surfaces probed for `unconfigured`:** `knip.json|jsonc|ts|js`, `.knip.json|jsonc|ts|js`, `knip.config.ts|js`, and a `knip` key in `package.json`. Entry-file exports are treated as used by knip (public surface) — not a bug.

### 2026-06-18 — parent — `unconfigured` is a hard-stop (maintainer ruling)

When knip is resolvable but the project ships no knip config (no entry-point/boundary model), the engine stops at status `unconfigured` + a pointer to add a `knip.json`, and does **not** run knip's bare defaults. Rationale: bare defaults flag legitimate entry points as unused → false positives with the appearance of truth ("bad-deletion confidence"). Maintainer chose hard-stop over defaults-with-banner (matches the codex recommendation and the spec lean). A `package.json#knip` key counts as configured.

### 2026-06-18 — parent — sync propagation needs no baseline edit (OQ resolved at /sdd tasks time)

`.agent0/harness-sync-baseline.json` does **not** exist in the Agent0 source repo — it is a *per-consumer* artifact `sync-harness.sh` writes into `$CONSUMER_ROOT/.agent0/`, capturing Agent0's managed-file sha-set. The source-side manifest is computed dynamically from glob sets at `sync-harness.sh:185-236` (`COPY_CHECK_RECURSIVE` = `.claude/skills`, `.agent0/context`, `.agent0/skills`, `.agent0/tests`, `.claude/agents`; `COPY_CHECK_GLOBS` includes `.agent0/tools|*.sh`), filtered to git-tracked files ("managed = tracked in Agent0"). Consequence: the three shipped files (`.agent0/tools/unused-code.sh`, `.agent0/context/rules/unused-code-audit.md`, `.claude/skills/unused-code/SKILL.md`) propagate automatically once git-tracked — no baseline edit, no manifest registration. CLAUDE.md propagates via the structured managed-block merge. Plan task 15 corrected accordingly.

### 2026-06-18 — parent — codex engine review (gate task 11): BLOCK → all folded

Codex (read-only, high effort) reviewed `.agent0/tools/unused-code.sh`: verdict BLOCK, 2 BLOCKER + 4 MAJOR + 2 MINOR. Folds:
- **BLOCKER 1** — knip exit code was ignored; exit 2 with valid `{"issues":[]}` reported `clean`. Now: only exit 0/1 are normal; any other → `failed`. Regression-guarded by `failed2` fixture (exit 2 + valid empty JSON → must be `failed`).
- **BLOCKER 2** — jq flatten failure swallowed → `clean`. Now: check `jq_rc` + empty-output + non-numeric count → `failed`. `norm` helper tolerates string-or-object array elements so `.name` can't crash jq.
- **MAJOR 4/5** — `pnpm exec`/bare `bunx` probes + plain `npx knip` run could trigger a network install. Now: single `$KNIP_RUN` resolved no-fetch (local `node_modules/.bin/knip` preferred; `npx --no-install` fallback) and reused for probe AND run, so the no-fetch guarantee can't drift.
- **MAJOR 6 / MINOR 7** — predictable `/tmp/...$$` stderr file → `mktemp` + `trap` cleanup; dead bunx branch removed.
- **MAJOR 3 / MINOR 8 (kept-with-rationale, not code-changed)** — usage errors (unknown flag, bad path) stay exit 64 (EX_USAGE), now documented in the header as deliberately exempt from the advisory exit model. Matches `/vuln-audit`'s posture (it too exits 64 on bad args). Result statuses remain default-exit-0.

Transcript: `.agent0/.runtime-state/codex-exec/20260619T002145Z-you-are-a-read-only-adversarial-code-reviewer-fo/last-message.md`. Post-fold: verify.sh 9/9.

## Deviations

_Places where implementation intentionally departed from `plan.md`. The departure + the reason it was necessary or better._

## Tradeoffs

_Alternatives weighed during implementation (not at plan time). The chosen path + what was given up + why the tradeoff was worth it._

## Open questions

_Questions surfaced during build that the implementer couldn't resolve alone. Owner (who decides) or path to resolution if known. Promote answered questions to `spec.md` § Open questions or as retroactive acceptance scenarios when the spec is updated._

## Verification log

### 2026-06-19T00:51:13Z — pass (1/1) — source: tasks.md
- `bash docs/specs/208-unused-code-audit/verify.sh` — pass
