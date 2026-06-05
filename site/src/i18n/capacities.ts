import type { Locale } from "./locales";
import { REPO_TREE } from "./locales";

// Runtime status vocabulary — mirrors .agent0/context/rules/runtime-capabilities.md.
// Keep these values in sync with that matrix; the currency check validates sourcePath,
// the page copy renders these statuses.
export type RuntimeStatus =
  | "native"
  | "native-opt-in"
  | "convention"
  | "read-only"
  | "planned"
  | "unsupported";

export type ThemeId =
  | "safety-gates"
  | "spec-workflow"
  | "quality-validators"
  | "runtime-session"
  | "skills-tooling";

export type Theme = {
  id: ThemeId;
  name: Record<Locale, string>;
  blurb: Record<Locale, string>;
};

// Grouped-by-theme IA (spec 127 resolved gate). Each capacity declares one primary theme.
export const THEMES: Theme[] = [
  {
    id: "spec-workflow",
    name: { en: "Spec workflow", pt: "Workflow spec", es: "Workflow spec" },
    blurb: {
      en: "Intent before code: how a change goes from a spec to merged, with the discipline that keeps the agent on contract.",
      pt: "Intenção antes do código: como uma mudança vai do spec ao merge, com a disciplina que mantém o agente no contrato.",
      es: "Intención antes que código: cómo un cambio va del spec al merge, con la disciplina que mantiene al agente en contrato.",
    },
  },
  {
    id: "safety-gates",
    name: { en: "Safety gates", pt: "Gates de segurança", es: "Gates de seguridad" },
    blurb: {
      en: "The hooks that block a destructive command, a leaked secret, or a known-vulnerable dependency before it lands.",
      pt: "Os hooks que bloqueiam um comando destrutivo, um segredo vazado ou uma dependência vulnerável antes que aconteça.",
      es: "Los hooks que bloquean un comando destructivo, un secreto filtrado o una dependencia vulnerable antes de que ocurra.",
    },
  },
  {
    id: "quality-validators",
    name: { en: "Quality validators", pt: "Validators de qualidade", es: "Validators de calidad" },
    blurb: {
      en: "Post-edit checks that run the project's own linter/typechecker and keep artifacts from bloating — advisory where it should be.",
      pt: "Checks pós-edição que rodam o linter/typechecker do próprio projeto e evitam inchaço de artefatos — advisory onde deve ser.",
      es: "Checks post-edición que ejecutan el linter/typechecker del propio proyecto y evitan el inflado de artefactos — advisory donde corresponde.",
    },
  },
  {
    id: "runtime-session",
    name: { en: "Runtime & session", pt: "Runtime & sessão", es: "Runtime & sesión" },
    blurb: {
      en: "What survives across sessions and across runtimes: handoff, memory, reminders, the capability matrix, and the multi-runtime entrypoints.",
      pt: "O que sobrevive entre sessões e entre runtimes: handoff, memória, reminders, a matriz de capacidades e os entrypoints multi-runtime.",
      es: "Lo que sobrevive entre sesiones y entre runtimes: handoff, memoria, reminders, la matriz de capacidades y los entrypoints multi-runtime.",
    },
  },
  {
    id: "skills-tooling",
    name: { en: "Skills & tooling", pt: "Skills & ferramentas", es: "Skills & herramientas" },
    blurb: {
      en: "The opt-in surfaces: skills, the product pipeline, routines, image generation, MCP recipes, and the one-way harness sync.",
      pt: "As superfícies opt-in: skills, o pipeline de produto, routines, geração de imagem, recipes de MCP e o sync one-way do harness.",
      es: "Las superficies opt-in: skills, el pipeline de producto, routines, generación de imagen, recipes de MCP y el sync one-way del harness.",
    },
  },
];

export type Capacity = {
  id: string;
  slug: string;
  theme: ThemeId;
  name: string;
  // Primary current source-of-truth, repo-relative. The currency check asserts it exists on disk.
  sourcePath: string;
  // Optional early/originating spec — rendered ONLY as a labeled "history" link, never the primary current target.
  historySpec?: string;
  // Per-runtime status, sourced from .agent0/context/rules/runtime-capabilities.md.
  runtime: {
    claude: RuntimeStatus;
    codex: RuntimeStatus;
    note?: Record<Locale, string>;
  };
  desc: Record<Locale, string>;
};

// Convenience: build the GitHub tree URL for a repo-relative source path.
export const sourceUrl = (p: string): string => `${REPO_TREE}/${p}`;

export const CAPACITIES: Capacity[] = [
  {
    id: "sdd",
    slug: "spec-driven-development",
    theme: "spec-workflow",
    name: "Spec-driven development",
    sourcePath: ".agent0/context/rules/spec-driven.md",
    runtime: {
      claude: "native",
      codex: "convention",
      note: {
        en: "Claude runs the /sdd skill; Codex follows the spec artifacts manually (slash-command execution isn't Codex-native).",
        pt: "Claude roda a skill /sdd; Codex segue os artefatos do spec manualmente (execução de slash-command não é nativa no Codex).",
        es: "Claude corre la skill /sdd; Codex sigue los artefactos del spec manualmente (la ejecución de slash-command no es nativa en Codex).",
      },
    },
    desc: {
      en: "Intent before code. Every non-trivial change starts with spec.md, plan.md, tasks.md under docs/specs/NNN-slug/. The /sdd skill scaffolds and progresses them — including a cross-model debate step.",
      pt: "Intenção antes do código. Toda mudança não-trivial começa com spec.md, plan.md, tasks.md em docs/specs/NNN-slug/. A skill /sdd faz scaffold e progressão — incluindo um passo de debate cross-model.",
      es: "Intención antes que código. Todo cambio no-trivial empieza con spec.md, plan.md, tasks.md en docs/specs/NNN-slug/. La skill /sdd los crea y los hace avanzar — incluyendo un paso de debate cross-model.",
    },
  },
  {
    id: "debate",
    slug: "cross-model-debate",
    theme: "spec-workflow",
    name: "Cross-model debate",
    sourcePath: ".agent0/skills/sdd/templates/debate.md.tmpl",
    runtime: {
      claude: "native",
      codex: "planned",
      note: {
        en: "Human-brokered direct-file debate works TODAY across Claude Code and Codex CLI (this site's specs used it); the automated runner is planned (091-sdd-debate-runner).",
        pt: "O debate humano-brokered por arquivo funciona HOJE entre Claude Code e Codex CLI (os specs deste site usaram); o runner automático é planejado (091-sdd-debate-runner).",
        es: "El debate humano-brokered por archivo funciona HOY entre Claude Code y Codex CLI (los specs de este sitio lo usaron); el runner automático es planeado (091-sdd-debate-runner).",
      },
    },
    desc: {
      en: "Two runtimes review a spec in separate sessions, writing to one debate.md — productive disagreement before plan.md locks. Each agent derives its role from its own runtime identity.",
      pt: "Dois runtimes revisam um spec em sessões separadas, escrevendo num único debate.md — desacordo produtivo antes do plan.md travar. Cada agente deriva seu papel da própria identidade de runtime.",
      es: "Dos runtimes revisan un spec en sesiones separadas, escribiendo en un único debate.md — desacuerdo productivo antes de que plan.md se fije. Cada agente deriva su rol de su propia identidad de runtime.",
    },
  },
  {
    id: "delegation",
    slug: "delegation-and-subagents",
    theme: "spec-workflow",
    name: "Delegation + post-edit validator",
    sourcePath: ".agent0/context/rules/delegation.md",
    historySpec: "002",
    runtime: {
      claude: "native",
      codex: "native",
      note: {
        en: "Claude's Agent tool blocks under-specified dispatch (a pre-dispatch gate). Codex has native subagents + SubagentStop verification, but NO pre-dispatch blocking hook exists, so the 5-field brief is convention-only there (spec 106).",
        pt: "A tool Agent do Claude bloqueia dispatch sub-especificado (gate pré-dispatch). Codex tem subagentes nativos + verificação no SubagentStop, mas NÃO existe hook de bloqueio pré-dispatch, então o briefing de 5 campos é convention-only lá (spec 106).",
        es: "La tool Agent de Claude bloquea dispatch sub-especificado (gate pre-dispatch). Codex tiene subagentes nativos + verificación en SubagentStop, pero NO existe hook de bloqueo pre-dispatch, así que el brief de 5 campos es convention-only ahí (spec 106).",
      },
    },
    desc: {
      en: "Every Agent dispatch requires a 5-field brief (TASK / CONTEXT / CONSTRAINTS / DELIVERABLE-or-DONE_WHEN). Sub-agent edits revalidated in a fix-then-retry loop, capped by a budget.",
      pt: "Todo dispatch do Agent exige briefing de 5 campos (TASK / CONTEXT / CONSTRAINTS / DELIVERABLE-or-DONE_WHEN). Edições de sub-agentes são re-validadas em loop fix-then-retry com orçamento.",
      es: "Todo despacho del Agent requiere un brief de 5 campos (TASK / CONTEXT / CONSTRAINTS / DELIVERABLE-or-DONE_WHEN). Las ediciones de sub-agentes se re-validan en bucle fix-then-retry con presupuesto.",
    },
  },
  {
    id: "user-prompt-framing",
    slug: "user-prompt-framing",
    theme: "spec-workflow",
    name: "User prompt framing",
    sourcePath: ".agent0/context/rules/user-prompt-framing.md",
    historySpec: "035",
    runtime: {
      claude: "convention",
      codex: "convention",
      note: {
        en: "Rule-only — no hook on either runtime; the agent self-applies the 3-question check.",
        pt: "Só regra — sem hook em nenhum runtime; o agente auto-aplica o check de 3 perguntas.",
        es: "Solo regla — sin hook en ningún runtime; el agente auto-aplica el check de 3 preguntas.",
      },
    },
    desc: {
      en: "On a non-trivial prompt the agent runs a 3-question mental check (TASK / CONTEXT / DONE clear?) and clarifies before acting when ≥2 are unclear.",
      pt: "Em um prompt não-trivial o agente roda um check mental de 3 perguntas (TASK / CONTEXT / DONE claros?) e clarifica antes de agir quando ≥2 estão obscuras.",
      es: "Ante un prompt no-trivial el agente corre un check mental de 3 preguntas (¿TASK / CONTEXT / DONE claros?) y aclara antes de actuar cuando ≥2 están confusas.",
    },
  },
  {
    id: "bdd",
    slug: "bdd-acceptance-scenarios",
    theme: "spec-workflow",
    name: "BDD acceptance scenarios",
    sourcePath: ".agent0/context/rules/spec-driven.md",
    runtime: {
      claude: "convention",
      codex: "convention",
    },
    desc: {
      en: "spec.md acceptance criteria use Given/When/Then prose. A sub-agent reading a scenario can construct the verification without follow-up clarification.",
      pt: "Critérios de aceite no spec.md usam prosa Given/When/Then. Um sub-agente lendo um cenário consegue construir a verificação sem clarificação extra.",
      es: "Los criterios de aceptación en spec.md usan prosa Given/When/Then. Un sub-agente leyendo un escenario puede construir la verificación sin aclaración extra.",
    },
  },
  {
    id: "tdd",
    slug: "tdd-working-agreement",
    theme: "spec-workflow",
    name: "TDD working agreement",
    sourcePath: ".agent0/context/rules/tdd.md",
    runtime: {
      claude: "convention",
      codex: "convention",
      note: {
        en: "Cultural discipline + a non-blocking validator advisory; not a hard gate on either runtime.",
        pt: "Disciplina cultural + uma advisory não-bloqueante do validator; não é gate duro em nenhum runtime.",
        es: "Disciplina cultural + una advisory no-bloqueante del validator; no es gate duro en ningún runtime.",
      },
    },
    desc: {
      en: "Cultural red→green→refactor. The validator emits a non-blocking `tdd-advisory:` when prod files change without tests in the same diff. The advisory surfaces — the agent decides.",
      pt: "Cultura red→green→refactor. O validator emite `tdd-advisory:` não-bloqueante quando código de produção muda sem testes no mesmo diff. A advisory aparece — o agente decide.",
      es: "Cultura red→green→refactor. El validator emite `tdd-advisory:` no-bloqueante cuando código de producción cambia sin tests en el mismo diff. La advisory aparece — el agente decide.",
    },
  },
  {
    id: "governance",
    slug: "governance-gate",
    theme: "safety-gates",
    name: "Governance gate",
    sourcePath: ".agent0/context/rules/secrets-scan.md",
    historySpec: "001",
    runtime: {
      claude: "native",
      codex: "native",
      note: {
        en: "PreToolUse(Bash) exists on both runtimes; the destructive-op / hook-bypass / blanket-staging floor is enforced via the runtime-neutral preflight.",
        pt: "PreToolUse(Bash) existe nos dois runtimes; o piso de op-destrutiva / bypass-de-hook / staging-cego é aplicado via preflight runtime-neutro.",
        es: "PreToolUse(Bash) existe en ambos runtimes; el piso de op-destructiva / bypass-de-hook / staging-ciego se aplica vía preflight runtime-neutral.",
      },
    },
    desc: {
      en: "PreToolUse(Bash) blocks destructive ops, hook bypass, and blanket staging. Override marker `# OVERRIDE: <reason ≥10 chars>` records intent in the audit log.",
      pt: "PreToolUse(Bash) bloqueia operações destrutivas, bypass de hooks e staging cego. Marcador `# OVERRIDE: <razão ≥10 chars>` registra intenção no log de auditoria.",
      es: "PreToolUse(Bash) bloquea operaciones destructivas, bypass de hooks y staging ciego. El marcador `# OVERRIDE: <razón ≥10 chars>` registra la intención en el log.",
    },
  },
  {
    id: "secrets-scan",
    slug: "secrets-scan",
    theme: "safety-gates",
    name: "Secrets scan",
    sourcePath: ".agent0/context/rules/secrets-scan.md",
    historySpec: "006",
    runtime: {
      claude: "native",
      codex: "native",
      note: {
        en: "The native .githooks/pre-commit (gitleaks) is runtime-agnostic; the PreToolUse(Bash) preflight gates dangerous commit shapes on both Claude Code and Codex CLI.",
        pt: "O .githooks/pre-commit nativo (gitleaks) é runtime-agnóstico; o preflight PreToolUse(Bash) barra shapes de commit perigosos no Claude Code e no Codex CLI.",
        es: "El .githooks/pre-commit nativo (gitleaks) es runtime-agnóstico; el preflight PreToolUse(Bash) frena shapes de commit peligrosos en Claude Code y Codex CLI.",
      },
    },
    desc: {
      en: "Two layers: native .githooks/pre-commit runs gitleaks over the staged diff (primary block); a runtime-neutral PreToolUse(Bash) preflight gates dangerous commit shapes.",
      pt: "Duas camadas: .githooks/pre-commit nativo roda gitleaks no diff staged (bloqueio primário); um preflight PreToolUse(Bash) runtime-neutro barra shapes de commit perigosos.",
      es: "Dos capas: .githooks/pre-commit nativo ejecuta gitleaks sobre el diff staged (bloqueo primario); un preflight PreToolUse(Bash) runtime-neutral frena shapes de commit peligrosos.",
    },
  },
  {
    id: "vuln-audit",
    slug: "vuln-audit",
    theme: "safety-gates",
    name: "Vuln audit",
    sourcePath: ".agent0/context/rules/vuln-audit.md",
    historySpec: "120",
    runtime: {
      claude: "native",
      codex: "native-opt-in",
      note: {
        en: "Claude has the /vuln-audit slash skill; Codex runs the runtime-neutral tool directly. Needs the osv-scanner binary + jq; engine-absent fails open (advisory, exit 0).",
        pt: "Claude tem a skill /vuln-audit; Codex roda a ferramenta runtime-neutra direto. Precisa do binário osv-scanner + jq; engine ausente falha-aberto (advisory, exit 0).",
        es: "Claude tiene la skill /vuln-audit; Codex corre la herramienta runtime-neutral directo. Necesita el binario osv-scanner + jq; engine ausente falla-abierto (advisory, exit 0).",
      },
    },
    desc: {
      en: "On-demand detector for known-vulnerable installed dependencies (engine: osv-scanner), stack-aware. Reports and proposes upgrades; never auto-fixes, never gates install or commit.",
      pt: "Detector on-demand de dependências instaladas com vulnerabilidades conhecidas (engine: osv-scanner), stack-aware. Reporta e propõe upgrades; nunca auto-corrige, nunca barra install ou commit.",
      es: "Detector on-demand de dependencias instaladas con vulnerabilidades conocidas (engine: osv-scanner), stack-aware. Reporta y propone upgrades; nunca auto-corrige, nunca frena install o commit.",
    },
  },
  {
    id: "lint-validator",
    slug: "lint-validator",
    theme: "quality-validators",
    name: "Lint validator extension",
    sourcePath: ".agent0/context/rules/lint-validator.md",
    historySpec: "013",
    runtime: {
      claude: "native",
      codex: "convention",
    },
    desc: {
      en: "Post-edit validator runs the project's idiomatic linter — Biome (JS/TS), Ruff (Python), Pint + PHPStan/Larastan (PHP) — when the manifest declares it; missing-but-declared emits a non-blocking advisory.",
      pt: "Validator pós-edição roda o linter idiomático do projeto — Biome (JS/TS), Ruff (Python), Pint + PHPStan/Larastan (PHP) — quando o manifesto declara; ausente-mas-declarado emite advisory não-bloqueante.",
      es: "El validator post-edición ejecuta el linter idiomático del proyecto — Biome (JS/TS), Ruff (Python), Pint + PHPStan/Larastan (PHP) — cuando el manifiesto lo declara; ausente-pero-declarado emite advisory no-bloqueante.",
    },
  },
  {
    id: "typecheck-advisory",
    slug: "typecheck-advisory",
    theme: "quality-validators",
    name: "Typecheck advisory",
    sourcePath: ".agent0/context/rules/typecheck-advisory.md",
    runtime: {
      claude: "native",
      codex: "convention",
    },
    desc: {
      en: "Validator runs a typecheck step only when the project declares the primitive (a tsconfig.json, or a `typecheck` script in package.json); otherwise it emits `typecheck-advisory:` and skips.",
      pt: "Validator roda o passo de typecheck só quando o projeto declara o primitivo (um tsconfig.json, ou script `typecheck` no package.json); senão emite `typecheck-advisory:` e pula.",
      es: "El validator corre el paso de typecheck solo cuando el proyecto declara el primitivo (un tsconfig.json, o un script `typecheck` en package.json); si no, emite `typecheck-advisory:` y lo omite.",
    },
  },
  {
    id: "artifact-size-cap",
    slug: "artifact-size-cap",
    theme: "quality-validators",
    name: "Artifact size cap",
    sourcePath: ".agent0/context/rules/artifact-budgets.md",
    historySpec: "065",
    runtime: {
      claude: "native",
      codex: "convention",
    },
    desc: {
      en: "Size is not a quality signal — scope/quality are judged by the /product quality judge. The only size mechanism is a uniform 200 KB catastrophe cap (a token-runaway circuit-breaker) plus per-step anti-stub floors.",
      pt: "Tamanho não é sinal de qualidade — escopo/qualidade são julgados pelo quality judge do /product. O único mecanismo de tamanho é um cap uniforme de 200 KB (circuit-breaker de runaway de tokens) mais pisos anti-stub por passo.",
      es: "El tamaño no es señal de calidad — alcance/calidad los juzga el quality judge de /product. El único mecanismo de tamaño es un cap uniforme de 200 KB (circuit-breaker de runaway de tokens) más pisos anti-stub por paso.",
    },
  },
  {
    id: "session-handoff",
    slug: "session-handoff",
    theme: "runtime-session",
    name: "Session handoff",
    sourcePath: ".agent0/context/rules/session-handoff.md",
    historySpec: "017",
    runtime: {
      claude: "native",
      codex: "native",
      note: {
        en: "Claude injects/nags by hooks; Codex receives the same SessionStart/Stop handoff via tracked .codex/hooks.json (Stop uses continue-with-corrective-prompt parity, not byte-for-byte blocking).",
        pt: "Claude injeta/cobra por hooks; Codex recebe o mesmo handoff SessionStart/Stop via .codex/hooks.json versionado (Stop usa paridade continue-with-corrective-prompt, não bloqueio byte-a-byte).",
        es: "Claude inyecta/recuerda por hooks; Codex recibe el mismo handoff SessionStart/Stop vía .codex/hooks.json versionado (Stop usa paridad continue-with-corrective-prompt, no bloqueo byte-a-byte).",
      },
    },
    desc: {
      en: ".agent0/HANDOFF.md is the runtime-neutral handoff (Current State / Active Work / Next Actions / Decisions). Both runtimes inject it at session start.",
      pt: ".agent0/HANDOFF.md é o handoff runtime-neutro (Current State / Active Work / Next Actions / Decisions). Os dois runtimes injetam no início da sessão.",
      es: ".agent0/HANDOFF.md es el handoff runtime-neutral (Current State / Active Work / Next Actions / Decisions). Ambos runtimes lo inyectan al inicio de la sesión.",
    },
  },
  {
    id: "memory",
    slug: "project-memory",
    theme: "runtime-session",
    name: "Project memory",
    sourcePath: ".agent0/context/rules/memory-placement.md",
    historySpec: "019",
    runtime: {
      claude: "native",
      codex: "native",
      note: {
        en: "Codex ports the memory hooks via tracked .codex/hooks.json (apply_patch is the v1 coverage surface; Bash writes are caught by the .githooks/pre-commit backstop).",
        pt: "Codex porta os hooks de memória via .codex/hooks.json versionado (apply_patch é a superfície de cobertura v1; escritas via Bash são pegas pelo backstop .githooks/pre-commit).",
        es: "Codex porta los hooks de memoria vía .codex/hooks.json versionado (apply_patch es la superficie de cobertura v1; escrituras vía Bash las atrapa el backstop .githooks/pre-commit).",
      },
    },
    desc: {
      en: "Factual project knowledge lives in .agent0/memory/<topic>.md with a trigger-read index (MEMORY.md). Git-tracked for the project, not shipped to forks.",
      pt: "Conhecimento factual do projeto vive em .agent0/memory/<topic>.md com um índice de leitura-por-gatilho (MEMORY.md). Versionado no projeto, não enviado a forks.",
      es: "El conocimiento factual del proyecto vive en .agent0/memory/<topic>.md con un índice de lectura-por-disparador (MEMORY.md). Versionado en el proyecto, no enviado a forks.",
    },
  },
  {
    id: "reminders",
    slug: "reminders",
    theme: "runtime-session",
    name: "Reminders",
    sourcePath: ".agent0/context/rules/reminders.md",
    historySpec: "003",
    runtime: {
      claude: "native",
      codex: "native",
    },
    desc: {
      en: "/remind add/list/dismiss writes .agent0/reminders.yaml — deferred intent auto-read at every session start. Sits between the handoff (WIP) and memory (knowledge).",
      pt: "/remind add/list/dismiss escreve em .agent0/reminders.yaml — intenções adiadas, lidas automaticamente no início de cada sessão. Fica entre o handoff (WIP) e a memória (conhecimento).",
      es: "/remind add/list/dismiss escribe en .agent0/reminders.yaml — intenciones diferidas, leídas automáticamente al inicio de cada sesión. Está entre el handoff (WIP) y la memoria (conocimiento).",
    },
  },
  {
    id: "browser-auth",
    slug: "browser-auth",
    theme: "runtime-session",
    name: "Browser auth workflow",
    sourcePath: ".agent0/context/rules/browser-auth.md",
    historySpec: "021",
    runtime: {
      claude: "native-opt-in",
      codex: "native-opt-in",
    },
    desc: {
      en: "Agent emits `BROWSER_LOGIN_REQUIRED: <host>` on an auth-gated URL; the human runs browser-login.sh and logs in, the agent attaches over CDP (adopt) and saves state to .agent0/.runtime-state/agent-browser/state/<host>.json for headless reads. No MCP.",
      pt: "Agente emite `BROWSER_LOGIN_REQUIRED: <host>` em URL com auth; o humano roda browser-login.sh e faz login, o agente anexa via CDP (adopt) e salva o estado em .agent0/.runtime-state/agent-browser/state/<host>.json para leituras headless. Sem MCP.",
      es: "El agente emite `BROWSER_LOGIN_REQUIRED: <host>` en una URL con auth; el humano ejecuta browser-login.sh e inicia sesión, el agente se conecta vía CDP (adopt) y guarda el estado en .agent0/.runtime-state/agent-browser/state/<host>.json para lecturas headless. Sin MCP.",
    },
  },
  {
    id: "runtime-capabilities",
    slug: "runtime-capabilities",
    theme: "runtime-session",
    name: "Runtime capabilities matrix",
    sourcePath: ".agent0/context/rules/runtime-capabilities.md",
    historySpec: "093",
    runtime: {
      claude: "native",
      codex: "native",
      note: {
        en: "A provider-neutral reference both runtimes consult; it is the source of truth for the status badges shown on this very page.",
        pt: "Uma referência provider-neutra que os dois runtimes consultam; é a fonte de verdade dos badges de status mostrados nesta própria página.",
        es: "Una referencia provider-neutral que ambos runtimes consultan; es la fuente de verdad de los badges de estado mostrados en esta misma página.",
      },
    },
    desc: {
      en: "A provider-neutral matrix of Agent0 capability support across Claude Code, Codex CLI, and future runtimes — consulted before assuming a .claude/* capability is native elsewhere.",
      pt: "Uma matriz provider-neutra do suporte das capacidades do Agent0 entre Claude Code, Codex CLI e runtimes futuros — consultada antes de assumir que uma capacidade .claude/* é nativa em outro lugar.",
      es: "Una matriz provider-neutral del soporte de las capacidades de Agent0 entre Claude Code, Codex CLI y runtimes futuros — consultada antes de asumir que una capacidad .claude/* es nativa en otro lugar.",
    },
  },
  {
    id: "runtime-entrypoints",
    slug: "runtime-entrypoints",
    theme: "runtime-session",
    name: "Multi-runtime entrypoints",
    sourcePath: "AGENTS.md",
    runtime: {
      claude: "native",
      codex: "native",
      note: {
        en: "Each runtime has a native first-contact file: CLAUDE.md for Claude Code, AGENTS.md for Codex; a shared managed index keeps them in sync.",
        pt: "Cada runtime tem um arquivo de primeiro-contato nativo: CLAUDE.md para Claude Code, AGENTS.md para Codex; um índice gerenciado compartilhado mantém os dois em sincronia.",
        es: "Cada runtime tiene un archivo de primer-contacto nativo: CLAUDE.md para Claude Code, AGENTS.md para Codex; un índice gestionado compartido los mantiene en sincronía.",
      },
    },
    desc: {
      en: "CLAUDE.md is the Claude Code entrypoint; AGENTS.md is the Codex entrypoint. Consumer customization lands in AGENTS.override.md or nested AGENTS.md.",
      pt: "CLAUDE.md é o entrypoint do Claude Code; AGENTS.md é o entrypoint do Codex. Customização do consumidor vai em AGENTS.override.md ou AGENTS.md aninhado.",
      es: "CLAUDE.md es el entrypoint de Claude Code; AGENTS.md es el entrypoint de Codex. La personalización del consumidor va en AGENTS.override.md o AGENTS.md anidado.",
    },
  },
  {
    id: "skill-compliance",
    slug: "skill-compliance",
    theme: "skills-tooling",
    name: "Skill compliance",
    sourcePath: ".agent0/skills/skill/SKILL.md",
    historySpec: "033",
    runtime: {
      claude: "native",
      codex: "native-opt-in",
      note: {
        en: "Portable skills' canonical body lives once at .agent0/skills/<slug>/SKILL.md; both runtimes follow discovery symlinks. Codex invokes via /skills or $mention.",
        pt: "O corpo canônico de skills portáveis vive uma vez em .agent0/skills/<slug>/SKILL.md; os dois runtimes seguem symlinks de descoberta. Codex invoca via /skills ou $mention.",
        es: "El cuerpo canónico de skills portables vive una vez en .agent0/skills/<slug>/SKILL.md; ambos runtimes siguen symlinks de descubrimiento. Codex invoca vía /skills o $mention.",
      },
    },
    desc: {
      en: "Every first-party skill must pass the agentskills.io frontmatter spec; the /skill meta-skill scaffolds, audits, ports, and validates them across three declared portability tiers.",
      pt: "Toda skill first-party precisa passar no spec de frontmatter da agentskills.io; a meta-skill /skill faz scaffold, auditoria, porte e validação em três tiers de portabilidade declarados.",
      es: "Toda skill first-party debe pasar el spec de frontmatter de agentskills.io; la meta-skill /skill hace scaffold, auditoría, port y validación en tres tiers de portabilidad declarados.",
    },
  },
  {
    id: "product",
    slug: "product-skill",
    theme: "skills-tooling",
    name: "Product skill",
    sourcePath: ".claude/skills/product/SKILL.md",
    historySpec: "048",
    runtime: {
      claude: "native",
      codex: "convention",
      note: {
        en: "cc-native: bound to Claude's Agent-tool multi-agent orchestration, so it stays physically in .claude/skills/. Codex can follow the pipeline's artifacts manually, but cannot invoke the skill.",
        pt: "cc-native: amarrada à orquestração multi-agente da tool Agent do Claude, então fica fisicamente em .claude/skills/. Codex pode seguir os artefatos do pipeline manualmente, mas não invoca a skill.",
        es: "cc-native: atada a la orquestación multi-agente de la tool Agent de Claude, así que queda físicamente en .claude/skills/. Codex puede seguir los artefactos del pipeline manualmente, pero no invoca la skill.",
      },
    },
    desc: {
      en: "/product is the foundation generator + design partner for the product lifecycle (idea → v1 → vN): a multi-step pipeline producing the planning artifacts + a visual contract that hands off to SDD.",
      pt: "/product é o gerador de fundação + parceiro de design para o ciclo do produto (ideia → v1 → vN): um pipeline multi-step que produz os artefatos de planejamento + um contrato visual que faz handoff para o SDD.",
      es: "/product es el generador de fundación + socio de diseño para el ciclo del producto (idea → v1 → vN): un pipeline multi-paso que produce los artefactos de planificación + un contrato visual que hace handoff al SDD.",
    },
  },
  {
    id: "routines",
    slug: "routines",
    theme: "skills-tooling",
    name: "Routines",
    sourcePath: ".agent0/context/rules/routines.md",
    historySpec: "064",
    runtime: {
      claude: "native",
      codex: "native",
    },
    desc: {
      en: ".agent0/routines/<slug>.md git-tracks recurring project work; an opt-in leader machine's cron enqueues each run for the next interactive session to dispatch via /routine run <slug>.",
      pt: ".agent0/routines/<slug>.md versiona trabalho recorrente do projeto; o cron de uma máquina líder opt-in enfileira cada run para a próxima sessão interativa despachar via /routine run <slug>.",
      es: ".agent0/routines/<slug>.md versiona trabajo recurrente del proyecto; el cron de una máquina líder opt-in encola cada run para que la próxima sesión interactiva lo despache vía /routine run <slug>.",
    },
  },
  {
    id: "image-gen",
    slug: "image-generation",
    theme: "skills-tooling",
    name: "Image generation",
    sourcePath: ".agent0/context/rules/image-gen.md",
    historySpec: "085",
    runtime: {
      claude: "native-opt-in",
      codex: "native-opt-in",
      note: {
        en: "Generation is runtime-neutral (gen.sh POSTs to the fal.run REST API; needs only FAL_KEY). Claude invokes /image, Codex invokes $image; the skill is gated to never auto-fire (paid, side-effecting).",
        pt: "A geração é runtime-neutra (gen.sh faz POST na API REST fal.run; precisa só de FAL_KEY). Claude invoca /image, Codex invoca $image; a skill é travada pra nunca auto-disparar (paga, side-effecting).",
        es: "La generación es runtime-neutral (gen.sh hace POST a la API REST fal.run; necesita solo FAL_KEY). Claude invoca /image, Codex invoca $image; la skill está bloqueada para nunca auto-disparar (paga, side-effecting).",
      },
    },
    desc: {
      en: "Opt-in AI image generation via fal.ai — the /image skill produces draft mockups and brand assets across three cost tiers with a mandatory --tier flag, pre-call cost printing, and a JSONL manifest of every call.",
      pt: "Geração de imagens IA opt-in via fal.ai — a skill /image produz mockups draft e brand assets em três tiers de custo com flag --tier obrigatória, impressão de custo antes da chamada e um manifesto JSONL de cada chamada.",
      es: "Generación de imágenes IA opt-in vía fal.ai — la skill /image produce mockups draft y brand assets en tres tiers de costo con flag --tier obligatoria, impresión de costo antes de la llamada y un manifiesto JSONL de cada llamada.",
    },
  },
  {
    id: "mcp-recipes",
    slug: "mcp-recipes",
    theme: "skills-tooling",
    name: "MCP recipes",
    sourcePath: ".mcp.json.example",
    runtime: {
      claude: "native-opt-in",
      codex: "native-opt-in",
      note: {
        en: "Templates only — .mcp.json.example for Claude Code, .codex/config.toml.example for Codex. Each block is disabled by default with env-var indirection for secrets.",
        pt: "Só templates — .mcp.json.example para Claude Code, .codex/config.toml.example para Codex. Cada bloco vem desativado por padrão com indireção via env-var para segredos.",
        es: "Solo templates — .mcp.json.example para Claude Code, .codex/config.toml.example para Codex. Cada bloque viene desactivado por defecto con indirección vía env-var para secretos.",
      },
    },
    desc: {
      en: "Copy-paste MCP server blocks (Playwright, Chrome DevTools, DBHub, Laravel Boost, Next.js DevTools, fal.ai) ship as templates for both runtimes — disabled by default, env-var indirection for secrets.",
      pt: "Blocos de servidor MCP copy-paste (Playwright, Chrome DevTools, DBHub, Laravel Boost, Next.js DevTools, fal.ai) vêm como templates para os dois runtimes — desativados por padrão, indireção via env-var para segredos.",
      es: "Bloques de servidor MCP copy-paste (Playwright, Chrome DevTools, DBHub, Laravel Boost, Next.js DevTools, fal.ai) vienen como templates para ambos runtimes — desactivados por defecto, indirección vía env-var para secretos.",
    },
  },
  {
    id: "harness-sync",
    slug: "harness-sync",
    theme: "skills-tooling",
    name: "Harness sync",
    sourcePath: ".agent0/context/rules/harness-sync.md",
    historySpec: "016",
    runtime: {
      claude: "native-opt-in",
      codex: "native-opt-in",
      note: {
        en: "Both runtimes run the shell tool explicitly; it is never automatic.",
        pt: "Os dois runtimes rodam a ferramenta shell explicitamente; nunca é automático.",
        es: "Ambos runtimes corren la herramienta shell explícitamente; nunca es automático.",
      },
    },
    desc: {
      en: "Sync tool brings a fork's harness up to date with Agent0 via 3-way baseline reconciliation. Stale files auto-update, consumer-customized files refuse without --force, never touches product code.",
      pt: "Ferramenta de sync atualiza o harness de um fork com Agent0 via reconciliação 3-way contra um baseline. Arquivos stale atualizam sozinhos, arquivos customizados recusam sem --force, nunca toca código de produto.",
      es: "La herramienta de sync actualiza el harness de un fork con Agent0 vía reconciliación 3-way contra un baseline. Archivos stale se actualizan solos, archivos personalizados rechazan sin --force, nunca toca código de producto.",
    },
  },
];
