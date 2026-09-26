# chore: keep the todo directory when the backlog is empty

- **Priority:** low
- **Touches:** NEW todo/README.md
- **Blocked by:** —

## Goal
`todo/` exists on trunk when the backlog is empty.

## Why
Git keeps no empty directories. When the last todo merged on 2026-09-26
the directory vanished with it. `aih init` gives every other repo a
`todo/README.md`; this one, configured before `init` existed, never got
one.

## Notes
- Copy `templates/todo-README.md` to `todo/README.md`, byte for byte.
- `plan`, `status` and the graph skip `README.md` by name, so it is never
  read as a todo.
- If the copy needs a change, change the template first, in its own todo.

## Done when
- [ ] `todo/README.md` is identical to `templates/todo-README.md`
- [ ] `./bin/aih plan` lists no todo named README
- [ ] `aih gate` passes
