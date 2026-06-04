# 147 — image-manifest-gitignore

_Created 2026-06-04._

**Status:** shipped

## Intent

Change `/image` storage policy so `assets/generated/.manifest.jsonl` is gitignored in Agent0 and every consumer project. The manifest records prompt, cost, status, and local session context for fal.ai image calls; that is useful operator audit data, but it should not become project history or show up as an untracked file the first time a consumer uses `/image`. Durable brand assets remain tracked under `assets/brand/*`; generated draft mockups remain ignored under `assets/generated/mockups/*`.

## Acceptance criteria

- [x] **Scenario: Agent0 ignores the image manifest**
  - **Given** the Agent0 repo has a local `assets/generated/.manifest.jsonl`
  - **When** `git status --short -- assets/generated/.manifest.jsonl` and `git check-ignore -v assets/generated/.manifest.jsonl` are run before the commit
  - **Then** the manifest is matched by the Agent0 `.gitignore` and any status entry is only the intentional index removal, not an untracked file

- [x] **Scenario: Consumers receive the ignore policy**
  - **Given** a synced consumer repo such as `/home/goat/ag-antecipa`
  - **When** `git check-ignore -v assets/generated/.manifest.jsonl` is run there
  - **Then** the consumer `.gitignore` ignores the image manifest by default

- [x] **Scenario: Durable image assets stay tracked**
  - **Given** the updated ignore policy
  - **When** `git check-ignore -v assets/brand/example.png` is run
  - **Then** brand assets are still not ignored by Agent0's default policy

- [x] `.agent0/context/rules/image-gen.md` and `.agent0/skills/image/SKILL.md` describe the image manifest as a local gitignored audit log, not a git-tracked artifact

## Non-goals

- Do not change `/image` output paths or tier semantics.
- Do not change `/video` storage policy; `.video-manifest.jsonl` remains governed by `video-gen.md`.
- Do not delete consumer-local manifest contents; ignore/untrack only.

## Open questions

- [x] Should the manifest be tracked anywhere by default? Owner: founder. Answer: no, gitignore it in Agent0 and consumers.

## Context / references

- `.agent0/context/rules/image-gen.md`
- `.agent0/skills/image/SKILL.md`
- `.gitignore`
- `docs/specs/085-image-gen-opt-in/`
