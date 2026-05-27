# Propagation advisory

A `PostToolUse(Edit|Write|MultiEdit)` hook (`.claude/hooks/propagation-advise.sh`) scans the edited content of shipped files for upstream-internal pointers and emits one `propagation-advisory:` line per finding to stderr. Mirrors the `tdd-advisory:` / `lint-advisory:` / `secrets-advisory:` family — always exits 0, never blocks. Fires for both parent AND sub-agent edits because the maintainer writing new rules is the most common author of fresh leaks.

The discipline this enforces is documented in `.claude/memory/propagation-hygiene.md` (maintainer-binding; doesn't ship). The advisory is the mechanical companion that surfaces drift in real time instead of waiting for a periodic audit.

## What fires, what stays silent

- **Edit / Write / MultiEdit on a shipped path** → scan the edit's new content (`new_string`, `content`, or each `edits[].new_string`) against 5 leak-pattern regexes.
- **Match on any pattern** → emit `propagation-advisory: <pattern> in <relpath>:<line> — <truncated text>` per finding (capped at 5 per pattern to limit noise).
- **No matches** → silent exit 0.
- **Path outside shipped surface** (e.g. `docs/specs/`, `.claude/memory/`) → silent exit 0 — those paths don't ship to consumer projects, so their content carries no propagation risk.

## The 5 patterns

Each maps to a leak class documented in `.claude/memory/propagation-hygiene.md`.

| Label | Regex | Catches | Example |
|---|---|---|---|
| `spec-NNN` | `\b[Ss]pec [0-9][0-9]+\b` | Concrete spec numbers | `spec 080`, `Spec 12` |
| `docs/specs/NNN` | `docs/specs/[0-9]+-` | Concrete spec dir paths | `docs/specs/070-propagation-hygiene/` |
| `anthill` | `\banthill\b` (case-insensitive) | Upstream design lineage | `anthill-fpa`, `Anthill's brand book` |
| `personal-path` | `/home/[a-z][a-z0-9_-]+/` | Personal absolute paths | `/home/goat/Agent0` |
| `memory-pointer` | `\.claude/memory/[a-z][a-z0-9_-]+\.md` | Memory file pointers | `.claude/memory/cc-platform-hooks.md` |

### Pattern exclusions (legitimate keeps that bypass the scan)

- `docs/specs/NNN-<slug>/` — the literal placeholder naming convention (no digits)
- `docs/specs/001-<slug>/`, `docs/specs/001-{{SLUG}}/`, `docs/specs/002-foundation/`, `docs/specs/003-*` — consumer-output paths the `/product` skill writes
- `.claude/memory/MEMORY.md` — the index file (carries no upstream-specific content)
- `.claude/memory/<topic>.md`, `<slug>.md`, `<file>.md`, `<name>.md` — placeholder forms a rule may legitimately reference
- `.claude/memory/.gitkeep` — empty scaffold

## Shipped surface (where the hook fires)

Mirrors `.claude/memory/propagation-hygiene.md § The shipped file class`:

- `.claude/hooks/*.sh`
- `.claude/rules/*.md`
- `.claude/tools/*.{sh,py,ts}`
- `.claude/validators/*.sh`
- `.claude/agents/*.md`
- `.claude/skills/**` (except `vendor/` and `design-systems/`)
- `.claude/tests/**`
- `.githooks/*`
- `CLAUDE.md`, `.mcp.json.example`, `.gitleaks.toml`, `.gitignore`

### Within-surface exclusions

- `.claude/skills/*/vendor/*` — vendored upstream content (open-design, etc.) has its own provenance
- `.claude/skills/*/design-systems/*` — vendor `DESIGN.md` files
- `.claude/hooks/propagation-advise.sh` — the hook itself documents patterns inline
- `.claude/rules/propagation-advisory.md` — this rule documents patterns inline
- `.claude/tests/propagation-advisory/*` — test fixtures intentionally carry the patterns

## Override marker

A line matching `^[[:space:]]*# OVERRIDE: propagation-exempt: <reason ≥10 chars>` in the edit content skips the scan entirely. Same grammar as the project's other gates (delegation, secrets-scan, supply-chain, governance, memory-index, image-gen). Mandatory ≥10-char reason — `skip`, `n/a` rejected by the length floor.

Legitimate use cases for the override:

- Historical-context prose that mentions a removed upstream feature by spec number
- A rule that intentionally documents anti-patterns by citing the canonical leak shape
- Test fixtures that carry the patterns deliberately

The override does NOT silence the advisory globally — it skips ONLY the specific edit's scan. The next edit to the same file re-runs the scan against its own content.

## Escape hatch

`CLAUDE_SKIP_PROPAGATION_ADVISE=1` short-circuits the hook before any scan. For throwaway scratch sessions where leak prose is acceptable. Do NOT set in a long-lived shell config — it permanently disables the discipline.

## Audit log

**None.** This capacity follows the advisory pattern — stderr signal only, no JSONL audit row. Findings live in session transcript context. If empirical observation shows drift surfacing more than ~3 times per week, that's the trigger to promote to:

1. **Pre-commit gate** (`.githooks/pre-commit`) — blocks drift at commit time
2. **Periodic `/routine`** — monthly scan + drift report regenerated for the maintainer

Both upgrades reuse the same regex set; the advisory is the cheapest first deployment.

## Gotchas

- **Diff-scope, not file-scope.** The hook scans the EDIT (`new_string` / `content` / `edits[].new_string`), not the file after the edit. Pre-existing leaks in untouched portions of a file don't trigger noise on every edit. Trade: a leak introduced by appending to an already-leaky file is still flagged (the appended text matches); a leak that was always there in an untouched paragraph is invisible to this hook.
- **2+-digit floor on spec-NNN.** Matches `spec 12` and up. Avoids false positives on prose like "spec 1 — overview". Agent0 specs are 3-digit zero-padded per the `NNN-<slug>/` convention, so the floor catches every real ref.
- **Pattern volume is capped at 5 per category.** An edit that introduces 30 spec refs surfaces 5 advisory lines per pattern, not 30. Signal economy — the maintainer needs proof of a leak class, not an exhaustive list. Run the audit grep manually for the full picture.
- **The hook doesn't validate `# OVERRIDE:` semantics deeply.** It matches the start-of-line anchor + the 10-char reason floor. Putting the marker inside a quoted heredoc or a Markdown code-fence still counts as "override present" because the hook is regex-based, not shell-aware. Same limitation as the secrets-scan preflight; acceptable for an advisory tier.
- **Parent edits fire.** Unlike `tdd-advisory:` and `secrets-advise.sh` (sub-agent only), this hook fires on parent edits too. The maintainer writing new rules is the most common author of fresh leaks, so excluding parent would defeat the purpose. If parent-fire becomes noisy, the env-var opt-out is the per-session escape.
- **Vendor and design-systems are excluded by path, not by content.** A file at `.claude/skills/product/vendor/open-design/foo.md` can carry `anthill` and `spec 027` freely — the hook never reads it. If vendor content ever migrates out of `vendor/`, the exclusion no longer applies.
- **No content-aware exclusions** for Markdown code-fences or backtick-quoted examples. A rule that legitimately documents leak patterns inline (e.g. this rule itself) is excluded BY PATH at the top of the hook (`.claude/rules/propagation-advisory.md`). Adding more such docs requires updating the path-exclusion case statement.

## Cross-references

- `.claude/memory/propagation-hygiene.md` — the maintainer-binding discipline this hook enforces
- `.claude/hooks/propagation-advise.sh` — implementation
- `.claude/tests/propagation-advisory/` — scenario tests
- `.claude/rules/delegation.md` § *Advisories* — the `<kind>-advisory:` pattern this follows
- `.claude/rules/secrets-scan.md` § *Soft advisory* — sibling on-edit advisory (sub-agent-only variant)
- `.claude/rules/tdd.md` § *Reading the validator advisory* — the canonical advisory-handling convention
