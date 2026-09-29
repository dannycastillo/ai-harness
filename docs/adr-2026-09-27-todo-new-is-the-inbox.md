# ADR 2026-09-27: todo/new/ is the inbox

- **Status:** Accepted
- **Date:** 2026-09-27

## Context
- `roles/protocol.md` says "filing is not prioritizing; the maintainer
  decides what gets picked up", but nothing enforced it: an agent filing a
  todo mid-run wrote straight into `todo/`, and the next `plan`/`run` tick
  picked it up unreviewed.
- `lib/graph.sh` and `lib/render.sh` already loop over the shell glob
  `todo/*.md`, which does not descend into subdirectories. The skip was an
  accident of that glob, not a rule anything stated or checked: a stem that
  named a nested file directly (`aih claim new/fix-x`) still reached it.

## Decision
- `todo/` stays flat. Only a file directly under it is the backlog; a
  subdirectory is never the backlog, whatever it's named or how many todos
  it holds.
- `todo/new/` is the inbox an agent files into (`roles/protocol.md`'s
  **Filing one**, `roles/worker.md`'s `--note`). A project may keep other
  subdirectories of its own, `todo/backlog/` or whatever it likes; the rule
  is the same for all of them.
- `ai_harness_todo_validate` (`lib/todo.sh`) refuses a stem that resolves
  under any subdirectory of `todo/`, naming the `git mv` that promotes it.
  `claim`, `run`, and `dispatch worker --print` all validate through it, so
  one message covers them.
- `ai_harness_open_blockers` (`lib/graph.sh`) treats a blocker sitting in a
  subdirectory as open, not closed: a todo in `todo/` blocked by one still in
  the inbox holds, rather than running against a dependency nobody promoted.
- `aih plan` prints one line naming how many todos sit in each subdirectory,
  so the inbox isn't invisible — just unrunnable.
- No `done/`. Deleting a todo's file is already the merge event
  (`AGENTS.md`'s **Picking one up**); a second directory to move it through
  would duplicate that with nothing gained.

## Alternatives considered
- **A status field on the todo (`state: filed`)** — two branches editing the
  same file's field race the way the git-mv-to-promote model doesn't: moving
  a file is a rename, editing a field is a merge conflict waiting to happen.
- **Numbered todos to mark filing order** — protocol already rejects this for
  the backlog itself (todos have no order); an inbox doesn't need one either.
- **`done/` alongside `new/`** — considered and dropped: git already holds
  the record of what got done (`git log --diff-filter=D -- todo/`), and a
  second status directory is a second thing that can drift from the merge.

## Consequences
- Filing is now two steps for an agent that wants work picked up automatically
  never: write into `todo/new/`, and a human's `git mv` is required before it
  runs. That's the point — the maintainer's review is back in the loop.
- A stale nested blocker reads as `blocked by <b>, in todo/<dir>/` rather than
  as closed, so a reader knows what to triage rather than why nothing ran.
- `lib/run.sh` and `verbs/run.sh` are unchanged: the loop still only ever sees
  `todo/*.md`, so the inbox needs no separate mechanism to stay invisible to
  it.
