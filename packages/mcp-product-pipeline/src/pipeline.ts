/**
 * Canonical 12-step pipeline registry — single source of truth for ordering,
 * phase boundaries, gate placement, and directory naming. Lifted from
 * /home/goat/anthill/.anthill/config/pipeline.yaml entries 1-12.
 *
 * The per-step execution mode + delegation hint live in template frontmatter
 * (src/templates/<NN-name>/prompt.md), not here — this file holds the
 * structural facts only. See docs/specs/025-mcp-product-pipeline/plan.md
 * § Files for the mode assignment table.
 */

export type Phase = "discovery" | "identity" | "specification";

export type ExecutionMode = "interactive" | "draft-after-input" | "synthesis";

export type DelegableLevel = "true" | "partial" | "false";

export interface StepDef {
  /** 1-based step number (1..12). */
  n: number;
  /** Short kebab-case name (e.g. "ideation"). Stable identifier. */
  name: string;
  /** Directory under docs/product/ — zero-padded NN-name (e.g. "01-ideation"). */
  dir: string;
  /** Phase this step belongs to. */
  phase: Phase;
}

export const PHASES: readonly Phase[] = ["discovery", "identity", "specification"] as const;

/**
 * Step numbers that mark the END of a phase. After completing one of these,
 * product_advance requires product_gate_pass(<closing phase>) before crossing
 * into the next phase.
 *
 *   Step 4 closes discovery  → gate before step 5 (identity)
 *   Step 7 closes identity   → gate before step 8 (specification)
 *   Step 12 closes specification → pipeline complete, handoff to /sdd
 */
export const GATE_AFTER: readonly number[] = [4, 7, 12] as const;

export const STEPS: readonly StepDef[] = [
  // ── Discovery ──────────────────────────────────────────────
  { n: 1, name: "ideation", dir: "01-ideation", phase: "discovery" },
  { n: 2, name: "prototype", dir: "02-prototype", phase: "discovery" },
  { n: 3, name: "spec", dir: "03-spec", phase: "discovery" },
  { n: 4, name: "ux-testing", dir: "04-ux-testing", phase: "discovery" },

  // ── Identity ───────────────────────────────────────────────
  { n: 5, name: "brand", dir: "05-brand", phase: "identity" },
  { n: 6, name: "design-system", dir: "06-design-system", phase: "identity" },
  { n: 7, name: "prototype-v2", dir: "07-prototype-v2", phase: "identity" },

  // ── Specification ──────────────────────────────────────────
  { n: 8, name: "prd", dir: "08-prd", phase: "specification" },
  { n: 9, name: "system-design", dir: "09-system-design", phase: "specification" },
  { n: 10, name: "cost-estimate", dir: "10-cost-estimate", phase: "specification" },
  { n: 11, name: "roadmap", dir: "11-roadmap", phase: "specification" },
  { n: 12, name: "legal", dir: "12-legal", phase: "specification" },
] as const;

export const FIRST_STEP = 1 as const;
export const LAST_STEP = 12 as const;

export function stepByN(n: number): StepDef {
  const step = STEPS.find((s) => s.n === n);
  if (!step) {
    throw new Error(`pipeline: no step with n=${n} (valid range: ${FIRST_STEP}..${LAST_STEP})`);
  }
  return step;
}

export function isGateAfter(n: number): boolean {
  return GATE_AFTER.includes(n);
}

/**
 * The phase that is CLOSING when step n is the last completed step and the
 * next step crosses into a new phase. Returns null if n is not a gate-after
 * boundary.
 */
export function gateClosingPhase(n: number): Phase | null {
  if (!isGateAfter(n)) return null;
  return stepByN(n).phase;
}
