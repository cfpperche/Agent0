import type { Locale } from "./locales";

export type Strings = {
  meta: {
    title: string;
    description: string;
  };
  nav: {
    capacities: string;
    mcps: string;
    whyBuilt: string;
    quickStart: string;
    howToExtend: string;
    faq: string;
    cheatsheet: string;
    github: string;
  };
  hero: {
    eyebrow: string;
    title: string;
    titleAccent: string;
    tagline: string;
    sub: string;
    primaryCta: string;
    secondaryCta: string;
  };
  whatYouGet: {
    eyebrow: string;
    title: string;
    sub: string;
    cardLabel: string;
    specLabel: string;
    ruleDocLink: string;
  };
  mcps: {
    eyebrow: string;
    title: string;
    sub: string;
    toolsSuffix: string;
    readmeLink: string;
    placeholder: string;
    distinction: string;
  };
  whyBuilt: {
    eyebrow: string;
    title: string;
    paragraphs: string[];
  };
  quickStart: {
    eyebrow: string;
    title: string;
    intro: string;
    steps: { title: string; body: string; code?: string }[];
    finalNote: string;
  };
  howToExtend: {
    eyebrow: string;
    title: string;
    intro: string;
    points: { title: string; body: string }[];
    closing: string;
  };
  faq: {
    eyebrow: string;
    title: string;
    items: { q: string; a: string }[];
  };
  footer: {
    builtWith: string;
    license: string;
    editPage: string;
    repoLink: string;
  };
};

const QUICK_START_CODE = `# Clone Agent0 as the seed of a new project
git clone git@github.com:cfpperche/Agent0.git my-new-project
cd my-new-project
rm -rf .git && git init

# Activate the native pre-commit hook (one-time, per-fork)
git config core.hooksPath .githooks

# Open in Claude Code — SessionStart will surface SESSION.md
# and any pending reminders automatically.`;

const EXTEND_CODE = `/sdd new my-capacity      # scaffolds docs/specs/NNN-my-capacity/
# fill spec.md with intent, BDD acceptance scenarios, non-goals
/sdd plan                 # drafts plan.md from spec.md
/sdd tasks                # drafts tasks.md from plan.md
# implement top-to-bottom, checking off as you go`;

export const STRINGS: Record<Locale, Strings> = {
  en: {
    meta: {
      title: "Agent0 — the harness for AI coding agents",
      description:
        "An open-source spec-driven harness for Claude Code: governance gates, delegation discipline, secrets and supply-chain scans, runtime introspection, and more — all opt-in, all auditable.",
    },
    nav: {
      capacities: "Capacities",
      mcps: "MCPs",
      whyBuilt: "Why",
      quickStart: "Quick start",
      howToExtend: "Extend",
      faq: "FAQ",
      cheatsheet: "Cheatsheet",
      github: "GitHub",
    },
    hero: {
      eyebrow: "Open-source · MIT",
      title: "The harness for",
      titleAccent: "AI coding agents.",
      tagline:
        "Agent0 is a base repository that ships the discipline — hooks, rules, spec-driven workflow — so every new project starts with the guardrails already wired up.",
      sub: "Fork it. Pick a stack. The hooks activate the moment your stack is detected.",
      primaryCta: "Get started",
      secondaryCta: "View on GitHub",
    },
    whatYouGet: {
      eyebrow: "Capacities",
      title: "Eighteen capacities, all opt-in.",
      sub: "Each one is documented in its own rule under .claude/rules/, and the non-trivial ones have a spec under docs/specs/. Every override marker (# OVERRIDE: <reason ≥10 chars>) is recorded — there is no silent bypass.",
      cardLabel: "Capacity",
      specLabel: "spec",
      ruleDocLink: "Read the rule →",
    },
    mcps: {
      eyebrow: "MCPs by Agent0",
      title: "Custom MCP servers we built for the harness.",
      sub: "Distinct from the MCP recipes capacity above, which adopts existing third-party MCPs (Playwright, DBHub, …). These are MCP servers we author and ship in this repo to extend Agent0's tool surface itself. Each one is opt-in via `.mcp.json`, plug-and-play, and leaves no footprint on the host harness when deactivated.",
      toolsSuffix: "tools",
      readmeLink: "Read the package →",
      placeholder: "Next MCP slot — open a discussion in the repo if you have a capability worth lifting into the catalog.",
      distinction: "Why this matters: the harness ships discipline (capacities), and the MCP catalog ships verbs (tools the agent can invoke). Both are versioned, both stay in-repo, both are auditable.",
    },
    whyBuilt: {
      eyebrow: "Why it was built",
      title: "Discipline at the speed of an AI agent.",
      paragraphs: [
        "AI coding agents move fast. That speed cuts both ways — a single bad delegation can ship a leaked credential, a force-pushed branch, or an under-specified feature into production before anyone reviews it.",
        "Agent0 is the operating discipline that catches those slips before they land. Not by slowing the agent down, but by giving it the same guardrails a senior engineer has internalized: never run a destructive command without saying why, never delegate without scope, never commit a credential, never install a dependency without leaving a trail.",
        "Each capacity is a hook that fires at a specific moment in the agent's lifecycle: PreToolUse for destructive shapes, PostToolUse for edit validation, SessionStart for context injection, PreCompact for raw-signal preservation. The capacities compose — a delegation gate plus a post-edit validator plus a secrets scan plus a supply-chain block plus a runtime introspect together form a pipeline the agent cannot drift out of.",
        "The discipline is spec-driven: intent before code, BDD scenarios as the contract, every override audited with a reason ≥10 characters. The agent stays fast; the surface area for accidents shrinks.",
      ],
    },
    quickStart: {
      eyebrow: "Quick start",
      title: "Three commands to a guarded project.",
      intro:
        "Agent0 is a template, not a framework. Clone it, reset the git history, point it at your own remote — you now have a project with the harness already wired in.",
      steps: [
        {
          title: "Clone & reset",
          body: "Use Agent0 as the seed. Discard its history; the harness rides with the files.",
          code: QUICK_START_CODE,
        },
        {
          title: "Fill the placeholders",
          body: "Replace the Overview / Stack / Build & test / Conventions / Gotchas sections in CLAUDE.md with your project's specifics. The Compact Instructions, SDD, Delegation, and TDD sections are template-stable.",
        },
        {
          title: "Plug in your stack",
          body: "The validator auto-detects bun, pnpm, npm, python, go, rust by lockfile or marker. When your stack lands, the typecheck+test commands wire up automatically. Stack not covered? Override CLAUDE_DELEGATION_VALIDATOR with your own script.",
        },
      ],
      finalNote:
        "That's it. Open the directory in Claude Code, and the SessionStart hook will surface SESSION.md and pending reminders on the first turn.",
    },
    howToExtend: {
      eyebrow: "Extend",
      title: "Add your own capacity in four steps.",
      intro:
        "Every capacity in Agent0 was once a /sdd new <slug> in someone's terminal. The workflow is identical for adopters.",
      points: [
        {
          title: "Scaffold the spec",
          body: "Run /sdd new my-capacity. The skill creates docs/specs/NNN-my-capacity/ with spec.md, plan.md, tasks.md. Fill spec.md first — intent, BDD acceptance scenarios, non-goals. Don't plan how until you've nailed what.",
        },
        {
          title: "Plan the approach",
          body: "Run /sdd plan to draft plan.md from spec.md. List at least one rejected alternative with reasoning — that's where the engineering judgment lives.",
        },
        {
          title: "Decompose into tasks",
          body: "Run /sdd tasks to draft tasks.md. Each task should be small enough that completion is unambiguous. Acceptance checks at the bottom map 1:1 to spec scenarios.",
        },
        {
          title: "Implement",
          body: "Work tasks.md top-to-bottom. Hooks are bash scripts under .claude/hooks/; rules are markdown under .claude/rules/. Register new hooks in .claude/settings.json. Test fixtures live in .claude/tests/<capacity>/.",
        },
      ],
      closing:
        "The harness already runs on top of itself — every Agent0 capacity was written using the same discipline it now enforces. The recursion is the proof.",
    },
    faq: {
      eyebrow: "FAQ",
      title: "Common questions.",
      items: [
        {
          q: "Do I need Claude Code to use Agent0?",
          a: "Yes — the hooks target Claude Code's lifecycle events (PreToolUse, PostToolUse, SessionStart, PreCompact, Stop). Most capacities have a native fallback that works without Claude Code (the gitleaks pre-commit hook is a real git hook), but the agent-side discipline assumes Claude Code is the driver.",
        },
        {
          q: "What does it cost?",
          a: "Nothing. Agent0 is MIT-licensed and has no runtime dependencies beyond what your project already needs (bash, git, jq, optionally gitleaks). It is a configuration template, not a service.",
        },
        {
          q: "Will the gates slow my agent down?",
          a: "The hooks add 10–30 ms per matched call. The discipline they enforce removes the much larger cost of an undisciplined agent — a leaked secret, a destructive command, a half-specified feature. The arithmetic favors the gates by orders of magnitude.",
        },
        {
          q: "How does it stay in sync across forks?",
          a: "The harness-sync tool (.claude/tools/sync-harness.sh) brings a fork's hooks/rules/tools up to date with Agent0. Hash-compare per file; structured merge for settings.json + CLAUDE.md. Never touches src/ or product manifests. One-way by design — improvements flow upstream via PR.",
        },
        {
          q: "Can I disable a capacity I don't want?",
          a: "Every capacity has an env-var escape (CLAUDE_SKIP_*, CLAUDE_*_BLOCK=0). Per-session opt-out is one var; permanent disable is removing the entry from .claude/settings.json. Override markers handle the per-action case.",
        },
        {
          q: "Why so many gates?",
          a: "Because each gate addresses a category of mistake that has actually been observed in real AI-agent sessions. No gate exists speculatively. The list grows when a new category surfaces; we resist adding gates for hypothetical risks.",
        },
      ],
    },
    footer: {
      builtWith: "Built with Astro · Tailwind · the same discipline it ships.",
      license: "MIT License",
      editPage: "Edit this page",
      repoLink: "Source on GitHub",
    },
  },

  pt: {
    meta: {
      title: "Agent0 — o harness para agentes de código IA",
      description:
        "Um harness open-source spec-driven para Claude Code: governance gates, disciplina de delegação, scans de segredos e supply-chain, introspecção em runtime e mais — tudo opt-in, tudo auditável.",
    },
    nav: {
      capacities: "Capacidades",
      mcps: "MCPs",
      whyBuilt: "Por quê",
      quickStart: "Início rápido",
      howToExtend: "Estender",
      faq: "FAQ",
      cheatsheet: "Cheatsheet",
      github: "GitHub",
    },
    hero: {
      eyebrow: "Open-source · MIT",
      title: "O harness para",
      titleAccent: "agentes de código IA.",
      tagline:
        "Agent0 é um repositório base que entrega a disciplina — hooks, regras, workflow spec-driven — para que cada novo projeto comece já com as guardrails ativas.",
      sub: "Faça fork. Escolha a stack. Os hooks ativam no momento em que sua stack for detectada.",
      primaryCta: "Começar",
      secondaryCta: "Ver no GitHub",
    },
    whatYouGet: {
      eyebrow: "Capacidades",
      title: "Dezoito capacidades, todas opt-in.",
      sub: "Cada uma documentada em sua própria regra em .claude/rules/, e as não-triviais têm spec em docs/specs/. Todo marcador de override (# OVERRIDE: <razão ≥10 chars>) é registrado — não existe bypass silencioso.",
      cardLabel: "Capacidade",
      specLabel: "spec",
      ruleDocLink: "Ler a regra →",
    },
    mcps: {
      eyebrow: "MCPs do Agent0",
      title: "Servidores MCP que escrevemos para o harness.",
      sub: "Distinto da capacidade \"MCP recipes\" acima, que adota MCPs de terceiros prontos (Playwright, DBHub, …). Estes são servidores MCP que nós mesmos publicamos neste repo para estender a superfície de tools do Agent0. Cada um é opt-in via `.mcp.json`, plug-and-play, e não deixa rastro no harness host quando desativado.",
      toolsSuffix: "tools",
      readmeLink: "Ler o pacote →",
      placeholder: "Próximo slot de MCP — abra uma discussão no repo se tiver uma capability digna de entrar no catálogo.",
      distinction: "Por que importa: o harness entrega disciplina (capacidades), e o catálogo de MCPs entrega verbos (tools que o agente pode invocar). Ambos são versionados, ambos vivem no repo, ambos são auditáveis.",
    },
    whyBuilt: {
      eyebrow: "Por que foi construído",
      title: "Disciplina na velocidade de um agente IA.",
      paragraphs: [
        "Agentes de código IA são rápidos. Essa velocidade corta dos dois lados — uma única delegação ruim pode colocar uma credencial vazada, um branch force-pushed, ou uma feature sub-especificada em produção antes de qualquer revisão.",
        "Agent0 é a disciplina operacional que pega esses escorregões antes que aconteçam. Não desacelerando o agente, mas dando a ele as mesmas guardrails que um engenheiro sênior já internalizou: nunca rodar comando destrutivo sem dizer por quê, nunca delegar sem escopo, nunca commitar credencial, nunca instalar dependência sem deixar rastro.",
        "Cada capacidade é um hook que dispara num momento específico do ciclo de vida do agente: PreToolUse para shapes destrutivos, PostToolUse para validação de edit, SessionStart para injeção de contexto, PreCompact para preservar sinal cru. As capacidades compõem — delegation gate + post-edit validator + secrets scan + supply-chain block + runtime introspect formam juntos uma pipeline da qual o agente não consegue derivar.",
        "A disciplina é spec-driven: intenção antes de código, cenários BDD como contrato, todo override auditado com razão ≥10 caracteres. O agente segue rápido; a superfície de acidentes diminui.",
      ],
    },
    quickStart: {
      eyebrow: "Início rápido",
      title: "Três comandos para um projeto protegido.",
      intro:
        "Agent0 é um template, não um framework. Clone, reseta o histórico do git, aponta para o seu remote — você tem um projeto com o harness já cabeado.",
      steps: [
        {
          title: "Clone & reset",
          body: "Use Agent0 como semente. Descarte o histórico; o harness viaja com os arquivos.",
          code: QUICK_START_CODE,
        },
        {
          title: "Preencha os placeholders",
          body: "Substitua as seções Overview / Stack / Build & test / Conventions / Gotchas no CLAUDE.md com as especificidades do seu projeto. As seções Compact Instructions, SDD, Delegation e TDD são estáveis no template.",
        },
        {
          title: "Encaixe sua stack",
          body: "O validator auto-detecta bun, pnpm, npm, python, go, rust por lockfile ou marcador. Quando sua stack chega, os comandos de typecheck+test se conectam automaticamente. Stack não coberta? Sobrescreva CLAUDE_DELEGATION_VALIDATOR com seu próprio script.",
        },
      ],
      finalNote:
        "É isso. Abra o diretório no Claude Code e o hook SessionStart vai mostrar SESSION.md e reminders pendentes no primeiro turno.",
    },
    howToExtend: {
      eyebrow: "Estender",
      title: "Adicione sua própria capacidade em quatro passos.",
      intro:
        "Toda capacidade do Agent0 já foi um /sdd new <slug> no terminal de alguém. O workflow é idêntico para quem adota.",
      points: [
        {
          title: "Scaffold da spec",
          body: "Rode /sdd new minha-capacidade. A skill cria docs/specs/NNN-minha-capacidade/ com spec.md, plan.md, tasks.md. Preencha spec.md primeiro — intenção, cenários BDD de aceite, não-objetivos. Não planeje como antes de cravar o quê.",
        },
        {
          title: "Planeje a abordagem",
          body: "Rode /sdd plan para draftar plan.md a partir de spec.md. Liste ao menos uma alternativa rejeitada com a razão — é aí que mora o julgamento de engenharia.",
        },
        {
          title: "Decomponha em tasks",
          body: "Rode /sdd tasks para draftar tasks.md. Cada task deve ser pequena o suficiente para que terminar seja não-ambíguo. Checks de aceite no final mapeiam 1:1 para os cenários do spec.",
        },
        {
          title: "Implemente",
          body: "Trabalhe tasks.md de cima pra baixo. Hooks são scripts bash em .claude/hooks/; regras são markdown em .claude/rules/. Registre novos hooks em .claude/settings.json. Fixtures de teste em .claude/tests/<capacidade>/.",
        },
      ],
      closing:
        "O harness já roda sobre si mesmo — toda capacidade do Agent0 foi escrita usando a mesma disciplina que ela agora aplica. A recursão é a prova.",
    },
    faq: {
      eyebrow: "FAQ",
      title: "Perguntas frequentes.",
      items: [
        {
          q: "Preciso do Claude Code pra usar Agent0?",
          a: "Sim — os hooks miram os eventos de ciclo de vida do Claude Code (PreToolUse, PostToolUse, SessionStart, PreCompact, Stop). A maioria das capacidades tem fallback nativo que funciona sem Claude Code (o pre-commit do gitleaks é um hook real do git), mas a disciplina do lado do agente assume Claude Code como motor.",
        },
        {
          q: "Quanto custa?",
          a: "Nada. Agent0 é MIT-licenciado e não tem dependências de runtime além do que seu projeto já precisa (bash, git, jq, opcionalmente gitleaks). É um template de configuração, não um serviço.",
        },
        {
          q: "Os gates vão desacelerar meu agente?",
          a: "Os hooks adicionam 10–30 ms por chamada que casa. A disciplina que eles aplicam remove o custo muito maior de um agente sem disciplina — segredo vazado, comando destrutivo, feature mal especificada. A aritmética favorece os gates em ordens de grandeza.",
        },
        {
          q: "Como mantém sincronia entre forks?",
          a: "A ferramenta harness-sync (.claude/tools/sync-harness.sh) atualiza hooks/regras/ferramentas de um fork com Agent0. Hash-compare por arquivo; merge estruturado para settings.json + CLAUDE.md. Nunca toca src/ ou manifestos do produto. One-way por design — melhorias sobem via PR.",
        },
        {
          q: "Posso desativar uma capacidade que não quero?",
          a: "Toda capacidade tem um escape via env-var (CLAUDE_SKIP_*, CLAUDE_*_BLOCK=0). Opt-out por sessão é uma variável; desativar permanente é remover a entrada de .claude/settings.json. Marcadores de override resolvem o caso por-ação.",
        },
        {
          q: "Por que tantos gates?",
          a: "Porque cada gate endereça uma categoria de erro que já foi observada em sessões reais com agente. Nenhum gate existe especulativamente. A lista cresce quando uma nova categoria surge; resistimos a adicionar gates por riscos hipotéticos.",
        },
      ],
    },
    footer: {
      builtWith: "Construído com Astro · Tailwind · a mesma disciplina que entrega.",
      license: "Licença MIT",
      editPage: "Editar esta página",
      repoLink: "Código no GitHub",
    },
  },

  es: {
    meta: {
      title: "Agent0 — el harness para agentes de código IA",
      description:
        "Un harness open-source spec-driven para Claude Code: governance gates, disciplina de delegación, scans de secretos y supply-chain, introspección en runtime y más — todo opt-in, todo auditable.",
    },
    nav: {
      capacities: "Capacidades",
      mcps: "MCPs",
      whyBuilt: "Por qué",
      quickStart: "Inicio rápido",
      howToExtend: "Extender",
      faq: "FAQ",
      cheatsheet: "Cheatsheet",
      github: "GitHub",
    },
    hero: {
      eyebrow: "Open-source · MIT",
      title: "El harness para",
      titleAccent: "agentes de código IA.",
      tagline:
        "Agent0 es un repositorio base que entrega la disciplina — hooks, reglas, workflow spec-driven — para que cada nuevo proyecto empiece con las guardrails ya activadas.",
      sub: "Haz fork. Elige el stack. Los hooks se activan en el momento en que tu stack es detectado.",
      primaryCta: "Empezar",
      secondaryCta: "Ver en GitHub",
    },
    whatYouGet: {
      eyebrow: "Capacidades",
      title: "Dieciocho capacidades, todas opt-in.",
      sub: "Cada una documentada en su propia regla en .claude/rules/, y las no-triviales tienen spec en docs/specs/. Todo marcador de override (# OVERRIDE: <razón ≥10 chars>) es registrado — no existe bypass silencioso.",
      cardLabel: "Capacidad",
      specLabel: "spec",
      ruleDocLink: "Leer la regla →",
    },
    mcps: {
      eyebrow: "MCPs de Agent0",
      title: "Servidores MCP que construimos para el harness.",
      sub: "Distinto de la capacidad \"MCP recipes\" arriba, que adopta MCPs de terceros existentes (Playwright, DBHub, …). Estos son servidores MCP que escribimos y publicamos en este repo para extender la superficie de tools de Agent0. Cada uno es opt-in vía `.mcp.json`, plug-and-play, y no deja huella en el harness host cuando se desactiva.",
      toolsSuffix: "tools",
      readmeLink: "Leer el paquete →",
      placeholder: "Próximo slot de MCP — abre una discusión en el repo si tienes una capability que merezca entrar al catálogo.",
      distinction: "Por qué importa: el harness entrega disciplina (capacidades), y el catálogo de MCPs entrega verbos (tools que el agente puede invocar). Ambos versionados, ambos en el repo, ambos auditables.",
    },
    whyBuilt: {
      eyebrow: "Por qué se construyó",
      title: "Disciplina a la velocidad de un agente IA.",
      paragraphs: [
        "Los agentes de código IA son rápidos. Esa velocidad corta por ambos lados — una sola delegación mal hecha puede dejar una credencial filtrada, un branch force-pushed, o una feature subespecificada en producción antes de cualquier revisión.",
        "Agent0 es la disciplina operativa que detecta esos resbalones antes de que ocurran. No frenando al agente, sino dándole las mismas guardrails que un ingeniero sénior ya tiene internalizadas: nunca ejecutar un comando destructivo sin decir por qué, nunca delegar sin scope, nunca commitear una credencial, nunca instalar una dependencia sin dejar rastro.",
        "Cada capacidad es un hook que dispara en un momento específico del ciclo de vida del agente: PreToolUse para shapes destructivos, PostToolUse para validación de edit, SessionStart para inyección de contexto, PreCompact para preservar señal cruda. Las capacidades componen — delegation gate + post-edit validator + secrets scan + supply-chain block + runtime introspect forman juntas un pipeline del que el agente no puede salirse.",
        "La disciplina es spec-driven: intención antes de código, escenarios BDD como contrato, todo override auditado con razón ≥10 caracteres. El agente sigue rápido; la superficie de accidentes se encoge.",
      ],
    },
    quickStart: {
      eyebrow: "Inicio rápido",
      title: "Tres comandos a un proyecto protegido.",
      intro:
        "Agent0 es un template, no un framework. Clónalo, resetea el historial de git, apúntalo a tu propio remote — ya tienes un proyecto con el harness cableado.",
      steps: [
        {
          title: "Clonar y resetear",
          body: "Usa Agent0 como semilla. Descarta su historial; el harness viaja con los archivos.",
          code: QUICK_START_CODE,
        },
        {
          title: "Rellena los placeholders",
          body: "Reemplaza las secciones Overview / Stack / Build & test / Conventions / Gotchas en CLAUDE.md con las especificidades de tu proyecto. Las secciones Compact Instructions, SDD, Delegation y TDD son estables en el template.",
        },
        {
          title: "Encaja tu stack",
          body: "El validator auto-detecta bun, pnpm, npm, python, go, rust por lockfile o marker. Cuando tu stack llega, los comandos de typecheck+test se cablean automáticamente. ¿Stack no cubierto? Sobrescribe CLAUDE_DELEGATION_VALIDATOR con tu propio script.",
        },
      ],
      finalNote:
        "Eso es todo. Abre el directorio en Claude Code y el hook SessionStart va a mostrar SESSION.md y los reminders pendientes en el primer turno.",
    },
    howToExtend: {
      eyebrow: "Extender",
      title: "Agrega tu propia capacidad en cuatro pasos.",
      intro:
        "Toda capacidad de Agent0 fue alguna vez un /sdd new <slug> en la terminal de alguien. El workflow es idéntico para quien adopta.",
      points: [
        {
          title: "Scaffold del spec",
          body: "Ejecuta /sdd new mi-capacidad. La skill crea docs/specs/NNN-mi-capacidad/ con spec.md, plan.md, tasks.md. Llena spec.md primero — intención, escenarios BDD de aceptación, no-objetivos. No planifiques cómo antes de fijar el qué.",
        },
        {
          title: "Planifica el approach",
          body: "Ejecuta /sdd plan para draftear plan.md a partir de spec.md. Lista al menos una alternativa rechazada con su razón — ahí vive el juicio de ingeniería.",
        },
        {
          title: "Descompón en tasks",
          body: "Ejecuta /sdd tasks para draftear tasks.md. Cada task debe ser pequeña lo suficiente para que terminarla sea no-ambiguo. Los checks de aceptación al final mapean 1:1 a los escenarios del spec.",
        },
        {
          title: "Implementa",
          body: "Trabaja tasks.md de arriba hacia abajo. Los hooks son scripts bash en .claude/hooks/; las reglas son markdown en .claude/rules/. Registra hooks nuevos en .claude/settings.json. Fixtures de tests viven en .claude/tests/<capacidad>/.",
        },
      ],
      closing:
        "El harness ya corre sobre sí mismo — toda capacidad de Agent0 fue escrita usando la misma disciplina que ahora hace cumplir. La recursión es la prueba.",
    },
    faq: {
      eyebrow: "FAQ",
      title: "Preguntas frecuentes.",
      items: [
        {
          q: "¿Necesito Claude Code para usar Agent0?",
          a: "Sí — los hooks apuntan a los eventos de ciclo de vida de Claude Code (PreToolUse, PostToolUse, SessionStart, PreCompact, Stop). La mayoría de las capacidades tienen un fallback nativo que funciona sin Claude Code (el pre-commit de gitleaks es un hook real de git), pero la disciplina del lado del agente asume a Claude Code como driver.",
        },
        {
          q: "¿Cuánto cuesta?",
          a: "Nada. Agent0 es MIT-licenciado y no tiene dependencias de runtime más allá de las que tu proyecto ya necesita (bash, git, jq, opcionalmente gitleaks). Es un template de configuración, no un servicio.",
        },
        {
          q: "¿Los gates van a frenar mi agente?",
          a: "Los hooks agregan 10–30 ms por llamada que matchea. La disciplina que aplican remueve el costo mucho mayor de un agente sin disciplina — secreto filtrado, comando destructivo, feature mal especificada. La aritmética favorece a los gates en órdenes de magnitud.",
        },
        {
          q: "¿Cómo mantiene la sincronía entre forks?",
          a: "La herramienta harness-sync (.claude/tools/sync-harness.sh) actualiza los hooks/reglas/herramientas de un fork con Agent0. Hash-compare por archivo; merge estructurado para settings.json + CLAUDE.md. Nunca toca src/ ni manifiestos del producto. One-way por diseño — las mejoras suben vía PR.",
        },
        {
          q: "¿Puedo desactivar una capacidad que no quiero?",
          a: "Toda capacidad tiene un escape vía env-var (CLAUDE_SKIP_*, CLAUDE_*_BLOCK=0). Opt-out por sesión es una variable; desactivar permanente es remover la entrada de .claude/settings.json. Los marcadores de override resuelven el caso por-acción.",
        },
        {
          q: "¿Por qué tantos gates?",
          a: "Porque cada gate atiende una categoría de error que ya fue observada en sesiones reales con agentes. Ningún gate existe especulativamente. La lista crece cuando una categoría nueva aparece; resistimos a agregar gates por riesgos hipotéticos.",
        },
      ],
    },
    footer: {
      builtWith: "Construido con Astro · Tailwind · la misma disciplina que entrega.",
      license: "Licencia MIT",
      editPage: "Editar esta página",
      repoLink: "Código en GitHub",
    },
  },
};

export { QUICK_START_CODE, EXTEND_CODE };
