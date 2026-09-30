# chore: usage errors read the header

- **Priority:** medium
- **Touches:** verbs/abandon.sh, verbs/check.sh, verbs/claim.sh, verbs/integrate.sh, verbs/init.sh, verbs/log.sh, verbs/path.sh, verbs/plan.sh, verbs/pause.sh, verbs/resume.sh, verbs/status.sh, verbs/stop.sh, verbs/unlock.sh
- **Blocked by:** —

## Goal
Every verb's usage error prints the `usage:` line of its own header, so the
usage text exists once per verb.

## Why
feat-every-verb-answers-help made the header the one home for a verb's
usage and converted `dispatch` and `role` to read it. Thirteen verbs still
die with an inline string that repeats the header, and two already
disagree: `check`'s header says `[<todo-stem> | --selftest]` while its
inline string says `[<todo-stem>] | --selftest`. A second copy is a
second place to forget.

## Notes
- `lib/common.sh` has `ai_harness_usage_line <verb>`; `verbs/dispatch.sh`
  line 15 and `verbs/role.sh` line 10 show the shape:
  `die "$EX_USAGE" "$(ai_harness_usage_line <verb>)"`.
- The thirteen: `grep -n '"usage: aih\|'"'"'usage: aih' verbs/*.sh` on
  2026-09-30 lists abandon, check, claim, integrate, init, log, path,
  plan, pause, resume, status, stop, unlock, one line each.
- Where the inline string and the header disagree, read the verb's
  argument parsing and make the header say what the code accepts; the
  inline string is then dropped, not reconciled.
- No behaviour changes beyond the wording of a usage error. Do not touch
  `dispatch.sh` or `role.sh`.

## Done when
- [ ] `grep -n '"usage: aih\|'"'"'usage: aih' verbs/*.sh` finds nothing
- [ ] for each of the thirteen verbs, the usage error's text equals its `--help` `usage:` line
- [ ] each of the thirteen headers' `usage:` line matches what the verb's argument parsing accepts
- [ ] `aih gate` passes
