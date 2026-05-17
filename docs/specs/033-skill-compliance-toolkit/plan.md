# 033 — skill-compliance-toolkit — plan

_Drafted from `spec.md` on 2026-05-17. Update this file if implementation reveals the plan is wrong; do NOT silently diverge._

## Approach

Build `/skill` as a self-contained meta-skill mirroring the `/sdd` namespace shape — five subcommands (`new`, `audit`, `port`, `validate`, `list`) under one directory at `.claude/skills/skill/`, with `templates/`, `references/`, and `scripts/` sub-folders that follow the same convention every other Agent0 skill already uses. Validator is bash, zero-dep; `skills-ref` (the official Python reference impl) is honored as defer-to-canonical when present on `PATH` but never required. The 3-tier portability classification (`cc-native` / `agentskills-portable` / `runtime-agnostic`) ships as a documented policy in `references/portability-tiers.md` and is recorded per-skill in `metadata.portability-tier` (custom key, allowed by spec).

Build order is **knowledge artifacts first, then logic, then orchestrator, then dogfood**: snapshot the agentskills.io spec into `references/spec-snapshot.md`; write the tier definitions; write the validator's human-readable rule list. Then build `validate.sh` and the 3 SKILL.md templates. Then write the meta-skill `SKILL.md` itself (which must be self-compliant — the toolkit's first acceptance test is validating its own SKILL.md). Finally apply `/skill port` to the 3 first-party skills (`remind`, `sdd`, `brainstorm`) as both dogfood and the immediate value delivery that unblocks REMINDERS.md item #2.

## Files to touch

**Create:**
- `.claude/skills/skill/SKILL.md` — meta-skill orchestrator with 5 subcommands (`new`, `audit`, `port`, `validate`, `list`); must pass its own validator
- `.claude/skills/skill/templates/SKILL.md.tmpl` — canonical compliant template, all fields commented inline
- `.claude/skills/skill/templates/cc-native.tmpl` — variant for skills with `.claude/` body paths; pre-fills `compatibility:` and `metadata.portability-tier: cc-native`
- `.claude/skills/skill/templates/portable.tmpl` — variant for runtime-agnostic skills; pre-fills the portable `compatibility:` text
- `.claude/skills/skill/references/spec-snapshot.md` — verbatim agentskills.io specification frozen 2026-05-17, with source URL + retrieval date in the header
- `.claude/skills/skill/references/portability-tiers.md` — 3-tier definition, examples per tier, decision flowchart
- `.claude/skills/skill/references/description-best-practices.md` — condensed best-practices for description authoring (kept local for offline access + Agent0-specific tailoring)
- `.claude/skills/skill/references/frontmatter-validation-rules.md` — human-readable enumeration of what `validate.sh` checks (failure modes + remediation hints), keeps validator behavior auditable without reading bash
- `.claude/skills/skill/scripts/validate.sh` — bash validator, zero-dep, exit 0 on pass / non-zero on fail with stderr listing violations by rule
- `.claude/skills/skill/scripts/port-frontmatter.sh` — idempotent frontmatter patcher invoked by `/skill port`; adds missing required fields, nests CC-extensions in `metadata:`, preserves body bytes
- `.claude/skills/skill/tests/fixtures/` — fixture SKILL.md files (one compliant, several with each kind of violation) for validator development and regression
- `.claude/skills/skill/tests/validate.test.sh` — shell harness running `validate.sh` against fixtures; exit non-zero on any unexpected pass/fail

**Modify:**
- `.claude/skills/remind/SKILL.md` — port via `/skill port`: add `name: remind`, add `compatibility:` (cc-native text), nest `argument-hint:` under `metadata:` (or keep dual-mirrored — see risk below), add `metadata.portability-tier: cc-native`
- `.claude/skills/sdd/SKILL.md` — same port shape
- `.claude/skills/brainstorm/SKILL.md` — same port shape
- `CLAUDE.md` — add `## Skill compliance` capacity block (single paragraph) pointing at `/skill` toolkit + linking the tier policy; follows the existing capacity-section convention

**Delete:**
- (none)

**Possibly create — defer to implementation:**
- `.claude/rules/skill-compliance.md` — only if behavioral mandate beyond SKILL.md docs proves needed (e.g., "new skills MUST declare a tier"). Leaning no; the SKILL.md scaffolder enforcing tier via templates is sufficient guard. Decide when the meta-skill SKILL.md is drafted.

## Alternatives considered

### Adopt `skills-ref` (Python) as the required validator

Rejected because adopting a Python dependency in the base repo violates Agent0's "harness ships zero-dep, bash-first" posture (spec 011 runtime-introspect, spec 016 harness-sync, spec 023 session-edit-attribution — all chose shell over Python despite richer ecosystem). Per-user venv management + Python version drift becomes friction at fork time. The validation surface is small enough (~6 rules: required-field presence, dirname-match, description-length, compatibility-length, name-regex, body-line-cap) that a bash implementation fits in ~30 lines. `skills-ref` is honored as defer-to-canonical fallback when present (`command -v skills-ref` check at top of `validate.sh`) — best of both: zero-dep default, canonical truth when available.

### Quick patch (Caminho A) — manual frontmatter edit, no toolkit

Rejected because it solves the immediate compliance gap but leaves no enforcing infrastructure. The 4th skill, 5th, Nth will repeat the same `name:`-missing mistake — there's no scaffolder forcing the shape and no `audit --all` to catch drift. Per Agent0's culture (delegation gate, post-edit validator, hook-enforced disciplines), one-off patches are the anti-pattern: capacity-as-policy is the convention. Spec exists to institutionalize, not to band-aid. The Caminho A trade was acknowledged in the discussion that produced this spec — user explicitly chose B.

### Auto-validate on Skill tool invocation via `PreToolUse(Skill)` hook

Rejected for v1 because (a) scope creep — this spec ends at "skill is compliant", not at "harness blocks invalid skills"; (b) requires deciding the policy on validation failure (block, warn, auto-port-then-rerun) which is a separate design conversation; (c) only 3 first-party skills exist today, so reactive `/skill validate` invoked by the user covers the volume. Revisit as a follow-up spec once first-party skill count ≥ ~10 OR after a real "we shipped a broken skill" incident — whichever surfaces first.

### One skill per concern — `skill-new`, `skill-audit`, `skill-port`, etc.

Rejected because it splits a single coherent toolkit across multiple Skill entries, inflating the discovery surface in the Skill list with no compositional benefit. `/sdd` already proves the multi-subcommand-under-one-namespace shape works (5 subcommands) and the user is fluent in it; cross-subcommand state (e.g. `port` invoking `validate` internally as its own confirmation gate) is trivial inside one skill, awkward across separate ones.

### Skip the snapshot file — link to live agentskills.io spec from `validate.sh`

Rejected because the validator's rule set MUST be frozen against a known spec version. Live-linking turns Agent0's validator into a moving target: an upstream spec edit could silently flip a passing skill to failing (or vice versa) with no audit trail. The dated `spec-snapshot.md` makes drift explicit — if upstream changes, the snapshot is the diff target. Periodic re-snapshot ritual (probably quarterly) is a small ongoing cost vs. the surface area silently floating.

## Risks and unknowns

- **Risk — `argument-hint` migration breaks CC rendering.** The Claude Code harness reads `argument-hint:` as a top-level frontmatter field to render the slash-command typing hint. Moving it under `metadata:` may stop CC from rendering. Mitigation: probe CC's behavior in a live session before declaring the port done. If CC reads only top-level, keep `argument-hint:` at top-level AND mirror it under `metadata:` for cross-runtime discoverability — accept the duplication. The cross-runtime cost of a missing hint is tiny; the CC-side cost of breaking the hint is real friction.
- **Risk — `metadata.portability-tier` collides with future agentskills.io spec field.** Mitigation: research during impl (Open question #1 in spec); if collision risk surfaces, namespace as `agent0.portability-tier`. Cheap rename if needed.
- **Risk — validator false positives on YAML edge cases.** Unicode in description, multi-line YAML strings, escaped quotes, etc. Mitigation: build a fixture corpus in `tests/fixtures/` covering known edge cases; iterate validator until the corpus passes.
- **Risk — spec drift.** agentskills.io spec evolves between adoption (2026-05-17) and any given future moment. Mitigation: dated snapshot file is the diff target; consider a REMINDERS.md item for quarterly re-check — deferred to post-ship decision.
- **Unknown — how strictly do Hermes / Codex / Cursor enforce frontmatter conformance?** Whether they reject SKILL.md missing `name:` outright vs silently degrade is empirically untested. This spec assumes spec-correct shipping is the right contract; actual cross-runtime behavior testing is part of REMINDERS.md #2 (publish `mcp-product-pipeline`), not this spec.
- **Unknown — best-practices file in `references/` earns its keep?** Tentatively yes (offline access + Agent0-specific tailoring), but if it sits unread after 3 months of toolkit life, fold it into `SKILL.md` body or delete.
- **Unknown — `init` / `review` / `security-review` / etc. (CC-marketplace skills) — confirm they truly are external and uneditable from this repo.** Spec assumes yes; verify during audit implementation (probably by inspecting the Skill tool's surfaced skill registry).

## Research / citations

- agentskills.io specification (will be frozen as `references/spec-snapshot.md`): https://agentskills.io/specification
- agentskills.io best practices (source for `description-best-practices.md`): https://agentskills.io/skill-creation/best-practices
- agentskills.io quickstart (canonical hello-world template): https://agentskills.io/skill-creation/quickstart
- `skills-ref` Python reference validator (defer-to-canonical target): https://github.com/agentskills/agentskills/tree/main/skills-ref
- Hermes Agent (consumer runtime driving the urgency): https://hermes-agent.nousresearch.com
- Hermes Agent / agentskills.io client showcase (40+ tools implementing the standard, surveyed for portability-tier examples): https://agentskills.io (Junie, Gemini CLI, Cursor, Goose, GitHub Copilot, VS Code, Claude Code, OpenAI Codex, Roo Code, Trae, Letta, Workshop, fast-agent, nanobot, OpenCode, OpenHands, others)
- Direct audit baseline: contents of `.claude/skills/{remind,sdd,brainstorm}/SKILL.md` (read 2026-05-17) — established the concrete gaps (missing `name:`, missing `compatibility:`, `argument-hint:` at top-level)
- `.claude/rules/spec-driven.md` § Acceptance scenarios (drove the `spec.md` shape choice — Given/When/Then sub-bullets for behavior, plain bullets for static facts)
- `.claude/rules/memory-placement.md` (drove the references/ placement decision — knowledge artifacts that ship WITH the skill go in `.claude/skills/<name>/references/`, NOT in `.claude/memory/` which is project-local and not shipped to forks)
- Prior agentskills.io research synthesis: conversation 2026-05-17 (Hermes Agent deep-research → Risk #1 → meta-skill design)
