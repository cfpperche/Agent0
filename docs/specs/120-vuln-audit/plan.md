# 120 — vuln-audit — plan

_Drafted from `spec.md` on 2026-05-30. Update this file if implementation reveals the plan is wrong; do NOT silently diverge._

## Approach

Ship one runtime-neutral bash tool, `.agent0/tools/vuln-audit.sh`, that is the whole engine; a thin
Claude Code skill and a rule wrap it for discoverability and documentation. The tool: (1) walks the
target dir for known lockfiles using a **thin lockfile→ecosystem map** (bash assoc array; the map
exists only to build the honest coverage report, not to re-implement matching); (2) shells out to
`osv-scanner scan --format json --recursive <path>` once (osv-scanner natively handles every
supported ecosystem in a single pass — this is why it's the engine); (3) parses the JSON with `jq`
into the three coverage buckets + per-finding records (package, version, advisory id + CVE alias,
severity from CVSS, fixed version, `direct|transitive`, path-to-direct-dep); (4) emits a
human-readable report by default or a stable structured doc under `--json`; (5) maps an internal
**result status** (`clean|findings|unavailable|failed`) that is independent of the process exit code
(always `0` unless `--exit-code` is passed).

Order: tests-first per `.claude/rules/tdd.md` — build a **fake `osv-scanner` stub** (canned JSON
fixtures on a temp PATH, mirroring `secrets-scan/`'s fake-command pattern) so every status, bucket,
and flag is exercised without the real binary or network. Then the tool, then the skill + rule +
CLAUDE.md/AGENTS.md managed-block section, then sync-harness manifest + baseline.

## Files to touch

**Create:**
- `.agent0/tools/vuln-audit.sh` — the runtime-neutral engine (detect → invoke osv-scanner → parse → bucket → status → render). Flags: `[path]` (default `.`), `--json`, `--exit-code`, `--severity <low|moderate|high|critical>`.
- `.claude/skills/vuln-audit/SKILL.md` — thin skill (tier `agentskills-portable`): describes when to run, invokes the tool, surfaces output. No business logic.
- `.claude/rules/vuln-audit.md` — capacity rule: trigger surface (on-demand, no gate), engine choice + why (osv-scanner-only; Trivy rejected; source-completeness caveat), result-status + `--exit-code` semantics, `--json` shape-only posture, override/escape grammar, non-goals.
- `.agent0/tests/vuln-audit/run-all.sh` + numbered scenarios:
  - `01-findings-status.sh` — osv stub returns vulns → status `findings`, per-finding fields present, exit 0.
  - `02-clean-status.sh` — stub returns packages, no vulns → status `clean`, "no known-vulnerable" line.
  - `03-unavailable.sh` — no `osv-scanner` on PATH → status `unavailable`, install advisory, exit 0.
  - `04-failed.sh` — stub exits 127 → status `failed`, exit 0.
  - `05-three-bucket-coverage.sh` — mixed tree → `found`/`covered`/`skipped` buckets correct.
  - `06-bun-lockb-skipped.sh` — `bun.lock` covered + `bun.lockb` skipped with migrate hint (canonical mixed case).
  - `07-json-shape.sh` — `--json` emits deterministic doc (status + buckets + findings), parseable by `jq`.
  - `08-exit-code-optin.sh` — `--exit-code` maps `findings`→non-zero; default run stays 0.
  - `09-transitive-path.sh` — transitive finding carries `path-to-direct-dependency`; unresolvable → "no direct remediation path known".
  - `10-severity-floor.sh` — `--severity high` filters out moderate findings.

**Modify:**
- `CLAUDE.md` — add `## Vuln audit` section inside the `AGENT0:BEGIN/END` managed block.
- `AGENTS.md` — mirror the same one-line index entry (baseline-tracked Codex entrypoint).
- `README.md` — one-line capacity mention if it carries a capacity list (verify at impl time).
- `.agent0/tools/sync-harness.sh` — confirm the new tool/skill/rule are covered by existing manifest globs (`.agent0/tools|*.sh`, `.claude/skills`, `.claude/rules`); add `.claude/harness-sync-baseline.json` entries so consumers receive the capacity.

**Delete:** _(none)_

## Alternatives considered

### Python tool instead of bash + jq
Rejected — the harness convention is bash tools (`.agent0/tools/*.sh`) with `jq` for JSON (already a
de-facto dep across the hooks). A Python helper is only warranted for YAML mutation (the `memory`/
`remind` precedent); here the input is JSON and the logic is shell-shaped (detect, shell-out, parse,
render). Bash + jq keeps it `agentskills-portable` and dependency-light.

### osv-scanner native dir-walk only, no Agent0-side lockfile map
Rejected — osv-scanner reports what it *covered* but not what it *skipped as unsupported*. Without a
thin Agent0-side map of known lockfiles, the `skipped/unsupported` bucket can't be populated and
"stack-aware" silently degrades to "whatever the engine noticed" (the exact defect Codex critique #1
flagged). The map stays thin: basename → {ecosystem, osv-supported bool}.

### Second scanner source / native-tool fallback matrix (incl. `bun audit`)
Rejected per the debate — divergent severity models, package-identity normalization, duplicate
findings. The `bun.lockb`-only case (osv-scanner can't parse it) is handled by the `skipped` bucket +
migrate-to-`bun.lock` hint, not a `bun audit` fallback. Deferred behind observed demand.

## Risks and unknowns

- **osv-scanner JSON shape (V1 vs V2 2026).** Severity lives in CVSS sub-objects and fixed-version in
  `affected[].ranges[].events[].fixed` — extraction is fiddly and version-sensitive. Mitigation:
  parse defensively (treat missing severity as `UNKNOWN`, missing fixed as "no fix published"); pin
  the parsing to fields verified against a real `osv-scanner scan --format json` sample at impl time.
- **`direct|transitive` + path may not be in base JSON.** osv-scanner's dependency-path / call
  analysis is partly `experimental`. If the base output lacks a reliable direct/transitive signal,
  degrade to `transitive: unknown` + "no direct remediation path known" rather than fabricate (the
  spec already allows the unknown branch).
- **`jq` availability.** Assumed present (harness-wide assumption). If absent, emit a one-line
  advisory and exit 0 (fail-open, advisory family) — same posture as the engine-absent path.
- **Real-binary smoke test is network-bound.** The 10 scenarios use a fake stub (deterministic,
  offline). A single manual real-osv-scanner smoke run is a post-merge reminder, not a CI test
  (mirrors the OD `--bump` reminder precedent).

## Research / citations

- OSV-Scanner JSON output + exit codes (`0` clean / `1` findings / `127` error / `128` no packages; JSON to stdout, logs to stderr): https://google.github.io/osv-scanner/output/ + https://google.github.io/osv-scanner/usage/
- Supported lockfiles incl. `bun.lock` text (not `bun.lockb` binary): https://google.github.io/osv-scanner/supported-languages-and-lockfiles/
- `bun audit` (deferred fallback, Bun ≥1.2.15): https://bun.com/docs/pm/cli/audit
- Trivy March-2026 supply-chain compromise + ~60–65% cross-tool overlap: https://appsecsanta.com/sca-tools/open-source-sca-tools
- Fake-command test pattern: `.agent0/tests/secrets-scan/` (canned-binary-on-temp-PATH precedent).
- Debate record: `docs/specs/120-vuln-audit/debate.md`.
