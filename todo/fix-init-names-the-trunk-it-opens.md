# fix: init names the trunk it opens

- **Priority:** low
- **Touches:** verbs/init.sh, test/first-run.sh, README.md
- **Blocked by:** —

## Goal
The commit `aih init --new-trunk` makes says what happened in that repo:
`chore: add ai-harness` the first time, `chore: open trunk <name>` when a
config already exists and only the trunk changes.

## Why
`init` commits `chore: add ai-harness` whichever case it is in. On
2026-09-29 two trunks were opened over an existing config and each commit
had to be amended by hand to `chore: open trunk <name>`, the subject the
first such trunk (`5e25525`) used. A reader of `git log --first-parent main`
sees the harness "added" once per trunk, which is wrong.

## Notes
- `verbs/init.sh` already knows which case it is in: `_copy=yes` when
  `.ai-harness.conf` existed and was copied with only `AI_HARNESS_TRUNK`
  rewritten. Pick the subject from that flag at the `git commit` near the
  end and in the `init: committed on … as "…"` line after it. One variable,
  set once, used twice.
- Two subjects only. Fresh repo: `chore: add ai-harness`. Existing config:
  `chore: open trunk <name>`. `chore` in both cases (AGENTS.md: no behavior
  a user of the tool observes changes).
- `--trunk <name>` (the branch checked out here) commits nothing and is
  unchanged.
- `test/first-run.sh:49` asserts the fresh subject; keep it, and add the
  copy case: init once, then `--new-trunk second --yes` from the new trunk,
  and assert its subject is `chore: open trunk second`.
- adr-2026-09-29-init-opens-a-dated-trunk-worktree says init commits
  `chore: add ai-harness` on a branch it created. That line describes the
  fresh case; the decision, that init commits on a branch it creates and
  not otherwise, stands. No new ADR, no edit to the old one.
- README.md, Quickstart, mentions what init commits; make it match.

## Done when
- [ ] in a repo with no config, `aih init --new-trunk a --yes` commits `chore: add ai-harness`
- [ ] from that trunk, `aih init --new-trunk b --yes` commits `chore: open trunk b` and its diff is only `AI_HARNESS_TRUNK`
- [ ] the `init: committed on …` line prints the subject actually used
- [ ] `sh test/first-run.sh` covers both and passes
- [ ] `aih gate` passes
