# fix: run report crashes on an empty backlog

- **Priority:** high
- **Touches:** lib/render.sh
- **Blocked by:** —

## Goal
`aih run --all` over a backlog with zero todos prints its final report and
exits 0, instead of exiting 1 with nothing printed.

## Why
`ai_harness_render_run` counts the set's rows with:

```sh
_st_rows=$(printf '%s\n' "$1" | ai_harness_render_rows "$(ai_harness_run_plan)")
_st_count=$(printf '%s\n' "$_st_rows" | grep -c .)
```

When `$1` (the run's stems) is empty, `_st_rows` is empty, and
`printf '%s\n' "" | grep -c .` matches zero lines. `grep -c` exits 1 when the
count is zero, and that assignment is a plain statement under `bin/aih`'s
`set -eu`, so the whole `aih` process exits right there — before
`ai_harness_render_status` prints anything. `verbs/run.sh` never gets to its
final `ai_harness_render_status >&2`.

Seen by hand: `aih init` in a repo with an empty `todo/`, then
`aih run --all` — it prints `run: working every todo` and exits 1 with no
report at all.

## Notes
- The same pattern appears once more, in the "outside this run" branch of
  `ai_harness_render_status`, but that call is only reached when its input
  is non-empty (`if [ -z "$_st_out" ]; then ... else ... fi`), so it cannot
  hit this.
- `ai_harness_run_set() { cat ... 2>/dev/null || : ; }` in `lib/run.sh` is the
  existing idiom in this codebase for neutralizing a command's exit status
  when only its stdout is wanted.

## Done when
- [ ] `aih run --all` in a repo with an empty `todo/` prints the run report
  and exits 0
- [ ] `test/render-fixture.sh` output is unchanged
- [ ] `aih gate` passes
