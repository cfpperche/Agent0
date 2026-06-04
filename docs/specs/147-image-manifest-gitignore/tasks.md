# 147 — image-manifest-gitignore — tasks

_Generated from `plan.md` on 2026-06-04. Work top-to-bottom. Check boxes as tasks complete. If a task reveals the plan is wrong, update `plan.md` before continuing._

## Implementation

- [x] 1. Add `assets/generated/.manifest.jsonl` to Agent0 `.gitignore`.
- [x] 2. Update image-generation docs and skill text to call the manifest gitignored local audit state.
- [x] 3. Remove `assets/generated/.manifest.jsonl` from the Agent0 git index without deleting the local file.
- [x] 4. Sync the updated harness policy to consumers.

## Verification

- [x] `git check-ignore -v assets/generated/.manifest.jsonl` matches Agent0 `.gitignore`.
- [x] `git status --short -- assets/generated/.manifest.jsonl` no longer shows an untracked file in Agent0; the pending index deletion is intentional.
- [x] `git check-ignore -v assets/generated/.manifest.jsonl` matches in `/home/goat/ag-antecipa`.
- [x] `git check-ignore -v assets/brand/example.png` does not match in Agent0.
- [x] Relevant shell scripts still pass syntax/test checks.

## Notes

- Validation: image-gen tests 4/4, multi-runtime-skills 9/9, harness-sync 40/40, `bash -n` clean for `gen.sh` and `sync-harness.sh`.
- Consumer sync: `assets/generated/.manifest.jsonl` is ignored in cognixse, mei-saas, tese, and ag-antecipa. Some sync runs exited 1 due unrelated customized managed files, but the target `.gitignore` policy applied and verified.
