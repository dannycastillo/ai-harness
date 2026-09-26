# fix: work from any directory in the repo

- **Priority:** high
- **Branch:** fix/run-from-any-directory
- **Touches:** ai-harness/bin/aih, ai-harness/verbs/submit.sh
- **Blocked by:** —

## Goal
Every verb gives the same result from a subdirectory as from the repo root.

## Why
The verbs read `todo/*.md` relative to the current directory, and the
config's gates use relative paths. From `ai-harness/`, `aih plan` prints an
empty plan, `claim` says "no such todo", and `gate` and `submit` fail.

## Notes
- `bin/aih` finds `$AI_HARNESS_REPO` but never changes to it. A `cd` there,
  after the config is sourced and before the verb, fixes every relative read at
  once: `lib/graph.sh`, `lib/todo.sh`, `verbs/status.sh`, `verbs/plan.sh`.
- `submit --body <file>` takes a path from the user, which must still resolve
  against the directory they ran it from. Save that directory before the `cd`.
- `dispatch` changes into the worktree it starts an agent in; that is unaffected.
- `bin/aih:30` says "run ai-harness/install.sh", which does not exist yet.
  Point at `ai-harness/README.md`'s Setup section instead.

## Done when
- [ ] from `ai-harness/`, `aih plan` and `aih status` print the same as from the root
- [ ] from `ai-harness/`, `aih gate --quick` passes
- [ ] `aih submit --body notes.txt` from a subdirectory reads that subdirectory's `notes.txt`
- [ ] the missing-config message names no file that does not exist
- [ ] `aih gate` passes
