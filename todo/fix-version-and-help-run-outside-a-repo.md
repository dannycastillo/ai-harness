# fix: version and help run outside a repo

- **Priority:** high
- **Touches:** bin/aih, verbs/help.sh, README.md
- **Blocked by:** —

## Goal
`aih version` and `aih help` print their output from any directory, inside a
git repository or not.

## Why
The first thing a person types after `brew install dannycastillo/tap/ai-harness`
is `aih version`, from wherever their shell happens to be. Today that dies
with `not inside a git repository`, and the Homebrew formula's `test do` has
to fake a git repo and a config to get past it.

## Notes
- `bin/aih` resolves `AI_HARNESS_REPO` with `git rev-parse --show-toplevel`
  and dies before it knows which verb was asked for, then `cd`s into the
  repo. Move verb resolution (`verb=help`, the `case`, the `verb_file` check)
  ahead of that, and for `help` and `version` skip the repo lookup, the
  `cd`, and sourcing `.ai-harness.conf`. Leave `AI_HARNESS_REPO` unset for
  them rather than inventing a value.
- `verbs/help.sh` prints `$AI_HARNESS_PROJECT` in its first line. With no
  config loaded print `aih — AI Harness` and nothing after the dash.
- `init` still needs a repository; every other verb keeps today's message.
- adr-2026-09-29-init-opens-a-dated-trunk-worktree lists `init`, `gate`,
  `help` and `version` as the verbs that run from any checkout. This
  extends two of them to no checkout at all, same spirit; no new ADR.
- `test/first-run.sh` exercises the no-config paths and must still pass.
- README.md, Setup: one sentence saying `version` and `help` work anywhere.

## Done when
- [ ] `cd "$(mktemp -d)" && aih version` prints the tree's `VERSION`
- [ ] `aih help` in that directory lists the verbs, first line `aih — AI Harness`
- [ ] `aih status` in that directory still exits 1 with `not inside a git repository`
- [ ] `sh test/first-run.sh` passes
- [ ] `aih doctor --selftest` passes
- [ ] `aih gate` passes
