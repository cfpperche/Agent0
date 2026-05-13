/**
 * Path resolvers — separates "where the user's project lives" (CWD) from
 * "where the package's templates live" (import.meta.url-relative).
 *
 * The MCP is launched by Claude Code with cwd = fork project root. Artifacts
 * for the user's product go under that cwd. But TEMPLATES are package
 * internals shipped inside packages/mcp-product-pipeline/src/templates/, and
 * must be resolved relative to this file's own location regardless of where
 * the MCP was launched from. See docs/specs/025-mcp-product-pipeline/plan.md
 * § Risks "Path resolution under MCP stdio invocation".
 */

import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { stepByN } from "./pipeline.js";

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
const PACKAGE_SRC = __dirname;
const PACKAGE_ROOT = resolve(__dirname, "..");

/** The user's project root (where Claude Code launched the MCP). */
export function projectRoot(): string {
  return process.cwd();
}

/** docs/product/ — where the user's pipeline artifacts live. */
export function productRoot(): string {
  return join(projectRoot(), "docs", "product");
}

/** docs/product/.state.json — pipeline state index. */
export function stateFile(): string {
  return join(productRoot(), ".state.json");
}

/** docs/product/<NN-name>/ — directory for a given step's artifacts. */
export function stepDir(n: number): string {
  return join(productRoot(), stepByN(n).dir);
}

/** docs/product/<NN-name>/<filename> — specific artifact path. */
export function stepArtifact(n: number, filename: string): string {
  return join(stepDir(n), filename);
}

/** packages/mcp-product-pipeline/src/templates/<NN-name>/ — package internal. */
export function templateDir(n: number): string {
  return join(PACKAGE_SRC, "templates", stepByN(n).dir);
}

/** packages/mcp-product-pipeline/src/templates/<NN-name>/<filename>. */
export function templateFile(n: number, filename: string): string {
  return join(templateDir(n), filename);
}

/** packages/mcp-product-pipeline/src/templates/<NN-name>/references/ — optional. */
export function templateReferencesDir(n: number): string {
  return join(templateDir(n), "references");
}

/** packages/mcp-product-pipeline/ — package root (one level above src). */
export function packageRoot(): string {
  return PACKAGE_ROOT;
}
