# 111 — delegation-verify-subagent-stop — notes

_Created 2026-05-29._

_In-flight design memory for this spec — decisions, deviations, tradeoffs, and open questions surfaced **while building** that weren't pre-empted by `spec.md` or `plan.md`. Append-only by convention. See `.claude/rules/spec-driven.md` § The four artifacts for purpose, and `.claude/rules/delegation.md` § The 5-field handoff for how sub-agents integrate._

**Entry shape:** `### YYYY-MM-DD — <author> — <one-line title>` followed by free-prose body. `<author>` is `parent` for the orchestrating agent, or the `subagent_type` (e.g. `general-purpose`, `Explore`) for delegated work.

**Routing rubric:** decision made under ambiguity → §1 Design decisions. Intentional departure from `plan.md` → §2 Deviations. Alternative weighed and chosen mid-flight → §3 Tradeoffs. Question surfaced during build, no answer yet → §4 Open questions. Sections may stay empty; the rubric is a guide, not a quota.

## Design decisions

_Choices made where the spec/plan was ambiguous. The decision itself + why this option over others considered in the moment._

### 2026-05-29 — parent — parallel-hook execution kills the sentinel design; counter-contract replaces it

Resolved the bulk of task 6 (the chain-semantics spike) by docs — `https://code.claude.com/docs/en/hooks` — **before** any cold-restart dogfood, per the verify-not-assume discipline. Findings: (1) exit-2 on `SubagentStop` "Prevents the subagent from stopping" (block + continue) — confirms the block mechanism; (2) **"All matching hooks run in parallel"** with no documented short-circuit — so `delegation-verify.sh` and `delegation-stop.sh` run concurrently, NOT in registration order; (3) `agent_id` is present on `SubagentStop` (OQ1 field-exists confirmed; preservation across a continuation still live-only); (4) the docs page omits `stop_hook_active`, BUT `delegation-stop.sh:54` already reads `.stop_hook_active` from the payload — so the field IS delivered on `SubagentStop`.

**Consequence — the plan's sentinel/ordering/close-row-suppression design is non-viable.** Two parallel hooks cannot coordinate "verify blocks → stop skips the close row" without a race (`delegation-stop.sh` may append the close row before `delegation-verify.sh` writes any sentinel).

**Replacement design (cleaner, and respects the spec-110 non-goal of leaving `delegation-stop.sh` untouched):**
- `delegation-verify.sh` becomes the WRITER of `.claude/.delegation-state/agents/<agent_id>/consecutive_failures` — the exact path `delegation-stop.sh:94` already READS for its `exit` field (a path the deleted `post-edit-validate.sh` never wrote — it wrote `agents/<agent_id>` as a flat file, a latent mismatch this fixes).
- `delegation-stop.sh` stays **byte-for-byte unchanged**: it keeps writing a close row on every stop (parallel, no suppression) and reads the counter for `exit`. The close row's `exit` field now reflects verify state. The contract between the two hooks is the counter file, not a sentinel.
- Escalation uses `stop_hook_active` as the primary guard (Claude's native stop-loop-prevention signal), NOT the agent_id counter — making the design robust to OQ1 regardless: fail + `!stop_hook_active` → exit 2 (block + one continuation) + increment counter; fail + `stop_hook_active` (already continued once) → exit 0 (accept closure as partial-result, do not block again) + increment. Pass → reset counter to 0. The counter is forensic (feeds `exit`); `stop_hook_active` is the loop guard.
- `delegation-verify.sh` writes its own `verify` audit rows (`event:"subagent-verify"`, `decision: pass|blocked|exhausted`) for forensics — adjacent to the close row, correlated by `agent_id`.

This supersedes plan.md § Approach (sentinel) and tasks 6–8; spec.md scenario 2 ("NO close row") is revised to "close row carries `exit` reflecting verify + a `subagent-verify` row records the block." Live cold-restart dogfood still required to confirm exit-2 actually continues the sub-agent + `agent_id`/`stop_hook_active` runtime values (can't run in-session — settings.json hooks load only at cold start).

### 2026-05-29 — parent — LIVE Claude dogfood PASSED (pass path) + parallel execution empirically confirmed

Initial assumption (cold-restart required to load the new `SubagentStop` registration) was **empirically wrong** — verified by inspecting `.agent0/delegation-audit.jsonl` instead of assuming. The hook fired live in-session:

- A controlled dispatch (`Agent` tool, `general-purpose` sub-agent `acb46fdc0a91cab59`, a read-only probe) closed at `2026-05-29T14:08:53Z`. Both `SubagentStop` hooks fired **at the same ts**:
  ```json
  {"event":"subagent-stop","agent_id":"acb46fdc0a91cab59","decision":null,"runtime":"claude-code","ts":"2026-05-29T14:08:53Z"}
  {"event":"subagent-verify","agent_id":"acb46fdc0a91cab59","agent_type":"general-purpose","decision":"pass","validator_exit":0,"stop_hook_active":false,"runtime":"claude-code","ts":"2026-05-29T14:08:53Z"}
  ```
- An earlier organic stop (`a6de78d9856a76348`, 14:07:11Z) showed the same pass-path fire; a pre-registration stop (`a5707de4cf3954546`, 13:42:15Z) shows only a `subagent-stop` row (no verify) — the before/after boundary confirms the registration took effect mid-session.

**What this proves (Claude, pass path):** the registration fires at a real `SubagentStop`; the validator runs (Agent0 has no stack → `ok=true` → `decision:pass`, `validator_exit:0`); the row is keyed by the real `agent_id` with `runtime:claude-code`. **Same-ts dual rows confirm the hooks run in PARALLEL** — the empirical basis for the counter-contract pivot (a sentinel could not have coordinated these two concurrent writers).

**Still synthetic-only (not live):** the block (`decision:blocked`, exit 2) and exhausted (`decision:exhausted`) paths — a live fire needs the validator to return `ok=false`, which requires a stack-detected project with failing tests (Agent0 has none; creating one would pollute the repo). Covered by `02-fail-blocks.sh` / `03-exhausted-partial.sh` via direct invocation with an `ok=false` stub. The block path uses the identical fire mechanism the pass path just proved live — only the validator result differs.

**Codex:** still pending (prompt below). The two runtime OQs (agent_id preservation across a continuation; stop_hook_active flip) need a live FAIL-path continuation, deferred to the block-path live dogfood on a stack project.

## Deviations

_Places where implementation intentionally departed from `plan.md`. The departure + the reason it was necessary or better._

### {{YYYY-MM-DD}} — {{author}} — {{one-line title}}

{{free-prose body — what the plan said, what was done instead, why}}

## Tradeoffs

_Alternatives weighed during implementation (not at plan time). The chosen path + what was given up + why the tradeoff was worth it._

### {{YYYY-MM-DD}} — {{author}} — {{one-line title}}

{{free-prose body — options considered in-flight, chosen path, accepted cost}}

## Open questions

_Questions surfaced during build that the implementer couldn't resolve alone. Owner (who decides) or path to resolution if known. Promote answered questions to `spec.md` § Open questions or as retroactive acceptance scenarios when the spec is updated._

### 2026-05-29 — parent — live dogfood prompts (OQ1/OQ2 resolution path)

OQ1 (does a continued sub-agent preserve `agent_id`?) and OQ2 (`stop_hook_active` across a blocked stop) are answerable only by a live cold-restart dogfood — the hook logic is fully validated via the 8-scenario synthetic suite, but the runtime VALUES need a real `SubagentStop` fire. The design is robust either way (escalation keys on `stop_hook_active`, not `agent_id` continuity), so these confirm rather than gate.

**Claude (cold restart REQUIRED — settings.json hooks load only at cold start):** after restart, dispatch a delegated sub-agent against a stack-detected scratch repo with failing tests → expect close blocked (exit 2, one continuation) + `subagent-verify`/`decision:blocked` row; then passing close → `decision:pass` accepted. Confirm `agent_id` preserved across the continuation + `stop_hook_active` flips true.

**Codex dogfood prompt:**

```
TAREFA: Live dogfood do hook delegation-verify.sh no runtime Codex CLI (spec 111, scenario 4).
CONTEXTO:
- .agent0/hooks/delegation-verify.sh roda o validator no SubagentStop, keyed por agent_id; bloqueia via decision:"block"/exit-2 na falha, aceita como partial-result no stop continuado (stop_hook_active).
- O bloco SubagentStop comentado já existe no .codex/config.toml.example (antes do delegation-stop).
- Audit canônico: .agent0/delegation-audit.jsonl (rows event:"subagent-verify").
PASSOS:
1. Habilitar no .codex/config.toml real o bloco [[hooks.SubagentStop]] do delegation-verify.sh (antes do delegation-stop.sh).
2. Cold restart do Codex + trust do hook novo.
3. Num repo com stack detectada (ex: package.json com "test" que falha), delegar um subagente cujo trabalho deixe os testes falhando → esperar fechamento bloqueado (decision:"block") com row subagent-verify/decision:blocked/runtime:"codex-cli".
4. Deixar continuar e ainda falhar → esperar decision:exhausted (partial-result), sem loop infinito.
5. VERIFICAR e REPORTAR: agent_id preservado no stop continuado? stop_hook_active vira true? Colar as rows reais. NÃO afirmar sucesso sem as rows (lição 108/109).
DONE_WHEN: rows subagent-verify com runtime:"codex-cli" (blocked + exhausted) registradas neste notes.md + resposta às 2 OQs.
```

### 2026-05-29 — parent — LIVE Codex dogfood PASSED (block + exhausted path)

Runtime proof was collected with Codex TUI, not `codex exec`: `codex-cli 0.135.0`, real `.codex/config.toml` `[[hooks.SubagentStop]]` enabled for `delegation-verify.sh` before `delegation-stop.sh`, cold-started via `codex --no-alt-screen -C /home/goat/Agent0 -s read-only ...`, then trusted the two changed `SubagentStop` hooks. A temporary root `package.json` supplied a stack-detected failing `npm test --silent` (`agent0-dogfood-failing-test`) and was removed after the proof. Earlier `codex exec` probes produced `subagent-start` rows only; the real `SubagentStop`/verify proof came from the TUI runtime surface.

Canonical audit rows from `.agent0/delegation-audit.jsonl`:

```json
{"schema_version":1,"runtime":"codex-cli","ts":"2026-05-29T14:23:42Z","event":"subagent-verify","session_id":"019e741d-d76b-7ec3-a742-f2ba30252f7d","agent_id":"019e741e-4344-7b93-b782-a1f10484e1da","agent_type":"default","decision":"blocked","validator_exit":1,"stop_hook_active":false}
{"schema_version":1,"runtime":"codex-cli","ts":"2026-05-29T14:23:55Z","event":"subagent-verify","session_id":"019e741d-d76b-7ec3-a742-f2ba30252f7d","agent_id":"019e741e-4344-7b93-b782-a1f10484e1da","agent_type":"default","decision":"exhausted","validator_exit":1,"stop_hook_active":true}
```

OQ answers:

- OQ1, continued sub-agent `agent_id` preservation: **yes**. The blocked and exhausted rows both use `agent_id:"019e741e-4344-7b93-b782-a1f10484e1da"`.
- OQ2, `stop_hook_active` across blocked stop: **yes**. The first failing close has `stop_hook_active:false` and `decision:"blocked"`; the continued failing close has `stop_hook_active:true` and `decision:"exhausted"`. Codex returned to the parent prompt after the exhausted row, so no infinite stop loop occurred.
