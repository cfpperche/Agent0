export const LOCALES = ["en", "pt", "es"] as const;
export type Locale = (typeof LOCALES)[number];

export const LOCALE_LABELS: Record<Locale, string> = {
  en: "English",
  pt: "Português",
  es: "Español",
};

export const LOCALE_SHORT: Record<Locale, string> = {
  en: "EN",
  pt: "PT",
  es: "ES",
};

export const DEFAULT_LOCALE: Locale = "en";

export const REPO_URL = "https://github.com/cfpperche/Agent0";
export const REPO_TREE = `${REPO_URL}/blob/main`;
