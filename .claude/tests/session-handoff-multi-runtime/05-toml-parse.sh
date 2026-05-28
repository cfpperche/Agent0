#!/usr/bin/env bash
# Scenario 5: uncommented Codex hook blocks from the template parse as TOML.

set -euo pipefail

AGENT0_ROOT="${AGENT0_ROOT:-$(cd "$(dirname "$0")/../../.." && pwd)}"
CONFIG="$AGENT0_ROOT/.codex/config.toml.example"

python3 - "$CONFIG" <<'PY'
import pathlib
import sys
import tempfile
import tomllib

config_path = pathlib.Path(sys.argv[1])
lines = config_path.read_text(encoding="utf-8").splitlines()

comment_blocks = []
i = 0
while i < len(lines):
    line = lines[i]
    if line.startswith("# [[hooks."):
        block = []
        while i < len(lines) and lines[i].startswith("#"):
            block.append(lines[i][2:] if lines[i].startswith("# ") else lines[i][1:])
            i += 1
        comment_blocks.append(block)
        continue
    i += 1

required = {
    "session-start.sh": None,
    "session-stop.sh": None,
    "session-track-edits.sh": None,
}
for block in comment_blocks:
    joined = "\n".join(block)
    for marker in required:
        if marker in joined:
            required[marker] = block

missing = [marker for marker, block in required.items() if block is None]
if missing:
    raise SystemExit(f"missing commented hook block(s): {', '.join(missing)}")

toml_text = "[features]\nhooks = true\n\n" + "\n\n".join(
    "\n".join(required[marker])
    for marker in ("session-start.sh", "session-stop.sh", "session-track-edits.sh")
)

with tempfile.NamedTemporaryFile("w", encoding="utf-8", delete=False) as fh:
    fh.write(toml_text)
    temp_name = fh.name

data = tomllib.loads(pathlib.Path(temp_name).read_text(encoding="utf-8"))
hooks = data.get("hooks", {})

session_start = hooks.get("SessionStart", [])
if not session_start or session_start[0].get("matcher") != "startup|resume|clear|compact":
    raise SystemExit("SessionStart matcher missing or wrong")

stop = hooks.get("Stop", [])
if not stop or "matcher" in stop[0]:
    raise SystemExit("Stop block must exist without matcher")

post_tool = hooks.get("PostToolUse", [])
if not post_tool or post_tool[0].get("matcher") != "^apply_patch$":
    raise SystemExit("PostToolUse apply_patch matcher missing or wrong")
PY

printf 'PASS\n'
exit 0
