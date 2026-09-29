# feat: check refuses a todo added to the backlog

- **Priority:** high
- **Touches:** lib/check.sh, verbs/check.sh, roles/protocol.md, README.md
- **Blocked by:** —

## Goal
A branch that adds a file at the top level of `todo/` parks with a code of
its own; adding one under any subdirectory of `todo/` stays free.

## Why
`todo/new/` is where agents file, and nothing in a subdirectory of `todo/`
is ever planned (adr-2026-09-27-todo-new-is-the-inbox). That rule is a
sentence in the protocol. `lib/check.sh` still lets a branch add
`todo/<stem>.md` without declaring it, and once `integrate` merges the
branch the file is backlog. A human files through a pull request, which
never runs `check`, so the only branches this can stop are agents'.

## Notes
- `lib/check.sh`, `ai_harness_check_diff`: the `case` arm `A:todo/*.md)
  continue` matches across `/`. Split it: `A:todo/*/*.md` continues,
  `A:todo/*.md` gets the new code. Deleting the branch's own todo and
  `D:todo/*.md` (`todo-deleted`) are unchanged.
- Code name: `todo-added`, listed with the others in `ai_harness_codes`.
  Detail: `<path> is filed into the backlog; file it in todo/new/`. It is a
  hard code, not a soft one: a park, since the fix is a `git mv` on the
  branch and a resubmit.
- `verbs/check.sh --selftest` trips every code in a throwaway repo; add an
  arm for this one.
- `roles/protocol.md` **Filing one**: say that `check` parks a todo filed
  into `todo/` itself. `README.md` lists the codes.

## Done when
- [ ] a branch that adds `todo/fix-x.md` gets `todo-added` from `aih check`, and `integrate` parks it
- [ ] a branch that adds `todo/new/fix-x.md` or `todo/backlog/fix-x.md` gets no code for it
- [ ] `aih check --selftest` trips `todo-added` and passes
- [ ] `aih gate` passes
