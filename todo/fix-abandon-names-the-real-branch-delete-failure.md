# fix: abandon names the real reason a branch was not deleted

- **Priority:** low
- **Touches:** verbs/abandon.sh
- **Blocked by:** —

## Goal
`aih abandon` says why `git branch -d` failed, and says nothing about the
branch when the branch does not exist.

## Why
On 2026-10-01 two parked branches were merged on GitHub with
`gh pr merge --merge --delete-branch`, which also removed the local
branches. `aih abandon <stem>` on each then printed
`holds unmerged commits — kept. --force deletes it` although there was no
branch to keep. `verbs/abandon.sh` line 64 treats any non-zero exit from
`git branch -d` as "unmerged"; a missing branch, or one still checked out
in another worktree, gets the same wrong sentence and sends the user to
`--force` for nothing.

## Notes
- `verbs/abandon.sh` lines 63 to 71. Before the delete, test
  `git show-ref -q --verify "refs/heads/$_branch"`; if absent, skip the
  delete silently, or log one line that the branch is already gone.
- Capture `git branch -d`'s stderr and print it in the warning instead of
  guessing the cause. Git's own messages already distinguish "not fully
  merged" from "checked out at <path>".
- Keep the `--force` hint only for the not-fully-merged case, where
  `branch -D` is what `--force` does.
- `test/first-run.sh` has no abandon scenario; a case there is welcome but
  not required for this fix.

## Done when
- [ ] `aih abandon <stem>` after the branch was deleted elsewhere releases the claim without mentioning unmerged commits
- [ ] when `git branch -d` refuses, the warning carries git's reason
- [ ] `aih gate` passes
