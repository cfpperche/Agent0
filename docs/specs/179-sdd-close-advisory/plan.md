# 179 — sdd-close-advisory — plan

_Drafted from `spec.md` on 2026-06-09. Update this file if implementation reveals the plan is wrong; do NOT silently diverge._

## Approach

Build a read-only checker `.agent0/tools/sdd-close.sh` that, for a shipped/`shipped-partial` spec, computes four static closure findings — `tasks-unchecked`, `acceptance-unchecked`, `placeholders`, `missing-closure` — and reports them (human default, `--json` machine). It mirrors `spec-verify.sh` (spec 177) line-for-line in structure: same arg-parsing shape, same repo-root resolution, same exit-code discipline (`0` clean / `1` findings / `64` usage), bash-3.2-safe, never writes. Then extend `.agent0/validators/run.sh` with a `sdd-close-advisory:` pass placed adjacent to (and modelled on) the existing spec-verify-advisory block — stderr-only, before stack detection, never touching `ok`.

The load-bearing design is the **noise split** (resolved OQs locked below):

- **Tool = full audit.** Run on demand over the whole corpus or one spec; reports every finding regardless of age. Intentional invocation ⇒ no nag problem.
- **Validator advisory = opt-in via `**Closure:**`.** Only a shipped spec that declares a `**Closure:**` line (formally closed under the modern discipline) is checked; if its artifacts contradict that assertion (unchecked tasks/acceptance or surviving placeholders) one aggregated advisory fires. Specs without a closure line are never nagged. No recency, no date math, no git dependency.

**Design pivot during implementation** (the dogfood overturned the original recency plan — recorded in `notes.md` § Design decisions): a rolling recency window was built first and rejected for two reasons the live corpus exposed — (1) Agent0 ships ~4 specs/day, so even a 14-day window captured ~80 specs; (2) the closure convention is brand-new, so every pre-convention spec tripped `missing-closure`. Git mtime was also tried and rejected — Agent0 is a consolidation repo where all specs share the bulk-migration commit date `2026-05-25`, so git mtime cannot separate fresh from legacy. The `**Closure:**` line is the only honest, self-scoping signal and it exactly mirrors spec-verify's `**Verify:**` opt-in. Verified silent (0 advisories) on the live corpus.

Placeholder detection strips inline `` `code` `` spans before scanning for `{{`, so a spec that merely *discusses* template syntax (177/178/179 themselves) is not a false positive — only an unfilled scaffold placeholder in bare prose counts.

Resolved open questions (locked after the dogfood): **OQ1** = recency dropped entirely. **OQ2** = `missing-closure` is NOT an advisory finding (it is the opt-out signal); tool-only. **OQ3** = one aggregated advisory line per spec.

## Files to touch

**Create:**
- `.agent0/tools/sdd-close.sh` — the read-only auditor (arg parse; per-spec finding computation; human + `--json` output; exits 0/1/64).
- `.agent0/context/rules/sdd-close.md` — rule doc (frontmatter `paths:`; lead + spec ref; H2s: the four findings / the tool / the advisory + opt-in-via-Closure noise model / opt-out / consumer-extension note).
- `.agent0/tests/sdd-close/run-all.sh` (+ numbered scenario scripts) — fixture-driven suite covering all acceptance scenarios.

**Modify:**
- `.agent0/validators/run.sh` — add the `sdd-close-advisory:` pass after the spec-verify block (same guard shape; opt-in via `**Closure:**`; `CLAUDE_VALIDATOR_SKIP_SDD_CLOSE` opt-out).
- `CLAUDE.md` + `AGENTS.md` — managed-index entry in the `## Spec verify advisory` style.

**Delete:** none.

## Alternatives considered

### Single always-on advisory over all shipped specs (no recency gate)

Rejected — this is the noise trap. ~160 legacy shipped specs carry residual unchecked boxes by design ("the earliest specs keep their flat-checklist shape"); nagging them all turns the validator into spam and re-creates the speculative-observability anti-pattern the project explicitly rejects (`feedback_speculative_observability`). The recency gate is the whole reason the advisory is shippable.

### Recency window (rolling N-day gate on _Created or git mtime) — TRIED, then rejected

This was the *original* plan and it was implemented and dogfooded before being discarded. Two independent failures the live corpus exposed: (1) Agent0's ~4-spec/day cadence means a 14-day window still captures ~80 specs — not narrow; (2) the closure convention being brand-new, every pre-convention spec trips `missing-closure`, so the window floods regardless. Git mtime as the recency source failed separately (consolidation repo → all specs share one migration-commit date). Recency is the wrong axis here; **opt-in via `**Closure:**`** is the right one (chosen), and it happens to need zero date/git machinery.

### Opt-in, but on a dedicated new marker instead of reusing `**Closure:**`

Rejected — `**Closure:**` already *means* "this spec has formally closed with this evidence." Checking that the artifacts back that assertion is the natural consistency check; a second marker would be redundant ceremony. Reusing the existing convention is why this advisory ships as pure validator prose with no new declaration.

### Auto-fix (check the boxes / write the Closure line)

Rejected — destructive and presumptuous. Checking a box asserts the work is done; only the author knows that. The tool surfaces; the human closes. Advisory-only is the doctrine.

## Risks and unknowns

- **`missing-closure` false-positive risk:** the closure line is *optional* by convention, so flagging its absence could feel like forced ceremony. Mitigated by recency-scoping (only fresh specs) + it being the softest finding; if dogfood shows it nags, OQ2's lean is reversible (drop missing-closure from the advisory, keep it in the on-demand tool). Documented as the one to watch.
- **Git dependency:** recency needs `git log`. Degradation path (placeholder-only) is specified and tested, so a git-less consumer checkout degrades quietly rather than flooding or erroring.
- **Acceptance-box counting:** must count `- [ ]` only under `## Acceptance criteria` in spec.md (not Open-questions boxes). Same parsing care as `/sdd list`'s N/M counting; covered by a fixture with both sections.
- **No mechanical proof of the rule prose** — acceptance for the rule doc is read-through; the *tool + advisory* behavior is fully test-covered, which is where the real risk lives.

## Research / citations

- `.agent0/tools/spec-verify.sh` and `.agent0/validators/run.sh` lines 26-55 — the mirrored idiom (read this session; structure copied deliberately).
- `.claude/skills/sdd/SKILL.md` § list — `CLAUDE_SDD_IN_FLIGHT_RECENCY_DAYS` 14-day window reused as the noise-control precedent.
- Spec 177 (`docs/specs/177-spec-verify-advisory/`) — sibling advisory; sdd-close is its static-consistency complement.

## Scope-admission classification (governance doctrine)

- **Layer:** first-party capacity — a new tool + a validator advisory surface (not a rule-only change).
- **Ownership boundary:** Agent0-owned; ships to consumers via `sync-harness`; advisory is consumer-relevant (keeps any project's closure honest).
- **Evidence:** the 177 unchecked-tasks defect is a concrete, in-corpus motivating case (not speculative); the closure convention it checks already shipped (`d6da13c`).
- **v1 posture:** read-only, advisory-only, recency-scoped, no auto-fix, no blocking. Strictly additive.
- **Blast radius:** validator emits one extra stderr line class for *recent* shipped specs only; `ok`/exit untouched; opt-out env var. Reversible by `git revert`.
- **Validation:** `.agent0/tests/sdd-close/` green; `doctor.sh` green; self-dogfood the tool over the live corpus.
- **Non-goals:** enumerated in `spec.md` § Non-goals (no verify duplication, no gate, no legacy nag, no auto-fix, no new schema).
