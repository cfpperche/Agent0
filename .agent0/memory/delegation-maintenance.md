---
name: delegation-maintenance
description: Maintainer-register for delegation.md — spec lineage, design rationales, and historical validator-cascade archaeology extracted from the rule corpus.
metadata:
  type: project
  created_at: '2026-06-10T00:00:00-03:00'
---
# Delegation maintenance

Maintainer-binding design-memory extracted from `.agent0/context/rules/delegation.md` during the register-split discipline (rule-corpus-discipline.md). The rule carries only operative content; historical rationales and spec-lineage archaeology live here.

## Spec lineage

- **spec 106** — every dispatch row in the audit log gained three discriminator fields: `schema_version` (`1`), `runtime` (`"claude-code"`), and `event` (`"dispatch"`). Hard cutover from the former `.agent0/delegation-audit.jsonl` format; no legacy-read path.
- **spec 111** — replaced the former per-edit `post-edit-validate.sh` hook with the stop-time `delegation-verify.sh` at `SubagentStop`. Two reasons: (1) Codex `PostToolUse(apply_patch)` carries no parent-vs-subagent discriminator, so per-edit delegated-edit attribution is not portable — `SubagentStop` carries `agent_id` on both runtimes; (2) the full suite running on every edit was expensive and cascade-prone. The section heading "Post-edit validator loop" is retained as a stable cross-reference anchor despite the trigger moving to stop-time.
- **spec 113** — Codex `SubagentStart`/`SubagentStop` `apply_patch` and propagation-advise port; runtime-neutral hooks hardened.
- **spec 155** — UI-producing brief verification integrated into `delegation-verify.sh`: surfaces the validator's `visual-contract-advisory:` and checks the named bundle's `report.json` for `.overall=="pass"` (non-blocking) at `SubagentStop`. Spec reference was on the UI-producing briefs paragraph of the rule.

## Validator-cascade archaeology

The "per-edit validator-cascade" was observed across Waves 3-5 of a `/product` dogfood run on 2026-05-20. Under the old per-edit design, ≥2 sub-agents editing one shared tree concurrently each saw the others' half-written files and flipped `ok` to `false` on errors they did not cause. Stop-time verification (spec 111) structurally eliminates this: each sub-agent is verified once, at its own close, against its own final tree state. Worktree isolation remains recommended for parallel fan-outs, but now for write-collision reasons only — not validator interference.

## Codex enforcement posture — verification history

The Codex convention-only posture (no blocking gate for the 5-field handoff) was verified against the official Codex hooks docs on 2026-05-28. Checked surfaces: `SubagentStart` is observational (`continue:false` "doesn't stop the subagent from starting"); `PreToolUse` never fires on a spawn (spawn is not a tool call); `PermissionRequest` does not fire on spawn and is an approval allow/deny, not a field validator. See `.agent0/memory/codex-cli-hooks.md` § Subagent dispatch surface for the full hook-surface audit.

## Why no `ISOLATION:` brief field

The original worktree-isolation draft proposed a 6th optional `ISOLATION:` field in the 5-field handoff. Empirical pre-flight (2026-05-19) showed the canonical mechanism is already `tool_input.isolation` set by the parent in the `Agent` tool call. Adding a brief field would duplicate intent (once verbally in CONSTRAINTS/DELIVERABLE, once mechanically in tool params) without enforcement value — the gate cannot mutate the tool call payload from the brief. The audit row records the canonical signal (`isolation` field in the dispatch row); the rule documents the discipline; the validator scoping fix mitigates the cross-cwd risk regardless of declaration. The `ISOLATION:` field was never shipped.
