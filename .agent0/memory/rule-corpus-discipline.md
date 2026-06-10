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

## B2 — Admission bar for new rules: the audience test

**Sharpened by the maintainer 2026-06-09:** the primary criterion is *audience* — **consumer-facing content becomes a rule; everything else becomes memory or a gate.** The rules dir IS the shipped control plane; nothing non-consumer-facing ships from it. Test: "would an agent working in a *consumer* project act differently after reading this?" If no → maintainer memory (discipline, Agent0-only mechanism docs, design rationale) or a mechanism (hook/validator/gate) if it must be enforced. Secondary bar, for content that passes the audience test: prefer mechanism-backed or demand-backed (rule-of-three, dogfood failure, recurring drift) over plausible-but-speculative prose.

## C — Prose→mechanism promotion principle

Mandatory prose whose corresponding advisory empirically fires on real cases gets promoted to a mechanism (gate/validator), and the prose shrinks to a pointer. This generalizes the propagation-advisory promotion policy ("advisory fires >~3×/week on legitimate leaks → promote to pre-commit gate") to the whole corpus. The inverse also applies: prose mandates whose mechanism was retired must be shrunk or deleted with the mechanism (the cascade lesson).

## Seed backlog (2026-06-09 audit of the 39-rule corpus, 417 KB)

**Move-whole — EXECUTED 2026-06-09 (audience test applied, corpus now 36 rules):**
- `agent0-governance-doctrine.md` + `scope-admission-governance.md` → moved to [[agent0-governance-doctrine]] / [[scope-admission-governance]]. Verified no hook wiring before the move (governance-gate.sh is the destructive-ops floor, unrelated). Coordinated edits: CLAUDE.md/AGENTS.md managed-block doctrine section removed; cross-ref bullet dropped from `spec-driven.md` § Relationship to other rules and two reference lines from `post-launch-maintenance-loop.md`. **Consumer residue:** the 3 consumers keep the stale CLAUDE.md section (append-only merge) and the stale rule copies — remove manually on the next sync visit.
- `propagation-advisory.md` → moved to [[propagation-advisory]] (maintainer suggestion: the rule documented a maintainer-only sync-excluded mechanism). Bonus simplification: its `COPY_CHECK_EXCLUDE` entry in `sync-harness.sh` deleted (hook + tests remain excluded — they live in shipped dirs); dead skip-line removed from `propagation-advise.sh`; `memory-placement.md` split-precedent sentence re-pointed at runtime-capabilities.

**Register-split — EXECUTED 2026-06-10 (maintainer-ordered one-time pass, not in-passing):**
- `harness-sync.md` 62→57 KB → [[harness-sync-maintenance]]; `delegation.md` 26→25 KB → [[delegation-maintenance]]; `memory-placement.md` 26→23 KB → [[memory-placement-maintenance]]; `secrets-scan.md` 20→18 KB → [[secrets-scan-maintenance]]. Same pass also swept ALL remaining rules for citation leaks (≈70 instances of `spec NNN` / `docs/specs/NNN-` / memory-pointers removed, facts kept): corpus 417→384 KB. Global grep for leak patterns over rules/ now returns zero — future leaks are fresh drift, caught by the propagation advisory at edit time.

**Checked and NOT candidates (audience verified consumer-facing):** `post-launch-maintenance-loop.md` (explicitly instrument-only, addressed to consumer projects), `php-laravel-support.md` (orientation index for Laravel consumers), `runtime-capabilities.md` (its maintainer register already lives in [[runtime-capabilities-maintenance]] — the pattern done right).

## Review trigger

If the corpus keeps growing despite this discipline (say, >45 rules or >450 KB six months from adoption), the withdrawn numeric-target diet returns to the table with evidence.
