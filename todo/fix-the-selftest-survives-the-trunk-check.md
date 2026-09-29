# fix: the selftest survives the trunk check

- **Priority:** high
- **Touches:** bin/aih, lib/selftest.sh
- **Blocked by:** —

## Goal
`aih doctor --selftest` passes from the trunk checkout again. The throwaway
worktree it makes is neither trunk nor a claim, and the harness it runs there
still answers.

## Why
adr-2026-09-29-init-opens-a-dated-trunk-worktree made `bin/aih` refuse every
verb but `init`, `gate`, `help` and `version` outside the trunk and claim
worktrees. `lib/selftest.sh:19` runs `aih doctor --print-state-dir` inside a
detached throwaway worktree to prove that a linked worktree resolves the same
state dir (the ADR-10 slip guard). That call is now refused, the selftest
prints `linked: (the linked worktree's harness failed)`, and `doctor` exits 1
on a trunk that is fine. The init todo's Touches left `lib/selftest.sh` out
and its Done-when did not run the selftest, so the merge went green.

## Notes
- `--print-state-dir` is the only thing the selftest asks of the linked
  worktree, and the selftest is its only caller (`verbs/doctor.sh:9`). The
  state dir is the same from every worktree by definition; that is what the
  selftest checks. So `bin/aih` may let `doctor --print-state-dir` through
  the check the way it lets `gate` through: a location-free query.
- No environment-variable bypass: a hidden switch that turns the check off
  is a second way to run from the wrong tree.
- The redirect itself stays: `aih doctor` with no flag from a detached
  worktree must still print `run this from the <trunk> checkout`.
- `test/first-run.sh` covers the redirects; run it.

## Done when
- [ ] `aih doctor --selftest` exits 0 from the trunk checkout
- [ ] `aih doctor` from a detached worktree still prints `run this from the <trunk> checkout: cd <path>`
- [ ] `sh test/first-run.sh` passes
- [ ] `aih gate` passes
