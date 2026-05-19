# 059 — In-flight notes

## Design decisions

### 2026-05-19 — parent — Allowlist inlined, not externalized

The 7-path Agent0 harness allowlist is inlined verbatim in `SKILL.md` § Phase 0 step 1 rather than referenced from a separate config file. Trade: maintenance debt (allowlist must stay in sync with `sync-harness.sh` manifest). Why: a separate config file would mean Phase 0 has to load/parse another resource at run time. The skill is model-orchestrated — adding I/O surface there is friction. Spec 016's sync-harness already enumerates the manifest in its own source; the spec 059 allowlist mirrors that, and the audit task (task 1) catches drift before each /product release.

### 2026-05-19 — parent — `.gitignore` append-marker is verbose

Marker chosen: `# --- /product (Next.js) ---`. Alternative considered: `# /product` (terse). Verbose wins because it survives `grep` searches and signals intent to a fork developer scanning the file cold. The same marker shape exists already in other parts of Agent0 (e.g. `compaction-continuity.md` references `# CC` markers in CLAUDE.md). Consistency.

### 2026-05-19 — parent — Surgical `rm -r` deferred

Spec 048's existing semantics for "dir has /product artifacts" remain: prompt overwrite → full `rm -r <out>` on `y`. Surgical rm (preserve harness during rm) was considered but rejected for v1. The re-run scenario (re-running /product on a dir with both harness AND prior /product output) is recoverable via `sync-harness.sh` post-rm, just annoying. If it becomes common (≥3 dogfoods), follow-up spec with surgical rm + tested rm-path-list.

## Deviations

(None yet — spec is fresh.)

## Tradeoffs

- **Tiny scope vs comprehensive.** Could have shipped surgical rm + harness-aware writes for CLAUDE.md + harness-aware writes for `.gitignore` + harness-aware writes for any future conflict. Picked tiny — only fix the immediate blocker (Phase 0 prompt) + minimal `.gitignore` collateral. Reduces shipping risk; surgical rm can land later when empirically needed.
- **Allowlist drift risk.** Hardcoding the 7 paths in SKILL.md means a sync-harness manifest expansion creates drift. Trade: cheap to audit (one file each side), zero runtime config-loading.
- **No automated test.** /product has no test harness today. Manual verification is the contract. Acceptable for v1; if /product gains a test framework someday, add scenarios 1-5 there.

## Open questions

1. **What if founder has manually-edited files at `<out>/` root that are NOT harness AND NOT /product output?** Current spec triggers the overwrite prompt for them (treats as /product artifacts). Founder can abort. Surgical rm would be more lenient but is out of scope. Watch for complaints in real use.
2. **Marker idempotency edge case.** If a founder edits the auto-generated `.gitignore` section (under the marker) and then re-runs /product, the replace-region-under-marker logic loses their edits. Acceptable? Probably — /product's `.gitignore` rules are deterministic from `--stack`. If founder wants custom rules, they go ABOVE the marker.
