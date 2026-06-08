# 169 - post-launch-maintenance-loop

_Created 2026-06-08._

**Status:** shipped
**UI impact:** none

## Intent

Define an Agent0 post-launch maintenance loop that helps consumer projects turn real production signals into reviewable agent work without making Agent0 the owner of production operations. The motivating concrete workflow is Sentry -> Linear -> Codex: a production error alert creates a work item, the work item delegates to a coding agent, and a human reviews the resulting branch or PR. Agent0 should generalize that pattern as an instrumented lifecycle surface for projects that used `/product` and for projects that adopted Agent0 later: observe -> intake -> delegate -> verify -> human review -> learn -> feed vN/refactor/hardening work back into SDD.

**Default v1 surface:** a shipped context rule plus copyable Markdown templates. The context rule explains the provider-neutral loop and safety discipline; templates help a consumer record its local mapping, issue/agent prompt boundary, review gate, and feedback sink. `/product` may link to the rule as an optional post-launch setup path. V1 deliberately does **not** add a new skill, hook, daemon, webhook receiver, API client, scheduler, validator, or hard gate. A future skill is a reopen candidate only after dogfood proves rule+templates are too passive.

**Scope admission brief:** this touches the continuous-evolution spine and security domain.

- **Layer:** continuous-evolution spine plus security domain.
- **Boundary:** **instrument-only**. Agent0 describes capability roles, evidence requirements, and safety checks; the consumer project owns observability, incident process, agent delegation, merge, release, and incident closure.
- **Evidence:** explicit founder directive in this session plus one external pattern studied live. There is not yet rule-of-three demand, a dogfood failure, or consumer propagation pain. That weak evidence intentionally caps v1 at docs/templates.
- **V1 posture:** documentation + templates, shipped to consumers; advisory only.
- **Blast radius:** consumer-shipped guidance and templates only; no credentials, telemetry payloads, provider config, or product-specific mappings in Agent0 upstream baseline files.
- **Validation:** static checks that the rule/templates exist and contain the required provider-neutral sections; grep checks that no credential placeholders or consumer-specific vendor choices are committed as configured defaults; one dogfood fixture that fills the templates for Sentry -> Linear -> Codex without enabling automation.
- **Non-goals:** no operation, webhooks, auto-delegation, auto-merge, deployment, rollback, or incident authority in Agent0.

## Acceptance criteria

- [x] **Scenario: `/product` foundations name the post-launch loop without installing it**
  - **Given** a future `/product` run reaches system-design, roadmap, or terminal handoff artifacts
  - **When** those artifacts reference post-launch maintenance
  - **Then** they point to the Agent0 maintenance-loop guidance as an optional consumer setup path, not as a required `/product` phase, and they do not assume a single vendor such as Sentry, Linear, or Codex

- [x] **Scenario: existing Agent0 consumer projects can adopt the loop**
  - **Given** a project did not originate from `/product` but has the Agent0 harness
  - **When** the operator asks how to wire post-launch bug-to-agent maintenance
  - **Then** Agent0 exposes standalone rule/template guidance that can be used without any `/product` artifacts and that asks the project to declare its chosen signal source, work hub, agent delegate, repo permission boundary, review gate, and feedback sink

- [x] **Scenario: tool mapping stays flexible**
  - **Given** a consumer chooses any supported combination such as Sentry, logs, uptime alerts, GitHub Actions, Linear, GitHub Issues, Codex, Claude, Cursor, Devin, or another coding agent
  - **When** the maintenance-loop guidance is applied
  - **Then** the resulting consumer artifact describes roles by capability class (`signal source`, `work hub`, `agent delegate`, `review gate`, `feedback sink`) and includes Sentry -> Linear -> Codex only as an example recipe, not the architecture

- [x] **Scenario: untrusted incident data is fenced from trusted agent instructions**
  - **Given** a production signal contains user-controlled strings such as exception messages, request URLs, tags, stack frames, logs, replay text, issue comments, or agent comments
  - **When** the work item is prepared for an agent
  - **Then** the template keeps trusted task instructions in a separate section from untrusted incident payload, labels the payload as untrusted data, and includes an adversarial example such as an exception message instructing the agent to install a package or ignore prior instructions

- [x] **Scenario: multi-hop prompt injection is named**
  - **Given** a maintenance item can flow across signal source -> work hub -> agent prompt -> branch/PR -> issue comment -> later re-ingestion
  - **When** the consumer fills the loop template
  - **Then** each hop is named as a potential injection or data-leak boundary, and the review gate requires checking both the generated code and the agent's interpretation of the untrusted payload

- [x] **Scenario: sensitive data is minimized before delegation**
  - **Given** a signal source can include secrets, PII, customer data, stack locals, replay text, request headers, tokens, or payment/health/minor-related data
  - **When** the consumer configures the maintenance loop
  - **Then** the guidance requires redaction/minimization before sending payloads to a work hub or third-party agent, and it records which provider receives which data class

- [x] **Scenario: agent authority is constrained**
  - **Given** a coding agent receives a maintenance item
  - **When** it proposes a fix
  - **Then** the loop requires least-privilege repo access, branch or PR output rather than direct production changes, no autonomous dependency installation from incident payload instructions, no auto-merge, and human review plus project validation evidence before release

- [x] **Scenario: maintenance work feeds back into SDD**
  - **Given** the agent fix reveals a recurring bug class, missing regression test, architecture hardening need, or product-learning signal
  - **When** the reviewer closes or escalates the maintenance item
  - **Then** the guidance routes durable follow-up into the right Agent0 surface: tests in the same diff, `/sdd new` for non-trivial hardening, project memory for factual lessons, reminder/routine for deferred or recurring checks, or `/product` vN discovery only when the signal changes product direction and the human explicitly chooses product discovery

- [x] **Scenario: cost and blast radius are explicit before automation**
  - **Given** a consumer wants automated issue creation or agent delegation from production signals
  - **When** they configure the loop
  - **Then** the guidance requires filters, rate limits or batching, duplicate suppression, provider cost notes, credential classification for every integration token, and a dry-run/manual-intake mode before any automatic delegation is enabled

- [x] A context rule for the maintenance loop exists and documents the provider-neutral roles, default v1 posture, trust boundaries, review gate, and feedback sink.
- [x] Copyable templates exist for at least: provider mapping, issue/agent prompt boundary, review checklist, and a Sentry -> Linear -> Codex example fixture.
- [x] The Sentry -> Linear -> Codex recipe is isolated to an example section or template; the provider-neutral guidance remains usable without Sentry, Linear, or Codex.
- [x] The shipped guidance includes at least one non-Sentry signal source category, one non-Linear work-hub option, and one non-Codex agent category.
- [x] The shipped files do not contain configured credentials, real DSNs, API keys, tokens, telemetry payloads, project-specific Linear team IDs, GitHub repo names, or vendor-specific local choices as Agent0 defaults.
- [x] No daemon, hosted service, webhook receiver, background scheduler, production observability integration, provider-specific API client, blocking hook, or validator is introduced.
- [x] Vendor-specific references are isolated so a future refresh can update them without rewriting the provider-neutral loop.

## Non-goals

- Build an Agent0-hosted or repo-local service that receives Sentry/GitHub/Linear webhooks.
- Auto-create, auto-assign, auto-run, auto-merge, auto-deploy, auto-rollback, or auto-close production incidents from Agent0 itself.
- Make Sentry, Linear, GitHub Issues, Codex, Claude, Cursor, Devin, or any other provider mandatory.
- Add a blocking validator, hook, or advisory in v1.
- Replace a team's incident-management, on-call, release, observability, security-response, or business workflow.
- Prescribe a consumer's incident process. Agent0 names capability roles and review evidence; the operator owns the operational process.
- Expand `/product` into a forever-running product-ops pipeline. `/product` may reference the loop, but the loop must stand alone for non-`/product` projects.
- Store production telemetry, customer data, credentials, Sentry event payloads, Linear/GitHub issue exports, or agent transcripts inside the Agent0 upstream repo.

## Open questions

- [x] **Template path:** resolved to `.agent0/context/templates/post-launch-maintenance-loop/` so the files ship with the existing `.agent0/context/**` sync surface without adding a new template root.
- [x] **Rule vs template split:** the rule stays concise and provider-neutral; copyable operational material lives in templates.
- [x] **Example freshness:** vendor-specific references are isolated to `examples/sentry-linear-codex.md`; no reminder/routine is added until a drift report or dogfood need appears.
- [x] **Future skill trigger:** promote to a portable skill only after dogfood shows rule+templates are too passive, such as repeated consumer setup misses or recurring unsafe prompt-boundary mistakes.

## Context / references

- `.agent0/context/rules/agent0-governance-doctrine.md` - Agent0 supports a continuous-evolution spine but should instrument, not own, consumer product operations; `continuous-evolution-spine` is a preserved follow-up, so this spec must stay narrow.
- `.agent0/context/rules/scope-admission-governance.md` - admission outcomes, instrument-only posture, evidence ladder, product-drift boundary, and hardening bar.
- `.agent0/context/rules/spec-driven.md` - this change is non-trivial, consumer-propagated, and security-adjacent, so it is spec-first.
- `.agent0/context/rules/secrets-scan.md` - credential-class framing and secret handling should inform the template's token/DSN guidance.
- `.claude/skills/product/SKILL.md` - `/product` produces the pre-build foundation and SDD handoff, not a running app; this loop belongs after release and must also serve non-`/product` projects.
- `.claude/skills/product/references/pipeline-coverage.md` - previous product-pipeline notes already described post-launch review as sibling infrastructure rather than a numbered pipeline step.
- Linear Sentry docs: Sentry integration can create/link Linear issues and can automatically create issues from Sentry alerts; private Linear teams are not supported by that integration. https://linear.app/docs/sentry
- Linear Agents docs: agents behave like app users, issue assignment delegates work to the agent while a human remains responsible, and agent guidance can carry workflow instructions. https://linear.app/docs/agents-in-linear
- Sentry alert rule docs: issue alerts can trigger on new/regressed/frequent issues and filter on occurrence count, assignment, release, category, tags, and event level; the older project issue-alert endpoint is now marked deprecated in favor of newer alert/monitor APIs. https://docs.sentry.io/api/alerts/create-an-issue-alert-rule-for-a-project/
- OpenAI Codex in Linear docs: Codex can be delegated from Linear and returns work through the Linear issue workflow. https://developers.openai.com/codex/integrations/linear
- GitHub Issues docs: issues can track bugs, tasks, features, and ideas; they support labels, milestones, assignments, projects, sub-issues, and API/CLI creation paths. https://docs.github.com/en/issues/tracking-your-work-with-issues/learning-about-issues/about-issues
- Claude review via `claude-exec`, session `24db416c-3005-4797-8213-f3416d8a451b`, captured at `.agent0/.runtime-state/claude-exec/20260608T005051Z-spec169-maintenance-loop-review/last-message.md`.
