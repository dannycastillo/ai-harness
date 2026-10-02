# fix: init says so when the repo has no commits

- **Priority:** medium
- **Touches:** verbs/init.sh test/first-run.sh
- **Blocked by:** —

## Goal
In a repo with no commits, `aih init` asked for a new trunk dies before any
prompt with one line: `init: no commits yet; commit once, then run aih init`.

## Why
Today it asks for the trunk name and the push answer, then dies
`fatal: invalid reference: HEAD` from `git worktree add`. The user answers
two prompts for an error git wrote, not us.

## Notes
`verbs/init.sh` computes `_here` at line 51, prompts for the trunk at
54-75 and the push answer at ~253-268, then runs
`git worktree add -q -b "$_trunk" "$_dest" HEAD` at ~280. On an unborn
branch `git symbolic-ref --short HEAD` still answers `main`, so `_here` is
set and nothing notices until `worktree add`.

Right after `_here` is set, test `git rev-parse -q --verify HEAD` (exit 1
on an unborn branch). When it fails and `--trunk` was not given, die with
the sentence above. `--trunk <name>` keeps working: it writes files and
commits nothing, and that path already succeeds on an unborn repo (checked
2026-10-01: `aih init --trunk main --yes` then `aih status` both exit 0).

Not `git worktree add --orphan`: the trunk's root commit would be
`chore: add ai-harness` with `main` still unborn, so the trunk could never
be promoted onto `main`. The ADR adr-2026-09-29-init-opens-a-dated-trunk-worktree
says init never touches `main`, and a first commit is the user's.

Add a scenario to `test/first-run.sh`: `git init -q -b main` with no commit,
`says` for `init --yes` with the new sentence, then `runs` for
`init --trunk main --yes`. Register it with `run <name>` at the bottom.
`sh test/first-run.sh` is the `firstrun` gate; `aih gate --quick` does not
run it, so run it yourself.

## Done when
- [ ] `git init && aih init --yes` prints the one line above on stderr and exits non-zero, with no prompt shown first
- [ ] interactive `aih init` on the same repo dies the same way before the trunk menu
- [ ] `aih init --trunk main --yes` on the same repo still exits 0
- [ ] `sh test/first-run.sh` passes with the new scenario
- [ ] `aih gate` passes
