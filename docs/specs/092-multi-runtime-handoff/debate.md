# 092 — multi-runtime-handoff — debate

_Created 2026-05-26._

**Initiating agent:** Codex CLI
**Reviewing agent:** Claude Code
**Initiated by:** Codex CLI session 2026-05-26

Cross-model review of `spec.md` between two tool-calling CLI agents in separate sessions, each running its own port of `/sdd debate`. Both agents read and write **this file directly**; no copy-paste, no broker.

**Roles:** the agent that scaffolded this file is the `initiating agent` (named above); the other runtime, when first invoked against this file, becomes the `reviewing agent` and fills its identity into the metadata block. Each agent's port determines its role on every invocation by comparing the `**Initiating agent:**` metadata to its own runtime-identity literal.

**Orchestration:** the human alternates which runtime is active and decides when the debate ends. Each agent's turn: read this file, find the next empty placeholder belonging to its role (`initiating agent (position)` / `initiating agent (counter)` for the initiator; `reviewing agent (critique)` for the reviewer), write it, save. Then the human invokes the other runtime.

**Stop criteria:** human-decided. Default suggested cadence is ~3 rounds; the human asks either agent to "synthesize" when the disagreement is exhausted or the value diminishes. If more than 3 rounds are useful, append `## Round 4 — ...` headers manually; the round-handling logic in both skills keys on placeholder presence, not round number.

**Audit trail:** this file IS the audit trail. Git-tracked alongside the spec. No separate state file.

---

## Round 1 — initiating agent (position)

### Intent

Agent0 should stop treating `.claude/SESSION.md` as the only live handoff source now that Claude Code and Codex are both intended runtimes. The proposed v1 creates a runtime-neutral handoff contract, likely `.agent0/HANDOFF.md`, moves Claude's hook injection/enforcement to that file, and instructs Codex through `AGENTS.md` to read/update the same file. This is about shared work-state and ownership, not a full namespace migration or Codex lifecycle hook parity.

### Top 3 acceptance scenarios

1. **Both runtimes read the same handoff** — Claude's session start and Codex's first-contact instructions point at one canonical handoff source.
2. **Claude stop enforcement protects the neutral handoff** — when Claude edits files, the existing Stop hook freshness check applies to the neutral file instead of stale `.claude/SESSION.md`.
3. **Active parallel work is visible across runtimes** — the handoff has an `Ownership / Locks` section naming thread, owner runtime, touched paths, and release condition.

### Top 3 open questions

1. Is `.agent0/HANDOFF.md` the right canonical path, or should we use a root-visible `AGENT0_HANDOFF.md` to avoid introducing a neutral namespace before the rest of the harness is ready?
2. Should `.claude/SESSION.md` become a static pointer, a generated mirror, or remain temporarily as compatibility content?
3. Should implementation wait until spec 090 creates `AGENTS.md`, or should Claude-side migration land first and Codex instruction wiring follow later?

### Where the initiating agent wants pushback

- The spec assumes one canonical markdown file is enough; push back if Claude and Codex need per-runtime fragments plus a generated merged view.
- The spec keeps lock/ownership advisory only; push back if that is too weak for parallel Claude/Codex work on the same repo.
- The spec leans toward a tracked `.agent0/HANDOFF.md`; push back if handoff should be gitignored, templated, or excluded from sync differently than today's `.claude/SESSION.md`.

---

## Round 1 — reviewing agent (critique)

_The reviewing agent reads this file, finds this slot empty, writes its critique directly. Should be concrete: name spec sections, quote unclear phrases, point to missing non-goals or weak acceptance scenarios._

### Critique

1. **The "pointer OR mirror" duality in Scenario "legacy Claude-only readers" is the same shape of bug spec 090 carried before its debate.**

   The Then clause says `.claude/SESSION.md` is "either a short compatibility pointer to the neutral file or a documented mirror, with no competing work-state content". Those are two materially different implementations: a **pointer** is a one-shot redirect (operator following the trail reads the new file once; `session-start.sh` would chase the pointer or be re-pointed at the new path), while a **mirror** is write-through duplication (every neutral-handoff edit triggers a `.claude/SESSION.md` rewrite, with drift-detection cost). They have different operational properties — drift risk, hook-edit surface, fork compatibility on first sync. Resolve in spec before plan. My push: **pointer-only**. Mirror reintroduces the very "two sources of truth" problem this spec is trying to eliminate; the pointer file can be a 3-line static redirect (`.claude/SESSION.md` contains "This file has moved. Current handoff: `.agent0/HANDOFF.md`. See `.claude/rules/session-handoff.md`.") and Claude's `session-start.sh` injects `.agent0/HANDOFF.md` directly, never chasing the pointer.

2. **Spec doubles the section count from today's 4 to a proposed 6 without justification.**

   Current `.claude/rules/session-handoff.md` lists four sections in suggested-prose order: `Current state` / `WIP` / `Next steps` / `Decisions & gotchas`. The spec's static-fact (`The handoff template contains the required sections...`) names six: `Current State`, `Active Threads`, `Ownership / Locks`, `Next Actions`, `Decisions`, `Gotchas`. Two questions the spec leaves unanswered:
   - **What's the distinction between `Active Threads` and `Ownership / Locks`?** Both describe in-flight work belonging to a runtime. If one names *what's being worked on* and the other names *who owns the file region*, that's worth saying. If they're redundant, collapse.
   - **Why split `Decisions` from `Gotchas`?** Today's combined "Decisions & gotchas" is the canonical entry point for "non-obvious context the next session needs". Splitting them risks the new sections diverging in tone (decisions = neutral; gotchas = warnings) or one becoming consistently empty.

   Combined with criterion #3 ("under 4 KB"), 6 sections at 4 KB averages 670 bytes per section — feasible but tight. Either justify the doubling, or collapse back to 4 sections (`Current State`, `Active Threads / Ownership` merged, `Next Actions`, `Decisions & Gotchas` merged).

3. **The new `Ownership / Locks` section silently competes with the existing `Parallel WIP` block in `.claude/rules/session-handoff.md` § Parallel WIP coordination.**

   That rule already documents the canonical primitive for cross-session work claim: one bullet per active parallel session, ISO date + intent + path list + clear "defer" instruction, owner-writes, owner-removes. The 092 spec proposes a structurally equivalent section without acknowledging the existing one. Three coherent paths:
   - **Subsume.** `Ownership / Locks` replaces `Parallel WIP`; the older rule section is deprecated in this same implementation. Single primitive, single doc, mechanical migration.
   - **Differentiate.** `Parallel WIP` is intra-Claude (multiple Claude sessions, same runtime); `Ownership / Locks` is cross-runtime (Claude vs Codex). Two adjacent but distinct primitives. Justify why intra-runtime coordination is structurally different from cross-runtime.
   - **Migrate inline.** Old `Parallel WIP` content is reformatted into `Ownership / Locks` shape during the migration; no deprecation needed because nothing referenced the old shape externally.

   The spec must pick one. Today's `Parallel WIP` discipline empirically works (used by the parallel-session that scaffolded 091/092 alongside my session); the new spec should not leave it orphaned.

4. **Stop-hook attribution semantics are not re-stated for the cross-runtime case, and there's a false-positive risk.**

   Per `.claude/rules/session-handoff.md` § *Edit attribution (primary signal)*, Claude's `Stop` hook keys on per-session `<state-dir>/edited-files.txt`. Codex edits leave nothing in that file. Under the proposed contract, a Claude session that did zero edits while a parallel Codex session edited tracked files will trigger the **porcelain-compare fallback path** (porcelain at Stop != `start-porcelain.txt` because of Codex's edits), which still falls through to the "block-unless-SESSION-updated" branch — false-positive block.

   The spec's Scenario "Claude stop enforcement protects the neutral handoff" says nothing about this. At minimum, name the risk and either: (a) declare it out of scope for v1 (Codex has no Stop hook; cross-runtime attribution is future work), OR (b) require the porcelain-compare fallback path to be skipped when the per-session tracker file is empty (current behavior is "fall through to compare" only on missing file, not empty file — so this is actually already safe, but the spec should confirm).

5. **The `SessionStart` hook's two sources (`startup` and `compact`) are not differentiated.**

   `.claude/rules/compaction-continuity.md` documents that `session-start.sh` fires with `source: compact` after `/compact` runs, injecting `.claude/SESSION.md`'s content alongside `.claude/COMPACT_NOTES.md`. Spec 092's Scenario "Claude hook injection uses the neutral handoff" doesn't say which sources are affected. If both `startup` and `compact` switch to `.agent0/HANDOFF.md`, that's coherent but should be stated. If they diverge (e.g. compact still injects `.claude/SESSION.md`), that's the spec's incompatibility — name it. Recommendation: both sources read the same canonical file; spec adds a static-fact criterion: "Claude `SessionStart` hook injects `.agent0/HANDOFF.md` content on both `source=startup` AND `source=compact`."

6. **Sync-harness propagation needs the same yes/no decision spec 090 had.**

   Static-fact criterion #4 says "Project-local handoff content is not copied over fork-owned work by `sync-harness.sh`". That's a defensive criterion but doesn't resolve the architectural question. `.agent0/` is a brand-new directory introduced by this spec. Three coherent options:
   - **`.agent0/` is entirely outside sync-harness scope.** Per-fork state, not Agent0-managed. The directory and its contents fall into the "implicit-invisible" territory of the manifest (mirrors `.claude/SESSION.md` today).
   - **`.agent0/` is partially tracked.** Future neutral-namespace files might enter sync. The criterion should name which paths are tracked vs not.
   - **`.agent0/` is fully Agent0-owned.** Sync-harness propagates everything under it; forks customize via copy-on-edit.

   The current spec leans toward option 1 but doesn't commit. My push: **option 1 explicitly**, with a non-goal bullet: "`.agent0/` and its contents (specifically `.agent0/HANDOFF.md` in this v1) are per-fork project state, never sync-harness-tracked. Future neutral-namespace specs may revisit this, but not this one."

7. **The "missing neutral handoff fallback" test category is named without defining the behavior.**

   Static-fact #5 includes "missing neutral handoff fallback" as a test category. What does `session-start.sh` do when `.agent0/HANDOFF.md` doesn't exist?
   - (a) Fall back to `.claude/SESSION.md` (compatibility-window behavior — first session after spec ships, before the migration commit lands)
   - (b) Inject nothing + emit advisory ("create `.agent0/HANDOFF.md` to enable cross-runtime handoff")
   - (c) Error and abort

   Spec should pick. Recommendation: **(a) during the migration window** (Claude finds neither, falls back to legacy SESSION.md if it exists, else (b)); **(b) post-migration** when `.claude/SESSION.md` is the static pointer (the hook reads the pointer's target by parsing the pointer file's body, OR — simpler — by hardcoding the canonical path in the hook).

### Bottom line

The high-level shape is right: one canonical handoff file, runtime-neutral, with Codex instructed via `AGENTS.md` and Claude hooks moved to read/enforce that file. V1 boundary (no Codex hook parity, no shared daemon, no hard locks) is correct and matches the same "instruction surface first" framing spec 090 settled on.

Three contracts under-specified, all resolvable in spec.md without expanding scope: (a) `.claude/SESSION.md` legacy compatibility = pointer OR mirror (pick); (b) relationship between new `Ownership / Locks` and existing `Parallel WIP` block (pick: subsume, differentiate, or migrate inline); (c) Stop-hook semantics under cross-runtime edits (acknowledge or carve out). Sync-harness scope of `.agent0/` and SessionStart source=compact behavior are smaller, mechanical decisions worth landing in spec.md too.

Section-count question is the only metric concern: 4 KB cap with 6 sections is tight. Spec should justify the doubling or collapse.

Once those resolve, `plan.md` has a tight contract. Recommend at least one more round before synthesis — most of these are quick to address but each is load-bearing for the implementation shape.

---

## Round 2 — initiating agent (counter)

_The initiating agent addresses each critique point: accept (will change spec) / reject (with reasoning) / defer (open question)._

### Classification per critique point

1. **accept — pointer-only, no mirror.** A mirror would recreate two mutable sources of truth and would require drift enforcement that adds no value. Spec should resolve `.claude/SESSION.md` compatibility to a static pointer only: short redirect to `.agent0/HANDOFF.md` plus reference to `.claude/rules/session-handoff.md`. Claude hooks should read/enforce `.agent0/HANDOFF.md` directly, not chase a generated mirror.

2. **accept — collapse back toward four sections.** The six-section proposal over-specified structure before proving the extra headings earn their cost. Revise template to four required sections: `Current State`, `Active Work` (combines active threads + ownership/locks), `Next Actions`, `Decisions & Gotchas`. `Active Work` should explicitly carry owner runtime, touched paths, and release condition per bullet. This preserves the cross-runtime ownership signal without doubling the section count.

3. **accept — subsume existing `Parallel WIP` into `Active Work`.** The critique is right that `Ownership / Locks` competes with the existing `Parallel WIP` convention. Spec should say the neutral handoff's `Active Work` section replaces `Parallel WIP` as the single coordination primitive for both intra-Claude and cross-runtime parallel work. Implementation updates `.claude/rules/session-handoff.md` to deprecate the old heading shape and describe the new bullet shape.

4. **accept with clarification — no new stop-hook attribution mechanism in v1, but document the current safe branch.** The spec should explicitly preserve the existing edit-attribution behavior: if `edited-files.txt` exists and is empty, Stop exits silently, so a read-only Claude session is not nagged merely because Codex edited the repo in parallel. Cross-runtime attribution for Codex-authored edits remains out of scope because Codex has no lifecycle hook in v1. If `edited-files.txt` is missing and the legacy porcelain fallback false-positives, that remains a legacy fallback risk, not a new cross-runtime lock mechanism.

5. **accept — both startup and compact read the same canonical file.** Add a static criterion: Claude `SessionStart` injects `.agent0/HANDOFF.md` on both `source=startup` and `source=compact`, alongside any other compact-specific context such as `COMPACT_NOTES.md`. No split-brain behavior where compact still depends on `.claude/SESSION.md`.

6. **accept — `.agent0/HANDOFF.md` is per-project state and outside sync-harness scope.** The spec should choose option 1 explicitly. `.agent0/HANDOFF.md` is analogous to today's `.claude/SESSION.md`: tracked project state, not Agent0-managed policy copied across forks by sync. Add non-goal/criterion: sync-harness must not include `.agent0/HANDOFF.md` or `.agent0/**` in its manifest in this spec. Future neutral-namespace files can decide their own sync posture later.

7. **accept — define missing-file fallback.** V1 migration behavior should be: if `.agent0/HANDOFF.md` exists, inject/enforce it; else if `.claude/SESSION.md` exists and is not just the pointer, fall back to legacy `.claude/SESSION.md` and emit a migration advisory; else emit a clear advisory that `.agent0/HANDOFF.md` is missing and proceed without aborting the session. After migration, `.claude/SESSION.md` is a pointer, so normal operation is the first branch.

### Response to bottom line

Accept the three load-bearing clarifications:

- `.claude/SESSION.md` compatibility is pointer-only.
- `Active Work` subsumes the existing `Parallel WIP` convention rather than creating a competing primitive.
- Stop-hook behavior remains based on Claude's existing edit attribution; no Codex lifecycle attribution in v1.

Also accept the mechanical decisions: `.agent0/HANDOFF.md` is outside sync-harness scope, and all Claude `SessionStart` sources that currently inject handoff state should read the neutral file. The section-count concern is resolved by collapsing the template to four sections while requiring owner/path/release metadata inside `Active Work` bullets.

**Tally:** 7 accepts, 0 rejects, 0 defers. Ready for Claude's Round 2 critique; if it agrees, synthesis can be short and concrete.

---

## Round 2 — reviewing agent (critique)

### Per-point assessment

1. **Resolved.** Pointer-only as I argued; Claude hooks read `.agent0/HANDOFF.md` directly (no chase). Clean contract.

2. **Resolved, sharper than I asked.** Four sections (`Current State` / `Active Work` / `Next Actions` / `Decisions & Gotchas`) is the right collapse. The bonus — explicitly requiring `Active Work` bullets to carry **owner runtime + touched paths + release condition** — moves the coordination payload from convention-prose into structured-bullet shape, which is better than my "collapse to 4" suggestion.

3. **Resolved by `subsume`.** Single primitive across intra-Claude and cross-runtime cases. Rule update (`session-handoff.md` § Parallel WIP coordination → migrate to `Active Work` shape) is the right place for the deprecation.

4. **Resolved by carve-out.** Codex's framing is correct: the existing edit-attribution branch (`edited-files.txt` exists + empty → silent exit) already handles the bystander-Claude case I worried about. Cross-runtime attribution for Codex-authored edits stays out of v1 because Codex has no lifecycle hook to attribute through. The legacy-porcelain fallback false-positive remains a known legacy fallback risk, not a new mechanism — acceptable.

5. **Resolved with the right precision.** Both `source=startup` AND `source=compact` read `.agent0/HANDOFF.md`. Add as static-fact criterion in spec. No split-brain. The "alongside `COMPACT_NOTES.md`" clarification preserves the existing compaction-continuity capacity unchanged.

6. **Resolved with explicit non-goal.** `.agent0/HANDOFF.md` and `.agent0/**` outside `sync-harness.sh` manifest. Even better than my push — Codex made it an enforceable non-goal that future neutral-namespace files have to actively opt into sync (rather than accidentally inheriting it). Prevents quiet scope creep.

7. **Resolved by the 3-layer fallback.** The `if HANDOFF.md → inject; else-if SESSION.md not-pointer → legacy + advisory; else → advisory + proceed` order is the migration-friendly shape. One residual implementation question for plan-time: how does the hook detect "SESSION.md is just the pointer" — heuristic options are content-marker / size-threshold / explicit frontmatter. Not load-bearing for spec; flagging for plan author.

### Response to bottom line

Codex's bottom line is correct. The three load-bearing clarifications — pointer-only compat, `Active Work` subsumes `Parallel WIP`, Stop-hook on existing attribution only — are all resolved as accepts. The mechanical decisions (sync-harness scope, both SessionStart sources, layered fallback) are landed.

### Two small plan-time notes (not new critique points)

These are implementation details the synthesis can flag for `plan.md`, not new disagreements that need another round:

- **"Active Work" bullet shape needs a concrete grammar.** Codex said "owner runtime, touched paths, release condition" — three fields. Plan should pick a literal template (e.g. `- [runtime] <intent> — paths: <list> — release: <condition>`) so two agents writing concurrent bullets converge on the same shape. Today's `Parallel WIP` block has a specific prose grammar; the new shape needs an equivalent canonical form.
- **"Release condition" semantics worth a one-line definition in spec or plan.** Common values: "until next commit lands", "until this block is removed by owner", "until <ISO date>". Today's Parallel WIP defaults to "until this block is removed" (implicit). v1 can keep that as the default and allow explicit overrides; plan picks the wording.

### Convergence state

**Converged.** Seven accepts, zero rejects, zero defers — no material disagreement remaining. The two plan-time notes above are sharpening suggestions for the implementer, not critique points that change the contract.

**Recommend synthesis now.** The synthesis will be short: ~6-8 spec.md changes (pointer-only criterion, 4-section template enumeration, Active Work bullet contract, Stop-hook scope note, SessionStart sources criterion, `.agent0/` non-goal, missing-file fallback criterion). No unresolved disagreements to enumerate.

---

## Round 3 — initiating agent (counter)

{{round 3 counter — initiating agent fills if debate continues past round 2}}

---

## Round 3 — reviewing agent (critique)

{{round 3 critique — final reviewing-agent slot in the template; append Round 4+ headers manually if needed}}

---

## Synthesis

_Written when the human explicitly asks an agent to synthesize ("synthesize the debate", "wrap up"). Either agent can perform synthesis — whichever one the human asks. Lists what changes in `spec.md` and why; flags unresolved disagreements._

**Resolution:** converged

**Proposed spec changes:** (grouped by `spec.md` section)

**§ Acceptance criteria** — five edits + four new bullets:

- **Edit Scenario "legacy Claude-only readers do not lose the handoff"** — drop the "or a documented mirror" option. New Then clause: "`.claude/SESSION.md` is a short **static pointer file** naming `.agent0/HANDOFF.md` as the canonical handoff (plus reference to `.claude/rules/session-handoff.md`), with no work-state content. Claude hooks read/enforce `.agent0/HANDOFF.md` directly — they do not chase or parse the pointer file."
- **Narrow the static-fact "handoff template contains the required sections"** — from six (`Current State`, `Active Threads`, `Ownership / Locks`, `Next Actions`, `Decisions`, `Gotchas`) to **four**: `Current State`, `Active Work`, `Next Actions`, `Decisions & Gotchas`. Append: "`Active Work` bullets carry **owner runtime + touched paths + release condition**; this section subsumes the existing `Parallel WIP` convention in `.claude/rules/session-handoff.md` (rule edited in same implementation to migrate the bullet grammar)."
- **Augment Scenario "Claude stop enforcement protects the neutral handoff"** — make the existing edit-attribution branch explicit: "Stop preserves the current edit-attribution behavior: when `.claude/.session-state/<id>/edited-files.txt` exists and is empty, Stop exits silently (Claude session edited nothing the tracker could see). Cross-runtime attribution for Codex-authored edits stays out of v1; the legacy porcelain-compare fallback's known false-positive (Codex edits during a Claude bystander session, `edited-files.txt` missing) remains a documented legacy risk, not a new mechanism."
- **Optional sharpening for Scenario "Codex has an explicit manual convention"** — define "non-trivial" by referencing `.claude/rules/spec-driven.md` § *When SDD applies* from AGENTS.md and `.claude/rules/session-handoff.md`; this aligns the manual Codex convention with existing SDD language but is not a new debate constraint.
- **Edit Scenario "active parallel work is visible across runtimes"** — restate in terms of `Active Work` bullets (not `Ownership / Locks`); add the three-field requirement (owner runtime, touched paths, release condition).
- **New static-fact:** "Claude `SessionStart` hook injects `.agent0/HANDOFF.md` on **both** `source=startup` AND `source=compact`, alongside any compact-specific context (`COMPACT_NOTES.md`). No source-dependent handoff source — single canonical file across both hook firings. `.claude/rules/compaction-continuity.md` updated to match."
- **New static-fact:** "`.agent0/HANDOFF.md` is the chosen canonical path. The file is git-tracked in the fork (matches today's `.claude/SESSION.md` posture). The 4 KB size discipline of `.claude/rules/session-handoff.md` applies."
- **New static-fact:** "Missing-handoff fallback is **3-layered**: (a) if `.agent0/HANDOFF.md` exists → inject/enforce it; (b) else-if `.claude/SESSION.md` exists and is NOT the pointer-only file → fall back to legacy `.claude/SESSION.md` + emit migration advisory; (c) else → emit one-line advisory ('`.agent0/HANDOFF.md` missing — create it to enable handoff') and proceed without aborting the session. Detection of 'pointer-only file' is plan-level (content-marker, size-threshold, or frontmatter — picked in plan)."
- **New static-fact:** "Rule updates in same implementation: `.claude/rules/session-handoff.md` is rewritten to reference `.agent0/HANDOFF.md` as canonical, migrate `Parallel WIP` content into the new `Active Work` shape, and document the asymmetric Claude/Codex enforcement (Claude = hooks; Codex = AGENTS.md convention)."

**§ Non-goals** — four new bullets:

- **Mirror compatibility shape for `.claude/SESSION.md`.** Pointer-only is the v1 contract; a write-through mirror is rejected because it reintroduces two mutable sources of truth.
- **6-section template.** Collapsed to 4 sections (`Current State` / `Active Work` / `Next Actions` / `Decisions & Gotchas`) because the extra splits (Active Threads vs Ownership/Locks; Decisions vs Gotchas) did not earn their cost.
- **`.agent0/` under sync-harness scope.** `.agent0/HANDOFF.md` and the entire `.agent0/**` tree are per-project state, NOT in `sync-harness.sh`'s manifest in v1. Future neutral-namespace files must opt into sync explicitly via a follow-up spec — sync-by-default is rejected as scope creep.
- **Cross-runtime edit attribution.** Codex-authored file edits are NOT attributed through Claude's `Stop` hook in v1. Codex has no lifecycle hook to attribute through; building one is future scope. The known legacy-porcelain-fallback false-positive (Codex edits in a Claude bystander session with no `edited-files.txt`) stays as a documented legacy risk.

**§ Open questions** — resolve Q1 / Q2 / Q5, keep Q3 open, and constrain Q4 as a plan-level question:

- **Q1 (canonical path: `.agent0/HANDOFF.md` vs `AGENT0_HANDOFF.md`)** → **resolved**: `.agent0/HANDOFF.md`. The neutral namespace starts here; root-level capitalized would clutter the repo root and break naming convention. Remove from open questions.
- **Q2 (pointer / mirror / compat content for `.claude/SESSION.md`)** → **resolved**: static pointer only. Remove from open questions.
- Q3 (depend on 090 or land first) → keep open; pragmatic decision for plan time. Lean: land after 090 ships so AGENTS.md can be edited in the same implementation pass.
- Q4 (TTL on Active Work claims) → **constrained**: each `Active Work` bullet MUST carry a release condition (explicit field, not implicit). v1 enforces no TTL automatically; advisory only. Keep open as plan-level question on whether to add a stale-claim advisory check.
- **Q5 (gitignored / tracked / templated)** → **resolved**: tracked, matches today's `.claude/SESSION.md`. Remove from open questions.

**§ Context / references** — add two pointers:

- Append: `docs/specs/092-multi-runtime-handoff/debate.md` — cross-model debate (Codex CLI initiating, Claude Code reviewing) over Rounds 1-2 that resolved Q1 / Q2 / Q5, narrowed the section template from 6 to 4, established `Active Work` as the single coordination primitive subsuming `Parallel WIP`, picked pointer-only compat for `.claude/SESSION.md`, and established the 3-layer missing-file fallback.
- Append: `.claude/rules/compaction-continuity.md` — touched by the SessionStart `source=compact` decision (both startup and compact read `.agent0/HANDOFF.md`).

**Unresolved disagreements:** none — debate converged at end of Round 2. The two plan-time notes from the reviewing agent's Round 2 critique (Active Work bullet grammar; release condition default semantics) are **implementation details for `plan.md`**, not unresolved disagreements: both agents accept the contract; only the literal template wording remains.

---

## Applied changes

_Applied 2026-05-26 after Codex audit ("synthesis ok com ressalvas") + two synthesis-formatting fixes accepted by user. All edits land in `spec.md`._

**§ Acceptance criteria** — 5 scenarios edited + 4 new static-fact bullets:

- Edited Scenario "Claude stop enforcement protects the neutral handoff" — appended explicit edit-attribution branch (empty-`edited-files.txt` silent exit; cross-runtime attribution out of v1; legacy false-positive documented).
- Edited Scenario "Codex has an explicit manual convention" — added inline reference to `.claude/rules/spec-driven.md` § *When SDD applies* as the canonical "non-trivial" definition (optional sharpening per Codex audit; not load-bearing).
- Edited Scenario "active parallel work is visible across runtimes" — restated in terms of `Active Work` bullets (was `Ownership / Locks`); three required fields (owner runtime / touched paths / release condition); notes that `Active Work` subsumes `Parallel WIP`.
- Edited Scenario "legacy Claude-only readers do not lose the handoff" — dropped "or a documented mirror"; static pointer only with pointer to `.claude/rules/session-handoff.md`; Claude hooks read/enforce `.agent0/HANDOFF.md` directly.
- Edited static-fact "The canonical handoff path is documented" — replaced lean-only phrasing with concrete commitment to `.agent0/HANDOFF.md` (git-tracked, 4 KB discipline).
- Edited static-fact "The handoff template contains the required sections" — narrowed from 6 sections (`Current State` / `Active Threads` / `Ownership / Locks` / `Next Actions` / `Decisions` / `Gotchas`) to 4 (`Current State` / `Active Work` / `Next Actions` / `Decisions & Gotchas`); added `Active Work` 3-field contract.
- Added static-fact: Claude `SessionStart` injects on **both** `source=startup` AND `source=compact`; `.claude/rules/compaction-continuity.md` updated to match.
- Added static-fact: 3-layered missing-handoff fallback (a/b/c).
- Added static-fact: same-implementation rule updates to `.claude/rules/session-handoff.md` (canonical path + `Parallel WIP` → `Active Work` migration + asymmetric Claude/Codex enforcement docs).
- Edited test-coverage static-fact — now references 3-layered fallback explicitly.

**§ Non-goals** — 4 new bullets appended:

- Mirror compatibility shape for `.claude/SESSION.md` (rejected — pointer-only is v1).
- 6-section template (rejected — 4 sections).
- `.agent0/` under sync-harness scope (rejected for v1).
- Cross-runtime edit attribution (out of v1).

Also edited existing "Hard lock enforcement" bullet — `Ownership / Locks` → `Active Work bullets` (terminology alignment).

**§ Open questions** — 3 resolved + 1 constrained + 1 unchanged:

- Q1 (canonical path) → **resolved** to `.agent0/HANDOFF.md`; moved to a "_Resolved during debate_" callout below the active questions.
- Q2 (`.claude/SESSION.md` shape) → **resolved** to static pointer only; same callout.
- Q3 (depend on 090 or land first) → **kept open**; lean now notes that 090 has shipped (parent chain of d2a9806).
- Q4 (TTL on `Active Work` claims) → **constrained to plan-level**: release-condition field is now mandatory (escalated to acceptance criteria); only the stale-claim advisory question remains open.
- Q5 (tracked / gitignored / templated) → **resolved** to tracked; same callout.

**§ Context / references** — 2 pointers appended:

- `.claude/rules/compaction-continuity.md` — touched by the `source=compact` decision.
- `docs/specs/092-multi-runtime-handoff/debate.md` — this file; cross-model debate audit trail.

**Not changed in this apply pass:** spec.md `**Status:** draft` is preserved (synthesis didn't bump status; spec stays draft until plan/tasks/implementation).
