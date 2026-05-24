#!/usr/bin/env bash
# SessionStart hook: surface stale .claude/memory/ entries inside a framed
# === MEMORY DECAY === block. Per spec 086, fires every session (always-fire
# with `(no stale entries)` empty case keeps the capacity discoverable).
#
# Reads staleness from frontmatter (per 082 schema): last_accessed (or
# created_at as fallback), confirmed_count. Score = age_days - confirms × 14.
# Threshold + boost configurable via .claude/memory.config.json (defaults
# 60 / 14 — see spec 086 OQ-1 resolution).
#
# Always exits 0 — never blocks SessionStart. Degrades silently when
# python3+yaml absent (no frame emitted).

set -uo pipefail

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$PWD}"
HELPER="$PROJECT_DIR/.claude/tools/memory-query-helper.py"

# Soft-skip if helper unavailable — the readout is informational, not load-bearing.
if [[ ! -x "$HELPER" ]] || ! command -v python3 >/dev/null 2>&1 || ! python3 -c "import yaml" 2>/dev/null; then
  exit 0
fi

CLAUDE_PROJECT_DIR="$PROJECT_DIR" python3 "$HELPER" decay --readout 2>/dev/null || true
exit 0
