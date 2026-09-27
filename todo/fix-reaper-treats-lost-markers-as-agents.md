# fix: the reaper treats a .lost marker as an agent record

- **Priority:** medium
- **Touches:** lib/agents.sh
- **Blocked by:** —

## Goal
`ai_harness_agents_reap` skips `agents/<stem>.<role>.lost` the way it skips
`.exit`, so a lost reviewer leaves no junk event behind.

## Why
`run` marks a lost reviewer with an empty `agents/<stem>.reviewer.lost`.
`ai_harness_agent_records` excludes only `*.exit`, so the next reap reads the
marker as a record with no pid, appends `exit=lost` to it, and writes an event
with an empty stem and role: `<time>  - exited lost`. `aih log` then shows a
line about nothing.

## Notes
`lib/agents.sh`, `ai_harness_agent_records`: the `case` that skips `*.exit`.
Seen on 2026-09-27 while testing `aih status` against a fixture with a lost
reviewer.

## Done when
- [ ] `ai_harness_agent_records` never prints a `.lost` path
- [ ] with `agents/x.reviewer.lost` present, `aih status` appends no event whose stem is empty
- [ ] `aih gate` passes
