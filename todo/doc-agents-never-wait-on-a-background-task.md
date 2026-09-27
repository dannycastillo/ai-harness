# doc: an agent never waits on a background task

- **Priority:** high
- **Touches:** roles/worker.md, roles/reviewer.md
- **Blocked by:** —

## Goal
Both role docs say that a box the agent cannot check in the foreground,
from where it sits, ends the session as a report or a park — never as a
background task the agent waits on.

## Why
On 2026-09-26 a run's worker, and then its reviewer, each hit a box that
needed a run in another repo, started it in the background, printed that
they would wait for the notification, and exited. A dispatched agent gets
no notification: `aih dispatch --detach` starts it under `nohup` with its
output in a log, and the session ends when it stops speaking. The worker
left its draft uncommitted and was recorded `exited`; the reviewer was
recorded `lost` and the loop stopped. `roles/protocol.md` already says a
box that can only be checked in the trunk checkout is a human's, and
`roles/reviewer.md` already says to park a needs-running box it cannot
run; neither doc names the background-task failure.

## Notes
- Worker: add to **Stop, and say so, when** in `roles/worker.md`. The
  submit `--body` says which box is unmet and why. Never start the check
  in the background.
- Reviewer: add to **Stop, and hand to a human, when** in
  `roles/reviewer.md`: `aih integrate --continue --park needs-human
  --detail "<box>"`.
- The sentence to add, in both: a dispatched session is never woken by
  anything it started; if a check is not done when you stop speaking, it
  is not done.
- A few lines each. Do not restate the rest of the doc, and do not repeat
  the trunk-checkout rule that `roles/protocol.md` already carries.

## Done when
- [ ] `roles/worker.md` says a box it cannot check in the foreground is reported in the submit body, never started in the background
- [ ] `roles/reviewer.md` says the same box is a `needs-human` park, and that a dispatched session is never woken by a background task
- [ ] `aih gate` passes
