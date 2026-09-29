# chore: add dependabot for actions

- **Priority:** low
- **Touches:** NEW .github/dependabot.yml
- **Blocked by:** —

## Goal
Dependabot opens a pull request when a GitHub Action this repo's workflows
pin to has a newer major version.

## Why
The only dependencies this repo has are the actions in
`.github/workflows/ci.yml` and `.github/workflows/release.yml`, pinned as
`actions/checkout@v4`. Nothing tells us when `v5` exists. The repo is public
now and Dependabot is free for it.

## Notes
- `.github/dependabot.yml`, `version: 2`, one entry: `package-ecosystem:
  github-actions`, `directory: /`, `schedule: interval: weekly`. Nothing
  else; there is no other ecosystem here.
- `.github/dependabot.yml` is not under `.github/workflows/*`, so it is not
  in `AI_HARNESS_PROTECTED` and this branch merges normally.
- Dependabot targets the default branch, so its pull requests land on `main`
  by hand, outside a trunk. `aih log` shows such a merge as `by hand`. That
  is fine for a version bump of an action; do not set `target-branch`, since
  trunks are short-lived.
- The `main` ruleset requires the `gate` checks and a merge commit, which a
  Dependabot pull request satisfies like any other.

## Done when
- [ ] `.github/dependabot.yml` exists with the one `github-actions` entry, weekly, directory `/`
- [ ] `ruby -ryaml -e 'YAML.load_file(ARGV[0])' .github/dependabot.yml` exits 0
- [ ] human: Insights → Dependency graph → Dependabot shows the config picked up after the promotion to `main`
- [ ] `aih gate` passes
