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

import { mkdir, readdir, writeFile } from "node:fs/promises";
import { join } from "node:path";
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
import { getTemplate } from "./templates.js";

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
      const entries = await readdir(dir);
      for (const e of entries) {
        if (e.endsWith(".md")) result.push(join(dir, e));
      }
    } catch (e: unknown) {
      if ((e as NodeJS.ErrnoException)?.code !== "ENOENT") throw e;
    }
  }
  return result;
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
    return err({ code: "pipeline-complete", hint: "all 12 steps done — call product_done" });
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
        prior_artifacts: priorArtifacts,
      },
      null,
      2,
    ),
  );
}

// ─── tool: product_step_submit ───────────────────────────────────

async function handleStepSubmit({
  filename,
  content,
}: {
  filename: string;
  content: string;
}) {
  const state = await readState();
  if (!state) return err({ code: "no-pipeline", hint: "call product_start(slug) first" });
  if (state.current_step > LAST_STEP) {
    return err({ code: "pipeline-complete", hint: "all 12 steps done — call product_done" });
  }
  if (!/^[a-z0-9][a-z0-9._-]*\.md$/i.test(filename)) {
    return err({
      code: "bad-filename",
      hint: "filename must match /^[a-z0-9][a-z0-9._-]*\\.md$/i",
      got: filename,
    });
  }
  const step = stepByN(state.current_step);
  let tmpl;
  try {
    tmpl = await getTemplate(step.n);
  } catch (e: unknown) {
    return err({ code: "template-error", step: step.n, message: (e as Error).message });
  }
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

  const path = stepArtifact(step.n, filename);
  await mkdir(stepDir(step.n), { recursive: true });
  await writeFile(path, content, "utf8");

  // Step 4 (ux-testing) extracts the validation_mode declaration into state
  // so downstream steps can read it without re-parsing the artifact.
  if (step.n === 4) {
    const modeMatch = /^validation_mode:\s*(tested|intuition|not-applicable)\s*$/im.exec(content);
    if (modeMatch) {
      const mode = modeMatch[1] as "tested" | "intuition" | "not-applicable";
      await setValidationMode(mode);
    }
  }

  return ok(JSON.stringify({ written: path, step: step.n, next_action: "call product_advance" }, null, 2));
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

  // step-12 completion: pipeline complete, don't advance past 12
  if (n === LAST_STEP) {
    return ok(
      JSON.stringify(
        {
          code: "pipeline-complete",
          slug: state.slug,
          message: `Product planning complete. Engineering execution starts via /sdd new <feature-slug> populating docs/specs/NNN-*/.`,
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
  lines.push("Deliverables:");
  for (const phase of PHASES) {
    const { dirs } = phaseSummary[phase];
    lines.push(`  - ${phase}: ${dirs.length} dir(s) — ${dirs.join(", ")}`);
  }
  lines.push("");
  lines.push(`Next phase: engineering execution starts via:`);
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
      description: "Return the current step's template (intent + guide questions + required schema sections) plus paths to prior-step artifacts under docs/product/ for context.",
    },
    handleStepGet,
  );

  server.registerTool(
    "product_step_submit",
    {
      description: "Validate then write a step artifact. The content must include all sections listed in the step's schema.md required-sections list. Returns schema-incomplete error with missing sections if not.",
      inputSchema: {
        filename: z.string().describe("Artifact filename, e.g. \"04-concept-brief.md\". Must end in .md."),
        content: z.string().describe("Full markdown content to write."),
      },
    },
    handleStepSubmit,
  );

  server.registerTool(
    "product_advance",
    {
      description: "Mark the current step complete and move forward by 1. Requires at least one .md artifact present in the current step's dir. At phase boundaries (after steps 4, 7, 12) returns code=gate-required if product_gate_pass has not been called for the closing phase.",
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
      description: "Terminal completion summary after step 12. Returns the deliverable map per phase plus the literal `/sdd new <slug>` handoff command. Errors with not-complete if step 12 is not yet in state.completed.",
    },
    handleDone,
  );

  server.registerTool(
    "product_get_delegation_brief",
    {
      description: "Return a pasteable 5-field handoff block (TASK / CONTEXT / CONSTRAINTS / DELIVERABLE / DONE_WHEN per .claude/rules/delegation.md) for dispatching the given step to a sub-agent via the Agent tool. Errors with not-delegable if the step's mode is interactive.",
      inputSchema: {
        step_n: z.number().int().min(1).max(12).describe("The step number whose template's delegation_hint drives the brief."),
      },
    },
    handleGetDelegationBrief,
  );
}
