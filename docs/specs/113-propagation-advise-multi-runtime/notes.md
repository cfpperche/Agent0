# 113 — propagation-advise-multi-runtime — notes

_Created 2026-05-29._

_In-flight design memory for this spec — decisions, deviations, tradeoffs, and open questions surfaced **while building** that weren't pre-empted by `spec.md` or `plan.md`. Append-only by convention. See `.claude/rules/spec-driven.md` § The four artifacts for purpose, and `.claude/rules/delegation.md` § The 5-field handoff for how sub-agents integrate._

**Entry shape:** `### YYYY-MM-DD — <author> — <one-line title>` followed by free-prose body. `<author>` is `parent` for the orchestrating agent, or the `subagent_type` (e.g. `general-purpose`, `Explore`) for delegated work.

**Routing rubric:** decision made under ambiguity → §1 Design decisions. Intentional departure from `plan.md` → §2 Deviations. Alternative weighed and chosen mid-flight → §3 Tradeoffs. Question surfaced during build, no answer yet → §4 Open questions. Sections may stay empty; the rubric is a guide, not a quota.

## Design decisions

_Choices made where the spec/plan was ambiguous. The decision itself + why this option over others considered in the moment._

### 2026-05-29 — parent — apply_patch content-scan via per-file `^+` sections

The new design problem vs the 106–111 ports: propagation-advise scans CONTENT, but the memory ports only extracted PATHS from `apply_patch`. Solution: funnel both runtimes through a common `(relpath, content)` intermediate. For Codex, `memory_patch_body` gives the patch; an awk pass splits it on `*** (Add|Update|Delete) File:` / `*** Move to:` headers and emits `^+` added lines (prefix stripped) per file — parity with Claude's "new content only" scan, with correct per-file `<relpath>` attribution. Validated manually on all 4 shapes (Claude Edit fire, Codex apply_patch fire, non-shipped silent, override silent) before touching tests. Default OQs adopted: moved to `.agent0/hooks/` (106–111 convention); Codex registration documented for the maintainer's own gitignored `.codex/config.toml`, NOT the shipped `.codex/config.toml.example` (avoids the spec-112 dangling-ref bug).

### 2026-05-29 — parent — caught 3 residual spec-112 sweep misses

While editing the propagation docs for the port, found 3 dead references the spec-112 cross-ref sweep missed (its grep keyed on `supply-chain`/`secrets-advise` literals, which these didn't contain): (1) `propagation-advisory.md` line 3 listed `secrets-advisory:` in the advisory family (secrets-advise removed in 112) → changed to `typecheck-advisory:`; (2) `propagation-advisory.md` § Cross-references linked `secrets-scan.md § Soft advisory` (section removed in 112) → dropped the line; (3) `propagation-hygiene.md` ended "TDD / lint / typecheck / secrets advisories" → dropped "secrets". Fixed in passing. The Codex 112-review also missed these (same literal-grep blind spot) — a reminder that dead-ref sweeps need semantic, not just literal, coverage.

## Deviations

_Places where implementation intentionally departed from `plan.md`. The departure + the reason it was necessary or better._

### {{YYYY-MM-DD}} — {{author}} — {{one-line title}}

{{free-prose body — what the plan said, what was done instead, why}}

## Tradeoffs

_Alternatives weighed during implementation (not at plan time). The chosen path + what was given up + why the tradeoff was worth it._

### {{YYYY-MM-DD}} — {{author}} — {{one-line title}}

{{free-prose body — options considered in-flight, chosen path, accepted cost}}

## Open questions

_Questions surfaced during build that the implementer couldn't resolve alone. Owner (who decides) or path to resolution if known. Promote answered questions to `spec.md` § Open questions or as retroactive acceptance scenarios when the spec is updated._

### 2026-05-29 — parent — live Codex apply_patch did not surface advisory

Fresh live validation in Codex session `019e753c-b82b-7230-9494-bf507d6e9035` created `.claude/rules/_dogfood-113.md` via a real `apply_patch` with added content `this refs spec 080`. The local `.codex/config.toml` has the `PostToolUse(apply_patch)` registration for `.agent0/hooks/propagation-advise.sh`, and the sibling `session-track-edits.sh` PostToolUse hook recorded `.claude/rules/_dogfood-113.md`, `docs/specs/_scratch.md`, and `.claude/rules/_dogfood-113-override.md` in `.agent0/.session-state/019e753c-b82b-7230-9494-bf507d6e9035/edited-files.txt`, proving the Codex PostToolUse chain was active. However, no `propagation-advisory: spec-NNN in .claude/rules/_dogfood-113.md` line appeared in the visible tool result or local session JSONL, and `patch_apply_end.stderr` for the positive dogfood was empty.

Classification for closeout: synthetic/manual hook payload validation is not enough for the first acceptance scenario. Treat the real Codex firing-path acceptance item as open until a live session shows the advisory line, or until an explicit runtime-output limitation is documented and another live side-effect proof is added.

### 2026-05-29 — parent — root-caused the live FAIL: Add File content is raw, not `+`-prefixed

The dogfood CREATED `.claude/rules/_dogfood-113.md` — a `*** Add File:` op, not `*** Update File:`. Bisected the parser against synthetic shapes: `*** Add File:` WITH `+` fires; `*** Add File:` with RAW content (no `+`) was SILENT — matching the live failure exactly. Root cause: the initial parser kept only `^+` lines, but Codex lists new-file content raw. This is the `verify-runtime-capabilities` lesson — I assumed the apply_patch added-line shape from my synthetic Update-File test and never confirmed the Add-File shape.

**Fix:** parser now branches by header — `*** Add File:` → every non-marker line is added content (leading `+` stripped if present, so both variants work); `*** Update File:`/`Delete File:` → only `^+` lines (skip context/removed). Re-validated synthetically across all shapes (Add raw FIRE, Add +-prefix FIRE, Update hunk fires only on +added not context/removed, non-shipped SILENT, override SILENT). Test 12 changed to Add-File-RAW (guards the real failing case); test 14 added (Update-hunk added-only). Suite 14/14 green.

**Still open until live re-confirm:** synthetic match ≠ live proof (the original sin). Added a gated `AGENT0_PROPAGATION_DEBUG=1` payload-capture to the hook so the re-dogfood either (a) shows the advisory line, or (b) dumps the real payload to `.agent0/.propagation-debug.json` for a definitive fix. The acceptance scenario stays unchecked and status stays in-progress until a live Codex session surfaces the advisory.

### 2026-05-29 — parent — re-dogfood proves invocation + parser, but not visible Codex stderr

Re-ran the live Codex `apply_patch` dogfood after the Add-File parser fix in session `019e753c-b82b-7230-9494-bf507d6e9035`. The positive Add File case created `.claude/rules/_dogfood-113b.md` with `this refs spec 080`; Codex again returned only normal apply_patch success and `patch_apply_end.stderr` stayed empty.

Temporary sentinel instrumentation in `.agent0/hooks/propagation-advise.sh` proved the PostToolUse command did run on that real apply_patch payload: it dumped `.agent0/.propagation-debug.json`, whose real shape is `tool_name=apply_patch` and `tool_input.command=<patch body>`, and a temporary sidecar in `emit_one` recorded `propagation-advisory: spec-NNN in .claude/rules/_dogfood-113b.md:1 — this refs spec 080`. Feeding the captured payload back into the unmodified hook also emits the advisory on stderr. The Update File dogfood likewise reached `emit_one` only for the `+added` line. The docs/specs non-shipped case and same-file override case stayed silent.

Classification: the live Codex hook invocation path and parser are proven, including the real `tool_input.command` payload shape; the spec acceptance as written is still FAIL because the advisory line was not surfaced in the Codex-visible stderr/context. Concrete remaining defect is runtime surfacing, not apply_patch parsing.

Follow-up fix in the same turn: updated Codex-path tests 12-14 to build payloads with `tool_input.command` instead of the older synthetic `tool_input.input` shape, so the suite now covers the real captured payload key.

### 2026-05-29 — parent — root-caused the surfacing gap: Codex drops exit-0 stderr; fix = stdout channel

The "advisory built but invisible" gap is a Codex output-contract fact, not a hook bug. Per `.agent0/memory/codex-cli-hooks.md` § Exit-code semantics: a PostToolUse hook's exit-0 **stderr is NOT surfaced** on Codex — only stdout (→ "developer context") or exit-2 stderr (→ block reason) reach the agent. Claude surfaces exit-0 stderr; Codex doesn't. The hook emitted stderr + exit 0, so on Codex it built the correct line into a void. (This also disproves the memory's prior claim that `<kind>-advisory:` stderr lines "port cleanly" — corrected in that memory.)

**Fix:** `emit_one` now branches the channel by `memory_runtime` — **stderr for Claude, stdout for Codex**. Verified synthetically: Codex `apply_patch` → advisory on stdout, stderr empty; Claude `Edit` → advisory on stderr, stdout empty; suite 14/14 (tests 12/14 now assert the stdout channel for Codex, 13 asserts silence on both). A gated `AGENT0_PROPAGATION_DEBUG=1` payload-capture stays in the hook for future format diagnosis; `.agent0/.propagation-debug.json` is gitignored.

**Still open until live re-confirm:** the synthetic stdout channel is proven; a third live Codex dogfood must confirm the `propagation-advisory:` line now appears in the Codex-visible context (developer-context channel). Acceptance scenario #1 stays unchecked / status in-progress until that live proof.

### 2026-05-29 — parent — third dogfood: stdout also not visible to Codex

Re-ran the live Codex `apply_patch` dogfood after the stdout-channel fix by creating `.claude/rules/_dogfood-113c.md` with `this refs spec 080`. The `apply_patch` tool result and session JSONL still showed only the normal patch success; no `propagation-advisory:` appeared as developer-context, tool output, or a separate transcript entry. The relevant `patch_apply_end.stdout` contained only `Success. Updated the following files...`; `patch_apply_end.stderr` remained empty.

Captured the real payload again with temporary sentinel instrumentation. Shape remained `tool_name=apply_patch` and `tool_input.command=<patch body>`. Feeding that exact payload back into `.agent0/hooks/propagation-advise.sh` produced the expected line on stdout and nothing on stderr:

`propagation-advisory: spec-NNN in .claude/rules/_dogfood-113c.md:1 — this refs spec 080`

Conclusion: hook invocation, parser, runtime detection, and stdout emission are all locally proven, but Codex does not expose PostToolUse hook stdout to this agent/session transcript either. The previous `codex-cli-hooks.md` claim that exit-0 stdout becomes developer context is not true for this live `PostToolUse(apply_patch)` command-hook path. Non-shipped `docs/specs/_scratch-113c.md` and shipped override `.claude/rules/_dogfood-113-override-c.md` both replayed to `stdout_bytes=0` and `stderr_bytes=0`.

### 2026-05-29 — parent — final fix: JSON additionalContext closes Codex live path

Official Codex hooks docs resolved the remaining contradiction: for `PostToolUse`, **plain text on stdout is ignored**; JSON stdout may include `hookSpecificOutput.hookEventName = "PostToolUse"` plus `hookSpecificOutput.additionalContext`, and that additionalContext is added as developer context. The earlier stdout-channel fix used plain text, so the live failure was expected.

Implemented the documented shape: on Codex, `emit_one` now appends advisory lines to an accumulator, and after scanning the hook emits a single JSON object:

`{"hookSpecificOutput":{"hookEventName":"PostToolUse","additionalContext":"propagation-advisory: ...\n"}}`

Claude still emits the same advisory lines on stderr, preserving the existing PostToolUse(Edit) behavior. Codex tests 12 and 14 now assert valid JSON stdout and inspect `.hookSpecificOutput.additionalContext`; test 13 still asserts silence on both channels. Suite 14/14 green.

Live Codex dogfood passed end-to-end: a real `apply_patch` created `.claude/rules/_dogfood-113d.md` with `this refs spec 080`, and Codex surfaced a developer-context message:

`propagation-advisory: spec-NNN in .claude/rules/_dogfood-113d.md:1 — this refs spec 080`

Negative live dogfoods remained silent: `docs/specs/_scratch-113d.md` (non-shipped) and `.claude/rules/_dogfood-113-override-d.md` (override marker). Throwaway files were removed afterward. Acceptance #1 is now closed.
