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

The durable encoding of umbrella spec 102's § Classification principle. It binds the **upstream maintainer** adding or relocating a harness surface; a consumer-side agent in a fork that only consumes (never extends) the harness never consults it, which is why it lives in project memory rather than a shipped `.agent0/context/rules/*` file (per the rule-vs-memory criterion in `.agent0/context/rules/memory-placement.md` § *Routing decision tree* — maintainer-binding, consumer-side agent does not load it).

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

- **`move` (shipped):** reminders, routines, session-state, runtime-state, browser-state, shared shell tools (103/104/105); validators + tests (118); **`delegation-gate.sh` + `.delegation-state/` + `.brainstorm-state/` (119)**; **`harness-sync-baseline.json` (130 — `.claude/`→`.agent0/`)**, the last consolidation holdout: it passes the shared test (read/written by the runtime-neutral `sync-harness.sh`, which Codex invokes directly), so it belongs in `.agent0/` like its sibling `delegation-audit.jsonl`; `sync-harness.sh` reads the legacy `.claude/` path as a fallback and removes it on the migrating `--apply`. The hooks and state files are runtime-neutral *files*; only their registration is runtime-specific.
- **`stays`:** `settings.json` (Claude hook-config format) + `.codex/config.toml` (Codex format) — the registration manifests themselves; the `Agent`-tool delegation *audit log* path is `.agent0/delegation-audit.jsonl` already, but the tool's *semantics* are Claude-only; `.claude/worktrees/` (CC-native `EnterWorktree`). What stays is format-bound or tool-semantic, never "a script with a Claude-only registration".
- **`move` (shipped, spec 121):** **portable skills** — a skill's canonical body lives at `.agent0/skills/<slug>/SKILL.md` (shared agentskills.io format), with per-runtime *discovery symlinks* `.claude/skills/<slug>` (Claude) + `.agents/skills/<slug>` (Codex) pointing back at it. Textbook location-neutral / registration-per-runtime: both runtimes follow the symlink to one source (proven on Codex 0.135.0 + Claude 2.1.158). `vuln-audit` is the pilot; migration is one-by-one. The "Codex actually consumes skills" trigger fired — Codex `.agents/skills` is a real native discovery path. sync-harness propagates the source + recreates the links (copy-materialization fallback on symlink-hostile checkouts).
- **`move` (shipped, spec 122):** **context rules** — behavioral rule bodies live at `.agent0/context/rules/<slug>.md`; `.agent0/hooks/context-inject.sh` hydrates selected fragments into both runtimes. `.claude/rules/` is no longer a harness-owned source or discovery surface; Claude receives the same Agent0-owned context channel as Codex, with only the registration living in `.claude/settings.json`.
- **`deferred`:** agents and **`cc-native` skills** — `cc-native` skills (those bound to `AskUserQuestion` / `${CLAUDE_SKILL_DIR}` with no Codex analogue) stay physically in `.claude/skills/` and are NOT symlinked into `.agents/skills/`. (Note: a skill staying `deferred` does NOT pin its *state output* to `.claude/` — see § Co-location, spec 119's `.brainstorm-state`.)

## Gotchas

- **A relocation must sweep the doc surfaces, not just the code.** Moving a surface `.claude/`→`.agent0/` (or removing a capacity) leaves stale path references in the prose entrypoints — `CLAUDE.md` (managed block) and `AGENTS.md` (baseline-tracked) — which the sync then propagates verbatim to every consumer. Two such refs survived multiple migrations and were only caught auditing the spec-129/130 mei-saas resync: the memory-index trigger still listed `.claude/hooks/` after spec 119 moved hooks to `.agent0/hooks/`, and the harness-sync description still named `.claude/harness-sync-baseline.json` after spec 130 moved it (fixed in `464976a`). **Checklist for any future relocation:** `grep -rn '\.claude/<old-path>' CLAUDE.md AGENTS.md .agent0/context/rules/ .agent0/memory/` and repoint every hit — excluding the genuinely-Claude-native survivors (`.claude/settings.json`, `.claude/skills/<cc-native>`, discovery symlinks). The code-only fix passes tests but ships stale docs.

## Cross-references

- `docs/specs/102-harness-consolidate-agent0/spec.md` § *Classification principle* + § *Gap matrix* — the source umbrella
- `.agent0/context/rules/memory-placement.md` § *Routing decision tree* — the rule-vs-memory criterion that routes this principle to memory
- `.agent0/context/rules/harness-sync.md` § *Path relocations (capacity-only)* — the consumer-migration posture when a surface relocates
