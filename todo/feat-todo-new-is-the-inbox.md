# feat: todo/new is the inbox

- **Priority:** high
- **Touches:** lib/graph.sh, lib/todo.sh, verbs/claim.sh, verbs/plan.sh, verbs/init.sh, roles/protocol.md, roles/worker.md, templates/todo-README.md, README.md, NEW todo/new/*, NEW docs/adr-*.md
- **Blocked by:** —

## Goal
A todo filed by an agent lands in `todo/new/`, where no verb will claim,
plan, or run it, until a human moves it into `todo/` by hand.

## Why
`todo/` is the backlog and everything in it is runnable. An agent that files
a todo mid-run puts it straight into a loop over every todo, and the loop
picks it up on its next tick, unreviewed. `roles/protocol.md` says "filing
is not prioritizing; the maintainer decides what gets picked up", and
nothing enforces that. An inbox the verbs cannot see makes the sentence a
mechanism. Decided 2026-09-27; `todo/` stays flat and there is no `done/`,
because deleting the file on the branch already makes merging the work and
clearing the backlog one event, and git holds the record.

## Notes
- Today the skip is an accident: `lib/graph.sh` and `lib/render.sh` loop over
  the shell glob `todo/*.md`, which does not descend. Keep the globs and make
  the rule explicit where a stem can name an inbox file:
  - `ai_harness_todo_validate` in `lib/todo.sh`: a stem that resolves to
    `todo/new/<stem>.md` fails with `<stem> is in todo/new/, not ready: git
    mv todo/new/<stem>.md todo/ to make it ready`. Today it fails on the
    prefix rule with a message about `new` not being a prefix. `claim`,
    `run`, and `dispatch worker --print` all validate through it, so one
    message covers them.
  - `ai_harness_open_blockers` in `lib/graph.sh` tests `-f todo/<b>.md`, so
    a blocker in the inbox reads as closed and the blocked todo runs. Treat
    `todo/new/<b>.md` as open too, and have the plan's hold reason say
    `blocked by <b>, in todo/new/` so the reader knows what to triage.
- `verbs/plan.sh`: one line after the `workers` line when the inbox is not
  empty, `inbox    N in todo/new/, not planned until moved into todo/`, and
  validate the inbox files the same way so a bad one shows as `invalid`.
  `aih status` does not change.
- `lib/check.sh` needs nothing: its `case` patterns `A:todo/*.md` and
  `D:todo/*.md` match across `/`, so a branch may add a file under
  `todo/new/` without declaring it in Touches, which is the point.
- `roles/protocol.md` **Filing one** and `roles/worker.md` `--note`: file
  into `todo/new/`, then mention it in a `--note`. The `--note` alone is not
  filing.
- `verbs/init.sh` creates `todo/new/` next to `todo/README.md`;
  `templates/todo-README.md` gets a paragraph on the two directories and the
  `git mv` that promotes one. The empty-directory problem is the same as
  `todo/` itself and is not this todo's.
- ADR: a directory rather than a status field, and no `done/`. One screen,
  dated the day it is written, on this branch as its own `doc:` commit.
- Mechanics of the loop are untouched: `lib/run.sh` and `verbs/run.sh` are
  not in Touches. If the work needs them, say so.

## Done when
- [ ] with `todo/new/fix-x.md` present, `aih plan` and `aih status` list no row for `fix-x`, and `aih run --all` does not claim it
- [ ] `aih claim fix-x` and `aih run fix-x` refuse with the `git mv` message
- [ ] a todo in `todo/` blocked by one in `todo/new/` is held, with `in todo/new/` in the reason
- [ ] `aih plan` prints the inbox line only when `todo/new/` has a todo in it
- [ ] `roles/protocol.md`, `roles/worker.md`, and `templates/todo-README.md` say to file into `todo/new/`
- [ ] `aih init` creates `todo/new/`
- [ ] a new ADR in `docs/` records the inbox and the decision against `done/`
- [ ] `test/render-fixture.sh` output is unchanged
- [ ] `aih gate` passes
