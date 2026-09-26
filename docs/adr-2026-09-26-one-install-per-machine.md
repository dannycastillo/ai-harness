# ADR 2026-09-26: One install per machine, config per repo

- **Status:** Accepted
- **Date:** 2026-09-26
- **Supersedes:** adr-2026-09-24-the-harness-is-its-own-repo, its layout rule only

## Context
- Today a repo carries the whole tree under `<repo>/ai-harness/`, and
  `bin/aih:24` refuses to run from anywhere else. That path exists because
  the tool was built inside another project.
- Adopting the harness means copying about 4,000 lines of shell into a repo
  and hand-writing a launcher. Upgrading means replacing the tree in every
  repo that has it.
- `bin/aih:10` finds its tree from `dirname $0` without resolving links, so
  a symlinked launcher, which is how package managers install a command,
  finds nothing.
- There is no version and no tag. Nothing is releasable.
- The per-worktree copy existed so each worktree read its own config. The
  config is read from the current worktree's root whichever copy runs, so
  the copy never needed to be per-worktree.

## Decision
- The repo root is the tree: `bin/`, `lib/`, `verbs/`, `roles/`,
  `adapters/`, `VERSION`. A release is `git archive` of a tag.
- The tree is relocatable. It installs once per machine wherever the
  package manager puts it; a repo holds `.ai-harness.conf`, `todo/`, and
  nothing of the harness.
- Two channels, both from the tagged tarball on GitHub Releases: a Homebrew
  tap (`dannycastillo/tap/ai-harness`, macOS and Linux) and `install.sh`,
  which unpacks into `${XDG_DATA_HOME:-$HOME/.local/share}/ai-harness` and
  writes `~/.local/bin/aih`. No apt, dnf, or other native packages.
- The command on PATH execs `${AI_HARNESS_HOME:-<tree>}/bin/aih`, and
  `bin/aih` resolves symlinks before locating its tree. The env var is how
  a developer runs a checkout's copy.
- `bin/aih` drops the layout guard. `AI_HARNESS_REPO` stays
  `git rev-parse --show-toplevel` of the current directory.
- `run` and `dispatch` put the running copy's `bin` first on an agent's
  `PATH`. Every agent in a run uses the copy that started the run.
- `VERSION` is in the tree and `aih version` prints it. A config may set
  `AI_HARNESS_MIN_VERSION`; `doctor` fails below it.
- The default `AI_HARNESS_PROTECTED` becomes `AGENTS.md`.
- State stays in `$(git rev-parse --git-common-dir)/ai-harness/` (ADR-07).
- Where the rules agents read live is
  adr-2026-09-26-the-protocol-ships-with-the-tree.

## Alternatives considered
- **Keep vendoring, ship `install.sh` to copy the tree** — every upgrade is
  a diff in every adopting repo, and the tree lands in their reviews.
- **Git submodule** — the same tree in every repo, plus submodule ceremony
  on every clone.
- **Keep the tree under `ai-harness/`** — the tarball and the formula then
  carry a directory that means nothing outside this repo.
- **Launcher that prefers an in-repo copy when one exists** — magic that
  turns a stray directory into a different harness.
- **Native packages** — each needs a hosted repository and signing; brew on
  Linux plus the script reach the same people.

## Consequences
- The repo goes public before the first tag; the tap and the script need it.
- Moving the tree is a `chore` that touches every path: the config's gate
  globs, the CI workflow, `selftest.sh:18`, `doctor.sh:127`, and the README.
- The tap is a second repo, `dannycastillo/homebrew-tap`, with one formula
  that a human updates per release.
- Two machines on one repo may run different versions; `AI_HARNESS_MIN_VERSION`
  is the only guard, and it is opt-in.
- In this repo a worker that changes a verb runs `./bin/aih` to see it; the
  reviewer's `integrate` runs the installed copy, so a branch still cannot
  loosen the check that judges it.
- `chore-add-the-install-script` is superseded; its stack detection moves
  to `aih init`.
