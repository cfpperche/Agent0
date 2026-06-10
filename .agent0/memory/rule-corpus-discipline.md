---
name: rule-corpus-discipline
description: Maintainer discipline for the rules corpus — register split on touch,
  mechanism-or-demand admission for new rules, prose→gate promotion. Read before
  adding a rule or editing a large one.
metadata:
  type: project
  created_at: '2026-06-09T21:55:00-03:00'
---

# Rule-corpus discipline

Adopted 2026-06-09 (spec 185, point P4 — chosen over a big-bang numeric diet, which was withdrawn as over-engineering under the lab-posture decision). Two habits plus a promotion principle. Like [[propagation-hygiene]], this binds the Agent0 maintainer and therefore lives in memory, not in a shipped rule.

## B1 — Register split, applied on touch

A rule file mixes two registers: **operative instruction** (what an agent must do — the control plane) and **design memory** (rationale, history, retired alternatives, dogfood evidence — why it is so). The second register grows without bound and is where coupled-prose contradictions breed (the delegation↔artifact-budgets cascade contradiction lived 3 weeks in a rationale section). Discipline: **whenever you touch a rule, extract non-operative register in passing** — move rationale/history to a memory entry (or delete it if git history already records it), leave the rule operative. Never a dedicated sweep; always in passing, like the propagation-hygiene cleanup convention.

## B2 — Admission bar for new rules

A new rule file is born only if at least one holds: (a) a mechanism backs it (hook, validator, gate, template — something that fails loudly), or (b) demonstrated demand (rule-of-three, dogfood failure, recurring drift). Otherwise the content is documentation (`docs/`) or maintainer memory — not control plane. This extends the governance doctrine's admission checklist down to the rule-file level.

## C — Prose→mechanism promotion principle

Mandatory prose whose corresponding advisory empirically fires on real cases gets promoted to a mechanism (gate/validator), and the prose shrinks to a pointer. This generalizes the propagation-advisory promotion policy ("advisory fires >~3×/week on legitimate leaks → promote to pre-commit gate") to the whole corpus. The inverse also applies: prose mandates whose mechanism was retired must be shrunk or deleted with the mechanism (the cascade lesson).

## Seed backlog (2026-06-09 audit of the 39-rule corpus, 417 KB)

**Move-whole candidates — maintainer-only content currently shipped:**
- `agent0-governance-doctrine.md` + `scope-admission-governance.md` — both bind whoever expands *Agent0*, are written Agent0-specific ("expanding Agent0 capacities"), and have **no hook wiring** (verified: governance-gate.sh is the destructive-ops floor, unrelated; no hook/skill references either file). In a consumer they are inert-to-confusing. Moving them is a small *coordinated* change, not an in-passing edit: relocate to memory + remove their CLAUDE.md/AGENTS.md managed-block sections + fix cross-refs from other rules + accept consumer residue (append-only CLAUDE.md merge keeps the stale section; whole-file-synced rule copies need manual removal on the 3 consumers). Execute on request or when next touched.

**Register-split candidates — stay rules, shed design memory on next touch:**
- `harness-sync.md` (62 KB — maintainer-register sections: baseline regeneration, manifest editing rationale)
- `delegation.md` (26 KB — spec-lineage history notes)
- `memory-placement.md` (26 KB — audit-outcome narrative)
- `secrets-scan.md` (20 KB — version-skew/dropped-signal history)

**Checked and NOT candidates (audience verified consumer-facing):** `post-launch-maintenance-loop.md` (explicitly instrument-only, addressed to consumer projects), `php-laravel-support.md` (orientation index for Laravel consumers), `propagation-advisory.md` (already sync-excluded via `COPY_CHECK_EXCLUDE` — the precedent this discipline generalizes), `runtime-capabilities.md` (its maintainer register already lives in [[runtime-capabilities-maintenance]] — the pattern done right).

## Review trigger

If the corpus keeps growing despite this discipline (say, >45 rules or >450 KB six months from adoption), the withdrawn numeric-target diet returns to the table with evidence.
