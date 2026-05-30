# 120 — vuln-audit

_Created 2026-05-29._

**Status:** shipped

## Intent

Add a runtime-neutral capacity that detects **known-vulnerable installed dependencies** in a
consumer project and surfaces them with enough context to act, without gating anything. This is the
positive replacement for the supply-chain block/advise capacity removed in spec 112 — that capacity
gated `npm install` at the wrong moment (install time), and the founder's decision was explicit:
**don't limit lib usage at install time; detect vulnerable installed libs and act.** The real signal
is "a dependency you already depend on has a published CVE/advisory and a fixed version exists" — a
question answerable from the project's lockfiles. The capacity is stack-aware (it covers whatever
ecosystems the project actually has) and multi-runner (works the same under Claude Code and Codex
CLI, mirroring the 106–113 multi-runtime port arc). It is human-in-loop: it reports and proposes,
it does not auto-upgrade and does not block a commit.

**Scope of the claim (source-completeness caveat).** v1 reports *"known vulnerabilities found by the
selected OSV-backed engine,"* NOT *"all vulnerabilities known anywhere."* The coverage report (below)
proves which lockfiles were parsed; it does **not** prove advisory-corpus completeness. Independent
scanners overlap only ~60–65%, so a single OSV-backed engine provably misses some advisories another
DB would catch — that is a source/database difference, accepted by design in v1 (see Non-goals).

**Trigger & staleness limitation.** v1 is **on-demand only** — the audit runs when the human invokes
it, never at install, never at commit, never on a schedule. The honest consequence: a vulnerability
published *after* your last run is invisible until you next run it. A recurring cadence is the
documented deferred path via the generic `/routine` capacity (no v1 code); see Non-goals.

## Acceptance criteria

- [x] **Scenario: stack-aware scan reports vulnerable installed deps with a three-bucket coverage report**
  - **Given** a consumer project containing one or more recognised lockfiles (e.g. `package-lock.json`, `poetry.lock`, `go.sum`, `Cargo.lock`, `composer.lock`, `bun.lock`)
  - **When** the audit is invoked on demand
  - **Then** it runs the engine over the locked dependency graph and emits a coverage report with three explicit buckets — **`found`** (lockfiles discovered), **`covered`** (parsed by the selected engine), **`skipped/unsupported`** (discovered but not parseable, each with a reason) — and, per finding, the package name, installed version, advisory/CVE id, severity, fixed version when published, **dependency kind (`direct` | `transitive`)**, and **path-to-direct-dependency when available, else `"no direct remediation path known"`**

- [x] **Scenario: mixed supported/unsupported lockfiles never silently drop**
  - **Given** a project carrying both a supported lockfile and an unsupported one — the canonical case being a Bun project with `bun.lock` (text, supported by osv-scanner since Bun ≥1.2) alongside a legacy `bun.lockb` (binary, **not** parsed by osv-scanner)
  - **When** the audit runs
  - **Then** `bun.lock` lands in `covered` and `bun.lockb` lands in `skipped/unsupported` with the reason + remediation hint ("regenerate as text `bun.lock` via `bun install` on Bun ≥1.2"), so a partially-covered project is never reported as a clean one

- [x] **Scenario: result status is decoupled from process exit**
  - **Given** any audit run
  - **When** it completes
  - **Then** it reports exactly one first-class **result status** — `clean` | `findings` | `unavailable` (engine binary absent) | `failed` (engine ran but errored / partial parse) — and the **process exit code defaults to `0` for all four** (advisory family); an opt-in `--exit-code` maps statuses → non-zero codes for consumer-owned CI, reflects **only the selected engine's status** (never multi-source assurance), and is never wired into any Agent0 `PreToolUse`/pre-commit path

- [x] **Scenario: clean project reports no findings, not silence**
  - **Given** a project whose locked dependencies have no known advisories in the engine's corpus
  - **When** the audit runs
  - **Then** result status is `clean` with an explicit "no known-vulnerable dependencies" line naming the ecosystems scanned, so `clean` is distinguishable from `unavailable`/`failed`

- [x] **Scenario: engine absent degrades to an advisory, never a hard failure**
  - **Given** the selected engine binary is not installed on the machine
  - **When** the audit is invoked
  - **Then** result status is `unavailable`, a one-line advisory names the install command and the ecosystems it *would* have scanned, and the process exits `0` — consistent with the `lint-advisory:` / `typecheck-advisory:` / `tdd-advisory:` family

- [x] **Scenario: findings carry a proposed remediation, not an auto-fix**
  - **Given** the scan produced at least one finding with a published fixed version
  - **When** results are surfaced
  - **Then** each fixable finding names the upgrade target, but the capacity does **not** modify any manifest or lockfile — remediation is the human's call (contract-not-promise, per `.claude/rules/delegation.md` § Why DONE_WHEN exists)

- [x] **Scenario: stable machine-readable output for tests and wrappers**
  - **Given** the audit is invoked with `--json`
  - **When** it completes
  - **Then** it emits a deterministic structured document (result status + coverage buckets + findings) on stdout, distinct from the human-readable default — bounded as **shape-only convenience, not a versioned wire contract** (field set may evolve; no schema-version key, deliberately — same posture as `/sdd list --json`)

- [x] The capacity ships as a runtime-neutral tool under `.agent0/` invoked by a thin Claude Code skill, and is documented for Codex CLI invocation — no Claude-only logic in the core.

- [x] A `.claude/rules/vuln-audit.md` rule documents the trigger surface, the engine choice + why, the override/escape grammar, and the non-goals, consistent with the existing rule family.

- [x] No commit gate and no install gate are introduced — the audit is never on the `PreToolUse(Bash)` or `.githooks/pre-commit` path.

## Non-goals

- **Gating install or commit.** The whole motivation (spec 112) is that install-time gating was the
  wrong shape; a commit gate is the same anti-pattern one step later. Detection + surfacing only.
- **Auto-upgrading dependencies.** No `npm audit fix`, no `osv-scanner fix --apply`, no `bun audit
  fix`, no manifest edits. The capacity proposes; the human disposes. (osv-scanner's `fix` command is
  explicitly risky on untrusted projects — it can trigger package-manager script execution.)
- **A default second scanner source.** v1 is **osv-scanner-only**. Adding `npm audit` / `pip-audit` /
  `bun audit` as a fallback or parallel-corroboration matrix immediately reintroduces the complexity
  the spec exists to avoid: divergent severity models, package-identity normalization, duplicate
  findings, per-ecosystem network/auth behavior, and ecosystem-specific remediation semantics. Even
  the tempting case — native `bun audit` for a `bun.lockb`-only project osv-scanner can't parse — is
  **out of v1**; that project's `bun.lockb` lands in `skipped/unsupported` with a migrate-to-`bun.lock`
  hint instead. A second source is deferred behind observed demand (rule-of-three): a follow-up
  trigger fires if real Agent0 projects surface advisories OSV lacks, or bun-only-with-`.lockb` forks
  ask for it.
- **A self-built reachability / call-graph analysis layer.** Reachability is surfaced **only as a
  pass-through field when the engine already computes it** — v1 builds no call-graph normalization of
  its own.
- **SBOM generation, container-image scanning, IaC misconfig, license compliance, secret scanning.**
  Each is a separate concern; secret scanning already exists (`secrets-scan`). v1 is dependency-CVE
  only.
- **Bundling or auto-installing the engine binary.** Agent0 ships the *mechanism* (detect, invoke,
  surface), not a vendored binary; install is the operator's responsibility, with an advisory when
  absent.
- **A standing audit log / dashboard / forensics surface.** Per the rule-of-three demand test
  (`.agent0/memory/feedback_speculative_observability.md`), no persisted JSONL audit trail is built.
  This is distinct from the one-shot `--json` output mode (which is in scope) — no *persisted* state,
  but a stable *output shape* for tests and wrappers.
- **Freezing a scanner as a shipped stack opinion.** The engine is a harness-internal mechanism
  choice, kept adaptive (stack-aware), not a frozen default imposed on consumer product code
  (`.agent0/memory/feedback_no_shipped_stack_opinions.md`).

## Open questions

_Resolved during the 2026-05-29 cross-model debate (see `debate.md`); retained here as the decision record._

- [x] **Engine — RESOLVED: osv-scanner-only for v1.** One static binary, 19+ lockfile ecosystems, OSV
  DB (free/transparent), call-graph FP reduction. The three-bucket coverage contract makes single-engine
  acceptable *because coverage is now honest*; the residual ~35% cross-tool miss is a source-corpus
  difference, recorded as the source-completeness caveat in § Intent, not closed by a second source.
  Trivy explicitly rejected (March-2026 supply-chain compromise, DB updates suspended).
- [x] **Trigger surface — RESOLVED: on-demand `/vuln-audit` skill only in v1.** Recurring cadence
  deferred to the generic `/routine` capacity (documented path, no v1 code). Staleness limitation
  stated in § Intent.
- [x] **Exit-code contract — RESOLVED: folded into the result-status model.** Default exit `0` for all
  four statuses; `--exit-code` is the consumer-owned opt-in.
- [ ] **Stack detection depth (still open, plan-time).** Trust osv-scanner's native directory walk for
  *matching*, but keep a thin Agent0-side lockfile→ecosystem map for the *coverage report* (so the
  three buckets and the "skipped/unsupported" reasons are honest). Confirm the map stays thin — a
  coverage-reporting aid, not a re-implementation of the engine's matcher. Owner: founder/plan.
- [ ] **Severity floor (still open, plan-time).** Report everything by default, group by severity; a
  `--severity` floor is a flag, not a default. Confirm at plan time.

## Context / references

- `docs/specs/120-vuln-audit/debate.md` — the cross-model debate (Claude Code ↔ Codex CLI) that
  resolved the engine/trigger/exit-code questions and added the source-completeness caveat + bun
  coverage handling. Converged in 2 rounds.
- `docs/specs/112-prune-supply-chain-and-secrets-advise/spec.md` § Non-goals — records this
  capacity as direction; the founder's "don't gate install, detect + act" framing is the seed.
- Reminder `r-2026-05-29-spec-the-vuln-audit-capacity` — carries the research + trigger-surface
  decision forward.
- `.claude/rules/delegation.md` § Why DONE_WHEN exists — the contract-not-promise discipline behind
  "propose, don't auto-fix".
- `.claude/rules/tdd.md` § Reading the validator advisory — the `<kind>-advisory:` non-blocking
  family this capacity's "engine absent" / "findings" output should mirror.
- `.agent0/memory/feedback_speculative_observability.md` — rule-of-three; why no audit log in v1.
- `.agent0/memory/feedback_no_shipped_stack_opinions.md` — why the engine stays a mechanism, not a
  frozen stack default.
- Research (2026-05-29/30): OSV-Scanner (Google) — multi-ecosystem, 19+ lockfile types incl. `bun.lock`
  (text, since Bun ≥1.2; `bun.lockb` binary NOT parsed), OSV DB, call-graph FP reduction, guided
  remediation: https://google.github.io/osv-scanner/ + supported-lockfiles
  https://google.github.io/osv-scanner/supported-languages-and-lockfiles/ ;
  Jit "OSV Scanner vs npm-audit": https://www.jit.io/resources/appsec-tools/osv-scanner-vs-npm-audit-a-detailed-comparison-of-sca-tools ;
  Trivy March-2026 supply-chain compromise + ~60–65% tool overlap: AppSec Santa SCA roundup
  https://appsecsanta.com/sca-tools/open-source-sca-tools ; pip-audit: https://pypi.org/project/pip-audit/ ;
  `bun audit` (Bun ≥1.2.15, GH Advisory DB, JSON, exit 0/1): https://bun.com/docs/pm/cli/audit
