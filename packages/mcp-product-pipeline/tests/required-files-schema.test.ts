/**
 * Unit tests for templates.ts § parseRequiredFiles — the JSON fenced block
 * extractor that drives Layer 1 validation in product_step_submit.
 *
 * Shape spec lives in templates.ts JSDoc; this file pins the parser contract
 * via positive + negative cases so authoring mistakes in schema.md surface
 * loudly instead of silently producing under-validated steps.
 */

import { describe, expect, test } from "bun:test";
import { parseRequiredFiles } from "../src/templates.js";

describe("parseRequiredFiles — happy path", () => {
  test("returns null when no fenced block is present", () => {
    const schema = [
      "# Step schema",
      "",
      "## Required sections",
      "",
      "- intro",
      "- conclusion",
    ].join("\n");
    expect(parseRequiredFiles(schema)).toBeNull();
  });

  test("parses required_files exact-path entries", () => {
    const schema = [
      "## Required artifacts",
      "",
      "```required_files",
      "{",
      '  "required_files": [',
      '    { "path": "direction-a.html", "min_size": 8192, "contains": ["<html", "<style"] },',
      '    { "path": "REPORT.md", "min_size": 4096, "contains": ["5-dimension critique"] }',
      "  ]",
      "}",
      "```",
    ].join("\n");
    const result = parseRequiredFiles(schema);
    expect(result).not.toBeNull();
    expect(result!.required_files).toHaveLength(2);
    expect(result!.required_files![0]).toEqual({
      path: "direction-a.html",
      min_size: 8192,
      contains: ["<html", "<style"],
    });
    expect(result!.required_files![1]!.path).toBe("REPORT.md");
    expect(result!.required_glob).toBeUndefined();
  });

  test("parses required_glob entries", () => {
    const schema = [
      "```required_files",
      "{",
      '  "required_glob": [',
      "    {",
      '      "pattern": "screens/[0-9]+-*.html",',
      '      "min_count": 8,',
      '      "per_match_min_size": 8192,',
      '      "per_match_contains": ["<html", "<style"]',
      "    }",
      "  ]",
      "}",
      "```",
    ].join("\n");
    const result = parseRequiredFiles(schema);
    expect(result).not.toBeNull();
    expect(result!.required_glob).toHaveLength(1);
    expect(result!.required_glob![0]).toEqual({
      pattern: "screens/[0-9]+-*.html",
      min_count: 8,
      per_match_min_size: 8192,
      per_match_contains: ["<html", "<style"],
    });
    expect(result!.required_files).toBeUndefined();
  });

  test("parses both required_files and required_glob in same block", () => {
    const schema = [
      "```required_files",
      "{",
      '  "required_files": [{"path": "REPORT.md", "min_size": 4096}],',
      '  "required_glob": [{"pattern": "screens/*.html", "min_count": 8}]',
      "}",
      "```",
    ].join("\n");
    const result = parseRequiredFiles(schema);
    expect(result!.required_files).toHaveLength(1);
    expect(result!.required_glob).toHaveLength(1);
  });

  test("accepts entries with only path (no constraints)", () => {
    const schema = [
      "```required_files",
      "{",
      '  "required_files": [{ "path": "x.md" }]',
      "}",
      "```",
    ].join("\n");
    const result = parseRequiredFiles(schema);
    expect(result!.required_files![0]!.min_size).toBeUndefined();
    expect(result!.required_files![0]!.contains).toBeUndefined();
  });

  test("contains strings tolerate special chars (HTML tags)", () => {
    const schema = [
      "```required_files",
      "{",
      '  "required_files": [{ "path": "x.html", "contains": ["</style>", "--color-", "{}"] }]',
      "}",
      "```",
    ].join("\n");
    const result = parseRequiredFiles(schema);
    expect(result!.required_files![0]!.contains).toEqual(["</style>", "--color-", "{}"]);
  });
});

describe("parseRequiredFiles — error cases", () => {
  test("throws when fence opens but never closes", () => {
    const schema = [
      "```required_files",
      '{ "required_files": [] }',
      "(no closing fence)",
    ].join("\n");
    expect(() => parseRequiredFiles(schema)).toThrow(/no closing/i);
  });

  test("throws on malformed JSON inside fence", () => {
    const schema = [
      "```required_files",
      "{ this is not json",
      "```",
    ].join("\n");
    expect(() => parseRequiredFiles(schema)).toThrow(/not valid JSON/i);
  });

  test("throws when required_files entry is missing path", () => {
    const schema = [
      "```required_files",
      "{",
      '  "required_files": [{ "min_size": 100 }]',
      "}",
      "```",
    ].join("\n");
    expect(() => parseRequiredFiles(schema)).toThrow(/path must be a non-empty string/);
  });

  test("throws when min_size is negative", () => {
    const schema = [
      "```required_files",
      "{",
      '  "required_files": [{ "path": "x.md", "min_size": -1 }]',
      "}",
      "```",
    ].join("\n");
    expect(() => parseRequiredFiles(schema)).toThrow(/min_size must be a non-negative/);
  });

  test("throws when contains is not an array of strings", () => {
    const schema = [
      "```required_files",
      "{",
      '  "required_files": [{ "path": "x.md", "contains": [1, 2, 3] }]',
      "}",
      "```",
    ].join("\n");
    expect(() => parseRequiredFiles(schema)).toThrow(/contains must be an array of strings/);
  });

  test("throws when required_glob entry is missing pattern", () => {
    const schema = [
      "```required_files",
      "{",
      '  "required_glob": [{ "min_count": 8 }]',
      "}",
      "```",
    ].join("\n");
    expect(() => parseRequiredFiles(schema)).toThrow(/pattern must be a non-empty string/);
  });

  test("throws when top-level is an array (not an object)", () => {
    const schema = [
      "```required_files",
      '[{ "path": "x.md" }]',
      "```",
    ].join("\n");
    expect(() => parseRequiredFiles(schema)).toThrow(/must be a JSON object/);
  });
});
