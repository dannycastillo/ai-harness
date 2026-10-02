# feat: reports print a blank line before and after

- **Priority:** medium
- **Touches:** bin/aih lib/render.sh verbs/status.sh verbs/plan.sh verbs/log.sh verbs/doctor.sh verbs/help.sh verbs/protocol.sh verbs/role.sh
- **Blocked by:** —

## Goal
Every verb that prints a report starts and ends its output with one blank
line, so the report sits apart from the prompt above and below it.

## Why
`aih plan` ends on its last table row and the next shell prompt lands
flush against it. The same for status, log and doctor. A report reads as
a block when it has air on both sides.

## Notes
Reports, and only these: `status`, `plan`, `log`, `doctor`, `help`,
`protocol`, `role`, and `aih <verb> --help` (`bin/aih` lines 40-41,
through `ai_harness_verb_help`). Unchanged: `version`, `check`, `claim`,
`submit` and every other one-line answer an agent reads; `run`, which
streams; every error, which is one line on stderr from `die`.

Not in the dispatcher: it cannot know a verb's line count without
buffering, and `run` and `log` must stream. Not gated on a tty: one
behaviour, and the consumers that read reports (agents, `test/first-run.sh`)
match substrings.

One home for it: a helper in `lib/render.sh` that prints the leading blank
and arranges the trailing one. `plan` exits early at lines 42 and 46 with
a one-line report and `doctor` exits through its own paths, so the trailing
blank has to cover every exit, not just the fall-through; an EXIT trap set
by the helper is the simple way. A short report still gets both blanks;
consistency over counting lines.

Exactly one blank at each end. `status` already prints `\n\n` after
`no run yet` (`lib/render.sh` ~288) and `plan` and `doctor` end with a
`printf '\n'`; fold those into the helper so nothing prints two blanks in
a row at the end of a report. Blank lines between sections stay as they
are.

`test/first-run.sh` matches substrings, so no assertion changes; run it
anyway, it is the `firstrun` gate and `aih gate --quick` skips it.

## Done when
- [ ] `aih plan | head -1` and `aih plan | tail -1` are both empty, and the same for status, log, doctor, help, protocol, role and `aih status --help`
- [ ] no report ends with two consecutive blank lines, including `status` with no run yet and `plan` with a run in progress
- [ ] `aih version` still prints exactly one line
- [ ] `sh test/first-run.sh` passes
- [ ] `aih gate` passes
