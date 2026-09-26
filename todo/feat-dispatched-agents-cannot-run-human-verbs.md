# feat: a dispatched agent cannot run a human's verb

- **Priority:** medium
- **Touches:** bin/aih, verbs/dispatch.sh, lib/agents.sh, README.md, AGENTS.md
- **Blocked by:** —

## Goal
The README's "Verbs, by owner" table is enforced: an agent the loop
dispatched cannot run a human-owned, state-changing verb against the repo
it was dispatched into.

## Why
On 2026-09-26 a reviewer verifying the abandon fix made three throwaway
claims in this repo's shared state. They counted against
`AI_HARNESS_MAX_WORKERS`, showed in `aih status` as a claim with a live pid
and no worktree, and a mistyped stem would have abandoned real work. The
role docs are the only guard today, and a rule an agent can break by
accident is not a guard.

## Notes
- `dispatch` exports `AI_HARNESS_AGENT=<stem>.<role>` and
  `AI_HARNESS_AGENT_REPO=<git-common-dir>` into the agent's environment.
  Look at how `lib/agents.sh` builds the command; the export goes there.
- `bin/aih` refuses, when `AI_HARNESS_AGENT` is set and the common dir
  matches: `claim`, `abandon`, `run`, `dispatch`, `pause`, `resume`,
  `stop`, `unlock`, `doctor --repair`, `integrate --next`. Exit 1, and the
  message says to test in a scratch repo.
- Still allowed: `gate`, `check`, `submit`, `status`, `plan`, `log`,
  `path`, `role`, `help`, `version`, and `integrate --continue`.
- A scratch repo has its own `.git`, so the common dir differs and every
  verb works there. That is the whole escape hatch; no override flag.
- `AGENTS.md`'s `## ai-harness` section gains one sentence: test harness
  behaviour in a scratch repo under `$TMPDIR`, never against this repo's
  state. `AGENTS.md` is protected, so this parks for a human by design.
- The README's verbs table gets one line saying which verbs a dispatched
  agent is refused.

## Done when
- [ ] with `AI_HARNESS_AGENT=x` and `AI_HARNESS_AGENT_REPO=$(git rev-parse --git-common-dir)` set, `./bin/aih abandon nothing` exits 1 and names the scratch-repo rule; unset, it behaves as before
- [ ] the same environment runs every verb in a scratch repo
- [ ] the README's verbs table says which verbs a dispatched agent is refused
- [ ] `AGENTS.md`'s `## ai-harness` section says to test in a scratch repo
- [ ] `aih gate` passes
