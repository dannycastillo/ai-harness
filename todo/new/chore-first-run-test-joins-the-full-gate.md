# chore: first-run test joins the full gate

- **Priority:** medium
- **Touches:** .ai-harness.conf, test/first-run.sh
- **Blocked by:** —

## Goal
`aih gate --full` runs `test/first-run.sh`, so a behaviour break in the
launcher or a verb fails at `submit` and at merge instead of after the
merge, on the loop's next tick.

## Why
On 2026-09-30 d1b3053 merged green and broke every `dispatch reviewer`
with `_wt: unbound variable`. The gate is shellcheck and shellsize, and
neither can see a variable assigned in one `case` arm and read after
another. `test/first-run.sh` exercises init, the trunk redirects, the
push and now a real reviewer dispatch, and takes about ten seconds. The
loop running live trunk code is the backstop by design; the gate is
where the break should stop first.

## Notes
- `.ai-harness.conf`: add `firstrun` to `AI_HARNESS_GATES` only, not to
  `AI_HARNESS_QUICK_GATES`; ten seconds is fine before a submit and a
  merge, not before every commit. Define
  `ai_harness_gate_firstrun() { sh test/first-run.sh; }` beside the other
  two, and `AI_HARNESS_GATE_TOOLS_firstrun="sh git"`.
- `.ai-harness.conf` is always a protected path, so a worker branch that
  edits it parks `protected-path`. Either the maintainer makes the conf
  change by hand on the trunk and the todo shrinks to whatever the test
  file needs, or the branch parks on purpose and a human merges it. Say
  which in the submit body.
- `test/first-run.sh` prints one line per case and exits non-zero on a
  failure; check its output shape reads well under the gate's one-line
  result format, and quiet anything that only a human reading it
  directly needs.
- The test builds throwaway repos under `mktemp -d`; confirm it leaves
  nothing behind on failure, since the gate will now run it in every
  worker's worktree and on the trunk after each merge.
- Measured 2026-09-30: `real 9.79s` on this machine with seven cases.

## Done when
- [ ] `aih gate --full` lists a `firstrun` line and is green
- [ ] `aih gate --quick` does not run it
- [ ] a deliberately broken `verbs/dispatch.sh` (drop the `_wt=$AI_HARNESS_REPO` line in the reviewer arm) makes `aih gate --full` red on the `firstrun` line
- [ ] `aih doctor` reports the gate runnable
- [ ] `aih gate` passes
