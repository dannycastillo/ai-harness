# chore: drop the Branch field; the filename is the only name

- **Priority:** high
- **Branch:** chore/drop-the-branch-field
- **Touches:** lib/todo.sh, roles/protocol.md, README.md, todo/*
- **Blocked by:** feat-aih-role.md

## Goal
A todo has one name, its filename. Nothing reads a **Branch** field, the shape in `roles/protocol.md` has none, and no open todo carries one.

## Why
The branch is derived from the filename and `AI_HARNESS_PREFIXES`, and
`todo_validate` only checks that the field equals that derivation. A
second name for the same thing is a thing that can drift. Decided
2026-09-26: the simplest mechanism for the MVP is the filename for
everything.

## Notes
- `lib/todo.sh`: `ai_harness_todo_validate` stops reading Branch. A
  todo that still has the line is not an error; the line is ignored.
- `roles/protocol.md`: the Shape drops the Branch line. The Git workflow
  section there shrinks to what the harness enforces: the declared
  prefixes name the todo file and the commit subject, and the branch is
  `<prefix>/<rest>` of the filename. "Branch for everything" and "One
  branch unless the split earns it" are a project's rules and come out;
  this repo keeps them in its own `AGENTS.md`.
- README's todo example, if any, drops the line.
- `roles/protocol.md`, Filing one: say that the prefixes are whatever the
  project declares in `AI_HARNESS_PREFIXES`, that what each one means is
  the project's `AGENTS.md`, and that after filing you run `aih plan` and
  fix any `invalid` row. Nowhere may the protocol name this repo's four
  as if they were the harness's.
- Strip the `- **Branch:**` line from every file in `todo/`, this one
  included. `Touches` names `todo/*` for that reason, so this runs while
  no other todo is claimed.
- The derivation itself is unchanged. Making it configurable was
  considered and deferred.

## Done when
- [ ] `grep -rn 'Branch:' todo roles README.md lib` prints nothing
- [ ] a todo with no Branch line validates, claims, and submits
- [ ] a todo that still has one validates and is claimed onto the derived branch, the line ignored
- [ ] `roles/protocol.md`'s Git workflow section states only the prefix rule and the derivation
- [ ] `roles/protocol.md` tells a filing agent to take the prefixes from `AI_HARNESS_PREFIXES`, read the project's `AGENTS.md` for their meaning, and check `aih plan` after filing; `grep -c 'feat fix doc chore' roles/protocol.md` prints 0
- [ ] `aih check --selftest` passes
- [ ] `aih gate` passes
