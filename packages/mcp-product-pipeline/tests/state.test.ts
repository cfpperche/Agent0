/**
 * Unit tests for state.ts. Each test gets a temp dir as cwd so paths.ts's
 * cwd-relative resolution lands in an isolated sandbox. Cleaned up afterEach.
 */

import { afterEach, beforeEach, describe, expect, test } from "bun:test";
import { mkdtemp, readFile, rm } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import {
  advanceStep,
  initState,
  markCompleted,
  markGatePassed,
  readState,
  setValidationMode,
  writeState,
  type PipelineState,
} from "../src/state.js";

let tmpRoot: string;
let originalCwd: string;

beforeEach(async () => {
  originalCwd = process.cwd();
  tmpRoot = await mkdtemp(join(tmpdir(), "mpp-state-test-"));
  process.chdir(tmpRoot);
});

afterEach(async () => {
  process.chdir(originalCwd);
  await rm(tmpRoot, { recursive: true, force: true });
});

describe("readState", () => {
  test("returns null when state file is missing", async () => {
    const state = await readState();
    expect(state).toBeNull();
  });

  test("returns parsed state after a write", async () => {
    const sample: PipelineState = {
      slug: "foo",
      current_step: 1,
      phase: "discovery",
      completed: [],
      gates_passed: [],
      started_at: "2026-05-12T00:00:00.000Z",
    };
    await writeState(sample);
    const read = await readState();
    expect(read).toEqual(sample);
  });
});

describe("initState", () => {
  test("creates a fresh state with sensible defaults", async () => {
    const state = await initState("tiktok-clone");
    expect(state.slug).toBe("tiktok-clone");
    expect(state.current_step).toBe(1);
    expect(state.phase).toBe("discovery");
    expect(state.completed).toEqual([]);
    expect(state.gates_passed).toEqual([]);
    expect(state.started_at).toMatch(/^\d{4}-\d{2}-\d{2}T/);
  });

  test("rejects non-kebab-case slugs", async () => {
    await expect(initState("TikTok")).rejects.toThrow(/kebab-case/);
    await expect(initState("123-bad")).rejects.toThrow(/kebab-case/);
    await expect(initState("with_underscore")).rejects.toThrow(/kebab-case/);
    await expect(initState("")).rejects.toThrow(/kebab-case/);
  });

  test("is idempotent when called with the same slug", async () => {
    const first = await initState("foo");
    const second = await initState("foo");
    expect(second).toEqual(first);
  });

  test("rejects when an existing pipeline has a different slug", async () => {
    await initState("foo");
    await expect(initState("bar")).rejects.toThrow(/multi-product/i);
  });
});

describe("markCompleted", () => {
  test("appends step number to completed array", async () => {
    await initState("foo");
    const after1 = await markCompleted(1);
    expect(after1.completed).toEqual([1]);
    const after2 = await markCompleted(2);
    expect(after2.completed).toEqual([1, 2]);
  });

  test("is idempotent — re-marking the same step is a no-op", async () => {
    await initState("foo");
    await markCompleted(1);
    await markCompleted(1);
    const state = await readState();
    expect(state?.completed).toEqual([1]);
  });

  test("keeps completed sorted ascending even with out-of-order calls", async () => {
    await initState("foo");
    await markCompleted(3);
    await markCompleted(1);
    await markCompleted(2);
    const state = await readState();
    expect(state?.completed).toEqual([1, 2, 3]);
  });

  test("throws if state file is missing", async () => {
    await expect(markCompleted(1)).rejects.toThrow(/no state file/i);
  });
});

describe("markGatePassed", () => {
  test("appends phase to gates_passed", async () => {
    await initState("foo");
    const after = await markGatePassed("discovery");
    expect(after.gates_passed).toEqual(["discovery"]);
  });

  test("is idempotent", async () => {
    await initState("foo");
    await markGatePassed("discovery");
    await markGatePassed("discovery");
    const state = await readState();
    expect(state?.gates_passed).toEqual(["discovery"]);
  });

  test("preserves chronological order of gate passes", async () => {
    await initState("foo");
    await markGatePassed("discovery");
    await markGatePassed("identity");
    const state = await readState();
    expect(state?.gates_passed).toEqual(["discovery", "identity"]);
  });
});

describe("advanceStep", () => {
  test("increments current_step and updates cached phase at boundaries", async () => {
    await initState("foo");
    // start at step 1 (discovery)
    let state = await advanceStep(); // -> 2
    expect(state.current_step).toBe(2);
    expect(state.phase).toBe("discovery");
    state = await advanceStep(); // -> 3
    state = await advanceStep(); // -> 4
    state = await advanceStep(); // -> 5 (identity)
    expect(state.current_step).toBe(5);
    expect(state.phase).toBe("identity");
    state = await advanceStep(); // -> 6
    state = await advanceStep(); // -> 7
    state = await advanceStep(); // -> 8 (specification)
    expect(state.current_step).toBe(8);
    expect(state.phase).toBe("specification");
  });

  test("stays at last phase after step 12 (post-pipeline)", async () => {
    await initState("foo");
    // jump to step 12
    await writeState({
      ...(await readState())!,
      current_step: 12,
      phase: "specification",
    });
    const state = await advanceStep();
    expect(state.current_step).toBe(13);
    expect(state.phase).toBe("specification");
  });
});

describe("setValidationMode", () => {
  test("stores the validation_mode field", async () => {
    await initState("foo");
    const after = await setValidationMode("intuition");
    expect(after.validation_mode).toBe("intuition");
  });

  test("is idempotent within the same mode", async () => {
    await initState("foo");
    await setValidationMode("tested");
    const state = await setValidationMode("tested");
    expect(state.validation_mode).toBe("tested");
  });
});

describe("atomic write — no torn writes under concurrent calls", () => {
  test("ten parallel completes leave a valid JSON state", async () => {
    await initState("foo");
    await Promise.all(
      Array.from({ length: 10 }, (_, i) => markCompleted(i + 1)),
    );
    const raw = await readFile(join(tmpRoot, "docs/product/.state.json"), "utf8");
    // must parse cleanly (no half-written JSON)
    const parsed = JSON.parse(raw) as PipelineState;
    expect(parsed.slug).toBe("foo");
    // Race posture is last-write-wins; we don't assert .completed has all 10
    // (the array length depends on interleaving). We only assert the file
    // is valid JSON. That's the atomic-rename contract.
    expect(Array.isArray(parsed.completed)).toBe(true);
  });
});
