---
name: propagation-advisory-maintenance
description: Maintainer discipline for propagation-advisory — pattern table + shipped-surface set + audit-log policy + deep gotchas.
metadata:
  type: project
  created_at: '2026-05-27T00:00:00Z'
  last_accessed: '2026-05-27'
  confirmed_count: 0
---
# Propagation advisory maintenance

Maintainer-binding companion to `.claude/rules/propagation-advisory.md`. The companion rule carries the consumer-facing slice (what the advisory line looks like, override grammar, escape hatch); this memory carries the upstream-maintainer surface — the 5-pattern regex table, the shipped-surface set, the audit-log promotion policy, and the deep gotchas a maintainer extending the hook needs.

## The 5 patterns

Each maps to a leak class documented in `.agent0/memory/propagation-hygiene.md`.

| Label | Regex | Catches | Example |
|---|---|---|---|
| `spec-NNN` | `\b[Ss]pec [0-9][0-9]+\b` | Concrete spec numbers | `spec 080`, `Spec 12` |
| `docs/specs/NNN` | `docs/specs/[0-9]+-` | Concrete spec dir paths | `docs/specs/070-propagation-hygiene/` |
| `anthill` | `\banthill\b` (case-insensitive) | Upstream design lineage | `anthill-fpa`, `Anthill's brand book` |
| `personal-path` | `/home/[a-z][a-z0-9_-]+/` | Personal absolute paths | `/home/goat/Agent0` |
| `memory-pointer` | `\.agent0/memory/[a-z][a-z0-9_-]+\.md` | Memory file pointers | `.agent0/memory/cc-platform-hooks.md` |

### Pattern exclusions (legitimate keeps that bypass the scan)

- `docs/specs/NNN-<slug>/` — the literal placeholder naming convention (no digits)
- `docs/specs/001-<slug>/`, `docs/specs/001-{{SLUG}}/`, `docs/specs/002-foundation/`, `docs/specs/003-*` — consumer-output paths the `/product` skill writes
- `.agent0/memory/MEMORY.md` — the index file (carries no upstream-specific content)
- `.agent0/memory/<topic>.md`, `<slug>.md`, `<file>.md`, `<name>.md` — placeholder forms a rule may legitimately reference
- `.agent0/memory/.gitkeep` — empty scaffold

## Shipped surface (where the hook fires)

Mirrors `.agent0/memory/propagation-hygiene.md § The shipped file class`:

- `.claude/hooks/*.sh`
- `.claude/rules/*.md`
- `.agent0/tools/*.{sh,py,ts}`
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
- `.claude/rules/propagation-advisory.md` — the rule documents patterns inline
- `.claude/tests/propagation-advisory/*` — test fixtures intentionally carry the patterns

## Audit log

**None.** This capacity follows the advisory pattern — stderr signal only, no JSONL audit row. Findings live in session transcript context. If empirical observation shows drift surfacing more than ~3 times per week, that's the trigger to promote to:

1. **Pre-commit gate** (`.githooks/pre-commit`) — blocks drift at commit time
2. **Periodic `/routine`** — monthly scan + drift report regenerated for the maintainer

Both upgrades reuse the same regex set; the advisory is the cheapest first deployment.

## Deep gotchas

- **Diff-scope, not file-scope.** The hook scans the EDIT (`new_string` / `content` / `edits[].new_string`), not the file after the edit. Pre-existing leaks in untouched portions of a file don't trigger noise on every edit. Trade: a leak introduced by appending to an already-leaky file is still flagged (the appended text matches); a leak that was always there in an untouched paragraph is invisible to this hook.
- **2+-digit floor on spec-NNN.** Matches `spec 12` and up. Avoids false positives on prose like "spec 1 — overview". Agent0 specs are 3-digit zero-padded per the `NNN-<slug>/` convention, so the floor catches every real ref.
- **Pattern volume is capped at 5 per category.** An edit that introduces 30 spec refs surfaces 5 advisory lines per pattern, not 30. Signal economy — the maintainer needs proof of a leak class, not an exhaustive list. Run the audit grep manually for the full picture.
- **The hook doesn't validate `# OVERRIDE:` semantics deeply.** It matches the start-of-line anchor + the 10-char reason floor. Putting the marker inside a quoted heredoc or a Markdown code-fence still counts as "override present" because the hook is regex-based, not shell-aware. Same limitation as the secrets-scan preflight; acceptable for an advisory tier.
- **Vendor and design-systems are excluded by path, not by content.** A file at a vendored path can carry leak strings freely — the hook never reads it. If vendor content ever migrates out of `vendor/`, the exclusion no longer applies.
- **No content-aware exclusions** for Markdown code-fences or backtick-quoted examples. A rule that legitimately documents leak patterns inline (e.g. the consumer-facing `.claude/rules/propagation-advisory.md`) is excluded BY PATH at the top of the hook. Adding more such docs requires updating the path-exclusion case statement.

## Cross-references

- `.claude/rules/propagation-advisory.md` — consumer-facing companion (override grammar + escape hatch + advisory-line shape)
- `.agent0/memory/propagation-hygiene.md` — the upstream-maintainer discipline this hook enforces
- `.claude/hooks/propagation-advise.sh` — implementation
- `.claude/tests/propagation-advisory/` — scenario tests
