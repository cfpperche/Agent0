# 059 — Plan

## Approach

Single-file edit to `.claude/skills/product/SKILL.md` § Phase 0. The skill is model-orchestrated (the model reads SKILL.md and executes Phase 0's logic against the filesystem); there is no shell script to patch. So "patching" = updating SKILL.md's prose to instruct the orchestrating model differently.

Two regions of SKILL.md change:

1. **§ Phase 0 step 1 — Idempotency check.** Replace the "if `<out>` exists and is non-empty" check with a "filter harness paths, then check remaining set" check. Harness allowlist enumerated inline so the model has the list at read time.

2. **§ Phase 0 step 2 — Init.** Add a clause about `.gitignore` append-when-exists. The scaffolding step that writes `.gitignore` (currently implicit; the writes happen during Step 02's `--stack=next` skeleton or similar — exact step varies) must check existence first and append under a marker comment if so.

No reference doc updates needed — the harness allowlist is short enough to inline in SKILL.md without leaking into references.

## Files to touch

- `.claude/skills/product/SKILL.md` — § Phase 0 step 1 (idempotency check) + § Phase 0 step 2 (init) — the only behavioral change
- `docs/specs/059-product-phase0-harness-aware/{spec, plan, tasks, notes}.md` — design memory (this spec)

## Alternatives considered

**A. Add a `--allow-existing-harness` flag.** Rejected: a flag implies the founder opts in per invocation. The harness presence is detectable; making it implicit is better DX. Flag adds invocation surface noise.

**B. Use `--from-step=01` with forged `.state.json`.** Rejected (in conversation 2026-05-19): brittle. Slug computation isn't documented as a stable algorithm; small string differences cause `state mismatch`. Founder workflow shouldn't depend on probabilistic slug matching.

**C. Surgical `rm -r` that preserves harness paths.** Rejected for v1: doubles the spec scope (read manifest, build allowlist for rm, handle conflicts). Tiny scope ships now; surgical rm becomes a follow-up if re-runs over harnessed dirs become common.

**D. Move `--out=<out>/project` (subdir).** Rejected (in conversation 2026-05-19): produces nested structure (`mei-saas/.claude/` + `mei-saas/project/app/` + `mei-saas/project/docs/`) — every founder navigates two trees forever. Topology > skill convenience.

**E. Patch the install order (sync-harness AFTER /product).** This is the current workaround (`/product`-first, sync-after) but feels backwards: founder bootstraps Agent0 LAST, after /product has already scaffolded. Mental model is wrong (Agent0 is the discipline, not the icing). Spec 059 lets the natural order work.

## Risks and unknowns

- **Re-run regression.** A founder re-running `/product` on a `<out>` that has BOTH harness AND prior `/product` output triggers the existing overwrite prompt → `rm -r <out>` nukes everything including harness. Recovery is re-sync via `sync-harness.sh`. Acceptable for v1 (rare workflow); revisit if observed.
- **`.gitignore` append-marker drift.** If the marker `# --- /product (Next.js) ---` changes shape between `/product` releases, re-running `/product` on an existing project may produce duplicate sections. Mitigation: idempotency rule — before appending, scan for an existing `# --- /product` line; if found, replace the region below it. Document in Phase 0 step 2.
- **Allowlist drift.** sync-harness manifest may add a new harness file (e.g. `.envrc` someday). Spec 059's allowlist is inline in SKILL.md, so a drift means the new file would NOT be exempt → false-positive overwrite prompt. Mitigation: when sync-harness manifest is edited, audit SKILL.md allowlist too. Could pin them via a shared constants file in v2.
- **No validator test.** `/product` has no automated tests (model-orchestrated). Validation is empirical: re-bootstrap mei-saas with patched `/product`, run `/product`, confirm no overwrite prompt fires.

## Acceptance verification

Mirror each spec.md scenario into a manual test step in tasks.md:

- Scenario 1 (empty) → manual: `mkdir /tmp/test-empty && /product ... --out=/tmp/test-empty` → expect no prompt
- Scenario 2 (harness only) → manual: `sync-harness /tmp/test-harness && /product ... --out=/tmp/test-harness` → expect no prompt
- Scenario 3 (`/product` artifacts) → manual: copy a prior `/product` output to `/tmp/test-artifacts && /product ... --out=/tmp/test-artifacts` → expect prompt
- Scenario 4 (`--from-step` resume) → manual: re-run `/product` with `--from-step=05` on a partially-completed run → expect state validation, no prompt
- Scenario 5 (`.gitignore` append) → manual: bootstrap harness, run `/product`, inspect `<out>/.gitignore` → expect both harness rules AND Next.js rules present, separated by marker line
