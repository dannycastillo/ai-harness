# fix: an empty gate list passes with a warning

- **Priority:** high
- **Touches:** verbs/gate.sh verbs/init.sh test/first-run.sh README.md roles/protocol.md
- **Blocked by:** —

## Goal
`aih gate` with nothing in `AI_HARNESS_GATES` (or in `AI_HARNESS_QUICK_GATES`
under `--quick`) warns that nothing is declared and exits 0.

## Why
`aih init` on a stack it does not recognise writes `AI_HARNESS_GATES=""`,
which is correct, and tells the user doctor will say "no gates declared"
rather than fail. But `aih gate` then dies with exit 4, so `submit` and
`integrate` stop on `gate-config` as if a tool were missing. Exit 4 is for
a declared gate whose tool is not installed or whose function is undefined,
not for a project that declares none.

## Notes
- `verbs/gate.sh` line 35: `[ -n "$_list" ] || die "$EX_CONFIG" ...`. Make
  it `warn` and exit 0 instead. Preflight already passes on an empty list.
- `lib/integrate.sh` maps exit 4 to a `gate-config` park; leave that, it
  is right for the case it was written for.
- `README.md` and `roles/protocol.md` state the exit-4 rule; add the
  empty-list behaviour next to it. `verbs/init.sh` line 225's comment says
  what doctor does; say what gate does too.
- `test/first-run.sh`'s `dated_trunk` inits a repo with no recognised
  stack, so a `runs "$W" gate` and `gate --quick` there covers it.

## Done when
- [ ] `aih gate` and `aih gate --quick` exit 0 and warn when their list is empty
- [ ] a declared gate with a missing tool still exits 4
- [ ] `test/first-run.sh` exercises the empty-list case
- [ ] `aih gate` passes
