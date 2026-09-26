# feat: a planner role turns an idea into a todo

- **Priority:** low
- **Touches:** NEW roles/planner.md, verbs/role.sh, README.md
- **Blocked by:** —

## Goal
`aih role planner` prints a prompt that takes a one-line idea and writes
one valid todo file, in the template's shape, for a human to review and
commit.

## Why
The template says what a todo looks like. It does not help a stranger
choose `Touches`, which is load-bearing for parallel work, or write a
`Done when` a reviewer can check. Two agents were lost on 2026-09-26 to
boxes a human wrote wrong. The planner is a prompt, not code, and it is
the front door people will actually use.

## Notes
- The prompt says to read, in order: `aih role protocol`, the todo
  directory's `README.md`, the project's `AGENTS.md`, and
  `AI_HARNESS_PREFIXES` from `.ai-harness.conf`. Prefixes and branch
  conventions come from the project, never from the prompt.
- It reads the code to decide `Touches`, and declares `NEW` paths for
  files it expects to create.
- Every `Done when` box must be checkable in the worker's worktree, in the
  foreground, with a command. Anything that needs the trunk checkout or
  another repo is written as a human's box and says so.
- It writes exactly one file, runs `aih plan` to show the file is valid
  and what it overlaps, and stops. It does not claim, commit, or start
  work.
- `verbs/role.sh` accepts `planner`; the README's role table and verbs
  table mention it in one line each.

## Done when
- [ ] `./bin/aih role planner` prints `roles/planner.md`
- [ ] the prompt names every field of the todo shape and says where prefixes come from
- [ ] the prompt says every box must be checkable in the worker's worktree in the foreground, and that trunk-checkout and other-repo boxes are a human's
- [ ] the README names the role
- [ ] `aih gate` passes
