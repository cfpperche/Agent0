/**
 * Pipeline state I/O — owns docs/product/.state.json.
 *
 * The state file is a thin index over the filesystem artifacts; the markdown
 * under docs/product/<NN-name>/*.md IS the canonical record. State exists
 * so the MCP can answer "what step are we on?" without globbing.
 *
 * Writes are atomic via mktemp + rename (POSIX rename atomicity). Reads
 * tolerate missing file (returns null) but reject malformed JSON (throws).
 *
 * Race posture: last-write-wins. The agent serialises tool calls in practice
 * so concurrent writes are unlikely; the rename atomicity prevents torn
 * writes if they ever happen. No file locking in v1.
 */

import { randomUUID } from "node:crypto";
import { mkdir, readFile, rename, writeFile } from "node:fs/promises";
import {
  FIRST_STEP,
  type Phase,
  stepByN,
} from "./pipeline.js";
import { productRoot, stateFile } from "./paths.js";

export interface PipelineState {
  /** kebab-case product slug, e.g. "tiktok-clone". Immutable for the lifetime of the pipeline. */
  slug: string;
  /** 1-based step the agent is currently working on (1..12). */
  current_step: number;
  /** Cached phase for current_step (denormalised; matches stepByN(current_step).phase). */
  phase: Phase;
  /** Step numbers fully submitted-and-advanced. Sorted ascending, no duplicates. */
  completed: number[];
  /** Phases the user has explicitly gate-passed. Order: discovery → identity → specification. */
  gates_passed: Phase[];
  /** ISO-8601 UTC. Set at initState, never mutated. */
  started_at: string;
  /** Optional: step 4 (ux-testing) declares "tested" | "intuition" | "not-applicable". */
  validation_mode?: "tested" | "intuition" | "not-applicable";
}

/** Read state file. Returns null if missing; throws on parse error. */
export async function readState(): Promise<PipelineState | null> {
  try {
    const raw = await readFile(stateFile(), "utf8");
    return JSON.parse(raw) as PipelineState;
  } catch (err: unknown) {
    if ((err as NodeJS.ErrnoException)?.code === "ENOENT") return null;
    throw err;
  }
}

/** Atomic write: writes to <stateFile>.tmp then renames. */
export async function writeState(state: PipelineState): Promise<void> {
  await mkdir(productRoot(), { recursive: true });
  const target = stateFile();
  // UUID-suffixed tmp avoids collision when two writers land in the same
  // millisecond + pid — `Date.now()`-only suffixes were observed to collide
  // under Promise.all concurrent calls (state.test.ts atomic-write case).
  const tmp = `${target}.tmp.${randomUUID()}`;
  await writeFile(tmp, JSON.stringify(state, null, 2) + "\n", "utf8");
  await rename(tmp, target);
}

/** Initialise state for a fresh slug. Throws if state already exists with a different slug. */
export async function initState(slug: string): Promise<PipelineState> {
  if (!/^[a-z][a-z0-9-]*$/.test(slug)) {
    throw new Error(
      `initState: slug must match /^[a-z][a-z0-9-]*$/ (kebab-case starting with a letter); got "${slug}"`,
    );
  }
  const existing = await readState();
  if (existing && existing.slug !== slug) {
    throw new Error(
      `initState: a pipeline already exists for slug "${existing.slug}". ` +
      `Multi-product is out of scope (spec 025 non-goals). To start fresh, ` +
      `archive or remove docs/product/ first.`,
    );
  }
  if (existing) return existing; // idempotent restart with same slug

  const fresh: PipelineState = {
    slug,
    current_step: FIRST_STEP,
    phase: stepByN(FIRST_STEP).phase,
    completed: [],
    gates_passed: [],
    started_at: new Date().toISOString(),
  };
  await writeState(fresh);
  return fresh;
}

/** Mark step n as completed. Idempotent — re-running with the same n is a no-op. */
export async function markCompleted(n: number): Promise<PipelineState> {
  const state = await readState();
  if (!state) {
    throw new Error("markCompleted: no state file. Call initState(slug) first.");
  }
  if (state.completed.includes(n)) return state;
  const next: PipelineState = {
    ...state,
    completed: [...state.completed, n].sort((a, b) => a - b),
  };
  await writeState(next);
  return next;
}

/** Append a passed-gate phase. Idempotent. */
export async function markGatePassed(phase: Phase): Promise<PipelineState> {
  const state = await readState();
  if (!state) {
    throw new Error("markGatePassed: no state file. Call initState(slug) first.");
  }
  if (state.gates_passed.includes(phase)) return state;
  const next: PipelineState = {
    ...state,
    gates_passed: [...state.gates_passed, phase],
  };
  await writeState(next);
  return next;
}

/** Move current_step forward by 1 (and update cached phase). Caller verifies gate logic. */
export async function advanceStep(): Promise<PipelineState> {
  const state = await readState();
  if (!state) {
    throw new Error("advanceStep: no state file. Call initState(slug) first.");
  }
  const next_n = state.current_step + 1;
  const nextPhase = next_n <= 12 ? stepByN(next_n).phase : state.phase;
  const next: PipelineState = {
    ...state,
    current_step: next_n,
    phase: nextPhase,
  };
  await writeState(next);
  return next;
}

/** Read-only convenience accessor. Returns FIRST_STEP-equivalent if no state. */
export async function getCurrentStep(): Promise<number | null> {
  const state = await readState();
  return state?.current_step ?? null;
}

/** Record the step-4 validation mode declaration. Idempotent within same mode. */
export async function setValidationMode(
  mode: "tested" | "intuition" | "not-applicable",
): Promise<PipelineState> {
  const state = await readState();
  if (!state) {
    throw new Error("setValidationMode: no state file. Call initState(slug) first.");
  }
  if (state.validation_mode === mode) return state;
  const next: PipelineState = { ...state, validation_mode: mode };
  await writeState(next);
  return next;
}
