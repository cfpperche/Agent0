# 165 — cross-dir-capacity-sourcing — notes

_Created 2026-06-07._

_In-flight design memory for this spec._

## Design decisions

### 2026-06-07 — parent — The "cross-dir cable" the 164 minority report feared was already built
The headline measurement: both `video` and `image` gen.sh ALREADY set `PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel)}"` and ALREADY cross into `tools/` (they invoke `$PROJECT_DIR/.agent0/tools/fal-rest.sh`). So reaching into `tools/lib` is not a new pattern — the only delta is *sourcing* a lib (functions into the shell) vs *invoking* a tool. The 164 reopen-trigger was honest to defer (it named a real un-validated bit) but the bit turned out small. `$PROJECT_DIR` is the right anchor — no `../../../`.

### 2026-06-07 — parent — Lazy-load inside paid subcommands, NOT file-top (Codex's opening catch)
sound/audio source the kernel at file-top because they're paid from the first line. video/image have NON-paid lanes (`--help`/`noargs`/`record`) that work today with no lib. A file-top source would make `--help` fail (exit 70) when the lib is absent — a behavior change. So a `load_paid_media` guard is called at the TOP of each paid subcommand only (video `prepare`/`submit`/`poll`; image `prepare`/`exec`). Verified: `staleness_advisory` (uses `yaml_top`→`pm_yaml_top`) is only reached from inside `sub_prepare`, after the load.

### 2026-06-07 — parent — image stays a pipe-table (the anti-punt judgment, answered head-on)
The founder explicitly warned against rationalized punts. The falsifiable test applied: does THIS work leave an image loose end? No — image adopts `pm_has_fal_key` (the shared bit it can use); converting its pipe-`TIER_TABLE` to YAML would CREATE a new oracle file + docs + tests, not RETIRE any duplication this pass introduces (~zero dedup value: one tool, one table). So image is left with zero loose ends; the pipe-table predates this work and survives intact. Not a punt — a scope boundary the founder's own "don't import adjacent refactors" rule draws.

## Deviations

### 2026-06-07 — parent — 5 existing tests gained lib-provisioning in their temp CLAUDE_PROJECT_DIR fixture
`video/02` + `image-gen/01-04` set `CLAUDE_PROJECT_DIR=<temp>` and run `prepare`. After migration, `prepare` lazy-loads `$PROJECT_DIR/.agent0/tools/lib/paid-media.sh` — absent in the bare temp → exit 70. This is the INTENDED new fail-clean behavior (the smoke test asserts it). The fix is to provision the lib in each temp fixture (`cp` the real lib into `$CLAUDE_PROJECT_DIR/.agent0/tools/lib/`), exactly as a real project has it — completing the fixture for the new dependency, not masking a regression. (Codex confirmed this is legitimate.)

## Tradeoffs

### 2026-06-07 — parent — Codex adversarial review caught a weak test + stale docs (FIX-FIRST)
The runtime migration was clean on first review, but Codex flagged two real Medium issues, both fixed: (1) the consumer-root smoke lane copied the REAL lib and only asserted `rc != 70` — so a regression to repo-root sourcing would still pass when run from the Agent0 repo. Fixed with an **observable sentinel** lib (its `pm_has_fal_key` emits a unique marker; the lane asserts the marker appears → proves the *consumer* lib was sourced, catches the regression). (2) `capacity-kit.md`/`CLAUDE.md`/`AGENTS.md` still said image-out / video-reopen-trigger — updated to the 165 reality + reopen-trigger CLOSED. Same value as 164's review (golden hermeticity): the second model catches what the author's own gate doesn't.

## Open questions

_None — all 3 spec OQs resolved in the meeting._

---

**Gotchas worth remembering:**
- **A skill-dir tool sourcing `tools/lib` needs the lib at `$PROJECT_DIR` — tests that point `CLAUDE_PROJECT_DIR` at a bare temp must provision it** (else the paid path exits 70). This is now the pattern for any future skill-dir kit consumer.
- **The smoke test's consumer-root proof must be OBSERVABLE** (a sentinel marker), not just "didn't exit 70" — else it can't distinguish consumer-root from repo-root sourcing.

**Build outcome:** `load_paid_media` (lazy) added to video + image; video reader → `pm_yaml_*` binders (byte-identical proven); FAL_KEY checks → `pm_has_fal_key || die_no_fal_key` (3 video + 2 image); new `tests/capacity-kit/cross-dir-source.sh` (8 lanes, observable sentinel); 5 fixtures provisioned. Docs (capacity-kit.md/CLAUDE.md/AGENTS.md) updated, 164 reopen-trigger CLOSED. **Gate GREEN 11/11, zero behavior change** (video/image `--help`/`noargs` byte-identical; sound/audio golden untouched). Meeting `.agent0/meetings/cross-dir-capacity-sourcing-2026-06-07T13-27-06Z/`.
