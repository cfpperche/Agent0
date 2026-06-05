---
paths:
  - ".agent0/tools/agent-browser.sh"
  - ".agent0/browser-policy.json"
  - ".agent0/browser-policy.json.example"
  - ".agent0/.runtime-state/agent-browser/**"
---

# Browser primitive

`agent-browser` (vercel-labs) is Agent0's **primary, runtime-neutral agent browser primitive** — the "eyes + hands" an agent drives against a web UI: navigate/control via CDP, accessibility-tree snapshot with stable LLM-friendly refs (`@e1`), click/fill/wait/drag, annotated screenshot + PDF, read text/HTML, cookies/storage/network/tabs/frames/dialogs, persistent auth, vitals, React introspection, JSON output. It is a native-Rust **CLI** (client-daemon over CDP), so Claude Code and Codex both invoke it through plain shell — **no per-runtime MCP wiring, no session restart**. This consolidates what used to be split across Playwright MCP + Chrome DevTools MCP. (spec 152, graduated from the accepted meeting `agent-browser-visual-inspection`.)

Playwright MCP + Chrome DevTools MCP (`browser-auth.md`) are **retained as a permanent, explicitly-routed fallback** — never deleted. The fallback doubles as the graceful-degradation path on machines where the `agent-browser` binary is not installed (a consumer fork's portability answer).

## The wrapper — `.agent0/tools/agent-browser.sh`

First-party browser work goes through the wrapper, not the raw binary. It adds the operational envelope: detection, routing, a policy guard, per-command audit, and a fail-readable JSON contract.

```
agent-browser.sh caps [--json]                       binary + chrome + pinned-version (tri-state)
agent-browser.sh route [task]                         → primary | fallback:<reason>
agent-browser.sh policy-eval <action> <target> [--confirm]   → allow|deny|confirm ; reason
agent-browser.sh run [--confirm] -- <agent-browser args...>   policy-gated, audited passthrough
agent-browser.sh verify-contract <url> <fixture.json> <outdir>   bounded visual-contract verify
agent-browser.sh audit <base-url> (--paths a,b,c|--paths-file f) [--out d] [--max-console N]   multi-page structural+console+vitals sweep (spec 152.1)
agent-browser.sh adopt <host> [--port 9222] [--detect-only]   attach to a human-logged-in CDP Chrome + save state (spec 152.2)
agent-browser.sh reset                                tear down the daemon (rebind launch options)
agent-browser.sh audit-tail [N]                       recent audit lines
```

The human-run launcher `.agent0/tools/browser-login.sh <host>` pairs with `adopt` (see § Human-in-the-loop auth).

The raw `agent-browser` CLI is fine for read-only ad-hoc inspection; route mutating/interactive flows through `run` so they are policy-gated and audited.

## Routing — primary vs MCP fallback (exhaustive)

`route` is deterministic. agent-browser is the default; the MCP fallback fires on **exactly three** conditions, nothing else:

1. **`fallback:no-binary`** — `agent-browser` is not on PATH.
2. **`fallback:no-chrome`** — no usable browser even via agent-browser's bundled Chrome-for-Testing (signalled by `AGENT0_BROWSER_NO_CHROME=1`; a missing *system* Chrome alone is NOT a fallback reason — agent-browser self-provides one).
3. **`fallback:override`** — `AGENT0_BROWSER=mcp` is set (explicit human/spec override).

A reserved `capability-gap` slot exists (`fallback:capability-gap:<task>`) but the v1 gap list is empty — agent-browser is a superset of the MCP surface. When `route` returns a fallback, use the Playwright/Chrome-DevTools MCP path in `browser-auth.md`. This is the single rule that keeps "two paths" from becoming an ambiguous agent instruction.

## Security — auditable hands

The bar for granting an agent "hands" is not *can it click* but **can a later human reconstruct WHY it clicked and WHICH guard allowed it**. The wrapper enforces a policy-as-file with safe built-in defaults (no file required); override via `.agent0/browser-policy.json` (template: `.agent0/browser-policy.json.example`):

- **Read-only** (`snapshot/screenshot/console/vitals/get/...`) → allowed + audited.
- **Same-origin interactive** (`click/fill/type/...` against an allowlisted host; `localhost`/`127.0.0.1`/`file://` are local) → allowed + audited.
- **External / sensitive** (cross-origin navigation; `upload/download/eval/cookies/storage/network/pdf`) → blocked unless the host is allowlisted or `--confirm` is passed (raw `eval` always needs `--confirm`). 

Every `run` appends a JSONL audit line (`ts/cmd/action/target/class/decision/guard`) under `.agent0/.runtime-state/agent-browser/` (gitignored). Profiles / saved `state` JSON are **credential-class** (gitignored, same posture as `browser-auth.md`'s `.browser-state/*.json` — see `secrets-scan.md`).

## Human-in-the-loop auth (spec 152.2 — the headed-login flow)

The headed human-login step **cannot be agent-spawned reliably** in this class of environment: WSLg drops the window surface and the harness reaps agent-spawned process trees (the Chrome process survives but the visible window dies). The robust, secure model is **the human owns the browser; the agent attaches over CDP**:

1. **Human runs one memorable command** — `bash .agent0/tools/browser-login.sh <host>` (`github` / `x` / `linkedin`, or any login URL). It launches a **dedicated, isolated, detached** Chrome with a CDP debug port (`9222`) at the login page. Detached so it survives the launching shell (terminal OR Claude `!`); dedicated profile (`.agent0/.runtime-state/agent-browser/profiles/login-<host>`) so only the account the human logs into is exposed — **never the human's main Chrome** (`--auto-connect` to the main profile is forbidden; see `browser-auth.md`).
2. **Human logs in** in that window. The agent never sees or handles credentials.
3. **Agent adopts** — `agent-browser.sh adopt <host> [--port 9222] [--timeout S]` polls the CDP `/json` endpoint (plain HTTP — **non-disruptive**, it never navigates the human's tab while they type) until a page on the host **leaves the login flow** (denylist: `login|signin|session|oauth|sso|challenge|checkpoint|authwall|i/flow`), then saves the session state (credential-class) over CDP. `--detect-only` reports completion without saving ("is the human logged in yet?"). After adopt, headless reuse via `--state`/`state load` works (§ Persistent auth).

The agent signals the start with `BROWSER_AUTH_REQUIRED: <host>` naming the exact `browser-login.sh` command. This is the agent-browser-native realization of `browser-auth.md`'s headed-login → save → reuse, with the CDP-attach twist the environment forces.

## Persistent auth

agent-browser's native `state save <file>` / `--state <file> open` (or `state load`) is the agent-browser equivalent of `browser-auth.md`'s headed-login → storage-state → reuse. The saved JSON holds cookies + localStorage and is credential-class. For an auth-gated flow: log in once (interactively or via `auth login`), `state save`, then reuse with `--state` on later runs. Playwright's headed-login lane remains the documented fallback.

## Visual-contract verification

`verify-contract <url> <fixture.json> <outdir>` is the bounded loop for verifying a `/product`→`/sdd` visual contract: it opens the URL, captures a11y snapshot + annotated screenshot + console + vitals, and asserts a fixture-spec (`{ "required": [{role,name}...], "max_console_errors": N }`) → a `PASS/FAIL` `report.json` + artifacts. The model reasons only over the residual, not over whether the page loaded.

## Structural audit (spec 152.1 — demand-validated by the real site-audit dogfood)

`audit <base-url> --paths a,b,c [--out dir] [--max-console N]` sweeps a page set and emits `report.{md,json}` + per-page screenshots. Per page it parses the rendered a11y tree for **structure** (exactly one level-1 heading + a `main` landmark + `nav`), counts console errors, and records vitals (advisory). Gate: a page fails if `h1 != 1`, no `main`, or console errors `> max`. The sweep owns daemon lifecycle + aggregation so callers don't hand-roll it.

The primitive owns the structural parsing because **hand-rolling it is error-prone**: the naive `grep -c 'level=1'` over the snapshot text ALSO matches `listitem [level=1]` (nesting depth), so a clean page with one `<h1>` and seven list items mis-reports as `h1=8`. `parse-structure` parses heading lines only (`heading … [level=1[,\]]`). This bug was hit for real auditing `site/dist/` by hand — the `audit` command exists so nobody repeats it. Vitals are meaningful only against a deployed/throttled target (on local static, LCP is always ~20ms).

## Activation (opt-in)

Opt-in, like the MCP recipes / `/image` / `/video`. Install once per machine:

```bash
npm install -g agent-browser        # or: brew install agent-browser / cargo install agent-browser
agent-browser install               # download Chrome-for-Testing (skip if a system Chrome exists)
```

The wrapper defaults the browser executable to the system Chrome via `AGENT_BROWSER_EXECUTABLE_PATH` when present. `bash .agent0/tools/doctor.sh` reports availability (tri-state under `=== browser primitive ===`). When the binary is absent the harness degrades to the MCP fallback rather than failing.

## Gotchas (verified empirically, spec 152 build)

- **`close --all` HANGS when no daemon is running.** The wrapper's `reset` guards this (only calls it when a daemon exists, with a timeout). Never call `agent-browser close --all` blind in a script.
- **The daemon is global and ignores launch options** (`--profile`/`--state`/`--session-name`) if already running. Use `agent-browser.sh reset` to rebind, or use **isolated `--session <name>`** (independent cookies within one daemon) to avoid restarts.
- **Kill the daemon surgically**: match processes whose argv[0] ends in `agent-browser-linux*`, never `pkill -f agent-browser` (that also kills the calling shell whose command line contains the pattern).
- **`agent-browser wait <ms>` is not a reliable settle in fast scripts** — prefer `wait <selector>` for presence, or a shell `sleep` for navigation settle.
- The JSON envelope is `{success, data, error}`; `snapshot --json` → `.data.refs` keyed by ref (`{name, role}`). Pinned version: see `PINNED_VERSION` in the wrapper.

## Cross-references

- `.agent0/context/rules/browser-auth.md` — the permanent Playwright/DevTools MCP fallback path (auth + driving).
- `.agent0/context/rules/secrets-scan.md` — credential-class framing for profiles/state files.
- `.agent0/context/rules/runtime-capabilities.md` — runtime-neutral capability matrix.
- `docs/specs/152-browser-primitive-consolidation/` — the spec; `.agent0/tests/agent-browser/` — the suite.
