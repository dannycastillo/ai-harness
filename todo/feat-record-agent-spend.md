# feat: record what each agent cost

- **Priority:** medium
- **Branch:** feat/record-agent-spend
- **Touches:** ai-harness/lib/agents.sh, ai-harness/lib/run.sh, ai-harness/verbs/log.sh, ai-harness/README.md
- **Blocked by:** —

## Goal
When the config declares how to read an agent's cost, `aih log` shows it per agent and the run report totals it.

## Why
The first unattended run spent an unknown amount. Anyone trying the harness
on their own repo asks "what did that cost" before anything else, and the
harness cannot answer.

## Notes
- The harness knows nothing about the agent CLI (ADR-09), so the parser is
  the project's: a config function `ai_harness_agent_cost <log-file>` that
  prints a number in dollars, or nothing. Undefined means no cost is recorded
  and nothing else changes.
- Call it in `ai_harness_agents_reap` (`lib/agents.sh`) when an agent's exit
  is recorded. Write `cost=<n>` into the agent record and emit an event
  `<stem> <role> cost <n>`.
- `aih log` prints the event as it prints the others. The run report
  (`ai_harness_run_status`, `lib/run.sh`) ends with a total when any agent
  in the set has a cost.
- For Claude Code, `claude -p --output-format json` puts `total_cost_usd`
  in its JSON output; the README example hook can show that. Changing
  `AI_HARNESS_AGENT_CMD` in this repo's config is a protected-path edit and
  is a human's follow-up, not this todo's.
- `lib/run.sh` is also in `fix-misleading-hints` and
  `fix-loop-reads-a-vanished-claim`; `plan` serializes them.

## Done when
- [ ] with `ai_harness_agent_cost` defined in a scratch config, `aih log <todo>` shows a `cost` line for each agent that ran
- [ ] the run report ends with a total when any cost was recorded, and is unchanged when none was
- [ ] with the function undefined, the events file gains no `cost` lines
- [ ] `ai-harness/README.md` documents the hook and shows the Claude Code example
- [ ] `aih gate` passes
