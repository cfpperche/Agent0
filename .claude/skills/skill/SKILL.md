---
name: skill
description: Skill compliance toolkit. Use when scaffolding a new Agent0 skill, auditing existing skills against the agentskills.io specification, porting non-compliant SKILL.md frontmatter to compliance, validating a single SKILL.md, or listing all skills with their declared portability tier. Subcommands - new <slug> [--tier cc-native|agentskills-portable|runtime-agnostic], audit [<slug>|--all], port <slug>, validate <slug>, list. See `.claude/skills/skill/references/spec-snapshot.md` for the frozen spec and `.claude/skills/skill/references/portability-tiers.md` for the 3-tier definition.
license: MIT
compatibility: Designed for Claude Code. Body references `.claude/skills/` paths and bash scripts at `.claude/skills/skill/scripts/`; portable to any runtime that maps a `.claude/`-analog directory and runs bash 4+.
metadata:
  agent0-portability-tier: cc-native
  version: "0.1"
argument-hint: <new <slug> [--tier <tier>] | audit [<slug>|--all] | port <slug> | validate <slug> | list>
---

# /skill — skill compliance toolkit

Scaffolds new Agent0 skills, audits existing ones against the agentskills.io specification, ports non-compliant SKILL.md frontmatter to compliance, and validates individual SKILL.md files. Every Agent0 skill should pass `/skill validate <slug>` before being committed.

`references/spec-snapshot.md` for the frozen agentskills.io rules; `references/portability-tiers.md` for the 3-tier classification (`cc-native` / `agentskills-portable` / `runtime-agnostic`).

## Argument parsing

User invokes as `/skill <subcommand> [args]`. The raw argument string is `$ARGUMENTS`. Parse it yourself: split on whitespace, first token is the subcommand (`new` / `audit` / `port` / `validate` / `list`); the rest are subcommand args. Do not rely on `$1`/`$2` positional substitution — harness behavior differs between slash invocation and Skill tool invocation. Always parse `$ARGUMENTS`.

Raw invocation: `$ARGUMENTS`

State paths used throughout:
- Skill root: `.claude/skills/<slug>/` (resolved relative to `$CLAUDE_PROJECT_DIR` or repo root)
- Toolkit root: `${CLAUDE_SKILL_DIR}` (when invoked as `/skill`, this resolves to `.claude/skills/skill/`)
- Validator: `${CLAUDE_SKILL_DIR}/scripts/validate.sh`
- Porter: `${CLAUDE_SKILL_DIR}/scripts/port-frontmatter.sh`
- Templates: `${CLAUDE_SKILL_DIR}/templates/{SKILL.md,cc-native,portable}.tmpl`

## Subcommand: `new <slug> [--tier <tier>]` — 🔒 Low freedom: scaffold + validate sequence

Scaffold a new Agent0 skill with a spec-compliant SKILL.md. Parse `$ARGUMENTS`: first token must be `new`; second token is the slug; optional `--tier <tier>` selects the template variant (default `cc-native`).

1. **Validate the slug**:
   - Reject if missing, empty, or non-kebab-case (`^[a-z][a-z0-9]*(-[a-z0-9]+)*$`).
   - Reject if `.claude/skills/<slug>/` already exists.

2. **Select the template**:
   - `--tier cc-native` (default) → `templates/cc-native.tmpl`
   - `--tier agentskills-portable` → `templates/portable.tmpl`
   - `--tier runtime-agnostic` → `templates/portable.tmpl` (no separate template in v1; switch the `metadata.agent0-portability-tier` value to `runtime-agnostic` post-substitution and remind the user to verify OS-agnostic patterns in the body)
   - Any other value → refuse with the canonical list.

3. **Scaffold the directory and copy the template**:
   ```bash
   mkdir -p .claude/skills/<slug>
   cp ${CLAUDE_SKILL_DIR}/templates/<selected>.tmpl .claude/skills/<slug>/SKILL.md
   ```

4. **Substitute placeholders** in the new SKILL.md (literal replace):
   - `{{SLUG}}` → `<slug>`
   - `{{DATE}}` → current date in `YYYY-MM-DD` (UTC)
   - Other `{{...}}` placeholders (description, title, opening, subcommands) are left for the user to fill — the meta-skill provides structure, not content.

5. **Run validate immediately**:
   ```bash
   bash ${CLAUDE_SKILL_DIR}/scripts/validate.sh .claude/skills/<slug>
   ```
   If non-zero exit, surface stderr and stop with a hint: "scaffolder placeholder values may have been edited; fill `{{DESCRIPTION_PLACEHOLDER}}` and re-run validate".

6. **Report**: output the new SKILL.md path and tell the user to fill the `{{...}}` placeholders (description first — that's the discovery surface) and re-validate when done.

## Subcommand: `audit [<slug>|--all]` — 🔓 Medium freedom: per-skill reporting adapts to compliance state

Inspect skills against the spec and report compliance + tier.

**Target selection** (parse `$ARGUMENTS` after `audit`):
- `audit <slug>` → audit only `.claude/skills/<slug>/`
- `audit --all` (default if no arg) → audit every `.claude/skills/*/SKILL.md` found

**For each target**:
1. Run `bash ${CLAUDE_SKILL_DIR}/scripts/validate.sh .claude/skills/<slug>` and capture exit code + stderr (agentskills.io frontmatter compliance — upstream spec).
2. Run `bash ${CLAUDE_SKILL_DIR}/scripts/check-rubric.sh .claude/skills/<slug>` and capture stderr (Agent0 rubric body-shape advisories — repo-local). Always exit 0 — advisory only.
3. Read frontmatter to extract declared `metadata.agent0-portability-tier` (or `unknown` if not present).
4. Classify:
   - `✓ compliant` — validate.sh exit 0
   - `✗ non-compliant (ruleN-...)` — validate.sh exit non-0, list rule IDs from stderr
   - Capture rubric advisories separately (zero or more `skill-rubric-advisory:` lines from check-rubric.sh) — these never flip compliance, they surface as a footer block.
5. **Out of scope**: CC-marketplace skills surfaced via the Claude Code harness (e.g., `init`, `review`, `security-review`, `claude-api`, `simplify`, `fewer-permission-prompts`, `loop`, `schedule`, `update-config`, `keybindings-help`) do not have files under `.claude/skills/` in this repo — they are not enumerated. Note this in the report footer for clarity.

**Output shape**:
```
skill              tier                          status
-----              ----                          ------
brainstorm         cc-native                     ✓ compliant
remind             cc-native                     ✓ compliant
sdd                cc-native                     ✓ compliant
skill              cc-native                     ✓ compliant (meta)
<other>            <tier or unknown>             <status>

rubric advisories (Agent0 body-shape — non-blocking):
  <verbatim skill-rubric-advisory: lines from check-rubric.sh, or "(none)">

summary: N compliant, M non-compliant, K rubric advisories, audited from .claude/skills/
note: external CC-marketplace skills (init, review, ...) are surfaced by
      the CC harness, not by this repo's .claude/skills/; not audited here.
```

If any target is non-compliant, exit the subcommand with a one-line hint pointing at `/skill port <slug>` as the next step. Rubric advisories alone do NOT trigger this hint — they're advisory only; the corrective for rubric gaps is hand-editing the skill body per `.claude/skills/skill/references/skill-rubric.md`.

## Subcommand: `port <slug>` — 🔒 Low freedom: porter + validator + diff-stat sequence

Apply `port-frontmatter.sh` to bring a skill's frontmatter into spec compliance. Parse `$ARGUMENTS`: first token `port`, second token `<slug>`.

1. **Validate** — refuse if `.claude/skills/<slug>/SKILL.md` doesn't exist.

2. **Confirm with the user** — show what's about to change (a dry-run preview is the right shape but v1 is destructive; warn the user and ask `y/N` before running). Include the detected tier and the planned compatibility text in the prompt.

3. **Run the porter**:
   ```bash
   bash ${CLAUDE_SKILL_DIR}/scripts/port-frontmatter.sh .claude/skills/<slug>
   ```

4. **Validate the result**:
   ```bash
   bash ${CLAUDE_SKILL_DIR}/scripts/validate.sh .claude/skills/<slug>
   ```
   If validate still fails, surface stderr — the porter does NOT auto-fix every rule (e.g., `rule3-name-dirname-mismatch` requires an editorial decision: rename the file or rename the directory). Hand back to the user.

5. **Verify body bytes preserved**:
   ```bash
   git diff --stat .claude/skills/<slug>/SKILL.md
   ```
   The diff stat should show ONLY frontmatter line additions; if any line below the frontmatter changed, that's a porter bug and must be reported.

6. **Report**: echo the porter's output line (`ported: <path> (tier: <tier>)`) and the validation result. Suggest the user `git diff .claude/skills/<slug>/SKILL.md` to review before committing.

## Subcommand: `validate <slug>` — 🔒 Low freedom: defer to validator script

Wrap `validate.sh` for a single skill. Parse `$ARGUMENTS`: first token `validate`, second token `<slug>` (omit for the meta-skill itself, i.e., `skill`).

1. **Resolve**: `<slug>` → `.claude/skills/<slug>/`. Default to `skill` (self-validation) if no slug given.

2. **Run**:
   ```bash
   bash ${CLAUDE_SKILL_DIR}/scripts/validate.sh .claude/skills/<slug>
   ```

3. **Report**: echo "pass" on exit 0 (and any stderr soft-warnings), or "fail" with the stderr block on exit non-0. Exit code mirrors `validate.sh`.

## Subcommand: `list` — 🔒 Low freedom: scan + format

Enumerate every `.claude/skills/*/` directory with its declared tier and a compliance check at a glance.

1. **Scan**: `ls -d .claude/skills/*/` (alphabetical).

2. **For each**: read SKILL.md frontmatter, extract `name` and `metadata.agent0-portability-tier` (or fall back to "(unknown)" if absent), run validator silently to get pass/fail.

3. **Output one line per skill**:
   ```
   <name>             <tier>                        <✓|✗>
   ```

4. **Footer**: short summary line: `N skills, M compliant, K non-compliant`.

## Unknown subcommand

If the first token of `$ARGUMENTS` is missing or not one of `new`, `audit`, `port`, `validate`, `list`, refuse with a single-line usage hint:

```
/skill <new <slug> [--tier <tier>] | audit [<slug>|--all] | port <slug> | validate <slug> | list>
```

## Eval Scenarios

### Eval 1: Happy path — scaffold a new cc-native skill

**Input:** User says `/skill new my-toolkit` after working through a `/sdd` spec that calls for a new Claude-Code-specific helper.

**Expected:** `new` subcommand runs. Slug regex passes; no existing `.claude/skills/my-toolkit/` collision. Default tier `cc-native` selected. Template copied; `{{SLUG}}` and `{{DATE}}` substituted; other `{{...}}` placeholders left for the user. `validate.sh` runs immediately and exits non-zero (description placeholder still present); the surfaced stderr names the rule + asks the user to fill `{{DESCRIPTION_PLACEHOLDER}}` and re-validate. New SKILL.md path reported. No git auto-commit.

**Failure indicators:** Scaffolder runs without the immediate validate pass. `{{...}}` content placeholders auto-filled with invented content. Tier flag silently coerced to `cc-native` when an invalid tier was passed (should refuse with canonical list). Skill directory created when slug collides with existing dir.

### Eval 2: Audit-all across the project

**Input:** User says `/skill audit --all` mid-feature to confirm the skill bucket is healthy before shipping a new spec.

**Expected:** Every `.claude/skills/*/SKILL.md` enumerated alphabetically. Per-skill row shows name + declared tier + `✓ compliant` or `✗ non-compliant (ruleN-...)`. CC-marketplace skills (`init`, `review`, `security-review`, etc.) explicitly NOT enumerated (they live in the harness, not in `.claude/skills/`); footer note flags this exclusion. Rubric-advisory findings (from `check-rubric.sh` per Task 6 wiring) listed as a separate footer block under the table. Summary line reads `summary: N compliant, M non-compliant, K rubric advisories`.

**Failure indicators:** CC-marketplace skills mistakenly enumerated and flagged as non-compliant (they have no local files). Per-skill table missing the tier column. Rubric findings mixed into the compliance column instead of the footer block. Summary line missing the rubric-advisory count.

### Eval 3: Port a non-compliant skill

**Input:** User says `/skill port legacy-helper` after `audit --all` surfaced `rule4-description-missing` on the target.

**Expected:** Porter confirms with the user (dry-run preview + `y/N` prompt). `port-frontmatter.sh` runs; `validate.sh` re-runs against the modified file. Diff-stat verifies ONLY frontmatter line additions — zero body changes. Porter output line + validation result echoed. If `validate.sh` still fails post-port (e.g. `rule3-name-dirname-mismatch` needs editorial decision), surfaces stderr and hands back to the user. User pointed at `git diff` before committing.

**Failure indicators:** Porter runs without user confirmation. Body bytes changed (any line below the frontmatter mutates) → reported as porter bug. Validate skipped after port → user ships still-non-compliant frontmatter. Auto-commit by the porter.

## Notes

_Consumer-extension surface — append consumer-local bullets to this section. Sync flags the file as `!! customized` (sha-compare is section-blind), but the conflict region is mechanically this section: take new upstream verbatim, re-add consumer bullets at the end. See `.claude/rules/harness-sync.md` § Consumer-extension convention._

- **Defer to canonical when available.** `validate.sh` `exec`s `skills-ref validate` when that Python tool is on PATH. The bash rule set is the zero-dep fallback; `skills-ref` is the source of truth. If the two disagree, prefer `skills-ref` and re-snapshot `references/spec-snapshot.md`.
- **Spec drift.** `references/spec-snapshot.md` was retrieved on 2026-05-17. Re-check the live spec (https://agentskills.io/specification) periodically; when it evolves, re-snapshot and audit `scripts/validate.sh` against the diff. A `reminders.yaml` entry is the natural cadence reminder.
- **Body not validated.** This toolkit checks frontmatter compliance only. Body portability (e.g., declared `agentskills-portable` tier but body uses `${CLAUDE_SKILL_DIR}`) is operator-asserted; a future enhancement could grep for tier-inconsistent signals during `/skill audit`.
- **`argument-hint` stays top-level.** Per Phase C research, Claude Code reads this field only at the top of frontmatter. The porter does NOT migrate it under `metadata:` — see `references/portability-tiers.md` § "On `argument-hint` placement" for the evidence.
- **No git auto-commit.** All operations leave the working tree dirty for review. The user decides what enters history. Suggest `git diff` after `port` to verify body bytes are untouched.
