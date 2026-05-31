# 133 — image-fal-rest-migration — tasks

_Generated from `plan.md` on 2026-05-31. Work top-to-bottom. Check boxes as tasks complete. If a task reveals the plan is wrong, update `plan.md` before continuing._

## Implementation

- [x] 1. **Add `run` to `fal-rest.sh`** — synchronous `run --model=<id> --body=<json>` → POST `https://fal.run/<model>` (`Authorization: Key`), print JSON on 200, die with body on non-200. Wire into the dispatch `case` + `--help`.
- [x] 2. **Migrate `/image gen.sh sub_exec`** — add `FAL_REST` resolver; replace the inline `curl POST fal.run` with `fal-rest.sh run`; replace the inline CDN download with `fal-rest.sh download`. Keep body shaping, `.images[0].url`, dimension reconciliation, and the receipt JSON byte-identical; preserve the failure-receipt path.
- [x] 3. **Fix stale docs in `/image SKILL.md`** — `description` frontmatter + body intro: remove MCP-delegation claims, reframe activation as FAL_KEY (MCP optional/discovery). Bump `version` to `0.3`.
- [x] 4. **Verify `image-gen.md`** carries no remaining "generation via MCP" stale claim (touch only if found).
- [x] 5. **Add `fal-rest.sh run` arg-contract test** to `.agent0/tests/video/` (or a shared lib test): `run` without `--model` dies; without FAL_KEY dies; `--help` lists `run`. No network.

## Verification

- [x] **`run` primitive** — `fal-rest.sh run` hits `fal.run` (not `queue.fal.run`); model-agnostic; dies clean without `--model`/`FAL_KEY` (new test + grep).
- [x] **`/image` behavior preserved** — `.agent0/tests/image-gen/` suite passes; `prepare`/`record`/manifest shapes unchanged.
- [x] **Doc-truth** — no "delegates to the MCP" / "invoking the MCP" / "via fal.ai's hosted MCP" left in `/image SKILL.md`; `description`+intro consistent with `compatibility:`.
- [x] **Syntax** — `bash -n` clean on `fal-rest.sh` + `/image gen.sh`; no image/video fields leaked into `fal-rest.sh`.

## Notes

_Populated during execution._
