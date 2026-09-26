# chore: run from any install location

- **Priority:** high
- **Branch:** chore/drop-the-layout-guard
- **Touches:** bin/aih, lib/agents.sh, lib/check.sh, lib/selftest.sh, verbs/doctor.sh, README.md
- **Blocked by:** chore-move-the-tree-to-the-repo-root.md

## Goal
`aih` runs from a tree anywhere on disk, through a symlink or a launcher, and agents it starts use the same tree.

## Why
adr-2026-09-26-one-install-per-machine. The guard at `bin/aih` refuses any
tree not at `<repo>/ai-harness`, and `dirname $0` does not resolve a
symlink, so a package-manager install finds nothing.

## Notes
- Resolve `$0` through symlinks in POSIX sh: loop on `readlink` while the
  path is a link, resolving relative targets against the link's directory.
  No `readlink -f`, which BSD lacks.
- Drop the guard and its comment. The config still comes from
  `git rev-parse --show-toplevel` of the current directory.
- `lib/agents.sh:41` prepends `$PWD/ai-harness/bin`; make it
  `$AI_HARNESS_HOME/bin`.
- `AI_HARNESS_PROTECTED` default in `lib/check.sh` becomes `AGENTS.md`.
- `doctor` prints the launcher as `exec "${AI_HARNESS_HOME:-<this tree>}/bin/aih" "$@"`
  with this tree's path filled in.
- `selftest.sh:18` looks for the tree inside the worktree; it now uses the
  running copy.

## Done when
- [ ] `ln -s <tree>/bin/aih /tmp/x/aih && /tmp/x/aih version` works from a repo with a config
- [ ] from a copy of the tree in a scratch directory outside any repo, `aih doctor` run inside this repo passes
- [ ] a dispatched agent's PATH begins with the running copy's `bin` (check the `cmd=`/`cwd=` record or a stub agent that prints `$PATH`)
- [ ] with `AI_HARNESS_PROTECTED` unset, `aih check --selftest` treats `AGENTS.md` as protected and `ai-harness/*` as not
- [ ] `aih gate` passes
