# doc: move each verb's facts out of the protocol

- **Priority:** medium
- **Touches:** roles/protocol.md, verbs/*
- **Blocked by:** feat-every-verb-answers-help, feat-protocol-is-its-own-verb

## Goal
`roles/protocol.md` holds only what two or more verbs or roles share, plus
a list of common tasks by intent, and every sentence about a single verb
lives in that verb's `--help`.

## Why
The protocol is a shared reservation: a todo that edits it runs beside
nothing else that does. It stays cheap to hold only if it changes when a
contract changes, not when a verb does. Now that each verb has a home for
its own facts, the ones that accumulated here can go there.

## Notes
- The test for a sentence: about what one verb reads, writes, refuses,
  prints or accepts as a flag, it moves to that verb's header. Needed by
  two or more verbs or roles, or before running anything, it stays.
- Seen on 2026-09-29, by section:
  - **Working in parallel**: "The mechanics and the verbs are in
    `README.md`" becomes "`aih help` lists the verbs and `aih <verb>
    --help` documents each." The `aih run` set-is-fixed sentence is
    `run`'s; keep one clause here.
  - **Done when**, the paragraph on which verbs run where and the `plan`
    during-a-loop caveat: each verb's `--help` says where it runs. Keep
    one sentence: every box must be checkable from the worker's own
    worktree, and `aih <verb> --help` says where a verb runs; a box that
    needs the trunk checkout is a human's and says so.
  - **Filing one**: "A branch that adds a file at the top level of
    `todo/` parks with `todo-added`" is `check`'s; "run `aih plan` and fix
    any row it marks `invalid`" is `plan`'s. Keep: file into `todo/new/`,
    a human promotes it.
  - **Picking one up**: the sequence stays; flag-level detail goes.
- Add `## Common tasks` at the end: one line per task, intent then verb,
  no flags. Open a trunk (`aih init`); see the backlog and what would run
  (`aih plan`); see what is running or ran (`aih status`, `aih log`);
  file a todo (a file in `todo/new/`); take one (`aih claim`); work a set
  unattended (`aih run`); hand off (`aih submit`); judge (`aih
  integrate`); retire a trunk (a pull request from the trunk to `main`,
  then `git worktree remove` and `git branch -d`; there is no verb,
  adr-2026-09-29-init-opens-a-dated-trunk-worktree).
- Add one paragraph under **Working in parallel** on the three places a
  verb runs: anywhere, the trunk checkout, or a claim's worktree, and
  that `--help` is the per-verb truth. Three sentences.
- `verbs/init.sh`, the one-install comment below its header, still says
  the protocol reaches agents through `aih role`; it is `aih protocol`
  and `aih role` now. A worker fixed it on 2026-09-30 outside its
  `Touches` and the change was dropped to clear the park; it is yours.
- A sentence moved into a header edits `verbs/<verb>.sh`; that is why
  `verbs/*` is reserved. Change nothing but comments there.
- The file was 181 lines on 2026-09-29. Net of the tasks section it
  should shrink; report before and after in the submit body.

## Done when
- [ ] no sentence in `roles/protocol.md` describes what one verb refuses, prints, or takes as a flag, and each one removed appears in that verb's `--help`
- [ ] `roles/protocol.md` has a `## Common tasks` section, one line per task, no flags
- [ ] `roles/protocol.md` says in one paragraph where verbs run and defers to `aih <verb> --help`
- [ ] `roles/protocol.md` no longer points at `README.md` for mechanics
- [ ] the diff under `verbs/` touches only comment lines
- [ ] `aih gate` passes
