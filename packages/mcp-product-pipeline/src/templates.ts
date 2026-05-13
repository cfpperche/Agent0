/**
 * Template loader — reads templates/<NN-name>/{prompt.md, schema.md} and
 * parses the prompt's YAML-lite frontmatter.
 *
 * Frontmatter contract (locked, validated loudly at parse time):
 *   ---
 *   mode: interactive | draft-after-input | synthesis
 *   delegable: true | partial | false
 *   delegation_hint: "<short TASK string for the 5-field handoff>"
 *   ---
 *
 * Parser is in-house ~50 LOC instead of pulling gray-matter (200+ KB
 * transitive). YAML-lite means: `---` fences on their own lines, `key: value`
 * per line, string values without explicit quoting required, no nesting,
 * no arrays. If we ever need richer frontmatter, revisit. See
 * docs/specs/025-mcp-product-pipeline/plan.md § Alternatives.
 */

import { readFile } from "node:fs/promises";
import {
  type DelegableLevel,
  type ExecutionMode,
} from "./pipeline.js";
import { templateFile } from "./paths.js";

export interface TemplateFrontmatter {
  mode: ExecutionMode;
  delegable: DelegableLevel;
  delegation_hint: string;
}

export interface Template {
  frontmatter: TemplateFrontmatter;
  /** Body of prompt.md AFTER the closing `---` fence. */
  body: string;
  /** Full contents of schema.md (no parsing). */
  schema: string;
}

const VALID_MODES: readonly ExecutionMode[] = [
  "interactive",
  "draft-after-input",
  "synthesis",
];

const VALID_DELEGABLE: readonly DelegableLevel[] = ["true", "partial", "false"];

const REQUIRED_KEYS: readonly (keyof TemplateFrontmatter)[] = [
  "mode",
  "delegable",
  "delegation_hint",
];

/**
 * Parse YAML-lite frontmatter from a markdown string. Throws if:
 * - File does not start with `---` fence
 * - Closing `---` fence is missing
 * - A line in the frontmatter is not `key: value` shape
 * - Required key is missing
 * - Unknown key is present
 * - `mode` is not one of VALID_MODES
 * - `delegable` is not one of VALID_DELEGABLE
 */
export function parseFrontmatter(source: string): { frontmatter: TemplateFrontmatter; body: string } {
  const lines = source.split(/\r?\n/);
  if (lines[0] !== "---") {
    throw new Error(
      `template parse: expected opening '---' fence on line 1, got "${lines[0] ?? "<empty>"}"`,
    );
  }
  let closingLine = -1;
  for (let i = 1; i < lines.length; i++) {
    if (lines[i] === "---") {
      closingLine = i;
      break;
    }
  }
  if (closingLine === -1) {
    throw new Error("template parse: missing closing '---' fence after frontmatter");
  }

  const raw: Record<string, string> = {};
  for (let i = 1; i < closingLine; i++) {
    const line = lines[i]!;
    // Allow blank lines inside frontmatter (tolerant).
    if (line.trim() === "") continue;
    const colon = line.indexOf(":");
    if (colon === -1) {
      throw new Error(
        `template parse: frontmatter line ${i + 1} is not 'key: value' shape: "${line}"`,
      );
    }
    const key = line.slice(0, colon).trim();
    let value = line.slice(colon + 1).trim();
    // Strip matched outer quotes (single or double) — YAML-lite cosmetic.
    if (
      (value.startsWith('"') && value.endsWith('"')) ||
      (value.startsWith("'") && value.endsWith("'"))
    ) {
      value = value.slice(1, -1);
    }
    raw[key] = value;
  }

  // Required-key presence
  for (const key of REQUIRED_KEYS) {
    if (!(key in raw)) {
      throw new Error(`template parse: missing required frontmatter key "${key}"`);
    }
  }
  // Unknown-key rejection
  for (const key of Object.keys(raw)) {
    if (!REQUIRED_KEYS.includes(key as keyof TemplateFrontmatter)) {
      throw new Error(
        `template parse: unknown frontmatter key "${key}" — allowed: ${REQUIRED_KEYS.join(", ")}`,
      );
    }
  }
  // Value validation
  const mode = raw.mode as ExecutionMode;
  if (!VALID_MODES.includes(mode)) {
    throw new Error(
      `template parse: invalid mode "${raw.mode}" — must be one of: ${VALID_MODES.join(", ")}`,
    );
  }
  const delegable = raw.delegable as DelegableLevel;
  if (!VALID_DELEGABLE.includes(delegable)) {
    throw new Error(
      `template parse: invalid delegable "${raw.delegable}" — must be one of: ${VALID_DELEGABLE.join(", ")}`,
    );
  }
  const delegation_hint = raw.delegation_hint!;

  const body = lines.slice(closingLine + 1).join("\n");
  return {
    frontmatter: { mode, delegable, delegation_hint },
    body,
  };
}

/**
 * Read templates/<NN-name>/prompt.md AND schema.md, parse the prompt's
 * frontmatter, return the structured template. Throws on parse error,
 * missing file, etc — designed to fail loudly at first call so authoring
 * mistakes don't propagate.
 */
export async function getTemplate(n: number): Promise<Template> {
  const promptPath = templateFile(n, "prompt.md");
  const schemaPath = templateFile(n, "schema.md");
  const [promptRaw, schemaRaw] = await Promise.all([
    readFile(promptPath, "utf8"),
    readFile(schemaPath, "utf8"),
  ]);
  const { frontmatter, body } = parseFrontmatter(promptRaw);
  return { frontmatter, body, schema: schemaRaw };
}
