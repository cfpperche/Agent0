// Spec 127 currency check — the anti-restaling guard.
// Fails the build when the site's capability manifest drifts from the repo:
//   - a capacity's primary sourcePath no longer exists on disk
//   - a primary sourcePath points at an early spec (specs are history-only)
//   - a capacity declares an unknown theme
//   - a theme with capacities lacks an explanatory page (per resolved locale)
//   - the "how it works" overview is missing (per resolved locale)
//
// Run: `bun run scripts/check-currency.ts` (wired into `bun run check` + prebuild).
import { existsSync } from "node:fs";
import { resolve } from "node:path";
import { CAPACITIES, THEMES } from "../src/i18n/capacities.ts";

const siteRoot = resolve(import.meta.dir, "..");
const repoRoot = resolve(siteRoot, "..");

// Spec 127: en-first shipped first; pt/es parity landed as the tracked follow-up
// (reminder r-2026-05-30-spec-127-follow-up-translate). Full 3-locale parity now.
const RESOLVED_LOCALES = ["en", "pt", "es"];

const errors: string[] = [];
const themeIds = new Set(THEMES.map((t) => t.id));

for (const c of CAPACITIES) {
  if (!existsSync(resolve(repoRoot, c.sourcePath))) {
    errors.push(`capacity "${c.id}": sourcePath 404 on disk → ${c.sourcePath}`);
  }
  if (c.sourcePath.startsWith("docs/specs/")) {
    errors.push(
      `capacity "${c.id}": primary sourcePath points at a spec (${c.sourcePath}); specs are history-only, use the current rule/skill`,
    );
  }
  if (!themeIds.has(c.theme)) {
    errors.push(`capacity "${c.id}": unknown theme "${c.theme}"`);
  }
}

for (const t of THEMES) {
  const hasCaps = CAPACITIES.some((c) => c.theme === t.id);
  if (!hasCaps) {
    errors.push(`theme "${t.id}": declared but no capacity uses it`);
    continue;
  }
  for (const loc of RESOLVED_LOCALES) {
    const page = resolve(siteRoot, `src/pages/${loc}/${t.id}.astro`);
    if (!existsSync(page)) {
      errors.push(`theme "${t.id}": missing explanatory page for locale "${loc}" → src/pages/${loc}/${t.id}.astro`);
    }
  }
}

for (const loc of RESOLVED_LOCALES) {
  const overview = resolve(siteRoot, `src/pages/${loc}/how-it-works.astro`);
  if (!existsSync(overview)) {
    errors.push(`missing "how it works" overview for locale "${loc}" → src/pages/${loc}/how-it-works.astro`);
  }
}

if (errors.length > 0) {
  console.error(`\ncurrency check FAILED (${errors.length}):`);
  for (const e of errors) console.error(`  ✗ ${e}`);
  console.error("");
  process.exit(1);
}

console.log(
  `currency check OK — ${CAPACITIES.length} capacities across ${THEMES.length} themes, locales [${RESOLVED_LOCALES.join(", ")}]`,
);
