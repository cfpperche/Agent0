#!/usr/bin/env bash
# Agent0 `agent-browser` — harness wrapper / operational envelope around the
# vercel-labs `agent-browser` CLI (spec 152, browser-primitive-consolidation).
#
# Turns the raw CLI into Agent0's PRIMARY, runtime-neutral agent browser
# primitive (eyes + hands + observe) with: binary/Chrome detection, deterministic
# primary-vs-MCP-fallback routing, a policy-as-file guard, per-command audit
# logging, and a fail-readable JSON contract. Playwright / Chrome DevTools MCP
# remain a PERMANENT, explicitly-routed fallback (never deleted) — and the
# graceful-degradation path when this binary is absent. See
# .agent0/context/rules/browser-primitive.md.
#
# Runtime-neutral: Claude Code and Codex CLI both invoke it through plain shell,
# NO per-runtime MCP wiring, NO session restart. Reports + gates; the heavy
# lifting is delegated to `agent-browser` itself.
#
# Subcommands:
#   caps [--json]                       detect binary+chrome+version (tri-state)
#   route [task]                        print: primary | fallback:<reason>
#   policy-eval <action> <target> [--confirm]   decision: allow|deny|confirm ; reason
#   run [--confirm] -- <agent-browser args...>   policy-gated, audited passthrough
#   verify-contract <url> <fixture.json> <outdir>   bounded visual-contract verify
#   audit <base-url> (--paths a,b,c|--paths-file f) [--out d] [--max-console N]   multi-page structural+console+vitals sweep
#   adopt <host> [--port 9222] [--domain d] [--timeout S] [--state f] [--detect-only]   attach to a human-logged-in CDP Chrome, save state (152.2)
#   audit-tail [N]                      show recent audit lines
#   help
#
# Exit: 0 ok; 2 policy-denied; 3 usage; 4 fallback-required (no binary).

set -uo pipefail

# --- pinned version (advisory drift, never blocks) --------------------------
PINNED_VERSION="0.27.1"

# --- roots ------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -n "${AGENT0_PROJECT_DIR:-}" ]; then
  PROJECT_DIR="$AGENT0_PROJECT_DIR"
else
  PROJECT_DIR="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel 2>/dev/null || true)"
  [ -n "$PROJECT_DIR" ] || PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
fi

POLICY_FILE="${AGENT0_BROWSER_POLICY:-$PROJECT_DIR/.agent0/browser-policy.json}"
AUDIT_DIR="$PROJECT_DIR/.agent0/.runtime-state/agent-browser"

# --- binary + chrome detection (overridable for tests) ----------------------
# AGENT0_BROWSER_BIN lets tests mask/redirect the binary; default resolves PATH.
ab_bin() { echo "${AGENT0_BROWSER_BIN:-agent-browser}"; }
have_binary() { command -v "$(ab_bin)" >/dev/null 2>&1; }

# Resolve a usable Chrome executable: explicit env wins, else common system paths.
resolve_chrome() {
  if [ -n "${AGENT_BROWSER_EXECUTABLE_PATH:-}" ] && [ -x "${AGENT_BROWSER_EXECUTABLE_PATH}" ]; then
    echo "${AGENT_BROWSER_EXECUTABLE_PATH}"; return 0
  fi
  local c
  for c in google-chrome google-chrome-stable chromium chromium-browser; do
    if command -v "$c" >/dev/null 2>&1; then command -v "$c"; return 0; fi
  done
  # agent-browser may ship/download its own Chrome-for-Testing; treat as present.
  return 1
}

detected_version() {
  have_binary || return 1
  "$(ab_bin)" --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1
}

# --- policy (jq-parsed JSON; safe built-in defaults when no file) -----------
# Defaults: mode=audit; localhost/127.0.0.1 allowlisted; file:// always local.
DEFAULT_ALLOWLIST='["localhost","127.0.0.1"]'
DEFAULT_SENSITIVE='["upload","download","eval","cookies","storage","network","pdf"]'

policy_get() { # policy_get <jq-filter> <fallback-json>
  local filter="$1" fallback="$2"
  if [ -f "$POLICY_FILE" ]; then
    jq -c "$filter // ($fallback)" "$POLICY_FILE" 2>/dev/null || printf '%s' "$fallback"
  else
    printf '%s' "$fallback"
  fi
}
policy_mode()      { policy_get '.mode' '"audit"' | tr -d '"'; }
policy_allowlist() { policy_get '.allowlist' "$DEFAULT_ALLOWLIST"; }
policy_sensitive() { policy_get '.sensitive_actions' "$DEFAULT_SENSITIVE"; }

# Classify an agent-browser subcommand token into read-only|interactive|sensitive.
READONLY_ACTIONS=" open snapshot screenshot console errors vitals get is find title url count box styles diff wait scrollintoview highlight react "
INTERACTIVE_ACTIONS=" click dblclick type fill press keyboard hover focus check uncheck select drag scroll mouse set tab pushstate "
classify_action() { # classify_action <action>
  local a="$1"
  if printf '%s' "$(policy_sensitive)" | jq -e --arg a "$a" 'index($a) != null' >/dev/null 2>&1; then
    echo "sensitive"; return
  fi
  case "$READONLY_ACTIONS" in *" $a "*) echo "read-only"; return;; esac
  case "$INTERACTIVE_ACTIONS" in *" $a "*) echo "interactive"; return;; esac
  echo "sensitive"  # unknown ⇒ treat as sensitive (fail-safe)
}

# Is a target host allowlisted? file:// and allowlisted hosts ⇒ yes.
host_allowlisted() { # host_allowlisted <target>
  local t="$1" host
  case "$t" in
    file://*|/*|./*|"") return 0 ;;  # local file paths / refs / empty ⇒ local
  esac
  host="$(printf '%s' "$t" | sed -E 's#^[a-zA-Z]+://##; s#[/?#].*$##; s#:[0-9]+$##')"
  [ -n "$host" ] || return 0
  printf '%s' "$(policy_allowlist)" | jq -e --arg h "$host" 'index($h) != null' >/dev/null 2>&1
}

# policy_eval <action> <target> [--confirm] → prints "decision\treason"; exit 0 allow,2 deny.
policy_eval() {
  local action="$1" target="${2:-}" confirm="no"
  [ "${3:-}" = "--confirm" ] && confirm="yes"
  local class; class="$(classify_action "$action")"
  case "$class" in
    read-only)
      # cross-origin navigation to a non-allowlisted host is still externally sensitive
      if [ "$action" = "open" ] && ! host_allowlisted "$target"; then
        if [ "$confirm" = "yes" ]; then echo -e "allow\texternal-nav-confirmed"; return 0
        else echo -e "confirm\texternal-nav-needs-confirm"; return 2; fi
      fi
      echo -e "allow\tread-only"; return 0 ;;
    interactive)
      if host_allowlisted "$target"; then echo -e "allow\tsame-origin-interactive"; return 0
      elif [ "$confirm" = "yes" ]; then echo -e "allow\texternal-interactive-confirmed"; return 0
      else echo -e "confirm\texternal-interactive-needs-confirm"; return 2; fi ;;
    sensitive)
      if [ "$confirm" = "yes" ]; then echo -e "allow\tsensitive-confirmed"; return 0
      elif host_allowlisted "$target" && [ "$action" != "eval" ]; then echo -e "allow\tsensitive-allowlisted"; return 0
      else echo -e "deny\tsensitive-needs-confirm"; return 2; fi ;;
  esac
}

# --- audit ------------------------------------------------------------------
audit_line() { # audit_line <cmd> <action> <target> <class> <decision> <guard>
  mkdir -p "$AUDIT_DIR" 2>/dev/null || return 0
  local ts; ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  local f="$AUDIT_DIR/audit-$(date -u +%Y-%m-%d).jsonl"
  jq -cn --arg ts "$ts" --arg cmd "$1" --arg action "$2" --arg target "$3" \
        --arg class "$4" --arg decision "$5" --arg guard "$6" \
        '{ts:$ts,cmd:$cmd,action:$action,target:$target,class:$class,decision:$decision,guard:$guard}' \
        >> "$f" 2>/dev/null || true
}

# --- routing ----------------------------------------------------------------
# Default = primary (agent-browser). MCP fallback fires on EXACTLY three
# conditions: binary/Chrome absent · named capability gap · explicit override.
CAPABILITY_GAPS=" "   # v1: none — agent-browser is a superset. Reserved slot.
route() {
  local task="${1:-}"
  if [ "${AGENT0_BROWSER:-}" = "mcp" ]; then echo "fallback:override"; return 0; fi
  if ! have_binary; then echo "fallback:no-binary"; return 0; fi
  # agent-browser self-provides Chrome-for-Testing, so a missing SYSTEM Chrome is
  # NOT itself a fallback reason — only an explicit "no usable browser" signal is
  # (AGENT0_BROWSER_NO_CHROME=1), surfaced by doctor when even the bundled browser
  # is unavailable.
  if [ "${AGENT0_BROWSER_NO_CHROME:-}" = "1" ]; then echo "fallback:no-chrome"; return 0; fi
  if [ -n "$task" ]; then
    case "$CAPABILITY_GAPS" in *" $task "*) echo "fallback:capability-gap:$task"; return 0;; esac
  fi
  echo "primary"
}

# --- daemon lifecycle -------------------------------------------------------
# agent-browser runs a single persistent daemon that IGNORES launch options
# (--profile/--state/--session-name) if already up. `reset` tears it down so the
# next call binds fresh. Surgical: matches ONLY processes whose argv[0] ends in
# the daemon binary — never this shell (whose cmdline contains the pattern).
daemon_pids() {
  pgrep -af agent-browser-linux 2>/dev/null | awk '$2 ~ /agent-browser-linux[^ ]*$/{print $1}'
}
reset_daemon() {
  # `close --all` HANGS if no daemon is running — only call it when one exists,
  # and cap it with a timeout as belt-and-suspenders.
  if [ -n "$(daemon_pids)" ]; then
    timeout 8 "$(ab_bin)" close --all >/dev/null 2>&1 || true
  fi
  daemon_pids | xargs -r kill 2>/dev/null || true
  sleep 1
}

# --- caps -------------------------------------------------------------------
caps() {
  local json="no"; [ "${1:-}" = "--json" ] && json="yes"
  local bin_present="no" chrome_path="" ver="" ver_state="unknown"
  have_binary && bin_present="yes"
  chrome_path="$(resolve_chrome 2>/dev/null || true)"
  if [ "$bin_present" = "yes" ]; then
    ver="$(detected_version || true)"
    if [ -z "$ver" ]; then ver_state="unknown"
    elif [ "$ver" = "$PINNED_VERSION" ]; then ver_state="pinned"
    else ver_state="drift"; fi
  fi
  if [ "$json" = "yes" ]; then
    jq -cn --arg bin "$bin_present" --arg chrome "${chrome_path:-}" --arg ver "${ver:-}" \
          --arg pinned "$PINNED_VERSION" --arg vstate "$ver_state" \
          '{binary:$bin,chrome:$chrome,version:$ver,pinned:$pinned,version_state:$vstate}'
  else
    echo "binary:        $bin_present"
    echo "chrome:        ${chrome_path:-<none on PATH; agent-browser may self-provide>}"
    echo "version:       ${ver:-<unknown>} (pinned $PINNED_VERSION; $ver_state)"
  fi
}

# --- run (policy-gated, audited passthrough) --------------------------------
run() {
  local confirm_flag=""
  if [ "${1:-}" = "--confirm" ]; then confirm_flag="--confirm"; shift; fi
  if [ "${1:-}" = "--" ]; then shift; fi
  [ "$#" -ge 1 ] || { echo "usage: agent-browser.sh run [--confirm] -- <agent-browser args...>" >&2; return 3; }

  local r; r="$(route)"
  if [ "$r" != "primary" ]; then
    echo "ROUTE=$r — agent-browser unavailable; use the MCP fallback (see browser-primitive.md § Routing)." >&2
    return 4
  fi

  # Find the real action + target by scanning past leading global flags
  # (--profile <v>, --session-name <v>, --engine <v>, etc. precede the subcommand).
  local action="" target="" seen_action="no" prev=""
  for tok in "$@"; do
    if [ "$seen_action" = "no" ]; then
      case " $READONLY_ACTIONS $INTERACTIVE_ACTIONS " in
        *" $tok "*) action="$tok"; seen_action="yes"; continue ;;
      esac
      # also catch sensitive-classified actions (from the policy list)
      if printf '%s' "$(policy_sensitive)" | jq -e --arg a "$tok" 'index($a) != null' >/dev/null 2>&1; then
        action="$tok"; seen_action="yes"; continue
      fi
    elif [ -z "$target" ]; then
      case "$tok" in -*) : ;; *) target="$tok" ;; esac
    fi
  done
  [ -n "$action" ] || action="$1"   # fallback: first token
  local dec reason
  IFS=$'\t' read -r dec reason < <(policy_eval "$action" "$target" ${confirm_flag:+--confirm})
  audit_line "run" "$action" "$target" "$(classify_action "$action")" "$dec" "$reason"
  if [ "$dec" = "deny" ] || [ "$dec" = "confirm" ]; then
    echo "POLICY=$dec ($reason) for '$action ${target}'. Pass --confirm or allowlist the host (see .agent0/browser-policy.json.example)." >&2
    return 2
  fi

  # Default the browser executable to the system Chrome if not already set.
  local chrome; chrome="$(resolve_chrome 2>/dev/null || true)"
  [ -n "$chrome" ] && [ -z "${AGENT_BROWSER_EXECUTABLE_PATH:-}" ] && export AGENT_BROWSER_EXECUTABLE_PATH="$chrome"
  "$(ab_bin)" "$@"
}

# --- verify-contract (the bounded visual-contract dogfood verifier) ---------
verify_contract() {
  local url="${1:-}" fixture="${2:-}" outdir="${3:-}"
  [ -n "$url" ] && [ -f "$fixture" ] && [ -n "$outdir" ] || {
    echo "usage: agent-browser.sh verify-contract <url> <fixture.json> <outdir>" >&2; return 3; }
  mkdir -p "$outdir"

  local r; r="$(route)"
  [ "$r" = "primary" ] || { echo "ROUTE=$r — cannot verify on the MCP fallback path here." >&2; return 4; }

  local chrome; chrome="$(resolve_chrome 2>/dev/null || true)"
  [ -n "$chrome" ] && export AGENT_BROWSER_EXECUTABLE_PATH="$chrome"
  local bin; bin="$(ab_bin)"

  audit_line "verify-contract" "open" "$url" "read-only" "allow" "contract-verify"
  "$bin" open "$url" >/dev/null 2>&1
  "$bin" snapshot --json > "$outdir/a11y.json" 2>/dev/null
  "$bin" screenshot "$outdir/screen.png" >/dev/null 2>&1
  "$bin" console --json > "$outdir/console.json" 2>/dev/null || echo '{"data":{"messages":[]}}' > "$outdir/console.json"
  "$bin" vitals --json > "$outdir/vitals.json" 2>/dev/null || echo '{}' > "$outdir/vitals.json"
  "$bin" close --all >/dev/null 2>&1 || true

  # --- assert against the fixture-spec ---
  local checks="[]" overall="pass"
  add_check() { # add_check <name> <ok-bool> <detail>
    checks="$(jq -c --arg n "$1" --argjson ok "$2" --arg d "$3" '. + [{name:$n,ok:$ok,detail:$d}]' <<<"$checks")"
    [ "$2" = "true" ] || overall="fail"
  }

  # required roles/names present in the a11y refs
  local nreq; nreq="$(jq '.required | length' "$fixture" 2>/dev/null || echo 0)"
  local i=0
  while [ "$i" -lt "${nreq:-0}" ]; do
    local role name found
    role="$(jq -r ".required[$i].role" "$fixture")"
    name="$(jq -r ".required[$i].name" "$fixture")"
    found="$(jq --arg role "$role" --arg name "$name" \
      '[.data.refs[] | select(.role==$role and .name==$name)] | length > 0' "$outdir/a11y.json" 2>/dev/null || echo false)"
    if [ "$found" = "true" ]; then add_check "required:$role:$name" true "present"
    else add_check "required:$role:$name" false "MISSING from a11y tree"; fi
    i=$((i+1))
  done

  # console errors within budget
  local maxerr nerr
  maxerr="$(jq '.max_console_errors // 0' "$fixture" 2>/dev/null || echo 0)"
  nerr="$(jq '[.data.messages[]? | select((.type//.level//"") == "error")] | length' "$outdir/console.json" 2>/dev/null || echo 0)"
  if [ "${nerr:-0}" -le "${maxerr:-0}" ]; then add_check "console-errors" true "$nerr ≤ $maxerr"
  else add_check "console-errors" false "$nerr > $maxerr"; fi

  # screenshot produced
  if [ -s "$outdir/screen.png" ]; then add_check "screenshot" true "captured"
  else add_check "screenshot" false "not produced"; fi

  jq -cn --arg overall "$overall" --argjson checks "$checks" --arg url "$url" \
        '{url:$url,overall:$overall,checks:$checks}' > "$outdir/report.json"
  echo "VERIFY-CONTRACT: $(echo "$overall" | tr a-z A-Z)  ($url)"
  jq -r '.checks[] | "  " + (if .ok then "✓" else "✗" end) + " " + .name + " — " + .detail' "$outdir/report.json"
  [ "$overall" = "pass" ]
}

# --- adopt: attach to a human-logged-in Chrome over CDP, save state (152.2) --
# Pairs with browser-login.sh: the human launched a dedicated CDP Chrome and is
# logging in; `adopt` polls the CDP /json endpoint (HTTP, NON-disruptive — never
# navigates the human's tab) until a page on the host leaves the login flow,
# then saves the session state (credential-class). Never handles credentials.
adopt_session() {
  local host="${1:-}"; shift || true
  local port=9222 timeout=300 statefile="" domain="" expect="" detect_only="no"
  while [ "$#" -gt 0 ]; do case "$1" in
    --port)    port="$2"; shift 2 ;;
    --timeout) timeout="$2"; shift 2 ;;
    --state)   statefile="$2"; shift 2 ;;
    --domain)  domain="$2"; shift 2 ;;
    --expect)  expect="$2"; shift 2 ;;
    --detect-only) detect_only="yes"; shift ;;
    *) shift ;;
  esac; done
  [ -n "$host" ] || { echo "usage: agent-browser.sh adopt <host> [--port N] [--domain d] [--timeout S] [--state f] [--expect re]" >&2; return 3; }
  case "$host" in
    github)    domain="${domain:-github.com}" ;;
    x|twitter) domain="${domain:-x.com}" ;;
    linkedin)  domain="${domain:-linkedin.com}" ;;
    *)         domain="${domain:-$host}" ;;
  esac
  [ -n "$statefile" ] || statefile="$AUDIT_DIR/state/$host.json"

  curl -s -m3 "http://localhost:$port/json/version" >/dev/null 2>&1 || {
    echo "adopt: no Chrome on CDP :$port — run  bash .agent0/tools/browser-login.sh $host  first." >&2; return 4; }

  local login_re='/(login|signin|sign_in|session|sessions|oauth|sso|challenge|checkpoint|authwall|i/flow|uas/login)'
  local deadline url=""; deadline=$(( $(date +%s) + timeout ))
  echo "adopt: watching CDP :$port for $host login (domain $domain, ≤${timeout}s; non-disruptive)…"
  while [ "$(date +%s)" -lt "$deadline" ]; do
    url="$(curl -s -m3 "http://localhost:$port/json" 2>/dev/null \
      | jq -r --arg d "$domain" '[.[] | select(.type=="page") | .url] | map(select(. != null and (test($d)))) | .[0] // ""' 2>/dev/null)"
    if [ -n "$url" ] && ! printf '%s' "$url" | grep -qiE "$login_re"; then
      if [ -z "$expect" ] || printf '%s' "$url" | grep -qE "$expect"; then break; fi
    fi
    url=""; sleep 3
  done
  [ -n "$url" ] || { echo "adopt: timed out — no authed $domain page seen on CDP :$port (still on the login flow?)." >&2; return 1; }

  if [ "$detect_only" = "yes" ]; then
    echo "DETECTED $host authed at $url"
    return 0
  fi

  mkdir -p "$(dirname "$statefile")"
  local chrome; chrome="$(resolve_chrome 2>/dev/null || true)"; [ -n "$chrome" ] && export AGENT_BROWSER_EXECUTABLE_PATH="$chrome"
  "$(ab_bin)" --cdp "$port" state save "$statefile" >/dev/null 2>&1
  audit_line "adopt" "state-save" "$host" "sensitive" "allow" "cdp-adopt"
  local cookies; cookies="$(jq '.cookies | length' "$statefile" 2>/dev/null || echo 0)"
  echo "ADOPTED $host → $statefile (authed at $url; $cookies cookies). Reuse headless: agent-browser --state $statefile open https://$domain/"
  [ "${cookies:-0}" -ge 1 ]
}

# --- structural parsing of the a11y text tree (spec 152.1) ------------------
# CORRECT structural metrics from `.data.snapshot`. The naive trap (real, hit
# during the site-audit dogfood): `grep -c 'level=1'` ALSO matches
# `listitem [level=1]` (nesting depth), wildly overcounting h1s. Headings must
# be parsed on heading lines only, with the level token terminated by `,` or `]`.
# parse_structure <snapshot-text> → echoes "h1=<n> h2=<n> main=<0|1> nav=<0|1>"
parse_structure() {
  local tree="$1" h1 h2 main nav
  h1="$(printf '%s' "$tree" | grep -cE 'heading .*\[level=1[],]' || true)"
  h2="$(printf '%s' "$tree" | grep -cE 'heading .*\[level=2[],]' || true)"
  main="$(printf '%s' "$tree" | grep -cE '^[[:space:]]*- main([[:space:]"]|$)' || true)"; main=$([ "${main:-0}" -gt 0 ] && echo 1 || echo 0)
  nav="$(printf '%s' "$tree" | grep -cE '^[[:space:]]*- navigation([[:space:]"]|$)' || true)"; nav=$([ "${nav:-0}" -gt 0 ] && echo 1 || echo 0)
  echo "h1=${h1:-0} h2=${h2:-0} main=${main} nav=${nav}"
}

# --- audit: multi-page structural + console + vitals sweep (spec 152.1) ------
# audit <base-url> (--paths a,b,c | --paths-file f) [--out dir] [--max-console N]
# Owns the daemon lifecycle + report aggregation so callers don't hand-roll it
# (and don't re-make the grep bug above). Structural gate: exactly one h1 + a
# main landmark + console errors ≤ max. nav/vitals are advisory.
audit_pages() {
  local base="" paths="" out="$PROJECT_DIR/.agent0/.runtime-state/agent-browser/audit" maxc=0
  base="${1:-}"; shift || true
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --paths) paths="$2"; shift 2 ;;
      --paths-file) paths="$(tr '\n' ',' < "$2")"; shift 2 ;;
      --out) out="$2"; shift 2 ;;
      --max-console) maxc="$2"; shift 2 ;;
      *) shift ;;
    esac
  done
  [ -n "$base" ] || { echo "usage: agent-browser.sh audit <base-url> (--paths a,b,c | --paths-file f) [--out dir] [--max-console N]" >&2; return 3; }
  [ -n "$paths" ] || paths="/"
  local r; r="$(route)"; [ "$r" = "primary" ] || { echo "ROUTE=$r — cannot audit on the MCP fallback path here." >&2; return 4; }

  mkdir -p "$out/shots"
  local chrome; chrome="$(resolve_chrome 2>/dev/null || true)"; [ -n "$chrome" ] && export AGENT_BROWSER_EXECUTABLE_PATH="$chrome"
  local bin; bin="$(ab_bin)"
  reset_daemon

  local results="[]" total=0 flagged=0
  local IFS=','
  for p in $paths; do
    [ -n "$p" ] || continue
    local url label
    url="${base%/}/${p#/}"
    label="$(printf '%s' "$p" | sed -E 's#^/+##; s#/+$##; s#[/]+#-#g')"; [ -n "$label" ] || label="root"
    audit_line "audit" "open" "$url" "read-only" "allow" "audit-sweep"
    "$bin" open "$url" >/dev/null 2>&1; sleep 1
    local snap console vitals tree
    snap="$(timeout 15 "$bin" snapshot --json 2>/dev/null)"
    console="$(timeout 15 "$bin" console --json 2>/dev/null)"
    vitals="$(timeout 20 "$bin" vitals --json 2>/dev/null)"
    "$bin" screenshot "$out/shots/$label.png" >/dev/null 2>&1
    tree="$(printf '%s' "$snap" | jq -r '.data.snapshot // ""' 2>/dev/null)"
    eval "$(parse_structure "$tree")"   # sets h1 h2 main nav
    local cerr lcp cls flags=""
    cerr="$(printf '%s' "$console" | jq '[.data.messages[]? | select(.type=="error")] | length' 2>/dev/null || echo 0)"
    lcp="$(printf '%s' "$vitals" | jq -r '(.data.lcp.startTime // 0) | floor' 2>/dev/null || echo 0)"
    cls="$(printf '%s' "$vitals" | jq -r '.data.cls.score // 0' 2>/dev/null || echo 0)"
    [ "${h1:-0}" != "1" ] && flags="${flags}h1=${h1} "
    [ "${main:-0}" = "0" ] && flags="${flags}no-main "
    [ "${nav:-0}" = "0" ] && flags="${flags}no-nav "
    [ "${cerr:-0}" -gt "${maxc:-0}" ] 2>/dev/null && flags="${flags}console=${cerr} "
    local ok=true; { [ "${h1:-0}" = "1" ] && [ "${main:-0}" = "1" ] && [ "${cerr:-0}" -le "${maxc:-0}" ]; } || { ok=false; flagged=$((flagged+1)); }
    total=$((total+1))
    results="$(jq -c --arg l "$label" --arg u "$url" --argjson h1 "${h1:-0}" --argjson main "${main:-0}" \
      --argjson nav "${nav:-0}" --argjson cerr "${cerr:-0}" --argjson lcp "${lcp:-0}" --arg cls "${cls:-0}" \
      --argjson ok "$ok" --arg flags "${flags:-—}" \
      '. + [{label:$l,url:$u,h1:$h1,main:$main,nav:$nav,console_errors:$cerr,lcp_ms:$lcp,cls:($cls|tonumber? // 0),ok:$ok,flags:$flags}]' <<<"$results")"
    echo "  $([ "$ok" = true ] && echo ✓ || echo ✗) $label (h1=${h1} main=${main} nav=${nav} console=${cerr} lcp=${lcp}ms) ${flags}"
  done
  reset_daemon

  jq -cn --argjson results "$results" --argjson total "$total" --argjson flagged "$flagged" \
    '{total:$total,flagged:$flagged,pages:$results}' > "$out/report.json"
  {
    echo "| page | h1 | main | nav | console-err | LCP ms | CLS | flags |"
    echo "|---|---|---|---|---|---|---|---|"
    jq -r '.pages[] | "| \(.label) | \(.h1) | \(if .main==1 then "Y" else "N" end) | \(if .nav==1 then "Y" else "N" end) | \(.console_errors) | \(.lcp_ms) | \(.cls) | \(.flags) |"' "$out/report.json"
  } > "$out/report.md"
  echo "AUDIT: $total pages, $flagged flagged → $out/report.md (vitals are advisory; meaningful only vs a deployed/throttled target)"
  [ "$flagged" -eq 0 ]
}

# --- dispatch ---------------------------------------------------------------
case "${1:-help}" in
  caps)            shift; caps "$@" ;;
  route)           shift; route "$@" ;;
  policy-eval)     shift
                   [ "$#" -ge 1 ] || { echo "usage: policy-eval <action> <target> [--confirm]" >&2; exit 3; }
                   out="$(policy_eval "$@")"; rc=$?; printf '%s\n' "$out" | tr '\t' ' '; exit $rc ;;
  run)             shift; run "$@" ;;
  reset)           reset_daemon; echo "daemon reset" ;;
  verify-contract) shift; verify_contract "$@" ;;
  audit)           shift; audit_pages "$@" ;;
  adopt)           shift; adopt_session "$@" ;;
  parse-structure) shift; parse_structure "${1:-}" ;;
  audit-tail)      shift; n="${1:-20}"; f="$AUDIT_DIR/audit-$(date -u +%Y-%m-%d).jsonl"
                   [ -f "$f" ] && tail -n "$n" "$f" || echo "(no audit entries today)" ;;
  help|--help|-h)  sed -n '2,28p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//' ;;
  *)               echo "unknown subcommand: $1" >&2
                   echo "try: caps | route | policy-eval | run | verify-contract | audit-tail | help" >&2; exit 3 ;;
esac
