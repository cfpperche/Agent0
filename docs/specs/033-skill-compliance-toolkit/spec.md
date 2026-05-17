# 033 — skill-compliance-toolkit

_Created 2026-05-17._

**Status:** shipped

## Intent

Ship a `/skill` meta-skill that scaffolds new SKILL.md files, audits existing ones against the agentskills.io spec, and ports non-compliant skills to compliance — plus a 3-tier portability classification (`cc-native` / `agentskills-portable` / `runtime-agnostic`) declared in skill metadata. Driving fact: an audit of Agent0's 3 first-party skills (`remind`, `sdd`, `brainstorm`) found all 3 missing the spec-required `name:` field and none declaring `compatibility:`, which blocks reuse by any agentskills-compatible runtime that validates strictly (Hermes Agent, Codex CLI, Cursor, OpenCode, Goose, plus ~35 others using Anthropic's open standard). Toolkit institutionalizes the discipline so future skills are born compliant, and unblocks the cross-runtime distribution path that REMINDERS.md item #2 (publish `mcp-product-pipeline` as a skill) depends on.

## Acceptance criteria

_Observable outcomes as Given/When/Then scenarios for behavior, plain checkbox bullets for static facts. If every box can be ticked, the spec is delivered. Each criterion should be verifiable without re-reading the plan. See `.claude/rules/spec-driven.md` § Acceptance scenarios for shape guidance._

- [x] **Scenario: scaffold a compliant new skill**
  - **Given** `.claude/skills/<slug>/` does not exist and `<slug>` matches the spec name regex
  - **When** the user runs `/skill new <slug>`
  - **Then** `.claude/skills/<slug>/SKILL.md` is created with all spec-required fields (`name:` matching the dirname, `description:` placeholder under 1024 chars, `compatibility:` placeholder, `metadata.agent0-portability-tier:` placeholder — kebab-namespaced per Phase C decision) and immediately passes `/skill validate <slug>`

- [x] **Scenario: audit detects all spec gaps across the suite**
  - **Given** the 3 existing Agent0 skills (before being ported) with missing `name:` and missing `compatibility:`
  - **When** the user runs `/skill audit --all`
  - **Then** the report enumerates each `.claude/skills/<slug>/` directory with its declared tier and compliance status (`✓ compliant` / `✗ non-compliant` + rule IDs from validator stderr), with no false positives on already-compliant skills. *Externals scope (per Non-goal): CC-marketplace skills (`init`, `review`, etc.) are surfaced by the CC harness, not by `.claude/skills/` files, and v1 does not enumerate them — documented in the audit footer.*

- [x] **Scenario: port adds frontmatter without altering body bytes**
  - **Given** an existing SKILL.md missing `name:` and `compatibility:`
  - **When** the user runs `/skill port <slug>` and confirms the proposed compatibility text
  - **Then** the patched SKILL.md (a) has `name:` matching dirname, (b) has `compatibility:` populated, (c) preserves `argument-hint:` at top-level (per Phase C decision: CC reads it only there; original "moved into metadata" plan was abandoned), (d) preserves description verbatim, and (e) the bytes after the frontmatter `---` closer are byte-identical to the original (verified on remind/sdd/brainstorm: 5664/14779/14454 bytes pre = post)

- [x] **Scenario: validator distinguishes pass and fail with actionable exit codes**
  - **Given** a compliant SKILL.md
  - **When** `/skill validate <slug>` runs
  - **Then** exit 0 with no stderr; **and** given a non-compliant SKILL.md, exit non-zero with stderr listing each violation by spec rule ID (verified: `name-regex-fail` fixture → exit 1, `rule2-name-regex` + `rule3-name-dirname-mismatch` on stderr)

- [x] **Scenario: portability tier classification on audit**
  - **Given** a skill whose body references `.claude/rules/`, `${CLAUDE_SKILL_DIR}`, or `.claude/hooks/`
  - **When** `/skill audit <slug>` runs
  - **Then** the report labels the skill `cc-native` and proposes the canonical `compatibility:` text for that tier (`port-frontmatter.sh` auto-detects via body grep)

- [x] **Scenario: meta-skill is self-compliant (dogfood)**
  - **Given** the `/skill` meta-skill itself
  - **When** `/skill validate skill` runs
  - **Then** exit 0 — the meta-skill ships as a spec-compliant exemplar

- [x] **Scenario: skills-ref defer-to-canonical when available**
  - **Given** the official Python `skills-ref` CLI is on `PATH`
  - **When** `/skill validate <slug>` runs
  - **Then** the bash validator defers to `skills-ref validate` and surfaces its output verbatim (canonical truth wins); when `skills-ref` is absent, the embedded bash validator runs without warning (code path at `validate.sh:42-44` verified by inspection; runtime test N/A — skills-ref not installed in dev env)

- [x] `.claude/skills/skill/SKILL.md` exists and passes `/skill validate skill`
- [x] `.claude/skills/skill/scripts/validate.sh` is executable, requires no Python dependency, and exits 0/non-0 correctly on the bundled fixture skills (`validate.test.sh` → 8/8)
- [x] `.claude/skills/skill/references/spec-snapshot.md` contains a verbatim, attributed copy of the agentskills.io spec frozen at adoption date (2026-05-17)
- [x] `.claude/skills/skill/references/portability-tiers.md` defines the 3 tiers with at-least-one example per tier
- [x] All 3 first-party Agent0 skills (`remind`, `sdd`, `brainstorm`) pass `/skill validate <slug>` after being ported by this spec's tasks
- [x] A skill scaffolded via `/skill new <slug>` produces a SKILL.md that passes `/skill validate <slug>` without manual edits to the frontmatter

## Non-goals

_What this change explicitly does NOT do. Future scope or adjacent problems that look similar but aren't in this spec._

- **Rewriting skill bodies for portability.** Frontmatter compliance is in scope; body rewrites (replacing `${CLAUDE_SKILL_DIR}` with portable env-var indirection, decoupling from `.claude/` paths, etc.) is a separate spec if and when a real consumer demands it.
- **Touching CC-marketplace skills.** `init`, `review`, `security-review`, `claude-api`, `simplify`, `fewer-permission-prompts`, `loop`, `schedule`, `update-config`, `keybindings-help` ship from Anthropic's Skill marketplace; they are visible to the harness but not editable in this repo. `/skill audit --all` may list them under a `[external]` label for visibility, but does not propose patches.
- **Adopting Python `skills-ref` as a hard dependency.** Validator is bash-first, zero-dep. `skills-ref` is honored as a defer-to-canonical fallback when present.
- **Auto-validation hook on Skill tool invocation.** Reactive `/skill validate` is enough for v1. A `PreToolUse(Skill)` hook that auto-blocks invalid skills can be a follow-up spec once volume of skills justifies it.
- **Cross-runtime conformance testing.** Validating SKILL.md against the spec is the toolkit's job; empirically running ported skills under Hermes / Codex / Cursor and confirming behavior is out of scope here — that's part of REMINDERS.md item #2 work for `mcp-product-pipeline`.
- **Skill marketplace publishing (hermeshub / skilldock / agentskills.so).** Publishing channels are downstream of "skill is compliant"; this spec ends at compliance, not at distribution.

## Open questions

_Unknowns to resolve before `plan.md` can be locked. Each should have an owner (who decides) or a path to resolution. Empty if there are none._

- [x] **Resolved (Phase C task #10):** namespace is `agent0-portability-tier` (kebab-prefixed). No prior community claim found; defensive prefix chosen to defend against future upstream collision. See `.claude/skills/skill/references/portability-tiers.md` § "Why the namespace is `agent0-` prefixed".
- [x] **Resolved (Phase D impl):** `port-frontmatter.sh` auto-proposes `compatibility:` text per detected tier (cc-native via body grep for `.claude/` paths; agentskills-portable otherwise) — no interactive prompt in v1; user reviews via `git diff` after port.
- [x] **Resolved (impl):** `/skill audit --all` does NOT enumerate CC-marketplace skills. They are surfaced by the CC harness, not via `.claude/skills/` files, so they have no on-disk SKILL.md to inspect. Audit footer notes the exclusion.
- [x] **Resolved (Phase C task #11):** `argument-hint:` stays **at top-level** of frontmatter — Claude Code reads it only there per official docs (https://code.claude.com/docs/en/skills.md). Porter does NOT migrate it. See `.claude/skills/skill/references/portability-tiers.md` § "On `argument-hint` placement".
- [ ] **Deferred:** spec-snapshot drift handling. Ship v1 with the 2026-05-17 snapshot; revisit if/when agentskills.io publishes a versioned spec with backwards-compat policy. Quarterly re-snapshot is recommended; defer to a REMINDERS.md item rather than blocking ship.

## Context / references

_Links to related specs, prior art, issues, docs, conversations._

- agentskills.io specification: https://agentskills.io/specification
- agentskills.io best practices: https://agentskills.io/skill-creation/best-practices
- agentskills.io quickstart: https://agentskills.io/skill-creation/quickstart
- `skills-ref` reference validator (Python, defer-to-canonical fallback): https://github.com/agentskills/agentskills/tree/main/skills-ref
- Hermes Agent (consumer runtime driving the urgency): https://hermes-agent.nousresearch.com
- `.claude/rules/spec-driven.md` — SDD shape this spec follows
- `.claude/rules/memory-placement.md` — buckets for any reference material this spec produces (e.g. spec-snapshot.md goes under skill `references/`, not `.claude/memory/`)
- `.claude/skills/{remind,sdd,brainstorm}/SKILL.md` — the 3 first-party skills audited; canonical port targets
- `.claude/REMINDERS.md` item #2 — blocks on this spec; publishing `packages/mcp-product-pipeline/` as a cross-runtime skill needs a known-good port path
- Prior research synthesis: conversation 2026-05-17 (Hermes Agent deep-research → Risk #1 → meta-skill design)
