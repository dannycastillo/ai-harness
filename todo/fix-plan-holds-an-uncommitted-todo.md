# fix: plan holds a todo that is not on trunk

- **Priority:** medium
- **Touches:** lib/graph.sh test/first-run.sh
- **Blocked by:** —

## Goal
A todo file in `todo/` that is not committed on the trunk branch shows as
held in `aih plan` and `aih status`, with the reason, and is never
dispatched.

## Why
`plan` reads the working tree and calls such a todo runnable; `claim`
reads the trunk branch and refuses it ("not on <trunk> yet, so the
worktree would not have it"). The loop dispatches what claim then rejects.
Checked 2026-10-02 with an uncommitted `todo/fix-zz-scratch.md`: plan
printed `runnable`, claim exited non-zero with that message.

## Notes
`ai_harness_plan` in `lib/graph.sh`, the `_why` chain at ~lines 108-124.
Add one test after the validate and blockers checks and before the
unclaimed-branch one:
`git cat-file -e "$AI_HARNESS_TRUNK:$_f" 2>/dev/null` fails, so
`_why="not committed on $AI_HARNESS_TRUNK"`. Same probe `claim` uses
(`verbs/claim.sh` ~line 72), so the two verbs agree by construction.

The row then renders `held` with that detail through
`ai_harness_render_row`; nothing in `lib/render.sh` changes. `claim`'s
own refusal stays, for a stem named by hand.

A todo in `todo/new/` is already invisible to plan (adr-2026-09-27-
todo-new-is-the-inbox) and is not what this is about. Supporting an
uncommitted or gitignored `todo/` is a separate, larger change that is on
hold; this only makes plan tell the truth about today's rule.

Add a scenario to `test/first-run.sh`: write a valid todo into the trunk
worktree without committing, `aih plan` succeeds and its row says
`held` and `not committed on $TRUNK`; commit it and the row says
`runnable`. `sh test/first-run.sh` is the `firstrun` gate; `aih gate
--quick` does not run it, so run it yourself.

## Done when
- [ ] an uncommitted todo shows `held` with `not committed on <trunk>` in `aih plan` and `aih status`
- [ ] `aih claim --next` with only that todo in `todo/` says nothing is runnable
- [ ] committing the file makes it `runnable` with no other change
- [ ] `sh test/first-run.sh` passes with the new scenario
- [ ] `aih gate` passes
