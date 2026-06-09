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

# Activate the native pre-commit hook (one-time, per project)
git config core.hooksPath .githooks

# Open in Claude Code or Codex. Agent0 supplies the
# repo-local rules, hooks, handoff, and validation loop.`;

const EXTEND_CODE = `/sdd new my-capacity      # scaffolds docs/specs/NNN-my-capacity/
# fill spec.md with intent, BDD acceptance scenarios, non-goals
/sdd plan                 # drafts plan.md from spec.md
/sdd tasks                # drafts tasks.md from plan.md
# implement top-to-bottom, checking off as you go`;

export const STRINGS: Record<Locale, Strings> = {
  en: {
    meta: {
      title: "Agent0 — portable discipline for coding agents",
      description:
        "A portable governance and evidence harness for Claude Code, Codex, and future coding-agent runtimes: specs, validation, handoff, safety checks, and syncable project discipline.",
    },
    nav: {
      capacities: "Surfaces",
      mcps: "MCPs",
      whyBuilt: "Why",
      quickStart: "Quick start",
      howToExtend: "Extend",
      faq: "FAQ",
      github: "GitHub",
    },
    hero: {
      eyebrow: "Open-source · MIT · Claude Code + Codex",
      title: "Portable discipline for",
      titleAccent: "coding agents.",
      tagline:
        "Agent0 is a base repository that gives existing agent runtimes a governed work loop: intent before code, bounded delegation, validation evidence, and session continuity.",
      sub: "Clone it. Pick a stack. Keep the project discipline in the repo, not in one vendor's UI.",
      primaryCta: "Get started",
      secondaryCta: "View on GitHub",
    },
    whatYouGet: {
      eyebrow: "Harness surfaces",
      title: "{n} documented surfaces, one work loop.",
      sub: "The value is not the count. Each surface supports the same loop: specify the change, execute it with bounded agency, prove the result, and leave a handoff the next runtime can trust.",
      cardLabel: "Surface",
      specLabel: "spec",
      ruleDocLink: "Read the rule →",
    },
    mcps: {
      eyebrow: "MCPs by Agent0",
      title: "Custom MCP servers we built for the harness.",
      sub: "Distinct from the MCP recipes surface above, which adopts existing third-party MCPs (Playwright, DBHub, …). These are MCP servers we author and ship in this repo to extend Agent0's tool surface itself. Each one is opt-in via `.mcp.json`, plug-and-play, and leaves no footprint on the host harness when deactivated.",
      toolsSuffix: "tools",
      readmeLink: "Read the package →",
      placeholder: "Next MCP slot — open a discussion in the repo if you have a capability worth lifting into the catalog.",
      distinction: "Why this matters: the harness ships discipline, and the MCP catalog ships verbs (tools the agent can invoke). Both are versioned, both stay in-repo, both are auditable.",
    },
    whyBuilt: {
      eyebrow: "Why it was built",
      title: "Discipline at the speed of coding agents.",
      paragraphs: [
        "Coding agents already write code. The scarce part is not another assistant; it is a repeatable way to make agent work inspectable, recoverable, and safe enough to continue tomorrow.",
        "Agent0 puts that discipline in the repository. The rules, hooks, skills, validators, handoff, and sync baseline travel with the project instead of living only inside Claude Code, Codex, or the current operator's memory.",
        "The loop is intentionally concrete: write the intent when the change is non-trivial, plan before editing, run bounded delegation, prove the result with the project's own checks, and close with a truthful handoff.",
        "The current proof is local and repo-backed, not a claim of market adoption. Agent0 is still validated by dogfood and consumer-project use on one machine; the public story should say that plainly.",
      ],
    },
    quickStart: {
      eyebrow: "Quick start",
      title: "Three commands to a disciplined project.",
      intro:
        "Agent0 is a template, not a framework or hosted service. Clone it, reset the git history, point it at your own remote — the governance and evidence loop now lives in your repo.",
      steps: [
        {
          title: "Clone & reset",
          body: "Use Agent0 as the seed. Discard its history; the harness travels with the files.",
          code: QUICK_START_CODE,
        },
        {
          title: "Fill the placeholders",
          body: "Set the project-specific identity, stack, commands, conventions, and gotchas. Agent0 supplies the runtime entrypoints and shared harness rules; the product context stays yours.",
        },
        {
          title: "Plug in your stack",
          body: "The validator and rules are stack-aware where possible, but Agent0 does not choose your stack. When the default detector is not enough, plug in your own validator script.",
        },
      ],
      finalNote:
        "That's it. Open the directory in Claude Code or Codex, and the repo-local handoff and rules become the starting context for the session.",
    },
    howToExtend: {
      eyebrow: "Extend",
      title: "Expand the harness only when the evidence earns it.",
      intro:
        "Agent0 should stay smaller than the temptation to automate everything. New first-party surfaces go through scope admission before they become part of the harness.",
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
          body: "Work tasks.md top-to-bottom. Hooks are bash scripts under .agent0/hooks/; rules are markdown under .agent0/context/rules/. Register hooks in .claude/settings.json (Claude Code) and tracked .codex/hooks.json (Codex CLI). Test fixtures live in .agent0/tests/<capacity>/.",
        },
      ],
      closing:
        "The harness runs on top of itself, but dogfood is not market proof. It is the engineering floor: if Agent0 cannot keep its own changes disciplined, it should not ask other projects to trust it.",
    },
    faq: {
      eyebrow: "FAQ",
      title: "Common questions.",
      items: [
        {
          q: "Which agent runtimes does Agent0 support?",
          a: "Claude Code and Codex today. Agent0 keeps a runtime-capability matrix because support is not identical: some surfaces are native, some opt-in, and some are convention-only. The point is honest portability, not pretending every runtime is the same.",
        },
        {
          q: "What does it cost?",
          a: "Nothing for Agent0 itself. It is MIT-licensed repo-local tooling, not a service. Some optional capacities use external tools or paid media providers, and those paths are cost-gated where relevant.",
        },
        {
          q: "Is this another coding agent?",
          a: "No. Agent0 does not replace Claude Code, Codex, or future runtimes. It gives them repo-local instructions, hooks, tools, proof expectations, and handoff state so their work is easier to trust and resume.",
        },
        {
          q: "How does it stay in sync across projects?",
          a: "The harness-sync tool (.agent0/tools/sync-harness.sh) updates Agent0-owned hooks, rules, tools, skills, and entrypoints with 3-way baseline reconciliation. It refuses consumer customizations without force and never touches product code.",
        },
        {
          q: "Can I disable a capacity I don't want?",
          a: "Every capacity has an env-var escape (CLAUDE_SKIP_*, CLAUDE_*_BLOCK=0). Per-session opt-out is one var; permanent disable is removing the entry from .claude/settings.json. Override markers handle the per-action case.",
        },
        {
          q: "What is not proven yet?",
          a: "External adoption. Agent0 is currently validated by local dogfood, repository evidence, and use in the maintainer's own projects. That is useful engineering evidence, but it is not customer traction.",
        },
      ],
    },
    footer: {
      builtWith: "Built with Astro · Tailwind · the same discipline it asks projects to keep.",
      license: "MIT License",
      editPage: "Edit this page",
      repoLink: "Source on GitHub",
    },
  },

  pt: {
    meta: {
      title: "Agent0 — disciplina portátil para agentes de código",
      description:
        "Um harness portátil de governança e evidência para Claude Code, Codex e futuros runtimes de agentes de código: specs, validação, handoff, checks de segurança e disciplina versionada no repo.",
    },
    nav: {
      capacities: "Superfícies",
      mcps: "MCPs",
      whyBuilt: "Por quê",
      quickStart: "Início rápido",
      howToExtend: "Estender",
      faq: "FAQ",
      github: "GitHub",
    },
    hero: {
      eyebrow: "Open-source · MIT · Claude Code + Codex",
      title: "Disciplina portátil para",
      titleAccent: "agentes de código.",
      tagline:
        "Agent0 é um repositório base que dá aos runtimes de agente existentes um loop governado: intenção antes do código, delegação delimitada, evidência de validação e continuidade entre sessões.",
      sub: "Clone. Escolha a stack. Mantenha a disciplina do projeto no repo, não na interface de um único fornecedor.",
      primaryCta: "Começar",
      secondaryCta: "Ver no GitHub",
    },
    whatYouGet: {
      eyebrow: "Superfícies do harness",
      title: "{n} superfícies documentadas, um loop de trabalho.",
      sub: "O valor não é a contagem. Cada superfície sustenta o mesmo loop: especificar a mudança, executar com agência delimitada, provar o resultado e deixar um handoff que o próximo runtime consiga confiar.",
      cardLabel: "Superfície",
      specLabel: "spec",
      ruleDocLink: "Ler a regra →",
    },
    mcps: {
      eyebrow: "MCPs do Agent0",
      title: "Servidores MCP que escrevemos para o harness.",
      sub: "Distinto da superfície \"MCP recipes\" acima, que adota MCPs de terceiros prontos (Playwright, DBHub, …). Estes são servidores MCP que nós mesmos publicamos neste repo para estender a superfície de tools do Agent0. Cada um é opt-in via `.mcp.json`, plug-and-play, e não deixa rastro no harness host quando desativado.",
      toolsSuffix: "tools",
      readmeLink: "Ler o pacote →",
      placeholder: "Próximo slot de MCP — abra uma discussão no repo se tiver uma capability digna de entrar no catálogo.",
      distinction: "Por que importa: o harness entrega disciplina, e o catálogo de MCPs entrega verbos (tools que o agente pode invocar). Ambos são versionados, ambos vivem no repo, ambos são auditáveis.",
    },
    whyBuilt: {
      eyebrow: "Por que foi construído",
      title: "Disciplina na velocidade de agentes de código.",
      paragraphs: [
        "Agentes de código já escrevem código. A parte escassa não é outro assistente; é um modo repetível de tornar o trabalho do agente inspecionável, retomável e seguro o bastante para continuar amanhã.",
        "Agent0 coloca essa disciplina no repositório. Regras, hooks, skills, validators, handoff e baseline de sync viajam com o projeto em vez de viver só no Claude Code, no Codex ou na memória do operador atual.",
        "O loop é concreto de propósito: escreva a intenção quando a mudança não for trivial, planeje antes de editar, use delegação delimitada, prove o resultado com os checks do próprio projeto e feche com um handoff verdadeiro.",
        "A prova atual é local e ancorada no repo, não uma afirmação de adoção de mercado. Agent0 ainda é validado por dogfood e uso em projetos próprios numa única máquina; a narrativa pública deve dizer isso sem inflar.",
      ],
    },
    quickStart: {
      eyebrow: "Início rápido",
      title: "Três comandos para um projeto disciplinado.",
      intro:
        "Agent0 é um template, não um framework ou serviço hospedado. Clone, resete o histórico do git, aponte para seu remote — o loop de governança e evidência passa a viver no seu repo.",
      steps: [
        {
          title: "Clone & reset",
          body: "Use Agent0 como semente. Descarte o histórico; o harness viaja com os arquivos.",
          code: QUICK_START_CODE,
        },
        {
          title: "Preencha os placeholders",
          body: "Defina identidade, stack, comandos, convenções e gotchas do projeto. Agent0 fornece os entrypoints de runtime e as regras compartilhadas do harness; o contexto do produto continua sendo seu.",
        },
        {
          title: "Encaixe sua stack",
          body: "O validator e as regras são stack-aware quando possível, mas Agent0 não escolhe sua stack. Quando o detector padrão não bastar, conecte seu próprio script de validação.",
        },
      ],
      finalNote:
        "É isso. Abra o diretório no Claude Code ou Codex, e o handoff e as regras do repo viram o contexto inicial da sessão.",
    },
    howToExtend: {
      eyebrow: "Estender",
      title: "Expanda o harness só quando a evidência justificar.",
      intro:
        "Agent0 deve continuar menor que a tentação de automatizar tudo. Novas superfícies first-party passam por admissão de escopo antes de virar parte do harness.",
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
          body: "Trabalhe tasks.md de cima pra baixo. Hooks são scripts bash em .agent0/hooks/; regras são markdown em .agent0/context/rules/. Registre hooks em .claude/settings.json (Claude Code) e no .codex/hooks.json versionado (Codex CLI). Fixtures de teste em .agent0/tests/<capacidade>/.",
        },
      ],
      closing:
        "O harness roda sobre si mesmo, mas dogfood não é prova de mercado. É o piso de engenharia: se Agent0 não consegue manter suas próprias mudanças disciplinadas, não deve pedir que outros projetos confiem nele.",
    },
    faq: {
      eyebrow: "FAQ",
      title: "Perguntas frequentes.",
      items: [
        {
          q: "Quais runtimes de agente o Agent0 suporta?",
          a: "Claude Code e Codex hoje. Agent0 mantém uma matriz de capacidades por runtime porque o suporte não é idêntico: algumas superfícies são nativas, outras opt-in, outras só convenção. O ponto é portabilidade honesta, não fingir que todo runtime é igual.",
        },
        {
          q: "Quanto custa?",
          a: "Nada pelo Agent0 em si. Ele é tooling local de repo com licença MIT, não um serviço. Algumas capacidades opcionais usam ferramentas externas ou provedores pagos de mídia, e esses caminhos têm gate de custo quando relevante.",
        },
        {
          q: "Isso é outro agente de código?",
          a: "Não. Agent0 não substitui Claude Code, Codex ou runtimes futuros. Ele dá a eles instruções, hooks, tools, expectativas de prova e estado de handoff dentro do repo para que o trabalho seja mais confiável e retomável.",
        },
        {
          q: "Como mantém sincronia entre projetos?",
          a: "A ferramenta harness-sync (.agent0/tools/sync-harness.sh) atualiza hooks, regras, tools, skills e entrypoints do Agent0 usando reconciliação 3-way por baseline. Ela recusa customizações do consumidor sem force e nunca toca código de produto.",
        },
        {
          q: "Posso desativar uma capacidade que não quero?",
          a: "Toda capacidade tem um escape via env-var (CLAUDE_SKIP_*, CLAUDE_*_BLOCK=0). Opt-out por sessão é uma variável; desativar permanente é remover a entrada de .claude/settings.json. Marcadores de override resolvem o caso por-ação.",
        },
        {
          q: "O que ainda não está provado?",
          a: "Adoção externa. Agent0 hoje é validado por dogfood local, evidência do repositório e uso nos projetos próprios do mantenedor. Isso é evidência útil de engenharia, mas não é tração de clientes.",
        },
      ],
    },
    footer: {
      builtWith: "Construído com Astro · Tailwind · a mesma disciplina que pede aos projetos.",
      license: "Licença MIT",
      editPage: "Editar esta página",
      repoLink: "Código no GitHub",
    },
  },

  es: {
    meta: {
      title: "Agent0 — disciplina portable para agentes de código",
      description:
        "Un harness portable de gobernanza y evidencia para Claude Code, Codex y futuros runtimes de agentes de código: specs, validación, handoff, checks de seguridad y disciplina versionada en el repo.",
    },
    nav: {
      capacities: "Superficies",
      mcps: "MCPs",
      whyBuilt: "Por qué",
      quickStart: "Inicio rápido",
      howToExtend: "Extender",
      faq: "FAQ",
      github: "GitHub",
    },
    hero: {
      eyebrow: "Open-source · MIT · Claude Code + Codex",
      title: "Disciplina portable para",
      titleAccent: "agentes de código.",
      tagline:
        "Agent0 es un repositorio base que da a los runtimes de agente existentes un loop gobernado: intención antes del código, delegación delimitada, evidencia de validación y continuidad entre sesiones.",
      sub: "Clona. Elige el stack. Mantén la disciplina del proyecto en el repo, no en la interfaz de un solo proveedor.",
      primaryCta: "Empezar",
      secondaryCta: "Ver en GitHub",
    },
    whatYouGet: {
      eyebrow: "Superficies del harness",
      title: "{n} superficies documentadas, un loop de trabajo.",
      sub: "El valor no es el conteo. Cada superficie sostiene el mismo loop: especificar el cambio, ejecutarlo con agencia delimitada, probar el resultado y dejar un handoff que el próximo runtime pueda confiar.",
      cardLabel: "Superficie",
      specLabel: "spec",
      ruleDocLink: "Leer la regla →",
    },
    mcps: {
      eyebrow: "MCPs de Agent0",
      title: "Servidores MCP que construimos para el harness.",
      sub: "Distinto de la superficie \"MCP recipes\" arriba, que adopta MCPs de terceros existentes (Playwright, DBHub, …). Estos son servidores MCP que escribimos y publicamos en este repo para extender la superficie de tools de Agent0. Cada uno es opt-in vía `.mcp.json`, plug-and-play, y no deja huella en el harness host cuando se desactiva.",
      toolsSuffix: "tools",
      readmeLink: "Leer el paquete →",
      placeholder: "Próximo slot de MCP — abre una discusión en el repo si tienes una capability que merezca entrar al catálogo.",
      distinction: "Por qué importa: el harness entrega disciplina, y el catálogo de MCPs entrega verbos (tools que el agente puede invocar). Ambos versionados, ambos en el repo, ambos auditables.",
    },
    whyBuilt: {
      eyebrow: "Por qué se construyó",
      title: "Disciplina a la velocidad de agentes de código.",
      paragraphs: [
        "Los agentes de código ya escriben código. La parte escasa no es otro asistente; es una forma repetible de hacer que el trabajo del agente sea inspeccionable, retomable y suficientemente seguro para continuar mañana.",
        "Agent0 pone esa disciplina en el repositorio. Reglas, hooks, skills, validators, handoff y baseline de sync viajan con el proyecto en vez de vivir solo en Claude Code, Codex o la memoria del operador actual.",
        "El loop es concreto a propósito: escribe la intención cuando el cambio no es trivial, planifica antes de editar, usa delegación delimitada, prueba el resultado con los checks del propio proyecto y cierra con un handoff verdadero.",
        "La prueba actual es local y anclada en el repo, no una afirmación de adopción de mercado. Agent0 todavía se valida por dogfood y uso en proyectos propios en una sola máquina; la narrativa pública debe decirlo sin inflarlo.",
      ],
    },
    quickStart: {
      eyebrow: "Inicio rápido",
      title: "Tres comandos a un proyecto disciplinado.",
      intro:
        "Agent0 es un template, no un framework ni un servicio hospedado. Clónalo, resetea el historial de git, apúntalo a tu propio remote — el loop de gobernanza y evidencia pasa a vivir en tu repo.",
      steps: [
        {
          title: "Clonar y resetear",
          body: "Usa Agent0 como semilla. Descarta su historial; el harness viaja con los archivos.",
          code: QUICK_START_CODE,
        },
        {
          title: "Rellena los placeholders",
          body: "Define la identidad, stack, comandos, convenciones y gotchas del proyecto. Agent0 suministra los entrypoints de runtime y las reglas compartidas del harness; el contexto del producto sigue siendo tuyo.",
        },
        {
          title: "Encaja tu stack",
          body: "El validator y las reglas son stack-aware cuando es posible, pero Agent0 no elige tu stack. Cuando el detector por defecto no alcanza, conecta tu propio script de validación.",
        },
      ],
      finalNote:
        "Eso es todo. Abre el directorio en Claude Code o Codex, y el handoff y las reglas del repo se vuelven el contexto inicial de la sesión.",
    },
    howToExtend: {
      eyebrow: "Extender",
      title: "Expande el harness solo cuando la evidencia lo justifique.",
      intro:
        "Agent0 debe seguir siendo más pequeño que la tentación de automatizarlo todo. Nuevas superficies first-party pasan por admisión de alcance antes de volverse parte del harness.",
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
          body: "Trabaja tasks.md de arriba hacia abajo. Los hooks son scripts bash en .agent0/hooks/; las reglas son markdown en .agent0/context/rules/. Registra hooks en .claude/settings.json (Claude Code) y en el .codex/hooks.json versionado (Codex CLI). Fixtures de tests viven en .agent0/tests/<capacidad>/.",
        },
      ],
      closing:
        "El harness corre sobre sí mismo, pero dogfood no es prueba de mercado. Es el piso de ingeniería: si Agent0 no puede mantener sus propios cambios disciplinados, no debería pedir que otros proyectos confíen en él.",
    },
    faq: {
      eyebrow: "FAQ",
      title: "Preguntas frecuentes.",
      items: [
        {
          q: "¿Qué runtimes de agente soporta Agent0?",
          a: "Claude Code y Codex hoy. Agent0 mantiene una matriz de capacidades por runtime porque el soporte no es idéntico: algunas superficies son nativas, otras opt-in y otras solo convención. El punto es portabilidad honesta, no fingir que todo runtime es igual.",
        },
        {
          q: "¿Cuánto cuesta?",
          a: "Nada por Agent0 en sí. Es tooling local de repo con licencia MIT, no un servicio. Algunas capacidades opcionales usan herramientas externas o proveedores pagos de media, y esos caminos tienen gate de costo cuando corresponde.",
        },
        {
          q: "¿Esto es otro agente de código?",
          a: "No. Agent0 no reemplaza a Claude Code, Codex ni runtimes futuros. Les da instrucciones, hooks, tools, expectativas de prueba y estado de handoff dentro del repo para que el trabajo sea más confiable y retomable.",
        },
        {
          q: "¿Cómo mantiene la sincronía entre proyectos?",
          a: "La herramienta harness-sync (.agent0/tools/sync-harness.sh) actualiza hooks, reglas, tools, skills y entrypoints de Agent0 usando reconciliación 3-way por baseline. Rechaza customizaciones del consumidor sin force y nunca toca código de producto.",
        },
        {
          q: "¿Puedo desactivar una capacidad que no quiero?",
          a: "Toda capacidad tiene un escape vía env-var (CLAUDE_SKIP_*, CLAUDE_*_BLOCK=0). Opt-out por sesión es una variable; desactivar permanente es remover la entrada de .claude/settings.json. Los marcadores de override resuelven el caso por-acción.",
        },
        {
          q: "¿Qué no está probado todavía?",
          a: "Adopción externa. Agent0 hoy se valida por dogfood local, evidencia del repositorio y uso en los proyectos propios del mantenedor. Eso es evidencia útil de ingeniería, pero no es tracción de clientes.",
        },
      ],
    },
    footer: {
      builtWith: "Construido con Astro · Tailwind · la misma disciplina que pide a los proyectos.",
      license: "Licencia MIT",
      editPage: "Editar esta página",
      repoLink: "Código en GitHub",
    },
  },
};

export { QUICK_START_CODE, EXTEND_CODE };
