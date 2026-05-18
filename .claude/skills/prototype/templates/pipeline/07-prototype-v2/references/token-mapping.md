# Step 7 — Token mapping (how step 6 tokens.css lands in HTML)

The contract for step 7's render: every color / type / spacing / radius / shadow value in `direction-final.html` and `screens/*.html` resolves to a `var(--token)` defined in `docs/product/06-design-system/tokens.css`. This page documents the mechanics of the substitution — how step 2's primitive tokens become step 6's semantic ones, how to handle naming mismatches, and where the canonical aliases live.

## The substitution contract

Step 2 declared its `:root` per direction (e.g. `--background`, `--foreground`, `--primary`, `--accent`, `--border`, `--muted` — six tokens, primitive names anchored to the direction's mood). Step 6 emits a richer, **semantic** token set (e.g. `--color-canvas`, `--color-foreground`, `--color-foreground-secondary`, `--color-foreground-tertiary`, `--color-accent`, `--color-border-1`, `--color-border-2`, plus `--font-*`, `--space-*`, `--radius-*`, optionally `--shadow-*`).

Step 7's job is to **carry the screens forward to the semantic vocabulary** without rewriting their structure. Two paths:

### Path A — Direct rename (recommended)

Find every `var(--background)` in the screen's CSS, replace with `var(--color-canvas)`. Same for the other 5 primitives. Apply consistently across all N screens AND `direction-final.html`. This is the cleanest landing — the HTML reads in step 6's vocabulary and a reader can grep for `--color-canvas` across the workspace and find the semantic intent.

When to pick this path: step 6's token names are recognisably semantic versions of step 2's primitives. Mechanical rename, no ambiguity.

### Path B — Alias in `:root`

Keep the screen's `var(--background)` references unchanged. In each screen's `:root` block, alias the primitives to the semantics:

```css
:root {
  /* step 6's canonical semantic tokens */
  --color-canvas: oklch(0.10 0.005 240);
  --color-foreground: oklch(0.96 0.005 240);
  --color-foreground-secondary: oklch(0.72 0.010 240);
  --color-foreground-tertiary: oklch(0.55 0.010 240);
  --color-accent: oklch(0.78 0.18 200);
  --color-border-1: oklch(0.20 0.010 240);
  --color-border-2: oklch(0.30 0.012 240);
  /* … */

  /* step 2 aliases — preserved so the screens' CSS doesn't have to be rewritten */
  --background: var(--color-canvas);
  --foreground: var(--color-foreground);
  --primary: var(--color-accent);
  --accent: var(--color-accent);
  --border: var(--color-border-1);
  --muted: var(--color-foreground-tertiary);
}
```

When to pick this path: step 2's HTML is dense and rewriting CSS selectors carries regression risk; or step 6's semantic names don't map 1:1 to step 2's primitives (e.g. step 2 had one `--border`, step 6 distinguishes `--color-border-1` / `--color-border-2`). The alias block makes the mapping explicit and locally visible.

**Pick the path once, apply consistently.** Mixing Path A on some screens and Path B on others creates an audit nightmare. Document the choice in `REPORT.md § Design System Applied`.

## What "canonical token names" mean per category

Step 6's `tokens.css` is the source of truth. Step 7's screens consume from there. Common categories + typical canonical names:

| Category | Typical semantic names | Notes |
|---|---|---|
| Color — canvas | `--color-canvas`, `--color-surface`, `--color-surface-2` | Background scale; brand-tuned by step 5 |
| Color — foreground | `--color-foreground`, `--color-foreground-secondary`, `--color-foreground-tertiary` | Text colors; tertiary is the body-meta level |
| Color — accent | `--color-accent`, `--color-accent-2` (optional) | Primary brand accent; max 1-2 |
| Color — semantic | `--color-success`, `--color-warning`, `--color-danger`, `--color-info` | State communication; brand-tuned hue family |
| Color — border | `--color-border-1`, `--color-border-2` | Border scale; primary load-bearing + secondary subtle |
| Type — family | `--font-display`, `--font-body`, `--font-mono` | Each is a font-stack with fallbacks |
| Type — scale | `--text-xs`, `--text-sm`, `--text-base`, `--text-lg`, `--text-xl`, `--text-2xl`, `--text-3xl`, `--text-4xl` | Paired with line-height + weight |
| Spacing | `--space-1` through `--space-8` (or `--space-tight-*` / `--space-spacious-*` when split) | Derived from density base |
| Radius | `--radius-none`, `--radius-sm`, `--radius-md`, optionally `--radius-full` | Brutalist directions often `--radius-none` only |
| Shadow | `--shadow-sm`, `--shadow-md`, `--shadow-lg` | Optional — direction may explicitly omit |

If step 6's `tokens.css` uses different names (e.g. `--background-primary` instead of `--color-canvas`), inherit step 6's names verbatim — DO NOT rename step 6's tokens to match this table. The table is illustrative; step 6's file is canonical.

## When a screen needs a token step 6 didn't define

This is the **token gap** signal. The screen wants a `--shadow-modal` (hard-edge dialog shadow); step 6's `tokens.css` defines `--shadow-sm` / `--shadow-md` / `--shadow-lg`, all of which feel too soft for the cool-brutalist direction's hairline aesthetic.

**Do not invent the token inline.** Two valid responses:

1. **Use the closest existing token + flag the gap in REPORT.md § Token Gaps** with a one-line recommendation for step 6 next iteration (`Recommend step 6 add --shadow-modal for hard-edge dialog elevation, or document that the direction is hairline-only and dialogs use 2px border-1 instead.`).
2. **Skip the shadow entirely and replace with a `--color-border-1` 2px outline** — i.e., make the design choice that aligns with the direction's posture (hairline brutalism doesn't have shadows). Document the choice in `## Deviations from Brand or System`.

Inventing `--shadow-modal: 0 0 0 2px black;` inline in a screen is the failure mode — the token escapes step 6's canonical definition and lives only in one screen; the next iteration of step 6 won't see it, and the screen drifts out of the system.

## When step 5's brand-book pulls a token in a direction step 2 didn't anticipate

The brand-book might call for a warmer canvas than step 2's direction chose (step 2 picked a Cool Brutalist with `oklch(0.10 0.005 240)`; step 5's brand voice reads "warm humanist" and step 6 ended up at `oklch(0.12 0.008 60)` — slightly warmer hue, same lightness). Step 7 inherits step 6's value verbatim — the screens get the warmer canvas, even though step 2's direction file still has the original cool value.

This is expected. The user's Layer 3 signoff at step 2 was on the *direction* (mood, hierarchy, system composition), not on the exact hex values. Step 5/6 refine those values; step 7 lands them. Document the shift in REPORT.md § Run Summary so the user sees the cascade explicitly.

## Self-contained file discipline

Every screen + `direction-final.html` MUST be self-contained — opening it directly via `file://` shows the full design without network access. This means:

- **No `<link rel="stylesheet" href="tokens.css">`** — inline the `:root` block verbatim in the screen's `<style>` tag.
- **No `@import url(...)` of remote fonts** — system-stack fallbacks only (`font-family: 'IBM Plex Mono', ui-monospace, 'SF Mono', Menlo, monospace;`). The brand-book may name a specific font; the screen's `--font-body` token can reference it, but the actual loading is a system-stack assumption.
- **No external CSS frameworks** (Tailwind, Bootstrap, etc.) — step 7's HTML is hi-fi mockup, not production code. Step 13 (prototype-v3, NEW) handles stack-native rendering when the spec demands it.

The schema's Layer 1 `per_match_contains: [":root", "var(--"]` enforces inline + token-consuming patterns. A screen that imports tokens via `<link>` and uses `var(--*)` in CSS rules WOULD pass the substring check (the substrings appear in the linked file when inlined), but a reviewer opening `file://` would see the screen unstyled — discipline failure surfaced at review, not at submit.

## Cross-step traceability

A reader of `screens/05-triage-view.html` should be able to trace any visual choice through:

1. The `:root` block → step 6's `tokens.css` (the value layer)
2. A `<!-- fix(F-NN): ... -->` HTML comment → step 4's findings frontmatter (the audit-driven changes)
3. A user-facing string → step 5's brand-book voice samples (the brand layer)
4. The component structure (e.g., `<article class="issue-card">`) → step 6's `components.md` § Anatomy (the system layer)
5. The screen filename → step 2's Turn-2 emit (the structural origin)

Five-step traceability is the audit trail step 7 produces. When any link in the chain breaks (a `var(--unknown-token)`, a string with no brand-book echo, a component shape that doesn't match `components.md`), that's a defect to surface in REPORT.md § Deviations or § Token Gaps.
