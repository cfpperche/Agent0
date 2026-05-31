# 132 — video-skill — tasks

_Generated from `plan.md` on 2026-05-31. Work top-to-bottom. Check boxes as tasks complete. If a task reveals the plan is wrong, update `plan.md` before continuing._

## Implementation

- [x] 1. **Spike HyperFrames render CLI** — confirmed: project-based (`init`/`render -o out.mp4`/`doctor`), composition format (`#root` data-attrs + paused GSAP timeline). Findings in `notes.md`. `code.sh` uses an owned template (not `init`) + wraps `doctor`.
- [x] 2. **Shared fal REST lib** — `.agent0/tools/fal-rest.sh`: `submit`/`status`/`result`/`download`; `Authorization: Key`; curl/jq; model-agnostic.
- [x] 3. **Tier table** — `.agent0/skills/video/references/video-tiers.yaml`: snapshot 2026-05-31, 3 tiers (draft/standard/premium) + Higgsfield documented as optional alt.
- [x] 4. **Generative helper** — `.agent0/skills/video/scripts/gen.sh`: `prepare` (gate), `submit` (ledger), `poll [--all|--id]` (status→result→download→manifest).
- [x] 5. **Code helper** — `.agent0/skills/video/scripts/code.sh`: `doctor`/`scaffold`/`render` + render fingerprint; fail-clean on missing toolchain.
- [x] 6. **Owned authoring layer** — `references/authoring.md` + `references/composition-template/` (index.html + hyperframes.json + package.json; lint-clean).
- [x] 7. **Skill body** — `.agent0/skills/video/SKILL.md`: required `--mode` router + errors; `agentskills-portable` frontmatter.
- [x] 8. **Codex manifest** — `.agent0/skills/video/agents/openai.yaml` (`allow_implicit_invocation: false`).
- [x] 9. **Discovery symlinks** — `.claude/skills/video` + `.agents/skills/video` → canonical body (both resolve).
- [x] 10. **Capacity rule** — `.agent0/context/rules/video-gen.md`.
- [x] 11. **Storage + gitignore** — `.gitkeep`s under `assets/video/`, `assets/video/compositions/`, `assets/generated/videos/`; `.gitignore` ignores rendered MP4s (ledger already covered by `.runtime-state/*`).
- [x] 12. **Entrypoint index** — `## Video generation` block added to `CLAUDE.md` + `AGENTS.md`.
- [x] 13. **Runtime-capabilities row** — `video generation` row added.
- [x] 14. **Tests** — `.agent0/tests/video/` (01 router/portability · 02 cost gate · 03 scaffold contract · 04 fal-rest lib · 05 gold render integration + run-all).

## Verification

_Acceptance checks tied to `spec.md` acceptance criteria._

- [x] **`--mode` required** — documented in SKILL.md; test 01 asserts the error + both options.
- [x] **Multi-runtime discovery** — both symlinks resolve; `openai.yaml allow_implicit_invocation: false` (test 01).
- [x] **Cost gate** — `prepare` refuses without/below `--confirm-cost-usd`; passes at/above; code exempt (test 02).
- [x] **Ledger async** — submit→ledger→poll shape implemented; gate+envelope+tier-resolution validated dry (test 02). _Live fal submit/poll network path is implemented but NOT billed-tested (needs a real FAL_KEY + paid job)._
- [x] **Tier refreshable** — resolves from `video-tiers.yaml`; no model IDs in body; stale-snapshot advisory (test 01/02).
- [x] **Zero-cost-if-unused + clean errors** — no-FAL_KEY error (test 02); missing-composition/dep fail-clean (test 03).
- [x] **Static facts** — `agentskills-portable`; shared lib at `.agent0/tools/fal-rest.sh` not `gen.sh` (test 04); manifest field-aligned with `/image`.
- [x] **Lint/syntax** — `bash -n` clean on all new `.sh` (shellcheck not installed in env); composition template lints 0/0; real render produced a valid 1920×1080 MP4 with a fingerprinted manifest line.

## Notes

- **Gold validation:** a real HyperFrames render ran end-to-end in this environment (`code.sh doctor` all-green) → `assets/generated/videos/2026-05-31-hello-agent0.mp4` (1920×1080 h264, 5s) + a fingerprinted manifest line. The opt-in integration test `05` (VIDEO_RENDER_IT=1) reproduces it.
- **Lint quirk (pre-1.0):** HyperFrames' lint is line-based — keep `#root` data-attrs on one line and no HTML comment immediately before `<div id="root">`, else false `root_missing_*`. Template + `authoring.md` + `video-gen.md` document it; template lints 0/0.
- **Follow-up (not a blocker):** (1) register the new managed files in `harness-sync-baseline.json` once specs 130/131 settle its location (the file is mid-relocation — absent from the tree right now). (2) Decoupled spec: migrate `/image` onto `.agent0/tools/fal-rest.sh` + fix `/image`'s stale MCP-delegation frontmatter wording (Codex debate catch).
