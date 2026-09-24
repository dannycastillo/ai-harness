# chore: run the gate in CI

- **Priority:** medium
- **Branch:** chore/add-ci
- **Touches:** NEW .github/workflows/*
- **Blocked by:** —

## Goal
Every push and pull request runs `aih gate` on macOS and Linux.

## Why
wut-command's CI ran the Go toolchain and didn't come across in the split, so
the harness now has no check outside a local `aih gate`.

## Notes
- The gates are `shellcheck` and `shellsize` (`.ai-harness.conf`).
  `shellcheck` must be installed on the runner. ubuntu-latest has it; macOS
  needs `brew install shellcheck`.
- `.github/workflows/*` is in `AI_HARNESS_PROTECTED`, so `check` stops on this
  todo's diff and a human merges it.
- ADR-05 in wut-command limits it to macOS and Linux.

## Done when
- [ ] a workflow runs `ai-harness/bin/aih gate` on ubuntu-latest and macos-latest
- [ ] it passes on the pull request that adds it
- [ ] `aih gate` passes
