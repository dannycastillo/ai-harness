# chore: remove two functions that do nothing

- **Priority:** low
- **Branch:** chore/strip-dead-code
- **Touches:** ai-harness/lib/agents.sh, ai-harness/lib/run.sh, ai-harness/verbs/run.sh
- **Blocked by:** —

## Goal
No function in `ai-harness/` is uncalled or a pass-through.

## Why
Code with no caller is still read by everyone who opens the file.

## Notes
- `ai_harness_agent_state` (`lib/agents.sh`) has no callers.
- `ai_harness_run_report` (`lib/run.sh`) calls `ai_harness_run_status` and
  ignores its argument. `verbs/run.sh` is its one caller: call
  `ai_harness_run_status` there. Its comment says the report and status must
  agree; keep that point where the call is.
- Shares `lib/run.sh` with `fix-misleading-hints`, so `plan` serializes them.

## Done when
- [ ] `grep -rn 'ai_harness_agent_state\|ai_harness_run_report' ai-harness` prints nothing
- [ ] `aih run --once` still ends with the run-set report
- [ ] `aih gate` passes
