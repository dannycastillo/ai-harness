# chore: drop the Go-only test-skip check

- **Priority:** medium
- **Branch:** chore/drop-the-go-skip-check
- **Touches:** ai-harness/lib/check.sh, ai-harness/verbs/check.sh, ai-harness/README.md
- **Blocked by:** —

## Goal
`check` has no rule that names a language.

## Why
`skip-added` counts added `t.Skip(` lines in `.go` files, a leftover from
wut-command. ADR-09 says the harness knows no language, and in any other
project the rule never fires.

## Notes
- `lib/check.sh`: the `skip-added` code in `ai_harness_codes` and the first
  awk in `ai_harness_check_diff`.
- `verbs/check.sh`: the `skip-added` selftest case. The seed's `src/a_test.go`
  also feeds `tests-shrunk`, which stays; rename the file only if the case
  still passes.
- `ai-harness/README.md`: "an added test skip" in the hard-stop list.
- `tests-shrunk` matches `_test.` and is soft. It stays.

## Done when
- [ ] `grep -rn 'skip-added\|t\.Skip' ai-harness` prints nothing
- [ ] `aih check --selftest` passes
- [ ] `aih gate` passes
