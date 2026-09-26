# ADR 2026-09-24: The harness is its own repo

- **Status:** Accepted
- **Date:** 2026-09-24
- **Superseded by:** adr-2026-09-26-one-install-per-machine, the layout rule only

## Context
- The harness was built inside `dannycastillo/wut-command`, first as
  `harness/`, renamed to `ai-harness/` on 2026-09-23.
- It is language-agnostic by design (ADR-09): everything project-specific is in
  `.ai-harness.conf`. Its own gate still ran Go's toolchain, and its backlog
  and ADRs sat among wut's.
- No commit in wut-command touched both the harness and the Go code.

## Decision
- `dannycastillo/ai-harness` holds the harness. Its history is wut-command's,
  filtered by `git filter-repo` to the harness's paths, old and new:
  `harness/`, `ai-harness/`, `.harness.conf`, `.ai-harness.conf`, `AGENTS.md`,
  `LICENSE`, ADR-07 to ADR-10, the dated ADRs, and the harness todos.
- PR references in commit messages are rewritten to
  `dannycastillo/wut-command#N`.
- The layout stays `ai-harness/` under the repo root, because `aih` refuses to
  run from anywhere else. The harness gates itself with its own config.
- wut-command is left as it was. How it takes the harness from here is its own
  decision.

## Alternatives considered
- **Copy the whole repo, then delete the Go code** — every picker commit stays
  in the harness's log.
- **`git subtree split --prefix=ai-harness`** — follows one path, so it drops
  everything before the rename.
- **A fresh repo with no history** — loses the record of how the harness was
  designed.

## Consequences
- Commit hashes differ from wut-command's. The original history is still
  there, unchanged.
- `git log --follow` stops at the rename commit for files it changed too much
  (`lib/run.sh`). `git log -- harness/<path>` reaches the earlier history.
- ADR-07 still names `../wut-command-worktrees`. ADRs are append-only.
- Until wut-command picks a way to take the harness (subtree, copy, installer),
  there are two copies that can drift.
