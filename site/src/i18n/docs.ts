import type { Locale } from "./locales";
import type { RuntimeStatus } from "./capacities";

// UI labels for the explanatory (doc) pages — spec 127. Kept separate from the
// landing's STRINGS so the doc surface can evolve without churning that type.
export type DocStrings = {
  eyebrow: string;
  backToHome: string;
  runtimeLabel: string;
  claude: string;
  codex: string;
  sourceLink: string;
  historyLink: string; // {n} replaced with the spec number
  capabilitiesHeading: string;
  capabilitiesSub: string; // {n} replaced with capacity count
  overviewTitle: string;
  overviewEyebrow: string;
  learnMore: string;
};

// Status badge text — sourced from the runtime-capabilities.md vocabulary.
export const STATUS_LABELS: Record<RuntimeStatus, Record<Locale, string>> = {
  native: { en: "native", pt: "nativo", es: "nativo" },
  "native-opt-in": { en: "native · opt-in", pt: "nativo · opt-in", es: "nativo · opt-in" },
  convention: { en: "convention", pt: "convenção", es: "convención" },
  "read-only": { en: "read-only", pt: "somente-leitura", es: "solo-lectura" },
  planned: { en: "planned", pt: "planejado", es: "planeado" },
  unsupported: { en: "unsupported", pt: "não suportado", es: "no soportado" },
};

export const DOC_STRINGS: Record<Locale, DocStrings> = {
  en: {
    eyebrow: "Capabilities",
    backToHome: "← Back to Agent0",
    runtimeLabel: "Runtime support",
    claude: "Claude Code",
    codex: "Codex CLI",
    sourceLink: "Source on GitHub →",
    historyLink: "History: spec {n}",
    capabilitiesHeading: "How the harness works",
    capabilitiesSub:
      "The {n} capacities, grouped by what they do. Each states its current per-runtime support (sourced from the runtime-capabilities matrix) and links to the canonical source — never a superseded spec.",
    overviewTitle: "How the harness works",
    overviewEyebrow: "Overview",
    learnMore: "Learn more →",
  },
  pt: {
    eyebrow: "Capacidades",
    backToHome: "← Voltar ao Agent0",
    runtimeLabel: "Suporte por runtime",
    claude: "Claude Code",
    codex: "Codex CLI",
    sourceLink: "Código no GitHub →",
    historyLink: "Histórico: spec {n}",
    capabilitiesHeading: "Como o harness funciona",
    capabilitiesSub:
      "As {n} capacidades, agrupadas pelo que fazem. Cada uma indica seu suporte atual por runtime (vindo da matriz runtime-capabilities) e linka pra fonte canônica — nunca uma spec superada.",
    overviewTitle: "Como o harness funciona",
    overviewEyebrow: "Visão geral",
    learnMore: "Saiba mais →",
  },
  es: {
    eyebrow: "Capacidades",
    backToHome: "← Volver a Agent0",
    runtimeLabel: "Soporte por runtime",
    claude: "Claude Code",
    codex: "Codex CLI",
    sourceLink: "Código en GitHub →",
    historyLink: "Historial: spec {n}",
    capabilitiesHeading: "Cómo funciona el harness",
    capabilitiesSub:
      "Las {n} capacidades, agrupadas por lo que hacen. Cada una indica su soporte actual por runtime (de la matriz runtime-capabilities) y enlaza a la fuente canónica — nunca una spec superada.",
    overviewTitle: "Cómo funciona el harness",
    overviewEyebrow: "Visión general",
    learnMore: "Más info →",
  },
};

// Hand-authored overview prose (the derive/curate split: this is curated, not
// derived). Bodies carry inline markup and are rendered with set:html — content
// is trusted, authored here. Code literals (paths/filenames) are language-neutral.
const MATRIX_LINK =
  '<a href="https://github.com/cfpperche/Agent0/blob/main/.agent0/context/rules/runtime-capabilities.md" target="_blank" rel="noopener" class="text-[var(--color-accent)] hover:text-[var(--color-accent-ink)]">runtime-capabilities matrix</a>';

export const OVERVIEW_INTRO: Record<Locale, string> = {
  en: "Agent0 is not a framework you import — it is a set of files that ride along in your repo and shape how an AI coding agent behaves. Four layers do the work, and they compose.",
  pt: "Agent0 não é um framework que você importa — é um conjunto de arquivos que viajam junto no seu repo e moldam como um agente de código IA se comporta. Quatro camadas fazem o trabalho, e elas compõem.",
  es: "Agent0 no es un framework que importas — es un conjunto de archivos que viajan junto en tu repo y moldean cómo se comporta un agente de código IA. Cuatro capas hacen el trabajo, y componen.",
};

export type OverviewSection = { title: Record<Locale, string>; body: Record<Locale, string> };

export const OVERVIEW_SECTIONS: OverviewSection[] = [
  {
    title: {
      en: "Rules — context, not enforcement",
      pt: "Regras — contexto, não imposição",
      es: "Reglas — contexto, no imposición",
    },
    body: {
      en: "Behavioral guidance lives once under <code class='font-mono text-sm'>.agent0/context/rules/</code>. A <code class='font-mono text-sm'>SessionStart</code> hook injects one bounded summary; prompt turns receive small capsules that point the agent at the relevant rule. Rules are how the agent <em>knows</em> the discipline — they don't force it.",
      pt: "A orientação comportamental vive uma vez em <code class='font-mono text-sm'>.agent0/context/rules/</code>. Um hook <code class='font-mono text-sm'>SessionStart</code> injeta um resumo limitado; turnos de prompt recebem cápsulas pequenas que apontam o agente pra regra relevante. As regras são como o agente <em>conhece</em> a disciplina — elas não a forçam.",
      es: "La guía de comportamiento vive una vez en <code class='font-mono text-sm'>.agent0/context/rules/</code>. Un hook <code class='font-mono text-sm'>SessionStart</code> inyecta un resumen acotado; los turnos de prompt reciben cápsulas pequeñas que apuntan al agente a la regla relevante. Las reglas son cómo el agente <em>conoce</em> la disciplina — no la fuerzan.",
    },
  },
  {
    title: {
      en: "Hooks — enforcement at lifecycle moments",
      pt: "Hooks — imposição em momentos do ciclo de vida",
      es: "Hooks — imposición en momentos del ciclo de vida",
    },
    body: {
      en: "Where a rule needs teeth, a hook fires at a specific lifecycle event: <code class='font-mono text-sm'>PreToolUse(Bash)</code> blocks a destructive command or a blanket <code class='font-mono text-sm'>git add</code>; <code class='font-mono text-sm'>SessionStart</code> injects the handoff, reminders, and rule context; <code class='font-mono text-sm'>Stop</code> nags once if you left dirty work without updating the handoff. The gates that <em>can</em> enforce do; the rest stay advisory and let the agent decide.",
      pt: "Onde uma regra precisa de dentes, um hook dispara num evento específico do ciclo de vida: <code class='font-mono text-sm'>PreToolUse(Bash)</code> bloqueia um comando destrutivo ou um <code class='font-mono text-sm'>git add</code> cego; <code class='font-mono text-sm'>SessionStart</code> injeta o handoff, os reminders e o contexto das regras; <code class='font-mono text-sm'>Stop</code> cobra uma vez se você deixou trabalho sujo sem atualizar o handoff. Os gates que <em>podem</em> impor, impõem; o resto fica advisory e deixa o agente decidir.",
      es: "Donde una regla necesita dientes, un hook dispara en un evento específico del ciclo de vida: <code class='font-mono text-sm'>PreToolUse(Bash)</code> bloquea un comando destructivo o un <code class='font-mono text-sm'>git add</code> ciego; <code class='font-mono text-sm'>SessionStart</code> inyecta el handoff, los reminders y el contexto de las reglas; <code class='font-mono text-sm'>Stop</code> recuerda una vez si dejaste trabajo sucio sin actualizar el handoff. Los gates que <em>pueden</em> imponer, imponen; el resto queda advisory y deja decidir al agente.",
    },
  },
  {
    title: {
      en: "Skills — packaged workflows",
      pt: "Skills — workflows empacotados",
      es: "Skills — workflows empaquetados",
    },
    body: {
      en: "Multi-step work is packaged as skills: <code class='font-mono text-sm'>/sdd</code> for spec-driven development, <code class='font-mono text-sm'>/product</code> for the product pipeline, <code class='font-mono text-sm'>/vuln-audit</code>, <code class='font-mono text-sm'>/image</code>, and more. A portable skill's canonical body lives once at <code class='font-mono text-sm'>.agent0/skills/&lt;slug&gt;/</code> and is discovered through symlinks by each runtime.",
      pt: "Trabalho multi-step é empacotado como skills: <code class='font-mono text-sm'>/sdd</code> pra desenvolvimento spec-driven, <code class='font-mono text-sm'>/product</code> pro pipeline de produto, <code class='font-mono text-sm'>/vuln-audit</code>, <code class='font-mono text-sm'>/image</code> e mais. O corpo canônico de uma skill portável vive uma vez em <code class='font-mono text-sm'>.agent0/skills/&lt;slug&gt;/</code> e é descoberto por symlinks em cada runtime.",
      es: "El trabajo multi-paso se empaqueta como skills: <code class='font-mono text-sm'>/sdd</code> para desarrollo spec-driven, <code class='font-mono text-sm'>/product</code> para el pipeline de producto, <code class='font-mono text-sm'>/vuln-audit</code>, <code class='font-mono text-sm'>/image</code> y más. El cuerpo canónico de una skill portable vive una vez en <code class='font-mono text-sm'>.agent0/skills/&lt;slug&gt;/</code> y se descubre por symlinks en cada runtime.",
    },
  },
  {
    title: {
      en: "Runtimes — one capability set, two front doors",
      pt: "Runtimes — um conjunto de capacidades, duas portas de entrada",
      es: "Runtimes — un conjunto de capacidades, dos puertas de entrada",
    },
    body: {
      en: `The same capabilities run on <strong>Claude Code</strong> (via <code class='font-mono text-sm'>.claude/settings.json</code> hooks) and <strong>Codex CLI</strong> (via tracked <code class='font-mono text-sm'>.codex/hooks.json</code>). <code class='font-mono text-sm'>CLAUDE.md</code> and <code class='font-mono text-sm'>AGENTS.md</code> are the two native entrypoints. Not every capability is identical on both — some are native, some opt-in, some convention-only — so each capability below states its exact per-runtime status, taken from the ${MATRIX_LINK}.`,
      pt: `As mesmas capacidades rodam no <strong>Claude Code</strong> (via hooks em <code class='font-mono text-sm'>.claude/settings.json</code>) e no <strong>Codex CLI</strong> (via <code class='font-mono text-sm'>.codex/hooks.json</code> versionado). <code class='font-mono text-sm'>CLAUDE.md</code> e <code class='font-mono text-sm'>AGENTS.md</code> são os dois entrypoints nativos. Nem toda capacidade é idêntica nos dois — algumas são nativas, outras opt-in, outras só convenção — então cada capacidade abaixo indica seu status exato por runtime, tirado da ${MATRIX_LINK}.`,
      es: `Las mismas capacidades corren en <strong>Claude Code</strong> (vía hooks en <code class='font-mono text-sm'>.claude/settings.json</code>) y <strong>Codex CLI</strong> (vía <code class='font-mono text-sm'>.codex/hooks.json</code> versionado). <code class='font-mono text-sm'>CLAUDE.md</code> y <code class='font-mono text-sm'>AGENTS.md</code> son los dos entrypoints nativos. No toda capacidad es idéntica en ambos — algunas son nativas, otras opt-in, otras solo convención — así que cada capacidad abajo indica su estado exacto por runtime, tomado de la ${MATRIX_LINK}.`,
    },
  },
];

