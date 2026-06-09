# 183 — runtime-platform-audit — plan

_Drafted from `spec.md` on 2026-06-09. Update this file if implementation reveals the plan is wrong; do NOT silently diverge._

## Approach

Markdown + cron only; no shell/code. Generalize the routine prompt and migrate the cron registration. Full reasoning is in `spec.md` § Intent. Open questions resolved at implementation:

- **Retire mechanism:** delete `cc-platform-audit.md` (git history preserves it); `install-routines.sh` regenerates the crontab block from `.agent0/routines/*.md`, dropping the old entry. The gitignored old state dir is left orphaned (harmless).
- **Matrix-audit aggressiveness:** only runtimes in the audit allowlist (Claude Code, Codex CLI); future-runtime placeholder rows are skipped, not guessed.
- **Prompt shape:** an explicit audit-unit table at the top of the prompt body the routine walks — adding a runtime is a one-row edit.

## Files to touch

**Create:** `.agent0/routines/runtime-platform-audit.md` — generalized provider-neutral routine.
**Delete:** `.agent0/routines/cc-platform-audit.md` — superseded.
**Modify (deployment + dry-run finding):** crontab block via `install-routines.sh`; `.agent0/context/rules/runtime-capabilities.md` — `~29 events` → `~30 events` (Claude cell drift caught by the dry-run, the exact cell-value gap this routine closes).

## Alternatives considered

### Clone a separate `codex-platform-audit` routine

Rejected — symmetric but creates N routines for N runtimes (proliferation the governance doctrine discourages) and still misses the matrix cell-value gap. The generalized single routine is provider-neutral, matching Agent0's design.

### Extend `check-instruction-drift.sh` to parse matrix cell values

Rejected — that tool deliberately validates structure only (per `runtime-capabilities-maintenance.md`). Cell-value drift is LLM-judgment-against-upstream-docs work, which is the routine's job. Keeping them complementary avoids a brittle per-cell parser.

## Risks and unknowns

- **Risk:** the routine prompt now does ~3-4 web fetches + a matrix pass per run; one unreachable doc must not abort the sweep — handled by the `unreachable: <unit>` continue-clause in the prompt.
- **Unknown (surfaced by dry-run):** Codex docs now say `apply_patch` is "also matchable as `Edit`/`Write` in regex matchers", contradicting `codex-cli-hooks.md`'s flat "Edit|Write|MultiEdit won't fire on Codex" (which was verified against a live Codex `/hooks` session 2026-05-27). NOT applied — needs live-Codex re-verification before rewriting the memo. Recorded as a follow-up in `notes.md`.

## Research / citations

- Dry-run this session: Codex hooks 10/10 events match (no drift); matrix `~29`→`~30` drift caught + fixed; `spec-snapshot.md` vs agentskills.io confirmed no-drift earlier today.
- `.agent0/memory/{codex-cli-hooks,cc-platform-hooks,runtime-capabilities-maintenance}.md`; `.agent0/context/rules/{runtime-capabilities,routines}.md`; spec 099.
