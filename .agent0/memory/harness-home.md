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

A harness surface's **file** belongs under **`.agent0/`** if it is not *intrinsically* tied to one runtime's on-disk format. Only the **registration** (the pointer that tells a runtime to invoke the file) is runtime-specific. The two axes are orthogonal:

- **Location** (where the file lives) → `.agent0/` by default; `.claude/`/`.codex/` only for files that ARE a runtime's native format (Claude's `settings.json`, Codex's `config.toml`, CC's `.claude/worktrees/`).
- **Registration** (what makes a runtime run it) → stays runtime-specific. A hook is registered in Claude's `settings.json` and/or Codex's `config.toml`; the *script it points at* lives in `.agent0/hooks/`.

`delegation-verify.sh` is the canonical proof: registered in BOTH `settings.json` (Claude) and `.codex/config.toml.example` (Codex), yet the file lives in `.agent0/hooks/`. `delegation-gate.sh` (spec 119) generalizes it the other direction — registered ONLY by Claude (its `Agent` tool has no Codex analog), but its file still lives in `.agent0/hooks/` because the *script* carries no Claude-native format. A Claude-only *registration* does not pin the *file* to `.claude/`.

`.claude/` is Claude Code's *conventional* home, not a runtime-neutral one. Keeping shared harness files there forces every multi-runtime port to re-decide "is this Claude-owned or shared?" path-by-path. Routing by this principle makes the multi-runtime story mechanical: a new runtime registers the `.agent0/` capacities through its own native surface, and the only runtime-specific files are the registration manifests themselves.

**Refinement history:** the original principle keyed location off "do both runtimes read/write it" — which mis-classified Claude-only-*registered* files (like `delegation-gate.sh`) as `stays`. Specs 117/118/119 sharpened it to the location-vs-registration split above. The earlier "shared test" below still holds as a *sufficient* condition for `.agent0/` (if both runtimes use it, it's definitely shared) but is no longer *necessary* (a Claude-only-registered script whose body is runtime-neutral also goes to `.agent0/`).

## The "shared" test

> _In a Codex-only consumer project that never opens Claude Code, would this file still be read or written?_

- **Yes** → `.agent0/`.
- **Dead weight without Claude** → `.claude/`.

## Co-location with the producer

A corollary surfaced by spec 104: **state moves *with* its producer, never ahead of it.** Runtime-state followed `probe.sh`; session-state followed its `.agent0/hooks/`. The rule is about avoiding a producer/state *split* — not about the producer's *file* having to move first. Spec 119 clarified this with `.brainstorm-state`: its producer (`/brainstorm` SKILL.md) stays in `.claude/skills/` (skills still `deferred`), yet the state dir relocated to `.agent0/.brainstorm-state/` because the skill's read/write path was **repointed in the same diff**. No split is created — the producer points at the new location. So the rule is satisfied by co-relocating *the producer's path reference*, which does not require relocating the producer's file. Do both in the same diff.

## Worked dispositions (umbrella 102 gap matrix; updated through spec 119, 2026-05-29)

- **`move` (shipped):** reminders, routines, session-state, runtime-state, browser-state, shared shell tools (103/104/105); validators + tests (118); **`delegation-gate.sh` + `.delegation-state/` + `.brainstorm-state/` (119)**. The hooks and state files are runtime-neutral *files*; only their registration is runtime-specific.
- **`stays`:** `settings.json` (Claude hook-config format) + `.codex/config.toml` (Codex format) — the registration manifests themselves; the `Agent`-tool delegation *audit log* path is `.agent0/delegation-audit.jsonl` already, but the tool's *semantics* are Claude-only; `.claude/worktrees/` (CC-native `EnterWorktree`). What stays is format-bound or tool-semantic, never "a script with a Claude-only registration".
- **`deferred`:** rules, skills, agents — runtime-neutral in principle but their relocation waits on the "Codex actually consumes rules/skills" trigger; decide shared-`.agent0/` vs per-runtime then. (Note: a skill staying `deferred` does NOT pin its *state output* to `.claude/` — see § Co-location, spec 119's `.brainstorm-state`.)

## Cross-references

- `docs/specs/102-harness-consolidate-agent0/spec.md` § *Classification principle* + § *Gap matrix* — the source umbrella
- `.claude/rules/memory-placement.md` § *Routing decision tree* — the rule-vs-memory criterion that routes this principle to memory
- `.claude/rules/harness-sync.md` § *Path relocations (capacity-only)* — the consumer-migration posture when a surface relocates
