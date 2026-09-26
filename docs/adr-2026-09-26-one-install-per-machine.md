# ADR 2026-09-26: One install per machine, config per repo

- **Status:** Accepted
- **Date:** 2026-09-26
- **Supersedes:** adr-2026-09-24-the-harness-is-its-own-repo, its layout rule only

## Context
- Today a repo carries the whole tree under `<repo>/ai-harness/`, and
  `bin/aih:24` refuses to run from anywhere else.
- Adopting the harness means copying about 4,000 lines of shell into a repo
  and hand-writing a launcher. Upgrading means replacing the tree in every
  repo that has it.
- Three dogfood runs on 2026-09-26 showed the mechanics work. What a
  stranger meets first is the install, and it is the least built part.
- The per-worktree copy existed so each worktree read its own config. The
  config is read from the current worktree's root regardless of which copy
  runs, so the copy never needed to be per-worktree.

## Decision
- The tree installs once per machine, under
  `${XDG_DATA_HOME:-$HOME/.local/share}/ai-harness`. A repo holds
  `.ai-harness.conf`, `todo/`, and nothing of the harness.
- `~/.local/bin/aih` execs `${AI_HARNESS_HOME:-<that tree>}/bin/aih`. The
  env var is how a developer of the harness runs a checkout's copy.
- `bin/aih` drops the layout guard. `AI_HARNESS_HOME` is wherever the
  running copy is; `AI_HARNESS_REPO` is `git rev-parse --show-toplevel` of
  the current directory, as now.
- `run` and `dispatch` put the running copy's `bin` first on an agent's
  `PATH`. Every agent in a run uses the copy that started the run.
- Role docs live in the tree. `aih role <worker|reviewer>` prints one.
  The boot prompt and the adapters say `aih role worker`, never a path.
- The tree carries a `VERSION` file, and `aih version` prints it. A config
  may set `AI_HARNESS_MIN_VERSION`; `doctor` fails below it.
- The default `AI_HARNESS_PROTECTED` becomes `AGENTS.md`.
- State stays in `$(git rev-parse --git-common-dir)/ai-harness/` (ADR-07).
- This repo keeps its source at `ai-harness/` and is the one repo where a
  worker runs `./ai-harness/bin/aih` to test its own change.

## Alternatives considered
- **Keep vendoring, ship `install.sh` to copy the tree** — every upgrade is
  a diff in every adopting repo, and the tree lands in their reviews.
- **Git submodule** — the same tree in every repo, plus submodule ceremony
  on every clone.
- **Launcher that prefers an in-repo copy when one exists** — magic that
  turns a stray `ai-harness/` directory into a different harness.
- **Bake the install path into adapters** — a team repo would carry one
  developer's home directory.

## Consequences
- `aih init` (a later todo) writes the config and copies adapters; nothing
  else lands in a repo.
- The AGENTS.md block and `README.md` stop naming `ai-harness/README.md`
  and `ai-harness/roles/`; they name `aih help` and `aih role`.
- `selftest.sh:18` and `doctor.sh:127`, which assume the in-repo path, change.
- Two machines on one repo may run different versions; `AI_HARNESS_MIN_VERSION`
  is the only guard, and it is opt-in.
- A worker in this repo that changes a verb cannot see the change through
  `aih` on PATH; it runs the checkout's `bin/aih` directly. The reviewer's
  `integrate` runs the installed copy, so a branch still cannot loosen the
  check that judges it.
- `chore-add-the-install-script` is superseded; its stack detection moves
  to `aih init`.
