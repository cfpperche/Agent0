/**
 * Open Design vendor access — path resolution + DS index loading.
 *
 * The vendored OD bundle ships INSIDE this package (spec 027):
 *   <pkg-root>/vendor/open-design/   — skills, prompts, frames, templates, MANIFEST
 *   <pkg-root>/design-systems/       — 72 DESIGN.md trees (sibling drawer)
 *   <pkg-root>/vendor/open-design/.cache/ds-index.json — generated DS digest
 *
 * `<pkg-root>` resolves from `import.meta.url` via paths.ts `packageRoot()`,
 * which is `resolve(srcDir, "..")` — identical in the dev layout
 * (`packages/mcp-product-pipeline/`) and the installed layout
 * (`node_modules/agent0-mcp-product-pipeline/`). The MCP tools return ABSOLUTE
 * paths so the agent's Read tool works regardless of the consumer's cwd.
 *
 * Fail-loud posture (spec 027 open question 6): a missing/partial vendor tree is
 * a broken install, not a runtime condition. `assertVendorPresent` throws
 * `VendorMissingError` with an actionable message rather than degrading silently.
 *
 * Deliberate opt-out (spec 027 follow-up): `PRODUCT_PIPELINE_OD=off` in the MCP
 * server's env makes `assertVendorPresent` throw `OdDisabledError` (code
 * `od-disabled`) — a subclass of `VendorMissingError`, so the existing
 * tools.ts catch + the step-2 templates' "Manual escape" routing handle it with
 * no extra wiring. This is the easy on/off switch for A/B'ing OD-grounded vs the
 * pre-OD inline 5-school method.
 */

import { existsSync, readFileSync } from "node:fs";
import { join } from "node:path";
import { packageRoot } from "./paths.js";

/** Resolved OD vendor paths for a given package root. Parameterised on `pkgRoot`
 * so tests can drive resolution against a fixture tree (dev vs installed layout
 * is just a different `pkgRoot` — the internal structure is identical). */
export function odPaths(pkgRoot: string = packageRoot()) {
  const vendorRoot = join(pkgRoot, "vendor", "open-design");
  return {
    pkgRoot,
    vendorRoot,
    designSystemsRoot: join(pkgRoot, "design-systems"),
    skillsRoot: join(vendorRoot, "skills"),
    promptsRoot: join(vendorRoot, "prompts"),
    framesRoot: join(vendorRoot, "frames"),
    templatesRoot: join(vendorRoot, "templates"),
    manifestPath: join(vendorRoot, "MANIFEST.json"),
    dsIndexPath: join(vendorRoot, ".cache", "ds-index.json"),
  };
}

/**
 * Absolute roots for the vendored subtrees the agent reads directly (skills,
 * prompts, frames, templates, design-systems). `product_design_systems_index`
 * returns this so the agent can build paths into the installed package without
 * knowing where npm placed it — the MCP resolves, the agent's Read tool reads.
 */
export function vendorAnchors(pkgRoot?: string): Record<string, string> {
  const p = odPaths(pkgRoot);
  return {
    design_systems: p.designSystemsRoot,
    skills: p.skillsRoot,
    prompts: p.promptsRoot,
    frames: p.framesRoot,
    templates: p.templatesRoot,
  };
}

/** Thrown when the vendored OD tree is missing or partial — a broken install. */
export class VendorMissingError extends Error {
  // Widened to `string` so OdDisabledError can override with a distinct code.
  readonly code: string = "od-vendor-missing";
  readonly missing: string[];
  constructor(missing: string[]) {
    super(
      `OD vendor tree missing or partial — expected paths absent: ${missing.join(", ")}. ` +
        `Reinstall agent0-mcp-product-pipeline (the vendor bundle ships inside the npm package). ` +
        `Manual escape: the step-2 references/pipeline.md retains an inline visual-school description ` +
        `under its "Manual escape" heading.`,
    );
    this.name = "VendorMissingError";
    this.missing = missing;
  }
}

/**
 * Thrown when OD grounding is deliberately switched off via `PRODUCT_PIPELINE_OD`.
 * Subclasses `VendorMissingError` so the tools.ts catch and the step-2 templates'
 * "Manual escape" routing pick it up unchanged — only the `code` differs, so the
 * agent (and the audit) can tell "deliberately off" apart from "broken install".
 */
export class OdDisabledError extends VendorMissingError {
  override readonly code = "od-disabled";
  constructor() {
    super([]);
    this.name = "OdDisabledError";
    this.message =
      `OD grounding is disabled (PRODUCT_PIPELINE_OD is set off). The step-2 templates ` +
      `route through references/pipeline.md § "Manual escape — OD vendor unavailable" — ` +
      `the pre-OD inline 5-school method. Unset PRODUCT_PIPELINE_OD (or set it "on") and ` +
      `restart the MCP server to re-enable vendored DESIGN.md grounding.`;
  }
}

/**
 * Is OD grounding deliberately switched off? Reads `PRODUCT_PIPELINE_OD` from the
 * env; truthy-off values are `off` / `0` / `false` / `no` / `disabled`
 * (case-insensitive). Unset, or any other value, means OD is on (the default).
 */
export function odDisabled(): boolean {
  const v = (process.env.PRODUCT_PIPELINE_OD ?? "").trim().toLowerCase();
  return v === "off" || v === "0" || v === "false" || v === "no" || v === "disabled";
}

/**
 * Throw if OD grounding is unavailable — either deliberately off
 * (`OdDisabledError`) or because the vendor anchors are absent
 * (`VendorMissingError`, a broken install). Both subclasses share a shape so
 * callers catch one type.
 */
export function assertVendorPresent(pkgRoot?: string): void {
  if (odDisabled()) throw new OdDisabledError();
  const p = odPaths(pkgRoot);
  const anchors: [string, string][] = [
    ["MANIFEST.json", p.manifestPath],
    ["ds-index.json", p.dsIndexPath],
    ["design-systems/", p.designSystemsRoot],
    ["vendor/open-design/skills/", p.skillsRoot],
  ];
  const missing = anchors.filter(([, abs]) => !existsSync(abs)).map(([label]) => label);
  if (missing.length > 0) throw new VendorMissingError(missing);
}

export interface DsIndexEntry {
  name: string;
  mood: string;
  palette_summary: string[];
}

export interface DsIndex {
  generated_at: string;
  pinned_sha: string | null;
  count: number;
  systems: DsIndexEntry[];
}

let cachedIndex: DsIndex | null = null;
let cachedIndexRoot: string | null = null;

/**
 * Load and parse `ds-index.json`. Cached per package root (so the default
 * production path is read once; tests with a distinct `pkgRoot` bypass the
 * cache). Throws `VendorMissingError` if the vendor tree is absent.
 */
export function loadDsIndex(pkgRoot?: string): DsIndex {
  assertVendorPresent(pkgRoot);
  const p = odPaths(pkgRoot);
  if (cachedIndex && cachedIndexRoot === p.dsIndexPath) return cachedIndex;
  const parsed = JSON.parse(readFileSync(p.dsIndexPath, "utf8")) as DsIndex;
  cachedIndex = parsed;
  cachedIndexRoot = p.dsIndexPath;
  return parsed;
}

/** Reset the ds-index cache — test-only seam. */
export function _resetDsIndexCache(): void {
  cachedIndex = null;
  cachedIndexRoot = null;
}

/**
 * Resolve the absolute path to a design system's `DESIGN.md`. The agent reads
 * the returned path with its own Read tool — the MCP resolves paths, it does
 * not stream file content. Fail-loud on an unknown system name or a missing
 * vendor tree.
 */
export function designSystemPath(name: string, pkgRoot?: string): string {
  assertVendorPresent(pkgRoot);
  if (!/^[a-z0-9][a-z0-9-]*$/.test(name)) {
    throw new Error(
      `invalid design-system name "${name}" — expected kebab-case matching /^[a-z0-9][a-z0-9-]*$/`,
    );
  }
  const p = odPaths(pkgRoot);
  const designMd = join(p.designSystemsRoot, name, "DESIGN.md");
  if (!existsSync(designMd)) {
    throw new Error(
      `unknown design system "${name}" — no DESIGN.md at ${designMd}. ` +
        `Call product_design_systems_index for the list of available systems.`,
    );
  }
  return designMd;
}
