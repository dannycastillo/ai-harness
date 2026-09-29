# feat: init offers a dated trunk worktree

- **Priority:** high
- **Touches:** bin/aih, lib/common.sh, verbs/init.sh, README.md, NEW test/first-run.sh, NEW docs/adr-*.md
- **Blocked by:** feat-aih-runs-from-a-trunk-worktree

## Goal
`aih init` offers two trunks, a new branch and worktree named
`ai-harness-YYYYMMDD` or the branch checked out here, and commits the config
on the new one; and `aih` run from any checkout that is neither the trunk
nor a claim worktree says which directory to run it from.

## Why
A first-time user has `main` checked out and work in progress. Today init
makes that branch the trunk, so trying the harness means giving up the
checkout: a dirty tree parks every merge, and switching branches leaves the
trunk checked out nowhere. A dated branch in its own worktree costs the user
nothing, and its removal is a worktree and a branch. Trunks are meant to be
short-lived and merged into `main` when the user decides; the name carries
the date for that reason, and nothing more needs saying to them.

Run from the wrong place today, `aih` either dies with `no .ai-harness.conf`
and a pointer to the setup docs, or, once a trunk has been merged into
`main`, loads `main`'s copy of the config and reports `main`'s stale `todo/`
as the backlog. Decided 2026-09-28: the trunk may be a branch on the main
working tree or a branch in its own worktree, and both are supported
equally.

## Notes
- `verbs/init.sh`, before the config preview, one question with no
  preamble:
  ```
  Trunk: where ai-harness merges finished work
    1) new branch and worktree ai-harness-20260928  (recommended)
    2) the branch checked out here (main)
  Choice [1]:
  ```
  `--yes` picks 1. `--trunk <name>` keeps its meaning and picks 2. A new
  flag, `--new-trunk [<name>]`, picks 1 without a terminal. The date is
  UTC, `date -u +%Y%m%d`.
- Option 1 never writes into the current tree. It branches from HEAD, adds
  the worktree at `$(ai_harness_worktree_root)/<name>`, writes the config,
  `todo/README.md`, `todo/new/.keep` and the adapter files there, and
  commits them on the new branch as `chore: add ai-harness`. It ends by
  printing the path, and `cd <path>` and `aih doctor` as the next two
  commands. The existing refusal to overwrite a config applies to the
  current tree only, so option 1 runs without `--force`.
- When the current tree already has a config, option 1 copies it and
  rewrites only the `AI_HARNESS_TRUNK` line, so a project's gates survive
  and `aih init` is how the next trunk is opened. `aih trunk new` and `aih
  trunk close` are not this todo; note in the README that closing a trunk
  is `git worktree remove` and `git branch -d` once it has merged.
- Option 2 is today's behaviour: write the files, commit nothing, tell the
  user to commit. `main` is written only by a merge, and the tool never
  commits on the user's branch.
- `bin/aih`, after the config loads and before the verb runs, unless the
  verb is `init`, `gate`, `help` or `version`: the current toplevel must be
  the trunk worktree (`ai_harness_trunk_worktree`) or a claim's worktree,
  the `worktree=` of some file under `claims/`. Otherwise:
  - trunk checked out somewhere: `aih: run this from the <trunk> checkout:
    cd <path>`
  - trunk checked out nowhere: `aih: <trunk> is not checked out anywhere;
    check it out, or start a new trunk with aih init`
  When the current tree has no config, look through `git worktree list` for
  a checkout that has one; if exactly one does, print the first message
  with its path instead of the setup pointer. Zero or several fall through
  to today's message. A helper for "is this path a claim worktree" goes in
  `lib/common.sh`; `lib/state.sh` is the repair todo's.
- The guards in `verbs/run.sh`, `verbs/integrate.sh` and `verbs/dispatch.sh`
  stay: they require the trunk specifically, and a claim worktree passes the
  central check but must not run them.
- `test/first-run.sh`, new: in a scratch clone, run `aih init --yes` and
  check the branch, the worktree, the commit and the untouched `main`; run
  `aih init --trunk main --yes` in a second clone and check nothing is
  committed; then from `main`, from a claim worktree, from the trunk
  worktree and from a detached scratch worktree, run `aih status` and
  check each message above, before and after merging the trunk into `main`.
- README: the quickstart shows option 1 and the `cd`, one paragraph says
  option 2 exists and what it costs, and a `Removing it` section lists the
  worktree, the branch and `$(git rev-parse --git-common-dir)/ai-harness`.
- ADR, one screen, its own `doc:` commit: the trunk is either kind of
  checkout, `aih` runs only from the trunk or a claim worktree and
  redirects otherwise, and init commits on a branch it created and never on
  one it did not. Alternatives: re-rooting to the trunk automatically, and
  reading config and todos from trunk by `git show`; both lost to keeping
  `ls todo/` the backlog and the current tree the thing every verb reads.
- The trunk's name stays in the committed config, so each new trunk opens
  with a commit that renames it and `main` names the last trunk after a
  release. Record in the ADR that a per-machine `git config` key was the
  alternative and lost to ADR-09.

## Done when
- [ ] `aih init --yes` on a clone with `main` checked out creates `ai-harness-<date>` in the worktree root, commits the config there, and leaves `main` and its working tree untouched
- [ ] `aih init --trunk main --yes` writes the config into the current tree and commits nothing
- [ ] on a tree that already has a config, `aih init --yes` opens a new trunk whose config differs from the old one only in `AI_HARNESS_TRUNK`
- [ ] `aih status` from `main` prints the `cd` line when the trunk is checked out elsewhere, and the not-checked-out line when it is not, both before and after the trunk has merged into `main`
- [ ] `aih status` from a claim worktree and from the trunk worktree runs; from a detached scratch worktree it redirects
- [ ] a trunk on the main working tree and a trunk in its own worktree both pass `aih doctor`, and `run`, `integrate` and `dispatch` still refuse outside the trunk
- [ ] `test/first-run.sh` passes
- [ ] README has the two-option quickstart and `Removing it`
- [ ] a new ADR in `docs/` records the decision and the two alternatives
- [ ] `test/render-fixture.sh` output is unchanged
- [ ] `aih gate` passes
