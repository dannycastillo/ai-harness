# doc: a five-minute quickstart

- **Priority:** medium
- **Branch:** doc/quickstart-readme
- **Touches:** README.md
- **Blocked by:** chore-add-the-tap-and-install-script.md, feat-aih-init.md

## Goal
A stranger reads the README, installs, runs `aih init` and `aih run` on their own repo, and sees a merge, without reading anything else.

## Why
The three steps of the vision are the README. Today's README is a spec
for the author.

## Notes
- Three steps, in order: install (both lines), `aih init`, write one todo
  and `aih run`. Then what to expect: worktrees, a reviewer, a merge with
  trailers, and a park when a human is needed.
- Say plainly what agents can do: they run with no prompts in a worktree
  that is the sandbox; the config is sourced as shell. One paragraph.
- Test it on a scratch repo in a language other than shell, following
  the text and nothing else. Fix the text, not the reader.
- The reference material (verbs table, config, state) stays below the
  quickstart.

## Done when
- [ ] the quickstart is the first section after the pitch and is under one screen
- [ ] following it verbatim on a scratch Go or Node repo produces a merge with `AI-Harness-*` trailers
- [ ] the safety paragraph exists
- [ ] `aih gate` passes
