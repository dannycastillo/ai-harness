# chore: drop claim --scratch

- **Priority:** low
- **Branch:** chore/drop-claim-scratch
- **Touches:** ai-harness/verbs/claim.sh
- **Blocked by:** —

## Goal
`claim` only claims todos.

## Why
`--scratch` wraps one `git worktree add --detach`, and no verb removes the
tree it makes, so a second use by the same agent fails. `roles/reviewer.md`
now gives the two git commands directly.

## Notes
- `verbs/claim.sh`: the option, the `_scratch` variable and branch, and the
  usage line.
- `lib/state.sh` mentions scratch trees only to explain why detached
  worktrees are skipped; that stays true.

## Done when
- [ ] `aih claim --scratch` fails as an unknown option
- [ ] `grep -rn 'scratch' ai-harness/verbs` prints nothing
- [ ] `aih gate` passes
