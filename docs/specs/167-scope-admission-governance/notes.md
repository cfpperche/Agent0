# 167 - scope-admission-governance - notes

## Design decisions

### 2026-06-07 - parent - Rule-only first

Scope admission is being formalized as a rule, not a hook or validator. The prior doctrine established the need for explicit admission discipline, but did not establish repeated failure to follow it.

### 2026-06-07 - parent - SDD pointer, not template section

The SDD rule should point Agent0 capacity-expansion specs to scope admission. The default `spec.md` template should not grow a mandatory section yet because many specs are not capacity proposals.

## Deviations

None.

## Tradeoffs

### 2026-06-07 - parent - Safety exception allowed

The rule-of-three posture needs an exception for narrow safety fixes. A single severe security or data-loss incident can justify immediate action, but the fix must stay narrow and avoid becoming a broad platform build.

## Open questions

None for this spec. The template/registry questions remain in `spec.md` as follow-up triggers.
