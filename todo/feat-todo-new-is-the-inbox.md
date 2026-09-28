# feat: todo/new is the inbox

- **Priority:** high
- **Touches:** lib/graph.sh, lib/todo.sh, verbs/claim.sh, verbs/plan.sh, verbs/init.sh, roles/protocol.md, roles/worker.md, templates/todo-README.md, README.md, NEW todo/new/*, NEW docs/adr-*.md
- **Blocked by:** —

## Goal
Only `todo/*.md` is the backlog. A todo filed by an agent lands in
`todo/new/`, and nothing in any subdirectory of `todo/` is claimed,
planned, or run until a human moves it into `todo/` by hand.

## Why
`todo/` is the backlog and everything in it is runnable. An agent that files
a todo mid-run puts it straight into a loop over every todo, and the loop
picks it up on its next tick, unreviewed. `roles/protocol.md` says "filing
is not prioritizing; the maintainer decides what gets picked up", and
nothing enforces that. An inbox the verbs cannot see makes the sentence a
mechanism. `new/` is the directory agents file into; a project may keep
others, `todo/backlog/` or whatever it likes, and the rule is the same for
all of them: a subdirectory is not the backlog. Decided 2026-09-27; `todo/`
stays flat and there is no `done/`, because deleting the file on the branch
already makes merging the work and clearing the backlog one event, and git
holds the record.

## Notes
- Today the skip is an accident: `lib/graph.sh` and `lib/render.sh` loop over
  the shell glob `todo/*.md`, which does not descend. Keep the globs; that
  is the rule, and it already covers any subdirectory name. Make it explicit
  where a stem can still reach a nested file:
  - `ai_harness_todo_validate` in `lib/todo.sh`: a stem that resolves to a
    file under any subdirectory of `todo/` fails with `<stem> is in
    todo/<dir>/, not ready: git mv todo/<dir>/<stem>.md todo/ to make it
    ready`. Today it fails on the prefix rule with a message about the
    directory name not being a prefix. `claim`, `run`, and `dispatch worker
    --print` all validate through it, so one message covers them.
  - `ai_harness_open_blockers` in `lib/graph.sh` tests `-f todo/<b>.md`, so
    a blocker sitting in a subdirectory reads as closed and the blocked todo
    runs. Look for the blocker anywhere under `todo/`, `find todo -name
    "<b>.md"` or a loop over `todo/*/`, and treat a hit in a subdirectory as
    open. The plan's hold reason says `blocked by <b>, in todo/<dir>/` so
    the reader knows what to triage.
- `verbs/plan.sh`: one line after the `workers` line when any subdirectory
  holds a todo, one entry per directory, `inbox    2 in todo/new/, 5 in
  todo/backlog/; moved into todo/ to be planned`. Validate those files the
  same way so a bad one shows as `invalid`. `aih status` does not change.
- `lib/check.sh` needs nothing: its `case` patterns `A:todo/*.md` and
  `D:todo/*.md` match across `/`, so a branch may add a file under any
  `todo/` subdirectory without declaring it in Touches, which is the point.
- `roles/protocol.md` **Filing one** and `roles/worker.md` `--note`: file
  into `todo/new/`, then mention it in a `--note`. The `--note` alone is not
  filing.
- `todo/new/.keep`, an empty file, so git keeps the directory when it is
  empty. This branch adds it; `verbs/init.sh` writes it next to
  `todo/README.md`. `templates/todo-README.md` gets a paragraph on the
  flat backlog, the `new/` inbox, other subdirectories being the project's
  own, and the `git mv` that promotes one.
- ADR: a directory rather than a status field, subdirectories are never the
  backlog, and no `done/`. One screen, dated the day it is written, on this
  branch as its own `doc:` commit.
- Mechanics of the loop are untouched: `lib/run.sh` and `verbs/run.sh` are
  not in Touches. If the work needs them, say so.

## Done when
- [ ] with `todo/new/fix-x.md` and `todo/backlog/fix-y.md` present, `aih plan` and `aih status` list no row for either, and `aih run --all` claims neither
- [ ] `aih claim fix-x` and `aih run fix-x` refuse with the `git mv` message naming `todo/new/`
- [ ] a todo in `todo/` blocked by one in any `todo/` subdirectory is held, with `in todo/<dir>/` in the reason
- [ ] `aih plan` prints the inbox line only when a subdirectory holds a todo, one entry per directory
- [ ] `todo/new/.keep` is on the branch, and `aih init` creates `todo/new/.keep`
- [ ] `roles/protocol.md`, `roles/worker.md`, and `templates/todo-README.md` say to file into `todo/new/`
- [ ] a new ADR in `docs/` records the inbox, that subdirectories are never the backlog, and the decision against `done/`
- [ ] `test/render-fixture.sh` output is unchanged
- [ ] `aih gate` passes
