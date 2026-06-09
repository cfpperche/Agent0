// Site-wide maintenance toggle.
//
// When enabled, every route renders the trilingual "Em construção" page
// (src/components/Maintenance.astro) instead of the marketing content.
//
// Why this exists: keep a fast manual pause switch when the harness moves
// faster than the public copy.
//
// Build-time override: `PUBLIC_UNDER_CONSTRUCTION=true bun run build`
const ENV = import.meta.env.PUBLIC_UNDER_CONSTRUCTION;

export const UNDER_CONSTRUCTION = ENV === undefined ? false : ENV === "true";
