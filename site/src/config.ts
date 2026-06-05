// Site-wide maintenance toggle.
//
// While `true`, every route renders the trilingual "Em construção" page
// (src/components/Maintenance.astro) instead of the marketing content. The
// full site source is untouched — it lives in the `else` branch of each
// layout, so flipping this back to `false` restores everything as-is.
//
// Why this exists: the Agent0 harness is changing fast and the site content
// is drifting out of date. Maintenance mode freezes the public shopfront until
// the content catches up.
//
// Build-time override (e.g. to preview the real site locally while the flag is
// on): `PUBLIC_UNDER_CONSTRUCTION=false bun run build`
const ENV = import.meta.env.PUBLIC_UNDER_CONSTRUCTION;

export const UNDER_CONSTRUCTION = ENV === undefined ? true : ENV !== "false";
