import type { Locale } from "./locales";
import { REPO_URL, REPO_TREE } from "./locales";

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

const PIPELINE_PKG = "packages/mcp-product-pipeline";

export const MCPS: Mcp[] = [
  {
    id: "product-pipeline",
    name: "Product Pipeline",
    status: "live",
    toolCount: 8,
    packagePath: PIPELINE_PKG,
    readme: `${REPO_TREE}/${PIPELINE_PKG}/README.md`,
    spec: "025/026/027",
    summary: {
      en: "A 12-step product-planning pipeline — from raw idea to engineering-ready spec.",
      pt: "Pipeline de 12 passos para planejar produto — da ideia crua à spec pronta para engenharia.",
      es: "Pipeline de 12 pasos para planificación de producto — de la idea cruda a una spec lista para ingeniería.",
    },
    desc: {
      en: "Lifts Discovery (ideation → prototype → spec → UX testing), Identity (brand → design system → branded prototype), and Specification (PRD → system design → cost → roadmap → legal) into 8 MCP tools. The MCP owns the state machine; your session is the interlocutor. Half of the steps are fully delegable to a sub-agent. Plug-and-play via `.mcp.json` — no hook, no rule, no CLAUDE.md change. When the pipeline closes, the literal `/sdd new <slug>` handoff drops you into Agent0's engineering workflow. Open Design vendor bundle grounds visual directions in real systems (Linear, Vercel, Notion, …).",
      pt: "Eleva Discovery (ideação → protótipo → spec → testes UX), Identity (marca → design system → protótipo brandado) e Specification (PRD → arquitetura → custo → roadmap → legal) em 8 tools MCP. O MCP detém a state machine; sua sessão é o interlocutor. Metade dos passos é totalmente delegável a sub-agente. Plug-and-play via `.mcp.json` — sem hook, sem regra, sem mudança no CLAUDE.md. Quando o pipeline fecha, o handoff literal `/sdd new <slug>` te leva para o workflow de engenharia do Agent0. Bundle vendored Open Design ancora direções visuais em sistemas reais (Linear, Vercel, Notion, …).",
      es: "Eleva Discovery (ideación → prototipo → spec → tests UX), Identity (marca → design system → prototipo branded) y Specification (PRD → diseño de sistema → costo → roadmap → legal) a 8 tools MCP. El MCP posee la state machine; tu sesión es el interlocutor. La mitad de los pasos es totalmente delegable a un sub-agente. Plug-and-play vía `.mcp.json` — sin hook, sin regla, sin tocar CLAUDE.md. Al cerrar el pipeline, el handoff literal `/sdd new <slug>` te lleva al workflow de ingeniería de Agent0. El bundle vendored Open Design ancla las direcciones visuales en sistemas reales (Linear, Vercel, Notion, …).",
    },
  },
];

export const STATUS_LABELS: Record<McpStatus, Record<Locale, string>> = {
  live: { en: "Live", pt: "Ativo", es: "Activo" },
  "in-progress": { en: "In progress", pt: "Em curso", es: "En curso" },
  planned: { en: "Planned", pt: "Planejado", es: "Planeado" },
};

export { REPO_URL };
