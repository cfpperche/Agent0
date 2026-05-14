#!/usr/bin/env bun
/**
 * Agent0 product-pipeline MCP server — stdio transport.
 *
 * Owns the 12-step product-planning pipeline (Discovery + Identity +
 * Specification). Activated per-fork by uncommenting the
 * "product-pipeline" block in .mcp.json (copy from .mcp.json.example).
 *
 * Spec: docs/specs/025-mcp-product-pipeline/. Tool surface defined in
 * tools.ts (10 tools: product_status, product_start, product_step_get,
 * product_step_submit, product_advance, product_gate_pass, product_done,
 * product_get_delegation_brief, plus the Open Design vendor tools
 * product_design_systems_index + product_design_system_path — spec 027).
 * registerAllTools(server) wires the full surface.
 */

import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import { registerAllTools } from "./tools.js";

const server = new McpServer(
  {
    name: "agent0-product-pipeline",
    version: "0.1.0",
  },
  {
    capabilities: {
      tools: {},
    },
  },
);

registerAllTools(server);

async function main(): Promise<void> {
  const transport = new StdioServerTransport();
  await server.connect(transport);
}

main().catch((err: unknown) => {
  // MCP stdio servers must write diagnostics to stderr — stdout is the
  // transport channel and any noise on it corrupts the JSON-RPC framing.
  process.stderr.write(`agent0-product-pipeline: fatal: ${String(err)}\n`);
  process.exit(1);
});
