#!/usr/bin/env bash
# Scenario: uncommented Codex hook template parses as TOML.

set -euo pipefail

AGENT0_ROOT="${AGENT0_ROOT:-$(cd "$(dirname "$0")/../../.." && pwd)}"
TEMPLATE="$AGENT0_ROOT/.codex/config.toml.example"
TMPDIR="$(mktemp -d -t multi-readouts-toml-XXXXXX)"
trap 'rm -rf "$TMPDIR"' EXIT

CONFIG="$TMPDIR/config.toml"
awk '
  /^# \[features\]$/,/^# statusMessage = "Projecting project-memory index"$/ {
    if ($0 ~ /^# (\[features\]|\[\[hooks\.|hooks =|matcher =|type =|command =|statusMessage =)/) {
      sub(/^# /, "")
      print
    }
  }
' "$TEMPLATE" > "$CONFIG"

python3 - "$CONFIG" <<'PY'
import sys

try:
    import tomllib
except ModuleNotFoundError:
    raise SystemExit("FAIL: python3 tomllib unavailable")

path = sys.argv[1]
with open(path, "rb") as f:
    data = tomllib.load(f)

session_start = data.get("hooks", {}).get("SessionStart", [])
if len(session_start) != 3:
    raise SystemExit(f"FAIL: expected 3 SessionStart entries, got {len(session_start)}")

commands = [
    hook.get("command", "")
    for block in session_start
    for hook in block.get("hooks", [])
]
required = [
    ".agent0/hooks/memory-decay-readout.sh",
    ".agent0/hooks/reminders-readout.sh",
    ".agent0/hooks/routines-readout.sh",
]
missing = [needle for needle in required if not any(needle in command for command in commands)]
if missing:
    raise SystemExit("FAIL: missing SessionStart commands: " + ", ".join(missing))

print("PASS: 05-toml-parse")
PY
