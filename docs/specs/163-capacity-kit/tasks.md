# 163 — capacity-kit — tasks

_Generated from `plan.md` on 2026-06-06. Work top-to-bottom. Behavior-preserving refactor — the golden gate is built BEFORE the change._

## Implementation

- [x] 1. **Golden parity harness** (`.agent0/tests/capacity-kit/golden.sh capture|verify`) — captures each tool's deterministic **plumbing surface** (`caps`/`doctor`/`--help`/usage/bad-flag — exactly what the kernel owns), normalizing repo-abs-path + temp dirs. (The deep engine paths — `--json` success/error/unavailable — stay covered by each tool's own offline suite; golden + suite together are the gate.) Baselines captured BEFORE extraction for audio/sound/transcribe/diagram.
- [x] 2. **Kernel** `.agent0/tools/lib/capacity.sh` — verbatim funcs (`cap_have`, `cap_sha256_str`, `cap_sha256_file`, `cap_emit_exit`) + parameterized mechanics (`cap_manifest_append <path> <line>`, `cap_fail` with a manifest-hook, `cap_resolve_ffmpeg <env-name>`, `cap_redact`). Small, flat, readable.
- [x] 3. **Migrate `diagram.sh` first** (smallest) — source the kit + missing-kit guard; delete its local copies; keep tool-specific logic. Prove: `tests/diagram/run-all.sh` green AND golden `verify` clean for diagram.
- [x] 4. **Migrate `transcribe.sh`, `audio.sh`, `sound.sh`** — same; reconcile transcribe's `emit_exit`/`resolve_ffmpeg` variants to the kernel (or a compatible form) under the parity gate.
- [ ] 5. **Paid sub-kit** `.agent0/tools/lib/paid-media.sh` — **DEFERRED to a follow-up** (separable, smaller win; ~2 first-class tools today). Scoping the solo pass to the kernel kept the blast radius bounded. `pm_tier_get`/`pm_tier_top`/`pm_fal_key_state`/`pm_cost_print`/`pm_confirm_gate`/`pm_fal_run` + migrating audio-remote/sound/image/video paid lanes = the next pass.
- [x] 6. **Sync fix + test** — add `.agent0/tools/lib|*.sh` to `COPY_CHECK_GLOBS`; add `.agent0/tests/capacity-kit/sync-propagation.sh` asserting `lib/capacity.sh` + `lib/paid-media.sh` reach a synced consumer; add a missing-kit-guard test.
- [x] 7. **Rule + index** — `.agent0/context/rules/capacity-kit.md` (kit contract + local-acquisition template + "7th tool as config" guide); `CLAUDE.md`+`AGENTS.md` `## Capacity kit` line.

## Verification (the squad done-gate)

- [x] All 5 suite-backed `run-all.sh` suites green
- [x] `golden.sh verify` clean for every migrated tool (zero behavior change)
- [x] sync-propagation test green (lib reaches consumer); missing-kit guard test green
- [x] `bash -n` clean on every tool + lib; `doctor.sh` green; `/skill validate` exit 0 for touched skills
- [x] `bash .agent0/validators/run.sh` clean

## Notes

- Order is gate-first: capture golden baselines BEFORE any extraction so "zero behavior change" is verified.
- `image` has no `run-all.sh` suite → migrate it last + carefully (live smoke), or defer to a follow-up; the paid sub-kit doesn't require image to land in v1.
- Built via `/squad` (Claude ↔ Codex), externally closed by the gate above.
