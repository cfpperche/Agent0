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

Maintainer-binding companion to `.agent0/context/rules/propagation-advisory.md`. The companion rule carries the consumer-facing slice (what the advisory line looks like, override grammar, escape hatch); this memory carries the upstream-maintainer surface — the 5-pattern regex table, the shipped-surface set, the audit-log promotion policy, and the deep gotchas a maintainer extending the hook needs.

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
- `.agent0/hooks/*.sh`
- `.agent0/context/rules/*.md`
- `.agent0/tools/*.{sh,py,ts}`
- `.agent0/validators/*.sh`
- `.claude/agents/*.md`
- `.claude/skills/**` (except `vendor/` and `design-systems/`)
- `.agent0/tests/**`
- `.githooks/*`
- `CLAUDE.md`, `.mcp.json.example`, `.gitleaks.toml`, `.gitignore`

### Within-surface exclusions

- `.claude/skills/*/vendor/*` — vendored upstream content (open-design, etc.) has its own provenance
- `.claude/skills/*/design-systems/*` — vendor `DESIGN.md` files
- `.agent0/hooks/propagation-advise.sh` — the hook itself documents patterns inline
- `.agent0/context/rules/propagation-advisory.md` — the rule documents patterns inline
- `.agent0/tests/propagation-advisory/*` — test fixtures intentionally carry the patterns

## Audit log

**None.** This capacity follows the advisory pattern — session-context signal only, no JSONL audit row. Claude surfaces the signal via stderr; Codex surfaces it via JSON stdout `hookSpecificOutput.additionalContext`. If empirical observation shows drift surfacing more than ~3 times per week, that's the trigger to promote to:

1. **Pre-commit gate** (`.githooks/pre-commit`) — blocks drift at commit time
2. **Periodic `/routine`** — monthly scan + drift report regenerated for the maintainer

Both upgrades reuse the same regex set; the advisory is the cheapest first deployment.

## Deep gotchas

- **Diff-scope, not file-scope.** The hook scans the EDIT — Claude `new_string` / `content` / `edits[].new_string`, or (Codex, spec 113) the `^+` added lines of each `apply_patch` per-file section — not the file after the edit. Pre-existing leaks in untouched portions of a file don't trigger noise on every edit. Trade: a leak introduced by appending to an already-leaky file is still flagged (the appended text matches); a leak that was always there in an untouched paragraph is invisible to this hook.
- **2+-digit floor on spec-NNN.** Matches `spec 12` and up. Avoids false positives on prose like "spec 1 — overview". Agent0 specs are 3-digit zero-padded per the `NNN-<slug>/` convention, so the floor catches every real ref.
- **Pattern volume is capped at 5 per category.** An edit that introduces 30 spec refs surfaces 5 advisory lines per pattern, not 30. Signal economy — the maintainer needs proof of a leak class, not an exhaustive list. Run the audit grep manually for the full picture.
- **The hook doesn't validate `# OVERRIDE:` semantics deeply.** It matches the start-of-line anchor + the 10-char reason floor. Putting the marker inside a quoted heredoc or a Markdown code-fence still counts as "override present" because the hook is regex-based, not shell-aware. Same limitation as the secrets-scan preflight; acceptable for an advisory tier.
- **Vendor and design-systems are excluded by path, not by content.** A file at a vendored path can carry leak strings freely — the hook never reads it. If vendor content ever migrates out of `vendor/`, the exclusion no longer applies.
- **No content-aware exclusions** for Markdown code-fences or backtick-quoted examples. A rule that legitimately documents leak patterns inline (e.g. the consumer-facing `.agent0/context/rules/propagation-advisory.md`) is excluded BY PATH at the top of the hook. Adding more such docs requires updating the path-exclusion case statement.

## Runtime-neutral + Codex activation (spec 113)

The hook lives at `.agent0/hooks/propagation-advise.sh` and sources `_memory-hook-lib.sh`. It fires on Claude `Edit|Write|MultiEdit` (registered in `.claude/settings.json`) AND on Codex `apply_patch`. Both runtimes funnel through a common `(relpath, content)` scan: Claude contributes the per-tool new content; Codex contributes each `apply_patch` per-file section's `^+` added lines (split on `*** (Add|Update|Delete) File:` / `*** Move to:` headers via `memory_patch_body`).

**The Codex registration is maintainer-only and must NOT ship.** Unlike the runtime-neutral hooks that ship to consumers (memory, secrets-preflight, delegation), propagation-advise is excluded from consumer propagation (see § *Shipped surface* / `propagation-hygiene.md`). The 106–111 pattern registers the Codex side in `.codex/config.toml.example` — but that file ships verbatim (`COPY_CHECK_FILES`) with NO exclusion filter, so a block there would point every consumer at a hook they don't have (the dangling-ref bug spec 112 cleaned up). Therefore:

- **Do NOT add a propagation-advise block to `.codex/config.toml.example`.** A test/grep asserts it stays absent.
- The maintainer who wants Codex coverage adds the block to their OWN gitignored `.codex/config.toml` (never shipped):
  ```toml
  [[hooks.PostToolUse]]
  matcher = "^apply_patch$"
  [[hooks.PostToolUse.hooks]]
  type = "command"
  command = 'bash "$(git rev-parse --show-toplevel)/.agent0/hooks/propagation-advise.sh"'
  statusMessage = "Scanning shipped-file edit for upstream-internal pointers"
  ```
- Claude-side exclusion is unchanged: `COPY_CHECK_EXCLUDE` lists `.agent0/hooks/propagation-advise.sh` (updated path), and the `merge_settings_json` companion filter drops the Claude registration by `propagation-advise.sh` basename (dir-agnostic, survives the move).

**apply_patch added-content extraction — two modes (spec 113 live-dogfood finding).** The first live Codex dogfood (2026-05-29) FAILED because the initial parser kept only `^+` lines, but Codex lists `*** Add File:` (new-file) content as **raw lines, no `+` prefix** — so a created file's leak was missed. The parser now branches by header:
- `*** Add File:` → mode `add`: EVERY subsequent non-marker line is added content (a leading `+`, if present, is stripped — handles both raw and +-prefixed variants).
- `*** Update File:` / `*** Delete File:` → mode `hunk`: only `^+` lines are additions (context ` ` and removed `-` lines are skipped — verified by test 14 that a leak on a context/removed line does NOT surface).
- `*** Begin/End Patch` and `@@` hunk headers are ignored.

If a future Codex format diverges again, set `AGENT0_PROPAGATION_DEBUG=1` in the runtime env — the hook dumps the raw stdin payload to `.agent0/.propagation-debug.json` (off by default, harmless) so the real shape can be inspected instead of guessed. This is the lesson from the failed first dogfood: do not assume the apply_patch wire shape — capture it.

**Output channel branches by runtime — this is the load-bearing surfacing detail.** `emit_one` writes the advisory to **stderr on Claude** but only accumulates advisory text on Codex; after scanning, Codex emits one JSON stdout object with `hookSpecificOutput.hookEventName = "PostToolUse"` and `hookSpecificOutput.additionalContext = <advisory lines>`. Reason (spec 113 live dogfood, 2026-05-29): Codex `PostToolUse` does NOT surface exit-0 stderr, and it also ignores plain stdout; the documented and live-proven non-blocking context path is JSON stdout `additionalContext`. The first port emitted stderr-only and exit 0 — invisible. The second emitted plain stdout — still invisible. The final JSON stdout fix surfaced the advisory end-to-end. See `.agent0/memory/codex-cli-hooks.md` § Exit-code semantics for the corrected cross-runtime table. Any future advisory hook ported to Codex must use the same JSON additionalContext pattern.

## Cross-references

- `.agent0/context/rules/propagation-advisory.md` — consumer-facing companion (override grammar + escape hatch + advisory-line shape)
- `.agent0/memory/propagation-hygiene.md` — the upstream-maintainer discipline this hook enforces
- `.agent0/hooks/propagation-advise.sh` — implementation (runtime-neutral; sources `_memory-hook-lib.sh`)
- `.agent0/tests/propagation-advisory/` — scenario tests (incl. Codex `apply_patch` scenarios 12–14)
