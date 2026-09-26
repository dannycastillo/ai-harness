# doc: an agent never waits on a background task

- **Priority:** high
- **Touches:** roles/worker.md, roles/reviewer.md
- **Blocked by:** —

## Goal
Both role docs say that a box the agent cannot check in the foreground,
from its own worktree, ends the session as a report or a park — never as a
background task the agent waits on.

## Why
On 2026-09-26 the quickstart's worker, and then its reviewer, each hit a
box that needed a run in another repo, started it in the background,
printed that they would wait for the notification, and exited. A headless
session gets no notification: it ends when it stops speaking. The worker
left its draft uncommitted; the reviewer was reported lost and the loop
stopped. `roles/reviewer.md` already says to park a needs-running box;
neither doc names this failure.

## Notes
- Worker: the submit body says which box is unmet and why. Never start
  the check in the background.
- Reviewer: `integrate --continue --park needs-human --detail "<box>"`.
- The sentence to add, in both: a session run with `-p` is never woken by
  anything it started; if a check is not done when you stop speaking, it
  is not done.
- A few lines each. Do not restate the rest of the doc.

## Done when
- [ ] `roles/worker.md` says a box it cannot check in the foreground is reported in the submit body, never started in the background
- [ ] `roles/reviewer.md` says the same box is a `needs-human` park, and that a headless session is never woken by a background task
- [ ] `aih gate` passes
