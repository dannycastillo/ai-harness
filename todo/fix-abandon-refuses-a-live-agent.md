# fix: abandon refuses a claim whose agent is still running

- **Priority:** medium
- **Branch:** fix/abandon-refuses-a-live-agent
- **Touches:** verbs/abandon.sh, README.md
- **Blocked by:** —

## Goal
`aih abandon` on a claim with a live agent stops with one line naming the pid, and `--force` kills the agent before releasing anything.

## Why
On 2026-09-26 a human abandoned a claim ten seconds after the loop
dispatched its worker. `abandon` removed the worktree and cleared the agent
record while the agent kept running; the loop re-dispatched into a fresh
worktree at the same path, and the orphan could have written into it or
marked the new agent exited through the shared record. It checks for a
submission, a dirty tree and unmerged commits, and never for the agent.

## Notes
- The agent record is `agents/<stem>.<role>`; `ai_harness_agent_alive` in
  `lib/agents.sh` says whether it is live. Check it before anything is
  removed, for every role that has a record.
- `--force`: kill the way `stop --agents` does (`lib/run.sh` has the
  TERM-then-KILL helper), wait for the exit marker, then proceed.
- README's `abandon` row says what it refuses.

## Done when
- [ ] with a live agent on the claim, `aih abandon <stem>` exits 1, names the pid, and removes nothing
- [ ] `aih abandon <stem> --force` kills the agent first; afterwards no process from its record is alive and the claim is gone
- [ ] with no live agent, behaviour is unchanged
- [ ] `aih gate` passes
