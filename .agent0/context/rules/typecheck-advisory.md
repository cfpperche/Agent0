---
paths:
  - ".agent0/validators/run.sh"
  - "tsconfig.json"
  - "**/tsconfig.json"
  - "**/package.json"
---

# Typecheck advisory

The post-edit validator (`.agent0/validators/run.sh`) first looks for a repo-local declarative contract at `.agent0/validator.json`. When present, that file is the validation source of truth: the harness executes the commands the project declares under `commands.test`, `commands.typecheck`, `commands.lint`, `commands.build`, and `commands.ui` in that order. This is the recommended path for real projects, especially monorepos: Agent0 provides the quality direction, while the consumer project owns its stack-specific commands.

When `.agent0/validator.json` is absent, the validator falls back to legacy stack detection. In that fallback path, it detects typecheck primitive availability per JS branch and emits a non-blocking `typecheck-advisory:` line on stderr when the consumer project has neither — instead of hard-failing the pipeline by trying `<runner> run typecheck` against a missing script. Mirrors the lint-validator's manifest-as-intent posture: declared = run, missing = advise, neither = skip. Surfaced via dogfood where every sub-agent edit was hard-failing the validator on a fresh consumer project without typecheck infrastructure.

The pnpm branch applies the same root-manifest discipline to tests: it runs `pnpm test` only when the root `package.json` declares `scripts.test`. If a pnpm monorepo has package/app-specific test scripts but no root test script, the validator omits the test step and emits `test-advisory:` instead of failing on an implicit `pnpm test`.

## What fires per branch

### Declarative contract

Compact `.agent0/validator.json` shape for common gates:

```json
{
  "commands": {
    "test": "pnpm --filter @cognix/web test:unit",
    "typecheck": "pnpm --filter @cognix/web typecheck",
    "lint": "pnpm --filter @cognix/web lint",
    "build": "pnpm --filter @cognix/web build",
    "ui": "pnpm --filter @cognix/web test:e2e:ui"
  }
}
```

Ordered shape for consumer-specific gates outside Agent0's common category names:

```json
{
  "commands": [
    { "name": "test:unit", "run": "pnpm --filter @cognix/web test:unit" },
    { "name": "db:rls", "run": "pnpm --filter @cognix/web test:e2e:rls" },
    { "name": "ui:projects", "run": "pnpm --filter @cognix/web test:e2e:ui -- projects-section-nav.spec.ts" },
    { "name": "build:web", "run": "pnpm --filter @cognix/web build" }
  ]
}
```

Rules:

- `.commands` may be an object of name→command strings or an ordered array of `{ "name": "...", "run": "..." }` entries.
- Command strings must be non-empty single-line strings.
- Missing common categories are allowed in v1; the project owns which gates are proportional to the current change.
- Custom command names are allowed and expected for project-specific gates (`db:rls`, `fixtures`, `ui:<surface>`, `seed:demo`, etc.).
- If `.agent0/validator.json` exists but is malformed or declares no runnable commands, the validator returns JSON `ok:false` and emits `validator-config-advisory:`. It does not fall back to guessed stack commands.
- `.agent0/validator.json` is consumer-owned. Agent0 does not ship a managed copy; each project declares its own commands.

### Legacy stack fallback

Each JS branch picks the typecheck step based on what's available in the consumer project. State dispatch:

**bun / pnpm:**
- `tsconfig.json` exists → `<runner> tsc --noEmit` (direct invocation, no script needed)
- `package.json` `.scripts.typecheck` exists → `<runner> [run] typecheck`
- Neither → omit typecheck step entirely + emit `typecheck-advisory:` to stderr

**npm:**
- `package.json` `.scripts.typecheck` exists → `npm run typecheck`
- Otherwise → omit + advisory

The npm branch is conservative — no tsconfig fast-path. `npx tsc --noEmit` would be the bun-equivalent, but `npx` is a separate binary from `npm` and adds resolution surprises (test fixtures shimming `npm` don't catch `npx`; npx-can-prompt-to-install behaviour). Consumer projects on npm declare `typecheck` in scripts; bun/pnpm get the tsconfig fast-path because their runners invoke `node_modules/.bin/tsc` directly.

Python branch (`pytest && mypy . || true`) already uses the `|| true` advisory pattern for mypy specifically — typecheck-advisory does NOT extend to Python (mypy missing is silently tolerated). Go and rust branches use toolchain-bundled typecheckers (`go vet`, `cargo clippy`) that are always available with the language install.

## Advisory format

Single-line stderr message, manager-flavored:

```
typecheck-advisory: no tsconfig.json or 'typecheck' script in package.json — typecheck step skipped (add a tsconfig.json or declare `bun run typecheck` to enable)
typecheck-advisory: no tsconfig.json or 'typecheck' script in package.json — typecheck step skipped (add a tsconfig.json or declare `pnpm typecheck` to enable)
typecheck-advisory: no 'typecheck' script in package.json — typecheck step skipped (declare `npm run typecheck` to enable)
```

Same shape as `lint-advisory:` and `tdd-advisory:` — surfaces via `delegation-verify.sh`'s separated stderr capture into the agent's next-turn context. Never blocks; never increments delegation loop budget; advisory is the WHOLE signal.

The pnpm test omission advisory is similarly non-blocking:

```
test-advisory: no 'test' script in root package.json — test step skipped (declare `pnpm test` or run the package/app-specific test command for this change)
```

## Non-goals

- **No env-var to silence.** The advisory IS the signal; suppressing it defeats the discipline. To stop the advisory, declare a tsconfig.json or typecheck script — that's the documented path.
- **No tsconfig-content validation.** The validator checks file presence only; an empty `{}` tsconfig.json counts as "yes, has typecheck primitive" even though `tsc --noEmit` may emit no errors and no work happened. Acceptable: signal of intent is "I have a tsconfig", not "I have a meaningful tsconfig". Consumer projects responsible for content.
- **No npm tsconfig fast-path.** Documented choice in `validator/run.sh` comments. If a consumer project on npm wants direct tsc invocation, they declare a `typecheck` script in package.json (`"typecheck": "tsc --noEmit"`). One indirection; explicit.
- **No multi-stack typecheck execution.** The legacy fallback is single-stack — first lockfile match wins (same constraint as the lint extension). Agent0 does **not** run every stack's typecheck per edit (hot-path overreach); a real monorepo declares `.agent0/validator.json` (spec 207) which owns multi-stack execution. The fallback only *advises* on partial coverage — see § Multi-stack honesty advisory.

## Multi-stack honesty advisory

When the validator runs the **legacy fallback** (no `.agent0/validator.json`) and detects more than one stack across the repo, it audits the first-match stack and emits a non-blocking `multi-stack-advisory:` naming the audited stack and the detected-but-unaudited ones, pointing at the declarative contract (spec 210). Detection is via `git ls-files` over the same manifest markers the fallback chain uses (`package.json`→js, `pyproject.toml`/`requirements.txt`→python, `go.mod`→go, `Cargo.toml`→rust, `composer.json`→php), ignore-aware, with vendored/generated trees pruned; it degrades to root-markers outside a git repo.

```
multi-stack-advisory: fallback validator detected multiple stacks (js php) but audited only 'js' — php not validated this run. Declare .agent0/validator.json with package-scoped commands for full multi-stack coverage.
```

It is **detection-only** — no extra pipeline runs — and never touches JSON `ok`/`exit` (advisory family, like `lint-advisory:`/`typecheck-advisory:`). It mirrors the `unaudited_stacks` honesty pattern `/unused-code` uses. Opt-out: `CLAUDE_VALIDATOR_SKIP_MULTISTACK=1`. The advisory never fires on the declarative path (`validator.json` present → stack detection bypassed → coverage is the consumer's declared commands).

## Gotchas

- **`has_typecheck_script` requires `jq` AND a parseable `package.json`.** A malformed package.json silently fails the script check (jq returns non-zero) → falls through to advisory. Acceptable: the consumer project has bigger problems than typecheck if package.json doesn't parse.
- **`scripts.typecheck` value is NOT validated.** The validator checks for the script's presence, not its content. `"typecheck": "true"` (no-op) passes; the validator runs it and exits 0. Mirrors the lint-validator's "manifest-as-intent" decision — content validation is project responsibility.
- **Multiple advisories can fire in same run.** A consumer project with biome declared+missing AND no typecheck primitive emits BOTH `lint-advisory:` and `typecheck-advisory:` on stderr — each on its own line. Agent reads both via delegation-verify.sh's stderr surface.
- **Bun/pnpm fast-path uses `bunx`-equivalent semantics.** `bun tsc --noEmit` and `pnpm tsc --noEmit` invoke the local `node_modules/.bin/tsc`. If TypeScript isn't installed locally (no `typescript` in devDependencies), the inner `tsc` invocation fails and `ok=false`. That's correct behavior — declaring a tsconfig.json without TypeScript installed IS a project setup error worth blocking on. Different from the typecheck-advisory case (where the consumer project hasn't declared intent at all).
- **Conservative npm path means npm consumer projects need a `typecheck` script even when they have a tsconfig.json.** Surprise for npm-stack consumer projects — by symmetry with bun/pnpm, a tsconfig.json should suffice. Documented in `validator/run.sh` comments. If npm dogfood surfaces this as routine pain, revisit (probably via `npm exec --no -- tsc --noEmit` after sandboxing the npx-prompt risk).
- **No yarn branch.** The validator's stack detector doesn't recognize `yarn.lock` — yarn consumer projects fall through to the npm branch (which `package.json` triggers). Same typecheck advisory applies; the runner naming in the advisory is npm-flavored even on yarn consumer projects. Add `yarn.lock` detection separately when a real yarn consumer project lands.
