# Session handoff

Read at the start of every Claude Code session and updated at the end. Captures work-in-progress context that wouldn't otherwise survive between sessions.

See `.claude/rules/session-handoff.md` for the protocol (4 KB size discipline + reader-side truncation defence).

---

## Current state

**Session 2026-05-23 — memory-system evolution scoped + scaffolded.** Specs 080 (umbrella) + 081 (first child, MS-3 compact-history + MS-6 runtime-state README) committed at `978bedd`. Deep research at `/tmp/research/{obsidian,opencode,hermes,anthill,synthesis}.md` (~2.5k lines, 5 files) motivated the design. 079 live re-run + 076 implementation still pending from prior sessions — not touched.

## WIP — resume point

**081 ready for `/sdd plan`.** spec.md has 8 acceptance scenarios + 6 NGs + 4 OQs. Plan resolves the OQs (dir pre-creation via `.gitkeep`, ISO filename collision suffix, `compactHistory.keepLast` config key, README enumeration scope), then `/sdd tasks` → ~210 LOC across `.claude/hooks/{pre-compact,session-start}.sh`, `.claude/rules/compaction-continuity.md`, new `.claude/.runtime-state/README.md` + gitignore exception, harness-sync manifest update.

082/083/084/085 unscaffolded — MS-1 schema validator (foundation), MS-2 event-sourcing, MS-4 reminders.yaml, MS-5+MS-7 cap+query+decay.

## Next steps

1. `/sdd plan` on 081 (recommended next-session opener).
2. After 081 ships, scaffold 082 (foundation for 083+085) → 083 → 084/085 parallel-safe.
3. **Carryover deferred again:** 079 live re-run (`cd /home/goat/mei-saas && /product "<idea>" --out=. --stack=next`); 076 implementation (plan + tasks drafted); 075 task 14 (`/product` dogfood scenarios 3-6).
4. Dated reminders due: 029 05-30 · 035 06-07 · 046 07-01 · 060 07-19.

## Decisions & gotchas

- **Agent0-as-product framing.** Rule-of-three demand test applies to speculative tooling inside the repo; does NOT apply to capacities Agent0 ships to forks. Memory bucket evolution prepares for fork-at-scale (100-500 entries, parallel sessions) even though current Agent0 has 13 memories. User pushed back on over-conservative framing mid-conversation — corrected. Promote to feedback memory if it holds after 081+082 ship.
- **NG-1 strict isolation auto-memory ↔ project-memory** is load-bearing for 080. Anthill conflates the two (`memory-sync-in/out.sh` + founder profile YAML inside `.anthill/memory/founder/<email>/profile.yaml`) — Agent0 rejects both. Don't relax in any child spec.
- **Decay engine pattern (085): mechanism + transparent overridable defaults.** ~10-line bash formula, all numerics in `.claude/memory.config.json`. Mirrors `delegation-gate` / `secrets-scan` shape. Generalizable — second instance triggers promotion to feedback memory.
- **`/tmp/research/` is tmpfs-ephemeral** — referenced in 080 spec.md § *Context / references*. Agents were dispatched fresh + reproducible; rebuild if lost.
- **Słomka quote verbatim** for Hermes blog (due 2026-06-30): *"Skill poisoning is prompt injection with a save button."* Krzysztof Słomka, Medium 2026-04-20. Replaces the paraphrase in the current reminder.

## Carryover (orthogonal — not touched this session)

- **079 live re-run** — pending from prior session.
- **076** — plan + tasks drafted, ready to implement.
- **075 task 14** — `/product` dogfood scenarios 3-6 pending.
- `docs/specs/074-subagent-personas/` — untracked draft; leave for originating session.
- `.claude/REMINDERS.md` items per startup readout.
