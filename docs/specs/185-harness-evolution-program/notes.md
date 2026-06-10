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

### 2026-06-09 — parent — P3 (multi-runtime posture) detailed for the Codex-only scope, then deferred by maintainer

Disposition: **deferred — "leave as is."** Symmetric-parity doctrine stands unchanged. Before deferral the maintainer narrowed scope: third runtime discarded for now; the `terceiro-runtime-modelos-chineses` meeting was deleted; only the Codex re-tier was elaborated. Analysis preserved below.

**The proposal (not adopted):** re-tier Codex from co-equal first-class runtime to **deliberation peer + bounded executor** — keep meeting/debate/squad/codex-exec lanes (the second model is load-bearing for the anti-bias protocols), freeze existing ports (`.codex/hooks.json`, config example, symlinked skills — working surface stays, zero teardown), and drop the commitment that every NEW capacity ships with Codex parity (new capacities Claude-first; Codex ports on rule-of-three demand).

**Evidence of the recurring cost:** specs 181/184 are the same feature built twice (claude-exec/codex-exec run bounds); every new hook requires a `.codex/hooks.json` port; new skills carry implicit runtime-agnostic pressure; the weekly platform-audit routine audits two platforms + cell-by-cell matrix upkeep; meanwhile the most important gate (delegation) is already convention-only on Codex — symmetry is partly fiction today.

**Files-to-touch list (if ever adopted — effort S/M, ~1 session):** runtime-capabilities.md (posture preamble, no new vocabulary so drift-checker/test suites stay green; drop the "Re-audit pending" footnote), agent0-governance-doctrine.md (transversal constraint reword → portable core + reference runtime; admission-checklist runtime question gets a Claude-first default), CLAUDE.md+AGENTS.md managed block (byte-identical), routines/runtime-platform-audit.md (descope to existing-Codex-surface auditing), skill portability-tiers reference (cc-native acceptable default), runtime-capabilities-maintenance memory. Untouched: meeting/squad rules, exec skills+tests, all existing Codex surface and multi-runtime suites.

**Risk noted for the status quo:** frozen-or-not, Codex hooks rot silently when Codex CLI changes payloads (the apply_patch matcher case); the platform-audit routine is the existing mitigation.

**Reopen triggers:** the 181/184 double-build pattern recurring on the next capacity; a Codex CLI breaking change forcing a re-port investment decision; or the third-runtime question returning (this analysis reprices that decision too — peers/providers are cheap, parity runtimes are expensive).

### 2026-06-09 — parent — P4 adopted as discipline (B+C), big-bang diet withdrawn

Disposition: **adopted, no child spec.** The original pitch (numeric target, ≤20 rules / ≤8 KB, big-bang restructure) was withdrawn during the round as over-engineering under the P2 lab posture (sync churn on 3 consumers + test/drift rework for marginal single-operator payoff). Adopted instead: (B1) register split applied on touch — operative instruction stays in rules, design memory moves out in passing; (B2) admission bar — new rule only if mechanism-backed or demand-backed; (C) prose→mechanism promotion when an advisory empirically fires, generalizing the propagation-advisory promotion policy. Recorded as maintainer memory `.agent0/memory/rule-corpus-discipline.md` (propagation-hygiene precedent: binds the maintainer, doesn't ship).

**Amendment (same day, maintainer sharpening):** the maintainer upgraded B2 to an **audience test as the primary criterion** — "consumer-facing → rule; otherwise → memory or gate; we don't ship rules that aren't consumer-facing" — and added `propagation-advisory.md` to the move list (it documented a maintainer-only, sync-excluded mechanism). **Executed immediately:** 3 rules moved to memory (`agent0-governance-doctrine`, `scope-admission-governance`, `propagation-advisory` — corpus 39→36), CLAUDE.md/AGENTS.md doctrine section removed from the managed block, cross-refs dropped from spec-driven/post-launch-maintenance-loop, memory-placement split-precedent re-pointed at runtime-capabilities, the rule's `COPY_CHECK_EXCLUDE` entry deleted from sync-harness.sh (one less special case), dead skip-line removed from propagation-advise.sh. Validation: drift-check exit 0, propagation-advisory + harness-sync (47) + instruction-drift + project-memory suites all green, doctor 24/24. Consumer residue (stale CLAUDE.md section + stale rule copies on the 3 consumers) to be cleaned manually on the next sync visit.

Candidate audit answering "which rules should become maintainer memory": **move-whole** = `agent0-governance-doctrine.md` + `scope-admission-governance.md` (maintainer-only, no hook wiring — verified governance-gate.sh is unrelated; move is a small coordinated change incl. CLAUDE.md/AGENTS.md sections + consumer residue, execute on request/next touch). **Register-split on next touch** = harness-sync, delegation, memory-placement, secrets-scan. **Verified NOT candidates** = post-launch-maintenance-loop and php-laravel-support (consumer-facing), propagation-advisory (already sync-excluded), runtime-capabilities (maintainer register already split into memory). Review trigger: corpus >45 rules or >450 KB ≈ 2026-12 → numeric diet returns with evidence.

### 2026-06-09 — parent — P5 killed by measurement (hook-chain latency is a non-problem)

Disposition: **killed.** The audit hypothesis ("5 PostToolUse + 4 PreToolUse bash spawns per tool call, never measured, consolidate if >~150 ms") was falsified by direct measurement. Method: each wired hook executed 20× with realistic JSON payloads on stdin (`CLAUDE_PROJECT_DIR` set, minimal env), wall-clock p50/p95 via `time.perf_counter()`.

Numbers (p50): governance-gate 4.1 ms, secrets-preflight 3.4 ms (same on commit-shaped commands — the real gitleaks scan lives in the native pre-commit, not the preflight), memory-index-gate 4.8 ms, session-track-edits 3.3 ms, **project-core-sync 28.1 ms (the only outlier)**, memory-frontmatter-validate 3.3 ms, memory-events-journal 3.3 ms, propagation-advise 3.2–3.3 ms (non-shipped fast-exit and shipped-content scan virtually identical), delegation-gate 4.8 ms. **Per-Bash-call chain: ~7 ms sequential / 4 ms parallel. Per-Edit chain: ~46 ms sequential / 28 ms parallel.** A 100-edit session pays ≤5 s total, spread out.

A dispatcher consolidation would save ~18 ms/edit at real complexity cost — speculative optimization, rejected. Even the lone outlier (project-core-sync running `--apply` on every edit) is fine at 28 ms.

**Reopen trigger:** a future hook doing real work per edit (e.g. a project-wide validator returning to per-edit), or any measured chain exceeding ~150 ms p50.

### 2026-06-09 — parent — P6 killed; P7 reopened and executed (operator-quality principle)

The maintainer articulated a principle that re-sorted the two remaining quality-adjacent points: **"personal/professional use doesn't mean the project shouldn't be optimized, easy, and working perfectly."** Quality investments that serve the *operator* stand on their own; only investments whose value scales with *other users* fall to the lab posture.

**P6 (kernel out of bash) → killed.** A Go/Rust rewrite buys installability/portability for strangers — it would leave the harness functionally identical for the operator while spending XL effort and risk. Operator-grade quality is delivered by the test corpus + CI instead. No dedicated reopen trigger: a P2 posture flip re-tables it naturally (carrying it as deferred would duplicate the P2 trigger).

**P7 (CI) → deferral overturned, executed same session.** By the operator-quality principle, tests that only run when someone remembers don't meet the "working perfectly" bar — CI is regression insurance *for the operator*. Shipped: `.agent0/tests/run-all-suites.sh` (global orchestrator: discovers every suite run-all.sh, per-suite PASS/FAIL/SKIP table, failing-suite output tail, `AGENT0_SUITE_SKIP` env for environment-bound suites) + `.github/workflows/harness-tests.yml` (push/PR on harness paths + manual dispatch; installs gitleaks; suites are otherwise hermetic — verified: exec-skill suites use PATH-prefixed mock CLIs, agent-browser uses `AGENT0_BROWSER_BIN` fakes, 43 fixtures set their own git identity). **First full local sweep: 42/43 suites passed (~6 min) and the one failure was a live catch** — `post-launch-maintenance-loop/01` still asserted the doctrine rule file that moved to memory hours earlier; test repointed at the new home. Exactly the regression class CI exists for.

**First CI run (red) caught three more real environment couplings the dev machine masked, all fixed:** (1) post-launch tests shelled out to `rg` — absent on runners, replaced with POSIX `grep -qF`/`grep -nE`; (2) `agent-browser/07-adopt-detect` faked the CDP endpoint but still needed the real binary for the wrapper's fail-closed route — given the same skip-guard as the live scenarios; (3) runner shellcheck (absent locally) flagged vestigial `override_present` in `delegation-gate.sh` — removed. **Second CI run green in 3m02s** (run 27280730691). Net: the operator-quality principle paid for itself within the hour — four real defects surfaced by making the tests run automatically.

### 2026-06-10 — parent — P8 admitted minimal + executed; program complete

Disposition: **admitted (minimal form) and executed.** Under the lab posture the adversarial threat model is thin (distributor and consumer are the same person), but the maintainer's operator-quality principle plus the corruption/accident case justified the cheapest defensible slice. Key design find: **the integrity data already existed** — sync writes `.agent0/harness-sync-baseline.json` (`.files` = relpath→sha256) into every consumer. So P8 became a doctor section, not a new manifest mechanism: `=== shipped integrity ===` verifies the executable shipped surface (`.agent0/hooks/*.sh`, `.agent0/tools/*`, `.agent0/validators/*`, `.claude/hooks/*.sh`, `.githooks/*`) against the baseline. Mismatch/missing = **advisory** ("customized or tampered — run sync-harness --check"), never broken (divergence can be legitimate customization); no baseline (source repo / pre-first-sync) = ok/n-a. The spec.md open question "does P1's bundle subsume P8" resolved: no — standalone baseline-backed check, no bundle format needed.

Validation (per maintainer directive "não entregar sem validação"): new suite `.agent0/tests/shipped-integrity/` (5 scenarios: intact-ok, tamper-advisory, missing-advisory, no-baseline-n/a, non-executable-surface-ignored; hermetic sandboxes, doctor exercised via `AGENT0_PROJECT_DIR`); full corpus 44/44 local; doctor on Agent0 25 ok / 0 advisory / 0 broken; **harness-tests CI green** (run 27281953335).

**Program tally (all 8 dispositioned):** executed = P4 (discipline + 3-rule relocation), P7 (CI, reopened by operator-quality principle), P8 (doctor integrity); decided = P2 (lab + showcase); killed = P5 (by measurement), P6 (operator-quality served by tests+CI); deferred = P1 (no users yet), P3 (parity doctrine stands).

## Deviations

_Places where implementation intentionally departed from `plan.md`. The departure + the reason it was necessary or better._

## Tradeoffs

_Alternatives weighed during implementation (not at plan time). The chosen path + what was given up + why the tradeoff was worth it._

## Open questions

_Questions surfaced during build that the implementer couldn't resolve alone. Owner (who decides) or path to resolution if known. Promote answered questions to `spec.md` § Open questions or as retroactive acceptance scenarios when the spec is updated._
