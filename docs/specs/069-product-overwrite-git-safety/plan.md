# 069 — product-overwrite-git-safety — plan

_Drafted from `spec.md` on 2026-05-21. Update this file if implementation reveals the plan is wrong; do NOT silently diverge._

## Approach

Extract the destructive overwrite into a small, regression-tested script — `.claude/skills/product/scripts/clear-target.sh` — and have SKILL.md Phase 0 step 1 invoke it instead of instructing a blunt `rm -r <out>`. The script computes the harness allowlist and removes only the non-allowlist top-level entries (`<remaining>`); `.git/`, `.claude/`, `CLAUDE.md`, and the rest of the allowlist survive untouched.

**Why a script, not a one-line prose fix (Q2 resolved).** The minimal fix is a prose edit — "`rm` each `<remaining>` entry" instead of "`rm -r <out>`". Rejected as insufficient: a destructive operation gated only by agent-interpreted prose is the exact fragility that produced Gap F (the prose said `rm -r <out>` and that is what ran). A script is deterministic — the agent invokes it, it does not re-derive the deletion set each run — and regression-testable, so the spec's acceptance scenarios become mechanically verifiable rather than "verified by re-reading prose". `/product` already ships a `scripts/` dir (`sync-open-design.ts`), so a second script is structurally consistent, not a new pattern.

**Defense in depth.** The allowlist is the *policy* for what survives; on top of it the script hard-refuses to ever `rm` a path whose basename is `.git` or `.claude`, independent of the allowlist match. A wrong allowlist entry then degrades to "deleted too little", never "deleted history". Deletion uses `rm -r` (never `rm -rf` — the governance gate blocks combined `-r`+`-f`, and the skill's current prose already honors this).

**Q1 resolved.** After a selective overwrite of a git repo, the removed paths show as deletions in `git status` — intended, no special handling. The operator's post-run `git diff` is the audit trail, consistent with every other fork-mutating Agent0 primitive (`sync-harness`, etc.). The only adjacent change: the Phase 0 confirmation prompt message is updated so the operator knows `.git/` and the harness are preserved — sets the right expectation, no behavior change.

Order: write the script → write its regression tests (red against the absent script, green once it exists) → rewire SKILL.md Phase 0 step 1 → update SKILL.md prompt/parenthetical wording.

## Files to touch

**Create:**
- `.claude/skills/product/scripts/clear-target.sh` — selective-clear script. Arg: `<out>` (absolute path). Removes every top-level entry of `<out>` NOT in the harness allowlist; skips `.git`/`.claude` unconditionally (defense in depth); prints one `removed <path>` line per entry; exit non-zero if `<out>` is missing / not a directory. Allowlist held as a script constant with a drift-warning comment naming SKILL.md as canonical.
- `.claude/tests/product-overwrite/` — regression tests (self-contained `mktemp -d` fixtures, mirroring `.claude/tests/harness-sync/` shape): `.git/` preserved, harness allowlist preserved, `<remaining>` cleared, empty/harness-only is a no-op, a dotfile in `<remaining>` is cleared, plus a `run-all.sh` orchestrator.

**Modify:**
- `.claude/skills/product/SKILL.md` — Phase 0 step 1: replace the `On y → rm -r <out>` instruction with `On y → bash .claude/skills/product/scripts/clear-target.sh <out>`; correct the stale parenthetical ("WILL also remove any harness present — founder re-syncs… after") to state that `.git/` and the harness are preserved; tweak the `Overwrite? (y/N)` prompt message so the operator knows what is and isn't removed.

**Delete:** none.

## Alternatives considered

### Prose-only fix (no script)

Change SKILL.md's "`rm -r <out>`" to "`rm -r` each entry in `<remaining>`". Rejected: a destructive op gated only by agent-interpreted prose is the fragility that caused Gap F; not regression-testable; the spec's acceptance scenarios would be verifiable only by re-reading SKILL.md prose, never by running anything.

### Refuse overwrite entirely when `<out>/.git` exists

Make `/product` abort with "target is a git repo — clear it yourself" whenever `.git/` is present. Rejected: too blunt — it blocks the legitimate, now-safe workflow of regenerating a `/product` foundation inside an existing repo (precisely the mei-saas case that motivated this spec). Prior art (`create-vite`, `cargo-scaffold`, copier, cruft) all scaffold *into* existing / git-tracked directories; none refuse them.

### git-aware deletion (`git rm` tracked + `rm` untracked)

Have the overwrite use `git rm -r` for tracked artifacts and `rm` for untracked. Rejected: over-engineered — couples `/product` to git, breaks when `<out>` is not a git repo, and buys nothing. Allowlist-based selective `rm` already preserves `.git/`; history stays intact and the operator's `git status` surfaces the deletions naturally.

## Risks and unknowns

- **Allowlist triplication.** The 7-path list now lives in SKILL.md prose, `sync-harness.sh`'s manifest, and the new script. SKILL.md line 51 already flags the SKILL↔sync-harness drift; the script adds a third copy. Mitigation: drift-warning comment in the script naming SKILL.md as canonical (mirrors the existing line-51 pattern). Not eliminated — single-sourcing the allowlist is its own spec, out of scope here.
- **The script runs real `rm -r`.** A bug in the allowlist match could delete the wrong path. Mitigations: the unconditional `.git`/`.claude` basename refusal (defense in depth), `rm -r` not `rm -rf`, and tests that assert `.git/` survives.
- **Dotfiles / hidden entries in `<remaining>`.** The top-level-entry enumeration must include dotfiles (`.state.json` lives under `docs/`, but `.mcp.json` is a root dotfile and IS in `<remaining>` — it is re-seeded by Phase 0 step 3). A test covers a root dotfile.
- **`clear-target.sh` ships to forks** via `.claude/tests/` + `.claude/skills/` already being in the sync manifest — no manifest change needed; confirm the new `scripts/` path is covered (it is: `.claude/skills` is `COPY_CHECK_RECURSIVE`).

## Research / citations

- create-vite — on a non-empty target it prompts "Target directory is not empty. Please choose how to proceed: Remove existing files and continue"; it clears files and scaffolds in place, it does not delete the directory or `.git/`. Refs: [vitejs/vite#12958](https://github.com/vitejs/vite/issues/12958), [create-vite-app#43](https://github.com/vitejs/create-vite-app/issues/43).
- [cargo-scaffold](https://docs.rs/cargo-scaffold) — exposes `--append` / `--force` for existing-dir handling; robust scaffolders detect `.git/`, preserve it, and copy template files while maintaining git history.
- copier / cruft (researched for spec 068) — update existing projects *in place*; never `rm` the target repo. The recorded-baseline → reconcile model, not delete-and-regenerate.
- `.claude/skills/product/SKILL.md` Phase 0 step 1 + the harness allowlist (lines ~37-51) — the code locus.
- `docs/specs/068-harness-sync-baseline-reconciliation/spec.md` § Non-goals — "Gap F" origin.
