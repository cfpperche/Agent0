import type { Locale } from "./locales";
import { REPO_TREE } from "./locales";

export type Capacity = {
  id: string;
  name: string;
  ruleDoc: string;
  spec?: string;
  desc: Record<Locale, string>;
};

export const CAPACITIES: Capacity[] = [
  {
    id: "sdd",
    name: "Spec-driven development",
    ruleDoc: `${REPO_TREE}/.claude/rules/spec-driven.md`,
    desc: {
      en: "Intent before code. Every non-trivial change starts with spec.md, plan.md, tasks.md under docs/specs/NNN-slug/. The /sdd skill scaffolds and progresses them.",
      pt: "Intenção antes do código. Toda mudança não-trivial começa com spec.md, plan.md, tasks.md em docs/specs/NNN-slug/. A skill /sdd faz o scaffold e progressão.",
      es: "Intención antes que código. Todo cambio no-trivial empieza con spec.md, plan.md, tasks.md en docs/specs/NNN-slug/. La skill /sdd los crea y los hace avanzar.",
    },
  },
  {
    id: "governance",
    name: "Governance gate",
    ruleDoc: `${REPO_TREE}/docs/specs/001-governance-gate/spec.md`,
    spec: "001",
    desc: {
      en: "PreToolUse(Bash) blocks destructive ops, hook bypass, and blanket staging. Override marker `# OVERRIDE: <reason ≥10 chars>` records intent in the audit log.",
      pt: "PreToolUse(Bash) bloqueia operações destrutivas, bypass de hooks e staging cego. Marcador `# OVERRIDE: <razão ≥10 chars>` registra intenção no log de auditoria.",
      es: "PreToolUse(Bash) bloquea operaciones destructivas, bypass de hooks y staging ciego. El marcador `# OVERRIDE: <razón ≥10 chars>` registra la intención en el log.",
    },
  },
  {
    id: "delegation",
    name: "Delegation + post-edit validator",
    ruleDoc: `${REPO_TREE}/.claude/rules/delegation.md`,
    spec: "002",
    desc: {
      en: "Every Agent dispatch requires a 5-field brief (TASK / CONTEXT / CONSTRAINTS / DELIVERABLE-or-DONE_WHEN). Sub-agent edits revalidated in a fix-then-retry loop, capped by a budget.",
      pt: "Todo dispatch do Agent exige briefing de 5 campos (TASK / CONTEXT / CONSTRAINTS / DELIVERABLE-or-DONE_WHEN). Edições de sub-agentes são re-validadas em loop fix-then-retry com orçamento.",
      es: "Todo despacho del Agent requiere un brief de 5 campos (TASK / CONTEXT / CONSTRAINTS / DELIVERABLE-or-DONE_WHEN). Las ediciones de sub-agentes se re-validan en bucle fix-then-retry con presupuesto.",
    },
  },
  {
    id: "reminders",
    name: "Reminders",
    ruleDoc: `${REPO_TREE}/.claude/rules/reminders.md`,
    spec: "003",
    desc: {
      en: "/remind add/list/dismiss writes .claude/REMINDERS.md — deferred intent that auto-reads at every SessionStart. Sits between SESSION.md (WIP) and memory (knowledge).",
      pt: "/remind add/list/dismiss escreve em .claude/REMINDERS.md — intenções adiadas, lidas automaticamente em todo SessionStart. Fica entre SESSION.md (WIP) e memória (conhecimento).",
      es: "/remind add/list/dismiss escribe en .claude/REMINDERS.md — intenciones diferidas, leídas automáticamente en cada SessionStart. Está entre SESSION.md (WIP) y memoria (conocimiento).",
    },
  },
  {
    id: "bdd",
    name: "BDD acceptance scenarios",
    ruleDoc: `${REPO_TREE}/.claude/rules/spec-driven.md#acceptance-scenarios`,
    spec: "004",
    desc: {
      en: "spec.md acceptance criteria use Given/When/Then prose. A sub-agent reading a scenario can construct the verification without follow-up clarification.",
      pt: "Critérios de aceite no spec.md usam prosa Given/When/Then. Um sub-agente lendo um cenário consegue construir a verificação sem clarificação extra.",
      es: "Los criterios de aceptación en spec.md usan prosa Given/When/Then. Un sub-agente leyendo un escenario puede construir la verificación sin aclaración extra.",
    },
  },
  {
    id: "tdd",
    name: "TDD working agreement",
    ruleDoc: `${REPO_TREE}/.claude/rules/tdd.md`,
    spec: "005",
    desc: {
      en: "Cultural red→green→refactor. Validator emits non-blocking `tdd-advisory:` when prod files change without tests in the same diff. The advisory surfaces — the agent decides.",
      pt: "Cultura red→green→refactor. Validator emite `tdd-advisory:` não-bloqueante quando código de produção muda sem testes no mesmo diff. A advisory aparece — o agente decide.",
      es: "Cultura red→green→refactor. El validator emite `tdd-advisory:` no-bloqueante cuando código de producción cambia sin tests en el mismo diff. La advisory aparece — el agente decide.",
    },
  },
  {
    id: "secrets-scan",
    name: "Secrets scan",
    ruleDoc: `${REPO_TREE}/.claude/rules/secrets-scan.md`,
    spec: "006/007",
    desc: {
      en: "Two layers: native .githooks/pre-commit runs gitleaks over the staged diff (primary block); PreToolUse(Bash) preflight gates dangerous shapes and bridges override markers via env var.",
      pt: "Duas camadas: .githooks/pre-commit nativo roda gitleaks no diff staged (bloqueio primário); PreToolUse(Bash) faz preflight de shapes perigosos e bridge do marcador override via env var.",
      es: "Dos capas: .githooks/pre-commit nativo ejecuta gitleaks sobre el diff staged (bloqueo primario); PreToolUse(Bash) hace preflight de shapes peligrosos y bridge del marcador override vía env var.",
    },
  },
  {
    id: "runtime-introspect",
    name: "Runtime introspect",
    ruleDoc: `${REPO_TREE}/.claude/rules/runtime-introspect.md`,
    spec: "011/020/022",
    desc: {
      en: "PostToolUse(Bash) captures the latest test/build/typecheck run to .claude/.runtime-state/last-run.json. Agent reads it back via `probe.sh last-run` — closing the edit→verify loop.",
      pt: "PostToolUse(Bash) captura a última execução de test/build/typecheck em .claude/.runtime-state/last-run.json. Agente lê com `probe.sh last-run` — fechando o loop edit→verify.",
      es: "PostToolUse(Bash) captura la última ejecución de test/build/typecheck en .claude/.runtime-state/last-run.json. El agente la lee con `probe.sh last-run` — cerrando el bucle edit→verify.",
    },
  },
  {
    id: "mcp-recipes",
    name: "MCP recipes",
    ruleDoc: `${REPO_TREE}/.claude/rules/mcp-recipes.md`,
    spec: "012/015",
    desc: {
      en: "Opt-in .mcp.json recipes for Playwright, Chrome DevTools, DBHub, and Next.js DevTools. SessionStart hook detects stack (walks monorepo workspace dirs depth-1) and hints applicable recipes.",
      pt: "Recipes opt-in de .mcp.json para Playwright, Chrome DevTools, DBHub e Next.js DevTools. Hook SessionStart detecta stack (anda em workspace dirs de monorepo até profundidade 1) e sugere recipes aplicáveis.",
      es: "Recipes opt-in de .mcp.json para Playwright, Chrome DevTools, DBHub y Next.js DevTools. El hook SessionStart detecta el stack (recorre workspace dirs de monorepo a profundidad 1) y sugiere los recipes aplicables.",
    },
  },
  {
    id: "lint-validator",
    name: "Lint validator extension",
    ruleDoc: `${REPO_TREE}/.claude/rules/lint-validator.md`,
    spec: "013",
    desc: {
      en: "Validator extends to Biome (JS/TS) and Ruff (Python) when the manifest declares them. Three states: installed → runs and gates; declared+missing → actionable advisory; not declared → silent skip.",
      pt: "Validator se estende para Biome (JS/TS) e Ruff (Python) quando o manifesto os declara. Três estados: instalado → roda e bloqueia; declarado+ausente → advisory acionável; não declarado → skip silencioso.",
      es: "El validator se extiende a Biome (JS/TS) y Ruff (Python) cuando el manifiesto los declara. Tres estados: instalado → ejecuta y bloquea; declarado+ausente → advisory accionable; no declarado → skip silencioso.",
    },
  },
  {
    id: "typecheck-advisory",
    name: "Typecheck advisory",
    ruleDoc: `${REPO_TREE}/.claude/rules/typecheck-advisory.md`,
    desc: {
      en: "Validator detects typecheck primitives per JS branch (tsconfig.json on bun/pnpm, `typecheck` script on npm). Missing both → omit the step + emit a non-blocking advisory pointing at the declaration that would re-enable it.",
      pt: "Validator detecta primitivos de typecheck por branch JS (tsconfig.json em bun/pnpm, script `typecheck` em npm). Sem ambos → omite o passo + emite advisory não-bloqueante apontando para a declaração que reativa.",
      es: "El validator detecta primitivos de typecheck por rama JS (tsconfig.json en bun/pnpm, script `typecheck` en npm). Sin ambos → omite el paso + emite advisory no-bloqueante apuntando a la declaración que lo reactivaría.",
    },
  },
  {
    id: "harness-sync",
    name: "Harness sync",
    ruleDoc: `${REPO_TREE}/.claude/rules/harness-sync.md`,
    spec: "016",
    desc: {
      en: "One-way sync tool brings a fork's harness up to date with Agent0. Hash-compare per-file, structured merge for settings.json + CLAUDE.md, never touches src/ or product manifests.",
      pt: "Ferramenta de sync one-way atualiza o harness de um fork com Agent0. Hash-compare por arquivo, merge estruturado para settings.json + CLAUDE.md, nunca toca src/ nem manifestos do produto.",
      es: "Herramienta de sync one-way actualiza el harness de un fork con Agent0. Hash-compare por archivo, merge estructurado para settings.json + CLAUDE.md, nunca toca src/ ni manifiestos de producto.",
    },
  },
  {
    id: "session-handoff",
    name: "Session handoff",
    ruleDoc: `${REPO_TREE}/.claude/rules/session-handoff.md`,
    spec: "017/023",
    desc: {
      en: "SessionStart injects SESSION.md into context. Stop hook nags once per session if you touched the repo without updating SESSION.md. Per-session state isolated; no-op sessions exit silent.",
      pt: "SessionStart injeta SESSION.md no contexto. Stop hook avisa uma vez por sessão se você mexeu no repo sem atualizar SESSION.md. Estado isolado por sessão; sessões no-op saem silenciosas.",
      es: "SessionStart inyecta SESSION.md en el contexto. El hook Stop avisa una vez por sesión si tocaste el repo sin actualizar SESSION.md. Estado aislado por sesión; sesiones no-op salen silenciosas.",
    },
  },
  {
    id: "memory",
    name: "Project memory",
    ruleDoc: `${REPO_TREE}/.claude/rules/memory-placement.md`,
    spec: "019",
    desc: {
      en: "Three buckets: per-user preferences (~/.claude/...), project knowledge (.claude/memory/, git-tracked, fork-local), and behavioral rules (.claude/rules/, ship to forks). Routing guidance prevents drift.",
      pt: "Três buckets: preferências por usuário (~/.claude/...), conhecimento de projeto (.claude/memory/, git-tracked, fork-local) e regras comportamentais (.claude/rules/, vão para forks). Guidance de roteamento evita drift.",
      es: "Tres buckets: preferencias por usuario (~/.claude/...), conocimiento de proyecto (.claude/memory/, git-tracked, fork-local) y reglas de comportamiento (.claude/rules/, viajan a forks). Guía de ruteo evita drift.",
    },
  },
  {
    id: "browser-auth",
    name: "Browser auth workflow",
    ruleDoc: `${REPO_TREE}/.claude/rules/mcp-recipes.md#authenticated-workflow`,
    spec: "021",
    desc: {
      en: "Agent emits `BROWSER_AUTH_REQUIRED: <host>` on 401/403; human logs in via headed Playwright MCP, saves storage state to .claude/.browser-state/<host>.json; agent reuses headlessly.",
      pt: "Agente emite `BROWSER_AUTH_REQUIRED: <host>` em 401/403; humano loga via Playwright MCP headed, salva storage em .claude/.browser-state/<host>.json; agente reusa headless.",
      es: "El agente emite `BROWSER_AUTH_REQUIRED: <host>` en 401/403; humano inicia sesión vía Playwright MCP headed, guarda el storage en .claude/.browser-state/<host>.json; el agente reusa headless.",
    },
  },
];
