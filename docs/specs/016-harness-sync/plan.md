# 016 — harness-sync — plan

_Drafted from `spec.md` on 2026-05-11. Update this file if implementation reveals the plan is wrong; do NOT silently diverge._

## Approach

Single bash script `.claude/tools/sync-harness.sh` (Bash 3.2 + `jq` baseline — same dependency floor every other hook in this repo assumes). The script walks an **internal manifest** of harness paths/patterns rather than scanning the rule dirs dynamically: explicit lists are easier to audit, harder to mis-trigger, and force the maintainer to update the manifest when a new capacity ships (failure mode is loud, not silent). Three operation categories drive the file walk:

1. **Copy-with-customization-check** — `.claude/hooks/*.sh`, `.claude/rules/*.md`, `.claude/tools/*.sh`, `.claude/validators/*.sh`, `.claude/agents/*` (if present), `.claude/skills/**` (full tree, including `templates/`), `.claude/tests/**`, `.mcp.json.example`, `.gitleaks.toml`, `.githooks/pre-commit`, `.gitignore`. Hash-compare via `sha256sum`: if fork's file exists AND content differs from Agent0 → customized (refuse without `--force`); if fork's file is missing → copy without prompt; if hashes match → `= up to date` (no-op).
2. **Structured merge** — `.claude/settings.json` (jq array-dedup keyed on `(matcher, hooks[].command)` tuple per top-level hook event), `CLAUDE.md` (capacity-section append before `## Compact Instructions` anchor). **CLAUDE.md uses heading-set comparison, not full-file hash** — fork-authored body (Overview, Stack, Gotchas) intentionally diverges from Agent0 and full-hash would always trigger "customized". The semantic check is: which `^## <Title>` headings exist in Agent0 but not in fork? If none missing → up-to-date regardless of body drift. If missing → append those sections only.
3. **Never touched** — explicit denylist surface check; `src/`, fork's `tests/` (outside `.claude/tests/`), `docs/`, `target/`, `node_modules/`, `.venv/`, `dist/`, `build/`, `package.json`, `Cargo.toml`, `pyproject.toml`, `.env*`, `.mcp.json`, `.git/` itself. The walk never recurses into these — they're invisible to the sync.

Modes: `--check` (default, read-only, exit 1 if drift), `--apply` (write changes), `--dry-run` (apply-shaped output without writes, exit 0), `--force` (overwrite customizations with `! overwritten:` warning). `--agent0-path=/abs/path` is required when not invoked from Agent0 itself; `AGENT0_HARNESS_PATH` env is the fallback; guessing is refused (usage hint + exit 2). The fork-path positional arg is mandatory.

Output is line-oriented: `+ copied <path>`, `= up to date <path>`, `!! customized <path>`, `! overwritten <path>`, `~ merged <path>`, `- skipped <path>` (out-of-scope guard fire). Per-file decisions stream to stdout so the developer pipes through `grep` if the diff is large. Final summary line on stderr: counts per outcome. No JSONL audit log — the operation is developer-driven and one-shot; the next `git diff` IS the audit trail.

## Files to touch

**Create:**
- `.claude/tools/sync-harness.sh` — the sync executable. Bash 3.2 compatible, single file, ~400-500 lines. Sections: `usage()`, manifest constants, `arg_parse()`, `resolve_paths()`, `walk_copy_check()`, `merge_settings_json()`, `merge_claude_md()`, `report_summary()`.
- `.claude/rules/harness-sync.md` — operational reference. Mirrors the shape of `.claude/rules/runtime-introspect.md` / `mcp-recipes.md`: what fires, modes, customization-detection algorithm, settings.json merge strategy, CLAUDE.md merge strategy, escape hatches (`--force`, env vars), audit (none — git diff), gotchas.
- `.claude/tests/harness-sync/01-check-mode-lists-drift.sh` — RED scenario 1: missing files surface in `--check`.
- `.claude/tests/harness-sync/02-apply-copies-missing.sh` — RED scenario 2: `--apply` copies + idempotent.
- `.claude/tests/harness-sync/03-apply-refuses-customized.sh` — RED scenario 3: hash-mismatch + exists → refuse, exit non-zero, others proceed.
- `.claude/tests/harness-sync/04-force-overrides.sh` — RED scenario 4: `--force` overwrites + warns.
- `.claude/tests/harness-sync/05-settings-merge-additive.sh` — RED scenario 5: jq dedup-merge.
- `.claude/tests/harness-sync/06-claude-md-section-append.sh` — RED scenario 6: capacity sections appended before Compact Instructions.
- `.claude/tests/harness-sync/07-dry-run-no-writes.sh` — RED scenario 7: dry-run shape matches apply but writes nothing.
- `.claude/tests/harness-sync/08-out-of-scope-untouched.sh` — RED scenario 8: `src/`, `tests/`, `.mcp.json` invisible.
- `.claude/tests/harness-sync/09-idempotent-apply.sh` — RED scenario 9: apply twice → second pass all `=`.
- `.claude/tests/harness-sync/10-agent0-path-explicit.sh` — RED scenario 10: no `--agent0-path` and no env → usage refusal.
- `.claude/tests/harness-sync/11-mcp-json-untouched.sh` — RED scenario 11: `.mcp.json.example` synced, `.mcp.json` invisible.
- `.claude/tests/harness-sync/run-all.sh` — driver that loops over the numbered scripts and reports pass/fail per scenario (mirror of `.claude/tests/runtime-introspect/run-all.sh` shape).

**Modify:**
- `CLAUDE.md` — append `## Harness sync` capacity block immediately before `## Compact Instructions`. ~5-8 lines pointing at `.claude/rules/harness-sync.md`. Mirrors the `## Runtime introspect` / `## MCP recipes` block shape.

**Delete:**
- None. This spec is additive only.

## Alternatives considered

### Bidirectional sync (fork → Agent0)

Rejected because forks ARE downstream by design; improvements flow back via PR review, not auto-sync. Bidirectional would require change-tracking metadata in each fork (commit SHAs, file ancestry), expand the customization-detection surface dramatically (Agent0 file customized? fork file customized? both? merge conflict?), and create a feedback loop where divergent improvements compete silently. One-way + manual PR review is the cheaper, more auditable shape. Revisit only if multiple forks routinely contribute improvements upstream — not the current pattern.

### Marker-file customization tracking (`.harness-version` per file or per-dir)

Rejected because hash-compare achieves the same outcome (detect "is this file the canonical Agent0 version?") without polluting fork directories with metadata files. Marker files would need maintenance every Agent0 sync, would surface in fork `git diff` as noise, and would create a new failure mode where a stale marker lies about the underlying file content. Hash-compare reads file content directly — single source of truth, no drift between marker and reality.

### Textual line-by-line settings.json patching (`patch` / `diff -u`)

Rejected because settings.json is structured JSON; jq-based array-dedup keyed on the natural identity tuple (matcher + command) is reliable and order-independent. Textual patching is brittle when the fork has reformatted the file (different indentation, key ordering), produces unreadable conflict markers when it fails, and offers no semantic understanding of "this hook entry is already registered". jq merge is one-pass, deterministic, and the dedup key is the right semantic identity for hook entries.

### Auto-detect Agent0 path via git remote URL

Rejected because git remotes are not a reliable signal (forks may have rewritten the remote, or have multiple remotes, or have detached working trees). Explicit `--agent0-path` / `AGENT0_HARNESS_PATH` keeps the source-of-truth choice in the developer's hands. The usability cost (one extra flag) is paid once per session via shell history; the wrong-source risk from auto-detection (sync from wrong working tree, sync from a clone with local-only experiments) is permanent.

### Per-spec selective sync (`--spec=011,012`)

Rejected for v1 because partial syncs introduce a new drift dimension: spec 011's hook present in fork but spec 011's rule doc missing (or vice versa). The cognitive cost of "did I sync the WHOLE capacity or just half" outweighs the freedom of partial sync. v1 syncs the full harness; if real demand surfaces (e.g. a fork wants to skip the secrets-scan capacity), revisit in v2 with a manifest-section flag.

## Risks and unknowns

- **`## Compact Instructions` anchor missing in fork's CLAUDE.md.** If a fork has renamed or removed that section, the CLAUDE.md merge step has no insertion point. Mitigation: detect the missing anchor pre-flight, emit `!! claude-md: missing "## Compact Instructions" anchor — capacity sections appended at EOF` warning, and append at EOF instead of failing the whole sync. The fork developer reviews the diff and either accepts EOF placement or reorganizes manually.
- **settings.json arrays grow unbounded over many syncs without prune.** The dedup logic prevents duplicate insertions, but if Agent0 later renames a hook (e.g. `supply-chain-scan.sh` → `supply-chain-block.sh`) the old entry stays in the fork's settings.json. v1 accepts this; the fork's `git diff` after sync will surface the new entry next to the stale old one, and the developer can prune manually. Auto-prune is a v2 feature gated on real-world drift evidence.
- **Hash-compare false-negative on whitespace-only changes.** A fork that ran `prettier` or `shfmt` over a hook script will have different bytes but identical semantics; sync will flag the file customized and refuse. Mitigation: documented in the rule doc — developer either reverts the formatter pass or uses `--force` consciously. No auto-normalization (would mask real customizations).
- **Bash script tested via tmp-dir fixtures, but real shrnks may surface edge cases.** Tests cover the scenario matrix from spec.md, but the three real shrnks (pyshrnk, shrnk, rshrnk) at Agent0 spec 007 state are the canonical first-real-customer. Plan: ship the script with green tests, then dry-run against each shrnk and inspect output before any `--apply`. Findings from those dry-runs feed back as test fixtures.
- **`.claude/tests/` sync may overwrite fork-specific test fixtures.** A fork might have added local-only tests under `.claude/tests/<capacity>/`. The customization check protects modified shared files, but fork-only NEW files under `.claude/tests/<capacity>/` are not removed by the sync (sync only writes; it never deletes). Acceptable — the fork's extra tests survive.
- **Concurrent `--apply` from two terminals.** Unlikely in practice (sync is a deliberate developer action), but no locking. The second writer overwrites the first's output. Acceptable for v1; mirrors the same "don't run two `git pull` in parallel" assumption.
- **Bash 3.2 portability.** macOS ships Bash 3.2; common pitfalls (no `declare -A` associative arrays, no `mapfile`) must be avoided. The hooks already follow this discipline; sync-harness inherits it.

## Research / citations

- Codebase: `.claude/hooks/runtime-capture.sh`, `.claude/hooks/supply-chain-scan.sh` — Bash 3.2 + jq baseline patterns for stdin parsing, `flock`-atomic appends (not needed here but reference shape), `printf x` + `${var%x}` trailing-newline preservation.
- Codebase: `.claude/tests/runtime-introspect/run-all.sh` — driver shape for the `.claude/tests/harness-sync/run-all.sh` mirror.
- Codebase: `.claude/settings.json` — structural shape (top-level `hooks` object with event-name keys → array of `{matcher, hooks: [{type, command}]}` entries) that drives the jq dedup key choice.
- Codebase: `CLAUDE.md` — capacity-section pattern (`^## <Title>` heading + free-form body) anchored by `## Compact Instructions` always-last.
- Codebase: `.claude/rules/runtime-introspect.md`, `.claude/rules/mcp-recipes.md` — rule-doc shape (intent, what fires, schema, escape hatches, gotchas).
- Spec 002 (`docs/specs/002-delegation/`) — hash-compare and override-marker patterns predate this spec; `.claude/hooks/delegation-gate.sh` is the reference for `# OVERRIDE: <reason>` shape (not used in 016 but conceptually related discipline).
- External: Cookiecutter / cruft (Python template sync) — concept inspiration only; their drift detection is timestamp + commit-SHA based, which is the marker-file alternative rejected above. Reference: <https://cruft.github.io/cruft/>
- External: `dotbot` (dotfile sync) — YAML-manifest-driven file copy; same shape as our internal-bash-manifest, simpler problem (no structured merge). Reference: <https://github.com/anishathalye/dotbot>
- Live evidence: pyshrnk / shrnk / rshrnk at `/home/goat/{py,,r}shrnk` — three real forks at Agent0 spec 001-007 state, the canonical drift the sync tool must close.
