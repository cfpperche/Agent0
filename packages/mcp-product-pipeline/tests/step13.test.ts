/**
 * Tests for the 13-step pipeline extension introduced by spec 026.
 *
 * Step 13 (prototype-v3) is the synthesis step that closes the pipeline with
 * a comprehensive screen atlas. It lives in the Specification phase and does
 * NOT add a new gate — GATE_AFTER stays [4, 7, 12]. After step 13 submits,
 * product_advance fires pipeline-complete and the /sdd handoff message.
 *
 * This file pins the structural facts so any future hand-edit of pipeline.ts
 * that drops back to 12 steps fails loudly.
 */

import { describe, expect, test } from "bun:test";
import {
  FIRST_STEP,
  GATE_AFTER,
  LAST_STEP,
  PHASES,
  STEPS,
  gateClosingPhase,
  isGateAfter,
  stepByN,
} from "../src/pipeline.js";

describe("pipeline registry — 13-step shape", () => {
  test("STEPS contains exactly 13 entries", () => {
    expect(STEPS).toHaveLength(13);
  });

  test("FIRST_STEP is 1 and LAST_STEP is 13", () => {
    expect(FIRST_STEP).toBe(1);
    expect(LAST_STEP).toBe(13);
  });

  test("step numbers are 1..13 contiguous and sorted", () => {
    const ns = STEPS.map((s) => s.n);
    expect(ns).toEqual([1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13]);
  });

  test("step 13 entry is prototype-v3 / 13-prototype-v3 / specification", () => {
    const step13 = stepByN(13);
    expect(step13.n).toBe(13);
    expect(step13.name).toBe("prototype-v3");
    expect(step13.dir).toBe("13-prototype-v3");
    expect(step13.phase).toBe("specification");
  });

  test("phase distribution: 4 discovery, 3 identity, 6 specification", () => {
    const counts = { discovery: 0, identity: 0, specification: 0 };
    for (const s of STEPS) counts[s.phase]++;
    expect(counts).toEqual({ discovery: 4, identity: 3, specification: 6 });
  });

  test("PHASES order is discovery → identity → specification", () => {
    expect([...PHASES]).toEqual(["discovery", "identity", "specification"]);
  });
});

describe("gate placement — step 13 closes nothing", () => {
  test("GATE_AFTER stays [4, 7, 12]", () => {
    expect([...GATE_AFTER]).toEqual([4, 7, 12]);
  });

  test("isGateAfter(13) is false (final step is in-phase deliverable)", () => {
    expect(isGateAfter(13)).toBe(false);
  });

  test("isGateAfter(12) is still true (specification gate before step 13)", () => {
    expect(isGateAfter(12)).toBe(true);
  });

  test("gateClosingPhase(13) is null", () => {
    expect(gateClosingPhase(13)).toBeNull();
  });

  test("gateClosingPhase(12) is specification (unchanged from v1)", () => {
    expect(gateClosingPhase(12)).toBe("specification");
  });
});

describe("stepByN bounds", () => {
  test("stepByN(13) succeeds", () => {
    expect(() => stepByN(13)).not.toThrow();
  });

  test("stepByN(14) throws with the new 13-step range hint", () => {
    expect(() => stepByN(14)).toThrow(/range:\s*1\.\.13/);
  });

  test("stepByN(0) throws", () => {
    expect(() => stepByN(0)).toThrow();
  });
});
