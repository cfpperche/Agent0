# 009 — supply-chain-block — plan

_Drafted from `spec.md` on 2026-05-11. Update this file if implementation reveals the plan is wrong; do NOT silently diverge._

## Approach

Modify the existing `.claude/hooks/supply-chain-scan.sh` (spec 008) in-place to add a **block-by-default mode** with the existing advisory path preserved as an env-gated opt-out. Single hook, two modes — the parse / tokenize / override-extract / audit-write pipeline is unchanged; only the *exit code* and the *stderr emission* branch on mode at the end. This is a much smaller intervention than the secrets-scan precedent (006 was greenfield; 009 is a delta to a hook that already exists and is now well-trusted after two live-dogfood passes).

Mode resolution at hook entry:
- `CLAUDE_SKIP_SUPPLY_CHAIN_SCAN=1` → exit 0 silently, no audit (existing behaviour, takes precedence over everything else)
- `CLAUDE_SUPPLY_CHAIN_BLOCK=0` → advisory mode (the spec 008 behaviour, decision values `advisory` / `advisory-override`)
- Default OR `CLAUDE_SUPPLY_CHAIN_BLOCK=1` OR any other value → block mode (decision values `block` / `block-override`)

The default-on-when-unset-or-noise shape is defensive: a typo in the env var name (`CLAUDE_SUPPLY_CHAIN_BLCOK=0`) should leave the discipline ON, not silently OFF. Symmetric reasoning to why `CLAUDE_SECRETS_OVERRIDE_REASON` requires explicit non-empty content to take effect.

In block mode, when a `(manager, verb, packages)` triple is detected:
1. **No override marker present** → emit the corrective stderr template, audit `decision: "block"` with `override_reason: null`, exit 2
2. **Override marker present, reason ≥10 chars** → silent, audit `decision: "block-override"` with `override_reason` populated, exit 0
3. **Override marker present, reason <10 chars** → emit the *short-reason* corrective stderr template, audit `decision: "block"` with `override_reason: <the too-short string>` (forensics preserved), exit 2

In advisory mode the existing 008 paths run unchanged — decision values `advisory` / `advisory-override` are preserved exactly to keep existing `jq` queries against `.claude/supply-chain-audit.jsonl` valid.

The stderr template is structured so the last lines are the **verbatim corrected form** the agent can copy-paste — same contract as secrets-scan's stderr templates (issue #24327 mitigation, see `.claude/rules/secrets-scan.md` § *Gotchas*). Two templates ship:

```
supply-chain-block: <manager> <action> detected — packages: <pkgs>

Dep installs require documented intent in block mode. Either re-run with an
override marker (reason ≥10 chars on its own line), or opt out of block mode
for this session: CLAUDE_SUPPLY_CHAIN_BLOCK=0 (advisory only) or
CLAUDE_SKIP_SUPPLY_CHAIN_SCAN=1 (full disable).

Corrected form:
  <original-command-line>
  # OVERRIDE: <reason ≥10 chars — why this dep is being added>
```

```
supply-chain-block: override reason must be ≥10 characters, got "<reason>"

Corrected form:
  <original-command-line>
  # OVERRIDE: <reason ≥10 chars — why this dep is being added>
```

Both end with the exact two-line shape (original command + OVERRIDE marker placeholder), so the agent's next-turn pattern match has unambiguous input to act on without re-deriving the intent.

Order of implementation is dependency-respecting and TDD-shaped: (1) write 4 new failing scenario tests (block-default, block-override-valid, block-override-too-short, advisory-opt-out); (2) patch the hook with the mode resolver + branching; (3) verify all 11 tests pass (7 existing as regression guards + 4 new); (4) update the rule doc with the new mode section and audit-log table extension; (5) update CLAUDE.md and README per-fork checklist; (6) tick spec boxes and commit.

## Files to touch

**Create:**
- `.claude/tests/supply-chain/08-block-default.sh` — block mode + no override = exit 2, stderr template, `decision: "block"`
- `.claude/tests/supply-chain/09-block-override-valid.sh` — block mode + valid override = exit 0, no stderr, `decision: "block-override"`
- `.claude/tests/supply-chain/10-block-override-too-short.sh` — block mode + too-short override = exit 2, short-reason stderr template, `decision: "block"` with `override_reason` populated
- `.claude/tests/supply-chain/11-advisory-opt-out.sh` — `CLAUDE_SUPPLY_CHAIN_BLOCK=0` + dep install (with/without override) = spec-008 paths intact

**Modify:**
- `.claude/hooks/supply-chain-scan.sh` — mode resolver near top (post-`CLAUDE_SKIP_*` check), new block branches in Phase 5 (Decision), two new stderr template strings as heredocs
- `.claude/rules/supply-chain.md` — § *What fires, what advises* updated to describe block-by-default; new § *Block vs advisory mode* (mode resolution table, decision-value matrix); § *Audit log* table gains `block` and `block-override` rows; § *Override grammar* updated to note the ≥10-char rule is now *enforced* in block mode (no soft-degrade); § *Escape hatch* gains the `CLAUDE_SUPPLY_CHAIN_BLOCK=0` opt-out; § *Gotchas* updated for the new default (first-fork friction, copy-paste contract)
- `.claude/tests/supply-chain/run-all.sh` — loop extended to `01 02 … 11`
- `CLAUDE.md` § *Supply chain* — single-sentence change reflecting block-by-default + the new env var (≤2 sentences of marginal text per spec)
- `README.md` — per-fork checklist gains one bullet on `CLAUDE_SUPPLY_CHAIN_BLOCK=0` opt-out
- `.claude/tests/supply-chain/01-bash-install-advisory.sh` (and tests 02, 05) — prepend `export CLAUDE_SUPPLY_CHAIN_BLOCK=0` to keep them regression guards for advisory-mode behaviour under the new default

**Delete:** none.

## Alternatives considered

### Separate hook script `supply-chain-block.sh` instead of in-place patch

Rejected. Two hooks running on the same `PreToolUse(Bash)` matcher would each fire on every Bash invocation, doubling the parse / tokenize / jq cost (~20-60ms per call) and forcing duplicate audit-row logic — either two rows per Bash (bloated log) or coordinated suppression (fragile). The existing hook already has 100% of the detection plumbing; adding a mode branch at the decision stage is ~30 LOC vs ~250 LOC for a parallel hook. Single source of truth for tokenization and audit row shape stays a hard requirement.

### Opt-in by default (block off, fork explicitly enables)

Considered seriously, rejected with user. Live-dogfood passes against pyshrnk and shrnk would have continued surfacing tokenizer bugs forever if the capacity were opt-in — the dogfood agents never proactively enabled the advisory either; it was on by default in 008, which is how the bugs surfaced. Block-by-default extends the same "trust the default, opt out for throwaway" philosophy that 006 secrets-scan established (`CLAUDE_SKIP_SECRETS_SCAN=1` is the escape, not the default).

### Soft-degrade short override reasons to advisory (preserve spec 008 behaviour)

Rejected — would create a footgun. Under spec 008's advisory-only nature, `# OVERRIDE: skip` silently degraded to a regular advisory because there was nothing to gate against. Under block mode, the SAME marker shape silently allowing the install would mean "type any short word to bypass the block" — exactly the kind of soft-edge erosion the secrets-scan ≥10-char floor exists to prevent. Block mode hard-enforces ≥10 chars matching secrets-scan precedent; the spec-008 behaviour is preserved only when explicitly running in advisory mode.

### Distinguish "no override" from "override too short" with separate decision values (`block` vs `block-override-too-short`)

Rejected for now. Both shapes end in the same outcome (exit 2 + corrective template); the difference is purely forensic. Recording `decision: "block"` with `override_reason` populated (for too-short) vs `null` (for missing) gives forensic queries a clean discriminator (`jq 'select(.decision == "block" and (.override_reason | length // 0) > 0)'`) without adding a new decision value to every reader's mental model. If real-session forensics demand it later, splitting is a non-breaking change.

### Lockfile-diff parsing to skip blocks on dep version bumps (only block new deps)

Rejected (also a non-goal in spec). Same reasoning as 008's rejection of this alternative: lockfile shapes vary across npm/pnpm/yarn/bun versions and break across major releases; running `git diff -- package-lock.json | jq` per hook firing adds ~100-500ms latency and brittle parsing. The override marker is the right tool for "yes I know, this is a deliberate bump" — same shape as for new deps.

### Add a `mode` field to audit rows for forensics

Rejected (also a non-goal in spec). The decision values already encode the mode unambiguously (`block` / `block-override` ⇒ block mode, `advisory` / `advisory-override` ⇒ advisory mode). Adding a `mode` field would either duplicate that signal or invite the trap of letting them disagree (e.g. `mode: "block"` with `decision: "advisory-override"` — what does that mean?). The `--arg mode "$mode"` per-row jq call would also burn a noticeable fraction of total hook latency for zero new information.

## Risks and unknowns

- **First-fork friction.** Unlike spec 008's advisory mode (which never blocks), block mode will surprise a fresh fork the moment its first `npm install <pkg>` lands. The mitigation is documentation density: README per-fork checklist explicitly names the opt-out, CLAUDE.md § *Supply chain* names it again, the stderr template itself names both opt-outs verbatim. A user who reads the template once knows the escape, the same way `git commit -a` rejection teaches the corrected form.
- **Stderr template length and noise.** The current advisory line is one line (~80 chars). The block template is ~10 lines including the corrected form. That's a one-time cost per blocked command — fine — but if a sub-agent gets stuck in a loop trying to install (post-edit-validator iteration), the multiline templates inflate the agent's next-turn context. Mitigation: the loop budget cap in `.claude/rules/delegation.md` already limits the iteration count.
- **Existing forks updating to the new harness.** A fork on the current main with the spec 008 advisory will pick up block-by-default the moment they `git pull`. The SESSION.md note from this session is the migration breadcrumb, but a fork that ignores SESSION.md will get a surprise block on their next install. Acceptable — the override marker is one line; the env-var opt-out is one shell line. The README per-fork checklist update names the upgrade hint.
- **Short-reason audit-row consistency.** Decision is `block` (same as no-override-at-all) but `override_reason` is populated with the rejected short string. Forensic queries must use `(.override_reason | length // 0)` to discriminate — straightforward but worth documenting in the rule doc so post-hoc analysis doesn't conflate the two.
- **Override-marker bridge to subsequent commands.** Unlike secrets-scan (which uses the `CLAUDE_SECRETS_OVERRIDE_REASON` env-var bridge to pass the marker reason from preflight to the native git hook), the supply-chain hook has no downstream layer that needs to read the reason — block decision is final at the preflight. So no bridge needed; the override marker affects ONLY the audit row's decision and `override_reason` field, identical to spec 008's `advisory-override` semantics.
- **Test isolation under the new default.** Existing tests 01-07 run with the default env (no `CLAUDE_SUPPLY_CHAIN_BLOCK` set), which under the new default means *block mode*. Test 01 (`bash-install-advisory`) currently asserts `decision: "advisory"` — it WILL break under the new default unless explicitly set to advisory mode. Plan: tests that assert advisory-mode behaviour (01, 02, 05 — the ones whose canonical case fires an advisory) get `CLAUDE_SUPPLY_CHAIN_BLOCK=0` exported at the top so they remain regression guards. Tests 03 (Edit advisory), 04 (parent edit silent), 06 (env-var disable), 07 (tokenizer shape) don't depend on mode and stay as-is.

## Research / citations

- `.claude/hooks/supply-chain-scan.sh` — current 008 hook; the in-place modification target. Phase 5 (Decision) is the only stage that gets new branches.
- `.claude/hooks/secrets-scan.sh` — precedent for the corrective stderr-template-as-contract pattern (issue #24327 mitigation). The two-template shape (no-override vs too-short) is copied wholesale.
- `.claude/rules/secrets-scan.md` § *Gotchas* — Claude Code issue #24327 note (stderr ingestion on exit-2 blocks). Same mechanic applies here.
- `.claude/rules/supply-chain.md` — current advisory discipline; sections § *What fires*, § *Override grammar*, § *Audit log*, § *Escape hatch*, § *Gotchas* all extend, none are rewritten.
- `docs/specs/006-secrets-scan/plan.md` — alternatives-considered shape and depth precedent; this plan mirrors it.
- `docs/specs/007-secrets-scan-timing/` — the timing-correctness pattern (native hook + preflight cooperation). Not applicable here because supply-chain has no native counterpart to coordinate with; preflight is the sole layer.
- Live-dogfood sessions 2026-05-11: pyshrnk uv pass (`docs/specs/008-supply-chain-scan/spec.md` + commits b730b63, 6b0ea3e) and shrnk bun pass (this session's transcript) — provided the detection-trust evidence that justifies promotion from advisory to block.
