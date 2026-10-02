# fix: init opens a trunk in a repo with no commits

- **Priority:** medium
- **Touches:** verbs/init.sh test/first-run.sh
- **Blocked by:** —

## Goal
In a repo with no commits, `aih init` asked for a new trunk makes one empty
root commit on the current branch, says so, and opens the trunk from it.

## Why
Today it asks for the trunk name and the push answer, then dies
`fatal: invalid reference: HEAD` from `git worktree add`. The commit it
needs is the one `git init` declined to make, and an empty repo has nothing
on its branch to protect.

## Notes
`verbs/init.sh` computes `_here` at line 51 and runs
`git worktree add -q -b "$_trunk" "$_dest" HEAD` at ~280. On an unborn
branch `git symbolic-ref --short HEAD` still answers `main`, so `_here` is
set and nothing notices until `worktree add`.

Only when `git rev-parse -q --verify HEAD` fails (exit 1 on an unborn
branch) and `_mode` is `new`: run
`git -C "$AI_HARNESS_REPO" commit -q --allow-empty -m 'chore: init'` just
before `worktree add`, and print one line,
`init: no commits yet; made an empty root commit on main` (the branch from
`_here`). Empty, not the conf: `main` holds nothing the user did not
choose, and the trunk's `chore: add ai-harness` commit stays what a first
PR shows. Any repo with a commit is untouched, so the existing scenarios'
"main moved" checks still hold.

`--trunk <name>` (choice 2) keeps working as is: it writes files and
commits nothing, and already succeeds on an unborn repo (checked
2026-10-01). The root commit is only for the path that needs a commit to
branch from.

This is the one case where init writes a branch it did not create. The
ADR adr-2026-09-29-init-opens-a-dated-trunk-worktree keeps init off the
user's checkout so trying the harness costs them nothing; an empty repo has
nothing to cost, so this is an exception with the reason intact and needs
no new ADR. The one-line notice is what keeps it from being silent.

Add a scenario to `test/first-run.sh`: `git init -q -b main` with no
commit, then `init --yes` exits 0 and prints the notice; `main` has
exactly one commit and its tree is empty (`git log --format=%s` is
`chore: init`, `git -C "$P" status --porcelain` is empty, no
`.ai-harness.conf` on `main`); the trunk worktree's last commit is
`chore: add ai-harness` with the conf. Register it with `run <name>` at
the bottom. `sh test/first-run.sh` is the `firstrun` gate; `aih gate
--quick` does not run it, so run it yourself.

## Done when
- [ ] `git init && aih init --yes` exits 0, prints the notice, and leaves one empty commit on `main`
- [ ] interactive `aih init` with choice 1 or 3 does the same after the prompts
- [ ] `aih init --trunk main --yes` on an empty repo still commits nothing
- [ ] a repo that already has a commit gets no extra commit on its branch
- [ ] `sh test/first-run.sh` passes with the new scenario
- [ ] `aih gate` passes
