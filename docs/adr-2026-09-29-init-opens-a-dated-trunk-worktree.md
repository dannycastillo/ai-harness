# ADR 2026-09-29: Init opens a dated trunk worktree

- **Status:** Accepted
- **Date:** 2026-09-29

## Context
- `aih init` made the checked-out branch the trunk, so trying the harness cost the user their checkout.
- `integrate` parks on a dirty trunk tree, and switching branches leaves the trunk checked out nowhere.
- Run from a checkout that is not the trunk, `aih` died with `no .ai-harness.conf`, or loaded `main`'s copy of the config after a merge and reported `main`'s stale `todo/`.

## Decision
- The trunk is either kind of checkout: a branch on the main working tree, or a branch in its own worktree. Both are supported.
- `aih init` offers a new branch and worktree `ai-harness-YYYYMMDD` (UTC) or the branch checked out here. `--yes` picks the new one.
- Init commits `chore: add ai-harness` on a branch it created. On a branch it did not create, it writes files and commits nothing.
- With a config already present, a new trunk copies it and rewrites only `AI_HARNESS_TRUNK`.
- `aih` runs only from the trunk worktree or a claim's worktree. `init`, `gate`, `help` and `version` run anywhere. Elsewhere it prints the trunk's path, or says the trunk is checked out nowhere.
- With no config in the current tree, the redirect is used if exactly one checkout has a config naming its own branch as trunk.
- The trunk's name stays in the committed config.

## Alternatives considered
- Re-root to the trunk automatically: the current tree stops being the thing every verb reads, and `ls todo/` stops being the backlog.
- Read config and todos from trunk by `git show`: every verb needs a second read path, and again `ls todo/` is no longer the backlog.
- Trunk name in a per-machine `git config` key: moves project settings out of `.ai-harness.conf`, against ADR-09.

## Consequences
- A first run costs the user nothing they had checked out; closing a trunk is `git worktree remove` and `git branch -d`.
- Each new trunk opens with a commit that renames it, and `main` names the last merged trunk.
- Before a trunk has merged, a redirect needs a checkout with a config; when the trunk is checked out nowhere and `main` has none, the setup pointer is what prints.
- `aih trunk new` and `aih trunk close` are not built; `aih init` is how the next trunk opens.
