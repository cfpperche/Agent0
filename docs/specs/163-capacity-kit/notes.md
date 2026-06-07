# 163 — capacity-kit — notes

_Created 2026-06-06._

_In-flight design memory — decisions, deviations, tradeoffs surfaced while building._

## Design decisions

### 2026-06-06 — parent — Manifest HOOK resolves the fail↔manifest coupling
The central design call. `cap_fail` calls an optional `_cap_on_fail <status>` the tool defines (its own `append_manifest`), which routes the append through `cap_manifest_append`. Manifest *schema* stays in the tool; *mechanics* (mkdir + one-line append) in the kernel. Clean, and behavior-identical (proven by golden).

### 2026-06-06 — parent — `cap_manifest_append` does NOT guard on jq (the caller does)
First draft put a `cap_have jq || return 0` guard in the kernel append. But transcribe had a **no-jq fallback** manifest line — the kernel guard would have silently dropped it (a latent behavior change in the no-jq edge). Fix: the kernel append only does `[ -n "$line" ] && mkdir && append` (empty line = no-op); the *caller* owns the jq decision. Preserves every tool's existing manifest behavior.

### 2026-06-06 — parent — Extract only byte-identical-or-cleanly-parameterized; keep variants local
Per-tool reality (measured): `have`/`emit_exit`/`sha256_str` are verbatim-identical → kernel. But `fail`'s JSON differs: diagram/sound emit compact `{status,message}` (= kernel `cap_fail`); **transcribe** emits rich `{status,input,message,outputs}` and **audio** emits *pretty* (`jq -n`) — both keep a **local `fail`** (still using `cap_emit_exit`+`cap_manifest_append`). Forcing them onto `cap_fail` would change `--json` error output = a behavior change the refactor forbids. The audio pretty-vs-compact inconsistency is pre-existing → a separate intentional follow-up, not normalized here.

## Deviations

### 2026-06-06 — parent — Paid-media sub-kit DEFERRED (kernel-only solo pass)
Plan scoped kernel + paid sub-kit. Founder chose solo completion (option c) over the `/squad` loop after turn-1 proved the pattern. To bound the blast radius in one pass, shipped the **kernel across all 4 `.agent0/tools/` capacity tools** (the bulk of the duplication + where both historical bugs lived) and **deferred** `lib/paid-media.sh` (tier-oracle reader + cost gate + fal wrapper; only ~2 first-class tools today) to a follow-up. squad.json gate trimmed to match. image/video (skill-dir tools, image has no run-all suite) also deferred.

### 2026-06-06 — parent — Golden scoped to the plumbing surface, not engine paths
`golden.sh` captures caps/doctor/--help/usage/bad-flag (deterministic, exactly the kernel's surface). The `--json`/error/unavailable engine paths stay covered by each tool's offline suite. Golden + suites together = the behavior gate. (A full engine-path golden would need each tool's fakes — redundant with the suites.)

## Tradeoffs

### 2026-06-06 — parent — Solo over /squad (founder choice)
The `/squad` turn-1 (claude) built golden+kernel+diagram byte-identical, then founder chose solo finish — faster than the ping-pong, no Codex cross-review of the interface. Mitigated: the golden+suite+sync gate is the external closer regardless of who wrote it; the interface (manifest hook) was already cross-pressured in the graduating meeting. The squad run was aborted cleanly (turn-1 work kept); squad.json stayed as the done-checklist.

## Open questions

_None outstanding — all 4 spec OQs resolved (see spec.md)._

---

**Gotcha worth remembering:** tools that print `--help` via `sed -n 'A,Bp' "$0"` print a fixed line range of their OWN source — inserting the kernel `source` inside that range drifts `--help`. audio hit this (help range 3-30, HERE at 27); fixed by sourcing **below** the help range (before first `cap_` use). diagram/sound/transcribe were unaffected (their inserts fell outside the range).

**Build outcome:** kernel `lib/capacity.sh` (+ tests `golden.sh`/`sync-propagation.sh`/`missing-kit-guard.sh`) extracted; audio/sound/transcribe/diagram migrated. **Gate GREEN:** 5 suites + golden parity (caps/doctor/help/usage/badflag byte-identical, before vs after) + sync-propagation + missing-kit-guard + `bash -n` + doctor (22 ok/0/0) + validator exit 0 + harness-sync suite all-pass. Zero behavior change. Sync glob `.agent0/tools/lib|*.sh` added (managed-block literal retired). Consumer-facing → founder-triggered harness-sync.
