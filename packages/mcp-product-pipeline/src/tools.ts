/**
 * The 8 product_* MCP tool handlers. Each registers on the given McpServer
 * instance. Tool surface is the contract documented in spec.md acceptance
 * criteria; argument shapes use the SDK's Zod-compat inputSchema pattern.
 *
 *   product_status                 — read state (or empty)
 *   product_start                  — initialise pipeline for a slug
 *   product_step_get               — read current step's template + prior artifacts
 *   product_step_submit            — validate + write a step artifact
 *   product_advance                — move forward (gate-check at boundaries)
 *   product_gate_pass              — confirm phase-boundary crossing
 *   product_done                   — terminal completion summary
 *   product_get_delegation_brief   — pasteable 5-field handoff for the Agent tool
 *
 * Error shape (when isError):
 *   {isError: true, content: [{type: "text", text: JSON.stringify({code, ...})}]}
 *
 * See docs/specs/025-mcp-product-pipeline/plan.md § Files for the design.
 */

import { mkdir, readdir, rename, writeFile } from "node:fs/promises";
import { dirname, join } from "node:path";
import { randomUUID } from "node:crypto";
import { z } from "zod";
import type { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import {
  FIRST_STEP,
  LAST_STEP,
  PHASES,
  gateClosingPhase,
  isGateAfter,
  stepByN,
  type Phase,
} from "./pipeline.js";
import {
  productRoot,
  stateFile,
  stepArtifact,
  stepDir,
} from "./paths.js";
import {
  advanceStep,
  initState,
  markCompleted,
  markGatePassed,
  readState,
  setValidationMode,
} from "./state.js";
import {
  getTemplate,
  type RequiredFileExact,
  type RequiredFileGlob,
  type RequiredFilesSpec,
} from "./templates.js";

// ─── helpers ─────────────────────────────────────────────────────

function ok(text: string) {
  return { content: [{ type: "text" as const, text }] };
}

function err(payload: { code: string; [k: string]: unknown }) {
  return {
    isError: true as const,
    content: [{ type: "text" as const, text: JSON.stringify(payload) }],
  };
}

async function listPriorArtifacts(currentStep: number): Promise<string[]> {
  const result: string[] = [];
  for (let n = FIRST_STEP; n < currentStep; n++) {
    const dir = stepDir(n);
    try {
      const entries = await readdir(dir, { recursive: true, withFileTypes: true });
      for (const e of entries) {
        if (e.isFile()) {
          // Filter out hidden / state files; surface everything else (md, html,
          // css, json, etc.) so synthesis-mode steps see the full inventory.
          if (e.name.startsWith(".")) continue;
          // readdir recursive returns paths relative to the root; the parentPath
          // field on Node 20+ gives the containing dir.
          const parent = (e as unknown as { parentPath?: string }).parentPath ?? dir;
          result.push(join(parent, e.name));
        }
      }
    } catch (e: unknown) {
      if ((e as NodeJS.ErrnoException)?.code !== "ENOENT") throw e;
    }
  }
  return result;
}

/**
 * Atomic single-file write via mktemp + rename (POSIX rename atomicity).
 * Same pattern state.ts uses for .state.json; inlined here for tool-side
 * writes so a partial extra_files batch doesn't leave half-written files
 * with the final names. Exported for unit testing.
 */
export async function atomicWriteFile(target: string, content: string): Promise<void> {
  await mkdir(dirname(target), { recursive: true });
  const tmp = `${target}.tmp.${randomUUID()}`;
  await writeFile(tmp, content, "utf8");
  await rename(tmp, target);
}

/**
 * Translate a `required_glob.pattern` into a RegExp anchored to a full path
 * (relative to the step's dir). Supported syntax (intentionally minimal):
 *   *        — any chars except /
 *   **       — any chars including /
 *   [a-z]    — char class (passed through)
 *   [0-9]+   — char class with quantifier (passed through)
 *   ?        — single char except /
 * Anything else is escaped. Patterns are tested via /^pattern$/.
 */
export function globToRegExp(pattern: string): RegExp {
  let out = "";
  let i = 0;
  while (i < pattern.length) {
    const ch = pattern[i]!;
    if (ch === "*") {
      if (pattern[i + 1] === "*") {
        out += ".*";
        i += 2;
      } else {
        out += "[^/]*";
        i++;
      }
    } else if (ch === "?") {
      out += "[^/]";
      i++;
    } else if (ch === "[") {
      // pass character class verbatim until matching ]
      const close = pattern.indexOf("]", i + 1);
      if (close === -1) {
        out += "\\[";
        i++;
      } else {
        out += pattern.slice(i, close + 1);
        i = close + 1;
        // optional quantifier (+, *, ?, {n,m}) — pass through
        if (i < pattern.length && /[+*?{]/.test(pattern[i]!)) {
          if (pattern[i] === "{") {
            const end = pattern.indexOf("}", i);
            if (end === -1) { out += "\\{"; i++; }
            else { out += pattern.slice(i, end + 1); i = end + 1; }
          } else {
            out += pattern[i]!;
            i++;
          }
        }
      }
    } else if (/[.+(){}^$|\\]/.test(ch)) {
      out += "\\" + ch;
      i++;
    } else {
      out += ch;
      i++;
    }
  }
  return new RegExp(`^${out}$`);
}

export interface SubmissionFile {
  /** Path relative to the step's dir. */
  path: string;
  content: string;
}

export interface Layer1Failure {
  path?: string;
  pattern?: string;
  reason: string;
}

/**
 * Run Layer 1 validation: for each entry in `spec.required_files`, match an
 * exact path in `files` and check min_size + contains. For each entry in
 * `spec.required_glob`, count matches via globToRegExp, check min_count, and
 * apply per_match_min_size + per_match_contains to each hit. Returns an
 * empty array on full pass.
 */
export function validateLayer1(
  spec: RequiredFilesSpec,
  files: SubmissionFile[],
): Layer1Failure[] {
  const failures: Layer1Failure[] = [];

  for (const req of spec.required_files ?? []) {
    const match = files.find((f) => f.path === req.path);
    if (!match) {
      failures.push({ path: req.path, reason: "required file is missing from submission" });
      continue;
    }
    if (req.min_size !== undefined && match.content.length < req.min_size) {
      failures.push({
        path: req.path,
        reason: `content length ${match.content.length} below min_size ${req.min_size}`,
      });
    }
    for (const needle of req.contains ?? []) {
      if (!match.content.includes(needle)) {
        failures.push({
          path: req.path,
          reason: `content does not contain required substring "${needle}"`,
        });
      }
    }
  }

  for (const reqGlob of spec.required_glob ?? []) {
    const re = globToRegExp(reqGlob.pattern);
    const matches = files.filter((f) => re.test(f.path));
    if (reqGlob.min_count !== undefined && matches.length < reqGlob.min_count) {
      failures.push({
        pattern: reqGlob.pattern,
        reason: `matched ${matches.length} file(s), below min_count ${reqGlob.min_count}`,
      });
    }
    for (const m of matches) {
      if (reqGlob.per_match_min_size !== undefined && m.content.length < reqGlob.per_match_min_size) {
        failures.push({
          path: m.path,
          reason: `content length ${m.content.length} below per_match_min_size ${reqGlob.per_match_min_size} for pattern "${reqGlob.pattern}"`,
        });
      }
      for (const needle of reqGlob.per_match_contains ?? []) {
        if (!m.content.includes(needle)) {
          failures.push({
            path: m.path,
            reason: `content does not contain required substring "${needle}" for pattern "${reqGlob.pattern}"`,
          });
        }
      }
    }
  }

  return failures;
}

/**
 * Parse a markdown body and extract H2 (## ) section titles.
 * Returns the lowercased, dash-separated slug for each: "## Concept" → "concept",
 * "## Target Audience" → "target-audience".
 */
function extractSectionSlugs(body: string): Set<string> {
  const slugs = new Set<string>();
  for (const line of body.split(/\r?\n/)) {
    const m = /^##\s+(.+?)\s*$/.exec(line);
    if (!m) continue;
    const title = m[1]!.trim().toLowerCase();
    const slug = title.replace(/[^a-z0-9]+/g, "-").replace(/^-|-$/g, "");
    if (slug) slugs.add(slug);
  }
  return slugs;
}

/**
 * Parse a schema.md and pull out the required-section list. Convention:
 * a schema.md contains lines of the form `- <section-slug>` under a
 * `## Required sections` heading (or as bare bullet list). Anything that
 * is `- token` where token is lowercase kebab-case counts.
 */
function extractRequiredSections(schemaMd: string): string[] {
  const out: string[] = [];
  for (const line of schemaMd.split(/\r?\n/)) {
    const m = /^-\s+([a-z][a-z0-9-]*)\s*$/.exec(line);
    if (m) out.push(m[1]!);
  }
  return out;
}

// ─── tool: product_status ────────────────────────────────────────

async function handleStatus() {
  const state = await readState();
  if (!state) {
    return ok(JSON.stringify({ empty: true, hint: "no pipeline yet — call product_start(slug)" }));
  }
  return ok(JSON.stringify(state, null, 2));
}

// ─── tool: product_start ─────────────────────────────────────────

async function handleStart({ slug }: { slug: string }) {
  try {
    const state = await initState(slug);
    await mkdir(stepDir(state.current_step), { recursive: true });
    return ok(
      JSON.stringify({
        started: true,
        slug: state.slug,
        current_step: state.current_step,
        phase: state.phase,
        state_file: stateFile(),
        next_action:
          `call product_step_get to receive the prompt + schema for step ${state.current_step}`,
      }, null, 2),
    );
  } catch (e: unknown) {
    return err({ code: "start-failed", message: (e as Error).message });
  }
}

// ─── tool: product_step_get ──────────────────────────────────────

async function handleStepGet() {
  const state = await readState();
  if (!state) return err({ code: "no-pipeline", hint: "call product_start(slug) first" });
  if (state.current_step > LAST_STEP) {
    return err({ code: "pipeline-complete", hint: `all ${LAST_STEP} steps done — call product_done` });
  }
  const step = stepByN(state.current_step);
  let tmpl;
  try {
    tmpl = await getTemplate(step.n);
  } catch (e: unknown) {
    return err({ code: "template-error", step: step.n, message: (e as Error).message });
  }
  const priorArtifacts = await listPriorArtifacts(state.current_step);
  return ok(
    JSON.stringify(
      {
        step: step.n,
        name: step.name,
        phase: step.phase,
        dir: stepDir(step.n),
        mode: tmpl.frontmatter.mode,
        delegable: tmpl.frontmatter.delegable,
        delegation_hint: tmpl.frontmatter.delegation_hint,
        prompt: tmpl.body,
        schema: tmpl.schema,
        references: tmpl.references,
        required_files: tmpl.required_files,
        prior_artifacts: priorArtifacts,
      },
      null,
      2,
    ),
  );
}

// ─── tool: product_step_submit ───────────────────────────────────

/** A single supplementary file passed alongside the primary `content`. */
interface ExtraFileInput {
  path: string;
  content: string;
}

async function handleStepSubmit({
  filename,
  content,
  extra_files,
}: {
  filename: string;
  content: string;
  extra_files?: ExtraFileInput[];
}) {
  const state = await readState();
  if (!state) return err({ code: "no-pipeline", hint: "call product_start(slug) first" });
  if (state.current_step > LAST_STEP) {
    return err({ code: "pipeline-complete", hint: `all ${LAST_STEP} steps done — call product_done` });
  }
  if (!/^[a-z0-9][a-z0-9._-]*\.(md|html|css|json)$/i.test(filename)) {
    return err({
      code: "bad-filename",
      hint: "primary filename must match /^[a-z0-9][a-z0-9._-]*\\.(md|html|css|json)$/i",
      got: filename,
    });
  }
  const extras: ExtraFileInput[] = extra_files ?? [];
  // Validate extra_files paths shape — relative, no .., no abs, no leading /.
  for (const e of extras) {
    if (typeof e.path !== "string" || e.path.length === 0) {
      return err({ code: "bad-extra-file", hint: "extra_files[].path must be a non-empty string", got: e });
    }
    if (e.path.startsWith("/") || e.path.startsWith("../") || e.path.includes("/../") || e.path === "..") {
      return err({
        code: "bad-extra-file",
        hint: "extra_files[].path must be a relative path under the step's dir; absolute paths and parent-dir escapes are rejected",
        got: e.path,
      });
    }
    if (typeof e.content !== "string") {
      return err({ code: "bad-extra-file", hint: "extra_files[].content must be a string", got: e.path });
    }
  }

  const step = stepByN(state.current_step);
  let tmpl;
  try {
    tmpl = await getTemplate(step.n);
  } catch (e: unknown) {
    return err({ code: "template-error", step: step.n, message: (e as Error).message });
  }

  // Section-level check on the primary markdown content (preserved from v1).
  // Only applies to .md primaries — HTML/CSS/JSON primaries skip this layer
  // (their structure is enforced via required_files Layer 1 instead).
  if (filename.toLowerCase().endsWith(".md")) {
    const required = extractRequiredSections(tmpl.schema);
    const present = extractSectionSlugs(content);
    const missing = required.filter((s) => !present.has(s));
    if (missing.length > 0) {
      return err({
        code: "schema-incomplete",
        step: step.n,
        missing,
        hint: `add level-2 markdown headings (## <Title>) whose slugs match the missing sections`,
      });
    }
  }

  // Layer 1 — required_files / required_glob from schema.md fenced block.
  // Only runs when the template declares specs; backwards-compat with v1
  // templates that have no required_files block.
  if (tmpl.required_files) {
    const submission: SubmissionFile[] = [
      { path: filename, content },
      ...extras.map((e) => ({ path: e.path, content: e.content })),
    ];
    const failures = validateLayer1(tmpl.required_files, submission);
    if (failures.length > 0) {
      return err({
        code: "schema-incomplete",
        step: step.n,
        layer: 1,
        failures,
        hint: "fix each failure (missing path / undersized content / missing required substring) and resubmit; nothing was written",
      });
    }
  }

  // All validation passed — atomically write every file.
  const primaryPath = stepArtifact(step.n, filename);
  const dir = stepDir(step.n);
  await mkdir(dir, { recursive: true });
  const writes: Array<Promise<void>> = [atomicWriteFile(primaryPath, content)];
  for (const e of extras) {
    writes.push(atomicWriteFile(join(dir, e.path), e.content));
  }
  await Promise.all(writes);

  // Step 4 (ux-testing) extracts the validation_mode declaration into state
  // so downstream steps can read it without re-parsing the artifact.
  if (step.n === 4) {
    const modeMatch = /^validation_mode:\s*(tested|intuition|not-applicable)\s*$/im.exec(content);
    if (modeMatch) {
      const mode = modeMatch[1] as "tested" | "intuition" | "not-applicable";
      await setValidationMode(mode);
    }
  }

  return ok(
    JSON.stringify(
      {
        written: primaryPath,
        extras_written: extras.map((e) => join(dir, e.path)),
        step: step.n,
        next_action: "call product_advance",
      },
      null,
      2,
    ),
  );
}

// ─── tool: product_advance ───────────────────────────────────────

async function handleAdvance() {
  const state = await readState();
  if (!state) return err({ code: "no-pipeline", hint: "call product_start(slug) first" });
  const n = state.current_step;
  if (n > LAST_STEP) {
    return err({ code: "pipeline-complete", hint: "call product_done" });
  }

  // require artifact(s) present in current step's dir before advancing
  const artifacts = await readdir(stepDir(n)).catch(() => [] as string[]);
  if (artifacts.filter((f) => f.endsWith(".md")).length === 0) {
    return err({
      code: "no-artifact",
      step: n,
      hint: "call product_step_submit with at least one .md artifact before advancing",
    });
  }

  // gate check at phase boundary
  if (isGateAfter(n)) {
    const closing = gateClosingPhase(n)!;
    if (!state.gates_passed.includes(closing)) {
      return err({
        code: "gate-required",
        phase: closing,
        next_phase: n < LAST_STEP ? stepByN(n + 1).phase : null,
        hint: `confirm with the user that ${closing} phase is ready to close, then call product_gate_pass("${closing}")`,
      });
    }
  }

  await markCompleted(n);

  // step-LAST_STEP completion: pipeline complete. Advance current_step past
  // LAST_STEP so subsequent product_step_get / product_step_submit cleanly
  // report pipeline-complete instead of returning the same step again.
  // Surfaces the screen-atlas (step 13 output) as the primary visual contract
  // handed to engineering — see spec 026 § Intent.
  if (n === LAST_STEP) {
    await advanceStep();
    return ok(
      JSON.stringify(
        {
          code: "pipeline-complete",
          slug: state.slug,
          message:
            `Product planning complete. The comprehensive screen atlas at docs/product/13-prototype-v3/screen-atlas.md is the visual contract for engineering. Execution starts via /sdd new ${state.slug} populating docs/specs/NNN-*/.`,
          next_action: "call product_done for the full handoff summary",
        },
        null,
        2,
      ),
    );
  }

  const next = await advanceStep();
  return ok(
    JSON.stringify(
      {
        advanced_from: n,
        advanced_to: next.current_step,
        phase: next.phase,
        next_action: "call product_step_get for the next step's template",
      },
      null,
      2,
    ),
  );
}

// ─── tool: product_gate_pass ─────────────────────────────────────

async function handleGatePass({ phase }: { phase: Phase }) {
  const state = await readState();
  if (!state) return err({ code: "no-pipeline", hint: "call product_start(slug) first" });
  if (!PHASES.includes(phase)) {
    return err({ code: "bad-phase", got: phase, valid: PHASES as readonly string[] });
  }
  const next = await markGatePassed(phase);
  return ok(
    JSON.stringify({
      gates_passed: next.gates_passed,
      next_action: "call product_advance to cross into the next phase",
    }, null, 2),
  );
}

// ─── tool: product_done ──────────────────────────────────────────

async function handleDone() {
  const state = await readState();
  if (!state) return err({ code: "no-pipeline", hint: "call product_start(slug) first" });
  if (!state.completed.includes(LAST_STEP)) {
    return err({
      code: "not-complete",
      hint: "pipeline still in flight — call product_status to see current step",
      current_step: state.current_step,
    });
  }
  const phaseSummary: Record<Phase, { steps: number[]; dirs: string[] }> = {
    discovery: { steps: [], dirs: [] },
    identity: { steps: [], dirs: [] },
    specification: { steps: [], dirs: [] },
  };
  for (const n of state.completed) {
    const step = stepByN(n);
    phaseSummary[step.phase].steps.push(n);
    phaseSummary[step.phase].dirs.push(stepDir(n));
  }
  const lines: string[] = [];
  lines.push(`Product planning complete for slug "${state.slug}".`);
  lines.push("");
  lines.push("Deliverables (by phase):");
  for (const phase of PHASES) {
    const { dirs } = phaseSummary[phase];
    lines.push(`  - ${phase}: ${dirs.length} dir(s) — ${dirs.join(", ")}`);
  }
  lines.push("");
  lines.push(`Visual contract for engineering: docs/product/13-prototype-v3/${state.slug}/screen-atlas.md`);
  lines.push("  (every screen of the product as HTML — brand+tokens applied, all states covered,");
  lines.push("   user-stories from the PRD cross-referenced; the contract engineering builds against)");
  lines.push("");
  lines.push("Next phase: engineering execution starts via:");
  lines.push(`  /sdd new ${state.slug}`);
  lines.push("");
  lines.push("Once the spec is scaffolded, /sdd plan and /sdd tasks decompose it for implementation. The MCP can be deactivated by commenting the product-pipeline block in .mcp.json (artifacts in docs/product/ remain).");
  return ok(lines.join("\n"));
}

// ─── tool: product_get_delegation_brief ──────────────────────────

async function handleGetDelegationBrief({ step_n }: { step_n: number }) {
  const state = await readState();
  if (!state) return err({ code: "no-pipeline", hint: "call product_start(slug) first" });
  if (step_n < FIRST_STEP || step_n > LAST_STEP) {
    return err({ code: "bad-step", step_n, valid_range: [FIRST_STEP, LAST_STEP] });
  }
  let tmpl;
  try {
    tmpl = await getTemplate(step_n);
  } catch (e: unknown) {
    return err({ code: "template-error", step_n, message: (e as Error).message });
  }
  if (tmpl.frontmatter.delegable === "false") {
    return err({
      code: "not-delegable",
      step_n,
      mode: tmpl.frontmatter.mode,
      hint: `step ${step_n} (${stepByN(step_n).name}) is mode=${tmpl.frontmatter.mode} and not delegable — the parent must conduct it directly`,
    });
  }
  const priorArtifacts = await listPriorArtifacts(step_n);
  const priorLine = priorArtifacts.length === 0
    ? "(none — this is an early-pipeline step)"
    : priorArtifacts.join(", ");
  const step = stepByN(step_n);
  const brief = [
    `TASK: ${tmpl.frontmatter.delegation_hint}`,
    `CONTEXT: call product_step_get to receive the step ${step_n} (${step.name}) template (prompt + schema). Prior artifacts to read for synthesis: ${priorLine}. The product-pipeline MCP exposes the same tool surface in your sub-agent context — you can call product_step_get and product_step_submit directly.`,
    `CONSTRAINTS: do NOT interview the user (sub-agents have no user channel). Do NOT modify docs/product/.state.json by hand — only via the MCP tools. Cite sources for any factual claims you introduce. Stay within the schema required-sections list.`,
    `DELIVERABLE: an artifact file submitted via product_step_submit, landing under docs/product/${step.dir}/.`,
    `DONE_WHEN: product_step_submit returned success (no schema-incomplete error). Report the written path back to the parent so it can decide on product_advance.`,
  ].join("\n");
  return ok(brief);
}

// ─── registration ────────────────────────────────────────────────

export function registerAllTools(server: McpServer): void {
  server.registerTool(
    "product_status",
    {
      description: "Return the pipeline state from docs/product/.state.json, or {empty: true} if no pipeline has been started in this project.",
    },
    handleStatus,
  );

  server.registerTool(
    "product_start",
    {
      description: "Initialise a new pipeline for the given product slug. Creates docs/product/.state.json and the first step's directory.",
      inputSchema: {
        slug: z.string().describe("kebab-case product slug (e.g. \"tiktok-clone\"). Must match /^[a-z][a-z0-9-]*$/"),
      },
    },
    handleStart,
  );

  server.registerTool(
    "product_step_get",
    {
      description: "Return the current step's template (intent + guide questions + required schema sections), per-step references (from templates/<NN>/references/*.md, surfaced inline as a basename-keyed map), parsed required_files spec for Layer 1 validation, plus paths to prior-step artifacts under docs/product/ for context.",
    },
    handleStepGet,
  );

  server.registerTool(
    "product_step_submit",
    {
      description: "Validate then write a step artifact. The primary content must include all sections listed in the step's schema.md required-sections list (for markdown primaries). When the schema declares required_files (fenced JSON block), Layer 1 validation also runs: every required path must be in the submission (primary + extra_files), each must meet min_size + contains[]; glob requirements check min_count + per-match size/contains. On failure, returns schema-incomplete with the failure list and writes NO file. On success, all files persist atomically via mktemp+rename.",
      inputSchema: {
        filename: z.string().describe("Primary artifact filename, e.g. \"REPORT.md\" or \"design-system.md\". Must match /^[a-z0-9][a-z0-9._-]*\\.(md|html|css|json)$/i."),
        content: z.string().describe("Full content of the primary artifact."),
        extra_files: z
          .array(
            z.object({
              path: z.string().describe("Relative path under the step's dir, e.g. \"direction-a.html\" or \"screens/01-landing.html\". No absolute paths, no parent-dir escapes."),
              content: z.string(),
            }),
          )
          .optional()
          .describe("Supplementary files to persist atomically alongside the primary. Used by visual / multi-artifact steps (2, 6, 7, 13). Default empty array."),
      },
    },
    handleStepSubmit,
  );

  server.registerTool(
    "product_advance",
    {
      description: "Mark the current step complete and move forward by 1. Requires at least one artifact file present in the current step's dir. At phase boundaries (after steps 4, 7, 12) returns code=gate-required if product_gate_pass has not been called for the closing phase. After step 13 (final), returns code=pipeline-complete; pipeline does not advance past 13.",
    },
    handleAdvance,
  );

  server.registerTool(
    "product_gate_pass",
    {
      description: "Record explicit user confirmation to cross a phase boundary. Phase values: \"discovery\" | \"identity\" | \"specification\". Idempotent.",
      inputSchema: {
        phase: z.enum(["discovery", "identity", "specification"]).describe("The phase that is CLOSING (not the next phase)."),
      },
    },
    handleGatePass,
  );

  server.registerTool(
    "product_done",
    {
      description: "Terminal completion summary after step 13 (the screen-atlas synthesis). Returns the deliverable map per phase plus the screen-atlas path and the literal `/sdd new <slug>` handoff command. Errors with not-complete if the final step is not yet in state.completed.",
    },
    handleDone,
  );

  server.registerTool(
    "product_get_delegation_brief",
    {
      description: "Return a pasteable 5-field handoff block (TASK / CONTEXT / CONSTRAINTS / DELIVERABLE / DONE_WHEN per .claude/rules/delegation.md) for dispatching the given step to a sub-agent via the Agent tool. Errors with not-delegable if the step's mode is interactive.",
      inputSchema: {
        step_n: z.number().int().min(FIRST_STEP).max(LAST_STEP).describe("The step number whose template's delegation_hint drives the brief."),
      },
    },
    handleGetDelegationBrief,
  );
}
