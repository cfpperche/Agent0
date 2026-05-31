# 133 — image-fal-rest-migration

_Created 2026-05-31._

**Status:** shipped

## Intent

Spec 132 extracted `.agent0/tools/fal-rest.sh` as the shared, model-agnostic fal.ai REST primitive layer, but only `/video` consumes it — `/image`'s `gen.sh exec` still carries its own inline curl POST + download. This spec closes the temporary duplication the 132 debate flagged as time-boxed debt (debate R4): migrate `/image` onto `fal-rest.sh` so there is **one** fal-REST implementation, and **fix the stale "delegates to the MCP" wording** in `/image`'s SKILL.md (the Codex debate catch — generation has routed through REST, not the MCP, since spec 088, but the `description` + body intro still say otherwise). Behavior-preserving refactor + doc-truth fix; no change to `/image`'s tiers, output paths, cost gate, or synchronous UX.

## Acceptance criteria

- [x] **Scenario: `fal-rest.sh` gains a synchronous `run` primitive**
  - **Given** the shared lib (currently queue-only: `submit`/`status`/`result`/`download`)
  - **When** a caller needs the synchronous fal endpoint
  - **Then** `fal-rest.sh run --model=<id> --body=<json>` POSTs to `https://fal.run/<model>` (NOT `queue.fal.run`) with `Authorization: Key $FAL_KEY`, prints the raw fal JSON on HTTP 200, and dies non-zero with the fal error body on stderr — model-agnostic (no image/video fields)

- [x] **Scenario: `/image gen.sh exec` delegates HTTP to the shared lib**
  - **Given** a prepared `/image` envelope
  - **When** `gen.sh exec` runs
  - **Then** the HTTP POST goes through `fal-rest.sh run` and the CDN download through `fal-rest.sh download`; image-specific logic (body shaping with `image_size`/`quality`, `.images[0].url` extraction, ffmpeg dimension reconciliation) stays in `/image gen.sh`; the emitted receipt JSON shape is unchanged

- [x] **Scenario: stale MCP-delegation wording corrected**
  - **Given** `/image SKILL.md` `description` says "(opt-in MCP recipe)", "invoking the MCP", "Activation - copy fal-ai block", and the body intro says "via fal.ai's hosted MCP" / "delegates to the MCP"
  - **When** the doc is fixed
  - **Then** those read as REST-truth (generation needs only `FAL_KEY`; the fal-ai MCP is optional discovery), consistent with the already-correct `compatibility:` field and `image-gen.md` § Activation — no remaining claim that generation goes through the MCP

- [x] Behavior preserved: the `/image` test suite (`.agent0/tests/image-gen/`) still passes; `prepare`/`record` output shapes and the manifest schema are byte-identical
- [x] `fal-rest.sh` + `/image gen.sh` pass `bash -n`; no model IDs or image/video-specific fields leak into `fal-rest.sh`

## Non-goals

- **No async migration of `/image`.** `/image` stays synchronous (`fal.run`); only the HTTP plumbing is shared. The queue path (`submit`/`poll`) remains video-only.
- **No tier/path/cost/UX change to `/image`.** Tiers, output paths, the cost-print contract, dimension reconciliation, and the manifest schema are untouched.
- **No new tests for `/image`'s live network path.** It is not network-tested today (needs a real paid key); this spec keeps that posture (structural + suite validation), it does not add a billed integration test.
- **No change to `/video`.** It already uses `fal-rest.sh`; the new `run` primitive is additive.

## Open questions

- [ ] Should `fal-rest.sh download` fully replace `/image`'s inline two-hop download, or only the POST? (Lean: replace both for maximal DRY, since `download` is already model-agnostic.) Owner: plan.

## Context / references

- **Debt origin:** spec 132 debate `docs/specs/132-video-skill/debate.md` § R4 (extract now, migrate `/image` as a decoupled follow-up) + the Codex "stale frontmatter" catch (R1, round-1 point 2).
- **Files:** `.agent0/tools/fal-rest.sh` (add `run`); `.agent0/skills/image/scripts/gen.sh` (exec → lib); `.agent0/skills/image/SKILL.md` (frontmatter + intro doc fix); possibly `.agent0/context/rules/image-gen.md` (verify no stale claim remains — § Gotchas already documents spec 088 REST accurately).
- **Why REST not MCP:** spec 088 (`docs/specs/088-image-skill-curl-exec/`) — the hosted MCP's `run_model` was diagnosed broken; generation routes through `fal.run` REST.
- **Prior:** spec 132 (created `fal-rest.sh`).
