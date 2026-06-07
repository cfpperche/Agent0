# {{NNN}} — {{SLUG}} — notes

_Created {{DATE}}._

_In-flight design memory for this spec — decisions, deviations, tradeoffs, and open questions surfaced **while building** that weren't pre-empted by `spec.md` or `plan.md`. Append-only by convention. See `.agent0/context/rules/spec-driven.md` § The four artifacts for purpose, and `.agent0/context/rules/delegation.md` § The 5-field handoff for how sub-agents integrate._

**Entry shape:** `### YYYY-MM-DD — <author> — <one-line title>` followed by free-prose body. `<author>` is `parent` for the orchestrating agent, or the `subagent_type` (e.g. `general-purpose`, `Explore`) for delegated work.

**Routing rubric:** decision made under ambiguity → §1 Design decisions. Intentional departure from `plan.md` → §2 Deviations. Alternative weighed and chosen mid-flight → §3 Tradeoffs. Question surfaced during build, no answer yet → §4 Open questions. Sections may stay empty; the rubric is a guide, not a quota.

## Design decisions

_Choices made where the spec/plan was ambiguous. The decision itself + why this option over others considered in the moment._

### 2026-05-30 — parent — Feasibility verified against CC docs: options (a) and (b) are dead, only (c) survives

Ran the load-bearing feasibility check (spec.md § Open questions Q1) against the official Claude Code hooks docs (`https://code.claude.com/docs/en/hooks`, cross-checked with verbatim field-table quotes). Findings:

- **`additionalContext`** (verbatim): "Claude Code wraps the string in a system reminder and inserts it into the conversation at the point where the hook fired. Claude reads the reminder on the next model request, but it does not appear as a chat message in the interface." → There is **no field to control formatting/newlines/display** of `additionalContext`.
- **No model-only/display-only toggle** for `SessionStart` / `UserPromptSubmit`. The display-only mechanism (`displayContent`, "Display-only: the transcript and what Claude sees keep the original") exists **only for the `MessageDisplay` event**, not for our two events.
- **`suppressOutput`** ("If `true`, hides the hook's stdout from the transcript") affects **stdout only**, not `additionalContext` — and our `emit_context()` already routes through `additionalContext` for CC.

**Decision:** the three-option space in spec.md § Intent collapses. Option (a) "preserve newlines in the human view" and option (b) "hide the block from the human while keeping the model channel" are both **infeasible** — CC exposes no supported lever. Only option (c) "reduce/restructure the emitted text so it survives flattening" remains, because that is pure string content in our own scripts (`startup-brief.sh` / `context-inject.sh`) with zero dependency on a CC rendering API.

**Why not resolve to `abandoned` (Ramo B):** the flatten damage is real and (c) is a genuine, propagatable fix — the handoff block's three nesting levels (`=== section ===` → `- Heading:` → `  - content`) collapse into one indistinguishable line when the renderer drops newlines. A flatten-safe inline hierarchy marker reconstructs the levels on a single physical line. This is small but not theater. Proportionality is acknowledged honestly: the current output is already partly flatten-tolerant (top-level `=== x ===` markers and per-capsule `---` survive); the delivered change is the marginal hierarchy-marker improvement, not a rewrite.

**Method caveat (carried to acceptance scenario 5):** docs say `additionalContext` "does not appear as a chat message," yet the founder *sees* a flattened "hook context" block — reconciled as a dimmed system-reminder block, not a chat message. This is only fully confirmable by live dogfood, so the dogfood artifacts (CC + Codex) remain a required acceptance gate; docs alone do not close it.

### 2026-05-30 — parent — Test-pinned strings constrain the marker design

`.agent0/tests/context-injection/09-startup-brief-budget.sh` greps `=== handoff ===` and `=== context ===` verbatim; the capsule tests pin `^source:`, `mode: prompt-capsules`, and `capsule: Read this file before acting`. Scenario 3 requires these suites pass **unchanged**. Decision: the flatten-safe marker is **additive** — keep every pinned substring intact, introduce a new inline marker (`▸`) only on the unpinned sub-structure boundaries (handoff sub-section headers; capsule separator alongside the retained `---`). No existing test string is touched.

## Live dogfood prompts (acceptance scenario 5 — manual gate)

_Implementation + automated verification are green (tasks 1–7). Scenario 5 is the human-run gate: a real session in each runtime confirming the `▸` markers actually survive the live renderer and that Codex consumption does not regress. Paste each prompt verbatim into a **fresh** session of that runtime, then attach the artifact to this spec._

### Claude Code — fresh session (captures scenario 5a)

> I just shipped spec 125 (`docs/specs/125-hook-context-visual-polish/`), which adds flatten-safe `▸` markers to the SessionStart startup brief and the per-turn context capsules. This is a fresh session, so the `SessionStart` hook already fired above. Do three things:
> 1. Look at the injected **hook context / startup brief** block as it renders in *this terminal UI* (not the raw file). Tell me whether the three handoff sub-sections — `▸ Current State:`, `▸ Active Work:`, `▸ Next Actions:` — are visually distinguishable from the `-` content bullets **even where the UI collapses newlines into long lines**. Quote how the flattened line actually looks.
> 2. Then send any prompt that selects a rule (e.g. ask me something about "sdd specs") and look at the `AGENT0_CONTEXT_INJECTION` capsule block: confirm each capsule is separated by a `▸ ---` boundary and that you can count the capsules on a flattened line.
> 3. Verdict: does the `▸` marker render as a clear glyph (not tofu/`□`) and does it improve scannability vs. plain `-`? If it renders as a box or doesn't help, say so plainly — that triggers the plan's ASCII-fallback (`>>`). Paste a screenshot or the literal rendered text back into the spec as the scenario-5a artifact.

### Codex CLI — fresh session (captures scenario 5b)

> I shipped spec 125 in Agent0; it changed two shared hooks (`.agent0/hooks/startup-brief.sh`, `.agent0/hooks/context-inject.sh`) to add `▸` markers. These hooks are runtime-neutral and you (Codex) consume their **raw stdout**. Verify there's no regression on the Codex path:
> 1. Run: `printf '{"hook_event_name":"SessionStart","source":"startup"}' | env -u CLAUDE_PROJECT_DIR AGENT0_PROJECT_DIR="$PWD" bash .agent0/hooks/startup-brief.sh`
> 2. Confirm the output is **plain text with no JSON envelope** (no `hookSpecificOutput` / `additionalContext` wrapper), that it stays under the 6000-byte / 80-line budget, and that the `▸ Current State:` / `▸ Active Work:` / `▸ Next Actions:` markers appear and read cleanly in the Codex TUI.
> 3. Run a prompt-capsule emit: `printf '{"hook_event_name":"UserPromptSubmit","prompt":"seguir sdd em docs/specs"}' | env -u CLAUDE_PROJECT_DIR AGENT0_PROJECT_DIR="$PWD" bash .agent0/hooks/context-inject.sh` and confirm each capsule carries a `▸ ---` boundary and a `^source:` line, still machine-parseable.
> 4. Verdict: is the Codex startup/prompt context as consumable and readable as before the change? Paste the output back as the scenario-5b artifact. If the glyph degrades the Codex TUI, flag it — same ASCII-fallback path.

## Dogfood artifacts (scenario 5)

### 2026-05-30 — parent (Claude Code, fresh session) — scenario 5a artifact

Live CC dogfood run. The `SessionStart` brief + a 5-rule `UserPromptSubmit` capsule block both fired this session and were read as rendered (not the raw file).

**Startup brief handoff — flattened line as received** (newlines → spaces):

> `▸ Current State: - **Spec 125 — ...** - Full SDD ran this session ... ▸ Active Work: - **Spec 125 dogfood gate ...** -  `docs/specs/125-*/notes.md` ... ▸ Next Actions: - 1. **Close spec 125:** ... - (hooks + test 12 ...).`

Finding: the 3 handoff sub-sections stay distinguishable on a flattened line — each section head is the only token prefixed `▸ `, every content line is prefixed `- `. The `▸` recovers the middle hierarchy level that flattening previously destroyed. Caveat: `▸` is a *small* triangle — a real but discreet landmark, weaker than the top-level `=== handoff ===` markers.

**Capsule block** — `selected: spec-driven delegation session-handoff artifact-budgets runtime-capabilities` (5 rules). Counted exactly **5** `▸ ---` boundaries on the flattened line, one per capsule; each retains its pinned `^source:` line. Capsules are countable and separable. ✅

**Glyph verdict + epistemic boundary (honest):**
- Verified at the byte layer: marker is `U+25B8` (`e2 96 b8`, Geometric Shapes block) — wide-support, arrives as a clean triangle in the model text stream, **no** substitution char.
- Structural scannability vs plain `-`: improved (recovers lost hierarchy). Recommendation from the model side: **do NOT trigger the `>>` ASCII fallback.**
- **Not confirmable by the model:** whether `▸` renders as a crisp glyph vs tofu/`□` is a font-rendering artifact at the human's terminal glass, which the agent does not observe (it only sees the codepoint). The at-glass tofu confirmation remains the human's to add to this artifact. _[human glass-check: ✅ CONFIRMED 2026-05-30 — founder reports `▸` renders as a crisp triangle, not tofu/□. No ASCII `>>` fallback needed.]_

### 2026-05-30 — Codex CLI (fresh session) — scenario 5b artifact

Live Codex probe run from `/home/goat/Agent0` with `CLAUDE_PROJECT_DIR` unset and `AGENT0_PROJECT_DIR="$PWD"`.

Startup probe validation: raw stdout/plain text, no `hookSpecificOutput` or `additionalContext` wrapper; 2292 bytes; 30 displayed lines (29 newline characters; no final newline); all three handoff markers found. The `▸` marker rendered as a normal glyph in the Codex output, not tofu.

```text
AGENT0_STARTUP_BRIEF
event: SessionStart
mode: summary
budget: 6000 bytes / 80 lines by default

=== handoff ===
▸ Current State:
  - **Spec 125 — hook-context-visual-polish is implemented + locally green; awaiting the manual dogfood gate.**
  - Full SDD ran this session (spec → debate w/ Codex `converged` → notes → plan → tasks). CC-docs feasibility
▸ Active Work:
  - **Spec 125 dogfood gate (task 8 / scenario 5) — only remaining step.** Paste-ready CC + Codex prompts in
  -   `docs/specs/125-*/notes.md` § Live dogfood prompts. Run both in fresh sessions, attach 5a/5b artifacts; on
▸ Next Actions:
  - 1. **Close spec 125:** run the two dogfood prompts, attach artifacts, flip status to shipped, commit
  -    (hooks + test 12 + `docs/specs/125-*`). Watch the `▸`-tofu fallback.
Full handoff: .agent0/HANDOFF.md

=== reminders ===
- [r-2026-05-14-fair-od-re-match-spec] Fair OD re-match for spec 027 — the blind-judge result (3.87 vs 4.73) is confounded (1 OD pass vs 4 refined iterations). To measure 027 honestly: either iterate the OD run to 4 pass...
- [r-2026-05-18-test-first-real-od-bump] Test the first real OD --bump/--apply against upstream — network-bound write-paths still untested. --check is empirically verified at the new skill location (2026-05-18 ran cleanl...
- [r-2026-05-17-full-23-route-prototype] Full 23-route `/prototype` dogfood — 2026-05-17 sandbox shipped spec 034 with typecheck+lint gate empirically verified on 2-stack scaffolds + 2 dispatched screens (Next.js linear-...
- [r-2026-05-19-discutir-expansao-full] Discutir expansão full-stack do /product (3 caminhos: A. /sdd new faz promoção como hoje; B. --scope=fullstack estende /product pra ~17 steps com BE+DB+api-contract; C. nova skill ...
- [r-2026-05-30-run-vuln-audit-once-against] Run vuln-audit once against a real project with the real osv-scanner binary (network-bound) to confirm the JSON parse matches live V2 output — spec 120 CI uses an offline fake...
... 1 more reminder(s); run /remind list for the full list.


=== context ===
Rules live in .agent0/context/rules/. Prompt turns receive bounded capsules from context-inject.sh.
For full inventory: AGENT0_CONTEXT_DIAGNOSTIC=1 bash .agent0/hooks/context-inject.sh <payload.json
END_AGENT0_STARTUP_BRIEF
```

Prompt-capsule probe validation: raw stdout/plain text, no `hookSpecificOutput` or `additionalContext` wrapper; 589 bytes; 14 displayed lines (13 newline characters; no final newline); one `▸ ---` boundary and one first-column `source:` line. The capsule remains machine-parseable.

```text
AGENT0_CONTEXT_INJECTION
event: UserPromptSubmit
mode: prompt-capsules
source_dir: .agent0/context/rules
selected: spec-driven
limits: max_fragments=5 max_bytes=6000

Instruction: These trusted repo-controlled capsules are routing hints. Read the named file before relying on omitted details; do not infer the full contract from this block.

▸ ---
source: .agent0/context/rules/spec-driven.md
title: Spec-driven development
capsule: Read this file before acting if the task depends on this Agent0 capacity. This capsule is a pointer, not the full rule body.
END_AGENT0_CONTEXT_INJECTION
```

Verdict: Codex startup/prompt context remains as consumable and readable as before the change. The `▸` marker did not degrade the Codex output in this run, so the Codex path does not indicate the ASCII fallback.

### 2026-05-30 — parent — scenario 5b artifact (Codex raw-stdout path)

Captured by the CC parent running the two runtime-neutral probes directly (the hooks are runtime-neutral; Codex consumes raw stdout, which is deterministic regardless of invoker). Honest scope: this verifies the **byte-level Codex contract**; the *Codex TUI readability* glass-check remains Codex's to confirm at its own glass, mirroring 5a's tofu.

**Probe 1 — `startup-brief.sh`:**
- No JSON envelope: `grep -c 'hookSpecificOutput\|additionalContext'` → **0** (plain text, no CC wrapper). ✅
- Budget: **2293 bytes / 30 lines** — under the 6000-byte / 80-line cap. ✅
- Markers: **3** `^▸ ` handoff sub-section heads present (`▸ Current State:` / `▸ Active Work:` / `▸ Next Actions:`). ✅

**Probe 2 — `context-inject.sh`** (`prompt: "seguir sdd em docs/specs"` → `selected: spec-driven`):
- One capsule, carrying its `▸ ---` boundary immediately followed by the pinned `source: .agent0/context/rules/spec-driven.md` line — still machine-parseable. ✅

Conclusion: Codex path does not regress — same plain-text envelope, within budget, markers additive over the pinned strings.

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

### {{YYYY-MM-DD}} — {{author}} — {{one-line title}}

{{free-prose body — the question, why it surfaced, what's blocked on it, who can decide}}
