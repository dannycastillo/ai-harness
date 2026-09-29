# fix: the agent command is split on spaces

- **Priority:** medium
- **Touches:** lib/agents.sh, README.md, templates/ai-harness.conf
- **Blocked by:** —

## Goal
`AI_HARNESS_AGENT_CMD` is parsed as a shell command line, so a flag whose
value has a space or quotes reaches the agent intact.

## Why
`ai_harness_agent_spawn` in `lib/agents.sh` expands `$AI_HARNESS_AGENT_CMD`
unquoted, which splits on whitespace and strips nothing. A config line
like `--append-system-prompt "answer briefly"` becomes three arguments
with the quote marks inside them. Most agent CLIs have at least one such
flag, and the README does not say the value cannot have one.

## Notes
- The config is already sourced as POSIX sh (ADR-09), so the value is a
  shell string; parsing it as one is consistent. The wrapper is already a
  `sh -c`: interpolate the command into that script instead of passing it
  as words, or `eval` it inside. Either way the prompt stays a separate,
  quoted argument appended last.
- The agent record's `cmd=` line keeps the raw string.
- Say in the README's "Running N workers" section and in the config
  template's comment that the value is a shell command line and is
  quoted like one.

## Done when
- [ ] in a scratch repo with `AI_HARNESS_AGENT_CMD='printf "%s|" a "b c"'`, the log of `./bin/aih dispatch worker --detach` reads `a|b c|<prompt>|`
- [ ] the README and `templates/ai-harness.conf` say the value is a shell command line
- [ ] `aih gate` passes
