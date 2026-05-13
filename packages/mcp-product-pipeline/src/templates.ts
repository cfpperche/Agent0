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

import { readFile, readdir } from "node:fs/promises";
import { basename, extname, join } from "node:path";
import {
  type DelegableLevel,
  type ExecutionMode,
} from "./pipeline.js";
import { templateFile, templateReferencesDir } from "./paths.js";

export interface TemplateFrontmatter {
  mode: ExecutionMode;
  delegable: DelegableLevel;
  delegation_hint: string;
}

/** One exact-path artifact requirement. */
export interface RequiredFileExact {
  path: string;
  min_size?: number;
  contains?: string[];
}

/** One glob-shaped artifact requirement (for product-dependent screen counts, etc.). */
export interface RequiredFileGlob {
  pattern: string;
  min_count?: number;
  per_match_min_size?: number;
  per_match_contains?: string[];
}

/**
 * Schema-declared artifact requirements parsed from a `required_files` fenced
 * JSON block in schema.md. Either / both fields may appear; null is returned
 * when no fenced block exists (single-file step — Layer 1 skipped, backwards
 * compat with spec 025 templates).
 */
export interface RequiredFilesSpec {
  required_files?: RequiredFileExact[];
  required_glob?: RequiredFileGlob[];
}

export interface Template {
  frontmatter: TemplateFrontmatter;
  /** Body of prompt.md AFTER the closing `---` fence. */
  body: string;
  /** Full contents of schema.md (no parsing). */
  schema: string;
  /**
   * Per-step references: basename-without-extension → file content. Loaded
   * from `templates/<NN-name>/references/*.md` if the dir exists. Empty map
   * when the dir is absent (most single-artifact steps). Surfaced inline in
   * `product_step_get` response so the agent never needs to know the package
   * filesystem path. See spec 026 Q1 resolution.
   */
  references: Record<string, string>;
  /**
   * Schema-declared `required_files` / `required_glob` parsed from a
   * ```required_files fenced block in schema.md. Null when absent. Drives
   * Layer 1 validation in product_step_submit. See spec 026 Q2 + Q4.
   */
  required_files: RequiredFilesSpec | null;
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
 * Extract a fenced JSON block tagged `required_files` from schema.md. Shape:
 *
 *   ```required_files
 *   {
 *     "required_files": [ {"path": "x.html", "min_size": 8192, "contains": ["<html"]} ],
 *     "required_glob":  [ {"pattern": "screens/[0-9]+-*.html", "min_count": 8, ...} ]
 *   }
 *   ```
 *
 * Returns null when no fenced block is present (backwards-compat: single-
 * artifact steps without explicit Layer 1 specs). Throws when the block
 * exists but is malformed (loud failure at template authoring time).
 *
 * JSON is chosen over YAML for parser zero-risk + zero deps. The fence tag
 * `required_files` (rather than `json`) acts as a discriminator so the
 * template author can include other unrelated JSON examples in the schema
 * body without false-positives.
 */
export function parseRequiredFiles(schemaBody: string): RequiredFilesSpec | null {
  const fenceOpen = /^```required_files\s*$/m;
  const fenceClose = /^```\s*$/m;
  const openMatch = fenceOpen.exec(schemaBody);
  if (!openMatch) return null;
  const afterOpen = schemaBody.slice(openMatch.index + openMatch[0].length);
  const closeMatch = fenceClose.exec(afterOpen);
  if (!closeMatch) {
    throw new Error(
      "schema parse: 'required_files' fence opened but no closing '```' fence found",
    );
  }
  const block = afterOpen.slice(0, closeMatch.index).trim();
  let parsed: unknown;
  try {
    parsed = JSON.parse(block);
  } catch (parseErr) {
    throw new Error(
      `schema parse: required_files fenced block is not valid JSON — ${(parseErr as Error).message}`,
    );
  }
  if (parsed === null || typeof parsed !== "object" || Array.isArray(parsed)) {
    throw new Error("schema parse: required_files must be a JSON object");
  }
  const obj = parsed as Record<string, unknown>;
  const result: RequiredFilesSpec = {};

  if ("required_files" in obj) {
    if (!Array.isArray(obj.required_files)) {
      throw new Error("schema parse: required_files must be an array");
    }
    result.required_files = obj.required_files.map((entry, i) => {
      if (typeof entry !== "object" || entry === null || Array.isArray(entry)) {
        throw new Error(
          `schema parse: required_files[${i}] must be an object`,
        );
      }
      const e = entry as Record<string, unknown>;
      if (typeof e.path !== "string" || e.path.length === 0) {
        throw new Error(
          `schema parse: required_files[${i}].path must be a non-empty string`,
        );
      }
      const out: RequiredFileExact = { path: e.path };
      if (e.min_size !== undefined) {
        if (typeof e.min_size !== "number" || e.min_size < 0) {
          throw new Error(
            `schema parse: required_files[${i}].min_size must be a non-negative number`,
          );
        }
        out.min_size = e.min_size;
      }
      if (e.contains !== undefined) {
        if (
          !Array.isArray(e.contains) ||
          !e.contains.every((s) => typeof s === "string")
        ) {
          throw new Error(
            `schema parse: required_files[${i}].contains must be an array of strings`,
          );
        }
        out.contains = e.contains as string[];
      }
      return out;
    });
  }

  if ("required_glob" in obj) {
    if (!Array.isArray(obj.required_glob)) {
      throw new Error("schema parse: required_glob must be an array");
    }
    result.required_glob = obj.required_glob.map((entry, i) => {
      if (typeof entry !== "object" || entry === null || Array.isArray(entry)) {
        throw new Error(
          `schema parse: required_glob[${i}] must be an object`,
        );
      }
      const e = entry as Record<string, unknown>;
      if (typeof e.pattern !== "string" || e.pattern.length === 0) {
        throw new Error(
          `schema parse: required_glob[${i}].pattern must be a non-empty string`,
        );
      }
      const out: RequiredFileGlob = { pattern: e.pattern };
      if (e.min_count !== undefined) {
        if (typeof e.min_count !== "number" || e.min_count < 0) {
          throw new Error(
            `schema parse: required_glob[${i}].min_count must be a non-negative number`,
          );
        }
        out.min_count = e.min_count;
      }
      if (e.per_match_min_size !== undefined) {
        if (typeof e.per_match_min_size !== "number" || e.per_match_min_size < 0) {
          throw new Error(
            `schema parse: required_glob[${i}].per_match_min_size must be a non-negative number`,
          );
        }
        out.per_match_min_size = e.per_match_min_size;
      }
      if (e.per_match_contains !== undefined) {
        if (
          !Array.isArray(e.per_match_contains) ||
          !e.per_match_contains.every((s) => typeof s === "string")
        ) {
          throw new Error(
            `schema parse: required_glob[${i}].per_match_contains must be an array of strings`,
          );
        }
        out.per_match_contains = e.per_match_contains as string[];
      }
      return out;
    });
  }

  return result;
}

/**
 * Load `templates/<NN-name>/references/*.md` into a basename-keyed map.
 * Returns empty `{}` when the references dir does not exist — references
 * are optional per step. Non-`.md` files in the dir are ignored.
 */
export async function loadReferences(n: number): Promise<Record<string, string>> {
  const dir = templateReferencesDir(n);
  let entries: string[];
  try {
    entries = await readdir(dir);
  } catch (err) {
    // ENOENT is expected for steps without a references subdir.
    if ((err as NodeJS.ErrnoException).code === "ENOENT") return {};
    throw err;
  }
  const out: Record<string, string> = {};
  await Promise.all(
    entries
      .filter((name) => extname(name) === ".md")
      .map(async (name) => {
        const content = await readFile(join(dir, name), "utf8");
        const key = basename(name, ".md");
        out[key] = content;
      }),
  );
  return out;
}

/**
 * Read templates/<NN-name>/prompt.md AND schema.md, parse the prompt's
 * frontmatter, load any references/*.md siblings, parse schema.md's
 * required_files fenced block (if any). Throws on parse error or missing
 * file — designed to fail loudly at first call so authoring mistakes don't
 * propagate.
 */
export async function getTemplate(n: number): Promise<Template> {
  const promptPath = templateFile(n, "prompt.md");
  const schemaPath = templateFile(n, "schema.md");
  const [promptRaw, schemaRaw, references] = await Promise.all([
    readFile(promptPath, "utf8"),
    readFile(schemaPath, "utf8"),
    loadReferences(n),
  ]);
  const { frontmatter, body } = parseFrontmatter(promptRaw);
  const required_files = parseRequiredFiles(schemaRaw);
  return { frontmatter, body, schema: schemaRaw, references, required_files };
}
