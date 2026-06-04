# {{NNN}} — {{SLUG}} — notes

_Created {{DATE}}._

_In-flight design memory for this spec — decisions, deviations, tradeoffs, and open questions surfaced **while building** that weren't pre-empted by `spec.md` or `plan.md`. Append-only by convention. See `.agent0/context/rules/spec-driven.md` § The four artifacts for purpose, and `.agent0/context/rules/delegation.md` § The 5-field handoff for how sub-agents integrate._

**Entry shape:** `### YYYY-MM-DD — <author> — <one-line title>` followed by free-prose body. `<author>` is `parent` for the orchestrating agent, or the `subagent_type` (e.g. `general-purpose`, `Explore`) for delegated work.

**Routing rubric:** decision made under ambiguity → §1 Design decisions. Intentional departure from `plan.md` → §2 Deviations. Alternative weighed and chosen mid-flight → §3 Tradeoffs. Question surfaced during build, no answer yet → §4 Open questions. Sections may stay empty; the rubric is a guide, not a quota.

## Design decisions

_Choices made where the spec/plan was ambiguous. The decision itself + why this option over others considered in the moment._

### 2026-06-04 — parent — commit stores the opening (orchestrator-sealed), not agent-resupply

The debate proposed `reveal --text-file --nonce` (agent re-supplies its opening + nonce at reveal, so even the orchestrator can't forge it). Implemented a simpler equivalent: `commit --text-file` **seals the opening** into a gitignored scratch + records its `sha256`; `reveal` reads the sealed copy, re-verifies the hash, publishes. Rationale: in Agent0's model the active runtime IS the trusted single-writer of the transcript, so orchestrator-sealing is adequate and removes a moving part (no nonce hand-off between commit and reveal). Blindness is therefore **procedural + tamper-evident**, not cryptographic against an adversarial peer — an honest scope statement (the goal is reducing bias between *cooperating* models, not defending against a malicious agent). Documented in `rules/meeting.md`.

### 2026-06-04 — parent — sealed state reuses `.agent0/.runtime-state/` (already gitignored)

Plan named `.agent0/.deliberation-state/`; used `.agent0/.runtime-state/deliberation/<key>/` instead — `.runtime-state/` is already gitignored, so no new `.gitignore` entry, and it's the established home for ephemeral per-session state. `<key>` = first 16 hex of `sha256(abs transcript path)`. Repo root resolved via `git -C <dir> rev-parse --show-toplevel`, falling back to `$CLAUDE_PROJECT_DIR` (tests set the latter to an isolated tmp).

### 2026-06-04 — parent — 149.1: two fast-follows surfaced + fixed by the spec-150 dogfood

The first real use of the protocol (the `/squad` design debate) surfaced two gaps, both now fixed + tested: (a) `/sdd debate`'s `debate.md` had no YAML front-matter, so `meeting.sh commit/reveal/ledger` couldn't run on it — added a `meeting.sh`-compatible front-matter block (`roster: claude,codex,human`, `tier: decision-grade`, `blind_phase`, …) to `debate.md.tmpl`, coexisting with the `**Initiating agent:**` human-readable block (tests: deliberation-bias/10). (b) A ledger claim containing a literal `|` corrupted the markdown-table column parse in `ledger-check`/`check-anchors` — `ledger-add` now sanitizes `|` → `/` (tests: deliberation-bias/11). The dogfood paid for itself: a tool tested in isolation (9/9) still had an integration gap that only real use exposed.

### 2026-06-04 — parent — mechanics in meeting.sh; debate reuses (no second engine)

Per the ratified plan: commit/reveal/ab-map/ledger/check-anchors/tier are `meeting.sh` subcommands; `/sdd debate` documents calling them rather than re-implementing in prose. `debate.md` sections (`## Blind submissions`, `## Claim/evidence ledger`) are CREATED by the subcommands on first use, so the debate template only carries a pointer + the minority-report slot. The blind Round 1 is the *preferred* path with the legacy position-first Round 1 retained as a documented fallback (so a runtime that can't run the script still works).

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
