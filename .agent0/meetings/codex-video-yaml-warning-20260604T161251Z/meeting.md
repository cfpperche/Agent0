---
meeting: codex-video-yaml-warning
topic: "Why Codex warns about invalid video SKILL YAML"
created: 2026-06-04T16:12:51Z
convener: codex
mode: human-orchestrated
roster: claude,codex,human
rotation: claude,codex
turn_counter: 3
next_speaker: human
synthesis: pending
---

# Meeting: Why Codex warns about invalid video SKILL YAML

_A multi-party, multi-model deliberation. The front-matter above is the machine-readable state: `roster` is every participant id, `rotation` is the deterministic **fallback order** of model participants (human excluded), `next_speaker` is the **derived default** speaker (set by a turn's trailing `Next: <id>` directive; not enforced legality), `turn_counter` counts written turns, `synthesis` tracks the close-out. Speaker selection is context-driven: a turn may end with an explicit `Next: <roster-id>` line to hand the floor; otherwise the human directs with `--speaker`. The body below is the chronological transcript._

## Participants

- claude - Claude Code via local claude-exec bridge
- codex - Codex CLI, active orchestrator receiving the startup warning
- human - User/convener asking why Codex sees the warning

## Transcript

_Turns are appended below in order. Each turn header is `### Turn N — <runtime> (<id>)`; a research-backed turn carries a `Sources:` block listing the URLs used. A turn may end with a single trailing `Next: <roster-id>` line to hand the floor to a specific participant (the directive stays visible here; it sets the default next speaker)._


### Turn 1 — Codex CLI (codex)

Investigation scope: Codex startup is reporting this warning twice:

`Skipped loading 1 skill(s) due to invalid SKILL.md files.`
`/home/goat/Agent0/.agent0/skills/video/SKILL.md: invalid YAML: mapping values are not allowed in this context at line 3 column 46`

Local facts I have checked:

- `.agent0/skills/video/SKILL.md` is a discoverable Agent0 skill for Codex because `.agents/skills/video` points to `../../.agent0/skills/video`.
- `.claude/skills/video` points to the same target, so this is a shared first-party skill surface, not a Codex-local copy.
- The skill frontmatter currently has plain YAML scalars on line 3 and line 4:
  - `description: AI + programmatic video generation ...`
  - `argument-hint: <--mode=code|generative> [code: scaffold <slug> | render <slug>] [generative: ...]`
- The runtime warning names line 3 column 46. My working hypothesis is that the Codex skill loader is parsing frontmatter with a strict YAML parser and the unquoted plain scalar contains punctuation that YAML treats as syntax, most likely a colon-space sequence in the long description or the adjacent `argument-hint` scalar. The line 4 `argument-hint` also has obvious unquoted `code:` and `generative:` tokens.

What I need from Claude this turn:

1. Confirm the most likely exact YAML rule being violated and why Codex receives this warning at startup.
2. Check whether the right fix is to quote or block-style the `description` and `argument-hint` fields, rather than changing Codex loader behavior.
3. Call out whether this looks isolated to `video/SKILL.md` or implies we should run a repo-wide frontmatter validation for all `.agent0/skills/*/SKILL.md` files.

Please do a read-only investigation and return one focused meeting turn. Do not edit files.

Next: claude


### Turn 2 — Claude Code (claude)

## Claude turn — root cause confirmed, with a column-level proof

I read the file and the repo. Answering your three questions:

**1. The exact YAML rule, and why the warning fires — it is NOT line 3 of the file.**

The culprit is **line 4** (`argument-hint`), not line 3 (`description`). Codex's parser strips the opening `---` document marker and numbers lines relative to the YAML body, so its **"line 3" = the file's line 4**. The column nails it:

- File line 4: `argument-hint: <--mode=code|generative> [code: scaffold <slug> ...`
- Counting: `argument-hint:` + space = 15 chars, value starts col 16; `<--mode=code|generative> [code` puts the `:` of `code:` at **column 46** — exactly the reported `line 3 column 46`.

The violated rule is YAML's **mapping-value indicator**: an unquoted (plain) scalar may not contain a `: ` (colon-space) sequence, because the scanner reads it as "start of a nested mapping value" — hence the precise message *"mapping values are not allowed in this context."* Your `argument-hint` value has two offenders: `[code: scaffold ...]` and `[generative: --tier...]`. The scanner chokes on the first one and aborts the whole frontmatter, so the skill is skipped.

I checked line 3 (`description`) directly: its column 46 is the `o` in "generation" — no colon-space anywhere in the description. Line 3 is innocent; the description's em-dash and `-` separators are fine because they aren't `: `. So your line-4 hypothesis was right; the warning's line number is just off-by-one due to the `---`-stripping.

**2. Right fix is at the data, not the loader.** Quote the `argument-hint` value. This is non-compliant frontmatter, not a Codex bug — Claude Code's loader is simply more lenient here, which is why it's been silently accepted. A double-quoted scalar is cleanest:

```yaml
argument-hint: "<--mode=code|generative> [code: scaffold <slug> | render <slug>] [generative: --tier=draft|standard|premium --duration=<sec> --confirm-cost-usd=<max> [--image-url=<url>] [--name=<slug>] \"<prompt>\"]"
```

Note the inner `"<prompt>"` must be escaped (`\"`) inside a double-quoted scalar — or use a YAML block scalar (`>-`/`|-`) to avoid escaping entirely. Do **not** touch loader behavior; strict YAML is correct and the `/skill validate` contract should be catching this.

**3. Scope: isolated to `video`, but it exposes a validator gap.** I grepped all 12 `.agent0/skills/*/SKILL.md` for `^(description|argument-hint):.*: ` (a frontmatter scalar containing colon-space) — **only `video/SKILL.md:4` matched.** So the immediate blast radius is one file. But the deeper finding: this file presumably passed `/skill validate`/`audit`, which means our compliance check is **not parsing frontmatter with a strict YAML parser** — it's likely regex/field-presence only. That's the real defect to log. Two follow-ups for whoever picks up the fix (not this turn):

- Fix `video/SKILL.md` line 4 (quote or block-scalar), then re-run Codex startup to confirm the warning clears.
- Harden `/skill validate` to load each SKILL.md's frontmatter through an actual strict YAML parse, so colon-space (and similar) is caught at authoring time across all skills and every consumer fork — this is the durable, ships-via-rules fix, not a one-off patch.

One caveat I'm flagging honestly: the off-by-one line attribution is my structural inference from the `---`-stripping + the column-46 match lining up perfectly on line 4; it's a strong fit but I haven't run Codex's parser to byte-confirm it. The *fix* doesn't depend on resolving that — quoting line 4 removes the only colon-space in the frontmatter regardless.

Next: codex


### Turn 3 — Codex CLI (codex)

I verified Claude's diagnosis locally after his turn.

Evidence:

- `awk` on `.agent0/skills/video/SKILL.md` line 4 shows `code_col=42` and `colon_col=46` for the first `code:` token in `argument-hint`.
- Parsing only the frontmatter body with PyYAML reproduces the same failure family:
  - `ScannerError`
  - `mapping values are not allowed here`
  - after stripping the leading newline from the frontmatter body, the parser reports `line 3, column 46`, matching the Codex runtime warning.

Conclusion: the warning is caused by invalid YAML in `.agent0/skills/video/SKILL.md`, specifically the unquoted `argument-hint` value containing `code: scaffold` and `generative: --tier...`. Codex is seeing it because `.agents/skills/video` symlinks into `.agent0/skills/video`, so the Codex skill discovery path loads that same first-party skill.

Recommended fix: quote or block-scalar the `argument-hint` value, then add or harden validation so every discoverable `SKILL.md` frontmatter is parsed with a real YAML parser before it can ship. The immediate file fix is small, but the validator gap is the durable follow-up.

Next: human

## Synthesis

_Written when a participant is asked to synthesize. Names the synthesizing runtime, the convergence, recorded disagreements, and a recommended next step (graduate to `/sdd refine` as seed context, or no-op). The human then accepts / redirects / ends._

_(not yet synthesized)_
