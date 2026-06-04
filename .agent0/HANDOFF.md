# Session handoff

Canonical runtime-neutral handoff for Agent0 sessions. Claude Code injects/nags through hooks; Codex receives the same handoff through tracked `.codex/hooks.json` after project/hook trust.

See `.agent0/context/rules/session-handoff.md` for the protocol, 4 KB size discipline, fallback behavior, and reader-side truncation defense.

---

## Current State

**Session 2026-06-04 — spec 147 `image-manifest-gitignore` shipped locally.** Founder decided `assets/generated/.manifest.jsonl` should be gitignored in Agent0 and consumers. Agent0 now ignores it, `assets/generated/.manifest.jsonl` was removed from the git index only (local file preserved), and live `/image` docs now describe it as gitignored local audit state. Brand assets under `assets/brand/*` stay tracked by default.

Validation passed: image-gen tests 4/4, multi-runtime-skills 9/9, harness-sync 40/40, `bash -n` clean for `.agent0/skills/image/scripts/gen.sh` and `.agent0/tools/sync-harness.sh`. `git check-ignore -v assets/generated/.manifest.jsonl` matches in Agent0 and all four consumers; `assets/brand/example.png` does not match Agent0 ignore rules.

**Session 2026-06-04 — Codex `/video` skill-loader warning fixed locally.** Meeting investigation traced the startup warning to `.agent0/skills/video/SKILL.md` frontmatter: unquoted `argument-hint` contained `code: scaffold`, which strict YAML parses as invalid at column 46. The value is now quoted, and `/skill` validation rejects invalid YAML frontmatter before field extraction.

Validation passed: `bash -n .agent0/skills/skill/scripts/validate.sh`; `/skill` fixtures 9/9 including `invalid-yaml-colon-space`; `validate.sh` over every `.agent0/skills/*` skill (only existing body-size warning for `/skill`); PyYAML parse over every skill frontmatter; multi-runtime-skills 9/9; video tests 4 pass / 1 integration skip; `git diff --check` clean.

## Active Work

No active Agent0 work is claimed. Spec 147, the `/video` YAML warning fix, and the meeting transcript were committed and pushed. Consumer sync was applied and pushed to `/home/goat/cognixse`, `/home/goat/mei-saas`, `/home/goat/tese`, and `/home/goat/ag-antecipa`. Existing consumer-local untracked brand assets, `uv.lock`, and unrelated feature work were left intact.

## Next Actions

No next action is pending for spec 147, the `/video` YAML warning fix, or the delegation-gate consumer propagation.

## Decisions & Gotchas

- `assets/generated/.manifest.jsonl` is now local audit state, not durable project history.
- Do not add the manifest to `sync-harness.sh` copy lists; that would risk copying Agent0 prompt/cost history into consumers.
- `/video` policy is unchanged: `.video-manifest.jsonl` remains governed by `.agent0/context/rules/video-gen.md`.
- `argument-hint:` is still a top-level skill frontmatter field; values containing `: ` must be quoted or block-styled.
- Root `AGENTS.md` and `CLAUDE.md` are Agent0-managed entrypoints; consumer-local Codex guidance still belongs in `AGENTS.override.md` or nested `AGENTS.md`.
