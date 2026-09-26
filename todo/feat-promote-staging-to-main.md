# feat: promote the staging trunk to main

- **Priority:** high
- **Branch:** feat/promote-staging-to-main
- **Touches:** NEW ai-harness/verbs/promote.sh, ai-harness/README.md, NEW docs/adr-*-agents-merge-into-a-staging-trunk.md
- **Blocked by:** —

## Goal
`aih promote` pushes the staging trunk and opens the pull request that carries it into the release branch, and an ADR records that agents never write the release branch.

## Why
Since 2026-09-26 agents merge into `ai-harness-trunk`, not `main`. The
staging trunk needed no code: `AI_HARNESS_TRUNK` did it. The step that moves
staging into `main` is still a hand-run push and `gh pr create`, and it is
the step a stranger will most want to see exist before they trust the tool.

## Notes
- Write the ADR first, on this branch. It records:
  - agents merge into `AI_HARNESS_TRUNK`, default `ai-harness-trunk`; the
    release branch (new config value `AI_HARNESS_RELEASE`, default `main`)
    is written only by a human through `promote`.
  - why not `main` directly: no dev should trust a new tool with main.
  - the three rules that keep the two lines one-way: the release branch
    receives promotion PRs and nothing else; a promotion merges with a merge
    commit, never squash or rebase, because both drop the trailers and
    rebase makes the lines diverge for good; the trunk is never reset,
    rebased, or merged from the release branch.
  - the cadence: promote at the end of a run, once the PR's CI is green.
  - It supersedes nothing; ADR-10's trunk mechanics stand.
- `promote` is a human verb. From the trunk checkout only. Refuses a dirty
  trunk, a pending `integrate`, and a trunk behind its upstream.
- It pushes `AI_HARNESS_TRUNK` to its upstream (or `origin`), then opens
  the PR with `gh` if present, else `glab`, else prints the command a human
  runs. It never merges the release branch and never pushes to it.
- The PR body is one line per first-parent merge since the release branch,
  from the trailers. `dannycastillo/ai-harness#4` is the hand-made model.
- **Never test against the real remote.** Test with a bare repo as origin
  (`git init --bare`, `git remote add origin`), and with a stub `gh` on
  PATH that records its arguments. A worker that pushes to the real origin
  or opens a real PR has failed this todo.
- `chore-make-the-repo-public` and the README's quickstart will lean on this.

## Done when
- [ ] the ADR is in `docs/` in the shape AGENTS.md gives, and names the default trunk and release branch names and the three one-way rules
- [ ] against a bare-repo origin, `aih promote` from the trunk checkout pushes the trunk, and with a stub `gh` on PATH calls `gh pr create` with `--base <release> --head <trunk>`
- [ ] with no `gh` or `glab` on PATH, it pushes and prints the command to open the PR
- [ ] it refuses with one line on a dirty trunk, a pending integrate, or a trunk behind its upstream
- [ ] `aih help` lists it as a human verb
- [ ] `ai-harness/README.md` documents the two branches, `AI_HARNESS_RELEASE`, and the verb
- [ ] `aih gate` passes
