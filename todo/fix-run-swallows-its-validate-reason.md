# fix: run swallows its validate reason

- **Priority:** low
- **Touches:** verbs/run.sh
- **Blocked by:** —

## Goal
`aih run <bad-stem>` names the actual reason a stem doesn't validate — a
nested todo, a bad prefix, a bad Priority or Touches — the same reason
`claim` and `dispatch worker --print` already show.

## Why
Noticed while wiring `todo/new/` as the inbox (feat/todo-new-is-the-inbox):
`claim` and `dispatch worker --print` both surface `ai_harness_todo_validate`'s
specific `warn()` — including the new "in todo/<dir>/, not ready: git mv ..."
message for a filed-but-not-promoted todo. `run` does not, and never did:
`verbs/run.sh:24` redirects the validate call's stdout *and* stderr to
`/dev/null`, then dies with a generic `run: no such todo: <stem>` regardless
of why validation actually failed. Out of scope for that branch (`verbs/run.sh`
was deliberately left out of its Touches), so filing it here instead.

## Notes
- `lib/todo.sh`'s `ai_harness_todo_validate` already `warn()`s the specific
  reason before returning 1; `verbs/claim.sh` and `verbs/dispatch.sh` let it
  reach stderr, `verbs/run.sh` alone discards it.
- Likely fix: drop the `>/dev/null 2>&1` on `verbs/run.sh:24`, or capture and
  re-`warn` the reason before the generic `die`.

## Done when
- [ ] `aih run <nested-stem>` prints the same `git mv` message `aih claim` does
- [ ] `aih run <stem with a bad Priority or Touches>` prints that reason
      instead of a generic "no such todo"
- [ ] `aih gate` passes
