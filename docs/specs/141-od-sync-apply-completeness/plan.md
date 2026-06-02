# 141 — od-sync-apply-completeness — plan

_Drafted from `spec.md` on 2026-06-02. Update this file if implementation reveals the plan is wrong; do NOT silently diverge._

## Approach

Three fixes inside the single engine file `.claude/skills/product/scripts/sync-open-design.ts`, all keeping the existing two-phase atomic `--apply` shape intact. The unifying idea: the idempotence gate and the catalogue regen are both made *content-true* — they answer "is on-disk really equal to the pinned content?" and "does every pipeline-facing index reflect the current system set?" instead of trusting the stale manifest.

**Fix 1 — content-true idempotence (acceptance 1/2/3).** Today the gate (lines ~430-441) compares on-disk file hashes against `vp.checksum` (the manifest's *last-recorded* checksum) and blind-skips recursive trees (`if (vp.recursive) continue`). After a `--bump` the manifest checksums still describe the OLD pin, so the gate fires a false "already in sync" and the advance is impossible without perturbing a file (the spec-135 workaround). The fix replaces the early gate with a **two-tier decision**:

- **Cheap fast-path no-op (no download):** if `verifyManifest(manifest, SKILL_ROOT)` passes (on-disk == manifest checksums for *all* paths, trees included — `verifyManifest` already does recursive tree-checksums correctly) AND the most recent `history` entry with `event === 'apply'` has `sha === manifest.pinned_sha`, then on-disk content == content-at-pinned-sha by transitivity → print `no-op (already in sync)` and return. This is the common "re-run `--apply` right after a successful apply" case and costs zero network. The MANIFEST history already records the apply sha (confirmed: the c128ffd5 apply event is present), so the check is a cheap local read.
- **Correct slow-path:** otherwise (a `--bump` moved `pinned_sha` away from the last apply, OR `verify` shows on-disk drift) we cannot decide cheaply — download + extract + stage Phase A as today, then derive `alreadyInSync` by comparing each **staged** checksum (the would-be content at the new pin, header-included, tree-aware via `computeTreeChecksum`) against the **on-disk** checksum. If every path matches → no-op, tear down staging, skip Phase B. Otherwise proceed to Phase B reconcile exactly as today. The `if (vp.recursive) continue` blind-skip is deleted; trees are content-compared through the staging digests.

This resolves OQ3 (no-op stays cheap via the fast-path; the slow path only runs when a real decision is needed, and the tarball is already cached at `tarball-<sha>.tar.gz` so even repeated slow paths don't re-download).

**Fix 2 — regenerate the pipeline-facing catalogue (acceptance 4).** Add a `generateCatalogIndex(pinnedSha)` function mirroring the existing `generateDsIndex`, porting the proven logic from the one-off `/tmp/gen-catalog.py`: read the freshly-written `.cache/ds-index.json`, load the existing `references/od-catalog-index.json` into a by-name map, and for each system **preserve a curated entry verbatim** (category / mood / palette_primary) or **add a new one mechanically** (`category` from the DESIGN.md `> Category:` line, `mood` + first `palette_summary` hex from the ds-index). Sort by name, write back with the same `{version, snapshot_date, source, vendors}` shape. Call it in `cmdApply` immediately after `generateDsIndex(sha)`, and — following the established `generateDsIndex` / `--gen-ds-index` dual-exposure pattern — also expose a standalone `--gen-catalog` CLI flag for bootstrap/repair. This resolves OQ1 (not either/or: do both, exactly as `generateDsIndex` already is both apply-wired and standalone).

**Fix 3 — stale-count advisory (acceptance 5).** Add a non-blocking stale-count scan at the end of `cmdApply`: grep a fixed allowlist of tracked doc files (`SKILL.md`, `templates/pipeline/02-prototype/{prompt.md,references/od-bridge.md}`, `templates/pipeline/14-design-system/prompt.md`) for `\b(\d+)\s+(?:design\s+)?systems?\b` / `(\d+)\s+DESIGN\.md` patterns, and list any line whose number != the current catalogue count in the apply report under a `## Stale count advisory` section. Reports only — never edits docs, never fails the apply. This is the in-engine mechanism the spec's criterion-5 "OR the apply report flags the stale-count doc lines" half asks for. (Verified the need: the 73→150 hand-fix already missed `02-prototype/prompt.md:104` — "73 `DESIGN.md` directories" is live and stale right now.) The companion editorial de-hardcoding of those strings is a tasks-level doc cleanup, not engine code.

OQ2 (collapse to a single index, deleting `od-catalog-index.json`) is **rejected** — see Alternatives.

## Files to touch

**Create:**
- _(none — no new files; the engine gains functions + a flag, not modules)_

**Modify:**
- `.claude/skills/product/scripts/sync-open-design.ts` — (a) replace the idempotence gate in `cmdApply` with the two-tier fast-path/slow-path decision (reuse `verifyManifest` + history scan for the fast path; compare staged-vs-on-disk for the slow path; delete `if (vp.recursive) continue`); (b) add `generateCatalogIndex(pinnedSha)` + call it after `generateDsIndex(sha)` in `cmdApply`; (c) add the `--gen-catalog` CLI branch in `main`; (d) add the stale-count scan + `## Stale count advisory` section to the apply report.
- `.claude/skills/product/scripts/sync-open-design.test.ts` (or the engine's existing test file — confirm exact path at tasks time) — unit tests for `generateCatalogIndex` (preserve-curated + mechanical-new), the slow-path staged-vs-on-disk idempotence, the recursive-tree content compare, and the stale-count scan.
- `.claude/skills/product/templates/pipeline/02-prototype/prompt.md` — de-hardcode the stale "73 `DESIGN.md` directories" string (→ "the vendored systems catalogued at `references/od-catalog-index.json`"); the load-bearing example of the criterion-5 doc drift.
- Other doc strings flagged by the new advisory (e.g. any remaining `02-prototype/references/od-bridge.md`, `14-design-system/prompt.md` count lines) — de-hardcode where the phrasing allows; let the advisory carry the rest.

**Delete:**
- `/tmp/gen-catalog.py` — superseded once its logic lands in `generateCatalogIndex`; it was always a session-scratch reference impl, not tracked.

## Alternatives considered

### OQ1 — separate `--gen-catalog` subcommand the apply invokes *instead of* an in-engine call

Rejected as an *either/or*. The codebase already answers this: `generateDsIndex` is BOTH called at the end of `cmdApply` AND exposed standalone via `--gen-ds-index`. Mirroring that for the catalogue (in-apply call + `--gen-catalog` flag) is the lowest-surprise, pattern-consistent choice. A standalone-only flag would re-introduce the exact "apply leaves the pipeline index stale" bug for anyone who forgets the second command.

### OQ2 — collapse to one index: pipeline reads `.cache/ds-index.json` directly, delete `od-catalog-index.json`

Rejected. It would erase the two-index problem but lose the curated fields the pipeline actually consumes — `category` (step 14 reads it to group systems) and the human-named `palette_primary` ("Rausch (#ff385c)" vs a bare `#ff385c`). The spec's Non-goals explicitly preserve the mechanical-vs-curated split ("A later quality pass can enrich them; mechanical is the functional floor"), and collapsing would force edits into the pipeline step templates (02-prototype, 14-design-system) — out of scope for "make the existing engine correct." Keep both; regen the curated one preserving curation.

### Idempotence fix — always download + stage, no fast-path

Rejected as the *primary* path but kept as the slow-path fallback. Downloading on every `--apply` (even a pure re-run) is the cost OQ3 flags. The fast-path (`verify` passes AND last-apply-sha == pinned_sha → no-op without network) makes the common re-run free, while the slow path stays correct for the post-bump case. The tarball cache already removes repeat-download cost, so the fast-path is a latency/clarity win, not a correctness requirement — if it proves fiddly at implementation time, falling back to "always stage, compare staged-vs-on-disk, rely on the tarball cache" is acceptable and still correct.

### Criterion 5 — fully de-hardcode all counts, no advisory

Rejected as insufficient on its own. De-hardcoding the ~6 known strings fixes today's drift but gives no guard against the *next* count change re-introducing stale strings. The engine advisory is the durable mechanism; de-hardcoding is the one-time cleanup. Doing both is belt-and-suspenders and matches the spec's "EITHER … OR …" by satisfying the stronger reading.

## Risks and unknowns

- **Test fixture path / framework** — the engine is `bun`-run; need to confirm the existing test file name and that fixtures can drive `cmdApply`'s staging without real network (the staged-vs-on-disk compare must be unit-testable against a fixture extract dir). Confirm at tasks time before writing tests.
- **Fast-path correctness hinges on history integrity** — if the manifest `history` were hand-edited so the last `apply` sha lies, the fast-path could false-positive a no-op. Mitigated because the fast-path *also* requires `verifyManifest` to pass (on-disk == recorded checksums); a lying history with drifted disk still falls to the slow path. A lying history with on-disk matching the recorded checksums but NOT the pinned content is only reachable by manual manifest corruption — out of the threat model (pin advance is a deliberate founder action).
- **`> Category:` line absence for new systems** — `generateCatalogIndex` falls back to `"Uncategorized"` (matches `/tmp/gen-catalog.py`); acceptable mechanical floor per Non-goals.
- **Stale-count regex false positives** — a doc line like "took 150 systems engineers" would wrongly flag. Mitigated by scoping to a fixed allowlist of OD-related doc files and requiring the `systems`/`DESIGN.md` noun adjacency; the advisory is non-blocking so a false flag costs only a noisy report line.

## Research / citations

- `.claude/skills/product/scripts/sync-open-design.ts` — read in full this session: idempotence gate (lines 429-446), `cmdApply` Phase A/B (414-609), `computeTreeChecksum` (100-103), `verifyManifest` (690-705), `generateDsIndex` (747-789), CLI dispatch (793-821) — the `--gen-ds-index` precedent for the dual-exposure decision.
- `/tmp/gen-catalog.py` — the proven preserve-curated + mechanical-new reference impl for `generateCatalogIndex`.
- `.claude/skills/product/references/od-catalog-index.json` — confirmed `{version, snapshot_date, source, vendors[]}` shape with `{name, category, mood, palette_primary, vendor_path}` entries.
- `.claude/skills/product/vendor/open-design/MANIFEST.json` § history — confirmed the c128ffd5 `apply` event is recorded, validating the fast-path's last-apply-sha check.
- `5233ab3` — the OD pin advance commit that surfaced both bugs and documents the manual workaround.
- `docs/specs/135-od-design-md-validator-drift/` — prior engine spec whose dogfood perturbed a file *because* of this idempotence gate; 141 fixes that root cause.
- Live drift evidence for criterion 5: `templates/pipeline/02-prototype/prompt.md:104` still reads "73 `DESIGN.md` directories" after the 73→150 advance.
