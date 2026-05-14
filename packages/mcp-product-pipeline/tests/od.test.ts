/**
 * Unit tests for src/od.ts — the Open Design vendor access layer (spec 027).
 *
 * Covers vendor-path resolution (dev layout vs simulated installed layout),
 * ds-index.json loading, the fail-loud VendorMissingError on a partial tree,
 * and designSystemPath name validation. The dev-vs-installed distinction is
 * just a different `pkgRoot` — od.ts is parameterised on it so both layouts
 * are one code path exercised against two fixture roots.
 */

import { afterEach, beforeEach, describe, expect, test } from "bun:test";
import { mkdtemp, mkdir, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import {
  odPaths,
  vendorAnchors,
  assertVendorPresent,
  loadDsIndex,
  designSystemPath,
  VendorMissingError,
  OdDisabledError,
  odDisabled,
  _resetDsIndexCache,
} from "../src/od.js";
import { packageRoot } from "../src/paths.js";

let tmpRoot: string;

beforeEach(async () => {
  tmpRoot = await mkdtemp(join(tmpdir(), "od-test-"));
  _resetDsIndexCache();
});

afterEach(async () => {
  await rm(tmpRoot, { recursive: true, force: true });
  _resetDsIndexCache();
});

/** Stage a minimally-complete vendor tree under `root`. */
async function stageVendor(root: string, systems: string[] = ["linear-app", "stripe"]) {
  await mkdir(join(root, "vendor/open-design/.cache"), { recursive: true });
  await mkdir(join(root, "vendor/open-design/skills"), { recursive: true });
  await mkdir(join(root, "vendor/open-design/prompts"), { recursive: true });
  await mkdir(join(root, "vendor/open-design/frames"), { recursive: true });
  await mkdir(join(root, "vendor/open-design/templates"), { recursive: true });
  await writeFile(join(root, "vendor/open-design/MANIFEST.json"), "{}");
  for (const name of systems) {
    await mkdir(join(root, "design-systems", name), { recursive: true });
    await writeFile(join(root, "design-systems", name, "DESIGN.md"), `# ${name}\n`);
  }
  const index = {
    generated_at: "2026-05-14T00:00:00.000Z",
    pinned_sha: "d25a7aaf4219d69b6a3055ddda25fbce0dafd24d",
    count: systems.length,
    systems: systems.map((name) => ({ name, mood: `${name} mood`, palette_summary: ["#000000"] })),
  };
  await writeFile(
    join(root, "vendor/open-design/.cache/ds-index.json"),
    JSON.stringify(index, null, 2),
  );
}

describe("odPaths — layout-agnostic resolution", () => {
  test("joins all vendor subtree paths under the given package root", () => {
    const p = odPaths("/some/pkg");
    expect(p.vendorRoot).toBe("/some/pkg/vendor/open-design");
    expect(p.designSystemsRoot).toBe("/some/pkg/design-systems");
    expect(p.skillsRoot).toBe("/some/pkg/vendor/open-design/skills");
    expect(p.dsIndexPath).toBe("/some/pkg/vendor/open-design/.cache/ds-index.json");
    expect(p.manifestPath).toBe("/some/pkg/vendor/open-design/MANIFEST.json");
  });

  test("dev layout and simulated-installed layout resolve identically (just a different root)", () => {
    const dev = odPaths("/repo/packages/mcp-product-pipeline");
    const installed = odPaths("/proj/node_modules/agent0-mcp-product-pipeline");
    // Same internal structure, different prefix — the only difference between layouts.
    expect(dev.skillsRoot.replace("/repo/packages/mcp-product-pipeline", "")).toBe(
      installed.skillsRoot.replace("/proj/node_modules/agent0-mcp-product-pipeline", ""),
    );
  });

  test("vendorAnchors exposes the five agent-readable subtree roots", () => {
    const anchors = vendorAnchors("/some/pkg");
    expect(Object.keys(anchors).sort()).toEqual(
      ["design_systems", "frames", "prompts", "skills", "templates"],
    );
    expect(anchors.skills).toBe("/some/pkg/vendor/open-design/skills");
  });
});

describe("assertVendorPresent — fail-loud on a missing/partial tree", () => {
  test("passes on a complete fixture tree", async () => {
    await stageVendor(tmpRoot);
    expect(() => assertVendorPresent(tmpRoot)).not.toThrow();
  });

  test("throws VendorMissingError naming the absent anchors", async () => {
    // empty root — nothing staged
    let caught: unknown;
    try {
      assertVendorPresent(tmpRoot);
    } catch (e) {
      caught = e;
    }
    expect(caught).toBeInstanceOf(VendorMissingError);
    expect((caught as VendorMissingError).code).toBe("od-vendor-missing");
    expect((caught as VendorMissingError).missing.length).toBeGreaterThan(0);
  });

  test("throws when the tree is partial (ds-index.json absent)", async () => {
    await stageVendor(tmpRoot);
    await rm(join(tmpRoot, "vendor/open-design/.cache/ds-index.json"));
    expect(() => assertVendorPresent(tmpRoot)).toThrow(VendorMissingError);
  });
});

describe("loadDsIndex", () => {
  test("parses ds-index.json from a fixture root", async () => {
    await stageVendor(tmpRoot, ["linear-app", "stripe", "notion"]);
    const idx = loadDsIndex(tmpRoot);
    expect(idx.count).toBe(3);
    expect(idx.systems.map((s) => s.name)).toContain("notion");
  });

  test("throws VendorMissingError when the vendor tree is absent", () => {
    expect(() => loadDsIndex(tmpRoot)).toThrow(VendorMissingError);
  });

  test("loads the real vendored index from the package root (72 systems)", () => {
    const idx = loadDsIndex(packageRoot());
    expect(idx.count).toBe(72);
    expect(idx.systems).toHaveLength(72);
    expect(idx.systems[0]).toHaveProperty("mood");
    expect(idx.systems[0]).toHaveProperty("palette_summary");
  });
});

describe("designSystemPath", () => {
  test("resolves a known system to its absolute DESIGN.md path", async () => {
    await stageVendor(tmpRoot);
    const p = designSystemPath("linear-app", tmpRoot);
    expect(p).toBe(join(tmpRoot, "design-systems/linear-app/DESIGN.md"));
  });

  test("fail-loud on an unknown system name", async () => {
    await stageVendor(tmpRoot);
    expect(() => designSystemPath("does-not-exist", tmpRoot)).toThrow(/unknown design system/);
  });

  test("rejects a non-kebab-case name before touching the filesystem", async () => {
    await stageVendor(tmpRoot);
    expect(() => designSystemPath("../etc/passwd", tmpRoot)).toThrow(/invalid design-system name/);
    expect(() => designSystemPath("Linear_App", tmpRoot)).toThrow(/invalid design-system name/);
  });

  test("throws VendorMissingError when the vendor tree is absent", () => {
    expect(() => designSystemPath("linear-app", tmpRoot)).toThrow(VendorMissingError);
  });

  test("resolves real vendored systems from the package root", () => {
    const p = designSystemPath("linear-app", packageRoot());
    expect(p).toBe(join(packageRoot(), "design-systems/linear-app/DESIGN.md"));
  });
});

describe("PRODUCT_PIPELINE_OD toggle", () => {
  const ENV_KEY = "PRODUCT_PIPELINE_OD";
  let saved: string | undefined;

  beforeEach(() => {
    saved = process.env[ENV_KEY];
  });
  afterEach(() => {
    if (saved === undefined) delete process.env[ENV_KEY];
    else process.env[ENV_KEY] = saved;
  });

  test("odDisabled() reads the env var — off-values disable, others don't", () => {
    for (const v of ["off", "0", "false", "no", "disabled", "OFF", " Off "]) {
      process.env[ENV_KEY] = v;
      expect(odDisabled()).toBe(true);
    }
    for (const v of ["on", "1", "true", "", "yes", "anything"]) {
      process.env[ENV_KEY] = v;
      expect(odDisabled()).toBe(false);
    }
    delete process.env[ENV_KEY];
    expect(odDisabled()).toBe(false); // unset = on (the default)
  });

  test("assertVendorPresent throws OdDisabledError when switched off — even with a complete tree", async () => {
    await stageVendor(tmpRoot);
    process.env[ENV_KEY] = "off";
    expect(() => assertVendorPresent(tmpRoot)).toThrow(OdDisabledError);
  });

  test("loadDsIndex and designSystemPath both fail-loud with OdDisabledError when off", async () => {
    await stageVendor(tmpRoot);
    process.env[ENV_KEY] = "off";
    expect(() => loadDsIndex(tmpRoot)).toThrow(OdDisabledError);
    expect(() => designSystemPath("linear-app", tmpRoot)).toThrow(OdDisabledError);
  });

  test("OdDisabledError is a VendorMissingError subclass with code 'od-disabled'", () => {
    const e = new OdDisabledError();
    // subclass relationship is what lets tools.ts catch it with no extra wiring
    expect(e).toBeInstanceOf(VendorMissingError);
    expect(e.code).toBe("od-disabled");
    expect(e.missing).toEqual([]);
    expect(e.message).toMatch(/PRODUCT_PIPELINE_OD/);
  });

  test("unset env var leaves OD on — normal resolution still works", async () => {
    delete process.env[ENV_KEY];
    await stageVendor(tmpRoot);
    expect(() => assertVendorPresent(tmpRoot)).not.toThrow();
    expect(loadDsIndex(tmpRoot).count).toBe(2);
  });
});
