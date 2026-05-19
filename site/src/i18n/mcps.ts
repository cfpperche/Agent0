import type { Locale } from "./locales";
import { REPO_URL } from "./locales";

export type McpStatus = "live" | "in-progress" | "planned";

export type Mcp = {
  id: string;
  name: string;
  status: McpStatus;
  toolCount: number;
  packagePath: string;
  readme: string;
  spec?: string;
  summary: Record<Locale, string>;
  desc: Record<Locale, string>;
};

export const MCPS: Mcp[] = [];

export const STATUS_LABELS: Record<McpStatus, Record<Locale, string>> = {
  live: { en: "Live", pt: "Ativo", es: "Activo" },
  "in-progress": { en: "In progress", pt: "Em curso", es: "En curso" },
  planned: { en: "Planned", pt: "Planejado", es: "Planeado" },
};

export { REPO_URL };
