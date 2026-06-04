# 151 — sync-harness-local-only

_Created 2026-06-04._

**Status:** shipped

## Intent

Some consumer projects want the Agent0 harness present **locally for development use** but **never committed** to their tracked history — e.g. a public repo that gitignores the whole `.agent0/` tree so the agent has current tooling without polluting the public project with harness files. Today `sync-harness.sh` has no notion of this: every `--apply` also writes/merges **tracked** files (`.gitignore`, `CLAUDE.md` + `AGENTS.md` managed blocks, `.gitleaks.toml`, `.githooks/`, `.claude/settings.json`), which then show up as committable drift. This forced a manual, error-prone workaround (the 2026-06-04 tmux-sentinel propagation accidentally pushed a harness `.gitignore` commit to a public repo). This spec adds a first-class **local-only mode**: `--apply` still refreshes the consumer's gitignored harness content, but leaves every **tracked** file untouched, so there is nothing harness-related to commit. Serves the maintainer running propagation and any consumer that consumes the harness as local dev tooling only.

## Acceptance criteria

- [x] **Scenario: local-only is auto-detected from the consumer's .gitignore**
  - **Given** a consumer whose `.gitignore` ignores the whole `.agent0/` harness tree (verified via `git check-ignore` on representative harness paths)
  - **When** `sync-harness.sh --check` or `--apply` runs against it
  - **Then** local-only mode activates automatically with no flag or marker required.

- [x] **Scenario: local-only apply refreshes harness but touches no tracked file**
  - **Given** a local-only (auto-detected) consumer whose working tree is clean
  - **When** `sync-harness.sh --apply` runs against it
  - **Then** gitignored harness content (the `.agent0/` tree the consumer ignores) is written/updated as usual, AND no tracked file is created or modified (`git status --porcelain` reports nothing for tracked paths) — specifically the `.gitignore` merge, the `CLAUDE.md`/`AGENTS.md` managed-block writes, `.gitleaks.toml`, `.githooks/*`, and `.claude/settings.json` merge are all skipped.

- [x] **Scenario: local-only mode is reported, not silent**
  - **Given** a local-only consumer
  - **When** `--apply` (or `--check`) runs
  - **Then** the tool prints a clear one-line notice that local-only mode is active and how many tracked-file writes were skipped (no silent truncation of behavior).

- [x] **Scenario: a normal (non-local-only) consumer is unchanged**
  - **Given** a consumer not flagged local-only
  - **When** `--apply` runs
  - **Then** behavior is byte-identical to today (tracked files merged/written as before) — local-only is strictly opt-in, zero regression.

- [x] **Scenario: the baseline still records under local-only**
  - **Given** a local-only consumer
  - **When** `--apply` runs
  - **Then** `.agent0/harness-sync-baseline.json` is still written (it lives under the gitignored `.agent0/`, so it is local state, not tracked drift) — re-syncs stay idempotent.

- [x] A regression test exercises local-only mode (tracked files untouched + reported) alongside the existing harness-sync suite; suite stays green.
- [x] `.agent0/context/rules/harness-sync.md` documents local-only mode and when to use it.

## Non-goals

- Does NOT change what counts as harness content vs project-local content (the existing copy-roots/excludes are unchanged).
- Does NOT add per-consumer config beyond what the resolved mechanism requires (no general consumer-config system).
- Does NOT retroactively rewrite or revert any prior accidental harness commit (e.g. tmux-sentinel `611b159`) — that is a one-off, accepted.
- Does NOT remove the consumer-side `.gitignore` discipline; local-only complements it, it does not replace it.

## Open questions

- [x] **Mechanism — RESOLVED (c): auto-detect from `.gitignore`.** Claude and Codex independently converged (2026-06-04 de-biased consult) on **(c)**: infer local-only by asking git's own ignore engine — `git check-ignore` on representative `.agent0/` harness paths; if the harness tree is ignored, the consumer has already made the durable "`.agent0/` is not part of this repo" decision, so enter local-only. Rejected: (a) flag — too easy to forget, recreates the exact failure this fixes; (b) tracked marker — contradicts the zero-footprint goal by adding a harness artifact to a clean public repo. Magic risk mitigated by: only infer when the **whole** `.agent0/` tree is ignored, and **always print an explicit notice** + document the rule.
- [x] `customized-refused` treatment — orthogonal; out of scope (closed).

## Context / references

- `.agent0/context/rules/harness-sync.md` — the sync discipline this extends.
- `.agent0/tools/sync-harness.sh` — `COPY_CHECK_*` arrays, `merge_settings_json`, `merge_claude_md`, gitignore-merge, `write_baseline`.
- `.agent0/memory/tmux-sentinel-sync-no-commit.md` — the motivating case (public consumer, harness gitignored, must never commit).
- Spec 144 (gitignore-aware walk) + the 150.x sync-harness MAX_ARG_STRLEN baseline fix — recent sync-harness work.
