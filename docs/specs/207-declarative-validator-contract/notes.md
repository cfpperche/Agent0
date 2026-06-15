# 207 — declarative-validator-contract — notes

## Design decisions

### 2026-06-15 — parent — Declarative file takes hard precedence

If `.agent0/validator.json` exists, the validator does not run stack fallback. This is intentionally stronger than "merge declared commands with inferred commands": a malformed or incomplete repo-owned contract should be visible, not hidden behind guessed stack behavior. Invalid or empty configs return JSON `ok:false` with `validator-config-advisory:`.

## Deviations

## Tradeoffs

### 2026-06-15 — parent — Fallback retained for compatibility

The stack detector remains when `.agent0/validator.json` is absent. This keeps older consumers working while shifting the recommended contract to repo-owned commands. Removing fallback entirely is a future migration, not part of this spec.

## Open questions
