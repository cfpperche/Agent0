/**
 * Unit tests for templates.ts — frontmatter parser shape contract.
 */

import { describe, expect, test } from "bun:test";
import { parseFrontmatter } from "../src/templates.js";

describe("parseFrontmatter — happy path", () => {
  test("parses valid required frontmatter and returns body", () => {
    const src = [
      "---",
      "mode: synthesis",
      "delegable: true",
      'delegation_hint: "draft system-design from PRD"',
      "---",
      "",
      "# Step 9",
      "",
      "Body content here.",
    ].join("\n");
    const { frontmatter, body } = parseFrontmatter(src);
    expect(frontmatter.mode).toBe("synthesis");
    expect(frontmatter.delegable).toBe("true");
    expect(frontmatter.delegation_hint).toBe("draft system-design from PRD");
    expect(body).toBe("\n# Step 9\n\nBody content here.");
  });

  test("strips matching single-quoted values", () => {
    const src = [
      "---",
      "mode: interactive",
      "delegable: false",
      "delegation_hint: 'n/a — interactive step'",
      "---",
      "body",
    ].join("\n");
    const { frontmatter } = parseFrontmatter(src);
    expect(frontmatter.delegation_hint).toBe("n/a — interactive step");
  });

  test("tolerates blank lines inside frontmatter", () => {
    const src = [
      "---",
      "mode: synthesis",
      "",
      "delegable: true",
      "delegation_hint: x",
      "---",
      "",
    ].join("\n");
    const { frontmatter } = parseFrontmatter(src);
    expect(frontmatter.mode).toBe("synthesis");
  });

  test("accepts all three modes", () => {
    for (const mode of ["interactive", "draft-after-input", "synthesis"]) {
      const src = `---\nmode: ${mode}\ndelegable: false\ndelegation_hint: x\n---\n`;
      expect(parseFrontmatter(src).frontmatter.mode).toBe(mode);
    }
  });

  test("accepts all three delegable levels", () => {
    for (const d of ["true", "partial", "false"]) {
      const src = `---\nmode: synthesis\ndelegable: ${d}\ndelegation_hint: x\n---\n`;
      expect(parseFrontmatter(src).frontmatter.delegable).toBe(d);
    }
  });
});

describe("parseFrontmatter — failure modes", () => {
  test("rejects when opening fence is missing", () => {
    const src = "mode: synthesis\ndelegable: true\ndelegation_hint: x\n---\n";
    expect(() => parseFrontmatter(src)).toThrow(/opening '---' fence/);
  });

  test("rejects when closing fence is missing", () => {
    const src = "---\nmode: synthesis\ndelegable: true\ndelegation_hint: x\n";
    expect(() => parseFrontmatter(src)).toThrow(/closing '---' fence/);
  });

  test("rejects malformed line (no colon)", () => {
    const src = [
      "---",
      "mode synthesis",
      "delegable: true",
      "delegation_hint: x",
      "---",
    ].join("\n");
    expect(() => parseFrontmatter(src)).toThrow(/not 'key: value' shape/);
  });

  test("rejects missing required key", () => {
    const src = [
      "---",
      "mode: synthesis",
      "delegable: true",
      "---",
    ].join("\n");
    expect(() => parseFrontmatter(src)).toThrow(/missing required.*delegation_hint/);
  });

  test("rejects unknown key", () => {
    const src = [
      "---",
      "mode: synthesis",
      "delegable: true",
      "delegation_hint: x",
      "extra_key: bogus",
      "---",
    ].join("\n");
    expect(() => parseFrontmatter(src)).toThrow(/unknown frontmatter key/);
  });

  test("rejects invalid mode value", () => {
    const src = [
      "---",
      "mode: bogus",
      "delegable: true",
      "delegation_hint: x",
      "---",
    ].join("\n");
    expect(() => parseFrontmatter(src)).toThrow(/invalid mode/);
  });

  test("rejects invalid delegable value", () => {
    const src = [
      "---",
      "mode: synthesis",
      "delegable: maybe",
      "delegation_hint: x",
      "---",
    ].join("\n");
    expect(() => parseFrontmatter(src)).toThrow(/invalid delegable/);
  });
});
