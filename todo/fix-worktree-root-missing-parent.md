# fix: name the missing directory in a bad worktree root

- **Priority:** medium
- **Branch:** fix/worktree-root-missing-parent
- **Touches:** ai-harness/lib/common.sh, ai-harness/verbs/claim.sh, ai-harness/verbs/doctor.sh, ai-harness/lib/state.sh
- **Blocked by:** —

## Goal
A worktree root whose parent does not exist fails with a message naming that parent.

## Why
`ai_harness_worktree_root` normalizes the parent with a `cd` inside `$(...)`.
When the parent is missing, the `cd` fails, the substitution is empty, and the
root becomes `/<leaf>`. `doctor` then reports "/ is not writable", and `claim`
fails on a path nobody configured.

## Notes
- `lib/common.sh`, `ai_harness_worktree_root`. Libraries only define functions.
- Callers: `claim`, `doctor`, `lib/state.sh` (`ai_harness_state_repair`).
  Each must stop, not continue with an empty root.

## Done when
- [ ] with `AI_HARNESS_WORKTREE_ROOT="../no-such-dir/trees"`, `aih doctor` names `../no-such-dir` (resolved) as missing
- [ ] with the same setting, `aih claim` fails before creating any branch
- [ ] `aih gate` passes
