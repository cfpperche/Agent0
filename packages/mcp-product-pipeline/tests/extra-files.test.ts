/**
 * Tests for the spec 026 plumbing extensions:
 *   - atomicWriteFile (mktemp + rename per file)
 *   - globToRegExp (glob → RegExp anchored on relative paths)
 *   - validateLayer1 (required_files + required_glob enforcement)
 *
 * These are the pieces product_step_submit composes into Layer 1 of the
 * 3-layer quality discipline. Tests pin behaviour before content port
 * (Phase B) starts authoring multi-artifact schemas.
 */

import { afterEach, beforeEach, describe, expect, test } from "bun:test";
import { mkdtemp, readFile, rm } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import {
  atomicWriteFile,
  globToRegExp,
  validateLayer1,
  type SubmissionFile,
} from "../src/tools.js";
import type { RequiredFilesSpec } from "../src/templates.js";

let tmpRoot: string;

beforeEach(async () => {
  tmpRoot = await mkdtemp(join(tmpdir(), "mpp-extra-files-test-"));
});

afterEach(async () => {
  await rm(tmpRoot, { recursive: true, force: true });
});

describe("atomicWriteFile", () => {
  test("writes content to target path via tmp+rename", async () => {
    const target = join(tmpRoot, "a.html");
    await atomicWriteFile(target, "<html><body>hi</body></html>");
    expect(await readFile(target, "utf8")).toBe("<html><body>hi</body></html>");
  });

  test("creates parent directories as needed", async () => {
    const target = join(tmpRoot, "nested", "deep", "x.css");
    await atomicWriteFile(target, ":root { --x: 1; }");
    expect(await readFile(target, "utf8")).toBe(":root { --x: 1; }");
  });

  test("overwrites existing file atomically", async () => {
    const target = join(tmpRoot, "b.md");
    await atomicWriteFile(target, "first");
    await atomicWriteFile(target, "second");
    expect(await readFile(target, "utf8")).toBe("second");
  });

  test("concurrent writes to different targets do not collide", async () => {
    const targets = Array.from({ length: 10 }, (_, i) => join(tmpRoot, `f${i}.txt`));
    await Promise.all(targets.map((t, i) => atomicWriteFile(t, `body-${i}`)));
    for (let i = 0; i < 10; i++) {
      expect(await readFile(targets[i]!, "utf8")).toBe(`body-${i}`);
    }
  });
});

describe("globToRegExp", () => {
  test("* matches any chars except /", () => {
    const re = globToRegExp("screens/*.html");
    expect(re.test("screens/landing.html")).toBe(true);
    expect(re.test("screens/dashboard.html")).toBe(true);
    expect(re.test("screens/sub/landing.html")).toBe(false);
    expect(re.test("other/landing.html")).toBe(false);
  });

  test("** matches any chars including /", () => {
    const re = globToRegExp("docs/**/page.html");
    expect(re.test("docs/a/page.html")).toBe(true);
    expect(re.test("docs/a/b/page.html")).toBe(true);
    expect(re.test("docs/page.html")).toBe(false); // ** requires at least one segment; use docs/*/page.html if you want one level
  });

  test("? matches single char except /", () => {
    const re = globToRegExp("file?.txt");
    expect(re.test("fileA.txt")).toBe(true);
    expect(re.test("file12.txt")).toBe(false);
    expect(re.test("file/x.txt")).toBe(false);
  });

  test("character class + quantifier works", () => {
    const re = globToRegExp("screens/[0-9]+-*.html");
    expect(re.test("screens/01-landing.html")).toBe(true);
    expect(re.test("screens/123-dashboard.html")).toBe(true);
    expect(re.test("screens/foo-landing.html")).toBe(false);
    expect(re.test("screens/01-landing.css")).toBe(false);
  });

  test("regex special chars are escaped (.+(){})", () => {
    const re = globToRegExp("file.txt");
    expect(re.test("file.txt")).toBe(true);
    expect(re.test("fileAtxt")).toBe(false); // . must match literal .
  });

  test("anchors full path (no implicit prefix/suffix match)", () => {
    const re = globToRegExp("a.html");
    expect(re.test("a.html")).toBe(true);
    expect(re.test("prefix/a.html")).toBe(false);
    expect(re.test("a.html.bak")).toBe(false);
  });
});

describe("validateLayer1 — required_files exact paths", () => {
  const spec: RequiredFilesSpec = {
    required_files: [
      { path: "REPORT.md", min_size: 100, contains: ["5-dimension critique"] },
      { path: "direction-a.html", min_size: 50, contains: ["<html"] },
    ],
  };

  test("returns empty array when all requirements met", () => {
    const files: SubmissionFile[] = [
      { path: "REPORT.md", content: "x".repeat(50) + "## 5-dimension critique\n" + "x".repeat(100) },
      { path: "direction-a.html", content: "<!doctype html><html><body>" + "x".repeat(100) + "</body></html>" },
    ];
    expect(validateLayer1(spec, files)).toEqual([]);
  });

  test("reports missing file when path absent", () => {
    const files: SubmissionFile[] = [
      { path: "REPORT.md", content: "x".repeat(200) + "5-dimension critique" },
    ];
    const failures = validateLayer1(spec, files);
    expect(failures).toHaveLength(1);
    expect(failures[0]!.path).toBe("direction-a.html");
    expect(failures[0]!.reason).toMatch(/missing from submission/);
  });

  test("reports under-min_size content", () => {
    const files: SubmissionFile[] = [
      { path: "REPORT.md", content: "tiny" },
      { path: "direction-a.html", content: "<html>" + "x".repeat(100) },
    ];
    const failures = validateLayer1(spec, files);
    const reportFailure = failures.find((f) => f.path === "REPORT.md");
    expect(reportFailure!.reason).toMatch(/below min_size/);
  });

  test("reports missing contains substring", () => {
    const files: SubmissionFile[] = [
      { path: "REPORT.md", content: "x".repeat(200) }, // missing "5-dimension critique"
      { path: "direction-a.html", content: "<html>" + "x".repeat(100) },
    ];
    const failures = validateLayer1(spec, files);
    expect(failures.some((f) => f.path === "REPORT.md" && /5-dimension critique/.test(f.reason))).toBe(true);
  });

  test("aggregates multiple failures across files", () => {
    const files: SubmissionFile[] = [
      { path: "REPORT.md", content: "tiny" }, // size + missing contains
      // direction-a.html entirely absent
    ];
    const failures = validateLayer1(spec, files);
    expect(failures.length).toBeGreaterThanOrEqual(2);
  });
});

describe("validateLayer1 — required_glob", () => {
  const spec: RequiredFilesSpec = {
    required_glob: [
      {
        pattern: "screens/[0-9]+-*.html",
        min_count: 3,
        per_match_min_size: 50,
        per_match_contains: ["<html"],
      },
    ],
  };

  test("passes when min_count met and all matches pass per-match checks", () => {
    const files: SubmissionFile[] = Array.from({ length: 4 }, (_, i) => ({
      path: `screens/0${i + 1}-page.html`,
      content: "<html><body>" + "x".repeat(60) + "</body></html>",
    }));
    expect(validateLayer1(spec, files)).toEqual([]);
  });

  test("reports under-min_count failure", () => {
    const files: SubmissionFile[] = [
      { path: "screens/01-page.html", content: "<html>" + "x".repeat(100) },
    ];
    const failures = validateLayer1(spec, files);
    expect(failures).toHaveLength(1);
    expect(failures[0]!.pattern).toBe("screens/[0-9]+-*.html");
    expect(failures[0]!.reason).toMatch(/min_count 3/);
  });

  test("non-matching paths do not count toward min_count", () => {
    const files: SubmissionFile[] = [
      { path: "screens/01-page.html", content: "<html>" + "x".repeat(100) },
      { path: "screens/foo-bar.html", content: "<html>" + "x".repeat(100) }, // does not match [0-9]+
      { path: "screens/02-page.html", content: "<html>" + "x".repeat(100) },
    ];
    const failures = validateLayer1(spec, files);
    expect(failures.some((f) => /matched 2 file/.test(f.reason))).toBe(true);
  });

  test("per-match min_size violation flagged on the offending file", () => {
    const files: SubmissionFile[] = [
      { path: "screens/01-page.html", content: "<html>" + "x".repeat(100) },
      { path: "screens/02-page.html", content: "<html>tiny" },
      { path: "screens/03-page.html", content: "<html>" + "x".repeat(100) },
    ];
    const failures = validateLayer1(spec, files);
    const offender = failures.find((f) => f.path === "screens/02-page.html");
    expect(offender).toBeDefined();
    expect(offender!.reason).toMatch(/per_match_min_size/);
  });
});

describe("validateLayer1 — empty / backwards-compat", () => {
  test("empty spec returns empty failures regardless of files", () => {
    const spec: RequiredFilesSpec = {};
    const files: SubmissionFile[] = [{ path: "anything.md", content: "x" }];
    expect(validateLayer1(spec, files)).toEqual([]);
  });
});

describe("validateLayer1 — any_of_contains (OR-semantics for required_files)", () => {
  const spec: RequiredFilesSpec = {
    required_files: [
      {
        path: "REPORT.md",
        any_of_contains: [
          "### Findings reviewed (not actioned",
          "*Step 4 audit ran without YAML frontmatter",
          "*No prototype-v2-routed findings",
        ],
      },
    ],
  };

  test("passes when at least one substring is present", () => {
    const files: SubmissionFile[] = [
      { path: "REPORT.md", content: "## Audit Response\n\n*No prototype-v2-routed findings from step 4 audit*\n" },
    ];
    expect(validateLayer1(spec, files)).toEqual([]);
  });

  test("passes when a different listed substring is present", () => {
    const files: SubmissionFile[] = [
      { path: "REPORT.md", content: "## Audit Response\n\n### Findings reviewed (not actioned at prototype-v2 layer)\n" },
    ];
    expect(validateLayer1(spec, files)).toEqual([]);
  });

  test("fails when NONE of the listed substrings is present", () => {
    const files: SubmissionFile[] = [
      { path: "REPORT.md", content: "## Audit Response\n\nThe audit was reviewed.\n" },
    ];
    const failures = validateLayer1(spec, files);
    expect(failures).toHaveLength(1);
    expect(failures[0]!.path).toBe("REPORT.md");
    expect(failures[0]!.reason).toMatch(/any of the required substrings/);
  });

  test("empty any_of_contains array is a no-op (does not fail)", () => {
    const specEmpty: RequiredFilesSpec = {
      required_files: [{ path: "REPORT.md", any_of_contains: [] }],
    };
    const files: SubmissionFile[] = [{ path: "REPORT.md", content: "any content" }];
    expect(validateLayer1(specEmpty, files)).toEqual([]);
  });

  test("any_of_contains composes with contains (AND + OR both enforced)", () => {
    const specBoth: RequiredFilesSpec = {
      required_files: [
        {
          path: "REPORT.md",
          contains: ["## Audit Response"], // required (AND)
          any_of_contains: ["*No prototype-v2-routed findings", "### Findings reviewed"], // one-of (OR)
        },
      ],
    };
    const files: SubmissionFile[] = [
      { path: "REPORT.md", content: "## Audit Response\n\n*No prototype-v2-routed findings from step 4*" },
    ];
    expect(validateLayer1(specBoth, files)).toEqual([]);
  });
});

describe("validateLayer1 — per_match_any_of_contains (OR-semantics for required_glob)", () => {
  const spec: RequiredFilesSpec = {
    required_glob: [
      {
        pattern: "screens/[0-9]+-*.html",
        min_count: 1,
        per_match_any_of_contains: ["<input", "<textarea", "<!-- semantic-input -->"],
      },
    ],
  };

  test("passes when each matched file carries at least one of the listed substrings", () => {
    const files: SubmissionFile[] = [
      { path: "screens/01-page.html", content: "<form><input type=text></form>" },
      { path: "screens/02-page.html", content: "<form><textarea></textarea></form>" },
    ];
    expect(validateLayer1(spec, files)).toEqual([]);
  });

  test("fails on the offending match when none of the substrings are present", () => {
    const files: SubmissionFile[] = [
      { path: "screens/01-page.html", content: "<form><input type=text></form>" },
      { path: "screens/02-page.html", content: "<div class='fake-input'>No real input</div>" },
    ];
    const failures = validateLayer1(spec, files);
    expect(failures).toHaveLength(1);
    expect(failures[0]!.path).toBe("screens/02-page.html");
    expect(failures[0]!.reason).toMatch(/any of the required substrings/);
  });
});
