# Reminders

- validator (.claude/validators/run.sh) detects bun.lockb (binary) but Bun 1.3+ emits text-based bun.lock — add bun.lock to the bun-stack guard alongside bun.lockb so future forks don't need to commit a bunfig.toml just to be detected
