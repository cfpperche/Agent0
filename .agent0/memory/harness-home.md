---
name: harness-home
description: Classification principle for where a harness surface lives — .agent0/ (runtime-neutral, both runtimes read/write) vs .claude/-.codex/ (runtime-exclusive). Consult before adding or relocating any harness file.
metadata:
  type: project
  created_at: '2026-05-28T00:00:00Z'
  last_accessed: '2026-05-28'
  confirmed_count: 0
---
# Harness home — where a surface lives

The durable encoding of umbrella spec 102's § Classification principle. It binds the **upstream maintainer** adding or relocating a harness surface; a consumer-side agent in a fork that only consumes (never extends) the harness never consults it, which is why it lives in project memory rather than a shipped `.claude/rules/*` file (per the rule-vs-memory criterion in `.claude/rules/memory-placement.md` § *Routing decision tree* — maintainer-binding, consumer-side agent does not load it).

## The principle

A harness surface belongs under **`.agent0/`** if **both** runtimes (or a future runtime) would read/write it through the harness. It stays under **`.claude/`** / **`.codex/`** only if it is **genuinely exclusive** to that runtime's mechanism — e.g. Claude's `settings.json` hook-config format, the Claude-only `Agent` delegation tool and its audit log, Codex's `config.toml`.

`.claude/` is Claude Code's *conventional* home, not a runtime-neutral one. Keeping shared harness state there forces every multi-runtime port to re-decide "is this Claude-owned or shared?" path-by-path. Routing by this principle makes the multi-runtime story mechanical: a new runtime registers the `.agent0/` capacities through its own native surface, and the only runtime-specific files are the registration manifests.

## The "shared" test

> _In a Codex-only consumer project that never opens Claude Code, would this file still be read or written?_

- **Yes** → `.agent0/`.
- **Dead weight without Claude** → `.claude/`.

## Co-location with the producer

A corollary surfaced by spec 104 and reaffirmed by row 14 (brainstorm-state): **state moves *with* its producer, never ahead of it.** Runtime-state followed `probe.sh`; session-state followed its `.agent0/hooks/`. A state dir whose sole producer/consumer is still a runtime-exclusive surface (e.g. `.claude/.brainstorm-state/`, produced only by the Claude-invoked `/brainstorm` skill) must NOT relocate before that producer does — moving it alone re-creates the exact state/producer split the consolidation kills. Relocate both in the same diff.

## Worked dispositions (umbrella 102 gap matrix, all terminal as of 2026-05-28)

- **`move` (shipped):** reminders, routines, session-state, runtime-state, browser-state, shared shell tools — written/read by both runtimes through the harness.
- **`stays`:** `settings.json` (Claude hook-config format), delegation state + audit (`Agent` tool is Claude-exclusive), Claude-only hooks (registered only via `settings.json`).
- **`deferred`:** rules, skills, validators, brainstorm-state — runtime-neutral in principle but their relocation waits on the "Codex actually consumes rules/skills" trigger; decide shared-`.agent0/` vs per-runtime then.

## Cross-references

- `docs/specs/102-harness-consolidate-agent0/spec.md` § *Classification principle* + § *Gap matrix* — the source umbrella
- `.claude/rules/memory-placement.md` § *Routing decision tree* — the rule-vs-memory criterion that routes this principle to memory
- `.claude/rules/harness-sync.md` § *Path relocations (capacity-only)* — the consumer-migration posture when a surface relocates
