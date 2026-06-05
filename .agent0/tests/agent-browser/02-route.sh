#!/usr/bin/env bash
# route: primary by default; MCP fallback on exactly three reasons.
source "$(dirname "$0")/_lib.sh"
echo "02-route"

FAKE="$(fake_bin)"

assert_eq "$(AGENT0_BROWSER_BIN="$FAKE" bash "$TOOL" route)" "primary" "binary present ⇒ primary"
assert_eq "$(AGENT0_BROWSER_BIN="$FAKE" AGENT0_BROWSER=mcp bash "$TOOL" route)" "fallback:override" "explicit override ⇒ fallback"
assert_eq "$(AGENT0_BROWSER_BIN="/nonexistent/agent-browser" bash "$TOOL" route)" "fallback:no-binary" "no binary ⇒ fallback"
assert_eq "$(AGENT0_BROWSER_BIN="$FAKE" AGENT0_BROWSER_NO_CHROME=1 bash "$TOOL" route)" "fallback:no-chrome" "no chrome ⇒ fallback"
# reserved capability-gap slot does not misfire for an unknown task
assert_eq "$(AGENT0_BROWSER_BIN="$FAKE" bash "$TOOL" route some-unknown-task)" "primary" "no declared gap ⇒ still primary"

finish
