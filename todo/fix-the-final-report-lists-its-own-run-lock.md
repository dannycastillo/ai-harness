# fix: the final report lists its own run lock

- **Priority:** high
- **Touches:** lib/render.sh
- **Blocked by:** —

## Goal
The status the loop prints as it exits ends with the todo table, not with a
`lock run` line naming the loop's own pid.

## Why
`verbs/run.sh` prints `ai_harness_render_status` before its EXIT trap
releases the run lock. The lock section of `ai_harness_render_status` hides
the run lock only while `ai_harness_run_live_pid` says its holder is alive,
and that function ignores `$$` on purpose so the loop never reports itself
as alive. From inside the loop the lock therefore reads as unheld and is
listed. Seen on 2026-09-27 at the end of a clean run:

```
lock run held by run pid 50829 on Ruths-MacBook-Air.local since 2026-09-27T02:03:40Z (302s)
```

A reader takes that for a stale lock and may `aih unlock run --force` a loop
that has already let go. Earlier runs' footers never carried the line; it
arrived with the shared render library.

## Notes
- `lib/render.sh`, the loop over `lock/*` at the end of
  `ai_harness_render_status`: skip the run lock when its holder is `$$` as
  well as when it is alive. `ai_harness_run_holder_pid` in `lib/run.sh`
  reads the holder.
- Keep `ai_harness_run_live_pid` as it is: the `loop` line relies on it
  ignoring `$$`.
- `test/render-fixture.sh` never runs status from inside a loop, so it
  cannot see this. Check it by hand: a run over an empty backlog prints its
  report in a few seconds.
- Mechanics stay untouched: `lib/run.sh`'s loop and `verbs/run.sh` are not
  in Touches.

## Done when
- [ ] the report `aih run --all` prints on exit has no `lock run` line
- [ ] `aih status` from another shell still hides the run lock while a loop is alive, and still lists it when the holder is dead
- [ ] `test/render-fixture.sh` output is unchanged
- [ ] `aih gate` passes
