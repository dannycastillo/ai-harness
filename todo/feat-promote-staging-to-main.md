# feat: promote the staging trunk to main

- **Priority:** high
- **Branch:** feat/promote-staging-to-main
- **Touches:** NEW ai-harness/verbs/promote.sh, ai-harness/README.md, NEW docs/adr-*-agents-merge-into-a-staging-trunk.md
- **Blocked by:** —

## Goal
`aih promote` pushes the staging trunk and opens the pull request that carries it into the release branch, and an ADR records that agents never write the release branch.

## Why
Since 2026-09-26 agents merge into `ai-harness-release`, not `main`. The
staging trunk needed no code: `AI_HARNESS_TRUNK` did it. The step that moves
staging into `main` is still a hand-run push and `gh pr create`, and it is
the step a stranger will most want to see exist before they trust the tool.

## Notes
- Write the ADR first, on this branch. It records: agents merge into
  `AI_HARNESS_TRUNK`, which defaults to a staging branch named
  `ai-harness-release`; the release branch (new config value, default
  `main`) is written only by a human through `promote`; why not `main`
  directly (no dev should trust a new tool with main); why a PR and not a
  local merge (the forge's review and protection apply). It supersedes
  nothing; ADR-10's trunk mechanics stand.
- `promote` is a human verb. From the trunk checkout only. Refuses a dirty
  trunk, a pending `integrate`, and a trunk behind its upstream.
- It pushes `AI_HARNESS_TRUNK` to `origin` (or the trunk's upstream), then
  opens the PR with `gh` if present, else `glab`, else prints the URL a
  human opens. It never merges the release branch and never pushes to it.
- The first promotion was done by hand as
  `dannycastillo/ai-harness#4`; its body is a fair template for the PR
  body: one line per first-parent merge, taken from the trailers.
- `chore-make-the-repo-public` and the README's quickstart will lean on this.

## Done when
- [ ] the ADR is in `docs/` in the shape AGENTS.md gives, and names the default staging and release branch names
- [ ] `aih promote` from the trunk checkout pushes the trunk and opens a PR into the release branch, or prints the command when no forge CLI is on PATH
- [ ] it refuses with one line on a dirty trunk, a pending integrate, or a trunk behind its upstream
- [ ] `aih help` lists it as a human verb
- [ ] `ai-harness/README.md` documents the two branches and the verb
- [ ] `aih gate` passes
