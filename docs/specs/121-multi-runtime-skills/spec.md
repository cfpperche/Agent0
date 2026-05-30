# 121 — multi-runtime-skills

_Created 2026-05-30._

**Status:** shipped

## Intent

Make Agent0's skills consumable by Codex CLI — and future agentskills.io-compatible runtimes —
migrated **one skill at a time**, like the 102→119 hook arc. We pivoted here from the rules surface:
Codex's instruction surface (AGENTS.md) has no `@import` and a 32 KiB cap, making neutral rule bodies
awkward — but **skills have a clean, standards-based path**, confirmed empirically in the cross-model
debate (`debate.md`, converged).

**The model (decided in debate).** A skill body is a runtime-neutral harness surface, so the
**canonical source moves to `.agent0/skills/<slug>/`**. Each runtime then receives a **native
discovery symlink only** — never a copy, never cross-reading another runtime's private home:

```
.agent0/skills/<slug>/SKILL.md        ← canonical source (single source of truth)
.claude/skills/<slug>  → ../../.agent0/skills/<slug>   (Claude discovery symlink)
.agents/skills/<slug>  → ../../.agent0/skills/<slug>   (Codex discovery symlink)
```

This is the `harness-home.md` principle applied to skills: **location neutral, registration
per-runtime** — the same shape the hook arc used. Both runtimes were proven to follow the symlink and
read the one physical `SKILL.md` (see § Context / local proof). Use `.agents/skills` as the Codex repo
discovery path (the official documented one); do **not** use `.codex/skills` for Agent0's primary
repo-level contract unless a future spec deliberately adopts it.

**The portability contract.** A skill may live in `.agent0/skills/` (with both symlinks) only if its
body avoids Claude-only primitives or documents their degradation: deterministic work routes through
neutral `.agent0/tools/*`; bundled resources resolve **relative to the SKILL.md path**, NOT via
`${CLAUDE_SKILL_DIR}` (which has no Codex equivalent — `skill_env_var_dependency_prompt` is removed in
Codex); `AskUserQuestion` interactive gates have no general Codex primitive (only Plan-mode
`request_user_input`), so skills depending on them stay `cc-native` (Claude-only, no `.agents/` symlink)
unless they degrade to plain-prose questions. The `Skill`-tool invocation model is Claude-specific;
Codex injects the discovered skill list and reads `SKILL.md` on trigger. The existing
`portability-tiers` framework (`cc-native` / `agentskills-portable` / `runtime-agnostic`) is the
classification gate.

The vuln-audit skill (spec 120) is the pilot: it already delegates to a neutral `.agent0/tools/vuln-audit.sh`,
so it is nearly portable already — it only needs relocation + symlinks + a `${CLAUDE_SKILL_DIR}` check.

## Acceptance criteria

- [x] **Scenario: canonical-source + symlink model is established and documented**
  - **Given** Claude discovers `.claude/skills/` and Codex discovers `.agents/skills/`
  - **When** the model is implemented
  - **Then** the canonical skill source lives at `.agent0/skills/<slug>/`, with `.claude/skills/<slug>` and `.agents/skills/<slug>` as relative discovery symlinks into it, documented in `.claude/rules/harness-sync.md` + `.claude/rules/runtime-capabilities.md`, with a duplicate-name rule (a skill is exposed through exactly **one** Codex repo discovery path — `.agents/skills` — never also `.codex/skills`, unless collision behavior is explicitly tested)

- [x] **Scenario: the pilot skill is discoverable + invocable in both runtimes**
  - **Given** the model and the `vuln-audit` pilot relocated to `.agent0/skills/vuln-audit/` with both symlinks
  - **When** each runtime starts in the repo
  - **Then** Claude discovers it via `.claude/skills/` (symlink) and invokes via the `Skill` tool / `/vuln-audit`; Codex discovers it via `.agents/skills/` (verified by `codex debug prompt-input` listing the path) and invokes explicitly via `$vuln-audit` or `/skills`; both resolve to the one physical `.agent0/skills/vuln-audit/SKILL.md`. Implicit Codex invocation is a **separate** check, gated by `agents/openai.yaml` `policy.allow_implicit_invocation` + description specificity — not assumed from discovery

- [x] **Scenario: a per-skill migration runbook exists**
  - **Given** the model
  - **When** a maintainer ports the next skill
  - **Then** a documented checklist names: classify tier → move source to `.agent0/skills/<slug>` → create both relative symlinks → neutralize CC-only primitives (`${CLAUDE_SKILL_DIR}`, `AskUserQuestion`, `Skill`-tool) or document the `cc-native` classification → add `agents/openai.yaml` only when Codex policy/UI/MCP-deps are needed → verify discovery + invocation in both runtimes

- [x] **Scenario: sync-harness propagates the model without breaking on symlink-hostile checkouts**
  - **Given** a consumer project running `.agent0/tools/sync-harness.sh`
  - **When** sync runs
  - **Then** the canonical `.agent0/skills/<slug>` source propagates AND the consumer ends with working discovery links for both runtimes — and on a symlink-hostile checkout (Windows without `core.symlinks`, or `git config core.symlinks false`) sync **detects** the condition and falls back to a documented copy-materialization (or emits a clear advisory), never silently leaving a text-file-stub where a symlink was expected

- [x] Each `cc-native` primitive (`${CLAUDE_SKILL_DIR}`, `AskUserQuestion`, `Skill`-tool) is treated as a hard portability check in the runbook — a skill moves to `.agent0/skills` only if it avoids them, routes through `.agent0/tools/*`, or carries a documented degradation/tier classification.

- [x] `.claude/rules/runtime-capabilities.md` carries a specific **skills** capability row (Claude native via `.claude/skills`, Codex native via `.agents/skills`, Agent0 shared-source convention `.agent0/skills` + discovery symlinks) — added BEFORE any broad row (`SDD`, `image generation`) is promoted on skill-format grounds.

## Non-goals

- **Porting every skill in this spec.** This settles the model + runbook and ports ONE pilot (`vuln-audit`). The rest are one-by-one follow-ups.
- **Rewriting skill behavior.** Migration is relocation + symlink + dependency-neutralization, not redesign.
- **Configuring Codex to read `.claude/skills` directly.** Codex does not scan `.claude/skills`; the accepted model is one canonical source + native discovery symlinks, NOT teaching one runtime another runtime's private home.
- **Copying skill bodies between runtime homes.** One physical source tree (`.agent0/skills/`) + symlinks; no duplicated `SKILL.md` files (that would drift).
- **Using `.codex/skills` for the primary contract.** `.agents/skills` is the official documented Codex repo path; `.codex/skills` is left to a deliberate future spec.
- **Porting irreducibly `cc-native` skills.** Skills fundamentally bound to `AskUserQuestion` flows (`/product`, `/sdd refine`) stay Claude-only; the tiers + runbook draw the line.
- **The rules surface.** Explicitly deferred (the pivot away from rules-first); revisit after skills.
- **A skill transpiler / codegen.** Runbook + symlink + minimal sync-harness handling, not a compiler.

## Open questions

_Most resolved in the debate (`debate.md`); the live ones are plan-time engineering._

- [x] **One file, two homes — RESOLVED.** Canonical `.agent0/skills/<slug>` source + relative discovery symlinks in `.claude/skills/<slug>` and `.agents/skills/<slug>`. Both runtimes proven to follow the symlink (§ Context / local proof). Codex follows symlinked skill dirs and canonicalizes to the neutral target; Claude discovers the linked skill.
- [x] **CC-primitive degradation — RESOLVED into the portability contract.** `${CLAUDE_SKILL_DIR}` → resolve relative to SKILL.md / use `.agent0/tools/`; `AskUserQuestion` → cc-native unless prose-degradable; `Skill`-tool → Codex injects discovered list. Hard checks in the runbook.
- [x] **Implicit-selection — RESOLVED.** Codex `policy.allow_implicit_invocation` defaults true; broad skills set it `false` in `agents/openai.yaml` or tighten `description`. Implicit invocation is tested separately from discovery.
- [ ] **Symlink portability on symlink-hostile checkouts (PLAN-TIME, elevated risk).** Git stores symlinks, but a Windows checkout without `core.symlinks` (or `core.symlinks=false`) materializes them as text-file stubs → discovery breaks. The sync-harness must detect this and fall back to copy-materialization or a loud advisory. This is the single real engineering risk; the plan must solve it, not defer it. Owner: plan.
- [ ] **sync-harness manifest coverage (PLAN-TIME).** The manifest knows `.claude/skills` recursively; it must now treat `.agent0/skills` as the source and (re)create the `.claude/skills` + `.agents/skills` discovery links on the consumer — including how it copies a symlink vs its target, and how the deletion pass handles a relocated skill. Owner: plan.
- [ ] **Tier target.** Is `agentskills-portable` the bar, or is `runtime-agnostic` (no-bash) needed for some? The vuln-audit tool is bash — fine for Codex-on-Linux, names the OS assumption.

## Context / references

### Official docs (source-of-truth claims)
- Codex skills are repo-discovered through **`.agents/skills`** (plus `$HOME/.agents/skills`, `$CODEX_HOME/skills`, `/etc/codex/skills`, system + plugin cache); `SKILL.md` + agentskills.io frontmatter (`name` + `description` required); optional `scripts/` `references/` `assets/` `agents/openai.yaml`; invocation `/skills` / `$mention` / implicit-by-description: https://developers.openai.com/codex/skills
- Claude project skills are discovered through `.claude/skills`. Cross-tool standard: https://agentskills.io / https://agents.md/

### Local runtime proof (this debate, 2026-05-30)
- A temp repo with `.agent0/skills/probe-shared/SKILL.md` symlinked into both `.agents/skills/probe-shared` and `.claude/skills/probe-shared` was discovered by BOTH runtimes: Codex `codex debug prompt-input` (codex-cli 0.135.0) listed `probe-shared` and canonicalized the path to `.agent0/skills/probe-shared/SKILL.md`; Claude Code 2.1.158 reported `AVAILABLE: probe-shared` with one project skill loaded from `.claude/skills`.
- Codex probe did **not** discover `.claude/skills/<skill>`. `${CLAUDE_SKILL_DIR}` has no Codex env equivalent (`skill_env_var_dependency_prompt` removed); `AskUserQuestion` ≈ Plan-mode `request_user_input` only; `agents/openai.yaml` optional for discovery but carries `policy.allow_implicit_invocation` (default true).

### Agent0 references
- `docs/specs/120-vuln-audit/` — the pilot's neutral-tool + thin-wrapper shape.
- `.claude/skills/skill/references/portability-tiers.md` — the classification gate; `references/spec-snapshot.md` — the agentskills.io frontmatter the `/skill` validator enforces.
- `.agent0/memory/harness-home.md` — the location-neutral / registration-per-runtime principle this extends; its deferred-skills disposition is updated by this spec.
- `.claude/rules/harness-sync.md` — the propagation mechanism the symlink model must work through.
- `.agent0/memory/feedback_verify_runtime_capabilities.md` — why the Codex mechanics were probed live (the corrections came from probing, not assuming).
- Removed `121-multi-runtime-rules` (2026-05-30): rules-first dropped — AGENTS.md has no `@import` + 32 KiB cap; skills have the cleaner standards path.
