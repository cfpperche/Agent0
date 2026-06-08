# Reference research - agent0-roadmap

_Created 2026-06-08 by /frontend-designer. Git-tracked decision record._

## Brief

This surface is a standalone documentation page for Agent0 maintainers. It needs to make the current governance harness shape visible at a glance: categories discussed in specs 166/167, shipped capabilities, and deferred follow-ups. The platform is plain HTML/CSS/JS because the root repo does not resolve to a frontend stack.

## References

| # | source (URL / path) | domain relevance | pattern borrowed | pattern rejected | implementation consequence |
|---|---------------------|------------------|------------------|------------------|----------------------------|
| 1 | `https://roadmap.sh/` | Canonical developer-roadmap reference. | Clear title, short explanatory text, category-driven navigation, community roadmap framing. | Exact brand, logo, copy, and site hierarchy. | Page starts with a compact hero, status chips, and category filters. |
| 2 | `https://roadmap.sh/roadmaps/?g=Web+Development` | Shows roadmap categories and browseable roadmap cards. | Category tabs/chips and compact roadmap entries. | Favorites/login/community statistics and promotional sections. | Agent0 page uses filter chips and dense category groups without account/product UI. |
| 3 | `.agent0/context/rules/agent0-governance-doctrine.md` | Canonical Agent0 governance taxonomy. | Layered model: spine, domains, substrate, transversal constraints, scope admission. | Treating the categories as flat feature buckets. | Roadmap rows are organized by governance layer and boundary. |
| 4 | `.agent0/context/rules/scope-admission-governance.md` | Defines what can be built, deferred, rejected, or instrumented. | Admission outcomes and hardening bar. | Presenting deferred work as promised work. | Missing items use explicit deferred/not-admitted language. |

## Conventions / accessibility notes

- Roadmap status must be textual, not color-only.
- Filter buttons should be real `button` elements with `aria-pressed`.
- The connected roadmap graphic should degrade to readable grouped sections on small screens.
- The primary page heading must be discoverable by role/name for render-tier visual verification.

## Sources

- https://roadmap.sh/
- https://roadmap.sh/roadmaps/?g=Web+Development
- `.agent0/context/rules/agent0-governance-doctrine.md`
- `.agent0/context/rules/scope-admission-governance.md`
- `.agent0/HANDOFF.md`
