# 112 — prune-supply-chain-and-secrets-advise

_Created 2026-05-29._

**Status:** shipped

## Intent

Prune two low-value advisory/gate capacities from the harness and re-anchor the
third, based on a critical re-read of what each earns its keep on (2026-05-29
session):

1. **Remove the supply-chain capacity entirely** — the `PreToolUse(Bash)`
   block-on-install preflight (`.agent0/hooks/supply-chain-preflight.sh`), the
   `PostToolUse(Edit)` manifest advisory (`.claude/hooks/supply-chain-advise.sh`),
   the rule (`.claude/rules/supply-chain.md`), the audit log, and all tests. The
   founder's decision: **don't limit lib usage at install time at all.** Gating
   `npm install` is the wrong shape; the real supply-chain signal is whether an
   installed lib is *vulnerable*, which a future vuln-audit capacity will surface
   (see Non-goals — that capacity is recorded as direction here, not built).
2. **Remove `secrets-advise.sh`** — the opt-in (`CLAUDE_SECRETS_ADVISE_ON_EDIT`),
   default-off `PostToolUse(Edit)` gitleaks advisory. Redundant: the
   commit-time native gitleaks gate (`.githooks/pre-commit`) + the
   `PreToolUse(Bash)` `secrets-preflight.sh` are the load-bearing layers — nothing
   enters history without passing them. The advise hook only buys marginally
   earlier feedback and ships dormant.
3. **`propagation-advise.sh` — verify-only.** Keep it as the upstream-maintainer
   tool it is, NOT shipped to consumers. **This is already true**: it sits in
   `sync-harness.sh`'s `COPY_CHECK_EXCLUDE` (hook + rule + tests), and the
   `merge_settings_json` companion filter drops its registration from the consumer
   settings merge. No change needed — this spec only asserts the exclusion still
   holds after the other removals (regression guard).

Why now: surfaced during the 106–111 hook-migration arc. "Is it necessary?"
precedes "should we port it?" — porting a capacity that doesn't earn its keep is
wasted work, so the migration is the right moment to delete instead of port.

## Acceptance criteria

### Supply-chain capacity — fully removed

- [x] `.agent0/hooks/supply-chain-preflight.sh` no longer exists.
- [x] `.claude/hooks/supply-chain-advise.sh` no longer exists.
- [x] `.claude/rules/supply-chain.md` no longer exists.
- [x] `.claude/tests/supply-chain/` and `.claude/tests/supply-chain-composer/` no longer exist.
- [x] **Scenario: no supply-chain hook registration survives**
  - **Given** the harness has been pruned
  - **When** `jq` inspects `.claude/settings.json` for any command containing `supply-chain`
  - **Then** zero matches are found (both the `PreToolUse(Bash)` preflight entry and the `PostToolUse(Edit)` advise entry are gone)
- [x] `.gitignore` no longer lists `.agent0/supply-chain-audit.jsonl` or its `.lock`.
- [x] `CLAUDE.md` `## Supply chain` managed-block section is removed (inside the `AGENT0:BEGIN/END` region).
- [x] `AGENTS.md` and `README.md` carry no supply-chain capacity description.
- [x] **Scenario: no dangling cross-references to the removed rule**
  - **Given** `.claude/rules/supply-chain.md` is deleted
  - **When** every other `.claude/rules/*.md`, `CLAUDE.md`, and `.agent0/memory/*.md` is swept for the substring `supply-chain.md` (a link to the deleted rule) or prose presenting supply-chain as a live capacity
  - **Then** each such reference is either removed or rewritten so no live document points at a deleted file

### secrets-advise — removed, secrets-scan otherwise intact

- [x] `.claude/hooks/secrets-advise.sh` no longer exists.
- [x] **Scenario: secrets-advise registration gone, secrets gates kept**
  - **Given** the harness has been pruned
  - **When** `jq` inspects `.claude/settings.json`
  - **Then** no command references `secrets-advise.sh`, AND the `secrets-preflight.sh` `PreToolUse(Bash)` registration is still present (the commit-time defense is untouched)
- [x] `.claude/rules/secrets-scan.md` § *Soft advisory* and the `CLAUDE_SECRETS_ADVISE_ON_EDIT` references are removed; the rest of the rule (native gate, preflight, override grammar, audit log) is unchanged.
- [x] Any secrets-scan test asserting advise-hook behavior is removed; tests for the native gate + preflight remain green.
- [x] `.gitignore` STILL lists `.agent0/secrets-audit.jsonl` (the kept layers write it).

### propagation-advise — behavior unchanged, exclusion verified

- [x] `.claude/hooks/propagation-advise.sh` and `.claude/tests/propagation-advisory/` exist and are byte-unchanged (the hook's behavior is untouched).
- [x] `.claude/rules/propagation-advisory.md` keeps its full propagation-advise mechanism unchanged; only two now-dead cross-refs to the removed capacities were swept (dropped `supply-chain` from the override-marker gate-family list and `secrets-advise.sh` from the "Parent edits fire" gotcha) — the same dead-ref cleanup OQ-1 applied to every other rule. _(Wording corrected post-Codex-review: the original literal "unchanged" contradicted the necessary sweep; reverting would re-introduce dangling refs to the deleted capacities.)_
- [x] **Scenario: propagation-advise stays maintainer-only**
  - **Given** the other removals are applied
  - **When** `sync-harness.sh`'s `COPY_CHECK_EXCLUDE` is inspected
  - **Then** all three propagation-advise paths are still listed, so the hook does not ship to consumers

### Harness integrity after pruning

- [x] **Scenario: full test suite green after pruning**
  - **Given** the three removals are complete
  - **When** the harness test runner executes the remaining suites
  - **Then** all pass — no test references a deleted hook, no orphaned suite remains
- [x] `.agent0/tools/bench-hooks.sh` and `.claude/.perf-baseline.json` no longer reference the removed hooks (or the baseline is regenerated).
- [x] `.agent0/memory/capacity-spec-index.md` no longer indexes supply-chain as a live capacity.
- [x] A `git grep -l` for the removed hook basenames across **live** (non-`docs/specs/`) files returns nothing unexpected (historical specs are left as audit trail).

## Non-goals

- **Building the vuln-audit capacity.** This spec only RECORDS the direction:
  run audit on installed packages (e.g. `osv-scanner` / `npm audit` /
  `pip-audit` / per-ecosystem), detect vulnerable libs, take action. Tool choice,
  trigger surface (on-demand skill vs routine/cron vs commit gate), and scope are
  deferred to a future `/sdd new` spec, fronted by research-before-proposing. A
  reminder + HANDOFF note carry the intent forward.
- **Touching the secrets-scan native gate or `secrets-preflight.sh`.** Only the
  Edit-time advise hook is removed; the commit-time defense is the whole point of
  keeping the capacity.
- **Auto-pruning the removed hook entries from already-synced consumer projects'
  `settings.json`.** The settings merge is additive and does not remove orphaned
  entries (documented limitation, auto-prune deferred to v2). Consumer projects
  prune manually post-sync; the file deletions DO propagate via the deletion pass.
- **Rewriting historical specs** (006–009, 108, 109, etc.). They are the audit
  trail of how these capacities were built; they stay verbatim.
- **Changing `propagation-advise.sh` behavior.** It is verify-only here.

## Open questions

- [x] Sweep depth for dangling cross-refs: do we rewrite *every* illustrative "mirrors the supply-chain gate" mention in sibling rules (delegation, secrets-scan, routines, image-gen, etc.), or only fix links to the deleted `supply-chain.md` file and leave prose analogies that no longer resolve? Proposed default: fix file-links + any prose that presents supply-chain as a *current* capacity; leave pure grammar-family mentions that still make sense without the rule (e.g. "same `# OVERRIDE:` grammar as the other gates"). Owner: founder confirms at plan time.
- [x] Do we delete `.agent0/supply-chain-audit.jsonl` from the working tree if present (gitignored, per-machine), or leave it as dead local data? Proposed: leave it (gitignored, harmless); only remove the `.gitignore` entries and the writers.

## Context / references

- Session 2026-05-29 — critical eval of the three advise hooks; founder decisions captured verbatim in § Intent.
- `.claude/rules/supply-chain.md` — capacity being removed (read for full footprint before deleting).
- `.claude/rules/secrets-scan.md` § *Soft advisory* — the section being removed; rest kept.
- `.agent0/tools/sync-harness.sh` lines 173–219 — manifest globs + `COPY_CHECK_EXCLUDE` (propagation already excluded).
- `.claude/rules/harness-sync.md` § *Manifest scope* / *Upstream deletions* — how file deletions propagate to consumers.
- `.agent0/memory/feedback_speculative_observability.md` — rule-of-three demand test; the lens that justified removing supply-chain-advise's forensic-only audit row.
- Prior specs (audit trail, NOT to edit): 006/007 secrets-scan, 008 supply-chain-scan, 009 supply-chain-block, 070 propagation-hygiene, 108/109 multi-runtime ports.
