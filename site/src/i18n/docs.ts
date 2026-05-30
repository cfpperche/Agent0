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
