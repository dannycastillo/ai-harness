# feat: a run is the set present when it starts

- **Priority:** high
- **Touches:** verbs/run.sh, lib/run.sh, lib/graph.sh, lib/render.sh, verbs/plan.sh, roles/protocol.md, README.md
- **Blocked by:** —

## Goal
`aih run --all` works the todos that are in `todo/` when it starts, and a
todo that appears later is outside that run: never claimed by its loop,
listed under `outside this run` by `aih status`, and worked by the next run.

## Why
`--all` empties the run set, and an empty set means the loop re-reads
`todo/*.md` on every tick. On 2026-09-28 a worker filed a todo into `todo/`
on its branch, `integrate` merged the branch, and seven seconds later the
same loop claimed the new todo, unreviewed. Every verb did what it was built
to do; the hole is that the run's membership was a live query rather than
a set. `todo/new/` (adr-2026-09-27-todo-new-is-the-inbox) closes the path
agents are told to use; this closes the one the loop can still take. It
also makes `plan` and `status` agree on `(Total: N)`, which today count
different things for an `every todo` run.

## Notes
- `verbs/run.sh`: `--all` writes the stems of `todo/*.md` present at start
  (README excluded, one per line) into `run/set` instead of truncating it.
  A bare `aih run` reuses the last set as it does now. Explicit stems are
  unchanged.
- `lib/graph.sh`, `ai_harness_plan`: the empty-set-means-everything branch
  stays for `aih plan` with no arguments, which shows the whole backlog. The
  loop just stops passing an empty set.
- `lib/render.sh`, `ai_harness_render_run_stems`: the "every todo, plus
  whatever merged since the start" query is no longer needed once the set
  is explicit; the set file is the run. `ai_harness_run_set_names` prints
  the names, so a large `--all` run gets a long first line; `every todo
  (Total: N)` may stay as the wording when `--all` took the set, with a
  marker of the worker's choosing under `run/`.
- `roles/protocol.md` and `README.md`: a run is a set fixed at start; work
  filed during a run waits for the next one.
- `lib/run.sh`'s loop body, timeouts, dispatch and judge are not this
  todo's. If the change reaches them, say so.

## Done when
- [ ] with `todo/fix-a.md` and `todo/fix-b.md` present, `aih run --all --once` writes both stems to `run/set`
- [ ] a todo added to `todo/` on the trunk while a `--all` loop runs is never claimed by that loop, and `aih status` shows it under `outside this run`
- [ ] `aih plan` and `aih status` print the same `(Total: N)` for the run
- [ ] `aih run --all` on an empty `todo/` prints its report and exits 0
- [ ] `test/render-fixture.sh` output is unchanged
- [ ] `aih gate` passes
