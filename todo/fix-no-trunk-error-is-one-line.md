# fix: the no-trunk error is one line

- **Priority:** medium
- **Touches:** lib/common.sh test/first-run.sh
- **Blocked by:** —

## Goal
With no trunk checked out anywhere, a verb that needs one dies with exactly:
`aih: there are no active trunks for this project; run aih init to create one.`

## Why
Today it prints two lines, "this branch (main) does not have an active aih
trunk." then "No active aih trunk on this machine; run aih init to create
one." The second says everything the first does. Errors are one line.

## Notes
`ai_harness_die_no_active_trunk` in `lib/common.sh` builds `_dnt_m` (the
branch line) before the `case`, then appends the no-trunk line in the `''`
arm. Make the `''` arm die with the new sentence alone and nothing else;
the one-trunk and several-trunks arms keep their text, since there the
branch line is what the redirect hangs off.

`test/first-run.sh` asserts the old wording at lines 70, 73, 97-101 and 114
(the `says` calls for `status`, `run --all`, `integrate --next`,
`dispatch reviewer`). Update them to the new sentence; the line-122 case
is the one-trunk arm and stays.

Run `sh test/first-run.sh` yourself: it is the `firstrun` gate and the
only behaviour test, and `aih gate --quick` does not run it.

## Done when
- [ ] `aih status` on `main` with no trunk worktree prints the one line above and nothing else on stderr
- [ ] `sh test/first-run.sh` passes with the updated assertions
- [ ] `aih gate` passes
