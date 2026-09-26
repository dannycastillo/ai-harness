# feat: print a todo's boot prompt without claiming it

- **Priority:** low
- **Branch:** feat/dispatch-prints-without-claiming
- **Touches:** verbs/dispatch.sh, README.md
- **Blocked by:** —

## Goal
`aih dispatch worker <stem> --print` prints the boot prompt the worker would get and changes no state.

## Why
A reviewer verifying the boot-prompt box of `feat-aih-role` had no way to
see the prompt except `aih dispatch worker`, which claims a todo first. It
claimed a real todo, read the prompt, and abandoned it. A reviewer that
changes shared state to verify a box is a reviewer that can collide with
the loop.

## Notes
- The prompt is built in `verbs/dispatch.sh` after `claim`; `--print`
  builds it for the named stem with a placeholder worktree path and exits 0
  before any claim. The reviewer form takes `--print` too and needs no
  pending packet.
- A Done-when box about the prompt then reads: "`aih dispatch worker x
  --print` shows ...".

## Done when
- [ ] `aih dispatch worker <stem> --print` prints the prompt and leaves `claims/` and `events` unchanged
- [ ] `aih dispatch reviewer --print` prints the reviewer prompt with no pending packet
- [ ] README's `dispatch` row mentions `--print`
- [ ] `aih gate` passes
