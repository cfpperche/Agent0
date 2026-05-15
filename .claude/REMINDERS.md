# Reminders

- Fair OD re-match for spec 027 — the blind-judge result (3.87 vs 4.73) is confounded (1 OD pass vs 4 refined iterations). To measure 027 honestly: either iterate the OD run to 4 passes, or re-judge it against the first-pass baseline. See .claude/memory/od-grounding-dogfood.md § Pointers.
- Test the first real OD --bump/--apply against upstream — network-bound, still untested. --check already confirms drift (upstream HEAD 75498838 ≠ pin d25a7aaf). See scripts/sync-open-design.ts + docs/specs/027-od-vendor-port/.
