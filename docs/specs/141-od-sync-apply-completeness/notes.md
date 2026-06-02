# 141 — od-sync-apply-completeness — notes

_Created 2026-06-02._

_In-flight design memory for this spec — decisions, deviations, tradeoffs, and open questions surfaced **while building** that weren't pre-empted by `spec.md` or `plan.md`. Append-only by convention. See `.agent0/context/rules/spec-driven.md` § The four artifacts for purpose, and `.agent0/context/rules/delegation.md` § The 5-field handoff for how sub-agents integrate._

**Entry shape:** `### YYYY-MM-DD — <author> — <one-line title>` followed by free-prose body. `<author>` is `parent` for the orchestrating agent, or the `subagent_type` (e.g. `general-purpose`, `Explore`) for delegated work.

**Routing rubric:** decision made under ambiguity → §1 Design decisions. Intentional departure from `plan.md` → §2 Deviations. Alternative weighed and chosen mid-flight → §3 Tradeoffs. Question surfaced during build, no answer yet → §4 Open questions. Sections may stay empty; the rubric is a guide, not a quota.

## Design decisions

### 2026-06-02 — parent — Pure exported cores + thin FS wrappers, matching the engine's test philosophy

The existing test file unit-tests only the pure exported functions (`computeTreeChecksum`, `validateDesignMd`, `resolveChangedVendoredScope`, `verifyManifest`); the network-bound `--apply`/`--check` are deliberately untested. I mirrored that: each of the 3 fixes extracts a pure exported function — `buildCatalogVendors`, `pinnedContentAlreadyApplied`, `scanStaleCounts` — TDD'd red→green, with the FS/network glue (`generateCatalogIndex`, `scanAllowlistStaleCounts`, the `cmdApply` rewire) left as thin untested wrappers. 16 new assertions added; suite 20→36, 0 fail.

### 2026-06-02 — parent — Stale-count regex tightened to context-specific phrasings after a false-positive on real docs

First pass used `\b(\d+)\s+(?:design\s+)?systems?\b` + `\b(\d+)\s+`?DESIGN\.md`. Running it over the real allowlist flagged 3 lines — the true target (`02-prototype/prompt.md:104` "73 `DESIGN.md`") plus 2 false positives: `SKILL.md:122` "Step 08 system-design" (matched "8 system") and `od-bridge.md:28` "shortlist 1-4 systems". A noisy advisory is an ignored advisory, so I narrowed to three precise patterns: `<N> design systems`, `available <N> systems`, `<N> [`]DESIGN.md`. Re-run flags exactly 1 line (the real one); clean after the doc fix. Precision over recall is the right call for a non-blocking nag — a missed stale "<N> entries" is cheaper than a cried-wolf advisory. (Adjusted one unit test that had relied on the bare-`systems` match.)

## Deviations

_None — implementation followed plan.md. The two-tier idempotence (fast-path + post-stage slow-path no-op) and the dual-exposure `generateCatalogIndex`/`--gen-catalog` landed as planned._

## Tradeoffs

### 2026-06-02 — parent — Live no-op fast-path is correct but masked on THIS repo by a pre-existing `skills/` tree drift

`--verify` fails on the committed state (and after a full re-apply) on exactly one path: `vendor/open-design/skills/` — the recursive skill-bundle tree. Root cause appears to be orphan files: `--apply` renames tarball files over the dst but never DELETES dst files that upstream removed, so `verifyManifest` (which walks the on-disk dst) hashes orphans the tarball-derived tree checksum doesn't include → permanent drift. This is the residue of the original advance's "manual workaround + hand-run regen" the spec § Intent references. Consequence: the fast-path (gated on `verifyManifest` passing) never fires on this repo, so every `--apply` here falls to the slow-path full reconcile — CORRECT (produced byte-identical vendored content, zero git diff on `design-systems/`/`skills/`) but not cheap. The fast-path is validated by unit tests and will engage on any repo with clean verify. I did NOT expand scope to fix orphan-cleanup (see Open questions) — spec 141's Non-goals and the named-2-bugs framing are firm.

## Open questions

### 2026-06-02 — parent — Orphan-file cleanup on `--apply` (out of scope for 141) — founder call

Discovered while validating: `--apply` leaves dst files that upstream deleted (a recursive tree never prunes orphans), which keeps `vendor/open-design/skills/` permanently failing `--verify`. This is a THIRD engine correctness gap, distinct from the 2 spec 141 targets (idempotence, catalogue regen). Fixing it = "delete dst files not present in the staged set before/with Phase B" — a small, well-bounded change. Owner: founder. Path: either a fast-follow spec (142) or a scope amendment to 141. Recommend a separate spec to keep 141's diff reviewable and its acceptance criteria honest. NOT blocking the 141 deliverable — the named bugs are fixed and validated.
