# 055 — In-flight notes

## Design decisions

### 2026-05-19 — parent — OQ-1/2 resolution: optional `chrome` with default-inference back-compat fallback

**Decided:** `chrome` is an optional route field. When omitted, the orchestrator applies a 5-row default-inference table at Step 15 atlas time (`primary/admin → app`, `marketing → marketing`, `auth → auth`, `error → chromeless`). Step 07 prompt instructs sub-agents to emit `chrome` explicitly on every route in NEW sitemaps; default-inference is for back-compat with pre-055 sitemaps only.

**Why two-tier:** required-field would break every existing dogfood sitemap. Optional-without-default would crash atlas on missing field. Optional-with-default-inference threads the needle: legacy sitemaps work unchanged (mechanical fallback), new sitemaps get explicit control.

**Critical context from critique:** the default-inference table CANNOT decide booking-vs-app correctly without help. Vetro's `/[clinicSlug]/agendar` was filed `category: primary` (covered booking US-NN entries; satisfied schema) but rendered runtime as `chrome: booking` (clinic white-label, not authenticated app shell). Default-inference would have placed it under `app/(app)/`, requiring parent override. The explicit-emit discipline avoids that pothole.

### 2026-05-19 — parent — OQ-3 resolution: `chrome: auth` with own `(auth)/layout.tsx`

**Decided:** auth routes get their own group layout — `app/(auth)/layout.tsx` — with consistent shell (logo, language switcher, back-to-marketing link). NOT `chrome: chromeless` (which is for routes with literally no shared anything).

**Why:** auth pages benefit from a shared shell — every login/signup/password-reset page shares the same logo + locale switcher. Chromeless would force every auth page to re-implement them. Vetro's auth routes already had this shape implicit; spec 055 makes it canonical.

### 2026-05-19 — parent — Enum closure for v1

**Decided:** `{app, marketing, booking, auth, chromeless}` is closed for v1. A future product needing `embed` (iframe-friendly), `print` (print-stylesheet), or `kiosk` (full-screen) would bump a spec.

**Why closure:** prevent enum-sprawl. Each new value requires a corresponding `app/(<chrome>)/layout.tsx` design decision + integration with atlas writer. Five values cover the observed product shapes (Vetro's tutor portals fit `booking`; SalãoOS's customer-facing booking would too). Open enum invites premature naming.

## Deviations

None — implementation follows plan.md exactly.

## Tradeoffs

- **Two fields per route (`category` + `chrome`) feel redundant when correlated.** A pure-app SMB SaaS will have most routes as `category: primary` + `chrome: app`. The redundancy is the price of orthogonality — it pays back the moment a single route diverges (Vetro's tutor portal). Mitigation: Step 07 sub-agent can emit chrome from the default-inference table for 80% of routes mechanically, only thinking explicitly when divergence exists.
- **Sitemap inflation.** Adding `chrome:` on every route grows sitemap.yaml. Empirically: a 24-route Vetro sitemap grows by ~24 lines. Acceptable.
- **Default-inference vs explicit-required.** Required would catch the booking-vs-app pothole upstream; optional-with-default leaves room for sub-agent to slip. Mitigation: Step 07 prompt makes the recommendation strong + Step 15 atlas can warn when default-inference fired on a `primary` route that contains `clinicSlug` / `[<dynamic>]` patterns (those are booking-divergence smells).
- **Atlas writes N layouts instead of 1-2.** Pre-055: atlas wrote `(app)/layout.tsx` mandatorily + `(marketing)/layout.tsx` conditionally. Post-055: atlas writes up to 4 layouts (`app`, `marketing`, `booking`, `auth`). Cost: ~4× layout-writes per atlas dispatch. Mitigation: each layout file is <1 KB; total atlas work grows ~3 KB. Negligible.

## Open questions

None remaining at ship — OQ-1/2/3 resolved above.

Forward-looking:

- **Does the explicit-emit discipline hold across next dogfood?** Step 07 sub-agent should emit `chrome` on every route. If next dogfood produces routes without `chrome:` and the default-inference catches them all correctly, the discipline is working. If sub-agent omits `chrome` on a route where default-inference is wrong (booking-vs-app pothole), the prompt needs strengthening (e.g. add a checklist line "every route MUST declare chrome unless it's literally `primary → app`").
- **Is the enum closure right?** 5 values worked for 3 dogfoods. If a future product needs `embed` or `print` chrome, the bump-spec discipline kicks in (and is cheap — add 1 row to enum + 1 layout pattern to atlas brief).
- **Atlas warning on default-inference fired in suspicious cases?** Currently the atlas silently applies default-inference when `chrome` missing. A v2 enhancement could log "default-inference fired on route X because chrome omitted — verify chrome choice" to REPORT.md. Worth doing if Phase 2 of spec 055 shows sub-agents drift on the explicit-emit discipline.
