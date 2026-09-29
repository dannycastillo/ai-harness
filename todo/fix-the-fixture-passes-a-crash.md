# fix: the fixture passes a crash

- **Priority:** medium
- **Touches:** test/render-fixture.sh
- **Blocked by:** —

## Goal
`test/render-fixture.sh` exits nonzero, and says which section, when `plan`
or `status` exits nonzero in a section where it must succeed.

## Why
The fixture is a before/after diff with no assertions. Section G, the empty
backlog, has had `status` crash with `rc=1` in its output since the render
library landed (a zero-match `grep -c` under `set -e`, fixed in 519544a),
and every before/after diff matched because the crash repeated itself
identically. A recorded `rc=1` that nobody reads is not a record. The
fixture already prints `rc=N` when a verb fails; it needs to count them and
fail.

## Notes
- `both()` in `test/render-fixture.sh` prints `rc=$?` on a nonzero exit.
  Keep that in the output, since the diff should still show where a crash
  moved, and also count it: a variable bumped in `both()`, printed as a
  last line `crashes: N`, with `exit 1` when N is not 0.
- Section D runs `plan` with explicit stems during a live loop and prints
  `rc=` on purpose if `plan` refuses; decide whether that section is
  expected to exit 0 and either exclude it from the count or assert its
  exact code. Say which in the header comment.
- The header comment says "No assertions"; it stops being true. Rewrite it:
  diff the output for wording, and the exit status says whether any verb
  crashed.
- POSIX sh only, bash 3.2 clean. The fixture runs from any directory; keep
  the `AIH` and `pwd -P` handling as it is.

## Done when
- [ ] with a deliberate crash in one section, the fixture prints `crashes: 1` naming the section and exits 1
- [ ] on the current trunk the fixture prints `crashes: 0` and exits 0
- [ ] the diffable output above the last line is unchanged from today's, apart from that line
- [ ] `aih gate` passes
