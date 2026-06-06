# Done-proof — reuse spec 155, fail closed, be honest about native

`frontend-designer` invents **no** acceptance gate. "Done" reuses the spec-155 visual-contract gate (`.agent0/context/rules/visual-contract.md`) — UI is proven by *driving* it, not by static review. This is the anti-drift anchor: no new "design quality score", no bespoke verifier.

## Browser-renderable surfaces (web, and any surface with a web harness)

1. Declare the tier in `design-direction.md`: `**UI impact:** render | interaction | flow`.
   - **render** — mounts; required a11y roles/names present; console errors within budget.
   - **interaction** — render + named controls respond (click/type/select/press → expected post-action role/name).
   - **flow** — interaction + ordered traversal from a start route, each step asserting URL/state.
2. Write a `fixture-spec.json` from `templates/fixture-spec.json.tmpl` with the surface's real assertions.
3. Run the surface (dev server / preview) and verify:
   ```bash
   bash .agent0/skills/frontend-designer/scripts/frontend-designer.sh verify \
     "http://localhost:<port>" path/to/fixture-spec.json <gitignored-out-dir>
   ```
   A green `report.json` (`overall: pass`) is the proof. Link it from `design-direction.md` § Acceptance.

## Fail closed — agent-browser unavailable is a BLOCKER, never a pass

The `verify` wrapper checks `agent-browser route` first. If it isn't `primary`, it exits **rc 4** with a `BLOCKER` message and produces no report. Unavailability does **not** become a pass, an "advisory skip", or an assumed-green. Install agent-browser + Chrome (`scripts/frontend-designer.sh caps` to check), or take the native-evidence path below — but never claim browser visual proof you didn't produce.

## Native-only surfaces (no web harness)

For native mobile/desktop surfaces with no browser-renderable harness:

1. **Prefer a project-provided web harness** if one exists — `react-native-web` / Expo web, Storybook/Ladle, a web preview. `detect` reports `browser_renderable: yes (expo-web|storybook)` when present. If so, verify through it like any web surface.
2. **Otherwise, ship honest evidence:** the code plus the project's native build/test output (typecheck, component tests, a native build that compiles), **explicitly labeled** in `design-direction.md` § Acceptance as *"native build/test evidence — NOT visual-contract proof."*
3. **Do not add new native visual tooling** (simulator screenshot pipelines, native pixel-diff harnesses). That is deferred behind the repo's rule-of-three demand test — it needs 3+ real demands before it's built, not a speculative dependency here.

The honest-evidence path proves *the code is real and builds*; it does **not** claim the visual contract was met. Say which one you have.
