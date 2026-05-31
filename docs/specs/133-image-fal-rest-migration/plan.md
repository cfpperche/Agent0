# 133 — image-fal-rest-migration — plan

_Drafted from `spec.md` on 2026-05-31. Update this file if implementation reveals the plan is wrong; do NOT silently diverge._

## Approach

Two independent, low-risk changes. (1) **DRY:** add a synchronous `run` subcommand to `.agent0/tools/fal-rest.sh` that POSTs to `https://fal.run/<model>` (the sync endpoint `/image` uses — distinct from the `queue.fal.run` endpoint the existing `submit`/`status`/`result` use), returning raw fal JSON, model-agnostic. Then rewrite `/image gen.sh`'s `sub_exec` so its HTTP POST goes through `fal-rest.sh run` and its CDN download through the existing `fal-rest.sh download` — while keeping every image-specific concern local (request body shaping with `image_size`/`quality`, `.images[0].url` extraction, ffmpeg dimension reconciliation, the receipt JSON). (2) **Doc-truth:** fix the stale "MCP-delegation" wording in `/image SKILL.md` (`description` frontmatter + body intro) to match the already-correct `compatibility:` field and `image-gen.md` § Activation. The two changes are orthogonal and each independently verifiable, so they land together but are reviewed separately. **Open question resolved:** replace BOTH the POST and the download with lib calls (the `download` primitive is already model-agnostic — maximal DRY, one HTTP surface).

## Files to touch

**Modify:**
- `.agent0/tools/fal-rest.sh` — add `run --model=<id> --body=<json>` (sync POST to `fal.run/<model>`, `Authorization: Key`, return JSON on 200, die with body on non-200). Update `--help` + the dispatch `case`.
- `.agent0/skills/image/scripts/gen.sh` — `sub_exec`: replace the inline `curl POST https://fal.run/$model` block with `bash "$FAL_REST" run --model="$model" --body="$body"`; replace the inline CDN `curl` download with `bash "$FAL_REST" download --url="$image_url" --output="$abs_output"`. Add a `FAL_REST` path resolver (mirror `/video gen.sh`: `$PROJECT_DIR/.agent0/tools/fal-rest.sh`). Keep body/`.images[0].url`/dimension logic + receipt unchanged. On lib failure, still emit the `{"status":"failure",...}` receipt.
- `.agent0/skills/image/SKILL.md` — `description`: drop "(opt-in MCP recipe)", change "invoking the MCP" → "running generation", reframe "Activation - copy fal-ai block..." → "Activation - set FAL_KEY (the fal-ai MCP recipe is optional, discovery-only)". Body intro (line ~14): "via fal.ai's hosted MCP" → "via the fal.ai REST API"; "delegates to the MCP" → "delegates to gen.sh (REST)"; "BEFORE the MCP fires" → "BEFORE generation fires". Bump frontmatter `version: "0.2"` → `"0.3"`.

**Verify (likely no change):**
- `.agent0/context/rules/image-gen.md` — confirm § Activation + § Gotchas already state the REST/spec-088 truth (they do); only touch if a stale claim remains.

**Delete:** none.

## Alternatives considered

### Migrate `/image` fully onto the queue endpoint (`submit`/`poll`) for symmetry with `/video`
Rejected — `/image` is synchronous by design (~1 min, one call, the cost-print-then-generate UX). Forcing it through the async queue would add a poll loop and a ledger for zero benefit and a worse UX. The right shared unit is the HTTP primitive (`run`), not the queue workflow.

### Leave `/image`'s inline curl, only fix the docs
Rejected — the 132 debate explicitly time-boxed the duplication as debt (R4); shipping `fal-rest.sh` and then never migrating `/image` leaves two fal-REST implementations to drift. The `run` primitive is ~20 lines and removes the fork.

### Move image-specific body/response shaping into `fal-rest.sh` too
Rejected — that would re-pollute the lib with `image_size`/`quality`/`.images[0].url` (exactly what the 132 debate Q5 said NOT to do). The lib stays model-agnostic; callers own their request/response shape.

## Risks and unknowns

- **`/image`'s `exec` network path is not covered by the test suite** (tests exercise `prepare`/`record` with fake keys; `exec` needs a real paid key). The refactor is therefore validated by: behavior-preserving structural review, `bash -n`, the full `prepare`/`record` suite staying green, and a new no-network arg-contract test for `fal-rest.sh run`. A real billed draft generation is NOT run (cost; no key). Risk: a subtle exec regression could slip past — mitigated by keeping the body/response/receipt logic byte-identical and only swapping the transport calls.
- **Path resolution for `FAL_REST` in `/image gen.sh`** must use the same `$PROJECT_DIR` resolver `/video` uses, so it works when invoked from any cwd and in a consumer project. Low risk (proven pattern).
- **`fal.run` vs `queue.fal.run` confusion** — the new `run` must hit `fal.run` (sync), not `queue.fal.run`. Test asserts the URL base.

## Research / citations

- `.agent0/skills/image/scripts/gen.sh` (current `sub_exec`, lines ~251–388: inline curl POST + CDN download + dim reconciliation).
- `.agent0/tools/fal-rest.sh` (spec 132 — current `submit`/`status`/`result`/`download`; `run` is the additive sync sibling).
- `.agent0/skills/image/SKILL.md` (stale `description`/intro vs accurate `compatibility:`); `.agent0/context/rules/image-gen.md` § Activation/§ Gotchas (REST-truth already documented).
- Spec 088 `docs/specs/088-image-skill-curl-exec/` (why generation is REST). Spec 132 debate § R4/§ Q5.
