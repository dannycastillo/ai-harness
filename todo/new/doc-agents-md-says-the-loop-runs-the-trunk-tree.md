# doc: AGENTS.md says the loop runs the trunk tree

- **Priority:** low
- **Touches:** AGENTS.md
- **Blocked by:** —

## Goal
The `## ai-harness` section of `AGENTS.md` says that in this repo the
loop, its workers and its reviewers all run the trunk tree's `bin/aih`,
and that the installed copy is for other repos.

## Why
The section reads "the reviewer's `integrate` runs the installed copy."
Decided 2026-09-30: this project dogfoods itself, so `aih run` is started
from the trunk worktree with `./bin/aih`, and every agent it dispatches
inherits that tree. A merge that breaks a verb breaks the next tick,
which is the point. The line as written contradicts that and sends a
by-hand reviewer to the brew copy, which lags the trunk.

## Notes
- `AGENTS.md` is a protected path: a worker branch that edits it parks.
  This is the maintainer's commit on the trunk, filed here so it is not
  forgotten.
- Suggested text for the section: a worker changing a verb runs
  `./bin/aih` to see it working; in this repo the loop is started from
  the trunk worktree as `./bin/aih run`, so its workers and reviewers run
  the trunk tree too, and a merge changes what the next tick runs. The
  installed copy is what other repos get.
- Keep it to three or four lines; the section is a pointer, not a
  policy. The reasoning is in the memory of the 2026-09-30 session and
  needs no ADR: it is how the tool has been run since the first trunk.

## Done when
- [ ] `AGENTS.md`'s `## ai-harness` section no longer says the reviewer runs the installed copy
- [ ] it says the loop, workers and reviewers in this repo run the trunk tree's `bin/aih`
- [ ] `aih gate` passes
