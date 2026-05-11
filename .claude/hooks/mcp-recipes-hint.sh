#!/usr/bin/env bash
# .claude/hooks/mcp-recipes-hint.sh
# SessionStart hook — detect fork's stack and emit MCP recipe suggestions.
#
# Pure recommendation: never blocks, never audits, exit 0 always. Honors
# CLAUDE_SKIP_MCP_RECIPES=1 to suppress regardless of stack signals. Silent
# when no signals match (Agent0 base case).
#
# Signal table (see .claude/rules/mcp-recipes.md for full reference):
#   Next.js   next.config.{js,ts,mjs,cjs} OR package.json next dep
#             -> next-devtools-mcp + playwright-mcp
#   Browser   react / vue / svelte / vite / astro in package.json (no next)
#             -> playwright-mcp + chrome-devtools-mcp
#   DB        schema.prisma / drizzle.config.{js,ts,mjs} / alembic.ini /
#             database/migrations/ / db/migrate/ / DATABASE_URL in .env.example
#             -> dbhub
#
# Reference:
#   .claude/rules/mcp-recipes.md          — full recipes + workflow
#   docs/specs/012-mcp-recipes/           — spec

set -uo pipefail

# ---------------------------------------------------------------------------
# Phase 1: User-facing escape hatch
# ---------------------------------------------------------------------------
if [ "${CLAUDE_SKIP_MCP_RECIPES:-0}" = "1" ]; then
  exit 0
fi

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$PWD}"

# ---------------------------------------------------------------------------
# Phase 2: Stack signal detection
# ---------------------------------------------------------------------------
signals=""             # human-readable signal labels (for hint header)
have_next=0
have_browser=0         # react/vue/svelte/vite/astro
have_db=0

# --- Next.js signal: config files ---
for f in next.config.js next.config.ts next.config.mjs next.config.cjs; do
  if [ -f "$PROJECT_DIR/$f" ]; then
    have_next=1
    signals="$signals $f"
    break
  fi
done

# --- package.json dep checks (jq-free for portability) ---
pkg="$PROJECT_DIR/package.json"
if [ -f "$pkg" ]; then
  # Check next, react, vue, svelte, vite, astro in dependencies + devDependencies.
  # Use grep on the raw file with a forgiving regex; jq is optional.
  if command -v jq >/dev/null 2>&1; then
    next_dep="$(jq -r '(.dependencies // {} | keys[]?), (.devDependencies // {} | keys[]?)' "$pkg" 2>/dev/null | grep -Fx 'next' | head -1)"
    if [ -n "$next_dep" ]; then
      have_next=1
      signals="$signals package.json:next"
    fi
    if [ "$have_next" -eq 0 ]; then
      for dep in react vue svelte vite astro; do
        match="$(jq -r '(.dependencies // {} | keys[]?), (.devDependencies // {} | keys[]?)' "$pkg" 2>/dev/null | grep -Fx "$dep" | head -1)"
        if [ -n "$match" ]; then
          have_browser=1
          signals="$signals package.json:$dep"
          break
        fi
      done
    fi
  else
    # jq absent — fall back to permissive regex on the raw JSON.
    if grep -qE '"next"[[:space:]]*:' "$pkg"; then
      have_next=1
      signals="$signals package.json:next"
    fi
    if [ "$have_next" -eq 0 ]; then
      for dep in react vue svelte vite astro; do
        if grep -qE "\"$dep\"[[:space:]]*:" "$pkg"; then
          have_browser=1
          signals="$signals package.json:$dep"
          break
        fi
      done
    fi
  fi
fi

# --- DB signal: prisma / drizzle / alembic / migrations dirs / env DATABASE_URL ---
for f in schema.prisma alembic.ini; do
  if [ -f "$PROJECT_DIR/$f" ]; then
    have_db=1
    signals="$signals $f"
    break
  fi
done

if [ "$have_db" -eq 0 ]; then
  for f in drizzle.config.js drizzle.config.ts drizzle.config.mjs; do
    if [ -f "$PROJECT_DIR/$f" ]; then
      have_db=1
      signals="$signals $f"
      break
    fi
  done
fi

if [ "$have_db" -eq 0 ]; then
  for d in database/migrations db/migrate; do
    if [ -d "$PROJECT_DIR/$d" ]; then
      have_db=1
      signals="$signals $d/"
      break
    fi
  done
fi

if [ "$have_db" -eq 0 ] && [ -f "$PROJECT_DIR/.env.example" ]; then
  if grep -qE '^DATABASE_URL=' "$PROJECT_DIR/.env.example"; then
    have_db=1
    signals="$signals .env.example:DATABASE_URL"
  fi
fi

# ---------------------------------------------------------------------------
# Phase 3: Build the suggested-recipes list (deduplicated union)
# ---------------------------------------------------------------------------
recipes=""

add_recipe() {
  local name="$1"
  # Avoid dup if already in the list.
  case " $recipes " in
    *" $name "*) return ;;
  esac
  if [ -z "$recipes" ]; then
    recipes="$name"
  else
    recipes="$recipes $name"
  fi
}

if [ "$have_next" -eq 1 ]; then
  add_recipe "next-devtools-mcp"
  add_recipe "playwright-mcp"
fi
if [ "$have_browser" -eq 1 ]; then
  add_recipe "playwright-mcp"
  add_recipe "chrome-devtools-mcp"
fi
if [ "$have_db" -eq 1 ]; then
  add_recipe "dbhub"
fi

# No recipes -> silent.
[ -z "$recipes" ] && exit 0

# ---------------------------------------------------------------------------
# Phase 4: Emit the hint block
# ---------------------------------------------------------------------------
signals_trim="${signals# }"

printf '\n=== mcp-recipes ===\n'
printf 'Stack signals detected: %s\n' "$signals_trim"
printf 'Suggested MCP recipes (copy + uncomment from .mcp.json.example):\n'
for r in $recipes; do
  case "$r" in
    next-devtools-mcp)
      printf '  - next-devtools-mcp  Next.js framework introspection (build errors, routes, server actions)\n' ;;
    playwright-mcp)
      printf '  - playwright-mcp     browser observation (DOM, console, network, screenshots)\n' ;;
    chrome-devtools-mcp)
      printf '  - chrome-devtools-mcp  Chrome DevTools (network, console, Lighthouse, V8 heap)\n' ;;
    dbhub)
      printf '  - dbhub              multi-engine DB schema + safe query exec\n' ;;
  esac
done
printf 'See .claude/rules/mcp-recipes.md for full recipes (install commands, runtime requirements, security).\n'
printf '=== end mcp-recipes ===\n'

exit 0
