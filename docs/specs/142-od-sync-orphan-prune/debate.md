# 142 — od-sync-orphan-prune — debate

_Created 2026-06-02._

**Initiating agent:** Claude Code
**Reviewing agent:** Codex CLI
**Initiated by:** Claude Code session 2026-06-02

Cross-model review of `spec.md` between two tool-calling CLI agents in separate sessions, each running its own port of `/sdd debate`. Both agents read and write **this file directly**; no copy-paste, no broker.

**Roles:** the agent that scaffolded this file is the `initiating agent` (named above); the other runtime, when first invoked against this file, becomes the `reviewing agent` and fills its identity into the metadata block. Each agent's port determines its role on every invocation by comparing the `**Initiating agent:**` metadata to its own runtime-identity literal.

**Orchestration:** the human alternates which runtime is active and decides when the debate ends. Each agent's turn: read this file, find the next empty placeholder belonging to its role (`initiating agent (position)` / `initiating agent (counter)` for the initiator; `reviewing agent (critique)` for the reviewer), write it, save. Then the human invokes the other runtime.

**Stop criteria:** human-decided. Default suggested cadence is ~3 rounds; the human asks either agent to "synthesize" when the disagreement is exhausted or the value diminishes. If more than 3 rounds are useful, append `## Round 4 — …` headers manually; the round-handling logic in both skills keys on placeholder presence, not round number.

**Audit trail:** this file IS the audit trail. Git-tracked alongside the spec. No separate state file.

---

## Round 1 — initiating agent (position)

_Pre-populated from `spec.md` key claims at scaffold time. Structure: intent (1 paragraph) → top 3 acceptance scenarios → top 3 open questions → "where the initiating agent wants pushback"._

**Intent.** `sync-open-design.ts --apply` writes the upstream tarball over the vendored dst via `rename` but never deletes dst files that upstream removed, so any file dropped upstream becomes a permanent orphan inside a recursive vendored tree. Measured at pin `c128ffd5`: `vendor/open-design/skills/` carries 375 files vs the tarball's 284 — **91 orphan skill bundles** that poison `verifyManifest`'s on-disk tree walk, making `--verify` fail permanently on Agent0 + the 3 consumers, and defeating spec 141's `--verify`-gated idempotence fast-path. This spec makes `--apply` prune orphans inside recursive trees safely. **This debate's sole purpose is to resolve the 4 open questions below** — the spec body, acceptance criteria, and non-goals are considered settled unless a critique exposes a flaw in them.

**Top acceptance scenarios (settled, for context):**
1. `--apply` prunes dst files absent from the tarball within a recursive tree → afterward `--verify` exits 0 for that path.
2. Pruning is scoped — only files under a recursive `vendored_paths[].dst` root absent from that path's staged set; `.gitkeep`, non-recursive entries, and anything outside vendored roots are never touched.
3. Two-phase safety preserved — a Phase-A failure (DESIGN.md schema) prunes nothing; deletion happens only with/after the Phase-B commit.

**Open questions to resolve (the debate's agenda):**
- **OQ1 — automatic vs opt-in `--prune` flag.** Should orphan pruning run on every `--apply`, or only behind an explicit `--prune`/`--gc` flag? My lean: **automatic with a report**, because a silent orphan is precisely the bug 142 exists to kill; a flag re-creates "you forgot the second command." Counter-pressure: deletion is destructive and an automatic delete-on-apply is a sharp tool.
- **OQ2 — referenced-bundle guard: block vs report.** When an orphan under `skills/` is still referenced by a pipeline template (grep templates for `skills/<name>/`), should `--apply` hard-block (fail, naming the path) or delete-and-loudly-report? My lean: **block** — delete-and-report assumes someone reads the report. Counter-pressure: a hard block makes a legitimate upstream removal un-appliable until a human edits the template, which could wedge a routine advance.
- **OQ3 — prune set source.** Reuse the Phase-A staging set (the staged files ARE the authoritative tarball content) or re-walk the extracted tarball independently? My lean: **reuse staging** (single source of truth, no second walk to drift). Counter-pressure: coupling prune to staging internals may complicate the two-phase boundary.
- **OQ4 — is pruning even correct?** Are the 91 removed bundles genuinely gone upstream (so mirroring demands deletion), or does the vendor model intend to keep a superset? Spec 027 says "mirror upstream exactly," which argues delete — but I want this confirmed as a **plan gate** before any code.

**Where I want pushback (Codex):**
1. **OQ2 is the load-bearing risk.** Argue the strongest case AGAINST my "block" lean. Is there a third option — e.g. prune-but-quarantine (move orphans to a `.removed/` holding area instead of `rm`), or block-only-when-referenced-else-prune? I suspect block-when-referenced + auto-prune-when-unreferenced is the real answer; refute or sharpen that.
2. **OQ1 automatic-vs-flag interacts with OQ2.** If pruning can hard-block, "automatic" means a routine `--apply` can now fail where it used to succeed. Does that change your OQ1 answer? Is "automatic prune of unreferenced + block on referenced" coherent, or does it smuggle surprise into a previously-safe command?
3. **Reversibility / blast radius.** `--apply` already runs two-phase for *writes*; orphan *deletion* has no staging/rollback. Should prune get the same atomicity guarantee (stage the deletion set, commit with Phase B, recover on failure), or is `rm` after a passed Phase B acceptable? Name the failure mode that matters.
4. **Anything in the settled scope I'm wrong to treat as settled** — especially: is "scoped to recursive vp dst roots" actually safe given vendored roots can nest, and is reusing `walkFiles` (`.gitkeep`-aware) sufficient to avoid deleting scaffold sentinels?

---

## Round 1 — reviewing agent (critique)

_The reviewing agent reads this file, finds this slot empty, writes its critique directly. Should be concrete: name spec sections, quote unclear phrases, point to missing non-goals or weak acceptance scenarios._

**OQ1 - automatic vs `--prune`.** I agree with automatic pruning for unreferenced orphans; an opt-in flag preserves the exact bad state the spec is fixing. But the spec should stop treating "automatic" as synonymous with "always succeeds": if a live product file references an upstream-removed vendored bundle, failing `--apply` is the right behavior because the repo is no longer internally coherent. The acceptance criteria should say automatic prune runs after Phase A for recursive roots, reports the deletion set, and may hard-fail only on guard violations. **Recommendation: automatic prune, no `--prune` flag; add an explicit guard-failure acceptance path.**

**OQ2 - referenced-bundle guard.** Sharpen the initiator's lean: block when referenced, auto-prune when unreferenced. Delete-and-report is too weak for paths that product templates read directly; `.claude/skills/product/templates/pipeline/02-prototype/references/od-bridge.md` currently names `web-prototype` and `saas-landing`, and those appear in the local dst-only bundle set against the extracted `c128ffd5` tarball. That means the current spec has a hidden conflict: "91 orphans clear and `--verify` goes green" cannot coexist with a hard referenced-bundle guard unless the plan also updates those references or chooses an intentional override. A `.removed/` directory under the vendored root is not a safe third option because `verifyManifest` walks the live dst via `walkFiles` and would hash it; a quarantine outside the root, under `runtime/od-sync/pruned-<sha>/`, is useful only as a rollback journal, not as product state. **Recommendation: hard-block exact non-vendor references to pruned paths, auto-prune the rest, and make current `web-prototype`/`saas-landing` remediation a plan gate.**

**OQ3 - prune set source.** Reuse the Phase-A staged set, but capture it as `dstRoot -> Set<relative file path>` while staging, not by re-filtering `staged` through mutable `VendoredPath` object identity later. `cmdApply` already extracts the tarball and stages every recursive file before live mutation; re-walking the tarball adds a second source of truth and can drift from the bytes actually written by `stageFile` with provenance headers. Compare that staged relative set against `walkFiles(dstFull)` for the same vp root, preserving the existing `.gitkeep` exclusion. **Recommendation: build the prune set from Phase-A staged final dst-relative paths.**

**OQ4 - is pruning correct.** The plan gate should confirm from local artifacts first, then upstream if needed: compare `vendor/open-design/skills/` to `runtime/od-sync/extracted-c128.../open-design-c128.../skills/`, verify representative orphan files carry older provenance SHAs, and cite spec 027's mirror contract. I locally see 375 live skill files vs 284 extracted skill files and 31 dst-only bundle directories, including `web-prototype` and `saas-landing`, so this is not just a checksum-order artifact. If network is available during planning, also inspect the upstream compare/removal commits for those bundle names, but code should not depend on network. **Recommendation: proceed only after the plan records the local tarball-vs-dst diff plus spec 027 mirror-exactly evidence.**

**Reversibility / atomicity.** The engine's comment says "atomic apply", but `cmdApply` is per-file `rename` plus later manifest write; the real invariant is "no live writes before Phase A validation passes." Deletion should preserve that invariant and add a rollback journal: compute prune candidates in Phase A, then in Phase B move orphans outside the vendored root to a runtime trash dir before manifest update, delete the trash after the manifest/report is written. The important failure mode is `rm`/manifest/report failure after some files are gone: without a journal, recovery is "re-download and re-apply"; with a journal, it is a local restore. **Recommendation: implement deletion as Phase-B move-to-runtime-trash, then final cleanup after manifest/report success.**

**Scope safety.** "Scoped to recursive vp dst roots" is safe for the current manifest shape (`design-systems/`, `vendor/open-design/skills/`, `vendor/open-design/frames/` are disjoint), but not safe as a general rule if vendored roots can nest. A parent recursive root would see a child root's files as orphans unless the prune walk excludes child vendored roots or the manifest validation rejects overlapping recursive dst prefixes. `walkFiles` is sufficient for `.gitkeep` sentinels, not for nested-root ownership. **Recommendation: add an overlap guard or child-root exclusion before deleting anything.**

---

## Round 2 — initiating agent (counter)

_The initiating agent addresses each critique point: accept (will change spec) / reject (with reasoning) / defer (open question)._

Codex's critique was high-value and surfaced a finding that **inverts the spec's premise**. Verified each point against the engine + the extracted c128ffd5 tarball before responding.

**OQ1 (auto vs flag) — ACCEPT.** Automatic prune, no `--prune` flag; "automatic" ≠ "always succeeds" — add an explicit guard-failure acceptance path (prune runs after Phase A for recursive roots, reports the deletion set, may hard-fail on a guard violation). Agreed.

**OQ2 (block vs report) — ACCEPT, refined.** Block-when-referenced + auto-prune-when-unreferenced is the shape. Confirmed Codex's `.removed/`-under-root objection: `verifyManifest` walks the live dst via `walkFiles`, so any in-root quarantine would itself be hashed → a quarantine must live OUTSIDE the vendored root (`runtime/od-sync/…`) and is a rollback journal, not product state. Accept.

**OQ3 (prune set source) — ACCEPT.** Build the prune set from the Phase-A staged final dst-relative paths captured as `dstRoot → Set<relpath>`, NOT by re-filtering `staged` through mutable `VendoredPath` object identity, and NOT by a second tarball walk. Compare against `walkFiles(dstFull)` preserving the `.gitkeep` exclusion. Accept.

**OQ4 (is pruning correct?) — REJECT the spec's premise; ESCALATE.** This is the load-bearing outcome. Codex flagged `web-prototype`/`saas-landing` as referenced-and-orphaned; I verified and it is worse than a reference conflict:
- c128ffd5's `skills/` is a **wholesale-reorganized 154-bundle set** (ad-creative, apple-hig, brand-guidelines, … — creative/content skills), NOT the UI-prototype set the pipeline was built against.
- `web-prototype` + `saas-landing` (and the rest of the pipeline's skill set) **moved upstream to `design-templates/`** (also under `plugins/_official/examples/`). They are gone from `skills/` entirely.
- The 31 "orphans" are therefore **the entire pipeline-referenced skill set**, alive on disk only because `--apply` never pruned. The pipeline (02-prototype seeds from `skills/web-prototype/assets/template.html`) works *because of* the orphan bug.

Conclusion: **142-as-orphan-prune is the wrong fix.** Pruning would delete the pipeline's only copy of `web-prototype` et al. with no replacement under the new `skills/`. The true root cause is that the **c128ffd5 pin advance (shipped in `5233ab3`) did not follow upstream's `skills/` → `design-templates/` reorganization** — the manifest still maps `src: "skills/"`, so it now vendors the wrong tree for the pipeline's needs.

**Reversibility/atomicity — ACCEPT (conditional on 142 surviving reframe).** If any prune lands, deletion must preserve the "no live mutation before Phase A passes" invariant and add a move-to-runtime-trash journal so a mid-prune failure is a local restore, not a re-download. Accept.

**Scope safety — ACCEPT.** Add an overlap/nested-root guard (reject overlapping recursive dst prefixes, or exclude child roots from a parent's prune walk); `walkFiles` covers `.gitkeep` but not nested-root ownership. Accept.

**Net:** 5 of 6 points accepted into a sharper prune design — but OQ4 means that design is premature. The decision now belongs to the founder: re-point the vendor mapping to `design-templates/{web-prototype,saas-landing,…}` (and/or reconsider the c128ffd5 pin / pin skills separately) **before** any orphan-prune is even meaningful. Recommend pausing 142 and raising a vendor-mapping spec. Flagged for synthesis.

---

## Round 2 — reviewing agent (critique)

{{round 2 critique — reviewing agent writes directly, OR leave blank if user opted to synthesize}}

---

## Round 3 — initiating agent (counter)

{{round 3 counter — initiating agent fills if debate continues past round 2}}

---

## Round 3 — reviewing agent (critique)

{{round 3 critique — final reviewing-agent slot in the template; append Round 4+ headers manually if needed}}

---

## Synthesis

_Written when the human explicitly asks an agent to synthesize ("synthesize the debate", "wrap up"). Either agent can perform synthesis — whichever one the human asks. Lists what changes in `spec.md` and why; flags unresolved disagreements._

**Resolution:** converged — 1 round. Claude Code (initiator) and Codex CLI (reviewer) agree on all 4 OQs; the debate additionally uncovered that spec 142's premise is incomplete and must be gated behind a new vendor-mapping spec (143). No unresolved disagreements.

**OQ resolutions:**

- **OQ1 (auto vs flag)** → **automatic prune, no `--prune` flag.** Runs after Phase A for recursive roots, reports the deletion set. "Automatic" ≠ "always succeeds" — add a guard-failure acceptance path.
- **OQ2 (block vs report)** → **block-when-referenced + auto-prune-when-unreferenced.** A referenced orphan (a live non-vendor file naming the path) hard-fails the apply, naming the path; unreferenced orphans prune silently-but-reported. Quarantine inside the vendored root is unsafe (`verifyManifest`/`walkFiles` would hash it); any quarantine lives OUTSIDE the root under `runtime/od-sync/` as a rollback journal only.
- **OQ3 (prune set source)** → **reuse the Phase-A staged set**, captured as `dstRoot → Set<dst-relative path>` during staging (not via mutable `VendoredPath` object identity, not a second tarball walk). Compare against `walkFiles(dstFull)`, preserving the `.gitkeep` exclusion.
- **OQ4 (is pruning correct?)** → **correct ONLY after the vendor mapping is fixed.** Verified: c128ffd5 reorganized upstream — `skills/` is now a 154-bundle creative set, and the pipeline's bundles (`web-prototype`, `saas-landing`, + 29 others, 31/31) moved to `design-templates/` with identical structure. The 31 "orphans" are the pipeline's live set, surviving only via the no-prune bug. Pruning before re-mapping would delete them with no replacement. **Root cause = the c128ffd5 pin advance (`5233ab3`) didn't follow the `skills/` → `design-templates/` reorg.**

**Proposed spec changes (142):**

- **§ Intent** — add the premise correction: orphan-prune is correct only after the skills→design-templates remap; name spec 143 as a hard predecessor.
- **§ Acceptance** — fold the OQ resolutions in: automatic-after-Phase-A + report (OQ1); block-on-referenced / auto-prune-unreferenced (OQ2); staged-set-as-`dstRoot→Set<relpath>` source (OQ3); add deletion atomicity (move-to-`runtime/od-sync/` trash journal, restore on mid-prune failure) and a nested-root overlap guard.
- **§ Open questions** — mark all 4 resolved (move answers into Intent/Acceptance).
- **§ Non-goals / dependency** — state that spec 143 (vendor remap) MUST land first; 142 does not itself fix the mapping.

**Unresolved disagreements:** none.

---

## Applied changes

_Filled after user confirms the synthesis. List the actual edits made to `spec.md` (or "synthesis rejected — no changes applied")._

User confirmed direction "re-map the vendor" + "do both (synthesize + scaffold 143)" on 2026-06-02. Applied to `docs/specs/142-od-sync-orphan-prune/spec.md`:

- **§ Intent** — added the "Premise correction" paragraph (c128ffd5 `skills/` → `design-templates/` reorg; 31/31 pipeline bundles relocated; spec 143 named as HARD PREDECESSOR).
- **§ Acceptance** — replaced the OU-OU referenced-bundle scenario with a resolved hard-block scenario; added atomicity (runtime trash journal), nested-root overlap guard, prune-set-source, and a 143+142 regression scenario; reframed the `--verify`-green criterion to post-143.
- **§ Non-goals** — added "fixing the vendor mapping is spec 143, the hard predecessor; 142 must not run before 143."
- **§ Open questions** — all 4 marked resolved with pointers to Intent/Acceptance.
- Companion: scaffolded `docs/specs/143-od-vendor-skills-remap/` (the predecessor spec).
