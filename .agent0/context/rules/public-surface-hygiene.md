# Public-surface hygiene

Agent0 is a **public repository** and a **distributed harness**: its tracked files are visible to anyone on the internet, and most are copied into consumer projects by `sync-harness.sh`. The harness must therefore stay free of anything that couples it to — or leaks — the specific projects that consume it. Agent0 knows only that it is a harness used by itself and by other projects; **it never names them.**

## The discipline

In **every tracked Agent0 artifact** — shipped rules/skills/tools/validators/hooks, the `CLAUDE.md`/`AGENTS.md` entrypoints, AND the project's own `docs/specs/**`, `.agent0/memory/**`, `.agent0/HANDOFF.md` — do **not**:

1. **Name a consumer/client project.** Refer to them generically: "a real consumer project", "a consumer in a `<vertical>` stack", "field dogfooding". A motivator or dogfood attribution never needs the project's name to make its engineering point.
2. **Embed a private absolute path** (`/home/<user>/…` or other machine-specific paths). Use a repo-relative path or a `<repo>/…` placeholder.
3. **Put operator-private commercial/strategy framing in shipped files** (which businesses, which verticals, revenue framing). That belongs in private notes, not the public harness.

## "founder" is overloaded — never blind-replace it

The same word means different things; replace by **meaning, per occurrence**, never with a repo-wide `sed`:

- In `.agent0/context/rules/*` and harness prose it usually meant the Agent0 **operator** → use **"maintainer"** (or just state the rule plainly).
- In `/product` it is the **product-builder persona** (the user running `/product`) → keep "founder".
- In legal/roadmap templates it is **domain vocabulary** ("startup founders") → keep.

(A repo-wide `s/founder/maintainer/` wrongly rewrote 46 `/product` files once; caught and reverted.)

## Self-check before committing

Audit the shipped + tracked surface for the known leak shapes (substitute the real consumer names for the audit; never commit the names into this rule):

```bash
git grep -nI -iE '<consumer-name-A>|<consumer-name-B>|/home/[a-z]+/' -- \
  '.agent0/context/**' '.agent0/skills/**' '.agent0/tools/**' \
  '.agent0/validators/**' '.agent0/hooks/**' '.claude/skills/**' \
  'CLAUDE.md' 'AGENTS.md' ':(exclude)*/runtime/**'
```

Generated runtime logs are a recurring offender (they bake in absolute paths) — keep them gitignored, not tracked (see `harness-sync.md` and the OD-engine's `runtime/od-sync/.gitignore`).

## Scope: forward-only

This is a **forward** discipline. Pre-existing benign attribution in the historical spec corpus and in git history is accepted as-is: retroactively scrubbing the spec corpus or rewriting public git history (`git filter-repo`) is disproportionate to benign dogfood attribution and would break consumer sync baselines, forks, and every commit SHA. Stop the leak going forward; the genuinely sensitive offenders (commercial strategy in shipped rules, private absolute paths) were removed in the hygiene pass that landed this rule.

## Notes

_Consumer-extension surface — append consumer-local bullets here. Sync flags the file as `!! customized` (sha-compare is section-blind); the conflict region is mechanically this section: take new upstream verbatim, re-add consumer bullets at the end._

- For a **consumer project**, the same discipline reads "do not leak *your own* client/customer names into harness-tracked artifacts" — the consumer's harness tree may itself be public or shared.
