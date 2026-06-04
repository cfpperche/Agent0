# Session handoff

Canonical runtime-neutral handoff for Agent0 sessions. Claude Code injects/nags through hooks; Codex receives the same handoff through tracked `.codex/hooks.json` after project/hook trust.

See `.agent0/context/rules/session-handoff.md` for the protocol, 4 KB size discipline, fallback behavior, and reader-side truncation defense.

---

## Current State

**Session 2026-06-04 — spec 147 `image-manifest-gitignore` shipped locally.** Founder decided `assets/generated/.manifest.jsonl` should be gitignored in Agent0 and consumers. Agent0 now ignores it, `assets/generated/.manifest.jsonl` was removed from the git index only (local file preserved), and live `/image` docs now describe it as gitignored local audit state. Brand assets under `assets/brand/*` stay tracked by default.

Validation passed: image-gen tests 4/4, multi-runtime-skills 9/9, harness-sync 40/40, `bash -n` clean for `.agent0/skills/image/scripts/gen.sh` and `.agent0/tools/sync-harness.sh`. `git check-ignore -v assets/generated/.manifest.jsonl` matches in Agent0 and all four consumers; `assets/brand/example.png` does not match Agent0 ignore rules.

## Active Work

Spec 147 local closeout is complete in Agent0. Consumer sync was applied to `/home/goat/cognixse`, `/home/goat/mei-saas`, `/home/goat/tese`, and `/home/goat/ag-antecipa`, and the 147-relevant files were committed separately in each consumer. Existing consumer-local untracked brand assets, `uv.lock`, debate files, and the unrelated `.agent0/tests/delegation-gate/` propagation were left out.

## Next Actions

Push Agent0 and the four consumer commits when the founder asks. No further local work is needed for spec 147.

## Decisions & Gotchas

- `assets/generated/.manifest.jsonl` is now local audit state, not durable project history.
- Do not add the manifest to `sync-harness.sh` copy lists; that would risk copying Agent0 prompt/cost history into consumers.
- `/video` policy is unchanged: `.video-manifest.jsonl` remains governed by `.agent0/context/rules/video-gen.md`.
- Root `AGENTS.md` and `CLAUDE.md` are Agent0-managed entrypoints; consumer-local Codex guidance still belongs in `AGENTS.override.md` or nested `AGENTS.md`.
