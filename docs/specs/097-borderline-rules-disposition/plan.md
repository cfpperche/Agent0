# 097 — borderline-rules-disposition — plan

_Drafted from `spec.md` on 2026-05-27. Update this file if implementation reveals the plan is wrong; do NOT silently diverge._

## Approach

Single PR, mechanical execution after a tight per-file audit. The audit's outcome (per § *Per-file disposition* below) locks each of the 3 borderlines into one of `split` / `move-full` / `keep-as-is` BEFORE tasks.md is generated; this spec does NOT defer disposition to implementation time. The execution shape mirrors spec 096's atomicity discipline (one PR touching `CLAUDE.md` + `AGENTS.md` + `memory-placement.md` exactly once), plus the new `split` machinery: for each splittable file, extract the maintainer-binding sections (named explicitly per file) into a `<slug>-maintenance.md` memory entry (mirrors precedent of `hook-chain-maintenance.md`), thin the rule down to its consumer-facing slice, and cross-link the two halves. Order of work: audit `runtime-capabilities` first (smallest, cleanest split), then `propagation-advisory` (mid-complexity but the patterns-vs-override-grammar boundary is sharp), then `runtime-introspect` (largest content + deepest cross-ref graph). Single grep at Phase 1 is repo-wide-minus-(`.git`/`node_modules`/`docs/specs/`) per the lesson from spec 096's missed surfaces (`.claude/.runtime-state/README.md` + `site/src/i18n/capacities.ts`).

The work is NOT mechanically uniform like 096 (which was 100% path-string rewrites). Split disposition requires content-level judgment per file: which sections move, which stay, where the cross-link goes. Acceptance therefore leans more heavily on the "each row's reasoning paragraph names the consumer-binding vs maintainer-binding sections" criterion from `spec.md` AC1 — the disposition table IS the audit artifact, not the diff.

## Per-file disposition

Locked at plan time. Each row carries the disposition + the specific sections drawn from the rule's current `## ` headings, identified as consumer-facing (CF — agent invokes it; user reads it when the capacity fires) or maintainer-binding (MB — extension contract, internal mechanism, drift tooling).

### `runtime-capabilities.md` → **split**

Audit:
- CF: `## Status vocabulary`, `## Capability matrix` (the table itself — Q&A surface for "does runtime X support capacity Y"), `## Future runtimes` (sets expectations for what's not there).
- MB: `## Update rule` ("Every future spec that changes runtime support for a capability MUST update this file" — binds the maintainer), `## Drift enforcement` (documents `check-instruction-drift.sh` behavior — maintainer tooling), `## Skill portability relationship` (cross-axis caveat for the maintainer doing capacity → skill-portability triangulation).

Split shape:
- `.claude/rules/runtime-capabilities.md` keeps the H1 + opening paragraph + § *Status vocabulary* + § *Capability matrix* + § *Future runtimes*. Add a closing § *Maintenance* one-liner pointing to `.claude/memory/runtime-capabilities-maintenance.md`.
- New `.claude/memory/runtime-capabilities-maintenance.md` carries § *Update rule* + § *Drift enforcement* + § *Skill portability relationship* with memory frontmatter (`name: runtime-capabilities-maintenance`, `description: Maintainer discipline for the runtime-capabilities matrix — Update rule + drift enforcement + skill-portability relationship.`, `metadata.type: project`).
- `check-instruction-drift.sh` path expectation unchanged (still reads `.claude/rules/runtime-capabilities.md` for the anchor checks — split leaves the matrix at that path).

### `propagation-advisory.md` → **split**

Audit:
- CF: opening paragraph (what the advisory line looks like when it fires), § *Override marker* (`# OVERRIDE: propagation-exempt:` grammar — agent invokes this), § *Escape hatch* (`CLAUDE_SKIP_PROPAGATION_ADVISE=1`), § *What fires, what stays silent* (table of when the advisory appears — the consumer needs this to read their session output).
- MB: § *The 5 patterns* deep table + extension prose, § *Pattern exclusions (legitimate keeps that bypass the scan)*, § *Shipped surface (where the hook fires)* + § *Within-surface exclusions* (pattern-set design), § *Audit log* (capacity policy — when to promote to pre-commit gate), § *Cross-references* internals, the deeper gotchas (diff-scope semantics, 2+-digit floor reasoning, vendor/design-systems path exclusion details).

Split shape:
- `.claude/rules/propagation-advisory.md` keeps H1 + opening + § *What fires, what stays silent* (abridged — just the rules-of-thumb) + § *Override marker* + § *Escape hatch* + a tight § *Gotchas* with the consumer-relevant pitfalls only (parent-fire surprise, override marker requires ≥10 char reason). Add § *Maintenance* one-liner pointing to the memory entry.
- New `.claude/memory/propagation-advisory-maintenance.md` carries § *The 5 patterns* + § *Pattern exclusions* + § *Shipped surface* + § *Within-surface exclusions* + § *Audit log* policy + the maintainer-deep gotchas, with memory frontmatter.
- **Known false-positive concern (out-of-scope for THIS spec but flagged in `notes.md` during implementation):** the 5 patterns are upstream-bias-sensitive — `docs/specs/NNN-*` and `/home/<user>/` and `.claude/memory/<topic>.md` patterns false-positive on legitimate consumer-side content. This spec's split makes the structural improvement cheap; tuning the patterns themselves is a follow-up. Implementation should NOT touch the hook's pattern list.

### `runtime-introspect.md` → **split**

Audit:
- CF: opening paragraph, § *What fires, what captures* (the agent reads probe output and needs to know what's captured), § *Probe output shape* (the literal stdout the agent pattern-matches), § *Escape hatches* (the 3 env vars — agent may set or honor them), § *`last-run.json` schema* top half (field semantics the agent reads), the top-half of § *Detector pair list (v1)* (table of what triggers capture — the agent needs to know which Bash invocations get captured).
- MB: § *Extension via env var (HUMAN-ONLY, pre-launch)* full text, § *Inference heuristics* per-detector pattern tables (maintainer adding a new detector consults these), § *State file (no audit log)* design rationale, the deep gotchas section (sibling-process env inheritance, ANSI-strip dogfood archaeology, Cargo workspace handling rationale, commit-message FP precedent).

Split shape:
- `.claude/rules/runtime-introspect.md` keeps H1 + opening + § *What fires, what captures* (condensed — name the hooks, drop the implementation paragraph) + § *Detector pair list* table (condensed — drop the extension-by-env subsection) + § *`last-run.json` schema* with field semantics only (drop the inference-heuristics-per-detector table) + § *Probe output shape* + § *Escape hatches* + a tight § *Gotchas* with consumer-relevant items (probe doesn't see its own capture; Bash-only-edit attribution caveat). Add § *Maintenance* one-liner.
- New `.claude/memory/runtime-introspect-maintenance.md` carries the extension contract + inference heuristics tables + cargo workspace handling + the rshrnk dogfood B3 finding archaeology + the maintainer-deep gotchas, with memory frontmatter.

## Files to touch

**Create:**
- `.claude/memory/runtime-capabilities-maintenance.md` — maintainer-binding slice of runtime-capabilities (Update rule + Drift enforcement + Skill portability relationship).
- `.claude/memory/propagation-advisory-maintenance.md` — maintainer-binding slice of propagation-advisory (5 patterns + Shipped surface + Audit log policy + deep gotchas).
- `.claude/memory/runtime-introspect-maintenance.md` — maintainer-binding slice of runtime-introspect (extension contract + inference heuristics + dogfood archaeology + deep gotchas).

**Modify:**
- `.claude/rules/runtime-capabilities.md` — remove MB sections, add § *Maintenance* pointer to memory.
- `.claude/rules/propagation-advisory.md` — remove MB sections, add § *Maintenance* pointer; thin Gotchas to consumer-relevant items only.
- `.claude/rules/runtime-introspect.md` — remove MB sections, add § *Maintenance* pointer; thin schema/detector/gotchas to consumer-relevant items only.
- `.claude/memory/MEMORY.md` — auto-regenerated by `memory-project.sh` from the 3 new entries' frontmatter (no manual edit).
- `.claude/rules/memory-placement.md` § *Why three buckets, not two* — third trigger entry citing spec 097 as the empirical case for the **split** discipline (096 established move-full; 097 establishes split as a distinct legitimate disposition).
- `.claude/rules/delegation.md` — if it cross-references the moved MB sections of propagation-advisory or runtime-introspect, rewrite pointers to memory; if it only references the consumer-facing slice, no change.
- `.claude/rules/php-laravel-support.md` — cross-ref check against runtime-introspect (likely references the detector list or laravel-specific runners; rewrite to whichever slice they target).
- `.claude/memory/cc-platform-hooks.md` — cross-refs to runtime-introspect's hook surface (likely the consumer-facing § *What fires* — confirm during execution; no rewrite if so).
- `.claude/memory/propagation-hygiene.md` — pairs with propagation-advisory (maintainer discipline doc); if cross-refs point at the MB sections that moved, rewrite paths.
- `.claude/memory/user-global-hooks-shadow.md` — cross-ref check; likely benign.
- `.claude/memory/hook-chain-latency.md` — § *Scope* mentions runtime-pre-mark.sh; cross-ref to the runtime-introspect rule may stay valid (consumer-facing slice retains the hook reference).
- `.claude/.runtime-state/README.md` — row for `.claude/.runtime-state/` points to runtime-introspect; row stays pointing to the rule (consumer-facing slice retains the schema/probe surface).
- `CLAUDE.md` — `## Runtime capabilities` section currently points to `runtime-capabilities.md`. After split, the matrix stays at that path — pointer text stays accurate. `## Runtime introspect` section currently points to `runtime-introspect.md`. After split, same — pointer stays accurate. No CLAUDE.md surgery for runtime-capabilities or runtime-introspect IF split is clean; for propagation-advisory, the CLAUDE.md `## Propagation advisory` mention (if any — verify during execution) likewise stays pointing at the rule. CLAUDE.md changes are limited to whatever surfaces require it; a no-op outcome is acceptable.
- `AGENTS.md` — symmetric to CLAUDE.md. Mirror whatever applies.
- `.claude/tools/check-instruction-drift.sh` — path expectation for runtime-capabilities.md unchanged (drift check anchors on `.claude/rules/runtime-capabilities.md` which still exists). No edit unless dogfood surfaces breakage.
- `.claude/tools/sync-harness.sh` — likely benign (references runtime-capabilities.md as the registry path; split keeps the path).
- `.claude/tools/probe.sh` — references runtime-introspect surface; if pointers target the consumer-facing slice (probe output shape, last-run schema), no rewrite. Verify.
- `.claude/hooks/propagation-advise.sh` — header comment references `.claude/rules/propagation-advisory.md`. Stays valid (the rule still exists with that name); no rewrite. Verify the comment doesn't reference a moved section.
- `.claude/hooks/runtime-capture.sh`, `.claude/hooks/runtime-pre-mark.sh` — header comments reference `.claude/rules/runtime-introspect.md`. Same logic — rule still exists; no rewrite unless they cite a moved section by name.
- `.claude/tests/runtime-capabilities/*.sh` — fixture scripts; likely no doc pointers to rewrite. Verify with grep.
- `site/src/i18n/capacities.ts` — `ruleDoc` URLs for the 3 capacities. Stay pointing at `.claude/rules/<slug>.md` (rule path unchanged after split). No rewrite unless a capacity's marketing description references a moved-out section by anchor.

**Delete:**

_None._ Split disposition keeps the rule file at its existing path (thinner content); move-full and keep-as-is are NOT used in this spec. The Files-to-Delete section is empty by design.

## Alternatives considered

### Move all 3 to memory (move-full) instead of split

Rejected because each of the 3 carries a non-trivial consumer-facing slice that's actively load-bearing for the agent:

- `runtime-capabilities.md`'s matrix is the Q&A surface CLAUDE.md / AGENTS.md tell the agent to consult before assuming a runtime supports a capacity ("Consult it before assuming a `.claude/*` capability is native in a runtime" — verbatim from CLAUDE.md § *Runtime capabilities*).
- `propagation-advisory.md`'s override grammar (`# OVERRIDE: propagation-exempt: <reason ≥10 chars>`) is invoked by the agent when an advisory fires on legitimate prose — moving the grammar to memory hides it from the consumer's load path right when they need it.
- `runtime-introspect.md`'s probe output shape + `last-run.json` schema + escape hatches are the actual contract the agent reads when calling `bash .claude/tools/probe.sh last-run` to verify its own work — moving the contract to memory breaks the verify loop's discoverability.

Move-full would optimize for the maintainer-binding sections at the cost of the consumer-binding sections — the wrong tradeoff. Split honors both without forcing a choice. The cost of split is N+1 files instead of N; the diff complexity is one cross-link per pair, mechanical.

### Keep all 3 as rules unchanged (re-classify the original spec 096 audit as wrong)

Rejected because the maintainer-binding sections demonstrably exist in each file (per § *Per-file disposition* above), and shipping that content to consumers is dead-weight context noise — the original spec 096 criterion stands. The only legitimate "keep as-is" outcome would be if a re-audit showed the MB sections are themselves consumer-relevant (e.g. the inference-heuristics table teaches the agent something it acts on). They aren't — the heuristics are deep extension/internal-mechanism content. Same logic applies to all 3 files.

### Split into MORE than 2 files per rule (consumer / maintainer / archaeology)

Rejected because per-rule trifurcation introduces a new bucket axis without precedent. The 3-bucket model in `memory-placement.md` is consumer-rule vs project-memory vs per-user; a "dogfood archaeology" sub-bucket would mint a 4th and dilute the routing-tree clarity. The dogfood archaeology in each rule (e.g. the rshrnk B3 finding #6 prose in runtime-introspect) folds into the `<slug>-maintenance.md` memory entry naturally — it IS maintainer-binding background.

### Defer disposition decisions to implementation time (let `tasks.md` author judge per file)

Rejected because the cost of getting the split boundary wrong per file is a follow-up audit + edit cycle; locking the boundary in `plan.md` makes the work mechanical at tasks-time. The spec 096 lesson stands: pre-plan completeness beats in-flight judgment for atomicity work.

## Risks and unknowns

- **Cross-reference triangulation may surface boundary errors at execution time.** The audit table above is based on reading the 3 files cold; when actually doing the split, the section that gets pulled to memory may turn out to have a paragraph that's consumer-binding (or vice versa). Mitigation: implementer flags any boundary ambiguity to `notes.md` and reads adjacent cross-refs (sibling rules, hooks that comment-reference the moved sections) before splitting. If the boundary feels arbitrary mid-split, the rule itself may need to be edited to clean up the cross-bucket interleaving as part of the split.
- **`check-instruction-drift.sh` may have anchor checks beyond just file existence.** Re-read it during execution; if it greps for specific § headings inside `runtime-capabilities.md` (e.g. the status-vocabulary terms) that survive the split, no edit needed. If it greps for something that moves to memory (e.g. "Update rule" heading), the drift check needs a path update to the memory entry OR the anchor needs to migrate to the memory file with the check pointing at both. Verify with a `--check` dry-run before declaring done.
- **Propagation-advisory false-positives may worsen after split.** The rule's prose mentions `docs/specs/NNN-*/` as an example exclusion and cites `spec 027`, etc. — moving the pattern table to memory means the consumer-facing rule that survives has less context for understanding what the advisory line means. The split slice in `.claude/rules/propagation-advisory.md` MUST retain enough pattern-naming for a consumer to read the advisory line (`propagation-advisory: spec-NNN in <relpath>:<line> — <text>`) and understand the category. The split rule keeps the pattern KIND names + override grammar; the memory carries the regexes + rationale + extension contract. Verify with a synthetic advisory line in `notes.md` ("if I see this output, can I act on the rule alone?") before declaring done.
- **CLAUDE.md / AGENTS.md managed-block surgery may be a no-op AND may not.** If split keeps all 3 rules at their existing paths, the managed-block section text stays accurate as-is. But CLAUDE.md might cite a moved section explicitly (e.g. § *Drift enforcement* of `runtime-capabilities`). Read the relevant CLAUDE.md / AGENTS.md sections during Phase 3 — adjust only if literally inaccurate. Don't surgery for the sake of symmetry with spec 096.
- **The split discipline becomes a third documented bucket case** — `memory-placement.md`'s § *Why three buckets, not two* gains a §3 entry citing spec 097. That edit must define the split discipline clearly enough that the next maintainer auditing a borderline rule doesn't have to re-derive it. The clearest framing is: "when a rule mixes consumer-binding sections (override grammar, env vars, behavior the agent invokes) with maintainer-binding sections (extension contracts, internal mechanism, drift tooling), the right disposition is split into a thin consumer-facing rule + a `<slug>-maintenance.md` memory companion. Move-full only when ZERO consumer-binding content exists." This text becomes the test for the next borderline.
- **Spec 096's repo-wide grep lesson must actually be applied this time.** Phase 1 grep MUST be repo-wide-minus-(`.git`/`node_modules`/`docs/specs/`), not per-dir. The pre-flight grep above already used that shape — that's the calibration. Implementation should re-run the same shape, not regress to per-dir.

## Research / citations

- `.claude/rules/memory-placement.md` § *Routing decision tree* — the "consumer-side agent acts on it" test (added by spec 096); § *Why three buckets, not two* — the two-trigger lineage this spec extends.
- `docs/specs/096-maintainer-rules-to-memory/{spec,plan,notes}.md` — the immediate precedent; this spec inherits the rewire-completeness lesson + entrypoint discipline + frontmatter conventions.
- `.claude/memory/hook-chain-maintenance.md` — the naming precedent for `<slug>-maintenance.md` memory entries; the structural template for what a "maintainer-binding companion" looks like.
- `.claude/rules/{propagation-advisory,runtime-introspect,runtime-capabilities}.md` — the 3 source files being audited; read cold during plan drafting (2026-05-27 this session) to identify CF vs MB section boundaries per file.
- Pre-flight grep run 2026-05-27 (this `/sdd plan` invocation): 24 files cross-reference the 3 borderlines across `.claude/{hooks,tools,memory,rules,tests}/`, `CLAUDE.md`, `AGENTS.md`, `.claude/.runtime-state/README.md`, and `site/src/i18n/capacities.ts`. Surface inventoried in § *Files to touch* above.
- Conversation 2026-05-27 (this session): user surfaced `runtime-capabilities.md` as a third borderline candidate by applying the spec 096 criterion to a rule not in the original audit set; the matrix-as-Q&A defense was weighed and judged real-but-narrow, motivating the split disposition over move-full.
