# 185 — harness-evolution-program — notes

_Created 2026-06-09._

_In-flight design memory for this spec — decisions, deviations, tradeoffs, and open questions surfaced **while building** that weren't pre-empted by `spec.md` or `plan.md`. Append-only by convention. See `.agent0/context/rules/spec-driven.md` § The four artifacts for purpose, and `.agent0/context/rules/delegation.md` § The 5-field handoff for how sub-agents integrate._

**Entry shape:** `### YYYY-MM-DD — <author> — <one-line title>` followed by free-prose body. `<author>` is `parent` for the orchestrating agent, or the `subagent_type` (e.g. `general-purpose`, `Explore`) for delegated work.

**Routing rubric:** decision made under ambiguity → §1 Design decisions. Intentional departure from `plan.md` → §2 Deviations. Alternative weighed and chosen mid-flight → §3 Tradeoffs. Question surfaced during build, no answer yet → §4 Open questions. Sections may stay empty; the rubric is a guide, not a quota.

## Design decisions

_Choices made where the spec/plan was ambiguous. The decision itself + why this option over others considered in the moment._

### 2026-06-09 — parent — P7 (CI for harness tests) deferred by maintainer

Disposition given without a full detailing round: **deferred** — the project is not in production, so the cost of a missed regression is low enough that ad-hoc suite runs (agents run affected suites per session, as dogfooded) are acceptable for now. Not a kill: the underlying fact stands (~360 tests / 44 suites, no CI workflow beyond site deploy, no global runner), and the deferral implicitly assumes someone keeps running suites manually. Reopen triggers: the project enters production use, a consumer beyond the maintainer's own adopts the harness, or a regression ships that an existing suite would have caught. Note the adjacency to P2 (lab-vs-asset): "not in production yet" is itself a data point for that decision round.

### 2026-06-09 — parent — P1 (evidence bundle as product) detailed, then deferred by maintainer

Disposition: **deferred** — maintainer: "no users yet; we'll think about it later." The full detailing analysis is preserved here so the round survives chat history (spec.md acceptance scenario 3).

**Problem (live-verified, worse than the original audit claim).** Harness evidence is scattered, keyless, and almost entirely *ephemeral*: `.agent0/.runtime-state/*` is gitignored (confirmed `git check-ignore`) — visual-contract `report.json`, claude-exec/codex-exec run `metadata.json` (the actual proof payloads) exist only on the producing machine. Both JSONL ledgers (`delegation-audit.jsonl` 777 rows incl. model/duration/edit_count; `secrets-audit.jsonl` 720 rows) are also untracked. Durable evidence today = `## Verification log` markdown blocks in spec notes.md (spec-verify) + prose claims in commits/handoff. No common key joins session_id / spec NNN / commit — "what evidence backs spec 182?" is mechanically unanswerable; HANDOFF.md cites a gitignored path as the spec-182 proof.

**Market window (researched 2026-06-09).** EU AI Act high-risk traceability enforcement 2026-08-02; in-toto/SLSA already used for AI-generation attestation (agent identity, model provenance, invocation params); NIST SSDF AI provenance guidance; enterprise procurement asking how AI-written code is attributed/logged/governed.

**Options weighed.** (A — recommended) per-spec bundle assembled at close time: `evidence-bundle.sh` hooked into the sdd-close/spec-verify seam harvests into `docs/specs/NNN/evidence/` a bundle.json (spec, commit range, verify commands+results, per-change agent/model from delegation-audit extract, artifact digests) + redacted payload copies; advisory-only when a shipped spec lacks a bundle. (B) per-commit ledger via Stop hook — too fine-grained, noisy, redaction-hard; later layer. (C) in-toto/DSSE attestation now — interoperable but heavy; treat as an *export target*: design bundle.json fields so an in-toto statement is derivable later. (D) kill + soften the "evidence harness" claim.

**Recommendation was:** A with C-compatible schema, advisory-only v1, effort M, new shipped surface (tool + rule). First child task would have been deciding the fate of the two gitignored ledgers + the redaction policy (transcript paths / sensitive content — reuse gitleaks/secrets-preflight patterns).

**Reopen triggers:** first external consumer/user; a compliance/procurement ask for provenance of agent-written code; OR the cheap subset becoming independently annoying (handoffs repeatedly citing machine-local paths that don't resolve — if that recurs, consider extracting just the durability slice: copy proof payloads into `docs/specs/NNN/evidence/` manually at close, no tooling).

**P2 adjacency:** second consecutive deferral whose rationale is "not in production / no users yet" (after P7). The maintainer is implicitly answering P2 (personal-lab posture for now) — the P2 round should make that explicit and harvest its implications for P3/P4/P6.

### 2026-06-09 — parent — P2 decided: lab + public showcase

Maintainer decision (explicit, via options round): **Agent0 is a personal lab optimized for one operator's throughput, with the public face (site/README/positioning-proof from the recent positioning reset) kept as a consultancy *showcase* — not an adoption funnel.** No adoption machinery (installer, quickstart, third-party stability commitments) gets built. The third option (pure lab — unpublish the showcase) was rejected: the showcase costs ~zero and serves the consultancy pitch as living proof of method.

**Reopen triggers:** first genuine external party asking to adopt the harness; a consultancy engagement that wants the harness deployed; a deliberate product decision.

**Implications harvested for the remaining rounds:**
- **P3 (multi-runtime posture):** strengthened but NOT automatic — in lab mode the consumer of Codex parity is the maintainer himself, who uses both runtimes daily (squad, meetings, debate protocols *require* a second model). P3's real question becomes: does cell-by-cell capability parity cost more than the dual-runtime workflow returns? The peer-deliberation lane is load-bearing regardless.
- **P4 (rules diet):** stands under either posture; justification shifts from "adopter compliance" to "agent compliance + single-maintainer upkeep cost".
- **P6 (kernel out of bash):** likely kill/hibernate under lab posture — bash works, one operator, test suites exist. To be confirmed in its own round.
- Consistent with the P7/P1 deferrals (both rationale'd "no production / no users").

## Deviations

_Places where implementation intentionally departed from `plan.md`. The departure + the reason it was necessary or better._

## Tradeoffs

_Alternatives weighed during implementation (not at plan time). The chosen path + what was given up + why the tradeoff was worth it._

## Open questions

_Questions surfaced during build that the implementer couldn't resolve alone. Owner (who decides) or path to resolution if known. Promote answered questions to `spec.md` § Open questions or as retroactive acceptance scenarios when the spec is updated._
