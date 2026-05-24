#!/usr/bin/env bash
# .claude/skills/image/scripts/gen.sh
#
# Pre-flight + post-flight helper for the /image skill.
# The actual MCP tool call is made by Claude Code's tool surface from the
# SKILL.md prose; this script handles everything around the call:
#   - prepare : validate inputs, derive output path, print cost estimate,
#               emit JSON envelope for the agent to pass to the MCP
#   - record  : append a manifest line after MCP success/failure
#
# Two-stage shape is deliberate — the MCP call cannot be made from bash
# (it goes through CC's tool surface), so the script can't be a single
# "do everything" invocation. The SKILL.md body coordinates the agent.
#
# Reference:
#   .claude/rules/image-gen.md                       — capacity rule
#   .claude/skills/image/SKILL.md                    — invocation surface
#   .claude/skills/image/references/tier-pricing.md  — static cost table

set -uo pipefail

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
MANIFEST_PATH="$PROJECT_DIR/assets/generated/.manifest.jsonl"

# ---------------------------------------------------------------------------
# Tier table — keep in sync with .claude/skills/image/references/tier-pricing.md
# ---------------------------------------------------------------------------
# Format per tier: MODEL|DIR|COST_USD|EXT
#   EXT is the file extension matching fal.ai's default content-type per model
#   (verified empirically 2026-05-24 via fal.run REST API):
#     - FLUX schnell    → image/jpeg
#     - gpt-image-2     → image/png  (verify before first brand-text invocation)
#     - imagen4/ultra   → image/png  (verify before first brand-photo invocation)
TIER_TABLE='draft|fal-ai/flux/schnell|assets/generated/mockups|0.003|jpg
brand-text|fal-ai/gpt-image-2|assets/brand|0.040|png
brand-photo|fal-ai/imagen4/ultra|assets/brand|0.060|png'

# ---------------------------------------------------------------------------
# Aspect table — fal.ai image_size enum + resolved dimensions
# ---------------------------------------------------------------------------
# Format per aspect: ASPECT|IMAGE_SIZE_ENUM|DIMENSIONS
# Enum values per fal.ai docs (https://fal.ai/models/fal-ai/flux/schnell).
ASPECT_TABLE='square|square_hd|1024x1024
landscape|landscape_16_9|1024x576
portrait|portrait_16_9|576x1024'

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
die_no_tier() {
  cat >&2 <<'EOF'
/image error: --tier is required. Pick one:
  --tier=draft       cheap mockup       (~$0.003/img, FLUX schnell)
  --tier=brand-text  premium with text  ($0.04-0.20/img, gpt-image-2)
  --tier=brand-photo premium photo-real (~$0.06/img, Imagen 4 Ultra)
EOF
  exit 2
}

die_bad_tier() {
  printf '/image error: invalid --tier=%s. Valid: draft, brand-text, brand-photo.\n' "$1" >&2
  exit 2
}

die_bad_aspect() {
  printf '/image error: invalid --aspect=%s. Valid: square, landscape, portrait.\n' "$1" >&2
  exit 2
}

die_no_fal_key() {
  cat >&2 <<'EOF'
/image error: FAL_KEY environment variable is not set.

Activation steps:
  1. Sign up at https://fal.ai and mint an API key
  2. export FAL_KEY="<uuid>:<secret>" in your shell or .env
  3. cp .mcp.json.example .mcp.json (if not done) and uncomment the fal-ai block
  4. Restart the Claude Code session (MCPs load at session start)

See .claude/rules/image-gen.md § Activation for the full workflow.
EOF
  exit 2
}

die_bad_name() {
  printf '/image error: --name=%s must be kebab-case (^[a-z][a-z0-9-]*$)\n' "$1" >&2
  exit 2
}

# kebab_slug "raw prompt text"
# → drops non-alphanumerics, lowercases, joins first 5 words with hyphens
kebab_slug() {
  printf '%s' "$1" \
    | tr '[:upper:]' '[:lower:]' \
    | tr -c 'a-z0-9' ' ' \
    | awk '{
        n = (NF < 5) ? NF : 5
        out = ""
        for (i = 1; i <= n; i++) {
          if ($i == "") continue
          out = (out == "") ? $i : out "-" $i
        }
        print out
      }'
}

# resolve_tier <tier-key>
# → echoes "MODEL|DIR|COST|EXT" on hit (return 0), nothing on miss (return 1).
# Caller is responsible for translating return 1 → die. Cannot `exit` from here:
# resolvers are called via $() (command substitution) which spawns a subshell;
# `exit` inside the subshell only kills the subshell, leaving the parent to
# continue with empty stdout. Tested empirically 2026-05-24.
resolve_tier() {
  local key="$1" line
  while IFS= read -r line; do
    case "$line" in
      "$key"\|*) printf '%s\n' "${line#"$key"|}"; return 0 ;;
    esac
  done <<<"$TIER_TABLE"
  return 1
}

# resolve_aspect <aspect-key>
# → echoes "IMAGE_SIZE_ENUM|DIMS" on hit (return 0), nothing on miss (return 1).
# Same subshell-exit caveat as resolve_tier above.
resolve_aspect() {
  local key="$1" line
  while IFS= read -r line; do
    case "$line" in
      "$key"\|*) printf '%s\n' "${line#"$key"|}"; return 0 ;;
    esac
  done <<<"$ASPECT_TABLE"
  return 1
}

# collision_suffix <path>
# → echoes a free path (appending -2, -3, ... if needed). Extension-agnostic:
# splits on the LAST dot so .jpg / .png / .webp all work identically.
collision_suffix() {
  local base="$1" dir name ext candidate n
  dir="$(dirname "$base")"
  ext=".${base##*.}"
  name="$(basename "$base" "$ext")"
  candidate="$base"
  n=2
  while [ -e "$candidate" ]; do
    candidate="$dir/$name-$n$ext"
    n=$((n + 1))
  done
  printf '%s\n' "$candidate"
}

# json_escape <str> → echoes the input with quotes / backslashes / control chars escaped
json_escape() {
  printf '%s' "$1" | python3 -c 'import json,sys; sys.stdout.write(json.dumps(sys.stdin.read())[1:-1])'
}

# ---------------------------------------------------------------------------
# Subcommand: prepare
# ---------------------------------------------------------------------------
sub_prepare() {
  local tier="" name="" prompt="" aspect="square"
  while [ $# -gt 0 ]; do
    case "$1" in
      --tier=*)   tier="${1#--tier=}"; shift ;;
      --name=*)   name="${1#--name=}"; shift ;;
      --aspect=*) aspect="${1#--aspect=}"; shift ;;
      --tier)     tier="${2:-}"; shift 2 ;;
      --name)     name="${2:-}"; shift 2 ;;
      --aspect)   aspect="${2:-square}"; shift 2 ;;
      --) shift; break ;;
      -*) printf '/image error: unknown flag: %s\n' "$1" >&2; exit 2 ;;
      *) prompt="$1"; shift ;;
    esac
  done
  # remaining args concatenated as prompt (in case prompt was unquoted)
  if [ $# -gt 0 ]; then
    prompt="$prompt $*"
  fi
  prompt="${prompt# }"

  [ -z "$tier" ] && die_no_tier
  [ -z "${FAL_KEY:-}" ] && die_no_fal_key
  [ -z "$prompt" ] && { printf '/image error: prompt is required.\n' >&2; exit 2; }

  if [ -n "$name" ]; then
    case "$name" in
      [a-z]*) : ;;
      *) die_bad_name "$name" ;;
    esac
    case "$name" in
      *[!a-z0-9-]*) die_bad_name "$name" ;;
    esac
  fi

  local tier_row model dir cost ext
  tier_row="$(resolve_tier "$tier")" || die_bad_tier "$tier"
  model="${tier_row%%|*}"; tier_row="${tier_row#*|}"
  dir="${tier_row%%|*}";   tier_row="${tier_row#*|}"
  cost="${tier_row%%|*}";  tier_row="${tier_row#*|}"
  ext="$tier_row"

  local aspect_row image_size dims
  aspect_row="$(resolve_aspect "$aspect")" || die_bad_aspect "$aspect"
  image_size="${aspect_row%%|*}"; aspect_row="${aspect_row#*|}"
  dims="$aspect_row"

  local slug base_path output_path
  slug="${name:-$(kebab_slug "$prompt")}"
  [ -z "$slug" ] && slug="image"

  # draft tier prefixes with date; brand tiers don't (durable, history-tracked)
  if [ "$tier" = "draft" ]; then
    base_path="$PROJECT_DIR/$dir/$(date -u +%Y-%m-%d)-$slug.$ext"
  else
    base_path="$PROJECT_DIR/$dir/$slug.$ext"
  fi
  mkdir -p "$(dirname "$base_path")"
  output_path="$(collision_suffix "$base_path")"

  # Cost estimate to stdout BEFORE the JSON envelope so it reads naturally
  printf 'estimated: $%s for %s at %s (%s)\n' "$cost" "$model" "$dims" "$aspect"

  # JSON envelope for the agent — adds image_size + extension so the agent
  # passes the right param to the MCP and saves with the right extension.
  printf '{"tier":"%s","model":"%s","prompt":"%s","output_path":"%s","approx_cost_usd":%s,"dimensions":"%s","aspect":"%s","image_size":"%s","extension":"%s"}\n' \
    "$tier" \
    "$model" \
    "$(json_escape "$prompt")" \
    "${output_path#"$PROJECT_DIR/"}" \
    "$cost" \
    "$dims" \
    "$aspect" \
    "$image_size" \
    "$ext"
}

# ---------------------------------------------------------------------------
# Subcommand: record
# ---------------------------------------------------------------------------
sub_record() {
  local tier="" model="" cost="" prompt="" output="" dims="" status="success"
  while [ $# -gt 0 ]; do
    case "$1" in
      --tier=*)   tier="${1#--tier=}"; shift ;;
      --model=*)  model="${1#--model=}"; shift ;;
      --cost=*)   cost="${1#--cost=}"; shift ;;
      --prompt=*) prompt="${1#--prompt=}"; shift ;;
      --output=*) output="${1#--output=}"; shift ;;
      --dims=*)   dims="${1#--dims=}"; shift ;;
      --status=*) status="${1#--status=}"; shift ;;
      --tier|--model|--cost|--prompt|--output|--dims|--status)
        eval "${1#--}=\"${2:-}\""; shift 2 ;;
      *) printf '/image record: unknown arg: %s\n' "$1" >&2; exit 2 ;;
    esac
  done

  for f in tier model prompt output; do
    eval "v=\$$f"
    if [ -z "${v:-}" ]; then
      printf '/image record: missing --%s\n' "$f" >&2
      exit 2
    fi
  done

  mkdir -p "$(dirname "$MANIFEST_PATH")"
  local ts session
  ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  session="${CLAUDE_SESSION_ID:-null}"

  # session_id needs to be quoted if non-null, bare null if absent
  local session_field
  if [ "$session" = "null" ]; then
    session_field='null'
  else
    session_field="\"$(json_escape "$session")\""
  fi

  printf '{"ts":"%s","session_id":%s,"tier":"%s","model":"%s","cost_usd":%s,"prompt":"%s","output_path":"%s","dimensions":"%s","status":"%s"}\n' \
    "$ts" \
    "$session_field" \
    "$tier" \
    "$model" \
    "${cost:-0}" \
    "$(json_escape "$prompt")" \
    "$(json_escape "$output")" \
    "${dims:-1024x1024}" \
    "$status" \
    >> "$MANIFEST_PATH"

  printf 'recorded: %s\n' "$output"
}

# ---------------------------------------------------------------------------
# Dispatch
# ---------------------------------------------------------------------------
case "${1:-}" in
  prepare) shift; sub_prepare "$@" ;;
  record)  shift; sub_record  "$@" ;;
  ""|-h|--help)
    cat <<'EOF'
/image — AI image generation helper (spec 085)

Subcommands:
  prepare --tier=<draft|brand-text|brand-photo> [--name=<slug>] "<prompt>"
    Validate inputs, derive output path, print cost estimate, emit JSON
    envelope (stdout). Errors out with --tier=missing template, FAL_KEY-unset
    pointer, or invalid-name complaint.

  record --tier=X --model=Y --cost=Z --prompt="..." --output=path
         [--dims=1024x1024] [--status=success]
    Append a manifest line to assets/generated/.manifest.jsonl after the MCP
    call returns. Called by the agent post-MCP, with the prepare-envelope
    values forwarded.

See .claude/skills/image/SKILL.md for the full invocation flow and
.claude/rules/image-gen.md for the capacity rule.
EOF
    [ -z "${1:-}" ] && exit 2 || exit 0
    ;;
  *)
    printf '/image error: unknown subcommand: %s\n' "$1" >&2
    printf 'Run with --help for usage.\n' >&2
    exit 2
    ;;
esac
