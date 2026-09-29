# feat: the todo directory is configurable

- **Priority:** medium
- **Touches:** lib/todo.sh, lib/graph.sh, lib/check.sh, verbs/claim.sh, verbs/abandon.sh, verbs/path.sh, verbs/dispatch.sh, verbs/log.sh, verbs/run.sh, verbs/plan.sh, verbs/status.sh, verbs/check.sh, verbs/init.sh, templates/ai-harness.conf, README.md, roles/protocol.md
- **Blocked by:** —

## Goal
`AI_HARNESS_TODO_DIR` in `.ai-harness.conf` names the backlog directory.
Unset, it is `todo`.

## Why
"Where the todo list exists" was one of the five knobs in the original
vision, and the only one that never got built. `todo/` is hard-coded in
eleven files. A repo that already has a `todo/` for something else, or
wants `backlog/`, cannot use the harness.

## Notes
- One accessor: `ai_harness_todo_dir` in `lib/todo.sh`, and
  `ai_harness_todo_file` built on it. Every `todo/` in `lib/` and `verbs/`
  goes through them; `grep -rn 'todo/' lib verbs bin` should then find
  only comments and the `check` selftest.
- Relative to the repo root, no trailing slash. Reject an absolute path
  and anything containing `..`.
- The `AI-Harness-Todo:` trailer records the real path, and `log` parses
  whatever directory it finds there, so old trailers still read.
- The `check` selftest in `verbs/check.sh` writes its fixtures under the
  configured directory.
- `init` writes the README into the configured directory, and the config
  template documents the knob in one line.
- The protocol says "the todo directory" where it now says `todo/`.

## Done when
- [ ] `grep -rn 'todo/' lib verbs bin` matches only comments and the `check` selftest
- [ ] in a scratch repo with `AI_HARNESS_TODO_DIR="backlog"` and one todo under `backlog/`, `./bin/aih plan` lists it as runnable and `./bin/aih claim` cuts its worktree
- [ ] `./bin/aih check --selftest` passes
- [ ] `templates/ai-harness.conf`, `README.md` and `roles/protocol.md` name the knob
- [ ] `aih gate` passes
