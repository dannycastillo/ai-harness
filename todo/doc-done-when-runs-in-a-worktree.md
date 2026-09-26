# doc: a Done-when box must be checkable from a worktree

- **Priority:** medium
- **Branch:** doc/done-when-runs-in-a-worktree
- **Touches:** AGENTS.md
- **Blocked by:** —

## Goal
AGENTS.md says that every Done-when box is checkable from the worker's worktree, and that a box needing the trunk checkout is a human's and says so.

## Why
The first unattended run parked `chore-strip-dead-code` `needs-human`: its box
"`aih run --once` still ends with the run-set report" can only run in the
trunk checkout, and the loop that dispatched the reviewer held the run lock.
The reviewer did the right thing. The todo author had no rule telling them the
box could never be verified by an agent.

## Notes
- The rule goes under **Done when** in the Todo section of `AGENTS.md`
  (around line 319, "Done when is the contract"), not in the checksummed
  `<!-- ai-harness:begin -->` block. Editing inside that block means
  updating its `cksum` or `doctor` fails.
- `AGENTS.md` is in `AI_HARNESS_PROTECTED`, so this parks for a human to
  merge by hand. Expected.
- Verbs that only run in the trunk checkout today: `run`, `integrate`,
  `dispatch reviewer`. `gate`, `check`, `plan`, `status` run anywhere.
- Say what a box that cannot be met from a worktree should look like:
  prefixed `human:` or rewritten as a static property of the diff.

## Done when
- [ ] AGENTS.md's Done-when guidance states that a box is checked from the worker's worktree
- [ ] it names the verbs that only run in the trunk checkout as the ones a box must not depend on
- [ ] `aih doctor` still reports the ai-harness block intact
- [ ] `aih gate` passes
