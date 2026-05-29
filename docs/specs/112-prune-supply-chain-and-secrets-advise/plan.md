# 112 — prune-supply-chain-and-secrets-advise — plan

_Drafted from `spec.md` on 2026-05-29. Update this file if implementation reveals the plan is wrong; do NOT silently diverge._

**Open questions resolved (defaults adopted, 2026-05-29):**
1. Cross-ref sweep depth → **fix file-links to the deleted `supply-chain.md` + drop `supply-chain` from any NAMED gate-family exemplar list + remove prose presenting it as a live capacity; LEAVE generic "other gates" mentions that don't name supply-chain.**
2. Local `.agent0/supply-chain-audit.jsonl` → **leave as gitignored dead data; only remove the `.gitignore` entries + the writers.**

## Approach

Three independent workstreams, executed in one diff so the harness never sits in a half-pruned state. The order is **structural core first, broad sweep second, verify last** so that when the cross-ref sweep runs, the canonical files (settings, manifest behavior, docs) are already in their final shape and the sweep only has to chase textual references.

The supply-chain removal is the bulk: delete the two hooks + preflight, the rule, both test dirs, the audit-log gitignore entries, and every live reference (settings registrations, `CLAUDE.md`/`AGENTS.md`/`README.md` capacity descriptions, the perf-baseline entry + the bench harness + the latency test that name `supply-chain-preflight.sh`, and `runtime-capture.sh`'s "tokeniser-twin" comments pointing at the now-deleted preflight). secrets-advise is a narrow excision: one hook + one rule section + one settings entry; the native gate and preflight are untouched. propagation-advise is verify-only — assert its `COPY_CHECK_EXCLUDE` entries survive.

The structural/high-stakes edits (hooks, settings, manifest-adjacent, docs, perf, tests) are done by the parent. The broad textual cross-ref sweep across the remaining `.claude/rules/*.md` and `.agent0/memory/*.md` is delegated to one sub-agent with the OQ-1 policy as its contract — judgment-laden but mechanical once the policy is fixed.

## Files to touch

**Delete:**
- `.agent0/hooks/supply-chain-preflight.sh` — Bash block-on-install gate (capacity removed).
- `.claude/hooks/supply-chain-advise.sh` — Edit manifest advisory (capacity removed).
- `.claude/hooks/secrets-advise.sh` — redundant opt-in Edit advisory (commit gate is load-bearing).
- `.claude/rules/supply-chain.md` — the capacity rule.
- `.claude/tests/supply-chain/` (14 files) + `.claude/tests/supply-chain-composer/` (4 files) — capacity tests.

**Modify — settings / gitignore:**
- `.claude/settings.json` — remove the `supply-chain-preflight.sh` PreToolUse(Bash) entry, the `supply-chain-advise.sh` PostToolUse entry, and the `secrets-advise.sh` PostToolUse entry. KEEP `secrets-preflight.sh` and `propagation-advise.sh`.
- `.gitignore` — remove `.agent0/supply-chain-audit.jsonl` + `.lock` lines. KEEP `secrets-audit.jsonl`.

**Modify — docs (entrypoints + README):**
- `CLAUDE.md` — remove the `## Supply chain` managed-block section (lines ~63-66, before `## Runtime introspect`).
- `AGENTS.md` — remove the `## Supply chain` section (~43-45).
- `README.md` — remove the Supply-chain table row (~37), drop "supply-chain" from the override-marker gate list (~39), remove the "Pick supply-chain mode" checklist step (~51, renumber following steps if needed).

**Modify — perf / bench / latency (must stay mutually consistent):**
- `.claude/.perf-baseline.json` — remove the `supply-chain-preflight.sh` entry (~164).
- `.agent0/tools/bench-hooks.sh` — remove `supply-chain-preflight.sh` from `HOOK_NAMES` (~76); update comments (~19, ~74) referencing the supply-chain audit log + hook.
- `.claude/tests/hook-chain-latency/01-baseline-exists.sh` — remove `supply-chain-preflight.sh` from the asserted-hook loop (~26).

**Modify — twin-comment cleanup (file stays, refs to deleted file go):**
- `.claude/hooks/runtime-capture.sh` — drop the "tokeniser-twin with supply-chain-preflight.sh" cross-ref comments (~12-15, ~37, ~76); the tokeniser code stays (it serves runtime-introspect).

**Modify — harness-sync fixtures (keep tests honest):**
- `.claude/tests/harness-sync/05-settings-merge-additive.sh` — swap the `supply-chain-preflight.sh` fixture entry for a surviving hook; update the "4 entries" assertion comment.
- `.claude/tests/harness-sync/06-claude-md-section-append.sh` — swap the `## Supply chain` example section for a surviving one (e.g. `## Runtime introspect`).
- `.claude/tests/typecheck-advisory/07-lockfile-globs-excluded.sh` — comment-only "supply-chain lockfiles" → "dependency lockfiles" (cosmetic; optional).

**Modify — canonical memory index:**
- `.agent0/memory/capacity-spec-index.md` — remove/strike the supply-chain capacity rows.

**Modify — delegated cross-ref sweep (OQ-1 policy):**
- `.claude/rules/*.md` (harness-sync, image-gen, lint-validator, memory-placement, php-laravel-support, propagation-advisory, routines, runtime-introspect, user-prompt-framing) — drop named supply-chain exemplars / dead links.
- `.agent0/memory/*.md` (agent0-core-thesis, cc-platform-hooks, hook-chain-latency, hook-chain-maintenance, rule-load-debug, runtime-introspect-maintenance) — same policy.

**Create / append (vuln-audit direction):**
- `.agent0/reminders.yaml` — add a reminder to spec the vuln-audit capacity.
- `.agent0/HANDOFF.md` — note the direction + that 112 removed supply-chain.
- `docs/specs/112-*/notes.md` — in-flight decisions (default adoption, delegated-sweep result).

## Alternatives considered

### Remove only the advise hooks, keep the Bash block-preflight

Rejected: the founder's directive is explicit — "não limitar uso de libs". The preflight's whole job is to block `npm install` at the shell, which IS limiting lib usage. Keeping it would contradict the decision and leave a half-capacity (block with no advisory companion) that's worse than either whole.

### Build the vuln-audit capacity in the same spec

Rejected: scope. Vuln-audit needs tool research (osv-scanner vs npm audit vs pip-audit), a trigger-surface decision, and per-ecosystem coverage — a spec of its own per research-before-proposing. Bundling would balloon 112 and delay the clean removal. Recorded as direction (reminder + handoff) instead.

### Do the entire cross-ref sweep in the parent

Rejected (mild): the rule+memory textual sweep is ~15 files of mechanical "drop the named exemplar" edits. Delegating it to one sub-agent with the OQ-1 policy as a 5-field brief frees the parent for the high-stakes structural edits and is exactly the delegation capacity's use case. Parent retains the structural core (settings, docs, perf, tests) where consistency is critical.

## Risks and unknowns

- **Settings changes don't take effect until session restart.** The three removed hooks stay registered+active for the rest of THIS session. They're advisory/non-blocking (supply-chain preflight blocks installs, but we won't run installs), so no functional risk; just means the live-session test of "hook gone" must be done by inspecting `settings.json`, not by triggering the hook.
- **perf-baseline ⇄ bench-hooks ⇄ hook-chain-latency/01 must stay consistent.** All three name `supply-chain-preflight.sh`; editing one without the others breaks the latency test. Treated as one atomic sub-task.
- **harness-sync fixtures are synthetic** — they'd still PASS referencing a deleted hook, but would be dishonest. Swapping to surviving exemplars keeps them meaningful; low risk if the swap picks a hook/section that genuinely survives.
- **Consumer projects already synced** keep orphaned settings entries (additive merge doesn't prune). Documented non-goal; file deletions DO propagate via the deletion pass. No action this spec.
- **Memory edits trigger the frontmatter-validate + journal hooks.** Expected; the journal regenerates `MEMORY.md`. The delegated sub-agent's memory edits will fire these — non-blocking advisories at worst.

## Research / citations

- No external research — this is an internal capacity removal. All footprint grounded in `git grep` sweeps run 2026-05-29 (recorded in spec session).
- `.claude/rules/harness-sync.md` § *Manifest scope* / *Upstream deletions* — confirms file deletions propagate to consumers; settings entries do not auto-prune.
- `.agent0/tools/sync-harness.sh` lines 173-219 — manifest globs + `COPY_CHECK_EXCLUDE` (propagation-advise already excluded — OQ basis for verify-only).
