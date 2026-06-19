# 208 — unused-code-audit — plan

_Drafted from `spec.md` on 2026-06-18. Update this file if implementation reveals the plan is wrong; do NOT silently diverge._

## Approach

Build `/unused-code` as a deliberate **twin of `/vuln-audit`** — same three-part shape, same posture, maximal reuse of an already-litigated design so review surface is small. The three parts: (1) a runtime-neutral engine `.agent0/tools/unused-code.sh` that detects JS/TS stack, probes for knip + its config, runs `knip --reporter json`, and maps the result to a first-class status; (2) a thin `/unused-code` skill (`.claude/skills/unused-code/SKILL.md`) that decides when to run the tool and surfaces the result; (3) a rule doc `.agent0/context/rules/unused-code-audit.md` that is the canonical contract. Then wire the capacity into the harness index (CLAUDE.md managed block + sync baseline) so a fresh fork inherits it.

The engine's control flow mirrors vuln-audit's status machine, with one addition the spec locked: **`unconfigured`**. Detection order — no JS/TS markers → `no-stack` clean no-op; knip not resolvable → `unavailable` + install hint; knip present but no config file → `unconfigured` + config pointer (we do **not** run bare defaults, which manufacture false positives); knip + config → run it: empty result → `clean`, ≥1 finding → `findings` (classified by kind), engine error/unparseable → `failed`. Default process exit is `0` for every status; `--exit-code` maps statuses for consumer CI only. No file is ever modified. Build the engine first (it is the whole capacity; skill + rule are wrappers), test it against three throwaway fixtures (clean / findings / unconfigured), then write the skill and rule, then index it.

## Files to touch

**Create:**
- `.agent0/tools/unused-code.sh` — the engine. Args `[path] [--json] [--exit-code]` (no `--severity` — unused-code has no severity axis; omit deliberately). Stack-detect JS/TS via the same markers run.sh uses (`package.json` / lockfiles); resolve knip via `node_modules/.bin/knip` then `npx knip --version`; detect config via knip's known config surfaces (`knip.json`, `knip.jsonc`, `knip.ts`, `.knip.json`, or a `knip` key in `package.json`); run `<runner> knip --reporter json`, parse with `jq` into status + per-kind findings; human-readable default output + `--json` structured doc (shape-only convenience, not a versioned contract — same disclaimer as vuln-audit/`sdd list`).
- `.claude/skills/unused-code/SKILL.md` — thin invocation wrapper over the tool (model on `vuln-audit/SKILL.md`: same frontmatter shape, `agentskills-portable` tier, `argument-hint`, points at the rule doc).
- `.agent0/context/rules/unused-code-audit.md` — canonical capacity contract: on-demand-only trigger surface, JS/TS-knip-only v1 engine choice + per-stack deferral list, the `unconfigured` caveat, status model + exit-code policy, report-never-delete + no-override-marker, the consumer `validator.json` custom-command hybrid, the `/routine` recipe for periodic scans, finding-taxonomy + public-API-boundary + suppression-is-engine-native notes, non-goals. Add the `paths:` frontmatter trigger (`.agent0/tools/unused-code.sh`, JS manifests) so it is rule-selected when relevant.
- `docs/specs/208-unused-code-audit/notes.md` — in-flight design memory (populated during build).

**Modify:**
- `CLAUDE.md` — add a managed-block index entry under the capacity list (one paragraph, same shape as the `## Vuln audit` entry), pointing at the rule. Propagates via `sync-harness.sh`'s structured CLAUDE.md merge.

**Propagation (no file to edit — resolved):** there is NO `.agent0/harness-sync-baseline.json` in the Agent0 source repo — it is a *per-consumer* artifact `sync-harness.sh` computes from a manifest built dynamically from glob sets (`COPY_CHECK_RECURSIVE` / `COPY_CHECK_GLOBS`), filtered to git-tracked files ("managed = tracked in Agent0"). The three new files already fall under existing globs — `.agent0/tools|*.sh`, `.agent0/context/**` (recursive), `.claude/skills/**` (recursive) — so they propagate automatically once git-tracked. No baseline edit, no manifest entry. (Investigated 2026-06-18; see `sync-harness.sh:185-236`.)

**Delete:**
- None.

## Alternatives considered

### Per-edit validator advisory (`unused-code-advisory:` in `run.sh`), the lint-class shape

Rejected. This is the literal "in the style of lint" reading of the ask, but unused-code is whole-program graph analysis: running knip after every edit is slow and floods false positives (knip has no cheap incremental single-file mode). vuln-audit already litigated and won the "keep expensive/noisy whole-program analysis off the hot per-edit/commit path" argument; re-importing it here would repeat a known anti-pattern. The inline need is met by the consumer-owned `validator.json` custom command — zero new Agent0 code, consumer owns proportionality.

### A new first-class `commands.deadcode` category in the spec-207 validator contract

Rejected. The ordered-custom-command array shipped in spec 207 already lets a consumer declare `{ "name": "deadcode", "run": "npx knip" }`. Adding a first-class category would assert this gate is universally proportional (it is not — it needs project config and is noisy) and would expand the validator's contract surface for no gain.

### Multi-stack v1 (knip + vulture + deadcode + cargo-machete + PHPStan)

Rejected for v1. Fails Agent0's rule-of-three (one ask) and reintroduces the divergent-definitions / duplicate-findings problem vuln-audit explicitly rejected. The engine's stack-detect is built extensibly (a dispatch the way run.sh branches), but only the JS/TS branch ships; further stacks land one-per-stack behind real dogfood, exactly how lint rolled out.

### Bundle complexity / code-smell detection into the same tool

Rejected. Complexity is threshold-politics (lines-per-function, cyclomatic/cognitive, class size) needing local taste; mixing it with high-signal unused-code findings poisons the useful part. Deferred to a future `/code-health` recipe or a consumer-declared analyzer command.

## Risks and unknowns

- **knip output schema drift.** `knip --reporter json` shape may change across knip majors; the `jq` parse must be defensive (tolerate missing keys → degrade to `failed` with a clear reason, never crash). Pin the parse to documented top-level keys; verify against the installed knip version during build.
- **Config-detection completeness.** knip reads config from several surfaces (`knip.{json,jsonc,ts,js}`, `.knip.*`, `package.json#knip`). Missing one → false `unconfigured`. Enumerate from knip's docs at build time; treat a `package.json#knip` key as configured.
- **`npx knip` can attempt a network install** when knip is absent — must gate the run on local resolution first (`node_modules/.bin/knip`), and only report `unavailable` (never silently trigger an install), mirroring how run.sh gates biome on local presence.
- **Monorepo scope (OQ).** Lean: rely on knip's own workspace-awareness, document root invocation, build no Agent0-side workspace walk (mirrors validator single-stack v1). Confirm knip's workspace default does not surprise.
- **`unconfigured` strictness (OQ).** Lean: hard-stop at `unconfigured` rather than running bare defaults. Confirm before locking — running defaults is the alternative but it manufactures false positives.
- **Surface form (OQ).** Lean: ship the full skill + tool twin (parity with vuln-audit, discoverability). Low risk; the tool is the substance regardless.
- ~~**Sync-baseline registration mechanism.**~~ RESOLVED 2026-06-18: no baseline in the source repo; the three files propagate via existing `sync-harness.sh` globs once git-tracked. See § Files to touch → Propagation.

## Research / citations

- Codex CLI adversarial design review, 2026-06-18 (read-only, high effort) — `.agent0/.runtime-state/codex-exec/20260618T232755Z-design-position-to-pressure-test-agent0-dead-cod/last-message.md`. Ruled all six design forks; this plan implements its crisp recommendation.
- `/vuln-audit` implementation as the structural template: `.agent0/tools/vuln-audit.sh`, `.claude/skills/vuln-audit/SKILL.md`, `.agent0/context/rules/vuln-audit.md`.
- `.agent0/validators/run.sh` — stack-detect markers, runner selection (bun/pnpm/npm), local-binary-gate pattern (biome), and the spec-207 custom-command array that provides the hybrid.
- knip docs — reporters/JSON output, config surfaces, workspace handling: https://knip.dev
