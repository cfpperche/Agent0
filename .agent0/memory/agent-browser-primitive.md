---
name: agent-browser-primitive
description: spec 152 made agent-browser the primary browser primitive (wrapper .agent0/tools/agent-browser.sh); MCP is permanent fallback; daemon/port gotchas that cost real debug time
metadata:
  type: project
---

Spec 152 (`browser-primitive-consolidation`) adopted `agent-browser` (vercel-labs native-Rust CLI) as Agent0's **primary, runtime-neutral browser primitive**, wrapped by `.agent0/tools/agent-browser.sh` (caps/route/run/verify-contract/reset/audit). Playwright + Chrome DevTools MCP (`browser-auth.md`) are a **permanent fallback** (founder decision — never deleted; also the no-binary degradation path). Graduated from the accepted meeting `agent-browser-visual-inspection` (2026-06-05, Claude↔Codex↔founder).

**Routing rule** (the load-bearing anti-ambiguity): agent-browser is default; MCP fallback fires on exactly `fallback:{no-binary, no-chrome (AGENT0_BROWSER_NO_CHROME=1), override (AGENT0_BROWSER=mcp)}`. A missing *system* Chrome is NOT a fallback reason — agent-browser self-provides Chrome-for-Testing.

**Daemon/port gotchas verified empirically during the build (these ate hours — do not relearn):**
- `agent-browser close --all` **HANGS when no daemon is running** (rc=143 timeout). The wrapper's `reset` guards it (only-if-daemon + `timeout`). Never call it blind in a script.
- The daemon is **global and ignores launch options** (`--profile`/`--state`/`--session-name`) if already up. Either `agent-browser.sh reset` to rebind, or use **isolated `--session <name>`** (independent cookies within one live daemon) to avoid restart entirely.
- Kill the daemon **surgically**: select processes whose argv[0] ends in `agent-browser-linux*` (`pgrep -af agent-browser-linux | awk '$2 ~ /agent-browser-linux[^ ]*$/{print $1}'`). NEVER `pkill -f agent-browser` — it matches the calling shell's own command line and self-terminates (exit 144).
- `agent-browser wait <ms>` is an unreliable settle in fast scripts — use `wait <selector>` (presence) or a shell `sleep` for navigation.
- JSON envelope is `{success,data,error}`; `snapshot --json` → `.data.refs` keyed by ref `{name,role}`. Pinned `0.27.1`.

**Auth reuse** = `state save <file>` then `--state <file> open` (or `state load`); saved JSON is credential-class (gitignored under `.agent0/.runtime-state/agent-browser/`). Validated by the auth dogfood slice with a negative control (fresh session bounces to login → proves the saved state is load-bearing).

**Structural `audit` (spec 152.1)** = multi-page sweep (`agent-browser.sh audit <base> --paths …` → report + screenshots; gate = one h1 + main landmark + console≤max; vitals advisory). Built after a real `site/dist/` audit dogfood. **Parsing trap (verified, cost a false finding):** `grep -c 'level=1'` over the snapshot text ALSO matches `listitem [level=1]` (nesting) — a clean page with 1 `<h1>` + 7 list items mis-reads as `h1=8`. Use `parse-structure` / count `heading … [level=1[,\]]` lines only. The `audit` command owns this so nobody hand-rolls the bug.

**Human-in-the-loop auth (spec 152.2)** = `.agent0/tools/browser-login.sh <host>` (HUMAN runs one word → detached, isolated, dedicated-profile Chrome with CDP `:9222` at the login page) + `agent-browser.sh adopt <host>` (agent polls the CDP `/json` HTTP endpoint — non-disruptive, never navigates the human's tab — until the host page leaves the login flow, then saves state over CDP; `--detect-only` = "logged in yet?"). **Why this shape (verified):** an agent-spawned headed Chrome does NOT stay visible here — WSLg drops the window + the harness reaps the agent's process tree (the Chrome process survives but the window dies). The human must own the browser; the agent attaches via CDP. Also the right security posture (no `--auto-connect` to the main profile — dedicated profile only). Reuse the adopted state with `state load` + isolated `--session` (the `--state` + cold-daemon path is timing-flaky).

Suite (`.agent0/tests/agent-browser/run-all.sh`) = 11 files / 68 asserts: caps/route/policy/audit/structure/adopt-detect logic + live json-contract/visual/auth/audit/adopt slices. Live tests share the global daemon → `run-all.sh` tears it down between scenarios to avoid contention flakes. Related: [[od-grounding-dogfood]] (dogfood discipline), the speculative-observability demand-gate (152 cleared it via two named slices; 152.1's `audit` is demand from a real use, not nice-to-have).
