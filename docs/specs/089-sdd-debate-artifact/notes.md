# 089 — sdd-debate-artifact — notes

_Created 2026-05-25._

_In-flight design memory for this spec — decisions, deviations, tradeoffs, and open questions surfaced **while building** that weren't pre-empted by `spec.md` or `plan.md`. Append-only by convention. See `.claude/rules/spec-driven.md` § The artifacts for purpose, and `.claude/rules/delegation.md` § The 5-field handoff for how sub-agents integrate._

**Entry shape:** `### YYYY-MM-DD — <author> — <one-line title>` followed by free-prose body. `<author>` is `parent` for the orchestrating agent, or the `subagent_type` (e.g. `general-purpose`, `Explore`) for delegated work.

**Routing rubric:** decision made under ambiguity → §1 Design decisions. Intentional departure from `plan.md` → §2 Deviations. Alternative weighed and chosen mid-flight → §3 Tradeoffs. Question surfaced during build, no answer yet → §4 Open questions. Sections may stay empty; the rubric is a guide, not a quota.

## Design decisions

### 2026-05-25 — parent — In-flight detection keys on the Resolution line, not the section header

Initial SKILL.md Step 2 said "refuse if `## Synthesis` section is absent". But the template ships with `## Synthesis` already present (so the section is ALWAYS there at scaffold time, even in-flight). The section header is therefore not a discriminator between in-flight and complete debates.

Sharpened the check: inspect the `**Resolution:**` line value. Template scaffolds it as the literal placeholder `{{converged | cap-reached | abandoned}}`; Step 7 Synthesis replaces it with one of the three concrete values. So the in-flight signal is "Resolution value is the placeholder", and the complete signal is "Resolution value is one of converged/cap-reached/abandoned". This is the only reliable bit; the header alone is noise.

Surfaced during dogfood verification (task 7) — exactly the kind of "looked obvious in the plan, broke when actually executed" gotcha that notes.md exists to capture.

## Deviations

### 2026-05-26 — parent — Removed Claude-specific coupling; runtime-neutral roles

The dual-agent direct-file design (shipped 2026-05-25) still carried Claude-as-initiator coupling in language and round labels: section header said "scaffold + write Claude-side rounds", Step 4 said "Claude's position", round template headers were `Round N — Claude (position)` / `Round N — external (critique)`. That assumed Claude Code would always be the agent invoking first — fine for the original setup but wrong-shaped for the multi-runtime direction the user pursued the next day (spec 090, `multi-runtime-entrypoints`).

Pivot:

1. **Roles, not runtimes** — `initiating agent` and `reviewing agent` are the two roles; either runtime can take either role. The agent that invokes `/sdd debate` first becomes the initiator and writes Round 1 position; the other runtime becomes the reviewer when first invoked against the same file.
2. **Identity metadata in the file** — three new lines at the top of `debate.md`: `**Initiating agent:**`, `**Reviewing agent:**`, `**Initiated by:**`. The initiator fills the first and third at scaffold time with its port's identity literal (this port writes `Claude Code`); the reviewer fills the second on its first write.
3. **Role detection on re-invocation** — each port compares `**Initiating agent:**` to its own identity string. Match → initiator (write counter or synthesis); mismatch → reviewer (write critique). Legacy files without the metadata fall back to "this runtime is initiator" with a stderr advisory.
4. **Round headers** — generic `Round N — initiating agent (position|counter)` and `Round N — reviewing agent (critique)`. No runtime name in the structure.
5. **Step 5 handoff instruction** — split into two role-shape variants: one for initiator (directs user to peer for next critique), one for reviewer (directs user back to initiator for next counter).
6. **Eval Scenarios** — replaced single happy-path eval with four covering the role permutations: this-initiates, peer-initiated, re-invoke-by-initiator (counter), re-invoke-by-reviewer (critique).

Why now: spec 090 surfaced the need for Agent0 to be transparent across Claude Code and Codex; carrying Claude-coupling in `/sdd debate` would have made spec 090's first dogfood ugly. Cheaper to fix the underlying skill once than to layer special cases later.

Scope kept narrow per user direction: no real Codex integration, no `.codex/` directory, no `AGENTS.md`, no API/MCP/broker. The shared `debate.md` file is still the only cross-runtime contract.

### 2026-05-25 — parent — Pivoted from broker-human-paste to dual-agent direct-file mode

Spec 089 was originally written and shipped with **broker-human** posture: Claude writes Round 1 to `debate.md`, user copies file to GPT-5 UI, pastes response back into Claude session, Claude appends verbatim. Hard cap at Round 3, Claude auto-detected convergence.

Within ~5 minutes of shipping, user pushed back: their actual workflow is **Codex CLI** running in a separate terminal with the same repo, with its own port of this skill. Both agents have native file read/write. The "external model" is not a UI to paste into — it's another tool-calling CLI agent that reads `debate.md` directly.

Pivot applied (this session, before the original ship had been used in anger):

1. **Step 5 broker-instruction** rewritten — no copy-paste; instead, human-orchestrated handoff between two CLI agent sessions sharing the file
2. **Step 6 round-handling** — removed auto-convergence detection; removed 3-round auto-cap; each `/sdd debate` invocation just writes the next empty Claude-side slot based on file state
3. **Step 7 synthesis** — now user-triggered ("synthesize the debate") rather than auto-fired on convergence/cap
4. **Step 2 in-flight refusal** — replaced with "in-flight = continue from current state". Re-invocation IS the orchestration pattern in dual-agent mode; refusing was a broker-human artifact
5. **Template** — broker-protocol + stop-criteria sections rewritten for dual-agent direct-file mode
6. **Rule** (`.claude/rules/spec-driven.md`) — `debate.md` description + step 1.5 updated to match
7. **Spec** (this file's `spec.md`) — intent paragraph + 4 affected acceptance scenarios + non-goals updated to match shipped reality

Why: the broker-human posture solved the wrong problem (UI-paste friction is high; the user wasn't going to do it). The dual-agent posture matches the user's actual setup and has lower per-round friction (one CLI command per agent turn vs file-copy + UI-switch + paste-back).

Out of scope kept explicit: concurrency control (assume turn-based human orchestration), Codex CLI's own port of this skill (user owns), cross-model API bridging (no, both agents are CLI-native).

## Tradeoffs

### 2026-05-25 — parent — Manual sed substitution for dogfood scaffold, not a shell helper

The dogfood step (task 7) used `cp + sed -i 's/{{NNN}}/089/g; ...'` rather than abstracting the substitution into a shell helper. Tradeoff: the SKILL.md text instructs Claude to "substitute exactly as `new` does", which already implies the same 3-placeholder substitution. Adding a helper script would duplicate logic already encoded in `/sdd new` and create a maintenance burden — every change to the substitution rule would need two updates.

Accepted cost: each `/sdd debate` invocation re-derives the substitution in-conversation rather than calling a shared script. The substitution is 3 literal replacements; the re-derivation cost is negligible. If a 4th placeholder is added in the future, both `new` and `debate` need their substitution sections updated — but they would anyway, because they're separate procedural sections in SKILL.md.

## Open questions

_(none surfaced during this build — all 3 spec-time open questions had default answers documented)_
