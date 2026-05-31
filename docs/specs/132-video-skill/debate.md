# 132 — video-skill — debate

_Created 2026-05-31._

**Initiating agent:** Claude Code
**Reviewing agent:** Codex CLI
**Initiated by:** Claude Code session 2026-05-31

Cross-model review of `spec.md` between two tool-calling CLI agents. This debate was conducted **out-of-band** via the `/codex-exec` bridge (spec 128) rather than the live two-session protocol — Claude Code authored each initiating slot, and Codex CLI (0.135.0, read-only sandbox, `--reasoning-effort high`) authored each critique by inspecting the real repo files. Transcripts: `.agent0/.runtime-state/codex-exec/20260531T170010Z-video-debate-r1/` and `…T170352Z-video-debate-r2/` (gitignored runtime state — this file is the durable record). Goal: pressure-test the architecture before `plan.md` is locked.

---

## Round 1 — initiating agent (position)

**Intent.** Add `/video` as an opt-in, multi-runtime skill with two disjoint modes under a required `--mode`: `code` (HyperFrames, deterministic HTML→MP4, zero inference cost) and `generative` (paid async fal.ai video). Locked before the debate: deterministic → HyperFrames (Apache-2.0 removes Remotion's per-org license gate; HTML is more reliable for LLM authoring); generative → extend the existing `/image` fal.ai mechanism, tiered by cost, Higgsfield as optional alt provider only.

**Top open questions put to the reviewer (Q1–Q6):**
1. **Topology** — one `/video --mode` vs two skills vs folding video into `/image`.
2. **Multi-runtime** — vendor vs delegate the upstream HyperFrames skill; how to keep the generative async path runtime-neutral on Codex (no Claude-only `run_in_background`).
3. **Async + cost gate** — submit/poll shape; is `/image`'s passive cost-print too weak for 100–1000× video cost?
4. **Storage/determinism** — track HTML source, gitignore MP4, record render; any drift trap?
5. **DRY** — shared `fal-rest.sh` lib vs calling `/image`'s `gen.sh`.
6. **Anti-rigidity** — keep tier→model from becoming a frozen stack opinion.

**Where the initiating agent wanted pushback:** Q2 (vendor-vs-delegate + Codex async parity) and Q3 (gate strength) were the least-confident areas.

---

## Round 1 — reviewing agent (critique)

Codex took independent positions (mostly REFINE), citing real files:

- **Q1 — REFINE.** Keep one user-facing `/video`, but don't pretend `--mode` is as simple as `/image --tier`; these are two execution contracts. Split helpers/manifests/policies internally. Folding into `/image` is worse — its storage/tiers/synchronous-REST assumptions are image-specific (`image/SKILL.md:44`).
- **Q2 — REFINE.** Delegate to HyperFrames but **no implicit install** (mutates checkout, breaks read-only/offline). Explicit activation + pinned version; vendoring risks nested-`SKILL.md` discovery problems against Agent0's one-canonical + symlink model (`runtime-capabilities.md:32`). Async parity breaks only if you use Claude conveniences — make submit/poll pure shell/curl/jq, persist job state, foreground loop.
- **Q3 — AGREE.** Stronger gate than `/image`'s cost-print (which admits it's the only v1 signal and sub-agent runaway isn't caught — `image-gen.md:166`). Use `--confirm-cost-usd=<max>` or an override marker bound to cost, not a generic `--confirm`. Paid generative only; deterministic exempt.
- **Q4 — REFINE.** Track source, ignore MP4, record receipts — but source alone isn't reproducible: Chrome/ffmpeg/fonts/HyperFrames-version/viewport/source-hash all must land in the manifest or committed HTML drifts from the last MP4.
- **Q5 — REFINE.** Shared fal primitives yes, but NOT via `/image`'s `gen.sh` (bakes `image_size`, `.images[0].url`, aspect tables, dim reconciliation — `gen.sh:292`). Put shared code at a non-discoverable path (`.agent0/tools/fal-rest.sh`) with tests; keep tier tables + storage per skill.
- **Q6 — REFINE.** Semantic tiers + refreshable `references/video-tiers.yaml` (snapshot date, candidates, price bands, constraints); resolve at `prepare`, optionally consult fal discovery, write resolved model to envelope+manifest; refresh monthly / warn after 45–60 days.

**Where Claude is wrong:** (1) "delegate/orchestrate" too loose — any live `npx skills add`/auto-install loses determinism + pinning. (2) `/image`'s SKILL.md is internally stale — frontmatter says MCP-delegation but the real contract is REST (`image/SKILL.md:105`, `gen.sh:305`); don't copy that confusion. (3) A plain `--confirm` becomes ritual text — bind it to cost/model/duration.

**Multi-runtime parity risks:** Codex doesn't consume `.claude/skills` as truth (need `.agent0/skills/video` + both symlinks + `openai.yaml allow_implicit_invocation:false`); don't rely on MCP generation or runtime-specific MCP tool names; don't rely on Claude background execution (submit→request_id, poll→status, download, persisted state + manifest for success/failure); HyperFrames adds local deps (Node/npx, Chromium, ffmpeg, fonts) Codex may lack — declare, pin, fail clean → `agentskills-portable`, not `runtime-agnostic` (`portability-tiers.md:23`).

---

## Round 2 — initiating agent (counter)

Conceded outright: Q3 (`--confirm-cost-usd` bound to envelope), Q4 fingerprint-in-manifest, Q6 refreshable `video-tiers.yaml`, and the `/image` stale-frontmatter catch (fix in `/image` separately, don't copy). Pushed back on four open forks:

- **R1 (own vs delegate).** HyperFrames is TWO artifacts — an npm **engine** (cleanly pinnable) and a separate agentskills.io **authoring skill** (a 2nd discovery surface Agent0 can't version-control). Counter-proposal: depend on the pinned npm engine, **own** a minimal authoring layer in `references/`, don't delegate to the upstream skill at all.
- **R2 (async model).** "Foreground loop" blocks 5+ min/clip — terrible for an 8-clip storyboard. Forced a choice: (A) blocking poll loop vs (B) fire-and-forget ledger + separate `poll [--all]`. Leaned B.
- **R3 (speculative-observability line).** Fingerprint as manifest fields = yes; a drift-detector tool = speculative observability, defer until rule-of-three. Asked Codex to agree the boundary.
- **R4 (DRY sequencing).** Extract `fal-rest.sh` for `/video` now; migrate `/image` onto it as a decoupled follow-up so `/video` doesn't block on destabilizing a working skill.
- **R5 (topology honesty).** Make `--mode` required no-default; is one thin-router SKILL.md honest, or was Codex arguing for two skills?

---

## Round 2 — reviewing agent (critique)

Codex converged — concrete `DECISION:` per fork:

- **R1 — Own the `/video` authoring layer; depend only on a pinned `hyperframes@x.y.z` engine.** One Agent0-owned discovery surface beats reusing upstream prose; cite upstream as prior art, ship minimal templates under `references/`.
- **R2 — Use B (fire-and-forget ledger) for v1.** Async video is job-based; hiding it behind a blocking `exec` is the wrong contract and unusable for batches. `prepare`/`submit`/`poll [--all]`/`download+record`; job state in a gitignored ledger; manifest entries only at terminal success/failure.
- **R3 — Record render fingerprints in v1; ship no drift-checker.** Fields are cheap and preserve evidence (source hash, output hash, HyperFrames/Chromium/ffmpeg versions, viewport, duration, render command). A drift detector is second-order automation — wait until mismatch pain recurs.
- **R4 — Extract `.agent0/tools/fal-rest.sh` for `/video` now; migrate `/image` in a follow-up spec.** Don't destabilize working `/image`; mark temporary duplication as time-boxed debt; follow-up includes the stale-docs fix + REST-lib migration.
- **R5 — One `/video` skill, required `--mode=code|generative`.** Cohesive noun is video; split is internal mechanics. Router only if honest: separate mode sections, helpers, storage rules, confirmation policy — no shared fake abstraction beyond invocation.

---

## Round 3 — initiating agent (counter)

_Not needed — debate converged at Round 2; Codex accepted every R2 rebuttal and produced clean DECISIONs._

---

## Round 3 — reviewing agent (critique)

_Not used._

---

## Synthesis

**Resolution:** converged

**Proposed spec changes** (all folded into `spec.md` at scaffold time):

- § Intent — one `/video`, required `--mode=code|generative`, two disjoint modes; ships mechanisms not frozen stack opinions.
- § Acceptance criteria — `--mode` required no-default; multi-runtime canonical+symlinks+`openai.yaml`; code mode = pinned npm engine + owned authoring + tracked source / ignored MP4 / fingerprint-in-manifest; generative = REST queue submit/poll **ledger async** + `--confirm-cost-usd` gate + refreshable `video-tiers.yaml`; zero-cost-if-unused + clean dependency errors; shared `fal-rest.sh`; declared `agentskills-portable`.
- § Non-goals — no general video studio; **no drift-checker in v1**; no `/image` refactor (decoupled follow-up + stale-docs fix); no `/product`/`/prototype` coupling; Higgsfield not foundation; no per-session budget enforcement.
- § Open questions — HyperFrames version pin; seed tier set/models; ledger location + poll UX; estimate-vs-actual cost reconciliation; storage roots.

**Unresolved disagreements:** none — full convergence.

---

## Applied changes

- `docs/specs/132-video-skill/spec.md` — authored from this debate; every § Acceptance criterion and § Non-goal traces to a Round-2 `DECISION:`. Status: draft, ready for `/sdd plan`.
- Follow-up flagged (NOT in this spec): a decoupled spec to migrate `/image` onto `.agent0/tools/fal-rest.sh` and fix the stale MCP-delegation wording in `/image`'s SKILL.md frontmatter (Codex catch, R1 round-1 point 2).
