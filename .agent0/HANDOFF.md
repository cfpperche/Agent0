# Session handoff

Canonical runtime-neutral handoff for Agent0 sessions. Claude Code injects/nags through hooks; Codex receives the same handoff after opting into the `.codex/config.toml.example` session-handoff hooks.

See `.claude/rules/session-handoff.md` for the protocol, 4 KB size discipline, fallback behavior, and reader-side truncation defense.

---

## Current State

**Spec 112 is committed; spec 113 (propagation-advise-multi-runtime) is implemented and live-validated in the working tree.** Recent commits include `edbaaf1 feat(112): remove supply-chain capacity + secrets-advise hook` and `624c46f docs(112): spec artifacts + vuln-audit direction`.

Spec 113 moves `propagation-advise.sh` from `.claude/hooks/` to `.agent0/hooks/`, rewrites it around `_memory-hook-lib.sh`, keeps the Claude `Edit|Write|MultiEdit` path, and adds Codex `apply_patch` added-line content scanning. It intentionally stays maintainer-only: `sync-harness.sh` excludes the new `.agent0/hooks/propagation-advise.sh` path, and `.codex/config.toml.example` must not gain a propagation-advise block.

Working tree shape: staged rename `R100 .claude/hooks/propagation-advise.sh -> .agent0/hooks/propagation-advise.sh`; unstaged edits in the moved hook, propagation docs/memory, `sync-harness.sh`, `.claude/settings.json`, and propagation-advisory tests; untracked spec 113 artifacts plus tests `12-codex-apply-patch-triggers.sh`, `13-codex-non-shipped-silent.sh`, and `14-codex-update-hunk-added-only.sh`.

Live dogfood status: CLOSED. The final root cause was channel format, not parser: Codex `PostToolUse` ignores plain stdout/stderr at exit 0, but JSON stdout with `hookSpecificOutput.additionalContext` is surfaced as developer context. `propagation-advise.sh` now emits Claude advisories on stderr and Codex advisories as one JSON stdout object. Live Codex dogfood created `.claude/rules/_dogfood-113d.md` and surfaced `propagation-advisory: spec-NNN in .claude/rules/_dogfood-113d.md:1 — this refs spec 080`; non-shipped `docs/specs/_scratch-113d.md` and override `.claude/rules/_dogfood-113-override-d.md` stayed silent. Final checks: propagation-advisory suite 14/14 green, `git diff --check` clean, `sync-harness.sh --check --agent0-path=/home/goat/Agent0 /home/goat/Agent0` clean, and `.codex/config.toml.example` has no propagation-advise block. The `_dogfood-113-live.md` throwaway was removed at closeout (its live-proof purpose served; it was a leak file in a shipped path). 113 is shipped + validated, uncommitted pending the user's commit go. Pre-existing untracked `docs/specs/091-sdd-debate-runner/` is out of scope.

## Active Work

- _None in flight._ Spec 113 is ready for Claude/human approval and commit.
- `docs/specs/113-propagation-advise-multi-runtime/{spec,tasks,notes}.md` now record the live Codex `apply_patch` positive path as passed end-to-end via JSON stdout `additionalContext`.

## Next Actions

1. Claude/human approval of the spec 113 implementation report.
2. Stage and commit spec 113 when approved. Suggested: `feat(113): port propagation advisory to runtime-neutral hook`.
3. Remaining hook-migration follow-up after 113: runtime-introspect pair (`runtime-capture.sh` / `runtime-pre-mark.sh`). Vuln-audit remains the replacement direction for removed supply-chain blocking (`r-2026-05-29-spec-the-vuln-audit-capacity`).

## Decisions & Gotchas

- **Maintainer-only means no shipped Codex example block.** Codex activation for propagation-advise belongs in the maintainer's gitignored `.codex/config.toml`, not `.codex/config.toml.example`, or consumers get a dangling reference to a non-shipped hook.
- **The dogfood file is intentionally dirty and intentionally leaks `spec 080`.** It exists to prove the real Codex `apply_patch` PostToolUse path; do not clean it up automatically.
- **Staged/unstaged split matters:** the hook move is staged as a rename, while the actual rewrite is unstaged on the moved file. Preserve that state unless intentionally restaging.
- **Settings changes need a fresh runtime session to be naturally live.** Direct tests/simulations can validate the script shape, but real Codex proof is the apply_patch dogfood path.
- **Spec 112 lesson still applies:** migration is also a pruning moment. Removed supply-chain/secrets-advise capacities stay removed; vuln-audit should detect vulnerable installed libraries rather than blocking installs.
