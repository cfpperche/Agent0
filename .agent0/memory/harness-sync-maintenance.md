---
name: harness-sync-maintenance
description: Maintainer register for the harness-sync rule — design rationale, dogfood history, and promotion triggers extracted under the register-split discipline.
metadata:
  type: project
  created_at: '2026-06-10T00:00:00-03:00'
---

Extracted from `.agent0/context/rules/harness-sync.md` under the register-split discipline (rule-corpus-discipline § B1 — move rationale/history to memory on touch, leave the rule operative).

## Why explicit `--agent0-path` (no auto-detection)

`sync-harness.sh` is in its own propagation manifest (§ Self-rebootstrap) — an identical copy lives at `.agent0/tools/sync-harness.sh` inside every consumer project. So neither the current directory nor `$BASH_SOURCE` can distinguish the Agent0 source from a consumer project: the script's location only reveals "which repo this copy lives in", never "is this repo Agent0". Inferring the source from either would silently sync a consumer project onto itself whenever a consumer project's own copy is run. The explicit-path requirement is the deliberate safe floor — a clean refusal beats a wrong-source sync.

## Consumer-extension convention — why convention, not machinery (yet)

Per-section marker-aware merge (analogous to `CLAUDE.md`'s managed-block) would require shipping `<!-- AGENT0-EXTENSION-START -->` / `<!-- AGENT0-EXTENSION-END -->` markers in every extensible file plus a per-marker merge handler in `sync-harness.sh`. That's ~200 LOC + 7 files of marker overhead. As of 2026-05-25, only **one consumer project** had surfaced this pain, with **two customizations**. Rule-of-three demand test says: don't pre-build the machinery. The convention costs zero LOC and reduces manual-merge time to ~30s per file (because the conflict is always at the same heading).

## Consumer-extension convention — promotion trigger

Promote convention → machinery when **≥3 consumer projects have ≥1 `!! customized` entry on a SKILL.md or rule** OR **≥5 distinct customizations surfaced across ≥2 consumer projects**. The trigger is event-driven, not calendar-driven — it fires when a real consumer hits customization-merge pain at that scale, which announces itself. The tracking reminder `r-2026-05-25` was closed 2026-06-02 as over-engineering: per `[[forks-ephemeral-dogfood]]`, current forks are ephemeral dogfood with no third-party customizers, so a periodic re-evaluation was just noise — this doc is the durable anchor. The machinery's design template already exists: `CLAUDE.md`'s managed-block merge, `settings.json`'s structured-key merge, `.gitignore`'s additive merge — pick the closest analog and generalize.

## Sync baseline — pre-v2 location (legacy path migration)

Spec 130 relocated `harness-sync-baseline.json` from `.claude/` to `.agent0/` — the harness-home for runtime-neutral artifacts, since the baseline is read/written by the runtime-neutral `sync-harness.sh`. The pre-130 `.claude/harness-sync-baseline.json` is read as a fallback and removed on the migrating `--apply`. `load_baseline` falls back to it when the new `.agent0/` path is absent (so a pre-130 consumer reconciles cleanly, no `!! customized` storm); `write_baseline` writes the new path and removes the legacy file after the new one is confirmed written — never before, so a failed write can't lose the baseline. The legacy removal shows as a deletion in the consumer's `git diff`. Once migrated, the fallback is inert.

## Path relocations — spec lineage

The capacity-only posture for path relocations covers the consolidation tracked by umbrella spec 102, which relocated reminders + routines (spec 103), session/runtime/browser state (spec 104), and shared shell tools (spec 105) from `.claude/` to `.agent0/`. The "no upstream auto-migration of consumer content" principle mirrors the hard-cutover posture of the `.claude/SESSION.md` removal (spec 101). The classification principle that drives `.agent0/` placement lives in `.agent0/memory/harness-home.md`.

## settings.json gotcha history — sub-bug A & B (statusLine dogfood)

Two bugs surfaced through statusline dogfood that informed the `merge_settings_json` design. The statusLine key itself was subsequently extracted to user-global `~/.claude/settings.json` on 2026-05-27 (no longer harness-owned), but the failure-mode lessons remain load-bearing for any future harness-owned key referencing a harness-shipped file.

**Sub-bug A (2026-05-12 dogfood):** the harness's `statusLine.command` referenced a script (`.claude/presence/statusline.mjs`) whose directory was missing from `COPY_CHECK_GLOBS`. Fix: the script's glob was added to `COPY_CHECK_GLOBS` so the file traveled with the settings entry that referenced it. Generalisation: whenever a tracked `.claude/settings.json` value references a file under `.claude/`, that file's directory MUST appear in `COPY_CHECK_RECURSIVE` or `COPY_CHECK_GLOBS`, otherwise consumer projects get a settings entry pointing at a non-existent path.

**Sub-bug B (2026-05-19 dogfood):** even after sub-bug A's fix, consumer projects were still missing the relevant `statusLine` block in their `settings.json`. Root cause: `merge_settings_json` jq expression emitted `{hooks: ...}` only, silently dropping every other top-level key (`$schema`, `statusLine`, `permissions`, `env`, `model`) from both sides. Fix: merge function rewritten to use consumer project's settings as the base + explicit whitelist of upstream-owned keys (`$schema` — `statusLine` was on the whitelist at the time and removed by the 2026-05-27 extraction) + the existing per-event hooks dedup. Regression test: `.agent0/tests/harness-sync/23-settings-merge-toplevel-keys.sh`.

**Upstream maintainer rule (derived from these bugs):** when adding any new directory under `.claude/` that ships scripts referenced by hooks/settings, add a matching entry to `COPY_CHECK_RECURSIVE` or `COPY_CHECK_GLOBS`. The audit `git ls-files .claude/ | awk -F/ '{print $1"/"$2}' | sort -u` lists current subdirs; cross-check against the manifest arrays. When adding a new harness-owned top-level key to `settings.json` (beyond `hooks`/`$schema`), also add it to the conditional `has(…)` block in `merge_settings_json` — otherwise the key won't propagate.

## Gotcha — pre-rebootstrap consumer crash is a one-time transitional

The self-rebootstrap guard lives *inside* `sync-harness.sh`, so a consumer project whose copy predates it runs the old, unguarded script on the very `--apply` that updates `sync-harness.sh` — that one run self-overwrites and crashes (or stops short). It is harmless: the crashed run already wrote the new `sync-harness.sh`, so re-running `--apply` completes cleanly. Same one-time-transitional shape as a no-baseline first sync; every `--apply` after it is single-run and crash-free.

The same one-time crash occurs on the spec-105 relocation `--apply` (the one that moves `sync-harness.sh` from `.claude/tools/` to `.agent0/tools/`): the consumer's old `.claude/tools/sync-harness.sh` is deleted as an orphan while bash reads it, and the pre-relocation script guards the old path — but the new `.agent0/tools/sync-harness.sh` is already written, so the re-run completes from the new location. No mitigation code; accepted transitional cost.

## Gotcha — first sync on a long-stale consumer produces a large diff

A consumer project that skipped several upstream releases will see ~30+ new files in one apply. Review the diff section-by-section, not as one giant blob: hooks first, rules second, tools third, then settings.json + CLAUDE.md. Commit in one go (e.g. `chore(harness-sync): adopt upstream harness updates`) so the audit trail is clean.
