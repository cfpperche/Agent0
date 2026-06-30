# Skills classification — where each Agent0 skill goes in Tachyon

_Created 2026-06-28. Updated 2026-06-29 — **plugin migration COMPLETE**. Private migration record (NAMES Agent0 →
never lands in the Tachyon repo, same hygiene as `tachyon-capability-harvest.md`)._

> **Status (2026-06-29): the plugin migration is DONE.** Every consumer-facing capability shipped as a marketplace
> plugin in `tachyon-plugins`. What remains is not plugin work: CORE skills retire (native-subsumed), `meeting`/`remind`
> are thin demand-gated residuals, and `frontend-designer` is blocked on a Tachyon-native prerequisite. See the Tally.

> **Scope vs the harvest map.** `tachyon-capability-harvest.md` classifies the capabilities that *built* Tachyon
> (self-hosting lens) — under that lens it correctly DROPS media/audit skills ("not what built Tachyon"). THIS doc uses
> the broader **dissolution** lens (Agent0 → Tachyon as a product platform): a skill's value to a Tachyon *consumer*.
> Under that lens the media/audit skills are **plugins**, not drops. Both are right for their scope.

## Buckets (Tachyon model)

- **PLUGIN** — ships as a marketplace plugin in its own repo: a neutral SKILL payload ± a provisioned tool (pinned
  binary via the launcher — the `dep-audit`/`secrets-guard` pattern). The home for consumer-facing capabilities.
  Sub-shapes: **tool-plugin** (provisions a binary / resolves an ambient runner), **API-plugin** (needs only an env key,
  no binary), **skill-plugin** (payload only, no tool).
- **CORE** — already engine-native in Tachyon; the skill does NOT migrate — it's *subsumed* by an existing Bridge/UI
  feature, so the move is "retire the Agent0 skill," not "port it."
- **OTHER FORMAT** — fits neither cleanly: becomes a recipe/doc, a redesign over a native primitive, or internal
  dev-tooling. A port would change its mechanism fundamentally.

## Classification

### PLUGIN — tool-plugin (skill + binary / ambient runner)

| Skill | Provisions | Disposition |
|---|---|---|
| **vuln-audit** | osv-scanner | ✅ **DONE** — shipped as the `dep-audit` plugin (spec 272, tachyon-plugins v0.11.0). |
| **transcribe** | whisper.cpp data-model + whisper-cli/ffmpeg external tools | ✅ **DONE** — local-first STT (specs 284/285/286, **v0.16.0**). First plugin on the data-artifact + external-tool engines. |
| **diagram** | mmdc (pinned npx) + system Chrome (289 candidate names) | ✅ **DONE** — local mermaid→SVG/PNG/PDF (spec 288, **v0.17.0**); degrades to validation-only when Chrome absent. |
| **audio** | kokoro / piper via uvx (ambient runner) | ✅ **DONE** — local-first TTS only (spec 290, **v0.18.0**). ElevenLabs/remote deferred to a FUTURE integration plugin (owner). |
| **hyperframes** | ffmpeg (HTML→MP4 from code) | ✅ **DONE** — the deterministic/free half of the split video capability (spec 292, **v0.20.0**). |

### PLUGIN — API-plugin (skill + env key, no binary)

| Skill | Needs | Disposition |
|---|---|---|
| **image** | FAL_KEY (fal.ai REST, sync) | ✅ **DONE** — cost-gated AI image gen (spec 291, **v0.19.1**). |
| **sound** | FAL_KEY (fal.ai REST, sync) | ✅ **DONE** — paid music/SFX, same shape as image (spec 291, **v0.19.1**). |
| **video** | FAL_KEY (fal.ai QUEUE, async) | ✅ **DONE** — the paid/generative half of the split (spec 293, **v0.21.0**); fire-and-forget submit→poll + ledger + hard cost gate. (`/video` was SPLIT into `hyperframes` + `video`.) |

### PLUGIN — skill-plugin (payload only, no tool)

| Skill | Disposition |
|---|---|
| **sdd** | ✅ **DONE** — the backbone, already an example plugin; GREW the back half of the lifecycle: `/sdd verify` + `/sdd close` (spec 295, **v1.2.0 / plugins v0.23.0**). |
| **product** | ✅ **DONE** — shipped as **`product-foundation`** (spec 294, **v0.22.0**), the last migration. Renamed (`product` too broad); the referenced `mcp-product-pipeline` MCP was DEAD → stripped, its Layer-1 invariant re-homed into a plugin-native validator; depends on the `agent-browser` plugin (spec-276) for the visual check; **claude-only v1** (codex a deliberate fast-follow). |
| **frontend-designer** | ⛔ **BLOCKED (not a plugin port yet)** — depends on a Tachyon-native **UI-acceptance render harness** (harvest-map Bucket D) existing first. That harness is Tachyon-native work, not a plugin port; migrate `frontend-designer` only after it lands. |

### CORE — subsumed by the Tachyon engine (retire the skill, don't port)

| Skill | Native Tachyon home |
|---|---|
| **claude-exec** | Bridge `spawn_agent` / `probe_agent` (captured second-model duets, spec 257) — the exec-bridge existed only because Agent0 had no native agent spawning; Tachyon has it. |
| **codex-exec** | Same — `spawn_agent` / `probe_agent`. |
| **status** | The sidebar + tmux Server Inspector + Handoff panel + Activity — a richer live cockpit than a text readout. |
| **routine** | Tachyon **schedules** (`propose_schedule` / `list_schedules` + cron). The git-tracked-routine pattern may want a thin layer, but the mechanism is native. |

### OTHER FORMAT — residual, demand-gated (not built; would change mechanism)

| Skill | Why & direction |
|---|---|
| **meeting** | Multi-party human+claude+codex deliberation. Its *mechanism* (the exec bridges) is ALREADY subsumed by native multi-agent spawn+probe → a port is a **redesign**, not a copy: a thin **deliberation-recipe skill-plugin** over native spawn (the residual value = the anti-confirmation-bias turn protocol). The most plugin-shaped of what's left, but **low-demand — build only on real demand** (rule-of-three). |
| **remind** | Deferred-intent list (due dates / snooze / check-cmd). Overlaps Tachyon **pins** (which lack due/snooze). Either a small NATIVE extension to pins OR a lightweight skill-plugin — not a clean fit either way. Demand-gated. |

### DROP — will NOT migrate (owner decision)

| Skill | Disposition |
|---|---|
| **unused-code** | **Discarded 2026-06-28 (owner).** The audit category is already represented by `dep-audit` (spec 272); adds no proof-of-pattern. Stays Agent0-only. |
| **brainstorm** | **Discarded 2026-06-29 (owner).** The ideation→HTML process adds no proof-of-pattern beyond the media skill-plugins. Stays Agent0-only. |
| **skill** | **Discarded as a plugin 2026-06-29.** Its core (SKILL.md compliance VALIDATION) is already native in the engine (`parseSkillFrontmatter` / `loadPlugin`); the only net-new bit (scaffold) is plugin-AUTHORING DX, not a consumer capability. If authoring friction lands, build a `tachyon plugin new/validate` dev-command (Tachyon pin **p-5c1d0a**) — NOT an installable plugin. |

## Tally (2026-06-29 — migration complete)

- **PLUGIN: 11 shipped** — vuln-audit (dep-audit ✅) · transcribe ✅ · diagram ✅ · audio ✅ · hyperframes ✅ · image ✅ · sound ✅ · video ✅ · sdd ✅ (+verify/close) · product (→ product-foundation ✅). **+1 BLOCKED:** frontend-designer (gated on a UI-acceptance harness).
- **CORE (subsumed, retire): 4** — claude-exec, codex-exec, status, routine.
- **OTHER (residual, demand-gated): 2** — meeting, remind.
- **DROP: 3** — unused-code, brainstorm, skill.

(`/video` was split into two plugins — `hyperframes` (code/local/free) + `video` (generative/paid) — so 11 shipped
plugins cover the 10 PLUGIN-classified skills.)

## What's left (none of it is plugin-port work)

1. **CORE retirements** — happen as the Tachyon-rooted equivalent is proven (cutover invariant). Possible thin layer:
   routine's git-tracked-recurring-definition pattern, IF native schedules don't capture "the routine lives in the repo,
   reviewable" — likely already covered.
2. **frontend-designer** — blocked on building the Tachyon-native UI-acceptance render harness FIRST (Bucket D).
3. **meeting / remind** — thin, demand-gated; do NOT build speculatively.
4. **Future DX track (not a migration):** `tachyon plugin new/validate` dev-command (pin p-5c1d0a); the agent-screen
   primitive (pin p-406332) stays deferred.
