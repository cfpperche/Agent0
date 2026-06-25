# Capability harvest — what built Tachyon, and where each piece goes

_Created 2026-06-25. Private technical migration record. Status: **draft → codex dueto folded (NEEDS-REVISION → revised below)**._

> **Why this doc exists.** Tachyon was built entirely inside sessions rooted at this Agent0 checkout: the Agent0 harness (SDD, second-model review, verify, secrets-scan, handoff, hygiene) was the invisible scaffolding. The goal now is to make **Tachyon self-hosting** — a session rooted at `/home/goat/tachyon` that builds Tachyon *with Tachyon*, with Agent0 fully out of the path so it never confuses a building agent. **Agent0 is discontinued once everything necessary is migrated.** This doc is the **map** that decision needs: which Agent0 capabilities were load-bearing for that construction, and the disposition of each.
>
> **The "decouple == harvest" thesis — and its limit.** The Tachyon repo contains *no* Agent0 artifacts (`.agent0/`, `.claude/`, `.codex/`, `.githooks/` all absent). Agent0 reaches Tachyon dev *only* because the session is rooted here. So removing Agent0 from the path is not a delete — it is giving Tachyon its **own** harness, which *is* the load-bearing capability set below. **BUT the dueto found the thesis is not free**: installing a Tachyon plugin while an Agent0-rooted session is still active can **double-fire** the same governance (two secrets-scans, two handoff writers). Decouple==harvest holds only under a **staged cutover invariant** (see § Cutover invariant). Treat it as a sequencing discipline, not an automatic identity.

## Methodology — mined, not remembered

Load-bearing verdicts come from the Tachyon repo's own construction evidence:

| Signal | Measurement (Tachyon repo, 2026-06-25) |
|---|---|
| SDD usage | **77 specs** under `docs/specs/**` — the whole product built spec-by-spec |
| second-model review | **72/77 specs** mention codex dueto / codex-review / adversarial |
| spec-verify | **73/77 specs** carry a `Verify:` line; suite-green counts up to **1291** |
| handoff | 81 doc/src references |
| delegation | 31 references |

## Hygiene constraints (binding)

- This map **names Agent0** → it is a **private** artifact. It must never land in the Tachyon repo.
- No gitignore needed: Agent0 is discontinued after migration. The doc stays tracked Agent0-side until then.
- Only the **resulting** plugins/engine-features — in **generic** language — land in Tachyon. A plugin carrying `secrets-scan` ships as "secrets preflight," never "Agent0's secrets-scan."

## Disposition buckets

### A — Already engine-native in Tachyon (confirm parity, then retire the Agent0 dependency)

Exists in the Tachyon engine; harvest = **confirm functional parity + write the acceptance proof**, not rebuild. The dueto sharpened each parity claim — none is a clean "done," each owes an acceptance test.

| Capability | Tachyon-native home | Parity caveat (dueto) → required acceptance |
|---|---|---|
| **second-model review (dueto)** | `probe_agent` Bridge tool + spec 257 (`adversarial-review` / `factual-verify` archetypes, claude+codex) | **Subsumed** — the core dueto lane is already engine-native. Only a thin wrapper remains *if* a named `/sdd debate` slot-fill / transcript format is wanted. Was Bucket B; **promoted to A** per dueto. |
| **session-handoff** | `src/handoff/ProjectHandoffStore.ts` + Bridge `*_project_handoff*` | Storage/CAS/pending-notes are strong, but canonical distillation is **manual/human-owner**; agents *append*, not rewrite. Not yet Agent0's closeout discipline. **Acceptance:** a Tachyon-rooted agent reads handoff on start, updates canonical state at finish, next agent resumes with **zero** Agent0 startup brief. |
| **delegation gate/verify** | `src/bridge/spawnContract.ts` | Narrower + has an explicit **`skip_contract_reason` bypass**; enforced only for ad-hoc AI `cmd` spawns (declared agents + terminal children out of scope). **Acceptance:** an ad-hoc codex/claude child receives task/context/constraints/done_when and the parent gates the result. |
| **pipeline/worktree done gate** | `src/pipeline/doneContract.ts` | Covers the squad/worktree "externally verified done" only — see BLOCKER split below. |

### B — Harvest as a plugin (via the spec-250 engine, which is shipped)

| Capability | Agent0 mechanism | Plugin shape | Notes |
|---|---|---|---|
| **spec-verify** (`Verify:` convention + artifact verifier) | `spec-verify.sh` + `tasks.md` `Verify:` line + advisory | Skill/hook plugin: the verify runner + the `Verify:` contract. | **Split out of Bucket A** — `doneContract` does NOT implement this. The *spec-artifact* verifier is genuine migration work. |
| **SDD** (spec-driven backbone) | `/sdd` skill + `spec-driven.md` + sdd-close | Skill plugin — OR an engine-native "spec" object (OQ). | **The backbone. Must come EARLY** (see bootstrap-ordering risk), not after two other migrations. |
| **secrets-scan** | `secrets-preflight.sh` (PreToolUse Bash) + native pre-commit | Hook plugin → wires `PreToolUse` into claude+codex. | **Demoted from "first slice."** It exercises the riskiest surface first (remote private source + hook execution + sensitive repos + claude/codex event diffs). Migrate **after** trust model, sourcing, and double-firing are proven. |
| validators (lint/typecheck/tdd advisories) | `governance-gate.sh`, lint/typecheck rules | Hook plugin bundle. | Note: per-edit validation may **not port** as-is (spec 248: Tachyon has no tool-loop hook) → may belong in Bucket D. |

### C — Drop / out of scope (Agent0 product capabilities, not used to build Tachyon)

- Media/capacity: audio, sound, transcribe, diagram, image-gen, video-gen, frontend-designer, capacity-kit
- Audit tools: unused-code-audit, vuln-audit (useful, but not what built Tachyon)
- Stack-specific: php-laravel-support
- Agent0-internal: harness-sync, agent0-status, runtime-capabilities, memory-placement, context-retrieval, propagation — their Tachyon analogues (plugin updater + Bridge) are shipped.

### D — Needs a Tachyon-native *story* (redesign, not a port) — added per dueto

Capabilities that WERE load-bearing but whose Agent0 mechanism does not portably transfer. They must not be silently dropped (Bucket C) nor assumed native (Bucket A).

| Capability class | Why it can't just port | Direction |
|---|---|---|
| **UI acceptance** ("drive/inspect UI locally") | Tachyon has many UI-impact specs + local-only render gates; CI **excludes** the VS Code host integration suite. Static unit tests don't prove webview behavior. Agent0's `agent-browser` is likely not the portable tool. | A Tachyon-native UI acceptance harness (VS Code / Xvfb render), not the Agent0 browser primitive. |
| **per-edit validation** (lint/typecheck on save) | spec 248: Tachyon has no tool-loop hook to fire a validator per edit. | Redesign as a Tachyon-native check (pre-commit / pipeline stage), not a per-edit hook. |

## Cutover invariant (the staged discipline that makes decouple==harvest true)

**One active harness per runtime per workspace.** For each capability, before retiring the Agent0 version: install the Tachyon replacement → run a clean **Tachyon-rooted smoke** proving it fires → only then remove the Agent0 path. Never run an Agent0-rooted session *and* the installed Tachyon plugin for the same governance simultaneously (double-fire).

## Minimum Viable Self-Hosting Slice (MVSH) — the real first milestone

The dueto's biggest unnamed risk: SDD is the backbone but was sequenced last. Fix — the first milestone is not "one plugin," it is the **smallest set that lets a Tachyon spec be built from `/home/goat/tachyon` with zero Agent0 reads**:

> **MVSH = handoff (A, prove acceptance) + SDD scaffolding (B, early) + spec-verify (B) + probe review (A, already there).**

## Recommended sequence (revised)

1. **Benign round-trip first.** Author a harmless marker/status hook plugin (writes a no-op status for claude+codex), install→wire→update→remove via the Plugins View in a clean `/home/goat/tachyon`. Proves the engine lifecycle **without** touching security/trust. (Replaces "secrets-scan first.")
2. **Confirm Bucket A acceptance** — write the handoff + delegation + done-gate parity proofs. Promote dueto-core to done.
3. **SDD scaffolding early** (B) — it is the backbone; the first real Tachyon-rooted spec needs it.
4. **spec-verify** (B).
5. **MVSH proof:** build one Tachyon spec end-to-end from a `tachyon`-rooted session, zero Agent0 reach.
6. **secrets-scan** (B) — only after trust/source/double-fire are proven.
7. UI acceptance + per-edit validation (D) — Tachyon-native redesign, on demand.

## Open questions

- **OQ1 — Plugin content repo location.** dedicated plugin repo · monorepo · per-capability repos? (spec-250 sourcing = git remote-only in v1.)
- **OQ2 — Bucket A retirement proofs.** Concrete acceptance per row in Bucket A (handoff / delegation / done) before removal — drafted above, needs to become real tests.
- **~~OQ3 — dueto vs probe-agent~~ RESOLVED by dueto:** probe-agent (spec 257) subsumes the second-model-review core → moved to Bucket A. Only a thin `/sdd debate` wrapper might remain.
- **OQ4 — Cutover sequencing** → resolved into the **Cutover invariant** above.
- **OQ5 — SDD: plugin or engine-native?** Skill plugin is the obvious shape, but Tachyon may want a first-class "spec" object. Decide before migrating the backbone.

## Dueto record

- **2026-06-25 — codex dueto (read /home/goat/tachyon).** Verdict NEEDS-REVISION. 2 BLOCKER (done/verify overclaim split into A+B; secrets-scan demoted as first slice → benign round-trip), 3 HIGH (probe subsumes dueto→A; Bucket D added for UI; cutover invariant), 3 MEDIUM (handoff/delegation acceptance sharpened; bootstrap-ordering → MVSH). All folded above. Transcript: `.agent0/.runtime-state/codex-exec/20260625T152552Z-harvest-map-dueto/`.
