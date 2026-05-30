import { defineConfig } from "astro/config";
import tailwindcss from "@tailwindcss/vite";

export default defineConfig({
  site: "https://cfpperche.github.io",
  base: "/Agent0/",
  trailingSlash: "always",
  i18n: {
    locales: ["en", "pt", "es"],
    defaultLocale: "en",
    routing: {
      prefixDefaultLocale: true,
      // Root redirect is handled by src/pages/index.astro (instant: JS replace
      // + 0s meta-refresh + canonical), not Astro's default 2s meta-refresh.
      redirectToDefaultLocale: false,
    },
  },
  vite: {
    plugins: [tailwindcss()],
  },
});
