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
    ruleDoc: `${REPO_TREE}/.agent0/context/rules/spec-driven.md`,
    desc: {
      en: "Intent before code. Every non-trivial change starts with spec.md, plan.md, tasks.md under docs/specs/NNN-slug/. The /sdd skill scaffolds and progresses them — including a cross-model debate step.",
      pt: "Intenção antes do código. Toda mudança não-trivial começa com spec.md, plan.md, tasks.md em docs/specs/NNN-slug/. A skill /sdd faz scaffold e progressão — incluindo um passo de debate cross-model.",
      es: "Intención antes que código. Todo cambio no-trivial empieza con spec.md, plan.md, tasks.md en docs/specs/NNN-slug/. La skill /sdd los crea y los hace avanzar — incluyendo un paso de debate cross-model.",
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
    ruleDoc: `${REPO_TREE}/.agent0/context/rules/delegation.md`,
    spec: "002",
    desc: {
      en: "Every Agent dispatch requires a 5-field brief (TASK / CONTEXT / CONSTRAINTS / DELIVERABLE-or-DONE_WHEN). Sub-agent edits revalidated in a fix-then-retry loop, capped by a budget.",
      pt: "Todo dispatch do Agent exige briefing de 5 campos (TASK / CONTEXT / CONSTRAINTS / DELIVERABLE-or-DONE_WHEN). Edições de sub-agentes são re-validadas em loop fix-then-retry com orçamento.",
      es: "Todo despacho del Agent requiere un brief de 5 campos (TASK / CONTEXT / CONSTRAINTS / DELIVERABLE-or-DONE_WHEN). Las ediciones de sub-agentes se re-validan en bucle fix-then-retry con presupuesto.",
    },
  },
  {
    id: "user-prompt-framing",
    name: "User prompt framing",
    ruleDoc: `${REPO_TREE}/.agent0/context/rules/user-prompt-framing.md`,
    spec: "035",
    desc: {
      en: "On a non-trivial prompt the agent runs a 3-question mental check (TASK / CONTEXT / DONE clear?) and clarifies before acting when ≥2 are unclear. Rule-only — no hook, pure discipline.",
      pt: "Em um prompt não-trivial o agente roda um check mental de 3 perguntas (TASK / CONTEXT / DONE claros?) e clarifica antes de agir quando ≥2 estão obscuras. Só regra — sem hook, disciplina pura.",
      es: "Ante un prompt no-trivial el agente corre un check mental de 3 preguntas (¿TASK / CONTEXT / DONE claros?) y aclara antes de actuar cuando ≥2 están confusas. Solo regla — sin hook, disciplina pura.",
    },
  },
  {
    id: "reminders",
    name: "Reminders",
    ruleDoc: `${REPO_TREE}/.agent0/context/rules/reminders.md`,
    spec: "003",
    desc: {
      en: "/remind add/list/dismiss writes .agent0/reminders.yaml — deferred intent auto-read at every session start. Sits between the handoff (WIP) and memory (knowledge).",
      pt: "/remind add/list/dismiss escreve em .agent0/reminders.yaml — intenções adiadas, lidas automaticamente no início de cada sessão. Fica entre o handoff (WIP) e a memória (conhecimento).",
      es: "/remind add/list/dismiss escribe en .agent0/reminders.yaml — intenciones diferidas, leídas automáticamente al inicio de cada sesión. Está entre el handoff (WIP) y la memoria (conocimiento).",
    },
  },
  {
    id: "bdd",
    name: "BDD acceptance scenarios",
    ruleDoc: `${REPO_TREE}/.agent0/context/rules/spec-driven.md`,
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
    ruleDoc: `${REPO_TREE}/.agent0/context/rules/tdd.md`,
    spec: "005",
    desc: {
      en: "Cultural red→green→refactor. Validator emits a non-blocking `tdd-advisory:` when prod files change without tests in the same diff. The advisory surfaces — the agent decides.",
      pt: "Cultura red→green→refactor. Validator emite `tdd-advisory:` não-bloqueante quando código de produção muda sem testes no mesmo diff. A advisory aparece — o agente decide.",
      es: "Cultura red→green→refactor. El validator emite `tdd-advisory:` no-bloqueante cuando código de producción cambia sin tests en el mismo diff. La advisory aparece — el agente decide.",
    },
  },
  {
    id: "secrets-scan",
    name: "Secrets scan",
    ruleDoc: `${REPO_TREE}/.agent0/context/rules/secrets-scan.md`,
    spec: "006/007",
    desc: {
      en: "Two layers: native .githooks/pre-commit runs gitleaks over the staged diff (primary block); a runtime-neutral PreToolUse(Bash) preflight gates dangerous commit shapes on Claude Code and Codex CLI.",
      pt: "Duas camadas: .githooks/pre-commit nativo roda gitleaks no diff staged (bloqueio primário); um preflight PreToolUse(Bash) runtime-neutro barra shapes de commit perigosos no Claude Code e no Codex CLI.",
      es: "Dos capas: .githooks/pre-commit nativo ejecuta gitleaks sobre el diff staged (bloqueo primario); un preflight PreToolUse(Bash) runtime-neutral frena shapes de commit peligrosos en Claude Code y Codex CLI.",
    },
  },
  {
    id: "vuln-audit",
    name: "Vuln audit",
    ruleDoc: `${REPO_TREE}/.agent0/context/rules/vuln-audit.md`,
    spec: "120",
    desc: {
      en: "On-demand detector for known-vulnerable installed dependencies (engine: osv-scanner), stack-aware and runtime-neutral. Reports and proposes upgrades; never auto-fixes, never gates install or commit.",
      pt: "Detector on-demand de dependências instaladas com vulnerabilidades conhecidas (engine: osv-scanner), stack-aware e runtime-neutro. Reporta e propõe upgrades; nunca auto-corrige, nunca barra install ou commit.",
      es: "Detector on-demand de dependencias instaladas con vulnerabilidades conocidas (engine: osv-scanner), stack-aware y runtime-neutral. Reporta y propone upgrades; nunca auto-corrige, nunca frena install o commit.",
    },
  },
  {
    id: "lint-validator",
    name: "Lint validator extension",
    ruleDoc: `${REPO_TREE}/.agent0/context/rules/lint-validator.md`,
    spec: "013",
    desc: {
      en: "Post-edit validator runs the project's idiomatic linter — Biome (JS/TS), Ruff (Python), Pint + PHPStan/Larastan (PHP) — when the manifest declares it; missing-but-declared emits a non-blocking advisory.",
      pt: "Validator pós-edição roda o linter idiomático do projeto — Biome (JS/TS), Ruff (Python), Pint + PHPStan/Larastan (PHP) — quando o manifesto declara; ausente-mas-declarado emite advisory não-bloqueante.",
      es: "El validator post-edición ejecuta el linter idiomático del proyecto — Biome (JS/TS), Ruff (Python), Pint + PHPStan/Larastan (PHP) — cuando el manifiesto lo declara; ausente-pero-declarado emite advisory no-bloqueante.",
    },
  },
  {
    id: "typecheck-advisory",
    name: "Typecheck advisory",
    ruleDoc: `${REPO_TREE}/.agent0/context/rules/typecheck-advisory.md`,
    desc: {
      en: "Validator runs a typecheck step only when the project declares the primitive (a tsconfig.json, or a `typecheck` script in package.json); otherwise it emits `typecheck-advisory:` and skips.",
      pt: "Validator roda o passo de typecheck só quando o projeto declara o primitivo (um tsconfig.json, ou script `typecheck` no package.json); senão emite `typecheck-advisory:` e pula.",
      es: "El validator corre el paso de typecheck solo cuando el proyecto declara el primitivo (un tsconfig.json, o un script `typecheck` en package.json); si no, emite `typecheck-advisory:` y lo omite.",
    },
  },
  {
    id: "mcp-recipes",
    name: "MCP recipes",
    ruleDoc: `${REPO_TREE}/.mcp.json.example`,
    spec: "012/015",
    desc: {
      en: "Copy-paste MCP server blocks (Playwright, Chrome DevTools, DBHub, Laravel Boost, Next.js DevTools, fal.ai) ship as templates for both runtimes — .mcp.json.example for Claude Code, .codex/config.toml.example for Codex. Disabled by default, env-var indirection for secrets.",
      pt: "Blocos de servidor MCP copy-paste (Playwright, Chrome DevTools, DBHub, Laravel Boost, Next.js DevTools, fal.ai) vêm como templates para os dois runtimes — .mcp.json.example para Claude Code, .codex/config.toml.example para Codex. Desativados por padrão, indireção via env-var para segredos.",
      es: "Bloques de servidor MCP copy-paste (Playwright, Chrome DevTools, DBHub, Laravel Boost, Next.js DevTools, fal.ai) vienen como templates para ambos runtimes — .mcp.json.example para Claude Code, .codex/config.toml.example para Codex. Desactivados por defecto, indirección vía env-var para secretos.",
    },
  },
  {
    id: "image-gen",
    name: "Image generation",
    ruleDoc: `${REPO_TREE}/.agent0/context/rules/image-gen.md`,
    spec: "085",
    desc: {
      en: "Opt-in AI image generation via fal.ai — the /image skill produces draft mockups and brand assets across three cost tiers with a mandatory --tier flag, pre-call cost printing, and a JSONL manifest of every call.",
      pt: "Geração de imagens IA opt-in via fal.ai — a skill /image produz mockups draft e brand assets em três tiers de custo com flag --tier obrigatória, impressão de custo antes da chamada e um manifesto JSONL de cada chamada.",
      es: "Generación de imágenes IA opt-in vía fal.ai — la skill /image produce mockups draft y brand assets en tres tiers de costo con flag --tier obligatoria, impresión de costo antes de la llamada y un manifiesto JSONL de cada llamada.",
    },
  },
  {
    id: "harness-sync",
    name: "Harness sync",
    ruleDoc: `${REPO_TREE}/.agent0/context/rules/harness-sync.md`,
    spec: "016",
    desc: {
      en: "Sync tool brings a fork's harness up to date with Agent0 via 3-way baseline reconciliation. Stale files auto-update, consumer-customized files refuse without --force, never touches product code.",
      pt: "Ferramenta de sync atualiza o harness de um fork com Agent0 via reconciliação 3-way contra um baseline. Arquivos stale atualizam sozinhos, arquivos customizados recusam sem --force, nunca toca código de produto.",
      es: "La herramienta de sync actualiza el harness de un fork con Agent0 vía reconciliación 3-way contra un baseline. Archivos stale se actualizan solos, archivos personalizados rechazan sin --force, nunca toca código de producto.",
    },
  },
  {
    id: "session-handoff",
    name: "Session handoff",
    ruleDoc: `${REPO_TREE}/.agent0/context/rules/session-handoff.md`,
    spec: "017/023",
    desc: {
      en: ".agent0/HANDOFF.md is the runtime-neutral handoff (Current State / Active Work / Next Actions / Decisions). Claude Code injects + nags through hooks; Codex receives the same handoff via tracked .codex/hooks.json.",
      pt: ".agent0/HANDOFF.md é o handoff runtime-neutro (Current State / Active Work / Next Actions / Decisions). Claude Code injeta + cobra via hooks; Codex recebe o mesmo handoff via .codex/hooks.json versionado.",
      es: ".agent0/HANDOFF.md es el handoff runtime-neutral (Current State / Active Work / Next Actions / Decisions). Claude Code inyecta + recuerda vía hooks; Codex recibe el mismo handoff vía .codex/hooks.json versionado.",
    },
  },
  {
    id: "memory",
    name: "Project memory",
    ruleDoc: `${REPO_TREE}/.agent0/context/rules/memory-placement.md`,
    spec: "019",
    desc: {
      en: "Factual project knowledge lives in .agent0/memory/<topic>.md with a trigger-read index (MEMORY.md). Git-tracked for the project, not shipped to forks; routing guidance keeps it from drifting into rules.",
      pt: "Conhecimento factual do projeto vive em .agent0/memory/<topic>.md com um índice de leitura-por-gatilho (MEMORY.md). Versionado no projeto, não enviado a forks; o roteamento evita drift para dentro das regras.",
      es: "El conocimiento factual del proyecto vive en .agent0/memory/<topic>.md con un índice de lectura-por-disparador (MEMORY.md). Versionado en el proyecto, no enviado a forks; el ruteo evita drift hacia las reglas.",
    },
  },
  {
    id: "browser-auth",
    name: "Browser auth workflow",
    ruleDoc: `${REPO_TREE}/.agent0/context/rules/browser-auth.md`,
    spec: "021",
    desc: {
      en: "Agent emits `BROWSER_AUTH_REQUIRED: <host>` on an auth-gated URL; the human logs in via a headed Playwright MCP session and the saved state (.agent0/.browser-state/<host>.json) is reused for headless reads.",
      pt: "Agente emite `BROWSER_AUTH_REQUIRED: <host>` em URL com auth; o humano loga via sessão Playwright MCP headed e o estado salvo (.agent0/.browser-state/<host>.json) é reusado para leituras headless.",
      es: "El agente emite `BROWSER_AUTH_REQUIRED: <host>` en una URL con auth; el humano inicia sesión vía sesión Playwright MCP headed y el estado guardado (.agent0/.browser-state/<host>.json) se reusa para lecturas headless.",
    },
  },
  {
    id: "skill-compliance",
    name: "Skill compliance",
    ruleDoc: `${REPO_TREE}/.agent0/skills/skill/SKILL.md`,
    spec: "033",
    desc: {
      en: "Every first-party skill must pass the agentskills.io frontmatter spec; the /skill meta-skill scaffolds, audits, ports, and validates them across three declared portability tiers.",
      pt: "Toda skill first-party precisa passar no spec de frontmatter da agentskills.io; a meta-skill /skill faz scaffold, auditoria, porte e validação em três tiers de portabilidade declarados.",
      es: "Toda skill first-party debe pasar el spec de frontmatter de agentskills.io; la meta-skill /skill hace scaffold, auditoría, port y validación en tres tiers de portabilidad declarados.",
    },
  },
  {
    id: "product",
    name: "Product skill",
    ruleDoc: `${REPO_TREE}/.claude/skills/product/SKILL.md`,
    spec: "048",
    desc: {
      en: "/product is the foundation generator + design partner for the product lifecycle (idea → v1 → vN): a multi-step pipeline producing the planning artifacts + a visual contract that hands off to SDD.",
      pt: "/product é o gerador de fundação + parceiro de design para o ciclo do produto (ideia → v1 → vN): um pipeline multi-step que produz os artefatos de planejamento + um contrato visual que faz handoff para o SDD.",
      es: "/product es el generador de fundación + socio de diseño para el ciclo del producto (idea → v1 → vN): un pipeline multi-paso que produce los artefactos de planificación + un contrato visual que hace handoff al SDD.",
    },
  },
  {
    id: "routines",
    name: "Routines",
    ruleDoc: `${REPO_TREE}/.agent0/context/rules/routines.md`,
    spec: "064",
    desc: {
      en: ".agent0/routines/<slug>.md git-tracks recurring project work; an opt-in leader machine's cron enqueues each run for the next interactive session to dispatch via /routine run <slug>.",
      pt: ".agent0/routines/<slug>.md versiona trabalho recorrente do projeto; o cron de uma máquina líder opt-in enfileira cada run para a próxima sessão interativa despachar via /routine run <slug>.",
      es: ".agent0/routines/<slug>.md versiona trabajo recurrente del proyecto; el cron de una máquina líder opt-in encola cada run para que la próxima sesión interactiva lo despache vía /routine run <slug>.",
    },
  },
  {
    id: "artifact-size-cap",
    name: "Artifact size cap",
    ruleDoc: `${REPO_TREE}/.agent0/context/rules/artifact-budgets.md`,
    spec: "065",
    desc: {
      en: "Size is not a quality signal — scope and quality are judged by the /product quality judge. The only size mechanism is a uniform 200 KB catastrophe cap (a token-runaway circuit-breaker) plus per-step anti-stub floors.",
      pt: "Tamanho não é sinal de qualidade — escopo e qualidade são julgados pelo quality judge do /product. O único mecanismo de tamanho é um cap uniforme de 200 KB (circuit-breaker de runaway de tokens) mais pisos anti-stub por passo.",
      es: "El tamaño no es señal de calidad — alcance y calidad los juzga el quality judge de /product. El único mecanismo de tamaño es un cap uniforme de 200 KB (circuit-breaker de runaway de tokens) más pisos anti-stub por paso.",
    },
  },
  {
    id: "runtime-capabilities",
    name: "Runtime capabilities matrix",
    ruleDoc: `${REPO_TREE}/.agent0/context/rules/runtime-capabilities.md`,
    spec: "093",
    desc: {
      en: "A provider-neutral matrix of Agent0 capability support across Claude Code, Codex CLI, and future runtimes — consulted before assuming a .claude/* capability is native in another runtime.",
      pt: "Uma matriz provider-neutra do suporte das capacidades do Agent0 entre Claude Code, Codex CLI e runtimes futuros — consultada antes de assumir que uma capacidade .claude/* é nativa em outro runtime.",
      es: "Una matriz provider-neutral del soporte de las capacidades de Agent0 entre Claude Code, Codex CLI y runtimes futuros — consultada antes de asumir que una capacidad .claude/* es nativa en otro runtime.",
    },
  },
  {
    id: "runtime-entrypoints",
    name: "Multi-runtime entrypoints",
    ruleDoc: `${REPO_TREE}/AGENTS.md`,
    desc: {
      en: "CLAUDE.md is the Claude Code entrypoint; AGENTS.md is the Codex entrypoint. A shared managed index keeps both in sync; consumer customization lands in AGENTS.override.md or nested AGENTS.md.",
      pt: "CLAUDE.md é o entrypoint do Claude Code; AGENTS.md é o entrypoint do Codex. Um índice gerenciado compartilhado mantém os dois em sincronia; customização do consumidor vai em AGENTS.override.md ou AGENTS.md aninhado.",
      es: "CLAUDE.md es el entrypoint de Claude Code; AGENTS.md es el entrypoint de Codex. Un índice gestionado compartido mantiene ambos en sincronía; la personalización del consumidor va en AGENTS.override.md o AGENTS.md anidado.",
    },
  },
];
