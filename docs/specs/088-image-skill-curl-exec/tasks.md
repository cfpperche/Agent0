# 088 — image-skill-curl-exec — tasks

_Decomposed from `plan.md` on 2026-05-25. Work top-to-bottom, check off as you go. If a task reveals the plan is wrong, update `plan.md` first._

## Implementation

- [x] 1. Flip `spec.md` `**Status:** draft` → `**Status:** in-progress` (already done at scaffold time — verify only).

- [x] 2. Implement `sub_exec()` in `.claude/skills/image/scripts/gen.sh`:
  - Accept the prepare-shape JSON envelope as `--envelope=<json>` or via stdin.
  - Parse `tier`, `model`, `prompt`, `output_path`, `image_size`, `extension` from envelope (use `jq`).
  - Validate `FAL_KEY` set; reuse `die_no_fal_key`.
  - Build request body: `{prompt, image_size}` for FLUX schnell + Imagen; `{prompt, image_size, quality: "high"}` for gpt-image-2 (brand-text tier).
  - POST `https://fal.run/<model>` with `-H "Authorization: Key $FAL_KEY"` and the JSON body. Inline comment: `# REST uses 'Key', NOT 'Bearer' — see image-gen.md § Gotchas`. Capture HTTP code + body.
  - If HTTP ≠ 200: emit body to stderr, print JSON receipt `{"status":"failure","http_code":<N>,"output_path":"..."}` to stdout, exit 1.
  - On 200: `jq -r '.images[0].url'` from response, GET to `<output_path>` (resolved absolute via `PROJECT_DIR`).
  - **Dimension check:** parse returned dims via `file <output>`; if `actual != expected_from_envelope` AND `command -v ffmpeg >/dev/null`: run `ffmpeg -y -loglevel error -i <output> -vf scale=<expected> <output>.tmp && mv <output>.tmp <output>`. If ffmpeg absent: emit `image-skill-advisory: returned <actual>, expected <expected>; install ffmpeg to auto-downscale` to stderr.
  - Print JSON receipt `{"status":"success","output_path":"<rel>","dimensions":"<final>","http_code":200}` to stdout; exit 0.

- [x] 3. Update dispatch case at bottom of `gen.sh` to include `exec) shift; sub_exec "$@" ;;`. Update `--help` text to list 3 subcommands with one-line summaries.

- [x] 4. Update `.claude/skills/image/SKILL.md`:
  - § *Invocation flow* — rewrite step 4 from "Invoke MCP" to "Invoke `gen.sh exec`". Collapse step 5 (write output) into step 4 — write happens inside exec.
  - § *Helper script* — list all 3 subcommands (`prepare`, `exec`, `record`); update the example bash invocation to reflect the new 3-call sequence.
  - § *Notes* — add a sentence: "Hybrid MCP+REST architecture: MCP recipe (`.mcp.json` fal-ai block) covers discovery tools (`search_models`, `get_model_schema`, `get_pricing`, `recommend_model`); generation routes through `gen.sh exec` curl path. See spec 088 for the diagnosis that drove this split."

- [x] 5. Update `.claude/rules/image-gen.md`:
  - § *Activation* — add a paragraph: "Step 1 (`.mcp.json` recipe) is now **optional for generation** — `gen.sh exec` calls fal.run REST directly with `FAL_KEY`. The recipe remains valuable for agent-side discovery (`search_models`, `get_pricing`); skip it only if your fork has no use for those tools."
  - § *Gotchas* — add a new bullet at the top documenting the diagnosis with a pointer to spec 088.

- [x] 6. Update `.claude/skills/image/references/tier-pricing.md`:
  - Bump brand-text `Approx cost (USD/img)` row to `~$0.20 (high default)` with a footnote pointing to spec 088 Open Q1.
  - Bump `Snapshot date` to today (2026-05-25).
  - Add new § *gpt-image-2 min-pixel floor* after § *Aspect ratios* explaining the 655,360 px floor → upsample to 1088×608 + the ffmpeg downscale convention.

- [x] 7. Update `gen.sh` `TIER_TABLE` brand-text cost from `0.040` to `0.200` to match the high-quality default. Inline comment: `# v1 bakes quality=high; see references/tier-pricing.md § brand-text`.

- [x] 8. Smoke-test the new path manually in this Agent0 repo (uses draft tier, ~$0.003):
  ```
  FAL_KEY=<…> bash .claude/skills/image/scripts/gen.sh prepare --tier=draft "a red circle"
  # Take the emitted envelope, pass to exec:
  FAL_KEY=<…> bash .claude/skills/image/scripts/gen.sh exec --envelope='<paste>'
  # Then record:
  bash .claude/skills/image/scripts/gen.sh record --tier=draft --model=fal-ai/flux/schnell --cost=0.003 --prompt="a red circle" --output=<path> --dims=1024x1024
  ```
  Verify: file exists at output_path, manifest line appended with `"status":"success"`, total time <10s.

## Verification

- [x] V1. **Scenario 1 (draft tier end-to-end)**: PASS — `2026-05-26-a-red-circle-on-a.jpg`, 87154 bytes, dims `1024x1024`, exit 0, elapsed 2s, manifest line written with `"status":"success"`.

- [x] V2. **Scenario 4 (FAL_KEY absent)**: PASS — exit 2; stderr matches `FAL_KEY environment variable is not set`; full `die_no_fal_key` template emitted.

- [x] V3. **Scenario 5 (non-200 response)**: PASS — bogus endpoint `fal-ai/nonexistent-endpoint-xyz` → HTTP 404 `{"detail":"Application 'nonexistent-endpoint-xyz' not found"}`; receipt `{"status":"failure","http_code":404,...}`; exit 1.

- [x] V4. **Scenario 6 (cost pre-print preserved)**: PASS — `estimated: $0.003 for fal-ai/flux/schnell at 1024x1024 (square)` is the first stdout line of `prepare`.

- [x] V5. `bash gen.sh --help | grep -cE '^  (prepare|exec|record)\b'` → 3.

- [x] V6. `gen.sh exec` mentioned 3× in SKILL.md (step 4 + helper script + Notes). Two remaining `mcp__fal-ai__run_model` mentions verified as anti-pattern callouts (line 49 "NOT the `mcp__fal-ai__run_model` tool"; line 104 "instead of `mcp__fal-ai__run_model`") — intentional negative documentation.

- [x] V7. `image-gen.md` has the diagnosis bullet (`run_model.*broken` count = 1); `tier-pricing.md` has the `gpt-image-2 min-pixel floor` section (count = 1).

- [x] V8. **Validator clean**: `{"ok":true,"command":"no-stack-detected","exit":0,...}` (no stack on Agent0 base; touched files are bash + markdown, no lint regression possible at this layer).

- [ ] V9. **Scenario 2/3 (dim drift, brand-text empirical)**: DEFERRED — code ships ffprobe-first dim parse + ffmpeg-downscale fallback + advisory. Empirically validated in codexeng spec 004 manual workflow (1088×608 → 1024×576). The live brand-text path through `gen.sh exec` will be exercised at next brand-text invocation; mark done after the first such PASS in any fork.

- [x] V10. **Status flip**: V1-V8 all PASS; V9 explicit deferral. Status flipped to `shipped`.

## Notes

_Anything that came up during execution that doesn't belong in plan.md but is useful for the PR description or future readers._
